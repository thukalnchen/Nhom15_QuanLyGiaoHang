import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/constants.dart';

class OrderDetailArguments {
  final int orderId;

  const OrderDetailArguments({required this.orderId});
}

class OrderDetailScreen extends StatefulWidget {
  static const String routeName = '/orders/detail';

  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  final Completer<GoogleMapController> _mapController = Completer();
  DateTime? _lastCheckInTime;
  bool _isCheckingIn = false; // Flag to prevent multiple simultaneous check-ins
  bool _isUpdatingStatus = false; // Flag to prevent multiple simultaneous status updates

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OrderDetailArguments) {
      Future.microtask(() => _loadOrder(args.orderId));
    }
  }

  Future<void> _loadOrder(int orderId) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    await context.read<OrderProvider>().fetchOrderDetails(token, orderId);
  }

  // Normalize status to ensure consistent comparison
  String _normalizeStatus(String status) {
    if (status.isEmpty) return status;
    
    final statusLower = status.toLowerCase().trim();
    
    // Map various status formats to standard format
    if (statusLower == 'assigned_to_driver' || 
        statusLower == 'assigned-to-driver' ||
        statusLower == 'assigned') {
      return OrderStatus.assigned;
    }
    
    if (statusLower == 'in_transit' || 
        statusLower == 'in-transit' ||
        statusLower == 'delivering' ||
        statusLower == 'shipped' ||
        statusLower == 'processing') {
      return OrderStatus.inTransit;
    }
    
    if (statusLower == 'delivered' || 
        statusLower == 'delivered_success' ||
        statusLower == 'delivered-success') {
      return OrderStatus.delivered;
    }
    
    if (statusLower == 'failed_delivery' || 
        statusLower == 'failed-delivery' ||
        statusLower == 'delivery_failed' ||
        statusLower == 'delivery-failed') {
      return OrderStatus.failed;
    }
    
    if (statusLower == 'cancelled' || statusLower == 'canceled') {
      return OrderStatus.failed;
    }
    
    return statusLower;
  }

  // Check if check-in button should be shown for this order status
  bool _shouldShowCheckIn(String status) {
    if (status.isEmpty) return false;
    
    final normalized = _normalizeStatus(status);
    
    // Don't show for completed/failed/cancelled statuses
    if (normalized == OrderStatus.delivered || 
        normalized == OrderStatus.failed) {
      return false;
    }
    
    // Show for all active statuses where shipper is handling the order
    // This includes: assigned, processing, shipped, in_transit, etc.
    // Since this is shipper app, if shipper can see the order, they can check-in
    return true;
  }

  Future<void> _updateStatus(int orderId, String status, {String? notes, String? reason}) async {
    // Prevent multiple simultaneous status updates
    if (_isUpdatingStatus) {
      debugPrint('⚠️ Status update already in progress, ignoring duplicate call');
      return;
    }
    
    setState(() {
      _isUpdatingStatus = true;
    });
    
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) {
        if (mounted) {
          setState(() {
            _isUpdatingStatus = false;
          });
        }
        return;
      }
      
      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.updateOrderStatus(token, orderId, status, notes: notes, reason: reason);
      
      if (!mounted) {
        return;
      }
      
      if (success) {
        // Update local state immediately for better UX
        // The provider already updates the order status in updateOrderStatus
        // So we just need to trigger a rebuild
        if (mounted) {
          setState(() {
            _isUpdatingStatus = false;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công')),
        );
        
        // Reload order in background to get full updated data
        // Don't await to avoid blocking UI
        if (mounted) {
          _loadOrder(orderId).catchError((error) {
            debugPrint('❌ Error reloading order: $error');
          });
        }
      } else {
        // Reset flag on error
        if (mounted) {
          setState(() {
            _isUpdatingStatus = false;
          });
        }
        
        if (orderProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(orderProvider.error!)),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _updateStatus: $e');
      if (!mounted) return;
      
      // Reset flag on error
      setState(() {
        _isUpdatingStatus = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // US-17: Check-in location
  Future<void> _checkInLocation(int orderId) async {
    // Prevent multiple simultaneous check-ins
    if (_isCheckingIn) {
      debugPrint('⚠️ Check-in already in progress, ignoring duplicate call');
      return;
    }
    
    debugPrint('🔄 _checkInLocation called for orderId: $orderId');
    
    setState(() {
      _isCheckingIn = true;
    });
    
    bool loadingDialogShown = false;
    
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) {
        debugPrint('❌ Token is null');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập lại')),
        );
        return;
      }

      debugPrint('✅ Token exists, checking location service...');

      // Check location service enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location service is disabled');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật dịch vụ định vị trên thiết bị')),
        );
        return;
      }

      debugPrint('✅ Location service is enabled, checking permission...');

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Current permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        debugPrint('📍 Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Permission still denied');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền truy cập vị trí để check-in')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permission denied forever');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng cấp quyền truy cập vị trí trong cài đặt')),
        );
        return;
      }

      debugPrint('✅ Permission granted, showing loading dialog...');

      // Get current location
      if (!mounted) return;
      loadingDialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        debugPrint('📍 Getting current position...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        debugPrint('✅ Got position: lat=${position.latitude}, lng=${position.longitude}');

        if (!mounted) {
          if (loadingDialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          return;
        }

        debugPrint('📡 Sending check-in request to API...');
        final orderProvider = context.read<OrderProvider>();
        final success = await orderProvider.checkInLocation(
          token,
          orderId,
          position.latitude,
          position.longitude,
        );

        if (!mounted) {
          if (loadingDialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          return;
        }
        
        // Close loading dialog
        if (loadingDialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingDialogShown = false;
        }

        if (success) {
          debugPrint('✅ Check-in successful');
          
          // Update last check-in time
          setState(() {
            _lastCheckInTime = DateTime.now();
          });
          
          if (!mounted) return;
          
          // Show success dialog with clear feedback
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              title: const Text('Check-in thành công!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vị trí của bạn đã được cập nhật.'),
                  const SizedBox(height: 8),
                  Text(
                    'Khách hàng có thể theo dõi vị trí của bạn trên bản đồ.',
                    style: AppTextStyles.caption,
                  ),
                  if (_lastCheckInTime != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Thời gian: ${_timeFormat.format(_lastCheckInTime!)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        } else {
          final errorMessage = orderProvider.error ?? 'Không thể check-in vị trí';
          debugPrint('❌ Check-in failed: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (locationError) {
        if (!mounted) {
          if (loadingDialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          return;
        }
        
        // Close loading dialog
        if (loadingDialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingDialogShown = false;
        }
        
        debugPrint('❌ Error getting location: $locationError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: ${locationError.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        if (loadingDialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }
      
      // Close loading dialog if it was shown
      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogShown = false;
      }
      
      debugPrint('❌ Error in _checkInLocation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always reset the flag, even if there was an error
      // Also ensure loading dialog is closed
      if (mounted) {
        if (loadingDialogShown) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (_) {
            // Dialog might already be closed, ignore
          }
        }
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Widget _buildMap(ShipperOrder order) {
    if (kIsWeb) {
      return _buildPlaceholder('Bản đồ chưa hỗ trợ trên trình duyệt');
    }
    if (order.pickupLat == null ||
        order.pickupLng == null ||
        order.deliveryLat == null ||
        order.deliveryLng == null) {
      return _buildPlaceholder('Chưa có tọa độ để hiển thị bản đồ');
    }

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(order.pickupLat!, order.pickupLng!),
        infoWindow: const InfoWindow(title: 'Điểm lấy hàng'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(order.deliveryLat!, order.deliveryLng!),
        infoWindow: const InfoWindow(title: 'Điểm giao hàng'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };

    final bounds = LatLngBounds(
      southwest: LatLng(
        order.pickupLat! < order.deliveryLat! ? order.pickupLat! : order.deliveryLat!,
        order.pickupLng! < order.deliveryLng! ? order.pickupLng! : order.deliveryLng!,
      ),
      northeast: LatLng(
        order.pickupLat! > order.deliveryLat! ? order.pickupLat! : order.deliveryLat!,
        order.pickupLng! > order.deliveryLng! ? order.pickupLng! : order.deliveryLng!,
      ),
    );

    final initialCamera = CameraPosition(
      target: LatLng(order.pickupLat!, order.pickupLng!),
      zoom: 13,
    );

    return SizedBox(
      height: 260,
      child: GoogleMap(
        initialCameraPosition: initialCamera,
        markers: markers,
        onMapCreated: (controller) async {
          if (!_mapController.isCompleted) {
            _mapController.complete(controller);
          }
          await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: AppColors.greyLight.withValues(alpha: 0.4),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final order = orderProvider.currentOrder;

    return Scaffold(
      appBar: AppBar(
        title: Text(order?.orderNumber ?? 'Chi tiết đơn hàng'),
        actions: [
          if (auth.token != null && order != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadOrder(order.id),
            ),
        ],
      ),
      body: orderProvider.isLoading && order == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : order == null
              ? const Center(child: Text('Không tìm thấy đơn hàng'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.orderNumber,
                                      style: AppTextStyles.heading1,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: OrderStatus.color(order.status).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppRadius.round),
                                    ),
                                    child: Text(
                                      OrderStatus.label(order.status),
                                      style: TextStyle(
                                        color: OrderStatus.color(order.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Tạo lúc: ${order.createdAt != null ? _dateFormat.format(order.createdAt!) : '--'}',
                                style: AppTextStyles.body,
                              ),
                              if (order.notes != null && order.notes!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Ghi chú: ${order.notes}',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildMap(order),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thông tin giao hàng', style: AppTextStyles.heading2),
                              const SizedBox(height: AppSpacing.md),
                              _DetailRow(
                                icon: Icons.storefront_outlined,
                                title: AppTexts.pickupAddress,
                                value: order.pickupAddress ?? 'Chưa có',
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _DetailRow(
                                icon: Icons.location_on_outlined,
                                title: AppTexts.deliveryAddress,
                                value: order.deliveryAddress ?? 'Chưa có',
                              ),
                              if (order.recipientName != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _DetailRow(
                                  icon: Icons.person_outline,
                                  title: AppTexts.recipient,
                                  value:
                                      '${order.recipientName}${order.recipientPhone != null ? ' (${order.recipientPhone})' : ''}',
                                ),
                              ],
                              if (order.customerName != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _DetailRow(
                                  icon: Icons.account_circle_outlined,
                                  title: AppTexts.customer,
                                  value:
                                      '${order.customerName}${order.customerPhone != null ? ' (${order.customerPhone})' : ''}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (order.history.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lịch sử trạng thái', style: AppTextStyles.heading2),
                                const SizedBox(height: AppSpacing.md),
                                ...order.history.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                OrderStatus.label(item.status),
                                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                              ),
                                              if (item.notes != null && item.notes!.isNotEmpty)
                                                Text(item.notes!, style: AppTextStyles.body),
                                              if (item.createdAt != null)
                                                Text(
                                                  _dateFormat.format(item.createdAt!),
                                                  style: AppTextStyles.caption,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      if (auth.token != null) ...[
                        // US-17: Check-in button - Hiển thị cho đơn đã được gán cho shipper
                        // (trừ các trạng thái đã giao, đã hủy, hoặc giao thất bại)
                        // Bao gồm: assigned, processing, shipped, in_transit và các status liên quan
                        if (_shouldShowCheckIn(order.status))
                          Column(
                            children: [
                              Card(
                                color: AppColors.primary.withValues(alpha: 0.05),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.my_location, color: AppColors.primary),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Check-in vị trí',
                                                  style: AppTextStyles.heading2.copyWith(fontSize: 16),
                                                ),
                                                const SizedBox(height: AppSpacing.xs),
                                                Text(
                                                  'Cập nhật vị trí của bạn để khách hàng theo dõi',
                                                  style: AppTextStyles.caption,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_lastCheckInTime != null) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        Container(
                                          padding: const EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                            border: Border.all(
                                              color: AppColors.success.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: AppColors.success,
                                                size: 20,
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Đã check-in thành công',
                                                      style: AppTextStyles.body.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.success,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Lần cuối: ${_timeFormat.format(_lastCheckInTime!)} - ${_dateFormat.format(_lastCheckInTime!)}',
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: AppColors.success,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.md),
                                      AbsorbPointer(
                                        absorbing: _isCheckingIn,
                                        child: Opacity(
                                          opacity: _isCheckingIn ? 0.6 : 1.0,
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: _isCheckingIn
                                                  ? null
                                                  : () {
                                                      debugPrint('🔄 Check-in button clicked for order: ${order.id}');
                                                      _checkInLocation(order.id);
                                                    },
                                              icon: _isCheckingIn
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AppColors.white,
                                                      ),
                                                    )
                                                  : const Icon(Icons.my_location),
                                              label: Text(
                                                _isCheckingIn
                                                    ? 'Đang check-in...'
                                                    : (_lastCheckInTime != null 
                                                        ? 'Check-in lại' 
                                                        : 'Check-in ngay')
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: AppColors.white,
                                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        _ActionButtons(
                          order: order,
                          onStartDelivery: () => _updateStatus(order.id, 'DELIVERING'),
                          onDelivered: () => _updateStatus(order.id, 'DELIVERED_SUCCESS'),
                          onFailed: () => _showFailureDialog(order.id),
                          loading: _isUpdatingStatus,
                          normalizeStatus: _normalizeStatus,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  // US-18: Show failure dialog with reason
  Future<void> _showFailureDialog(int orderId) async {
    final reasonController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lý do giao thất bại'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vui lòng nhập lý do giao thất bại:',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Khách hàng không có ở nhà, Địa chỉ sai, Khách hàng từ chối nhận hàng...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do giao thất bại')),
                );
                return;
              }
              Navigator.pop(context, {'reason': reason});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result != null && result['reason'] != null) {
      await _updateStatus(orderId, 'DELIVERY_FAILED', reason: result['reason']);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ShipperOrder order;
  final VoidCallback onStartDelivery;
  final VoidCallback onDelivered;
  final VoidCallback onFailed;
  final bool loading;
  final String Function(String) normalizeStatus;

  const _ActionButtons({
    required this.order,
    required this.onStartDelivery,
    required this.onDelivered,
    required this.onFailed,
    required this.loading,
    required this.normalizeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = normalizeStatus(order.status);
    final canStart = normalizedStatus == OrderStatus.assigned || normalizedStatus == OrderStatus.pending;
    final canFinish = normalizedStatus == OrderStatus.inTransit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canStart)
          AbsorbPointer(
            absorbing: loading,
            child: Opacity(
              opacity: loading ? 0.6 : 1.0,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onStartDelivery,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(loading ? 'Đang xử lý...' : AppTexts.startDelivery),
              ),
            ),
          ),
        if (canFinish) ...[
          AbsorbPointer(
            absorbing: loading,
            child: Opacity(
              opacity: loading ? 0.6 : 1.0,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onDelivered,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(loading ? 'Đang xử lý...' : AppTexts.deliveredSuccess),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AbsorbPointer(
            absorbing: loading,
            child: Opacity(
              opacity: loading ? 0.6 : 1.0,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onFailed,
                icon: const Icon(Icons.error_outline),
                label: const Text(AppTexts.deliveredFailed),
              ),
            ),
          ),
        ],
        if (!canStart && !canFinish)
          Text(
            'Không có hành động khả dụng cho trạng thái hiện tại.',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}


