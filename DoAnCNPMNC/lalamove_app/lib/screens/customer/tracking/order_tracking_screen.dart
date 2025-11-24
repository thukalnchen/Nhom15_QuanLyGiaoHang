import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _orderDetails;
  Map<String, dynamic>? _shipperLocation;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _orderDetails = widget.order;
    _loadOrderDetails();
    _loadShipperLocation();
    
    // Auto-refresh location every 10 seconds if order is in transit
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh location every 3 seconds if order is being delivered
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final order = _orderDetails ?? widget.order;
      final status = order['status']?.toString() ?? '';
      
      // Only auto-refresh if order is in transit or being delivered
      if (status == 'in_transit' || 
          status == 'picked_up' || 
          status == 'shipped' ||
          status == 'processing' ||
          status == 'ready_for_pickup' ||
          status == 'in_transit') {
        print('🔄 [${DateTime.now().toString().substring(11, 19)}] Auto-refreshing...');
        // Refresh both order details and location
        _loadOrderDetails();
        _loadShipperLocation();
      } else {
        print('⏸️ Auto-refresh paused - order status: $status');
      }
    });
  }

  Future<void> _loadOrderDetails() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final token = authProvider.token;
    
    if (token == null || _orderDetails == null) return;

    setState(() => _isLoading = true);

    final orderId = _orderDetails!['id'];
    if (orderId != null) {
      final success = await orderProvider.getOrderDetails(
        int.parse(orderId.toString()),
        token,
      );

      if (success && orderProvider.currentOrder != null) {
        final updatedOrder = orderProvider.currentOrder!;
        
        // Also check if shipper_location is in the order details response
        if (updatedOrder['shipper_location'] != null) {
          final shipperLoc = updatedOrder['shipper_location'];
          print('📍 Found shipper_location in order details: $shipperLoc');
          
          // Update shipper location if it exists
          setState(() {
            _orderDetails = updatedOrder;
            _shipperLocation = {
              'id': 'from_order_details',
              'latitude': shipperLoc['latitude'],
              'longitude': shipperLoc['longitude'],
              'created_at': shipperLoc['created_at'],
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            _orderDetails = updatedOrder;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadShipperLocation({bool showLoading = false}) async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    
    if (token == null || _orderDetails == null) {
      print('❌ Cannot load location: token or order details is null');
      return;
    }

    final orderId = _orderDetails!['id'];
    if (orderId == null) {
      print('❌ Cannot load location: orderId is null');
      return;
    }

    // Check if order has shipper assigned
    final order = _orderDetails ?? widget.order;
    if (order['shipper_id'] == null && order['driver_id'] == null) {
      print('ℹ️ Order chưa có shipper được phân công');
      if (mounted) {
        setState(() {
          _shipperLocation = null;
          _isLoadingLocation = false;
        });
      }
      return;
    }

    // Only show loading on manual refresh, not on auto-refresh
    if (showLoading && !_isLoadingLocation) {
      if (mounted) {
        setState(() => _isLoadingLocation = true);
      }
    }

    try {
      // Ensure orderId is a number, not a string
      final orderIdNum = orderId is int ? orderId : int.tryParse(orderId.toString());
      if (orderIdNum == null) {
        print('❌ Invalid orderId: $orderId');
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      final url = '${AppConstants.apiBaseUrl}${AppConstants.ordersEndpoint}/$orderIdNum/shipper-location';
      print('📍 [${DateTime.now().toString().substring(11, 19)}] ========== FETCHING LOCATION ==========');
      print('   Order ID: $orderIdNum (type: ${orderIdNum.runtimeType})');
      print('   URL: $url');
      print('   Token: ${token.substring(0, 20)}...');
      print('   Order details: shipper_id=${order['shipper_id']}, driver_id=${order['driver_id']}, status=${order['status']}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('📍 Response received:');
      print('   Status Code: ${response.statusCode}');
      print('   Body length: ${response.body.length}');

      print('📍 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📍 Response data: ${data.toString().substring(0, data.toString().length > 300 ? 300 : data.toString().length)}');
        
        if (data['status'] == 'success' && data['data'] != null && data['data']['location'] != null) {
          final newLocation = data['data']['location'];
          final newLocationId = newLocation['id']?.toString();
          final currentLocationId = _shipperLocation?['id']?.toString();
          final newLat = newLocation['latitude'];
          final newLng = newLocation['longitude'];
          final currentLat = _shipperLocation?['latitude'];
          final currentLng = _shipperLocation?['longitude'];
          
          print('✅ Got shipper location: lat=$newLat, lng=$newLng, id=$newLocationId');
          print('   Current: lat=$currentLat, lng=$currentLng, id=$currentLocationId');
          
          // Check if location changed (by ID or coordinates)
          final locationChanged = newLocationId != currentLocationId ||
              (newLat != null && currentLat != null && (newLat != currentLat || newLng != currentLng));
          
          if (locationChanged) {
            print('🆕 New location detected! Updating UI...');
            if (mounted) {
              setState(() {
                _shipperLocation = newLocation;
                _isLoadingLocation = false;
              });
              
              // Show snackbar notification only if not from auto-refresh
              if (showLoading) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('📍 Vị trí tài xế đã được cập nhật'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          } else {
            print('ℹ️ Location unchanged');
            if (mounted) {
              setState(() => _isLoadingLocation = false);
            }
          }
        } else {
          print('⚠️ No location data in response');
          if (mounted) {
            setState(() {
              _shipperLocation = null;
              _isLoadingLocation = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        // Shipper hasn't checked in yet - this is normal
        print('ℹ️ Shipper chưa check-in vị trí (404)');
        if (mounted) {
          setState(() {
            _shipperLocation = null;
            _isLoadingLocation = false;
          });
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error';
        print('❌ Error fetching location: ${response.statusCode} - $errorMessage');
        
        // Show user-friendly error message
        if (mounted && showLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $errorMessage'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
      }
    } catch (e) {
      print('❌ Exception fetching location: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _orderDetails ?? widget.order;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Theo dõi ${order['order_number'] ?? 'Đơn hàng'}'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.dark),
        actions: [
          IconButton(
            icon: _isLoadingLocation 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoadingLocation ? null : () {
              _loadOrderDetails();
              _loadShipperLocation(showLoading: true);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadOrderDetails();
                await _loadShipperLocation(showLoading: true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Status Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppUtils.getStatusColor(order['status']),
                            AppUtils.getStatusColor(order['status']).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppUtils.getStatusColor(order['status']).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStatusIcon(order['status']),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppUtils.getStatusText(order['status']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusDescription(order['status']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Status Timeline
                    if (order['status_history'] != null && 
                        (order['status_history'] as List).isNotEmpty)
                      _buildStatusTimeline(order['status_history'] as List),

                    // Shipper Location (if available)
                    if (_shipperLocation != null)
                      _buildShipperLocationCard(),

                    // Route Information
                    _buildRouteCard(order),

                    // Contact Information
                    if (order['shipper_id'] != null || order['driver_name'] != null)
                      _buildContactCard(order),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusTimeline(List<dynamic> statusHistory) {
    if (statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedHistory = List<Map<String, dynamic>>.from(statusHistory)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] ?? '');
        final dateB = DateTime.parse(b['created_at'] ?? '');
        return dateA.compareTo(dateB);
      });

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Lịch sử trạng thái',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(sortedHistory.length, (index) {
            final historyItem = sortedHistory[index];
            final isLast = index == sortedHistory.length - 1;
            final status = historyItem['status']?.toString() ?? '';
            final notes = historyItem['notes']?.toString();
            final createdAt = historyItem['created_at']?.toString();
            
            DateTime? dateTime;
            if (createdAt != null) {
              try {
                dateTime = DateTime.parse(createdAt);
              } catch (e) {
                dateTime = null;
              }
            }

            return _buildTimelineItem(
              status: status,
              notes: notes,
              dateTime: dateTime,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String status,
    String? notes,
    DateTime? dateTime,
    required bool isLast,
  }) {
    final statusText = _getStatusDisplayText(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIconForTimeline(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.lightGrey,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (dateTime != null)
                      Text(
                        _formatTime(dateTime),
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                  ],
                ),
                if (dateTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(dateTime),
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notes,
                      style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShipperLocationCard() {
    final order = _orderDetails ?? widget.order;
    final status = order['status']?.toString() ?? '';
    
    // Show location card if order has shipper assigned and is in transit
    final hasShipper = order['shipper_id'] != null || order['driver_id'] != null;
    final isInTransit = status == 'in_transit' || 
        status == 'picked_up' || 
        status == 'shipped' ||
        status == 'processing' ||
        status == 'ready_for_pickup';
    
    if (!hasShipper || !isInTransit) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Vị trí tài xế',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () => _loadShipperLocation(showLoading: true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingLocation && _shipperLocation == null)
            const Center(child: CircularProgressIndicator())
          else if (_shipperLocation != null) ...[
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                const Text(
                  'Đã cập nhật vị trí',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_shipperLocation!['address'] != null) ...[
              Row(
                children: [
                  Icon(Icons.place, size: 16, color: AppColors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _shipperLocation!['address'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.grey),
                const SizedBox(width: 8),
                Text(
                  'Cập nhật: ${_formatDateTime(_shipperLocation!['created_at'])}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
            if (_shipperLocation!['latitude'] != null && _shipperLocation!['longitude'] != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open map with shipper location
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng bản đồ sẽ được tích hợp')),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Xem trên bản đồ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài xế chưa check-in vị trí. Vị trí sẽ được cập nhật tự động khi tài xế check-in.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Tuyến đường',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRoutePoint(
            icon: Icons.circle,
            iconColor: AppColors.primary,
            title: 'Điểm đón hàng',
            address: order['pickup_address'] ?? 'Không có thông tin',
          ),
          const SizedBox(height: 16),
          _buildRoutePoint(
            icon: Icons.location_on,
            iconColor: Colors.green,
            title: 'Điểm giao hàng',
            address: order['delivery_address'] ?? 'Không có thông tin',
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Thông tin liên hệ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (order['driver_name'] != null || order['shipper_name'] != null)
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['driver_name'] ?? order['shipper_name'] ?? 'Tài xế',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (order['driver_phone'] != null || order['shipper_phone'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          order['driver_phone'] ?? order['shipper_phone'] ?? '',
                          style: const TextStyle(color: AppColors.grey, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                if (order['driver_phone'] != null || order['shipper_phone'] != null)
                  IconButton(
                    onPressed: () {
                      // TODO: Call driver
                      final phone = order['driver_phone'] ?? order['shipper_phone'];
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gọi: $phone')),
                      );
                    },
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.access_time;
      case AppConstants.statusProcessing:
        return Icons.local_shipping;
      case AppConstants.statusShipped:
        return Icons.delivery_dining;
      case AppConstants.statusDelivered:
        return Icons.check_circle;
      case AppConstants.statusCancelled:
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getStatusDescription(String? status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Đơn hàng đang chờ xác nhận';
      case AppConstants.statusProcessing:
        return 'Đang tìm tài xế';
      case AppConstants.statusShipped:
        return 'Đang trên đường giao hàng';
      case AppConstants.statusDelivered:
        return 'Đã giao hàng thành công';
      case AppConstants.statusCancelled:
        return 'Đơn hàng đã bị hủy';
      default:
        return '';
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'warehouse_received':
        return 'Đã nhận vào kho';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'ready_for_pickup':
        return 'Sẵn sàng lấy hàng';
      case 'picked_up':
        return 'Đã lấy hàng';
      case 'in_transit':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      case 'returned':
        return 'Đã trả lại';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'warehouse_received':
      case 'preparing':
        return AppColors.info;
      case 'ready_for_pickup':
      case 'picked_up':
        return AppColors.primary;
      case 'in_transit':
        return AppColors.primaryDark;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
      case 'returned':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  IconData _getStatusIconForTimeline(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'warehouse_received':
        return Icons.warehouse;
      case 'preparing':
        return Icons.build_circle_outlined;
      case 'ready_for_pickup':
        return Icons.shopping_bag_outlined;
      case 'picked_up':
        return Icons.inventory_2_outlined;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'returned':
        return Icons.undo;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Hôm nay';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${_formatTime(dateTime)} - ${_formatDate(dateTime)}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}

