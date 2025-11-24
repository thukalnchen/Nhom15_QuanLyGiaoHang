import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants.dart';
import '../../../services/admin_api_service.dart';
import '../../../providers/auth_provider.dart';

/// Story #23: Pricing Policy
class PricingPolicyScreen extends StatefulWidget {
  const PricingPolicyScreen({super.key});

  @override
  State<PricingPolicyScreen> createState() => _PricingPolicyScreenState();
}

class _PricingPolicyScreenState extends State<PricingPolicyScreen> {
  List<Map<String, dynamic>> _pricingTables = [];
  List<Map<String, dynamic>> _surcharges = [];
  List<Map<String, dynamic>> _discounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      
      final pricing = await AdminApiService.getPricingTables(token);
      final surcharges = await AdminApiService.getSurcharges(token);
      final discounts = await AdminApiService.getDiscounts(token);
      
      setState(() {
        _pricingTables = pricing;
        _surcharges = surcharges;
        _discounts = discounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi tải dữ liệu: $e');
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
        title: const Text('Chính Sách Giá'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Bảng Giá'),
                      Tab(text: 'Phí Phụ'),
                      Tab(text: 'Giảm Giá'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPricingTable(),
                        _buildSurcharges(),
                        _buildDiscounts(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPricingTable() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _pricingTables.length,
      itemBuilder: (context, index) {
        final pricing = _pricingTables[index];
        return _buildPricingCard(context, pricing);
      },
    );
  }

  Widget _buildPricingCard(BuildContext context, Map<String, dynamic> pricing) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getVehicleTypeName(pricing['vehicle_type'] ?? ''),
                  style: AppTextStyles.heading3,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _editPricing(pricing),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá cơ bản:'),
                      Text(
                        '${_formatNumber(pricing['base_price'])} VND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá/km:'),
                      Text(
                        '${_formatNumber(pricing['price_per_km'])} VND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá tối thiểu:'),
                      Text(
                        '${_formatNumber(pricing['minimum_price'])} VND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (pricing['surge_multiplier'] != null && pricing['surge_multiplier'] != 1.0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hệ số tăng giá:'),
                        Text(
                          'x${pricing['surge_multiplier']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (pricing['description'] != null && pricing['description'].isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                pricing['description'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getVehicleTypeName(String type) {
    final names = {
      'bike': 'Xe máy',
      'motorcycle': 'Xe máy',
      'car': 'Xe hơi',
      'van': 'Xe tải nhỏ',
      'truck': 'Xe tải lớn',
    };
    return names[type] ?? type;
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  bool _isPositive(dynamic value) {
    if (value == null) return false;
    if (value is num) return value > 0;
    final parsed = double.tryParse(value.toString());
    return parsed != null && parsed > 0;
  }

  void _editPricing(Map<String, dynamic> pricing) async {
    final basePriceController = TextEditingController(text: pricing['base_price']?.toString() ?? '');
    final perKmController = TextEditingController(text: pricing['price_per_km']?.toString() ?? '');
    final minPriceController = TextEditingController(text: pricing['minimum_price']?.toString() ?? '');
    final surgeController = TextEditingController(text: pricing['surge_multiplier']?.toString() ?? '1.0');
    final descController = TextEditingController(text: pricing['description'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật giá - ${_getVehicleTypeName(pricing['vehicle_type'])}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: basePriceController,
                decoration: const InputDecoration(labelText: 'Giá cơ bản (VND)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: perKmController,
                decoration: const InputDecoration(labelText: 'Giá/km (VND)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: minPriceController,
                decoration: const InputDecoration(labelText: 'Giá tối thiểu (VND)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: surgeController,
                decoration: const InputDecoration(labelText: 'Hệ số tăng giá'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.updatePricing(token, {
        'vehicleType': pricing['vehicle_type'],
        'basePrice': double.tryParse(basePriceController.text) ?? 0,
        'pricePerKm': double.tryParse(perKmController.text) ?? 0,
        'minimumPrice': double.tryParse(minPriceController.text) ?? 0,
        'surgeMultiplier': double.tryParse(surgeController.text) ?? 1.0,
        'description': descController.text,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại')),
        );
      }
    }
  }

  Widget _buildSurcharges() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: _addSurcharge,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Phí Phụ'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _surcharges.length,
            itemBuilder: (context, index) {
              final surcharge = _surcharges[index];
              return _buildSurchargeCard(context, surcharge);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSurchargeCard(BuildContext context, Map<String, dynamic> surcharge) {
    final isPercent = surcharge['type'] == 'percentage';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surcharge['name'] ?? '',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isPercent ? 'Tính theo %' : 'Cố định',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPercent ? '${surcharge['value']}%' : '${_formatNumber(surcharge['value'])} VND',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                          onPressed: () => _editSurcharge(surcharge),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteSurcharge(surcharge),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (surcharge['description'] != null && surcharge['description'].isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                surcharge['description'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addSurcharge() async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'fixed';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm Phí Phụ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên phí phụ *'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Loại *'),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Cố định (VND)')),
                    DropdownMenuItem(value: 'percentage', child: Text('Phần trăm (%)')),
                    DropdownMenuItem(value: 'multiplier', child: Text('Hệ số nhân')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: selectedType == 'percentage' ? 'Giá trị (%) *' : 'Giá trị *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (nameController.text.isEmpty || valueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin bắt buộc')),
        );
        return;
      }

      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.createSurcharge(token, {
        'name': nameController.text,
        'type': selectedType,
        'value': double.tryParse(valueController.text) ?? 0,
        'description': descController.text,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm thất bại')),
        );
      }
    }
  }

  void _editSurcharge(Map<String, dynamic> surcharge) async {
    final nameController = TextEditingController(text: surcharge['name']);
    final valueController = TextEditingController(text: surcharge['value']?.toString());
    final descController = TextEditingController(text: surcharge['description'] ?? '');
    String selectedType = surcharge['type'] ?? 'fixed';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cập nhật Phí Phụ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên phí phụ *'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Loại *'),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Cố định (VND)')),
                    DropdownMenuItem(value: 'percentage', child: Text('Phần trăm (%)')),
                    DropdownMenuItem(value: 'multiplier', child: Text('Hệ số nhân')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Giá trị *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.updateSurcharge(
        token,
        surcharge['id'],
        {
          'name': nameController.text,
          'type': selectedType,
          'value': double.tryParse(valueController.text) ?? 0,
          'description': descController.text,
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại')),
        );
      }
    }
  }

  void _deleteSurcharge(Map<String, dynamic> surcharge) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có muốn xóa "${surcharge['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.deleteSurcharge(token, surcharge['id']);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thất bại')),
        );
      }
    }
  }

  Widget _buildDiscounts() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: _addDiscount,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Mã Giảm Giá'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _discounts.length,
            itemBuilder: (context, index) {
              final discount = _discounts[index];
              return _buildDiscountCard(context, discount);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountCard(BuildContext context, Map<String, dynamic> discount) {
    final isPercent = discount['type'] == 'percentage';
    final validTo = discount['valid_to'] != null 
        ? DateTime.parse(discount['valid_to']).toString().substring(0, 10)
        : 'Không giới hạn';
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã: ${discount['code']}',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        discount['name'] ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isPercent 
                            ? 'Giảm ${discount['value']}%' 
                            : 'Giảm ${_formatNumber(discount['value'])} VND',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _editDiscount(discount),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDiscount(context, discount),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isPositive(discount['min_order_value']))
                    Text('Đơn tối thiểu: ${_formatNumber(discount['min_order_value'])} VND', style: const TextStyle(fontSize: 12)),
                  if (_isPositive(discount['max_discount']))
                    Text('Giảm tối đa: ${_formatNumber(discount['max_discount'])} VND', style: const TextStyle(fontSize: 12)),
                  Text('Hết hạn: $validTo', style: const TextStyle(fontSize: 12)),
                  if (discount['usage_limit'] != null)
                    Text('Sử dụng: ${discount['usage_count'] ?? 0}/${discount['usage_limit']}', 
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDiscount() async {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final minOrderController = TextEditingController(text: '0');
    final maxDiscountController = TextEditingController();
    final usageLimitController = TextEditingController();
    DateTime? validFromDate;
    DateTime? validToDate = DateTime.now().add(const Duration(days: 30));
    String selectedType = 'percentage';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm Mã Giảm Giá'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã giảm giá *',
                    hintText: 'VD: SAVE20K',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên chương trình *',
                    hintText: 'VD: Giảm 20K cho đơn đầu',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Loại giảm giá *'),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Phần trăm (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Cố định (VND)')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: selectedType == 'percentage' ? 'Giá trị (%) *' : 'Giá trị (VND) *',
                    hintText: selectedType == 'percentage' ? '10' : '20000',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Đơn hàng tối thiểu (VND)',
                    hintText: '0 = không giới hạn',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: maxDiscountController,
                  decoration: const InputDecoration(
                    labelText: 'Giảm tối đa (VND)',
                    hintText: 'Để trống = không giới hạn',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: usageLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Giới hạn sử dụng (lần)',
                    hintText: 'Để trống = không giới hạn',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(validFromDate != null 
                      ? validFromDate.toString().substring(0, 10)
                      : 'Ngay lập tức'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => validFromDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày hết hạn'),
                  subtitle: Text(validToDate != null 
                      ? validToDate.toString().substring(0, 10)
                      : 'Không giới hạn'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: validToDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => validToDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (codeController.text.isEmpty || nameController.text.isEmpty || valueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin bắt buộc')),
        );
        return;
      }

      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.createDiscount(token, {
        'code': codeController.text.toUpperCase(),
        'name': nameController.text,
        'type': selectedType,
        'value': double.tryParse(valueController.text) ?? 0,
        'minOrderValue': double.tryParse(minOrderController.text) ?? 0,
        'maxDiscount': maxDiscountController.text.isNotEmpty ? double.tryParse(maxDiscountController.text) : null,
        'usageLimit': usageLimitController.text.isNotEmpty ? int.tryParse(usageLimitController.text) : null,
        'validFrom': validFromDate?.toIso8601String(),
        'validTo': validToDate?.toIso8601String(),
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm thất bại')),
        );
      }
    }
  }

  void _editDiscount(Map<String, dynamic> discount) async {
    final codeController = TextEditingController(text: discount['code']);
    final nameController = TextEditingController(text: discount['name']);
    final valueController = TextEditingController(text: discount['value']?.toString());
    final minOrderController = TextEditingController(text: discount['min_order_value']?.toString() ?? '0');
    final maxDiscountController = TextEditingController(text: discount['max_discount']?.toString() ?? '');
    final usageLimitController = TextEditingController(text: discount['usage_limit']?.toString() ?? '');
    DateTime? validFromDate = discount['valid_from'] != null 
        ? DateTime.tryParse(discount['valid_from'])
        : null;
    DateTime? validToDate = discount['valid_to'] != null 
        ? DateTime.tryParse(discount['valid_to'])
        : null;
    String selectedType = discount['type'] ?? 'percentage';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cập nhật Mã Giảm Giá'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Mã giảm giá *'),
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên chương trình *'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Loại *'),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Phần trăm (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Cố định (VND)')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Giá trị *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(labelText: 'Đơn hàng tối thiểu (VND)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: maxDiscountController,
                  decoration: const InputDecoration(labelText: 'Giảm tối đa (VND)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: usageLimitController,
                  decoration: const InputDecoration(labelText: 'Giới hạn sử dụng'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(validFromDate != null 
                      ? validFromDate.toString().substring(0, 10)
                      : 'Ngay lập tức'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: validFromDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => validFromDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày hết hạn'),
                  subtitle: Text(validToDate != null 
                      ? validToDate.toString().substring(0, 10)
                      : 'Không giới hạn'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: validToDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => validToDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.updateDiscount(
        token,
        discount['id'],
        {
          'code': codeController.text.toUpperCase(),
          'name': nameController.text,
          'type': selectedType,
          'value': double.tryParse(valueController.text) ?? 0,
          'minOrderValue': double.tryParse(minOrderController.text) ?? 0,
          'maxDiscount': maxDiscountController.text.isNotEmpty ? double.tryParse(maxDiscountController.text) : null,
          'usageLimit': usageLimitController.text.isNotEmpty ? int.tryParse(usageLimitController.text) : null,
          'validFrom': validFromDate?.toIso8601String(),
          'validTo': validToDate?.toIso8601String(),
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại')),
        );
      }
    }
  }

  void _deleteDiscount(BuildContext context, Map<String, dynamic> discount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có muốn xóa mã "${discount['code']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.deleteDiscount(token, discount['id']);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thất bại')),
        );
      }
    }
  }
}
