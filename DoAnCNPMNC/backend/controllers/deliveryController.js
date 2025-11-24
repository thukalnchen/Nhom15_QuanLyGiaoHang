const axios = require('axios');
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

// Fallback price configuration (used if database pricing rules are not available)
const FALLBACK_PRICE_CONFIG = {
  basePricePerKm: {
    motorcycle: 5000,
    van_500: 8000,
    van_750: 10000,
    van_1000: 12000,
  },
  minimumFare: {
    motorcycle: 15000,
    van_500: 30000,
    van_750: 40000,
    van_1000: 50000,
  },
  servicePrices: {
    train_station: 20000,
    extra_weight_per_kg: 10000,
    helper_small: 50000,
    helper_large: 70000,
    round_trip_percentage: 0.7,
  },
};

// Get active pricing rule from database
async function getPricingRuleFromDB(vehicleType) {
  try {
    const query = `
      SELECT 
        base_price_per_km,
        minimum_fare,
        train_station_fee,
        extra_weight_per_kg,
        helper_small_fee,
        helper_large_fee,
        round_trip_percentage,
        weight_factor,
        distance_factor
      FROM pricing_rules
      WHERE vehicle_type = $1 
        AND is_active = true
        AND (effective_from IS NULL OR effective_from <= NOW())
        AND (effective_until IS NULL OR effective_until >= NOW())
      ORDER BY created_at DESC
      LIMIT 1
    `;
    
    const result = await pool.query(query, [vehicleType]);
    
    if (result.rows.length > 0) {
      const rule = result.rows[0];
      return {
        basePricePerKm: parseFloat(rule.base_price_per_km),
        minimumFare: parseFloat(rule.minimum_fare),
        trainStationFee: parseFloat(rule.train_station_fee),
        extraWeightPerKg: parseFloat(rule.extra_weight_per_kg),
        helperSmallFee: parseFloat(rule.helper_small_fee),
        helperLargeFee: parseFloat(rule.helper_large_fee),
        roundTripPercentage: parseFloat(rule.round_trip_percentage),
        weightFactor: parseFloat(rule.weight_factor || 1.0),
        distanceFactor: parseFloat(rule.distance_factor || 1.0),
      };
    }
    
    // Return null if no rule found (will use fallback)
    return null;
  } catch (error) {
    console.error('Error getting pricing rule from DB:', error);
    // Return null to use fallback
    return null;
  }
}

