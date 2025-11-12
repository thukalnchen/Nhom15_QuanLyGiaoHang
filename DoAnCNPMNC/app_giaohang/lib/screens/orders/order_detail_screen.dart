import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  final Completer<GoogleMapController> _mapController = Completer();

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

  Future<void> _updateStatus(int orderId, String status, {String? notes}) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.updateOrderStatus(token, orderId, status, notes: notes);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thành công')),
      );
      await _loadOrder(orderId);
    } else if (orderProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.error!)),
      );
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
                      if (auth.token != null)
                        _ActionButtons(
                          order: order,
                          onStartDelivery: () => _updateStatus(order.id, 'DELIVERING'),
                          onDelivered: () => _updateStatus(order.id, 'DELIVERED_SUCCESS'),
                          onFailed: () => _showFailureDialog(order.id),
                          loading: orderProvider.isLoading,
                        ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _showFailureDialog(int orderId) async {
    final notesController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lý do giao thất bại'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú cho khách hàng',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, notesController.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateStatus(orderId, 'DELIVERY_FAILED', notes: result);
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

  const _ActionButtons({
    required this.order,
    required this.onStartDelivery,
    required this.onDelivered,
    required this.onFailed,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = order.status;
    final canStart = currentStatus == OrderStatus.assigned || currentStatus == OrderStatus.pending;
    final canFinish = currentStatus == OrderStatus.inTransit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canStart)
          ElevatedButton.icon(
            onPressed: loading ? null : onStartDelivery,
            icon: const Icon(Icons.play_arrow),
            label: const Text(AppTexts.startDelivery),
          ),
        if (canFinish) ...[
          ElevatedButton.icon(
            onPressed: loading ? null : onDelivered,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(AppTexts.deliveredSuccess),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: loading ? null : onFailed,
            icon: const Icon(Icons.error_outline),
            label: const Text(AppTexts.deliveredFailed),
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


