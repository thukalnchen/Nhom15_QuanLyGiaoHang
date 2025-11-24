import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../tracking/order_tracking_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _orderDetails = widget.order;
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final token = authProvider.token;
    
    if (token == null || _orderDetails == null) return;

    setState(() => _isLoading = true);

    final orderId = _orderDetails!['id'];
    if (orderId != null) {
      final success = await orderProvider.getOrderDetails(
        int.parse(orderId.toString()),
        token,
      );

      if (success && orderProvider.currentOrder != null) {
        setState(() {
          _orderDetails = orderProvider.currentOrder;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _orderDetails ?? widget.order;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(order['order_number'] ?? 'Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.dark),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrderDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppUtils.getStatusColor(order['status']),
                            AppUtils.getStatusColor(order['status']).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppUtils.getStatusColor(order['status']).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStatusIcon(order['status']),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppUtils.getStatusText(order['status']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusDescription(order['status']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Status Timeline Section
                    if (order['status_history'] != null && 
                        (order['status_history'] as List).isNotEmpty)
                      _buildStatusTimeline(order['status_history'] as List),

                    // Order Info Section
                    _buildSection(
                      title: 'Thông tin đơn hàng',
                      icon: Icons.receipt_long,
                      child: Column(
                        children: [
                          _buildInfoRow('Mã đơn hàng', order['order_number'] ?? 'N/A'),
                          _buildInfoRow(
                            'Thời gian đặt',
                            AppUtils.formatDateTime(DateTime.parse(order['created_at'])),
                          ),
                          _buildInfoRow('Loại xe', _getVehicleText(order['vehicle_type'])),
                          if (order['distance'] != null)
                            _buildInfoRow('Khoảng cách', '${order['distance']} km'),
                          if (order['duration'] != null)
                            _buildInfoRow('Thời gian dự kiến', order['duration']),
                        ],
                      ),
                    ),

                    // QR Code Section - For warehouse staff to scan
                    _buildSection(
              title: 'Mã QR đơn hàng',
              icon: Icons.qr_code_2,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: QrImageView(
                      data: order['order_code'] ?? order['order_number'] ?? '',
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order['order_code'] ?? order['order_number'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📱 Quét mã này tại kho để nhận hàng',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

                    // Route Section
                    _buildSection(
              title: 'Tuyến đường',
              icon: Icons.route,
              child: Column(
                children: [
                  _buildRoutePoint(
                    icon: Icons.circle,
                    iconColor: AppColors.primary,
                    title: 'Điểm đón hàng',
                    address: order['pickup_address'] ?? 'Không có thông tin',
                    isFirst: true,
                  ),
                  _buildRoutePoint(
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    title: 'Điểm giao hàng',
                    address: order['delivery_address'] ?? 'Không có thông tin',
                    isFirst: false,
                  ),
                ],
              ),
            ),

                    // Recipient Info
                    if (order['recipient_name'] != null || order['recipient_phone'] != null)
                      _buildSection(
                title: 'Thông tin người nhận',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    if (order['recipient_name'] != null)
                      _buildInfoRow('Tên người nhận', order['recipient_name']),
                    if (order['recipient_phone'] != null)
                      _buildInfoRow('Số điện thoại', order['recipient_phone']),
                  ],
                ),
              ),

                    // Services Section
                    if (order['services'] != null && (order['services'] as List).isNotEmpty)
                      _buildSection(
                title: 'Dịch vụ thêm',
                icon: Icons.miscellaneous_services,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (order['services'] as List).map<Widget>((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        service.toString(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

                    // Notes Section
                    if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                      _buildSection(
                title: 'Ghi chú',
                icon: Icons.note_alt_outlined,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order['notes'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.dark,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

                    // Price Breakdown Section
                    _buildSection(
              title: 'Chi tiết giá',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  if (order['base_fare'] != null)
                    _buildPriceRow(
                      'Cước phí cơ bản',
                      order['base_fare'].toDouble(),
                    ),
                  if (order['service_fee'] != null && order['service_fee'] > 0)
                    _buildPriceRow(
                      'Phí dịch vụ',
                      order['service_fee'].toDouble(),
                    ),
                  if (order['discount'] != null && order['discount'] > 0)
                    _buildPriceRow(
                      'Giảm giá',
                      -order['discount'].toDouble(),
                      color: Colors.green,
                    ),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Tổng cộng',
                    order['total_amount']?.toDouble() ?? 0,
                    isTotal: true,
                  ),
                ],
              ),
            ),

                    // Driver Info (if assigned)
                    if (order['driver_name'] != null)
                      _buildSection(
                title: 'Thông tin tài xế',
                icon: Icons.person,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['driver_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (order['driver_phone'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              order['driver_phone'],
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (order['driver_phone'] != null)
                      IconButton(
                        onPressed: () {
                          // TODO: Call driver
                        },
                        icon: const Icon(Icons.phone, color: AppColors.primary),
                      ),
                  ],
                ),
              ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      
      // Bottom Action Buttons
      bottomNavigationBar: _isLoading ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if ((order['status'] == AppConstants.statusPending || 
                   order['status'] == 'pending')) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy đơn',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(order: order),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Theo dõi đơn hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    required bool isFirst,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: AppColors.lightGrey,
              ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isFirst ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.dark,
            ),
          ),
          Text(
            AppUtils.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isTotal ? AppColors.primary : AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.access_time;
      case AppConstants.statusProcessing:
        return Icons.local_shipping;
      case AppConstants.statusShipped:
        return Icons.delivery_dining;
      case AppConstants.statusDelivered:
        return Icons.check_circle;
      case AppConstants.statusCancelled:
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getStatusDescription(String? status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Đơn hàng đang chờ xác nhận';
      case AppConstants.statusProcessing:
        return 'Đang tìm tài xế';
      case AppConstants.statusShipped:
        return 'Đang trên đường giao hàng';
      case AppConstants.statusDelivered:
        return 'Đã giao hàng thành công';
      case AppConstants.statusCancelled:
        return 'Đơn hàng đã bị hủy';
      default:
        return '';
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

  Widget _buildStatusTimeline(List<dynamic> statusHistory) {
    if (statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by created_at to ensure chronological order
    final sortedHistory = List<Map<String, dynamic>>.from(statusHistory)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] ?? '');
        final dateB = DateTime.parse(b['created_at'] ?? '');
        return dateA.compareTo(dateB);
      });

    return _buildSection(
      title: 'Lịch sử trạng thái',
      icon: Icons.timeline,
      child: Column(
        children: List.generate(sortedHistory.length, (index) {
          final historyItem = sortedHistory[index];
          final isLast = index == sortedHistory.length - 1;
          final status = historyItem['status']?.toString() ?? '';
          final notes = historyItem['notes']?.toString();
          final reason = historyItem['reason']?.toString();
          final createdAt = historyItem['created_at']?.toString();
          
          DateTime? dateTime;
          if (createdAt != null) {
            try {
              dateTime = DateTime.parse(createdAt);
            } catch (e) {
              dateTime = null;
            }
          }

          return _buildTimelineItem(
            status: status,
            notes: notes,
            reason: reason,
            dateTime: dateTime,
            isLast: isLast,
            isCompleted: true, // All past statuses are completed
          );
        }),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String status,
    String? notes,
    String? reason,
    DateTime? dateTime,
    required bool isLast,
    required bool isCompleted,
  }) {
    final statusText = _getStatusDisplayText(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIconForTimeline(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor,
                  width: 2,
                ),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.lightGrey,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (dateTime != null)
                      Text(
                        _formatTime(dateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
                if (dateTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(dateTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.dark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lý do: $reason',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'warehouse_received':
        return 'Đã nhận vào kho';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'ready_for_pickup':
        return 'Sẵn sàng lấy hàng';
      case 'picked_up':
        return 'Đã lấy hàng';
      case 'in_transit':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      case 'returned':
        return 'Đã trả lại';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'warehouse_received':
      case 'preparing':
        return AppColors.info;
      case 'ready_for_pickup':
      case 'picked_up':
        return AppColors.primary;
      case 'in_transit':
        return AppColors.primaryDark;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
      case 'returned':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  IconData _getStatusIconForTimeline(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'warehouse_received':
        return Icons.warehouse;
      case 'preparing':
        return Icons.build_circle_outlined;
      case 'ready_for_pickup':
        return Icons.shopping_bag_outlined;
      case 'picked_up':
        return Icons.inventory_2_outlined;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'returned':
        return Icons.undo;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Hôm nay';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Cancel order
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Hủy đơn',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

