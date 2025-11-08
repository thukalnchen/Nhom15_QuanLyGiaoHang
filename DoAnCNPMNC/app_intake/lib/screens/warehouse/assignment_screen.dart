import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../utils/constants.dart';

class AssignmentScreen extends StatefulWidget {
  final Order order;

  const AssignmentScreen({super.key, required this.order});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  String? _selectedDriverId;
  bool _isLoadingDrivers = false;
  List<Map<String, dynamic>> _availableDrivers = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableDrivers();
  }

  Future<void> _loadAvailableDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
    });

    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    if (authProvider.token == null) return;

    // Load drivers with matching vehicle type
    final vehicleType = widget.order.recommendedVehicle ?? 'bike';
    
    final drivers = await warehouseProvider.getAvailableDrivers(
      token: authProvider.token!,
      vehicleType: vehicleType,
    );

    if (mounted) {
      setState(() {
        _availableDrivers = drivers;
        _isLoadingDrivers = false;
      });
    }
  }

  Future<void> _assignDriver() async {
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tài xế'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận phân tài xế'),
        content: Text(
          'Phân đơn hàng ${widget.order.orderCode} cho tài xế đã chọn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    if (authProvider.token == null) return;

    final success = await warehouseProvider.assignDriver(
      token: authProvider.token!,
      orderId: widget.order.id,
      driverId: _selectedDriverId!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã phân tài xế thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true); // Return true to refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            warehouseProvider.errorMessage ?? 'Không thể phân tài xế',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehouseProvider = context.watch<WarehouseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tài xế'),
        actions: [
          IconButton(
            onPressed: _loadAvailableDrivers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order info card
            _OrderInfoCard(order: widget.order),

            const SizedBox(height: AppSpacing.lg),

            // Vehicle requirement
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    VehicleInfo.getIcon(widget.order.recommendedVehicle ?? 'bike'),
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yêu cầu phương tiện',
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          VehicleInfo.getDisplayName(
                            widget.order.recommendedVehicle ?? 'bike',
                          ),
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          widget.order.zone != null
                              ? 'Khu vực: ${ZoneInfo.getDisplayName(widget.order.zone!)}'
                              : '',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Available drivers section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tài xế khả dụng (${_availableDrivers.length})',
                  style: AppTextStyles.heading3,
                ),
                if (_isLoadingDrivers)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Drivers list
            if (_isLoadingDrivers && _availableDrivers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_availableDrivers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: AppColors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Không có tài xế khả dụng',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Loại xe: ${VehicleInfo.getDisplayName(widget.order.recommendedVehicle ?? 'bike')}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._availableDrivers.map((driver) {
                final isSelected = _selectedDriverId == driver['id'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDriverId = driver['id'];
                      });
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.grey.withOpacity(0.3),
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.grey,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          
                          // Driver info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver['name'] ?? 'Unknown',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: AppColors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      driver['phone'] ?? '',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      VehicleInfo.getIcon(
                                        driver['vehicle_type'] ?? 'bike',
                                      ),
                                      size: 14,
                                      color: AppColors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      VehicleInfo.getDisplayName(
                                        driver['vehicle_type'] ?? 'bike',
                                      ),
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                                if (driver['current_orders'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Đơn hiện tại: ${driver['current_orders']}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.info,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Selection indicator
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: AppSpacing.xl),

            // Assign button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: warehouseProvider.isLoading || _selectedDriverId == null
                    ? null
                    : _assignDriver,
                child: warehouseProvider.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Xác nhận phân tài xế'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  final Order order;

  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mã đơn hàng', style: AppTextStyles.bodySmall),
                      Text(order.orderCode, style: AppTextStyles.heading3),
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
            _InfoRow(
              icon: Icons.location_on,
              label: 'Lấy hàng',
              value: order.pickupAddress,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.place,
              label: 'Giao hàng',
              value: order.deliveryAddress,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.straighten,
                    label: 'Kích thước',
                    value: PackageSize.getDisplayName(
                      order.packageSize ?? 'medium',
                    ),
                  ),
                ),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.scale,
                    label: 'Cân nặng',
                    value: order.weight != null ? '${order.weight} kg' : 'N/A',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
