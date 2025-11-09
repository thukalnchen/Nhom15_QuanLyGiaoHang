import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.token != null) {
      await orderProvider.getOrders(token: authProvider.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.tracking),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Filter orders that are being delivered
          final trackingOrders = orderProvider.orders.where((order) {
            final status = order['status'];
            return status == AppConstants.statusShipped || 
                   status == AppConstants.statusProcessing;
          }).toList();

          if (trackingOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có đơn hàng nào đang giao',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Các đơn hàng đang giao sẽ hiển thị ở đây',
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
            itemCount: trackingOrders.length,
            itemBuilder: (context, index) {
              final order = trackingOrders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                          fontSize: 16,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Mock tracking information
                      _TrackingStep(
                        title: 'Đơn hàng đã được xác nhận',
                        subtitle: 'Nhà hàng đang chuẩn bị món ăn',
                        isCompleted: true,
                        isActive: order['status'] == AppConstants.statusProcessing,
                      ),
                      const SizedBox(height: 8),
                      
                      _TrackingStep(
                        title: 'Đang chuẩn bị',
                        subtitle: 'Nhà hàng đang chuẩn bị món ăn',
                        isCompleted: order['status'] == AppConstants.statusShipped,
                        isActive: order['status'] == AppConstants.statusProcessing,
                      ),
                      const SizedBox(height: 8),
                      
                      _TrackingStep(
                        title: 'Đang giao hàng',
                        subtitle: 'Shipper đang trên đường đến',
                        isCompleted: false,
                        isActive: order['status'] == AppConstants.statusShipped,
                      ),
                      const SizedBox(height: 8),
                      
                      _TrackingStep(
                        title: 'Đã giao hàng',
                        subtitle: 'Đơn hàng đã được giao thành công',
                        isCompleted: false,
                        isActive: false,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Delivery Information
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin giao hàng',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Địa chỉ: ${order['delivery_address'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (order['delivery_phone'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'SĐT: ${order['delivery_phone']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/order-details',
                                  arguments: order['id'],
                                );
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Chi tiết'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showMapDialog(order);
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('Bản đồ'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMapDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Theo dõi ${order['order_number']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Icon(
                Icons.map_outlined,
                size: 100,
                color: AppColors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Tính năng bản đồ sẽ được tích hợp với Google Maps',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Địa chỉ giao hàng:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                order['delivery_address'] ?? 'N/A',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;

  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    Color stepColor = AppColors.grey;
    IconData stepIcon = Icons.radio_button_unchecked;
    
    if (isCompleted) {
      stepColor = AppColors.success;
      stepIcon = Icons.check_circle;
    } else if (isActive) {
      stepColor = AppColors.primary;
      stepIcon = Icons.radio_button_checked;
    }

    return Row(
      children: [
        Icon(
          stepIcon,
          color: stepColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primary : AppColors.dark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

