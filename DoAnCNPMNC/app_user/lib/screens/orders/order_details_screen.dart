import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.token != null) {
      await orderProvider.getOrderDetails(widget.orderId, authProvider.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
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

          if (orderProvider.currentOrder == null) {
            return const Center(
              child: Text('Không tìm thấy đơn hàng'),
            );
          }

          final order = orderProvider.currentOrder!;
          final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Card(
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
                                fontSize: 20,
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
                        const SizedBox(height: 8),
                        Text(
                          'Ngày đặt: ${AppUtils.formatDateTime(DateTime.parse(order['created_at']))}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items
                const Text(
                  'Sản phẩm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Card(
                  child: Column(
                    children: items.map((item) {
                      return ListTile(
                        title: Text(item['name'] ?? 'Sản phẩm'),
                        subtitle: Text('Số lượng: ${item['quantity']}'),
                        trailing: Text(
                          AppUtils.formatCurrency(item['price'] * item['quantity']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Information
                const Text(
                  'Thông tin giao hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          label: 'Địa chỉ',
                          value: order['delivery_address'] ?? 'N/A',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Số điện thoại',
                          value: order['delivery_phone'] ?? 'N/A',
                        ),
                        if (order['notes'] != null && order['notes'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Ghi chú',
                            value: order['notes'],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Order Summary
                const Text(
                  'Tóm tắt đơn hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính'),
                            Text(AppUtils.formatCurrency(
                              items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']))
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(AppTexts.deliveryFee),
                            Text(AppUtils.formatCurrency(order['delivery_fee']?.toDouble() ?? 0)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              AppTexts.total,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              AppUtils.formatCurrency(order['total_amount']?.toDouble() ?? 0),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status History
                if (order['status_history'] != null) ...[
                  const Text(
                    'Lịch sử trạng thái',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Card(
                    child: Column(
                      children: List<Map<String, dynamic>>.from(order['status_history'])
                          .map((history) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppUtils.getStatusColor(history['status']),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(AppUtils.getStatusText(history['status'])),
                          subtitle: Text(history['notes'] ?? ''),
                          trailing: Text(
                            AppUtils.formatDateTime(DateTime.parse(history['created_at'])),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
