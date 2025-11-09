import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/constants.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  // Initialize Firebase Cloud Messaging
  Future<void> initializeNotifications() async {
    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        
        // Get FCM token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('FCM Token: $token');
          await _saveFCMToken(token);
        }

        // Listen to token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

        // Check for initial message (app opened from terminated state)
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessage(initialMessage);
        }

        // Fetch notifications from server
        await fetchNotifications();
        await fetchUnreadCount();
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = await prefs.getString('token');

      if (savedToken == null) {
        print('No auth token found, skipping FCM token save');
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $savedToken',
        },
        body: json.encode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        print('FCM token saved to server');
      } else {
        print('Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(message);
    
    // Refresh notifications list
    fetchNotifications();
    fetchUnreadCount();
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
    
    // Handle navigation based on notification data
    if (message.data['type'] == 'order' && message.data['reference_id'] != null) {
      // TODO: Navigate to order detail
      print('Navigate to order: ${message.data['reference_id']}');
    }
    
    // Refresh notifications
    fetchNotifications();
    fetchUnreadCount();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'lalamove_channel',
      'Lalamove Notifications',
      channelDescription: 'Notifications for Lalamove orders and updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Lalamove',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  void _onSelectNotification(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      print('Notification tapped with data: $data');
      // TODO: Handle navigation
    }
  }

  // Fetch notifications from server
  Future<void> fetchNotifications({bool isRead, String? type}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('No auth token found');
        _isLoading = false;
        notifyListeners();
        return;
      }

      String url = '${AppConstants.apiBaseUrl}/notifications?limit=50';
      if (isRead != null) {
        url += '&is_read=$isRead';
      }
      if (type != null) {
        url += '&type=$type';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _notifications = (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      } else {
        print('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch unread count
  Future<void> fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _unreadCount = data['data']['unread_count'];
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            userId: _notifications[index].userId,
            title: _notifications[index].title,
            body: _notifications[index].body,
            type: _notifications[index].type,
            referenceId: _notifications[index].referenceId,
            data: _notifications[index].data,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: _notifications[index].createdAt,
            updatedAt: DateTime.now(),
          );
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await fetchNotifications();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        await fetchUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Request permission
  Future<bool> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
