import '../models/feedback.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class FeedbackService {
  static Future<Feedback> createFeedback({
    required int orderId,
    required String type,
    required String title,
    required String content,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.feedbacks, {
        'order_id': orderId,
        'type': type,
        'title': title,
        'content': content,
      });
      
      if (response['feedback'] != null) {
        return Feedback.fromJson(response['feedback']);
      }
      throw Exception('Failed to create feedback');
    } catch (e) {
      throw Exception('Failed to create feedback: $e');
    }
  }
}

