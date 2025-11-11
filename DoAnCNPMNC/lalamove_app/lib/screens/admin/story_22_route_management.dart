import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants.dart';
import '../../../services/admin_api_service.dart';
import '../../../providers/auth_provider.dart';

/// Story #22: Route Management
class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _routes = [];
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
      
      final zones = await AdminApiService.getZones(token);
      final routes = await AdminApiService.getRoutes(token);
      
      setState(() {
        _zones = zones;
        _routes = routes;
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
        title: const Text('Quản Lý Tuyến Đường'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Khu Vực'),
                      Tab(text: 'Tuyến Đường'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildZonesList(),
                        _buildRoutesList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildZonesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _zones.length,
      itemBuilder: (context, index) {
        final zone = _zones[index];
        return _buildZoneCard(context, zone);
      },
    );
  }

  Widget _buildZoneCard(BuildContext context, Map<String, dynamic> zone) {
    final isActive = zone['status'] == 'active';
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
                  zone['name'],
                  style: AppTextStyles.heading3,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    isActive ? 'Hoạt động' : 'Không hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.red,
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
                    const Text(
                      'Diện tích',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                    Text(
                      '${zone['area']} km²',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đơn hàng',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                    Text(
                      '${zone['orders']}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(child: Text('Sửa')),
                    const PopupMenuItem(child: Text('Xóa')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _routes.length,
      itemBuilder: (context, index) {
        final route = _routes[index];
        return _buildRouteCard(context, route);
      },
    );
  }

  Widget _buildRouteCard(BuildContext context, Map<String, dynamic> route) {
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
                        route['name'],
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Khu vực: ${route['zone']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(child: Text('Sửa')),
                    const PopupMenuItem(child: Text('Xóa')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${route['distance']} km',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_searching, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${route['stops']} dừng',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
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

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm khu vực/tuyến'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location),
              title: const Text('Thêm khu vực'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng thêm khu vực sẽ sớm ra mắt')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Thêm tuyến'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng thêm tuyến sẽ sớm ra mắt')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
