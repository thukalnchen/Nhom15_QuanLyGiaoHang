import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/vehicle_type.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants.dart';

class LalamoveOrderSummaryScreen extends StatefulWidget {
  final VehicleType vehicle;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;
  final Map<String, dynamic> distanceData;
  final Map<String, dynamic> priceData;
  final Map<String, bool> selectedServices;
  final double extraWeight;

  const LalamoveOrderSummaryScreen({
    super.key,
    required this.vehicle,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distanceData,
    required this.priceData,
    required this.selectedServices,
    required this.extraWeight,
  });

  @override
  State<LalamoveOrderSummaryScreen> createState() => _LalamoveOrderSummaryScreenState();
}

class _LalamoveOrderSummaryScreenState extends State<LalamoveOrderSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    print('🔵 _submitOrder: Confirm Order clicked!');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ _submitOrder: Form validation failed');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      print('✅ _submitOrder: Preparing order data...');
      print('   Pickup: ${widget.pickupLocation['address']}');
      print('   Dropoff: ${widget.dropoffLocation['address']}');
      print('   Vehicle: ${widget.vehicle.name}');
      print('   Total: ${widget.priceData['total']}đ');
      
      // Call API to create order using OrderProvider.createOrder
      final success = await orderProvider.createOrder(
        restaurantName: widget.pickupLocation['address'] ?? 'Pickup Location',
        items: [
          {
            'name': 'Delivery Service - ${widget.vehicle.name}',
            'quantity': 1,
            'price': widget.priceData['total'] ?? 0,
          }
        ],
        totalAmount: (widget.priceData['total'] ?? 0).toDouble(),
        deliveryAddress: widget.dropoffLocation['address'] ?? '',
        deliveryFee: (widget.priceData['baseFare'] ?? 0).toDouble(),
        deliveryPhone: _recipientPhoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? 'Distance: ${widget.distanceData['distance']['text']}, Duration: ${widget.distanceData['duration']['text']}'
            : _notesController.text.trim(),
        token: authProvider.token,
      );

      if (mounted) {
        if (success) {
          print('✅ _submitOrder: Order created successfully!');
          
          // Reload orders
          await orderProvider.getOrders(token: authProvider.token);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Navigate back to home
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          print('❌ _submitOrder: Order creation failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.error ?? 'Failed to create order'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ _submitOrder: Exception - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
          'Order Summary',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Information
                    _buildRouteCard(),
                    const SizedBox(height: 16),

                    // Vehicle Information
                    _buildVehicleCard(),
                    const SizedBox(height: 16),

                    // Additional Services
                    if (_hasServices()) ...[
                      _buildServicesCard(),
                      const SizedBox(height: 16),
                    ],

                    // Recipient Information
                    _buildRecipientForm(),
                    const SizedBox(height: 16),

                    // Notes
                    _buildNotesField(),
                    const SizedBox(height: 16),

                    // Price Breakdown
                    _buildPriceBreakdown(),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  bool _hasServices() {
    return widget.selectedServices.values.any((selected) => selected);
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Route',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pick-up',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.pickupLocation['fullAddress'] ?? widget.pickupLocation['address'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Connecting line
          Container(
            margin: const EdgeInsets.only(left: 5),
            width: 2,
            height: 24,
            color: AppColors.lightGrey,
          ),
          
          // Dropoff
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drop-off',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.dropoffLocation['fullAddress'] ?? widget.dropoffLocation['address'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 32),
          
          // Distance and Duration
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.straighten,
                  label: widget.distanceData['distance']['text'],
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.access_time,
                  label: widget.distanceData['duration']['text'],
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.vehicle.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicle.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.vehicle.maxWeight} • ${widget.vehicle.dimensions}',
                  style: const TextStyle(
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

  Widget _buildServicesCard() {
    final services = widget.priceData['servicesApplied'] as List<String>? ?? [];
    
    if (services.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          ...services.map((service) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecipientForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recipient Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Recipient Name
          TextFormField(
            controller: _recipientNameController,
            decoration: InputDecoration(
              labelText: 'Recipient Name',
              hintText: 'Enter recipient name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter recipient name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Recipient Phone
          TextFormField(
            controller: _recipientPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Recipient Phone',
              hintText: 'Enter phone number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              if (value.trim().length < 10) {
                return 'Please enter valid phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any special instructions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final baseFare = widget.priceData['baseFare'] ?? 0;
    final servicesCost = widget.priceData['servicesCost'] ?? 0;
    final roundTripCost = widget.priceData['roundTripCost'] ?? 0;
    final total = widget.priceData['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildPriceRow('Base fare', baseFare, isSubtotal: false),
          
          if (servicesCost > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Services', servicesCost, isSubtotal: false, isPositive: true),
          ],
          
          if (roundTripCost > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Round trip (+70%)', roundTripCost, isSubtotal: false, isPositive: true),
          ],
          
          const Divider(height: 24),
          
          _buildPriceRow('Total', total, isSubtotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {required bool isSubtotal, bool isPositive = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSubtotal ? 16 : 14,
            fontWeight: isSubtotal ? FontWeight.bold : FontWeight.normal,
            color: isSubtotal ? AppColors.dark : AppColors.grey,
          ),
        ),
        Text(
          '${isPositive && !isSubtotal ? '+' : ''}${amount.toStringAsFixed(0)}đ',
          style: TextStyle(
            fontSize: isSubtotal ? 18 : 14,
            fontWeight: isSubtotal ? FontWeight.bold : FontWeight.w600,
            color: isSubtotal ? AppColors.primary : AppColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final total = widget.priceData['total'] ?? 0;
    
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${total.toStringAsFixed(0)}đ',
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
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.grey,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

