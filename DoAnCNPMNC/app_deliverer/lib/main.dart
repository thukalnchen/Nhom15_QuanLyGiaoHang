import 'package:flutter/material.dart';
import 'models/order.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Deliverer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Danh sách đơn được giao'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Order> orders;

  @override
  void initState() {
    super.initState();
    orders = List<Order>.from(mockOrders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.separated(
        itemCount: orders.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            leading: _statusIcon(order.status),
            title: Text(order.recipientName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã đơn: '),
                Text('Địa chỉ: '),
                Text('Trạng thái: '),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<OrderStatus>(
              icon: const Icon(Icons.more_vert),
              onSelected: (OrderStatus newStatus) {
                setState(() {
                  orders[index].status = newStatus;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: OrderStatus.delivering,
                  child: Text(_statusText(OrderStatus.delivering)),
                ),
                PopupMenuItem(
                  value: OrderStatus.delivered,
                  child: Text(_statusText(OrderStatus.delivered)),
                ),
                PopupMenuItem(
                  value: OrderStatus.failed,
                  child: Text(_statusText(OrderStatus.failed)),
                ),
                PopupMenuItem(
                  value: OrderStatus.returned,
                  child: Text(_statusText(OrderStatus.returned)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Giao thành công';
      case OrderStatus.failed:
        return 'Thất bại';
      case OrderStatus.returned:
        return 'Trả hàng';
    }
  }

  Widget _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivering:
        return const Icon(Icons.local_shipping, color: Colors.orange);
      case OrderStatus.delivered:
        return const Icon(Icons.check_circle, color: Colors.green);
      case OrderStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case OrderStatus.returned:
        return const Icon(Icons.undo, color: Colors.blueGrey);
    }
  }
}
