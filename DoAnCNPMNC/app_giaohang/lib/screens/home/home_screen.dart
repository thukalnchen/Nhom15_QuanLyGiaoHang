import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../orders/order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrders);
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    // Fetch all orders without status filter to allow client-side filtering
    // This ensures consistent filtering regardless of backend status format
    await context.read<OrderProvider>().fetchOrders(token);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName, (route) => false);
  }

  void _changeStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadOrders();
  }

  // Normalize status to ensure consistent comparison
  // This function maps various backend status formats to standard format
  String _normalizeStatus(String status) {
    if (status.isEmpty) return status;
    
    // Map various status formats to standard format
    final statusLower = status.toLowerCase().trim();
    
    // Check in_transit (đang giao) - exact match or specific formats
    if (statusLower == 'in_transit' || statusLower == 'in-transit') {
      return 'in_transit';
    }
    
    // Check shipped (also means in_transit - when admin sets "Đang giao")
    if (statusLower == 'shipped') {
      return 'in_transit';
    }
    
    // Check delivering (also means in_transit)
    if (statusLower == 'delivering') {
      return 'in_transit';
    }
    
    // Check processing (also means in_transit - when admin assigns order)
    if (statusLower == 'processing') {
      return 'in_transit';
    }
    
    // Check assigned_to_driver (also should show in "Đang giao" tab)
    if (statusLower == 'assigned_to_driver' || statusLower == 'assigned-to-driver') {
      return 'assigned_to_driver';
    }
    
    // Check delivered
    if (statusLower == 'delivered') {
      return 'delivered';
    }
    
    // Check failed_delivery
    if (statusLower == 'failed_delivery' || statusLower == 'failed-delivery') {
      return 'failed_delivery';
    }
    
    // Check cancelled (also means failed_delivery - when admin cancels order)
    if (statusLower == 'cancelled' || statusLower == 'canceled') {
      return 'failed_delivery';
    }
    
    // Return original if no match
    return statusLower;
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final statuses = <String?, String>{
      null: 'Tất cả',
      OrderStatus.inTransit: OrderStatus.label(OrderStatus.inTransit),
      OrderStatus.delivered: OrderStatus.label(OrderStatus.delivered),
      OrderStatus.failed: OrderStatus.label(OrderStatus.failed),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.orders),
        actions: [
          IconButton(
            tooltip: AppTexts.logout,
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: statuses.entries.map((entry) {
                    final bool selected = _selectedStatus == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => _changeStatus(entry.key),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.black,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Builder(builder: (context) {
                  if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (orderProvider.error != null && orderProvider.orders.isEmpty) {
                    return Center(
                      child: Text(
                        orderProvider.error!,
                        style: AppTextStyles.body.copyWith(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Filter orders by status on client side to ensure correct filtering
                  final displayedOrders = _selectedStatus == null
                      ? orderProvider.orders
                      : orderProvider.orders.where((order) {
                          // Normalize status from order (backend format)
                          final normalizedOrderStatus = _normalizeStatus(order.status);
                          // Normalize selected status (constant format like 'in_transit', 'cancelled', etc.)
                          final normalizedSelectedStatus = _normalizeStatus(_selectedStatus!);
                          
                          // Special case: "Đang giao" (in_transit) should include both in_transit and assigned_to_driver
                          if (normalizedSelectedStatus == 'in_transit') {
                            return normalizedOrderStatus == 'in_transit' || 
                                   normalizedOrderStatus == 'assigned_to_driver';
                          }
                          
                          // For other statuses (delivered, failed_delivery, cancelled), use exact match
                          // Note: cancelled orders are normalized to 'failed_delivery' so they show in "Giao thất bại" tab
                          return normalizedOrderStatus == normalizedSelectedStatus;
                        }).toList();

                  if (displayedOrders.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedStatus == null
                            ? AppTexts.noOrders
                            : 'Không có đơn hàng với trạng thái "${statuses[_selectedStatus]}"',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return InkWell(
                        onTap: () async {
                          if (auth.token == null) return;
                          await Navigator.pushNamed(
                            context,
                            OrderDetailScreen.routeName,
                            arguments: OrderDetailArguments(orderId: order.id),
                          );
                          if (!mounted) return;
                          await _loadOrders();
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
                                        style: AppTextStyles.heading2,
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
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.storefront, size: 18, color: AppColors.grey),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        order.pickupAddress ?? 'Chưa có địa chỉ lấy hàng',
                                        style: AppTextStyles.body,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.grey),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        order.deliveryAddress ?? 'Chưa có địa chỉ giao hàng',
                                        style: AppTextStyles.body,
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.recipientName != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 18, color: AppColors.grey),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          order.recipientName!,
                                          style: AppTextStyles.body,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemCount: displayedOrders.length,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: orderProvider.isLoading
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: AppColors.primary,
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            )
          : null,
    );
  }
}


