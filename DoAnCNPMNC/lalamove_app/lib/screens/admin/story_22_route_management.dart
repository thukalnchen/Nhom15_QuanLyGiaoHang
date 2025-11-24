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
    );
  }

  Widget _buildZonesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: _addZone,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Khu Vực'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _zones.length,
            itemBuilder: (context, index) {
              final zone = _zones[index];
              return _buildZoneCard(context, zone);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoneCard(BuildContext context, Map<String, dynamic> zone) {
    final isActive = zone['is_active'] == true;
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
                        zone['zone_name'] ?? zone['zoneName'] ?? 'N/A',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Mã: ${zone['zone_code'] ?? zone['zoneCode'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    isActive ? 'Hoạt động' : 'Tạm dừng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _editZone(zone),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteZone(zone),
                ),
              ],
            ),
            if (zone['description'] != null && zone['description'].toString().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                zone['description'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá cơ bản:', style: TextStyle(fontSize: 12)),
                      Text('${zone['base_price'] ?? zone['basePrice'] ?? 0} VND', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá/km:', style: TextStyle(fontSize: 12)),
                      Text('${zone['price_per_km'] ?? zone['pricePerKm'] ?? 0} VND', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildRoutesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: _addRoute,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Tuyến Đường'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _routes.length,
            itemBuilder: (context, index) {
              final route = _routes[index];
              return _buildRouteCard(context, route);
            },
          ),
        ),
      ],
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
                        route['route_name'] ?? route['routeName'] ?? 'N/A',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Mã: ${route['route_code'] ?? route['routeCode'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _editRoute(route),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: Colors.green),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    route['start_point'] ?? route['startPoint'] ?? 'N/A',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    route['end_point'] ?? route['endPoint'] ?? 'N/A',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Khoảng cách', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(
                        '${route['total_distance'] ?? route['totalDistance'] ?? '0'} km',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Trạng thái', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(
                        _getRouteStatusText(route['status']),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
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

  String _getRouteStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'Đang hoạt động';
      case 'planned':
        return 'Đã lên kế hoạch';
      case 'inactive':
        return 'Tạm dừng';
      default:
        return 'N/A';
    }
  }

  void _addZone() async {
    final zoneCodeController = TextEditingController();
    final zoneNameController = TextEditingController();
    final descController = TextEditingController();
    final basePriceController = TextEditingController(text: '15000');
    final pricePerKmController = TextEditingController(text: '3000');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Khu Vực'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: zoneCodeController,
                decoration: const InputDecoration(
                  labelText: 'Mã khu vực *',
                  hintText: 'VD: Q1, TD',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: zoneNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khu vực *',
                  hintText: 'VD: Quận 1',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả khu vực',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: basePriceController,
                decoration: const InputDecoration(
                  labelText: 'Giá cơ bản (VND) *',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: pricePerKmController,
                decoration: const InputDecoration(
                  labelText: 'Giá/km (VND) *',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (zoneCodeController.text.isEmpty || zoneNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin bắt buộc')),
        );
        return;
      }

      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final response = await AdminApiService.createZone(token, {
        'zoneCode': zoneCodeController.text.toUpperCase(),
        'zoneName': zoneNameController.text,
        'description': descController.text.isEmpty ? null : descController.text,
        'basePrice': double.tryParse(basePriceController.text) ?? 0,
        'pricePerKm': double.tryParse(pricePerKmController.text) ?? 0,
      });

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm thành công')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thêm thất bại: ${response['message']}')),
          );
        }
      }
    }
  }

  void _editZone(Map<String, dynamic> zone) async {
    final zoneNameController = TextEditingController(text: zone['zone_name'] ?? zone['zoneName']);
    final descController = TextEditingController(text: zone['description'] ?? '');
    final basePriceController = TextEditingController(text: (zone['base_price'] ?? zone['basePrice'])?.toString());
    final pricePerKmController = TextEditingController(text: (zone['price_per_km'] ?? zone['pricePerKm'])?.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật Khu Vực'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: zoneNameController,
                decoration: const InputDecoration(labelText: 'Tên khu vực *'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: basePriceController,
                decoration: const InputDecoration(labelText: 'Giá cơ bản (VND) *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: pricePerKmController,
                decoration: const InputDecoration(labelText: 'Giá/km (VND) *'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final response = await AdminApiService.updateZone(
        token,
        zone['id'],
        {
          'zoneName': zoneNameController.text,
          'description': descController.text.isEmpty ? null : descController.text,
          'basePrice': double.tryParse(basePriceController.text) ?? 0,
          'pricePerKm': double.tryParse(pricePerKmController.text) ?? 0,
        },
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thành công')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cập nhật thất bại: ${response['message']}')),
          );
        }
      }
    }
  }

  void _deleteZone(Map<String, dynamic> zone) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có muốn xóa khu vực "${zone['zone_name'] ?? zone['zoneName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      final success = await AdminApiService.deleteZone(token, zone['id']);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thành công')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thất bại')),
        );
      }
    }
  }

  void _addRoute() async {
    await showDialog(
      context: context,
      builder: (context) => _AddRouteDialog(
        zones: _zones,
        onSave: (routeData) async {
          final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
          final response = await AdminApiService.createRoute(token, routeData);
          
          if (mounted) {
            if (response['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thêm thành công')),
              );
              _loadData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Thêm thất bại: ${response['message']}')),
              );
            }
          }
        },
      ),
    );
  }

  void _editRoute(Map<String, dynamic> route) async {
    await showDialog(
      context: context,
      builder: (context) => _EditRouteDialog(
        route: route,
        zones: _zones,
        onSave: (routeData) async {
          final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
          final response = await AdminApiService.updateRoute(token, route['id'], routeData);
          
          if (mounted) {
            if (response['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật thành công')),
              );
              _loadData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cập nhật thất bại: ${response['message']}')),
              );
            }
          }
        },
      ),
    );
  }
}

