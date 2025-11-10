class NotificationModel {
  final int id;
  final int? orderId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? trackingNumber;

  NotificationModel({
    required this.id,
    this.orderId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.trackingNumber,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      orderId: json['order_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      trackingNumber: json['tracking_number'],
    );
  }
}

