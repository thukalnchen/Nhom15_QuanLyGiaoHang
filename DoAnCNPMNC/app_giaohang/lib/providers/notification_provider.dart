import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/constants.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  IO.Socket? _socket;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  // Initialize notifications with Socket.IO
  Future<void> initializeNotifications() async {
    try {
      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Request notification permissions
      await _requestPermissions();

      // Connect to Socket.IO
      await _connectSocket();

      // Fetch notifications from server
      await fetchNotifications();
      await fetchUnreadCount();
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

  Future<void> _requestPermissions() async {
    // Request permissions for local notifications
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted == true) {
        print('✅ Notification permissions granted');
      }
    }

    final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == true) {
        print('✅ Notification permissions granted');
      }
    }
  }

  Future<void> _connectSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.token);
      final userJson = prefs.getString(StorageKeys.user);

      if (token == null || userJson == null) {
        print('No auth token or user data found, skipping Socket.IO connection');
        return;
      }

      final userData = json.decode(userJson);
      final userId = userData['id'];

      if (userId == null) {
        print('User ID not found, skipping Socket.IO connection');
        return;
      }

      // Disconnect existing socket if any
      _disconnectSocket();

      // Connect to Socket.IO server
      _socket = IO.io(
        AppConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ Socket.IO connected for notifications');
        
        // Register user with backend (send as integer to match backend expectations)
        final userIdInt = userId is int ? userId : (userId is String ? int.tryParse(userId) : null);
        if (userIdInt != null) {
          _socket!.emit('register-user', userIdInt);
          print('📝 Registered user $userIdInt with Socket.IO server');
        } else {
          print('⚠️ Invalid user ID format: $userId');
        }
      });

      _socket!.onDisconnect((_) {
        print('⚠️ Socket.IO disconnected');
      });

      _socket!.onError((error) {
        print('❌ Socket.IO error: $error');
      });

      // Listen for notifications
      _socket!.on('notification', (data) {
        print('📬 Received notification via Socket.IO');
        print('📬 Notification data: $data');
        
        try {
          // Ensure data is a Map
          Map<String, dynamic> notificationData;
          if (data is Map) {
            notificationData = Map<String, dynamic>.from(data);
          } else if (data is String) {
            notificationData = json.decode(data) as Map<String, dynamic>;
          } else {
            print('⚠️ Invalid notification data format: ${data.runtimeType}');
            return;
          }
          
          _handleIncomingNotification(notificationData);
        } catch (e) {
          print('❌ Error parsing notification data: $e');
          print('❌ Raw data: $data');
        }
      });

      // Handle ping/pong to keep connection alive
      _socket!.on('ping', (_) {
        _socket!.emit('pong', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      });

    } catch (e) {
      print('Error connecting Socket.IO: $e');
    }
  }

  void _disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  void _handleIncomingNotification(Map<String, dynamic> data) {
    try {
      print('📱 Handling incoming notification...');
      print('📱 Title: ${data['title']}');
      print('📱 Body: ${data['body']}');
      
      // Show local notification
      final title = data['title']?.toString() ?? 'Thông báo';
      final body = data['body']?.toString() ?? '';
      final notificationData = data['data'] is Map 
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};
      
      _showLocalNotification(title, body, notificationData);

      // Refresh notifications list
      Future.delayed(const Duration(milliseconds: 500), () {
        fetchNotifications();
        fetchUnreadCount();
      });
    } catch (e) {
      print('❌ Error handling incoming notification: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'shipper_channel',
      'Shipper Notifications',
      channelDescription: 'Notifications for Shipper orders and updates',
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
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: json.encode(data),
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
  Future<void> fetchNotifications({bool? isRead, String? type}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.token);

      if (token == null) {
        print('No auth token found');
        _isLoading = false;
        notifyListeners();
        return;
      }

      String url = '${AppConfig.apiBaseUrl}/notifications?limit=50';
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
      final token = prefs.getString(StorageKeys.token);

      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/unread-count'),
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
      final token = prefs.getString(StorageKeys.token);

      if (token == null) return;

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/$notificationId/read'),
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
      final token = prefs.getString(StorageKeys.token);

      if (token == null) return;

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/read-all'),
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
      final token = prefs.getString(StorageKeys.token);

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/$notificationId'),
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

  // Reconnect Socket.IO (call this after login)
  Future<void> reconnect() async {
    await _connectSocket();
  }

  // Disconnect Socket.IO (call this on logout)
  void disconnect() {
    _disconnectSocket();
  }

  @override
  void dispose() {
    _disconnectSocket();
    super.dispose();
  }
}
