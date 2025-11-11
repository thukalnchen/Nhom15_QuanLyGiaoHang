import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants.dart';
import '../../../services/admin_api_service.dart';
import '../../../providers/auth_provider.dart';

/// Story #21: Driver Assignment - Admin can assign drivers to orders
class DriverAssignmentScreen extends StatefulWidget {
  const DriverAssignmentScreen({super.key});

  @override
  State<DriverAssignmentScreen> createState() => _DriverAssignmentScreenState();
}

class _DriverAssignmentScreenState extends State<DriverAssignmentScreen> {
  List<Map<String, dynamic>> _unassignedOrders = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUnassignedOrders();
  }

  Future<void> _loadUnassignedOrders() async {
    try {
      print('🔵 [STORY21] Loading unassigned orders...');
      setState(() => _isLoading = true);
      
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      
      // Get all orders
      final allOrders = await AdminApiService.getAllOrders(token);
      
      // Filter orders that need driver assignment (status: confirmed, received_at_warehouse, classified)
      final needAssignment = allOrders.where((order) {
        final status = order['status']?.toString() ?? '';
        return status == 'confirmed' || 
               status == 'received_at_warehouse' || 
               status == 'classified' ||
               (status == 'pending' && order['driver_id'] == null);
      }).toList();
      
      print('🔵 [STORY21] Found ${needAssignment.length} orders needing driver assignment');
      
      setState(() {
        _unassignedOrders = needAssignment;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [STORY21] Error loading orders: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Công Tài Xế'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUnassignedOrders,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unassignedOrders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadUnassignedOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _unassignedOrders.length,
                    itemBuilder: (context, index) {
                      final order = _unassignedOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tất cả đơn hàng đã được phân tài xế',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Không có đơn hàng nào đang chờ phân công',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'pending';
    final hasDriver = order['driver_id'] != null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showAssignDriverDialog(order),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_number']?.toString() ?? 'N/A',
                          style: AppTextStyles.heading3,
                        ),
                        Text(
                          _getStatusLabel(status),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!hasDriver)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.warning, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Chưa có tài xế',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const Divider(height: AppSpacing.lg),
              
              // Sender info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.grey),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Người gửi', style: AppTextStyles.bodySmall),
                        Text(
                          order['sender_name']?.toString() ?? 'N/A',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Locations
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle, size: 12, color: Colors.green),
                      Container(
                        width: 2,
                        height: 20,
                        color: AppColors.grey.withOpacity(0.3),
                      ),
                      Icon(Icons.location_on, size: 16, color: Colors.red),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['pickup_location']?.toString() ?? 'N/A',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          order['delivery_location']?.toString() ?? 'N/A',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Vehicle & Amount
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: AppColors.grey),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _getVehicleLabel(order['vehicle_type']?.toString() ?? 'bike'),
                    style: AppTextStyles.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${order['total_amount']?.toString() ?? '0'}đ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Assign button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAssignDriverDialog(order),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: Text(hasDriver ? 'Đổi tài xế' : 'Phân công tài xế'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDriverDialog(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DriverSelectionScreen(
          order: order,
          onAssigned: () {
            _loadUnassignedOrders(); // Reload list after assignment
          },
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Chờ xử lý';
      case 'confirmed': return 'Đã xác nhận';
      case 'received_at_warehouse': return 'Đã nhận tại kho';
      case 'classified': return 'Đã phân loại';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'received_at_warehouse': return Colors.purple;
      case 'classified': return Colors.indigo;
      default: return AppColors.grey;
    }
  }

  String _getVehicleLabel(String vehicle) {
    switch (vehicle) {
      case 'motorcycle':
      case 'bike': return 'Xe máy';
      case 'van_500': return 'Van 500kg';
      case 'van_750': return 'Van 750kg';
      case 'van_1000': return 'Van 1000kg';
      case 'car': return 'Xe ô tô';
      case 'van': return 'Xe Van';
      case 'truck': return 'Xe tải';
      default: return vehicle;
    }
  }
}

// Driver Selection Screen
class _DriverSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAssigned;

  const _DriverSelectionScreen({
    required this.order,
    required this.onAssigned,
  });

  @override
  State<_DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<_DriverSelectionScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = false;
  String? _selectedDriverId;
  
  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      print('🔵 [STORY21] Loading available drivers...');
      setState(() => _isLoading = true);
      
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      
      final drivers = await AdminApiService.getAvailableDriversAdmin(token);
      
      print('🔵 [STORY21] Loaded ${drivers.length} drivers');
      
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [STORY21] Error loading drivers: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách tài xế: $e')),
        );
      }
    }
  }

  Future<void> _assignDriver() async {
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tài xế'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận phân công'),
        content: Text(
          'Phân công đơn hàng ${widget.order['order_number']} cho tài xế đã chọn?',
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
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final orderId = widget.order['id'];
      
      print('🔵 [STORY21] Assigning driver $_selectedDriverId to order $orderId');
      
      final result = await AdminApiService.assignDriverToOrder(
        token,
        orderId.toString(),
        _selectedDriverId!,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Phân công tài xế thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onAssigned(); // Notify parent to reload
        Navigator.pop(context); // Close driver selection screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Không thể phân công tài xế'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      print('❌ [STORY21] Error assigning driver: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Tài Xế'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrivers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Order info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.primary.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng: ${widget.order['order_number']}',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loại xe: ${_getVehicleLabel(widget.order['vehicle_type']?.toString() ?? 'bike')}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          
          // Drivers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _drivers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _drivers.length,
                        itemBuilder: (context, index) {
                          final driver = _drivers[index];
                          return _buildDriverCard(driver);
                        },
                      ),
          ),
          
          // Assign button
          if (!_isLoading && _drivers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedDriverId == null ? null : _assignDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Xác nhận phân công'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            'Vui lòng thử lại sau',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final driverId = driver['id']?.toString();
    final isSelected = _selectedDriverId == driverId;
    final driverName = driver['full_name']?.toString() ?? driver['name']?.toString() ?? 'N/A';
    final driverPhone = driver['phone']?.toString() ?? 'N/A';
    final vehicleType = driver['vehicle_type']?.toString() ?? 'bike';
    final currentOrders = int.tryParse(driver['current_orders']?.toString() ?? '0') ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDriverId = driverId;
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
                  color: isSelected ? AppColors.white : AppColors.grey,
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
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(driverPhone, style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 14,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getVehicleLabel(vehicleType),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    if (currentOrders > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Đơn hiện tại: $currentOrders',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.blue,
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
  }

  String _getVehicleLabel(String vehicle) {
    switch (vehicle) {
      case 'motorcycle':
      case 'bike': return 'Xe máy';
      case 'van_500': return 'Van 500kg';
      case 'van_750': return 'Van 750kg';
      case 'van_1000': return 'Van 1000kg';
      case 'car': return 'Xe ô tô';
      case 'van': return 'Xe Van';
      case 'truck': return 'Xe tải';
      default: return vehicle;
    }
  }
}
