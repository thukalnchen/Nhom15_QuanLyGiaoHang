import 'package:flutter/material.dart';
import '../../../models/vehicle_type.dart';
import '../../../utils/constants.dart';
import '../../../services/maps_service.dart';
import '../orders/lalamove_order_summary_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final VehicleType vehicle;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;

  const VehicleSelectionScreen({
    super.key,
    required this.vehicle,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final Map<String, bool> _selectedServices = {};
  double _extraWeight = 0;
  
  // Distance and price data
  Map<String, dynamic>? _distanceData;
  Map<String, dynamic>? _priceData;
  bool _isLoadingPrice = false;

  @override
  void initState() {
    super.initState();
    // Initialize all services as unselected
    for (var service in widget.vehicle.additionalServices) {
      _selectedServices[service.id] = false;
    }
    _calculateDistanceAndPrice();
  }

  Future<void> _calculateDistanceAndPrice() async {
    print('🚀 [AUTO CALCULATE] Bắt đầu tính toán tự động...');
    print('📍 Pickup: lat=${widget.pickupLocation['lat']}, lng=${widget.pickupLocation['lng']}');
    print('📍 Dropoff: lat=${widget.dropoffLocation['lat']}, lng=${widget.dropoffLocation['lng']}');
    
    setState(() {
      _isLoadingPrice = true;
    });

    try {
      // Calculate distance
      print('⏳ Đang tính khoảng cách bằng công thức Haversine...');
      final distance = await GoogleMapsService.calculateDistance(
        originLat: widget.pickupLocation['lat'],
        originLng: widget.pickupLocation['lng'],
        destLat: widget.dropoffLocation['lat'],
        destLng: widget.dropoffLocation['lng'],
      );

      if (distance != null) {
        print('✅ Khoảng cách: ${distance['distance']['text']}');
        print('✅ Thời gian: ${distance['duration']['text']}');
        
        setState(() {
          _distanceData = distance;
        });

        // Calculate initial price
        print('💰 Đang tính giá cơ bản...');
        _updatePrice();
      } else {
        print('❌ Không tính được khoảng cách!');
      }
    } catch (e) {
      print('❌ LỖI khi tính khoảng cách: $e');
      debugPrint('Error calculating distance: $e');
    } finally {
      setState(() {
        _isLoadingPrice = false;
      });
    }
  }

  void _updatePrice() {
    if (_distanceData == null) {
      print('⚠️ Chưa có dữ liệu khoảng cách, không thể tính giá!');
      return;
    }

    final distanceInMeters = _distanceData!['distance']['value'].toDouble();
    print('📏 Distance in meters: $distanceInMeters m');

    final price = PriceCalculationService.calculatePrice(
      vehicleId: widget.vehicle.id,
      distanceInMeters: distanceInMeters,
      selectedServices: _selectedServices,
      extraWeight: _extraWeight,
    );

    print('💵 GIÁ ĐÃ TÍNH:');
    print('   - Base fare: ${price['baseFare']}đ');
    print('   - Services cost: ${price['servicesCost']}đ');
    print('   - Round trip: ${price['roundTripCost']}đ');
    print('   - TOTAL: ${price['total']}đ ✅');

    setState(() {
      _priceData = price;
    });
  }

  double _calculateTotalPrice() {
    double total = 0;
    
    for (var service in widget.vehicle.additionalServices) {
      if (_selectedServices[service.id] == true) {
        if (service.id == 'extra_weight') {
          total += _extraWeight * 10000; // 10k per kg
        } else if (!service.isPercentage) {
          total += service.price;
        }
      }
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Vehicle',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.dark),
      ),
      body: Column(
        children: [
          // Route Info Card
          _buildRouteInfo(),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Header Card
                  _buildVehicleHeader(),
                  
                  const SizedBox(height: 8),
                  
                  // Vehicle Specifications
                  _buildSpecifications(),
                  
                  const SizedBox(height: 8),
                  
                  // Additional Services
                  if (widget.vehicle.additionalServices.isNotEmpty)
                    _buildAdditionalServices(),
                ],
              ),
            ),
          ),
          
          // Bottom Bar with Total Price
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.circle_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.pickupLocation['name'] ?? widget.pickupLocation['address'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.dropoffLocation['name'] ?? widget.dropoffLocation['address'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_distanceData != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.straighten, color: AppColors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _distanceData!['distance']['text'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _distanceData!['duration']['text'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (_isLoadingPrice)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vehicle Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.vehicle.icon,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Vehicle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicle.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.vehicle.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Specifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSpecRow(
            Icons.straighten,
            'Dimensions',
            widget.vehicle.dimensions,
          ),
          const SizedBox(height: 12),
          
          _buildSpecRow(
            Icons.scale,
            'Max Weight',
            '${widget.vehicle.maxWeight} kg',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalServices() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          
          ...widget.vehicle.additionalServices.map((service) {
            if (service.id == 'extra_weight') {
              return _buildExtraWeightService(service);
            } else if (service.id == 'round_trip') {
              return _buildRoundTripService(service);
            } else {
              return _buildCheckboxService(service);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildCheckboxService(AdditionalService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: _selectedServices[service.id] ?? false,
            onChanged: (value) {
              print('🔄 [SERVICE TOGGLE] User thay đổi service: ${service.name}');
              print('   - Service ID: ${service.id}');
              print('   - New value: $value');
              setState(() {
                _selectedServices[service.id] = value ?? false;
                print('⏳ Đang tính lại giá real-time...');
                _updatePrice();
              });
            },
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                if (!service.isPercentage)
                  Text(
                    '+${_formatPrice(service.price)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraWeightService(AdditionalService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _selectedServices[service.id] ?? false,
                onChanged: (value) {
                  setState(() {
                    _selectedServices[service.id] = value ?? false;
                    if (value == false) {
                      _extraWeight = 0;
                    }
                    _updatePrice();
                  });
                },
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          
          if (_selectedServices[service.id] == true) ...[
            const SizedBox(height: 8),
            Text(
              'Weight: ${_extraWeight.toStringAsFixed(0)} kg',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
            Slider(
              value: _extraWeight,
              min: 0,
              max: 50,
              divisions: 50,
              activeColor: AppColors.primary,
              label: '${_extraWeight.toStringAsFixed(0)} kg',
              onChanged: (value) {
                setState(() {
                  _extraWeight = value;
                });
              },
              onChangeEnd: (value) {
                _updatePrice();
              },
            ),
            Text(
              '+${_formatPrice(_extraWeight * 10000)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundTripService(AdditionalService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  '+${service.price.toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _selectedServices[service.id] ?? false,
            onChanged: (value) {
              setState(() {
                _selectedServices[service.id] = value;
                _updatePrice();
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalPrice = _priceData?['total'] ?? 0;
    final baseFare = _priceData?['baseFare'] ?? 0;
    final servicesCost = _priceData?['servicesCost'] ?? 0;
    final roundTripCost = _priceData?['roundTripCost'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price Breakdown
            if (_priceData != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Base fare',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    '${baseFare.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
              if (servicesCost > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    Text(
                      '+${servicesCost.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
              if (roundTripCost > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Round trip (+70%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    Text(
                      '+${roundTripCost.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16),
            ],
            
            // Total and Continue Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Total',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingPrice
                            ? 'Calculating...'
                            : '${totalPrice.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoadingPrice || _priceData == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LalamoveOrderSummaryScreen(
                                vehicle: widget.vehicle,
                                pickupLocation: widget.pickupLocation,
                                dropoffLocation: widget.dropoffLocation,
                                distanceData: _distanceData!,
                                priceData: _priceData!,
                                selectedServices: _selectedServices,
                                extraWeight: _extraWeight,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k VND';
    }
    return '${price.toStringAsFixed(0)} VND';
  }
}

