class OrderItem {
  final int id;
  final String itemName;
  final int quantity;
  final double? weight;
  final double? price;

  OrderItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    this.weight,
    this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      weight: json['weight'] != null ? double.parse(json['weight'].toString()) : null,
      price: json['price'] != null ? double.parse(json['price'].toString()) : null,
    );
  }
}

class OrderStatusHistory {
  final int id;
  final String status;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;

  OrderStatusHistory({
    required this.id,
    required this.status,
    this.description,
    this.createdBy,
    required this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'],
      status: json['status'],
      description: json['description'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang vận chuyển';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      case 'cod_pending':
        return 'Chờ thu COD';
      default:
        return status;
    }
  }
}

class OrderPaymentTransaction {
  final int id;
  final String reference;
  final String provider;
  final double amount;
  final String currency;
  final String status;
  final String? paymentUrl;
  final String? signature;
  final DateTime? expiresAt;
  final double? paidAmount;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderPaymentTransaction({
    required this.id,
    required this.reference,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentUrl,
    this.signature,
    this.expiresAt,
    this.paidAmount,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderPaymentTransaction.fromJson(Map<String, dynamic> json) {
    return OrderPaymentTransaction(
      id: json['id'],
      reference: json['reference'],
      provider: json['provider'],
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      currency: json['currency'] ?? 'VND',
      status: json['status'],
      paymentUrl: json['payment_url'],
      signature: json['signature'],
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      paidAmount: json['paid_amount'] != null
          ? double.tryParse(json['paid_amount'].toString())
          : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return 'Đã thanh toán';
      case 'failed':
        return 'Thanh toán thất bại';
      case 'cancelled':
        return 'Thanh toán bị hủy';
      case 'expired':
        return 'Giao dịch hết hạn';
      case 'pending':
        return 'Chờ thanh toán';
      default:
        return status;
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class Order {
  final int id;
  final String trackingNumber;
  final String senderName;
  final String senderPhone;
  final String senderAddress;
  final String? senderCity;
  final String? senderDistrict;
  final String? senderWard;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String? receiverCity;
  final String? receiverDistrict;
  final String? receiverWard;
  final String packageType;
  final String serviceType;
  final String pickupType;
  final String? pickupNotes;
  final double? parcelWeight;
  final double? parcelLength;
  final double? parcelWidth;
  final double? parcelHeight;
  final double? declaredValue;
  final double codAmount;
  final double insuranceFee;
  final double shippingFee;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentReference;
  final DateTime? estimatedPickup;
  final DateTime? estimatedDelivery;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;
  final OrderPaymentTransaction? paymentTransaction;

  Order({
    required this.id,
    required this.trackingNumber,
    required this.senderName,
    required this.senderPhone,
    required this.senderAddress,
    this.senderCity,
    this.senderDistrict,
    this.senderWard,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    this.receiverCity,
    this.receiverDistrict,
    this.receiverWard,
    required this.packageType,
    required this.serviceType,
    required this.pickupType,
    this.pickupNotes,
    this.parcelWeight,
    this.parcelLength,
    this.parcelWidth,
    this.parcelHeight,
    this.declaredValue,
    required this.codAmount,
    required this.insuranceFee,
    required this.shippingFee,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentReference,
    this.estimatedPickup,
    this.estimatedDelivery,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.statusHistory,
    this.paymentTransaction,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      trackingNumber: json['tracking_number'],
      senderName: json['sender_name'],
      senderPhone: json['sender_phone'],
      senderAddress: json['sender_address'],
      senderCity: json['sender_city'],
      senderDistrict: json['sender_district'],
      senderWard: json['sender_ward'],
      receiverName: json['receiver_name'],
      receiverPhone: json['receiver_phone'],
      receiverAddress: json['receiver_address'],
      receiverCity: json['receiver_city'],
      receiverDistrict: json['receiver_district'],
      receiverWard: json['receiver_ward'],
      packageType: json['package_type'] ?? 'tài liệu',
      serviceType: json['service_type'] ?? 'standard',
      pickupType: json['pickup_type'] ?? 'door_to_door',
      pickupNotes: json['pickup_notes'],
      parcelWeight: json['parcel_weight'] != null
          ? double.tryParse(json['parcel_weight'].toString())
          : null,
      parcelLength: json['parcel_length'] != null
          ? double.tryParse(json['parcel_length'].toString())
          : null,
      parcelWidth: json['parcel_width'] != null
          ? double.tryParse(json['parcel_width'].toString())
          : null,
      parcelHeight: json['parcel_height'] != null
          ? double.tryParse(json['parcel_height'].toString())
          : null,
      declaredValue: json['declared_value'] != null
          ? double.tryParse(json['declared_value'].toString())
          : null,
      codAmount: double.tryParse((json['cod_amount'] ?? 0).toString()) ?? 0,
      insuranceFee: double.tryParse((json['insurance_fee'] ?? 0).toString()) ?? 0,
      shippingFee: double.tryParse((json['shipping_fee'] ?? 0).toString()) ?? 0,
      status: json['status'],
      paymentMethod: (json['payment_method'] ?? 'cod').toString(),
      paymentStatus: (json['payment_status'] ?? 'pending').toString(),
      paymentReference: json['payment_reference'],
      estimatedPickup: json['estimated_pickup'] != null
          ? DateTime.tryParse(json['estimated_pickup'])
          : null,
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.tryParse(json['estimated_delivery'])
          : null,
      totalAmount: double.parse(json['total_amount'].toString()),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((item) => OrderStatusHistory.fromJson(item))
              .toList() ??
          [],
      paymentTransaction: json['payment_transaction'] != null
          ? OrderPaymentTransaction.fromJson(
              json['payment_transaction'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang vận chuyển';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      case 'cod_pending':
        return 'Chờ thu COD';
      default:
        return status;
    }
  }

  String getPaymentMethodText() {
    switch (paymentMethod.toLowerCase()) {
      case 'online':
        return 'Online (VNPay/MoMo mô phỏng)';
      case 'cod':
      default:
        return 'Thu hộ (COD)';
    }
  }

  String getPaymentStatusText() {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
        return 'Đang chờ thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      case 'failed':
        return 'Thanh toán thất bại';
      case 'cancelled':
        return 'Thanh toán bị hủy';
      case 'cod_pending':
        return 'Chờ thu COD';
      default:
        return paymentStatus;
    }
  }
}

class PaymentInitResult {
  final String paymentUrl;
  final String reference;
  final double amount;
  final String currency;
  final String? status;
  final String? provider;
  final DateTime? expiresAt;
  final String? signature;

  PaymentInitResult({
    required this.paymentUrl,
    required this.reference,
    required this.amount,
    required this.currency,
    this.status,
    this.provider,
    this.expiresAt,
    this.signature,
  });

  factory PaymentInitResult.fromJson(Map<String, dynamic> json) {
    return PaymentInitResult(
      paymentUrl: json['payment_url'] as String,
      reference: json['reference'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      currency: (json['currency'] ?? 'VND') as String,
      status: json['status'] as String?,
      provider: json['provider'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      signature: json['signature'] as String?,
    );
  }
}

