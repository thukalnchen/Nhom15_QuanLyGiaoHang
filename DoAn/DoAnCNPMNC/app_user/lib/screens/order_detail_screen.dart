import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'feedback_form_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final Order? initialOrder;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingPayment = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _isLoading = widget.initialOrder == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail(forceRefresh: true);
    });
  }

  Future<void> _loadDetail({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    setState(() {
      _isLoading = true;
      if (forceRefresh) {
        _error = null;
      }
    });
    try {
      final order = await OrderService.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipping':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.settings;
      case 'shipping':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTransactionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.redAccent;
      case 'expired':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _describeRemainingTime(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);
    if (difference.isNegative) {
      final minutes = difference.inMinutes.abs();
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final remainMinutes = minutes % 60;
        return 'đã quá hạn ${hours}h${remainMinutes.toString().padLeft(2, '0')}p';
      }
      return 'đã quá hạn $minutes phút';
    }
    final minutes = difference.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainMinutes = minutes % 60;
      return 'còn khoảng ${hours}h${remainMinutes.toString().padLeft(2, '0')}p';
    }
    return 'còn khoảng $minutes phút';
  }

  Future<void> _copyToClipboard(String value, {String? message}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Đã sao chép'),
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở đường dẫn thanh toán')),
      );
    }
  }

  String _getServiceLabel(String value) {
    switch (value.toLowerCase()) {
      case 'express':
        return 'Hỏa tốc';
      case 'economy':
        return 'Tiết kiệm';
      default:
        return 'Tiêu chuẩn';
    }
  }

  Future<void> _initiatePayment() async {
    final order = _order;
    if (order == null) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final result = await OrderService.initiateOnlinePayment(order.id);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          final expiresText = result.expiresAt != null
              ? '${_dateFormat.format(result.expiresAt!)} (${_describeRemainingTime(result.expiresAt!)})'
              : 'Không xác định';
          return AlertDialog(
            title: const Text('Khởi tạo thanh toán online'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số tiền: ${_currencyFormat.format(result.amount)}'),
                const SizedBox(height: 8),
                Text('Mã tham chiếu: ${result.reference}'),
                const SizedBox(height: 12),
                if (result.provider != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Gateway: ${result.provider!.toUpperCase()}'),
                  ),
                if (result.status != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Trạng thái hiện tại: ${result.status}'),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Hết hạn: $expiresText'),
                ),
                Text(
                  'Bạn có thể mở URL bên dưới trên trình duyệt và sau đó gọi API webhook (POST /api/payment/webhook) với reference tương ứng để giả lập thanh toán thành công.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  result.paymentUrl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
                if ((result.signature ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Chữ ký (signature):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SelectableText(
                    result.signature!,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => _copyToClipboard(
                  result.paymentUrl,
                  message: 'Đã sao chép URL thanh toán',
                ),
                child: const Text('Sao chép URL'),
              ),
              if ((result.signature ?? '').isNotEmpty)
                TextButton(
                  onPressed: () => _copyToClipboard(
                    result.signature!,
                    message: 'Đã sao chép signature',
                  ),
                  child: const Text('Copy signature'),
                ),
              TextButton(
                onPressed: () => _launchExternalUrl(result.paymentUrl),
                child: const Text('Mở trình duyệt'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đã hiểu'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
        await _loadDetail(forceRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final statusColor = _getStatusColor(order?.status ?? 'pending');
    final statusIcon = _getStatusIcon(order?.status ?? 'pending');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDetail(forceRefresh: true),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Không thể tải dữ liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadDetail(forceRefresh: true),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadDetail(forceRefresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.05 * 255).round()),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(statusIcon, size: 48, color: statusColor),
                              const SizedBox(height: 12),
                              Text(
                                order!.getStatusText(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.trackingNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withAlpha((0.08 * 255).round()),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Thanh toán: ${order.getPaymentStatusText()}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (order.statusHistory.isNotEmpty)
                          _buildSection(
                            title: 'Theo dõi trạng thái',
                            children: [
                              _buildTimeline(order.statusHistory),
                            ],
                          ),
                        _buildSection(
                          title: 'Thông tin vận đơn',
                          children: [
                            _buildInfoRow('Mã vận đơn', order.trackingNumber),
                            _buildInfoRow('Ngày tạo', _dateFormat.format(order.createdAt)),
                            _buildInfoRow('Cập nhật lần cuối', _dateFormat.format(order.updatedAt)),
                            if (order.estimatedPickup != null)
                              _buildInfoRow('Dự kiến lấy hàng', _dateFormat.format(order.estimatedPickup!)),
                            if (order.estimatedDelivery != null)
                              _buildInfoRow('Dự kiến giao hàng', _dateFormat.format(order.estimatedDelivery!)),
                            _buildInfoRow('Dịch vụ', _getServiceLabel(order.serviceType)),
                            _buildInfoRow('Loại hàng', order.packageType),
                            if (order.notes != null && order.notes!.isNotEmpty)
                              _buildInfoRow('Ghi chú', order.notes!),
                          ],
                        ),
                        _buildSection(
                          title: 'Thông tin người gửi',
                          children: [
                            _buildInfoRow('Họ tên', order.senderName),
                            _buildInfoRow('Số điện thoại', order.senderPhone),
                            _buildInfoRow('Địa chỉ', order.senderAddress),
                            if ((order.senderCity ?? '').isNotEmpty)
                              _buildInfoRow('Khu vực', '${order.senderWard ?? ''} ${order.senderDistrict ?? ''} ${order.senderCity ?? ''}'.trim()),
                          ],
                        ),
                        _buildSection(
                          title: 'Thông tin người nhận',
                          children: [
                            _buildInfoRow('Họ tên', order.receiverName),
                            _buildInfoRow('Số điện thoại', order.receiverPhone),
                            _buildInfoRow('Địa chỉ', order.receiverAddress),
                            if ((order.receiverCity ?? '').isNotEmpty)
                              _buildInfoRow('Khu vực', '${order.receiverWard ?? ''} ${order.receiverDistrict ?? ''} ${order.receiverCity ?? ''}'.trim()),
                          ],
                        ),
                        _buildSection(
                          title: 'Thông tin kiện hàng',
                          children: [
                            if (order.parcelWeight != null)
                              _buildInfoRow('Khối lượng', '${order.parcelWeight} kg'),
                            if (order.parcelLength != null && order.parcelWidth != null && order.parcelHeight != null)
                              _buildInfoRow('Kích thước', '${order.parcelLength} x ${order.parcelWidth} x ${order.parcelHeight} cm'),
                            if (order.declaredValue != null)
                              _buildInfoRow('Giá trị khai báo', _currencyFormat.format(order.declaredValue)),
                            _buildInfoRow('Hình thức nhận hàng', order.pickupType == 'drop_off' ? 'Gửi tại bưu cục' : 'Nhân viên đến lấy'),
                            if ((order.pickupNotes ?? '').isNotEmpty)
                              _buildInfoRow('Ghi chú lấy hàng', order.pickupNotes!),
                          ],
                        ),
                        _buildSection(
                          title: 'Chi phí & thanh toán',
                          children: [
                            _buildInfoRow('Phí vận chuyển', _currencyFormat.format(order.shippingFee)),
                            _buildInfoRow('Phí bảo hiểm', _currencyFormat.format(order.insuranceFee)),
                            if (order.codAmount > 0)
                              _buildInfoRow('Tiền thu hộ (COD)', _currencyFormat.format(order.codAmount)),
                            _buildInfoRow('Phương thức thanh toán', order.getPaymentMethodText()),
                            _buildInfoRow('Trạng thái thanh toán', order.getPaymentStatusText()),
                            _buildInfoRow('Tổng tiền', _currencyFormat.format(order.totalAmount)),
                            if (order.paymentReference != null)
                              _buildInfoRow('Mã giao dịch', order.paymentReference!),
                            if (order.paymentMethod.toLowerCase() == 'online' &&
                                order.paymentStatus.toLowerCase() != 'paid')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessingPayment ? null : _initiatePayment,
                                  icon: _isProcessingPayment
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.payment),
                                  label: const Text('Thanh toán online ngay'),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (order.status.toLowerCase() == 'delivered')
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FeedbackFormScreen(order: order),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.feedback_outlined),
                              label: const Text('Gửi phản hồi cho đơn hàng này'),
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
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTransactionInfoRow(
    String label,
    String value, {
    List<Widget>? actions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actions != null && actions.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions
                        .map(
                          (widget) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: widget,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<OrderStatusHistory> history) {
    return Column(
      children: history.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == history.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 48,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.primaryColor
                        .withAlpha((0.3 * 255).round()),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.statusText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateFormat.format(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    if ((item.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    if ((item.createdBy ?? '').isNotEmpty)
                      Text(
                        'Thực hiện bởi: ${item.createdBy}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