// Calculate price based on distance and services
exports.calculatePrice = async (req, res) => {
  try {
    const {
      pickupLat,
      pickupLng,
      dropoffLat,
      dropoffLng,
      vehicleType,
      services = {},
      extraWeight = 0,
    } = req.body;

    // Validate required fields
    if (!pickupLat || !pickupLng || !dropoffLat || !dropoffLng || !vehicleType) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: pickupLat, pickupLng, dropoffLat, dropoffLng, vehicleType',
      });
    }

    // Calculate distance using Google Distance Matrix API or fallback to straight-line distance
    let distanceInMeters;
    let durationInSeconds;

    if (process.env.GOOGLE_MAPS_API_KEY && process.env.GOOGLE_MAPS_API_KEY !== 'YOUR_GOOGLE_MAPS_API_KEY') {
      try {
        const response = await axios.get('https://maps.googleapis.com/maps/api/distancematrix/json', {
          params: {
            origins: `${pickupLat},${pickupLng}`,
            destinations: `${dropoffLat},${dropoffLng}`,
            key: process.env.GOOGLE_MAPS_API_KEY,
          },
        });

        if (response.data.status === 'OK' && response.data.rows[0].elements[0].status === 'OK') {
          distanceInMeters = response.data.rows[0].elements[0].distance.value;
          durationInSeconds = response.data.rows[0].elements[0].duration.value;
        } else {
          throw new Error('Google API returned invalid response');
        }
      } catch (error) {
        console.error('Google Distance Matrix API error:', error.message);
        // Fallback to straight-line distance
        distanceInMeters = calculateStraightLineDistance(pickupLat, pickupLng, dropoffLat, dropoffLng);
        durationInSeconds = Math.floor((distanceInMeters / 500) * 60); // Rough estimate: 30km/h
      }
    } else {
      // Use straight-line distance if no API key
      distanceInMeters = calculateStraightLineDistance(pickupLat, pickupLng, dropoffLat, dropoffLng);
      durationInSeconds = Math.floor((distanceInMeters / 500) * 60);
    }

    // Get pricing rule from database or use fallback
    const pricingRule = await getPricingRuleFromDB(vehicleType);
    
    const priceConfig = pricingRule || {
      basePricePerKm: FALLBACK_PRICE_CONFIG.basePricePerKm[vehicleType] || 5000,
      minimumFare: FALLBACK_PRICE_CONFIG.minimumFare[vehicleType] || 15000,
      trainStationFee: FALLBACK_PRICE_CONFIG.servicePrices.train_station,
      extraWeightPerKg: FALLBACK_PRICE_CONFIG.servicePrices.extra_weight_per_kg,
      helperSmallFee: FALLBACK_PRICE_CONFIG.servicePrices.helper_small,
      helperLargeFee: FALLBACK_PRICE_CONFIG.servicePrices.helper_large,
      roundTripPercentage: FALLBACK_PRICE_CONFIG.servicePrices.round_trip_percentage,
      weightFactor: 1.0,
      distanceFactor: 1.0,
    };

    // Calculate pricing with factors
    const distanceInKm = (distanceInMeters / 1000) * priceConfig.distanceFactor;
    const basePricePerKm = priceConfig.basePricePerKm;
    const minimumFare = priceConfig.minimumFare;

    let baseFare = distanceInKm * basePricePerKm;
    if (baseFare < minimumFare) {
      baseFare = minimumFare;
    }

    // Apply weight factor if applicable
    if (extraWeight > 0 && priceConfig.weightFactor !== 1.0) {
      baseFare = baseFare * priceConfig.weightFactor;
    }

    // Calculate services cost
    let servicesCost = 0;
    const servicesApplied = [];

    if (services.train_station) {
      servicesCost += priceConfig.trainStationFee;
      servicesApplied.push(`Giao đến bến xe/nhà ga (+${formatPrice(priceConfig.trainStationFee)})`);
    }

    if (services.extra_weight && extraWeight > 0) {
      const extraWeightCost = extraWeight * priceConfig.extraWeightPerKg;
      servicesCost += extraWeightCost;
      servicesApplied.push(`Tăng trọng tải ${extraWeight}kg (+${formatPrice(extraWeightCost)})`);
    }

    if (services.helper) {
      const helperCost = vehicleType === 'van_1000' 
        ? priceConfig.helperLargeFee 
        : priceConfig.helperSmallFee;
      servicesCost += helperCost;
      servicesApplied.push(`Người phụ (+${formatPrice(helperCost)})`);
    }

    // Calculate subtotal
    const subtotal = baseFare + servicesCost;

    // Calculate round trip cost
    let roundTripCost = 0;
    if (services.round_trip) {
      roundTripCost = subtotal * priceConfig.roundTripPercentage;
      const percentage = Math.round(priceConfig.roundTripPercentage * 100);
      servicesApplied.push(`Khứ hồi (+${percentage}%)`);
    }

    // Calculate total
    const total = subtotal + roundTripCost;

    // Build response
    res.json({
      success: true,
      data: {
        distance: {
          value: distanceInMeters,
          text: `${(distanceInMeters / 1000).toFixed(1)} km`,
        },
        duration: {
          value: durationInSeconds,
          text: `${Math.floor(durationInSeconds / 60)} phút`,
        },
        pricing: {
          baseFare: Math.round(baseFare),
          servicesCost: Math.round(servicesCost),
          roundTripCost: Math.round(roundTripCost),
          subtotal: Math.round(subtotal),
          total: Math.round(total),
          servicesApplied,
          breakdown: {
            baseFareText: `Base fare: ${formatPrice(baseFare)}`,
            servicesText: servicesCost > 0 ? `Services: +${formatPrice(servicesCost)}` : null,
            roundTripText: roundTripCost > 0 ? `Round trip: +${formatPrice(roundTripCost)}` : null,
            totalText: `Total: ${formatPrice(total)}`,
          },
        },
      },
    });
  } catch (error) {
    console.error('Calculate price error:', error);
    res.status(500).json({
      success: false,
      message: 'Error calculating price',
      error: error.message,
    });
  }
};

