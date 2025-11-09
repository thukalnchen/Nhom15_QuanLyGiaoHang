class Complaint {
  final int id;
  final int orderId;
  final int customerId;
  final String title;
  final String description;
  final String status; // pending, processing, resolved, rejected
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int responseCount;
  
  // Optional fields for detail view
  final String? customerName;
  final OrderInfo? order;
  final List<ComplaintResponse>? responses;

  Complaint({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.title,
    required this.description,
    required this.status,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.responseCount = 0,
    this.customerName,
    this.order,
    this.responses,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      orderId: json['order_id'],
      customerId: json['customer_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls'])
          : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      responseCount: json['response_count'] ?? 0,
      customerName: json['customer_name'],
      order: json['order'] != null ? OrderInfo.fromJson(json['order']) : null,
      responses: json['responses'] != null
          ? (json['responses'] as List)
              .map((r) => ComplaintResponse.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'title': title,
      'description': description,
      'status': status,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'response_count': responseCount,
      'customer_name': customerName,
      'order': order?.toJson(),
      'responses': responses?.map((r) => r.toJson()).toList(),
    };
  }

  String getStatusText() {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã giải quyết';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }

  String getStatusEmoji() {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'processing':
        return '🔄';
      case 'resolved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '❓';
    }
  }
}

class OrderInfo {
  final int id;
  final String orderCode;
  final String pickupAddress;
  final String deliveryAddress;
  final double totalCost;

  OrderInfo({
    required this.id,
    required this.orderCode,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.totalCost,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: json['id'],
      orderCode: json['order_code'],
      pickupAddress: json['pickup_address'],
      deliveryAddress: json['delivery_address'],
      totalCost: (json['total_cost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'total_cost': totalCost,
    };
  }
}

class ComplaintResponse {
  final int id;
  final int complaintId;
  final String message;
  final bool isAdmin;
  final int responderId;
  final String responderName;
  final DateTime createdAt;

  ComplaintResponse({
    required this.id,
    required this.complaintId,
    required this.message,
    required this.isAdmin,
    required this.responderId,
    required this.responderName,
    required this.createdAt,
  });

  factory ComplaintResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintResponse(
      id: json['id'],
      complaintId: json['complaint_id'],
      message: json['message'],
      isAdmin: json['is_admin'],
      responderId: json['responder_id'],
      responderName: json['responder_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'message': message,
      'is_admin': isAdmin,
      'responder_id': responderId,
      'responder_name': responderName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
