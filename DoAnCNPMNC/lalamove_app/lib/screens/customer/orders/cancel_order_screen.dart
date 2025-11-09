import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../utils/constants.dart';

class CancelOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const CancelOrderScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedCancelType;
  bool _isLoading = false;

  final List<Map<String, String>> _cancelTypes = [
    {'value': 'customer_request', 'label': 'Yêu cầu của khách hàng'},
    {'value': 'out_of_stock', 'label': 'Hết hàng'},
    {'value': 'wrong_address', 'label': 'Địa chỉ sai'},
    {'value': 'duplicate_order', 'label': 'Đơn hàng trùng lặp'},
    {'value': 'change_mind', 'label': 'Thay đổi ý định'},
    {'value': 'other', 'label': 'Lý do khác'},
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _getStatusText(String status) {
    final statusMap = {
      'pending': 'Chờ xử lý',
      'processing': 'Đang xử lý',
      'confirmed': 'Đã xác nhận',
      'shipped': 'Đang giao',
      'in_transit': 'Đang vận chuyển',
      'delivered': 'Đã giao',
      'cancelled': 'Đã hủy',
    };
    return statusMap[status] ?? status;
  }

  bool _canCancel() {
    final status = widget.order['status'] as String;
    final cannotCancelStatuses = ['delivered', 'cancelled', 'shipped', 'in_transit'];
    return !cannotCancelStatuses.contains(status);
  }

  Future<void> _submitCancellation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCancelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn lý do hủy đơn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đơn hàng này?\n\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      await orderProvider.cancelOrder(
        orderId: widget.order['id'],
        reason: _reasonController.text.trim(),
        cancelType: _selectedCancelType!,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đơn hàng đã được hủy thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = _canCancel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hủy đơn hàng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: !canCancel
          ? _buildCannotCancelView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderInfo(),
                    const SizedBox(height: 24),
                    _buildCancelTypeSelection(),
                    const SizedBox(height: 24),
                    _buildReasonInput(),
                    const SizedBox(height: 24),
                    _buildWarningBox(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCannotCancelView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể hủy đơn hàng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đơn hàng ở trạng thái "${_getStatusText(widget.order['status'])}" không thể hủy.\n\n'
              'Vui lòng liên hệ bộ phận hỗ trợ nếu cần trợ giúp.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Mã đơn:', widget.order['order_number']),
            _buildInfoRow('Trạng thái:', _getStatusText(widget.order['status'])),
            _buildInfoRow(
              'Tổng tiền:',
              '${widget.order['total_amount'].toStringAsFixed(0)} đ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lý do hủy đơn *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._cancelTypes.map((type) {
          return RadioListTile<String>(
            title: Text(type['label']!),
            value: type['value']!,
            groupValue: _selectedCancelType,
            onChanged: (value) {
              setState(() => _selectedCancelType = value);
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết lý do *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Nhập chi tiết lý do hủy đơn (tối thiểu 5 ký tự)...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập lý do hủy đơn';
            }
            if (value.trim().length < 5) {
              return 'Lý do phải có ít nhất 5 ký tự';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lưu ý: Sau khi hủy đơn, bạn không thể hoàn tác. '
              'Nếu đã thanh toán, tiền sẽ được hoàn lại trong 3-5 ngày làm việc.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitCancellation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Xác nhận hủy đơn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

