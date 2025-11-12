import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants.dart';
import '../../../services/admin_api_service.dart';
import '../../../providers/auth_provider.dart';

/// Story #20: Orders Management - Orders List Screen
class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      print('🔵 [STORY20] _loadOrders started');
      setState(() => _isLoading = true);
      
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      print('🔵 [STORY20] Token: ${token.substring(0, 20)}...');
      
      final orders = await AdminApiService.getAllOrders(token);
      print('🔵 [STORY20] Got ${orders.length} orders from API');
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
      print('✅ [STORY20] Orders loaded successfully');
    } catch (e) {
      print('❌ [STORY20] Lỗi tải đơn hàng: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Text('Không có đơn hàng nào'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(context, order);
                  },
                ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    Color statusColor = _getStatusColor(order['status']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showOrderDetails(context, order),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['order_number']?.toString() ?? 'N/A',
                    style: AppTextStyles.heading3,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _getStatusLabel(order['status']?.toString() ?? 'pending'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Người gửi: ${order['sender_name']?.toString() ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ngày: ${order['created_at']?.toString().substring(0, 10) ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order['total_amount']?.toString() ?? '0'} VND',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _updateOrderStatus(context, order),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Cập nhật'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'received_at_warehouse':
        return Colors.purple;
      case 'classified':
        return Colors.indigo;
      case 'assigned':
        return Colors.teal;
      case 'picked_up':
        return Colors.cyan;
      case 'in_delivery':
        return Colors.lightBlue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'received_at_warehouse':
        return 'Đã nhận tại kho';
      case 'classified':
        return 'Đã phân loại';
      case 'assigned':
        return 'Đã phân tài xế';
      case 'picked_up':
        return 'Đã lấy hàng';
      case 'in_delivery':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      case 'processing':
        return 'Đang xử lý';
      default:
        return status;
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết đơn hàng ${order['order_number']?.toString() ?? 'N/A'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người gửi: ${order['sender_name']?.toString() ?? 'N/A'}'),
            const SizedBox(height: AppSpacing.sm),
            Text('SĐT gửi: ${order['sender_phone']?.toString() ?? 'N/A'}'),
            const SizedBox(height: AppSpacing.sm),
            Text('Người nhận: ${order['receiver_name']?.toString() ?? 'N/A'}'),
            const SizedBox(height: AppSpacing.sm),
            Text('SĐT nhận: ${order['receiver_phone']?.toString() ?? 'N/A'}'),
            const SizedBox(height: AppSpacing.sm),
            Text('Trạng thái: ${_getStatusLabel(order['status']?.toString() ?? 'pending')}'),
            const SizedBox(height: AppSpacing.sm),
            Text('Tổng tiền: ${order['total_amount']?.toString() ?? '0'} VND'),
            const SizedBox(height: AppSpacing.sm),
            Text('Ngày: ${order['created_at']?.toString().substring(0, 10) ?? 'N/A'}'),
          ],
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

  void _updateOrderStatus(BuildContext context, Map<String, dynamic> order) {
    final currentStatus = order['status']?.toString() ?? 'pending';
    
    // Cannot update if delivered or cancelled
    if (currentStatus == 'delivered') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật đơn hàng đã giao thành công'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (currentStatus == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật đơn hàng đã hủy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Get all possible statuses (admin can choose freely)
    final allStatuses = _getAllAvailableStatuses(currentStatus);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật từ: ${_getStatusLabel(currentStatus)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...allStatuses.map((status) => ListTile(
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                title: Text(_getStatusLabel(status)),
                subtitle: status == 'cancelled' && !_canCancel(currentStatus)
                    ? const Text(
                        'Không thể hủy đơn này',
                        style: TextStyle(color: Colors.red, fontSize: 11),
                      )
                    : null,
                enabled: status == 'cancelled' ? _canCancel(currentStatus) : true,
                onTap: status == 'cancelled' && !_canCancel(currentStatus)
                    ? null
                    : () => _updateStatus(context, order, status),
              )).toList(),
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

  List<String> _getAllAvailableStatuses(String currentStatus) {
    // Admin can select all statuses except current one
    final allStatuses = [
      'pending',
      'confirmed',
      'received_at_warehouse',
      'classified',
      'assigned',
      'picked_up',
      'in_delivery',
      'delivered',
      'cancelled',
    ];
    
    // Remove current status from list
    return allStatuses.where((s) => s != currentStatus).toList();
  }

  bool _canCancel(String currentStatus) {
    // Cannot cancel if order is too far in the process
    final cannotCancelStatuses = [
      'received_at_warehouse',
      'classified',
      'assigned',
      'picked_up',
      'in_delivery',
      'delivered',
    ];
    
    return !cannotCancelStatuses.contains(currentStatus);
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'received_at_warehouse':
        return Icons.warehouse;
      case 'classified':
        return Icons.category;
      case 'assigned':
        return Icons.person_pin;
      case 'picked_up':
        return Icons.local_shipping;
      case 'in_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _updateStatus(BuildContext context, Map<String, dynamic> order, String newStatus) async {
    Navigator.pop(context); // Close dialog first
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final orderId = order['id'].toString(); // Convert to string
      
      print('🔵 [STORY20] Updating order $orderId to status: $newStatus');
      
      final result = await AdminApiService.updateOrderStatus(
        token,
        orderId,
        newStatus,
      );
      
      final success = result['success'] ?? false;
      final message = result['message'] ?? '';
      
      print('🔵 [STORY20] Update result: $success');
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
        // Reload orders to get updated data
        _loadOrders();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
