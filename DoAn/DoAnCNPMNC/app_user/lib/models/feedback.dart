class Feedback {
  final int id;
  final int orderId;
  final int userId;
  final String type; // 'complaint' or 'feedback'
  final String title;
  final String content;
  final String status;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'],
      orderId: json['order_id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      content: json['content'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'type': type,
      'title': title,
      'content': content,
    };
  }
}

