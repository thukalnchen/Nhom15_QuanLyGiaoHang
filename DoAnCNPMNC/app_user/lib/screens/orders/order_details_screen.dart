import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(order['order_number'] ?? 'Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.dark),
      ),
      body: SingleChildScrollView(
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
      
      // Bottom Action Buttons
      bottomNavigationBar: Container(
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
              if (order['status'] == AppConstants.statusPending) ...[
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
                    // TODO: Track order
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
