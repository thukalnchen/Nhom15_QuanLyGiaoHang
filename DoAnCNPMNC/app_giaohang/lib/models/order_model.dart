import 'dart:convert';

class ShipperOrder {
  final int id;
  final String orderNumber;
  final String status;
  final String? pickupAddress;
  final String? deliveryAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? recipientName;
  final String? recipientPhone;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final double? totalAmount;
  final double? deliveryFee;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<OrderStatusHistory> history;

  ShipperOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.pickupAddress,
    this.deliveryAddress,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.recipientName,
    this.recipientPhone,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.totalAmount,
    this.deliveryFee,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.history = const [],
  });

  factory ShipperOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final historyList = json['status_history'];
    return ShipperOrder(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      pickupAddress: json['pickup_address']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      pickupLat: _toDouble(json['pickup_lat']),
      pickupLng: _toDouble(json['pickup_lng']),
      deliveryLat: _toDouble(json['delivery_lat']),
      deliveryLng: _toDouble(json['delivery_lng']),
      recipientName: json['recipient_name']?.toString(),
      recipientPhone: json['recipient_phone']?.toString() ?? json['delivery_phone']?.toString(),
      customerName: customer?['full_name']?.toString(),
      customerPhone: customer?['phone']?.toString(),
      customerEmail: customer?['email']?.toString(),
      totalAmount: _toDouble(json['total_amount']),
      deliveryFee: _toDouble(json['delivery_fee']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      history: historyList is List
          ? historyList.map<OrderStatusHistory>((item) => OrderStatusHistory.fromJson(item)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'customer': {
        'full_name': customerName,
        'phone': customerPhone,
        'email': customerEmail,
      },
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'status_history': history.map((item) => item.toJson()).toList(),
    };
  }

  ShipperOrder copyWith({
    String? status,
    List<OrderStatusHistory>? history,
  }) {
    return ShipperOrder(
      id: id,
      orderNumber: orderNumber,
      status: status ?? this.status,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      totalAmount: totalAmount,
      deliveryFee: deliveryFee,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      history: history ?? this.history,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<ShipperOrder> listFromResponse(dynamic data) {
    if (data is List) {
      return data.map<ShipperOrder>((item) => ShipperOrder.fromJson(item as Map<String, dynamic>)).toList();
    }
    if (data is String) {
      final List<dynamic> decoded = json.decode(data) as List<dynamic>;
      return decoded
          .map<ShipperOrder>((item) => ShipperOrder.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }
}

class OrderStatusHistory {
  final String status;
  final String? notes;
  final DateTime? createdAt;

  const OrderStatusHistory({
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}


