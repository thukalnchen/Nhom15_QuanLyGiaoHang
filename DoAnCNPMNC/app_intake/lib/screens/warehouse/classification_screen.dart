import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../utils/constants.dart';

class ClassificationScreen extends StatefulWidget {
  final Order order;

  const ClassificationScreen({super.key, required this.order});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  bool _isCalculating = false;
  double? _calculatedDistance;
  String? _suggestedZone;
  String? _suggestedVehicle;
  
  // User can override suggestions
  String? _selectedZone;
  String? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _calculateDistanceAndSuggest();
  }

  Future<void> _calculateDistanceAndSuggest() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      // TODO: Integrate with Google Maps Distance Matrix API or calculate using coordinates
      // For now, using mock calculation based on straight-line distance
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Mock calculation (in real app, use actual coordinates)
      // Format: "Địa chỉ A, Quận B, TP.HCM"
      final distance = _mockCalculateDistance(
        widget.order.pickupAddress,
        widget.order.deliveryAddress,
      );

      final zone = _suggestZone(distance);
      final vehicle = _suggestVehicle(
        widget.order.packageSize ?? 'medium',
        distance,
      );

      setState(() {
        _calculatedDistance = distance;
        _suggestedZone = zone;
        _suggestedVehicle = vehicle;
        _selectedZone = zone; // Default to suggested
        _selectedVehicle = vehicle; // Default to suggested
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tính khoảng cách: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Mock distance calculation - In production, use Google Maps API
  double _mockCalculateDistance(String pickup, String delivery) {
    // Simple mock: random distance between 2-25km
    // In real app: use Geolocator or Google Distance Matrix API
    final pickupHash = pickup.hashCode.abs();
    final deliveryHash = delivery.hashCode.abs();
    final distance = ((pickupHash + deliveryHash) % 23) + 2.0;
    return distance;
  }

  String _suggestZone(double distanceKm) {
    if (distanceKm <= 5) return 'zone_1';
    if (distanceKm <= 10) return 'zone_2';
    if (distanceKm <= 20) return 'zone_3';
    return 'zone_4';
  }

  String _suggestVehicle(String packageSize, double distanceKm) {
    // Primary: package size
    switch (packageSize) {
      case 'small':
        return 'bike';
      case 'medium':
        // If distance > 15km, upgrade to car for comfort
        return distanceKm > 15 ? 'car' : 'bike';
      case 'large':
        return 'van';
      case 'extra_large':
        return 'truck';
      default:
        return 'car';
    }
  }

  Future<void> _submitClassification() async {
    if (_selectedZone == null || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khu vực và loại xe'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if override from customer request
    bool needsConfirmation = false;
    String? overrideMessage;
    
    if (widget.order.customerRequestedVehicle != null &&
        _selectedVehicle != widget.order.customerRequestedVehicle) {
      needsConfirmation = true;
      overrideMessage = 
          'Bạn đang chọn ${VehicleInfo.getDisplayName(_selectedVehicle!)} '
          'khác với yêu cầu của khách (${VehicleInfo.getDisplayName(widget.order.customerRequestedVehicle!)}).\n\n'
          'Phí giao hàng có thể thay đổi. Tiếp tục?';
    }

    // Show confirmation dialog if override
    if (needsConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.warning),
              SizedBox(width: AppSpacing.sm),
              Text('Xác nhận thay đổi'),
            ],
          ),
          content: Text(overrideMessage!),
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
    }

    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    if (authProvider.token == null) return;

    final success = await warehouseProvider.classifyOrder(
      token: authProvider.token!,
      orderId: widget.order.id,
      zone: _selectedZone!,
      recommendedVehicle: _selectedVehicle!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phân loại thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true); // Return true to refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            warehouseProvider.errorMessage ?? 'Không thể phân loại đơn hàng',
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
        title: const Text('Phân loại gói hàng'),
      ),
      body: _isCalculating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Đang tính toán khoảng cách...',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order info card
                  _OrderInfoCard(order: widget.order),

                  const SizedBox(height: AppSpacing.lg),

                  // Distance & Route info
                  if (_calculatedDistance != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.route,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Thông tin tuyến đường',
                                  style: AppTextStyles.heading3,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _InfoRow(
                              icon: Icons.straighten,
                              label: 'Khoảng cách ước tính',
                              value: '${_calculatedDistance!.toStringAsFixed(1)} km',
                              valueColor: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _InfoRow(
                              icon: Icons.access_time,
                              label: 'Thời gian ước tính',
                              value: '${(_calculatedDistance! * 3).round()} phút',
                              valueColor: AppColors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Zone classification
                  Text(
                    'Phân khu vực giao hàng',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_suggestedZone != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Gợi ý: ${ZoneInfo.getDisplayName(_suggestedZone!)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),

                  // Zone selection
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ZoneInfo.getAllZones().map((zone) {
                      final isSelected = _selectedZone == zone;
                      final isSuggested = _suggestedZone == zone;
                      
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ZoneInfo.getDisplayName(zone)),
                            if (isSuggested) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.star, size: 14),
                            ],
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedZone = zone;
                          });
                        },
                        selectedColor: ZoneInfo.getColor(zone).withOpacity(0.7),
                        backgroundColor: ZoneInfo.getColor(zone).withOpacity(0.2),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Vehicle recommendation
                  Text(
                    'Đề xuất phương tiện',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Customer requested vehicle (if available)
                  if (widget.order.customerRequestedVehicle != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Khách yêu cầu: ${VehicleInfo.getDisplayName(widget.order.customerRequestedVehicle!)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_suggestedVehicle != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Hệ thống gợi ý: ${VehicleInfo.getDisplayName(_suggestedVehicle!)} (Dựa trên kích thước: ${PackageSize.getDisplayName(widget.order.packageSize ?? 'medium')})',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),

                  // Vehicle selection
                  ...VehicleInfo.getAllVehicles().map((vehicle) {
                    final isSelected = _selectedVehicle == vehicle;
                    final isSuggested = _suggestedVehicle == vehicle;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                            _selectedVehicle = vehicle;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Icon(
                                VehicleInfo.getIcon(vehicle),
                                size: 32,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.grey,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          VehicleInfo.getDisplayName(vehicle),
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.primary
                                                : null,
                                          ),
                                        ),
                                        if (isSuggested) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: AppColors.warning,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      VehicleInfo.getDescription(vehicle),
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: AppSpacing.xl),

                  // Submit button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: warehouseProvider.isLoading
                          ? null
                          : _submitClassification,
                      child: warehouseProvider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Xác nhận phân loại'),
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
              ],
            ),
            const Divider(height: AppSpacing.lg),
            _InfoRow(
              icon: Icons.person,
              label: 'Người gửi',
              value: order.customerName,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.straighten,
              label: 'Kích thước',
              value: PackageSize.getDisplayName(order.packageSize ?? 'medium'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.scale,
              label: 'Cân nặng',
              value: order.weight != null ? '${order.weight} kg' : 'Chưa cân',
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.category,
              label: 'Loại hàng',
              value: PackageType.getDisplayName(order.packageType ?? 'parcel'),
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
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
