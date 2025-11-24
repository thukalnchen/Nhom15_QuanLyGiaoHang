import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/warehouse_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../utils/constants.dart';
import '../../common/notifications/notification_history_screen.dart';
import '../scan/scan_screen.dart';
import '../orders/orders_screen.dart';
import '../warehouse/warehouse_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const OrdersScreen(),
    const WarehouseScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load data sau khi frame đầu tiên được render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();
    
    if (authProvider.token != null) {
      await warehouseProvider.loadOrders(authProvider.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: 'Kho hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code_scanner, color: AppColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Dashboard Tab
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final warehouseProvider = context.watch<WarehouseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          notificationProvider.unreadCount > 99
                              ? '99+'
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (authProvider.token != null) {
                await warehouseProvider.loadOrders(authProvider.token!);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.token != null) {
            await warehouseProvider.loadOrders(authProvider.token!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'N',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào,',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              authProvider.user?.name ?? '',
                              style: AppTextStyles.heading3,
                            ),
                            if (authProvider.user?.warehouseName != null)
                              Text(
                                authProvider.user!.warehouseName!,
                                style: AppTextStyles.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Statistics
              Text(
                'Thống kê hôm nay',
                style: AppTextStyles.heading3,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Chờ nhận',
                      count: warehouseProvider.pendingOrders.length,
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      title: 'Đã nhận',
                      count: warehouseProvider.receivedOrders.length,
                      icon: Icons.check_circle,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Đã phân loại',
                      count: warehouseProvider.classifiedOrders.length,
                      icon: Icons.category,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      title: 'Sẵn sàng',
                      count: warehouseProvider.readyOrders.length,
                      icon: Icons.local_shipping,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Quick actions
              Text(
                'Thao tác nhanh',
                style: AppTextStyles.heading3,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Quét mã',
                      icon: Icons.qr_code_scanner,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Nhận hàng',
                      icon: Icons.inventory,
                      color: AppColors.info,
                      onTap: () {
                        // Navigate to Orders tab (index 1) to see pending orders
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrdersScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Phân loại',
                      icon: Icons.category,
                      color: Colors.purple,
                      onTap: () {
                        // Navigate to Warehouse tab (index 2) -> Classification subtab
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WarehouseScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Phân tài xế',
                      icon: Icons.person_add,
                      color: AppColors.success,
                      onTap: () {
                        // Navigate to Warehouse tab for assignment
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WarehouseScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              count.toString(),
              style: AppTextStyles.heading2.copyWith(color: color),
            ),
            Text(
              title,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

