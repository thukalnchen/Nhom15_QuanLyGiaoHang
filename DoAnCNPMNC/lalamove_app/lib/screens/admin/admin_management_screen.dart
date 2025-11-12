import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'story_20_orders_list.dart';
import 'story_21_driver_assignment.dart';
import 'story_22_route_management.dart';
import 'story_23_pricing_policy.dart';
import 'story_24_reporting.dart';

/// Admin Management Home Screen
/// Hiển thị dashboard quản lý cho admin
class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Giao Hàng'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(context),
            const SizedBox(height: AppSpacing.xl),

            // Management Sections
            Text(
              'Các Chức Năng Quản Lý',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Story #20: Orders Management
            _buildManagementCard(
              title: 'Quản Lý Đơn Hàng',
              subtitle: 'Story #20',
              icon: Icons.shopping_cart,
              description: 'Xem, cập nhật, quản lý tất cả đơn hàng',
              onTap: () => _navigateToScreen(context, 'orders_management'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Story #21: Driver Assignment
            _buildManagementCard(
              title: 'Gán Tài Xế',
              subtitle: 'Story #21',
              icon: Icons.person_add,
              description: 'Gán tài xế cho các đơn hàng',
              onTap: () => _navigateToScreen(context, 'driver_assignment'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Story #22: Route Management
            _buildManagementCard(
              title: 'Quản Lý Tuyến Đường',
              subtitle: 'Story #22',
              icon: Icons.map,
              description: 'Quản lý khu vực và tuyến giao hàng',
              onTap: () => _navigateToScreen(context, 'route_management'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Story #23: Pricing Policy
            _buildManagementCard(
              title: 'Chính Sách Giá',
              subtitle: 'Story #23',
              icon: Icons.attach_money,
              description: 'Quản lý giá cả, phí phụ, và giảm giá',
              onTap: () => _navigateToScreen(context, 'pricing_policy'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Story #24: Reporting
            _buildManagementCard(
              title: 'Báo Cáo',
              subtitle: 'Story #24',
              icon: Icons.assessment,
              description: 'Xem báo cáo doanh thu, hiệu suất, phân tích',
              onTap: () => _navigateToScreen(context, 'reporting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userName = authProvider.user?.name ?? 'Admin';
        return Card(
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng, $userName!',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Quản lý hệ thống giao hàng từ trang này',
                  style: const TextStyle(
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Text(
                      authProvider.user?.name ?? 'Admin',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Quản Trị Viên',
                  style: TextStyle(
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Cài Đặt'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng cài đặt sẽ sớm ra mắt')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Đăng Xuất'),
            onTap: () {
              Navigator.pop(context);
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String screenName) {
    Widget screen;
    switch (screenName) {
      case 'orders_management':
        screen = const OrdersListScreen();
        break;
      case 'driver_assignment':
        screen = const DriverAssignmentScreen();
        break;
      case 'route_management':
        screen = const RouteManagementScreen();
        break;
      case 'pricing_policy':
        screen = const PricingPolicyScreen();
        break;
      case 'reporting':
        screen = const ReportingScreen();
        break;
      default:
        return;
    }
    
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
