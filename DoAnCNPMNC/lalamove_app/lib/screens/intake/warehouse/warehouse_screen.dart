import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/warehouse_provider.dart';
import '../../../utils/constants.dart';
import 'classification_screen.dart';
import 'assignment_screen.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    if (authProvider.token != null) {
      await warehouseProvider.loadOrders(authProvider.token!);
    }
  }

  Future<void> _navigateToClassification(Order order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassificationScreen(order: order),
      ),
    );

    if (result == true) {
      _loadOrders(); // Refresh after classification
    }
  }

  Future<void> _navigateToAssignment(Order order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentScreen(order: order),
      ),
    );

    if (result == true) {
      _loadOrders(); // Refresh after assignment
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehouseProvider = context.watch<WarehouseProvider>();

    // Get orders by status from provider
    final receivedOrders = warehouseProvider.receivedOrders;
    final classifiedOrders = warehouseProvider.classifiedOrders;
    final readyOrders = warehouseProvider.readyOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý kho'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Cần phân loại',
              icon: Badge(
                isLabelVisible: receivedOrders.isNotEmpty,
                label: Text('${receivedOrders.length}'),
                child: const Icon(Icons.category),
              ),
            ),
            Tab(
              text: 'Đã phân loại',
              icon: Badge(
                isLabelVisible: classifiedOrders.isNotEmpty,
                label: Text('${classifiedOrders.length}'),
                child: const Icon(Icons.check_circle_outline),
              ),
            ),
            Tab(
              text: 'Sẵn sàng',
              icon: Badge(
                isLabelVisible: readyOrders.isNotEmpty,
                label: Text('${readyOrders.length}'),
                child: const Icon(Icons.local_shipping),
              ),
            ),
          ],
        ),
      ),
      body: warehouseProvider.isLoading && 
             (receivedOrders.isEmpty && classifiedOrders.isEmpty && readyOrders.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Received orders (need classification)
                _OrderList(
                  orders: receivedOrders,
                  emptyMessage: 'Không có đơn hàng cần phân loại',
                  onTap: _navigateToClassification,
                  actionLabel: 'Phân loại ngay',
                ),

                // Tab 2: Classified orders
                _OrderList(
                  orders: classifiedOrders,
                  emptyMessage: 'Không có đơn hàng đã phân loại',
                  onTap: _navigateToAssignment,
                  actionLabel: 'Phân tài xế',
                ),

                // Tab 3: Ready orders
                _OrderList(
                  orders: readyOrders,
                  emptyMessage: 'Không có đơn hàng sẵn sàng',
                  onTap: null, // View only
                ),
              ],
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final String emptyMessage;
  final Function(Order)? onTap;
  final String? actionLabel;

  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              emptyMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh from parent
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(
            order: order,
            onTap: onTap != null ? () => onTap!(order) : null,
            actionLabel: actionLabel,
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _OrderCard({
    required this.order,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order code + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            order.orderCode,
                            style: AppTextStyles.heading3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: OrderStatus.getStatusColor(order.status)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      OrderStatus.getStatusName(order.status),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: OrderStatus.getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: AppSpacing.lg),

              // Package info
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.straighten,
                      label: PackageSize.getDisplayName(
                        order.packageSize ?? 'medium',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.scale,
                      label: order.weight != null
                          ? '${order.weight} kg'
                          : 'Chưa cân',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Addresses
              _AddressRow(
                icon: Icons.location_on,
                label: 'Lấy hàng',
                address: order.pickupAddress,
              ),
              const SizedBox(height: AppSpacing.xs),
              _AddressRow(
                icon: Icons.place,
                label: 'Giao hàng',
                address: order.deliveryAddress,
              ),

              // Classification info (if classified)
              if (order.zone != null || order.recommendedVehicle != null) ...[
                const Divider(height: AppSpacing.lg),
                Row(
                  children: [
                    if (order.zone != null)
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.map,
                          label: ZoneInfo.getDisplayName(order.zone!),
                          color: ZoneInfo.getColor(order.zone!),
                        ),
                      ),
                    if (order.zone != null && order.recommendedVehicle != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (order.recommendedVehicle != null)
                      Expanded(
                        child: _InfoChip(
                          icon: VehicleInfo.getIcon(
                            order.recommendedVehicle!,
                          ),
                          label: VehicleInfo.getDisplayName(
                            order.recommendedVehicle!,
                          ),
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ],

              // Action button
              if (onTap != null && actionLabel != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.category, size: 18),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: address),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

