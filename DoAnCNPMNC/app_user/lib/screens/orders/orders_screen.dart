import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'order_details_screen.dart';
import 'cancel_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedStatus = '';

  IconData _getVehicleIcon(String? vehicleType) {
    switch (vehicleType) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'van_500':
      case 'van_750':
      case 'van_1000':
        return Icons.local_shipping;
      default:
        return Icons.delivery_dining;
    }
  }

  String _getVehicleText(String? vehicleType) {
    switch (vehicleType) {
      case 'motorcycle':
        return '🏍️ Xe máy';
      case 'van_500':
        return '🚚 Van 500kg';
      case 'van_750':
        return '🚚 Van 750kg';
      case 'van_1000':
        return '🚚 Van 1000kg';
      default:
        return 'Xe giao hàng';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.token != null) {
      await orderProvider.getOrders(
        token: authProvider.token,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.myOrders),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tất cả',
                    isSelected: _selectedStatus.isEmpty,
                    onSelected: () {
                      setState(() {
                        _selectedStatus = '';
                      });
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppTexts.pending,
                    isSelected: _selectedStatus == AppConstants.statusPending,
                    onSelected: () {
                      setState(() {
                        _selectedStatus = AppConstants.statusPending;
                      });
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppTexts.processing,
                    isSelected: _selectedStatus == AppConstants.statusProcessing,
                    onSelected: () {
                      setState(() {
                        _selectedStatus = AppConstants.statusProcessing;
                      });
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppTexts.shipped,
                    isSelected: _selectedStatus == AppConstants.statusShipped,
                    onSelected: () {
                      setState(() {
                        _selectedStatus = AppConstants.statusShipped;
                      });
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppTexts.delivered,
                    isSelected: _selectedStatus == AppConstants.statusDelivered,
                    onSelected: () {
                      setState(() {
                        _selectedStatus = AppConstants.statusDelivered;
                      });
                      _loadOrders();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Orders List
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (orderProvider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Không có đơn hàng nào',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy tạo đơn giao hàng đầu tiên của bạn',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orderProvider.orders.length,
                  itemBuilder: (context, index) {
                    final order = orderProvider.orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.lightGrey, width: 1),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Navigate to order details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(order: order),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Icon + Order Number + Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppUtils.getStatusColor(order['status']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getVehicleIcon(order['vehicle_type']),
                                          color: AppUtils.getStatusColor(order['status']),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order['order_number'] ?? 'ORD-XXXX',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getVehicleText(order['vehicle_type']),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppUtils.getStatusColor(order['status']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      AppUtils.getStatusText(order['status']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Route Info
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 2,
                                        height: 30,
                                        color: AppColors.lightGrey,
                                      ),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order['pickup_address'] ?? 'Địa chỉ đón hàng',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          order['delivery_address'] ?? 'Địa chỉ giao hàng',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              
                              // Footer: Price + Time + Cancel Button + Arrow
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppUtils.formatCurrency(order['total_amount']?.toDouble() ?? 0),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: AppColors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppUtils.formatDateTime(
                                                DateTime.parse(order['created_at']),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Show cancel button if order can be cancelled
                                  if (_canCancelOrder(order['status']))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showCancelDialog(order),
                                        icon: const Icon(Icons.cancel_outlined, size: 16),
                                        label: const Text('Hủy'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: AppColors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _canCancelOrder(String status) {
    final cannotCancelStatuses = ['delivered', 'cancelled', 'shipped', 'in_transit'];
    return !cannotCancelStatuses.contains(status);
  }

  Future<void> _showCancelDialog(Map<String, dynamic> order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CancelOrderScreen(order: order),
      ),
    );

    // If cancellation was successful, refresh the orders list
    if (result == true) {
      _loadOrders();
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
