import '../models/notification.dart' as NotificationModel;
import '../config/api_config.dart';
import 'api_service.dart';

class NotificationService {
  static Future<List<NotificationModel.NotificationModel>> getMyNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.notifications}?limit=$limit&offset=$offset'
      );
      if (response['notifications'] != null) {
        return (response['notifications'] as List<dynamic>)
            .map((json) => NotificationModel.NotificationModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.patch(
        '${ApiConfig.notifications}/$notificationId/read',
        null,
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}

