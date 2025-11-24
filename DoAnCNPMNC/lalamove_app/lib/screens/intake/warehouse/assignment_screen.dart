import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/warehouse_provider.dart';
import '../../../utils/constants.dart';

/// Assignment Screen - Phân tài xế cho đơn hàng
/// Pattern: Giống web_admin dispatch modal
/// Flow: 
/// 1. Hiển thị thông tin đơn hàng
/// 2. Load danh sách tài xế khả dụng (theo vehicle_type)
/// 3. Cho phép chọn 1 tài xế
/// 4. Gọi API POST /warehouse/assign-driver
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableDrivers();
  }

  /// Load danh sách tài xế khả dụng
  /// Pattern giống web_admin: GET /admin/shippers/available
  /// Backend endpoint: GET /warehouse/drivers/available?vehicle_type=...
  Future<void> _loadAvailableDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    if (authProvider.token == null) {
      setState(() {
        _isLoadingDrivers = false;
        _errorMessage = 'Không có token xác thực';
      });
      return;
    }

    try {
      // Load drivers với vehicle type phù hợp với đơn hàng
      final vehicleType = widget.order.recommendedVehicle ?? 'bike';
      
      final drivers = await warehouseProvider.getAvailableDrivers(
        token: authProvider.token!,
        vehicleType: vehicleType,
      );

      if (mounted) {
        setState(() {
          _availableDrivers = drivers;
          _isLoadingDrivers = false;
          
          // Nếu không có tài xế nào
          if (drivers.isEmpty) {
            _errorMessage = 'Không có tài xế khả dụng cho loại xe ${VehicleInfo.getDisplayName(vehicleType)}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDrivers = false;
          _errorMessage = 'Lỗi tải danh sách tài xế: ${e.toString()}';
        });
      }
    }
  }

  /// Phân tài xế cho đơn hàng
  /// Pattern giống web_admin: assignSelectedOrders()
  /// Backend: POST /warehouse/assign-driver
  /// Body: {order_id, driver_id}
  Future<void> _assignDriver() async {
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn tài xế'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Tìm thông tin tài xế được chọn để hiển thị
    final selectedDriver = _availableDrivers.firstWhere(
      (d) => d['id']?.toString() == _selectedDriverId,
      orElse: () => {'name': 'Tài xế'},
    );

    // Xác nhận trước khi phân
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Row(
          children: [
            Icon(Icons.assignment_ind, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            const Text('Xác nhận phân tài xế'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân đơn hàng cho tài xế?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Đơn: ${widget.order.orderCode}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Tài xế: ${selectedDriver['name']}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('✓ Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    if (authProvider.token == null) {
      _showErrorSnackbar('Không có token xác thực');
      return;
    }

    // Gọi API phân tài xế
    final success = await warehouseProvider.assignDriver(
      token: authProvider.token!,
      orderId: widget.order.id,
      driverId: _selectedDriverId!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '✓ Đã phân tài xế ${selectedDriver['name']} thành công',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      // Quay lại màn hình trước và báo cần refresh
      Navigator.pop(context, true);
    } else {
      _showErrorSnackbar(
        warehouseProvider.errorMessage ?? 'Không thể phân tài xế',
      );
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehouseProvider = context.watch<WarehouseProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📋 Phân tài xế'),
        elevation: 0,
        actions: [
          // Refresh button - giống web admin
          IconButton(
            onPressed: _isLoadingDrivers ? null : _loadAvailableDrivers,
            icon: _isLoadingDrivers 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Làm mới danh sách',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order info card - Thông tin đơn hàng
            _OrderInfoCard(order: widget.order),

            const SizedBox(height: AppSpacing.lg),

            // Vehicle requirement section
            _VehicleRequirementCard(
              recommendedVehicle: widget.order.recommendedVehicle ?? 'bike',
              zone: widget.order.zone,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Available drivers header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Tài xế khả dụng',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_availableDrivers.length}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // Drivers list - Pattern giống web admin dispatch modal
            if (_isLoadingDrivers && _availableDrivers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.md),
                      Text('Đang tải danh sách tài xế...'),
                    ],
                  ),
                ),
              )
            else if (_availableDrivers.isEmpty)
              _EmptyDriversPlaceholder(
                vehicleType: widget.order.recommendedVehicle ?? 'bike',
              )
            else
              ..._availableDrivers.map((driver) {
                return _DriverCard(
                  driver: driver,
                  isSelected: _selectedDriverId == driver['id']?.toString(),
                  onTap: () {
                    setState(() {
                      _selectedDriverId = driver['id']?.toString();
                    });
                  },
                );
              }).toList(),

            const SizedBox(height: AppSpacing.xl),

            // Assign button - giống web admin "Gán đơn hàng"
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: warehouseProvider.isLoading || _selectedDriverId == null
                    ? null
                    : _assignDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 2,
                ),
                child: warehouseProvider.isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text('Đang xử lý...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_turned_in, size: 24),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Xác nhận phân tài xế',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGET COMPONENTS ====================

/// Card hiển thị thông tin đơn hàng
class _OrderInfoCard extends StatelessWidget {
  final Order order;

  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Mã đơn + trạng thái
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã đơn hàng',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        order.orderCode,
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: OrderStatus.getStatusColor(order.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: OrderStatus.getStatusColor(order.status),
                      width: 1,
                    ),
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
            
            // Địa chỉ lấy hàng
            _InfoRow(
              icon: Icons.store,
              iconColor: AppColors.success,
              label: 'Điểm lấy hàng',
              value: order.pickupAddress,
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Địa chỉ giao hàng
            _InfoRow(
              icon: Icons.location_on,
              iconColor: AppColors.error,
              label: 'Điểm giao hàng',
              value: order.deliveryAddress,
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Thông tin bưu kiện
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.inventory,
                    iconColor: AppColors.info,
                    label: 'Kích thước',
                    value: PackageSize.getDisplayName(
                      order.packageSize ?? 'medium',
                    ),
                  ),
                ),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.scale,
                    iconColor: AppColors.warning,
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

/// Card hiển thị yêu cầu phương tiện
class _VehicleRequirementCard extends StatelessWidget {
  final String recommendedVehicle;
  final String? zone;

  const _VehicleRequirementCard({
    required this.recommendedVehicle,
    this.zone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              VehicleInfo.getIcon(recommendedVehicle),
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YÊU CẦU PHƯƠNG TIỆN',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  VehicleInfo.getDisplayName(recommendedVehicle),
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (zone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.map,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Khu vực: ${ZoneInfo.getDisplayName(zone!)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state khi không có tài xế
class _EmptyDriversPlaceholder extends StatelessWidget {
  final String vehicleType;

  const _EmptyDriversPlaceholder({required this.vehicleType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Không có tài xế khả dụng',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Loại xe: ${VehicleInfo.getDisplayName(vehicleType)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Thử làm mới hoặc chọn loại xe khác',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card tài xế - Pattern giống web admin shipper option
class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final bool isSelected;
  final VoidCallback onTap;

  const _DriverCard({
    required this.driver,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final driverName = driver['name'] ?? 'Unknown';
    final driverPhone = driver['phone'] ?? '';
    final vehicleType = driver['vehicle_type'] ?? 'bike';
    // Parse current_orders to int (backend returns as String from PostgreSQL COUNT)
    final currentOrders = int.tryParse(driver['current_orders']?.toString() ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                        )
                      : null,
                  color: isSelected ? null : AppColors.grey.withOpacity(0.2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: isSelected
                      ? AppColors.white
                      : AppColors.grey.withOpacity(0.3),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: isSelected ? AppColors.primary : AppColors.grey,
                  ),
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driverPhone,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          VehicleInfo.getIcon(vehicleType),
                          size: 16,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          VehicleInfo.getDisplayName(vehicleType),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: currentOrders > 0
                                ? AppColors.warning.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 12,
                                color: currentOrders > 0
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$currentOrders đơn',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: currentOrders > 0
                                      ? AppColors.warning
                                      : AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppSpacing.sm),
              
              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.grey,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row hiển thị thông tin với icon
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
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

