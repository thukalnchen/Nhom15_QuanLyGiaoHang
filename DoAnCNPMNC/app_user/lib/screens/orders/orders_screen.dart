import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có đơn hàng nào',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy tạo đơn hàng đầu tiên của bạn',
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
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/order-details',
                            arguments: order['id'],
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order['order_number'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppUtils.getStatusColor(order['status']),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      AppUtils.getStatusText(order['status']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order['restaurant_name'] ?? 'Nhà hàng',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppUtils.formatCurrency(order['total_amount']?.toDouble() ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
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
