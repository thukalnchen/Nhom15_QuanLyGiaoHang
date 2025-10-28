enum OrderStatus {
  delivering,
  delivered,
  failed,
  returned,
}

class Order {
  final String id;
  final String recipientName;
  final String address;
  OrderStatus status;

  Order({
    required this.id,
    required this.recipientName,
    required this.address,
    required this.status,
  });
}

List<Order> mockOrders = [
  Order(
    id: 'DH001',
    recipientName: 'Nguyen Van A',
    address: '123 Le Loi, Q1, TP.HCM',
    status: OrderStatus.delivering,
  ),
  Order(
    id: 'DH002',
    recipientName: 'Tran Thi B',
    address: '456 Tran Hung Dao, Q5, TP.HCM',
    status: OrderStatus.delivered,
  ),
  Order(
    id: 'DH003',
    recipientName: 'Le Van C',
    address: '789 Cach Mang Thang 8, Q10, TP.HCM',
    status: OrderStatus.failed,
  ),
  Order(
    id: 'DH004',
    recipientName: 'Pham Thi D',
    address: '321 Nguyen Trai, Q1, TP.HCM',
    status: OrderStatus.returned,
  ),
];