// Dialog widget for adding route with dropdown
class _AddRouteDialog extends StatefulWidget {
  final List<Map<String, dynamic>> zones;
  final Function(Map<String, dynamic>) onSave;

  const _AddRouteDialog({
    required this.zones,
    required this.onSave,
  });

  @override
  State<_AddRouteDialog> createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<_AddRouteDialog> {
  final routeCodeController = TextEditingController();
  final routeNameController = TextEditingController();
  final startPointController = TextEditingController();
  final endPointController = TextEditingController();
  final distanceController = TextEditingController();
  int? selectedZoneId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Tuyến Đường'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: routeCodeController,
              decoration: const InputDecoration(
                labelText: 'Mã tuyến *',
                hintText: 'VD: R001',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: routeNameController,
              decoration: const InputDecoration(
                labelText: 'Tên tuyến *',
                hintText: 'VD: Tuyến Q1-Q3',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              value: selectedZoneId,
              decoration: const InputDecoration(labelText: 'Khu vực'),
              items: widget.zones.map((zone) {
                return DropdownMenuItem<int>(
                  value: zone['id'],
                  child: Text(zone['zone_name'] ?? zone['zoneName'] ?? 'N/A'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedZoneId = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: startPointController,
              decoration: const InputDecoration(
                labelText: 'Điểm bắt đầu *',
                hintText: 'VD: Nhà Opera',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: endPointController,
              decoration: const InputDecoration(
                labelText: 'Điểm kết thúc *',
                hintText: 'VD: Công Viên Tao Đàn',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(
                labelText: 'Khoảng cách (km)',
                hintText: '3.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            if (routeCodeController.text.isEmpty || routeNameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin bắt buộc')),
              );
              return;
            }

            widget.onSave({
              'routeCode': routeCodeController.text.toUpperCase(),
              'routeName': routeNameController.text,
              'zoneId': selectedZoneId,
              'startPoint': startPointController.text.isEmpty ? null : startPointController.text,
              'endPoint': endPointController.text.isEmpty ? null : endPointController.text,
              'totalDistance': double.tryParse(distanceController.text),
              'status': 'planned',
            });
            
            Navigator.pop(context);
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    routeCodeController.dispose();
    routeNameController.dispose();
    startPointController.dispose();
    endPointController.dispose();
    distanceController.dispose();
    super.dispose();
  }
}

// Dialog widget for editing route with dropdown
class _EditRouteDialog extends StatefulWidget {
  final Map<String, dynamic> route;
  final List<Map<String, dynamic>> zones;
  final Function(Map<String, dynamic>) onSave;

  const _EditRouteDialog({
    required this.route,
    required this.zones,
    required this.onSave,
  });

  @override
  State<_EditRouteDialog> createState() => _EditRouteDialogState();
}

class _EditRouteDialogState extends State<_EditRouteDialog> {
  late TextEditingController routeNameController;
  late TextEditingController startPointController;
  late TextEditingController endPointController;
  late TextEditingController distanceController;
  late int? selectedZoneId;

  @override
  void initState() {
    super.initState();
    routeNameController = TextEditingController(text: widget.route['route_name'] ?? widget.route['routeName']);
    startPointController = TextEditingController(text: widget.route['start_point'] ?? widget.route['startPoint']);
    endPointController = TextEditingController(text: widget.route['end_point'] ?? widget.route['endPoint']);
    distanceController = TextEditingController(text: (widget.route['total_distance'] ?? widget.route['totalDistance'])?.toString());
    selectedZoneId = widget.route['zone_id'] ?? widget.route['zoneId'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cập nhật Tuyến Đường'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: routeNameController,
              decoration: const InputDecoration(labelText: 'Tên tuyến *'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              value: selectedZoneId,
              decoration: const InputDecoration(labelText: 'Khu vực'),
              items: widget.zones.map((zone) {
                return DropdownMenuItem<int>(
                  value: zone['id'],
                  child: Text(zone['zone_name'] ?? zone['zoneName'] ?? 'N/A'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedZoneId = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: startPointController,
              decoration: const InputDecoration(labelText: 'Điểm bắt đầu *'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: endPointController,
              decoration: const InputDecoration(labelText: 'Điểm kết thúc *'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(labelText: 'Khoảng cách (km)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave({
              'routeName': routeNameController.text,
              'zoneId': selectedZoneId,
              'startPoint': startPointController.text.isEmpty ? null : startPointController.text,
              'endPoint': endPointController.text.isEmpty ? null : endPointController.text,
              'totalDistance': double.tryParse(distanceController.text),
            });
            
            Navigator.pop(context);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    routeNameController.dispose();
    startPointController.dispose();
    endPointController.dispose();
    distanceController.dispose();
    super.dispose();
  }
}
