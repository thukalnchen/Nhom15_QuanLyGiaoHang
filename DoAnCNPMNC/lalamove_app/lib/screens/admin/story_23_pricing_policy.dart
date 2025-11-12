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
                  pricing['name'],
                  style: AppTextStyles.heading3,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {},
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
                        '${pricing['basePrice']} VND',
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
                        '${pricing['perKm']} VND',
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
                        '${pricing['minPrice']} VND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurcharges() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _surcharges.length,
      itemBuilder: (context, index) {
        final surcharge = _surcharges[index];
        return _buildSurchargeCard(context, surcharge);
      },
    );
  }

  Widget _buildSurchargeCard(BuildContext context, Map<String, dynamic> surcharge) {
    final isPercent = surcharge['type'] == 'percent';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surcharge['name'],
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
                  isPercent ? '${surcharge['amount']}%' : '${surcharge['amount']} VND',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscounts() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _discounts.length,
      itemBuilder: (context, index) {
        final discount = _discounts[index];
        return _buildDiscountCard(context, discount);
      },
    );
  }

  Widget _buildDiscountCard(BuildContext context, Map<String, dynamic> discount) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã: ${discount['code']}',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Giảm: ${discount['percent']}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteDiscount(context, discount),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hết hạn: ${discount['validUntil']}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDiscount(BuildContext context, Map<String, dynamic> discount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có muốn xóa mã ${discount['code']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _discounts.remove(discount);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xóa thành công')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
