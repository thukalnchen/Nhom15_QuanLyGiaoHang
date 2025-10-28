import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GoogleMapsService {
  // Using Nominatim API (OpenStreetMap) - 100% FREE!
  // No API key needed
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  // Get current location
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Get address suggestions using Nominatim (OpenStreetMap) - FREE!
  static Future<List<Map<String, dynamic>>> getAddressSuggestions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final url = Uri.parse(
      '$_nominatimBaseUrl/search'
      '?q=${Uri.encodeComponent(input)}'
      '&format=json'
      '&countrycodes=vn' // Limit to Vietnam
      '&limit=5'
      '&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LalamoveDeliveryApp/1.0', // Required by Nominatim
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((place) {
          return {
            'place_id': place['place_id'].toString(),
            'description': place['display_name'],
            'main_text': place['name'] ?? place['display_name'].split(',')[0],
            'secondary_text': place['display_name'].split(',').skip(1).join(',').trim(),
            'lat': double.parse(place['lat']),
            'lng': double.parse(place['lon']),
          };
        }).toList();
      }
    } catch (e) {
      print('Error getting address suggestions: $e');
    }
    return [];
  }

  // Get place details - for Nominatim, we already have lat/lng in search results
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_nominatimBaseUrl/lookup'
      '?osm_ids=N$placeId'
      '&format=json'
      '&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LalamoveDeliveryApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final place = data[0];
          return {
            'lat': double.parse(place['lat']),
            'lng': double.parse(place['lon']),
            'formatted_address': place['display_name'],
            'name': place['name'] ?? place['display_name'].split(',')[0],
          };
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
    return null;
  }

  // Calculate distance and duration between two points
  static Future<Map<String, dynamic>?> calculateDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    // Always use fallback calculation for now
    final distanceInMeters = Geolocator.distanceBetween(
      originLat,
      originLng,
      destLat,
      destLng,
    );
    return {
      'distance': {
        'value': distanceInMeters.toInt(),
        'text': '${(distanceInMeters / 1000).toStringAsFixed(1)} km',
      },
      'duration': {
        'value': (distanceInMeters / 500 * 60).toInt(), // Rough estimate: 30km/h average
        'text': '${(distanceInMeters / 500).toInt()} phút',
      },
    };
  }

  // Reverse geocoding - get address from coordinates using Nominatim
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    final url = Uri.parse(
      '$_nominatimBaseUrl/reverse'
      '?lat=$lat'
      '&lon=$lng'
      '&format=json'
      '&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LalamoveDeliveryApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'];
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }
}

// Price calculation service
class PriceCalculationService {
  // Base prices per km for each vehicle type
  static const Map<String, double> _basePricePerKm = {
    'motorcycle': 5000,    // 5k VND per km
    'van_500': 8000,       // 8k VND per km
    'van_750': 10000,      // 10k VND per km
    'van_1000': 12000,     // 12k VND per km
  };

  // Minimum fare
  static const Map<String, double> _minimumFare = {
    'motorcycle': 15000,
    'van_500': 30000,
    'van_750': 40000,
    'van_1000': 50000,
  };

  static Map<String, dynamic> calculatePrice({
    required String vehicleId,
    required double distanceInMeters,
    required Map<String, dynamic> selectedServices,
    double extraWeight = 0,
  }) {
    final distanceInKm = distanceInMeters / 1000;
    final basePricePerKm = _basePricePerKm[vehicleId] ?? 5000;
    final minimumFare = _minimumFare[vehicleId] ?? 15000;

    // Base fare
    double baseFare = distanceInKm * basePricePerKm;
    if (baseFare < minimumFare) {
      baseFare = minimumFare;
    }

    // Additional services cost
    double servicesCost = 0;
    List<String> servicesApplied = [];

    // Train station delivery
    if (selectedServices['train_station'] == true) {
      servicesCost += 20000;
      servicesApplied.add('Giao đến bến xe/nhà ga (+20k)');
    }

    // Extra weight
    if (selectedServices['extra_weight'] == true && extraWeight > 0) {
      final extraWeightCost = extraWeight * 10000;
      servicesCost += extraWeightCost;
      servicesApplied.add('Tăng trọng tải ${extraWeight.toInt()}kg (+${_formatPrice(extraWeightCost)})');
    }

    // Helper
    if (selectedServices['helper'] == true) {
      final helperCost = vehicleId == 'van_1000' ? 70000.0 : 50000.0;
      servicesCost += helperCost;
      servicesApplied.add('Người phụ (+${_formatPrice(helperCost)})');
    }

    // Subtotal
    double subtotal = baseFare + servicesCost;

    // Round trip (percentage increase)
    double roundTripCost = 0;
    if (selectedServices['round_trip'] == true) {
      roundTripCost = subtotal * 0.7; // 70% increase
      servicesApplied.add('Khứ hồi (+70%)');
    }

    // Total
    final total = subtotal + roundTripCost;

    return {
      'baseFare': baseFare,
      'servicesCost': servicesCost,
      'roundTripCost': roundTripCost,
      'subtotal': subtotal,
      'total': total,
      'servicesApplied': servicesApplied,
      'breakdown': {
        'distance': '${distanceInKm.toStringAsFixed(1)} km',
        'baseFare': _formatPrice(baseFare),
        'servicesCost': _formatPrice(servicesCost),
        'roundTripCost': _formatPrice(roundTripCost),
        'total': _formatPrice(total),
      },
    };
  }

  static String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M VND';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k VND';
    }
    return '${price.toStringAsFixed(0)} VND';
  }
}
