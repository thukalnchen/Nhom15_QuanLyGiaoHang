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
    await context.read<OrderProvider>().fetchOrders(token, status: _selectedStatus);
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

                  if (orderProvider.orders.isEmpty) {
                    return const Center(
                      child: Text(
                        AppTexts.noOrders,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final order = orderProvider.orders[index];
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
                    itemCount: orderProvider.orders.length,
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