// Calculate straight-line distance using Haversine formula
function calculateStraightLineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

// Format price for display
function formatPrice(price) {
  if (price >= 1000) {
    return `${Math.round(price / 1000)}k VND`;
  }
  return `${Math.round(price)} VND`;
}

// Create delivery order
exports.createDeliveryOrder = async (req, res) => {
  try {
    const {
      pickupLocation,
      dropoffLocation,
      vehicleType,
      vehicleName,
      distance,
      distanceText,
      duration,
      durationText,
      services,
      extraWeight,
      pricing,
      recipientName,
      recipientPhone,
      notes,
    } = req.body;

    // Validate required fields
    if (!pickupLocation || !dropoffLocation || !vehicleType || !recipientName || !recipientPhone) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: pickupLocation, dropoffLocation, vehicleType, recipientName, recipientPhone',
      });
    }

    // Get user ID from authenticated token
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    // Generate unique order number
    const orderNumber = `DLV-${Date.now()}-${uuidv4().substring(0, 8).toUpperCase()}`;

    console.log('Creating delivery order:', {
      orderNumber,
      userId,
      vehicleType,
      pickupLocation: pickupLocation?.address,
      dropoffLocation: dropoffLocation?.address,
    });

    // Insert order into database
    const result = await pool.query(
      `INSERT INTO orders (
        order_number, user_id, vehicle_type,
        pickup_address, pickup_lat, pickup_lng,
        delivery_address, delivery_lat, delivery_lng,
        recipient_name, recipient_phone,
        distance, duration,
        services, notes,
        base_fare, service_fee, total_amount,
        status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
      RETURNING *`,
      [
        orderNumber,
        userId,
        vehicleType,
        pickupLocation.address,
        pickupLocation.lat,
        pickupLocation.lng,
        dropoffLocation.address,
        dropoffLocation.lat,
        dropoffLocation.lng,
        recipientName,
        recipientPhone,
        distance,
        durationText || duration,
        JSON.stringify(services || []),
        notes || '',
        pricing?.baseFare || 0,
        pricing?.serviceFee || 0,
        pricing?.totalPrice || 0,
        'pending',
      ]
    );

    const order = result.rows[0];

    // Add initial status to history
    await pool.query(
      'INSERT INTO order_status_history (order_id, status, notes) VALUES ($1, $2, $3)',
      [order.id, 'pending', 'Đơn hàng đã được tạo']
    );

    // Initialize delivery tracking
    await pool.query(
      'INSERT INTO delivery_tracking (order_id, status) VALUES ($1, $2)',
      [order.id, 'preparing']
    );

    console.log('✅ Delivery order created successfully:', orderNumber);

    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      data: {
        orderId: order.id,
        orderNumber: order.order_number,
        pickupLocation,
        dropoffLocation,
        vehicleType,
        vehicleName,
        distance,
        distanceText,
        duration,
        durationText,
        services,
        extraWeight,
        pricing,
        recipientName,
        recipientPhone,
        notes,
        status: order.status,
        createdAt: order.created_at,
      },
    });
  } catch (error) {
    console.error('Create delivery order error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating order',
      error: error.message,
    });
  }
};
