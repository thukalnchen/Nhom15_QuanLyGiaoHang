import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/constants.dart';
import '../../../services/admin_api_service.dart';
import '../../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// Story #24: Reporting với dữ liệu thật từ database
class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  Map<String, dynamic> _revenueData = {};
  Map<String, dynamic> _deliveryData = {};
  List<dynamic> _driverData = [];
  Map<String, dynamic> _customerData = {};
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = false;
  Timer? _autoRefreshTimer;
  DateTime _lastUpdate = DateTime.now();

  final _numberFormat = NumberFormat('#,###', 'vi_VN');
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadReports();
    // Auto refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadReports();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);
      
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      
      final revenue = await AdminApiService.getRevenueReport(token);
      final delivery = await AdminApiService.getDeliveryStats(token);
      final driver = await AdminApiService.getDriverPerformance(token);
      final customer = await AdminApiService.getCustomerAnalytics(token);
      final dashboard = await AdminApiService.getDashboard(token);
      
      print('📊 Revenue data: $revenue');
      print('📊 Delivery data: $delivery');
      print('📊 Driver data: $driver');
      print('📊 Customer data: $customer');
      print('📊 Dashboard data: $dashboard');
      
      setState(() {
        _revenueData = revenue;
        _deliveryData = delivery;
        _driverData = driver;
        _customerData = customer;
        _dashboardData = dashboard;
        _lastUpdate = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi tải báo cáo: $e');
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Báo Cáo Thống Kê'),
            Text(
              'Cập nhật: ${DateFormat('HH:mm:ss').format(_lastUpdate)}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Làm mới (tự động mỗi 30s)',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    isScrollable: true,
                    tabs: const [
                      Tab(icon: Icon(Icons.attach_money), text: 'Doanh Thu'),
                      Tab(icon: Icon(Icons.local_shipping), text: 'Giao Hàng'),
                      Tab(icon: Icon(Icons.person), text: 'Tài Xế'),
                      Tab(icon: Icon(Icons.people), text: 'Khách Hàng'),
                      Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRevenueReport(),
                        _buildDeliveryStats(),
                        _buildDriverPerformance(),
                        _buildCustomerAnalytics(),
                        _buildDashboard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRevenueReport() {
    final today = _revenueData['today'] ?? {};
    final monthly = _revenueData['monthly'] ?? {};
    final yearly = _revenueData['yearly'] ?? {};
    final byVehicle = _revenueData['by_vehicle'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            title: 'Doanh Thu Hôm Nay',
            value: _currencyFormat.format(today['total_revenue'] ?? 0),
            subtitle: '${today['total_orders'] ?? 0} đơn hàng',
            icon: Icons.today,
            color: Colors.green,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            title: 'Doanh Thu Tháng Này',
            value: _currencyFormat.format(monthly['total_revenue'] ?? 0),
            subtitle: '${monthly['total_orders'] ?? 0} đơn hàng',
            icon: Icons.calendar_month,
            color: Colors.blue,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            title: 'Doanh Thu Năm Nay',
            value: _currencyFormat.format(yearly['total_revenue'] ?? 0),
            subtitle: '${yearly['total_orders'] ?? 0} đơn hàng',
            icon: Icons.date_range,
            color: Colors.purple,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Biểu đồ theo loại xe - luôn hiển thị
          const Text(
            'Doanh Thu Theo Loại Xe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (byVehicle.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text(
                'Chưa có dữ liệu đơn hàng',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          else ...[
            // Pie Chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieSections(byVehicle),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Bar Chart - Doanh thu theo xe
            const Text(
              'Biểu Đồ Cột - Doanh Thu Theo Xe',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxRevenue(byVehicle) * 1.2,
                  barGroups: _buildRevenueBarGroups(byVehicle),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < byVehicle.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getVehicleLabel(byVehicle[value.toInt()]['type']),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            ...byVehicle.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildDetailCard(
                _getVehicleLabel(item['type']),
                _currencyFormat.format(item['revenue'] ?? 0),
                (item['revenue'] ?? 0) / (today['total_revenue'] ?? 1) * 100,
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryStats() {
    final byStatus = _deliveryData['by_status'] ?? [];
    final byTime = _deliveryData['by_time'] ?? [];
    final successRate = _deliveryData['success_rate'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            title: 'Tổng Đơn Hàng',
            value: '${successRate['total_orders'] ?? 0}',
            subtitle: 'Tất cả đơn trong hệ thống',
            icon: Icons.shopping_bag,
            color: Colors.blue,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            title: 'Đơn Giao Thành Công',
            value: '${successRate['delivered_orders'] ?? 0}',
            subtitle: 'Đã giao đến khách',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            title: 'Tỷ Lệ Thành Công',
            value: '${successRate['success_rate'] ?? 0}%',
            subtitle: 'Delivery success rate',
            icon: Icons.percent,
            color: Colors.purple,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Biểu đồ trạng thái đơn hàng - luôn hiển thị
          const Text(
            'Phân Bố Trạng Thái Đơn Hàng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (byStatus.isEmpty)
            Container(
              height: 250,
              alignment: Alignment.center,
              child: const Text(
                'Chưa có dữ liệu trạng thái đơn hàng',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: byStatus.fold<double>(0, (max, item) => 
                    (int.tryParse(item['count']?.toString() ?? '0') ?? 0) > max 
                      ? (int.tryParse(item['count']?.toString() ?? '0') ?? 0).toDouble() 
                      : max) * 1.2,
                  barGroups: _buildBarGroups(byStatus),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < byStatus.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getStatusLabel(byStatus[value.toInt()]['status']),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Thống kê theo thời gian trong ngày
          if (byTime.isNotEmpty) ...[
            const Text(
              'Đơn Hàng Theo Thời Gian Trong Ngày',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ...byTime.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildDetailCard(
                _getTimePeriodLabel(item['time_period']),
                '${item['count']} đơn',
                (int.tryParse(item['count']?.toString() ?? '0') ?? 0) / 
                  byTime.fold(0, (sum, i) => sum + (int.tryParse(i['count']?.toString() ?? '0') ?? 0)) * 100,
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverPerformance() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text(
          'Top Tài Xế Theo Doanh Thu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_driverData.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('Chưa có dữ liệu tài xế'),
            ),
          )
        else
          ..._driverData.map((driver) => _buildDriverCard(driver)),
      ],
    );
  }

  Widget _buildCustomerAnalytics() {
    final topCustomers = _customerData['top_customers'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            title: 'Tổng Khách Hàng',
            value: '${_customerData['total_customers'] ?? 0}',
            subtitle: 'Trong hệ thống',
            icon: Icons.people,
            color: Colors.blue,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            title: 'Khách Mới (Tháng Này)',
            value: '${_customerData['new_customers'] ?? 0}',
            subtitle: 'Khách hàng mới',
            icon: Icons.person_add,
            color: Colors.green,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            title: 'Khách Quay Lại',
            value: '${_customerData['repeat_customers'] ?? 0}',
            subtitle: 'Đặt hàng > 1 lần',
            icon: Icons.repeat,
            color: Colors.orange,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          if (topCustomers.isNotEmpty) ...[
            const Text(
              'Khách Hàng Hàng Đầu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ...topCustomers.map((customer) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCustomerItem(
                customer['name'] ?? 'N/A',
                customer['total_orders'] ?? 0,
                _currencyFormat.format(customer['total_spent'] ?? 0),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Đơn Hôm Nay', 
                  '${_dashboardData['orders_today'] ?? 0}', 
                  Colors.blue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMiniStatCard(
                  'Tài Xế', 
                  '${_dashboardData['active_drivers'] ?? 0}', 
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Doanh Thu', 
                  _currencyFormat.format(_dashboardData['revenue_today'] ?? 0).replaceAll('₫', '').trim() + 'đ',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMiniStatCard(
                  'Thành Công', 
                  '${_dashboardData['success_rate'] ?? 0}%', 
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildStatCard(
            title: 'Đơn Đang Xử Lý',
            value: '${_dashboardData['in_progress'] ?? 0}',
            subtitle: 'Đang giao',
            icon: Icons.local_shipping,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<PieChartSectionData> _buildPieSections(List<dynamic> data) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    final total = data.fold<double>(0, (sum, item) => sum + (item['revenue'] ?? 0));
    
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final revenue = item['revenue'] ?? 0;
      final percentage = total > 0 ? (revenue / total * 100) : 0;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: revenue.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(List<dynamic> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final count = int.tryParse(item['count']?.toString() ?? '0') ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _buildRevenueBarGroups(List<dynamic> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final revenueValue = item['revenue'];
      double revenue = 0;
      
      if (revenueValue is num) {
        revenue = revenueValue.toDouble();
      } else if (revenueValue is String) {
        revenue = double.tryParse(revenueValue) ?? 0;
      }
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: revenue,
            color: colors[index % colors.length],
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxRevenue(List<dynamic> data) {
    double max = 0;
    for (var item in data) {
      final revenueValue = item['revenue'];
      double revenue = 0;
      
      if (revenueValue is num) {
        revenue = revenueValue.toDouble();
      } else if (revenueValue is String) {
        revenue = double.tryParse(revenueValue) ?? 0;
      }
      
      if (revenue > max) max = revenue;
    }
    return max > 0 ? max : 100000;
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(dynamic driver) {
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
                  child: Text(
                    driver['name'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${driver['success_rate'] ?? 0}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đơn hoàn thành', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '${driver['delivered_orders'] ?? 0}/${driver['total_orders'] ?? 0}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tổng thu nhập', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      _currencyFormat.format(driver['total_earnings'] ?? 0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerItem(String name, int orders, String spent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$orders đơn', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(spent, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'bike':
      case 'motorcycle':
        return 'Xe máy';
      case 'car':
        return 'Xe hơi';
      case 'van':
        return 'Xe tải nhỏ';
      case 'truck':
        return 'Xe tải';
      default:
        return type ?? 'Khác';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Chờ';
      case 'confirmed':
        return 'Xác nhận';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Hủy';
      case 'assigned':
        return 'Đã phân';
      case 'picked_up':
        return 'Đã lấy';
      case 'in_delivery':
        return 'Đang giao';
      default:
        return status ?? '';
    }
  }

  String _getTimePeriodLabel(String? period) {
    switch (period) {
      case 'morning':
        return 'Buổi sáng (6h-12h)';
      case 'afternoon':
        return 'Buổi chiều (12h-18h)';
      case 'evening':
        return 'Buổi tối (18h-24h)';
      case 'night':
        return 'Ban đêm (0h-6h)';
      default:
        return period ?? '';
    }
  }
}
