import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<ShipperOrder> _orders = [];
  ShipperOrder? _currentOrder;

  bool get isLoading => _loading;
  String? get error => _error;
  List<ShipperOrder> get orders => _orders;
  ShipperOrder? get currentOrder => _currentOrder;

  Future<bool> fetchOrders(String token, {String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final query = status != null ? '?status=$status' : '';
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.shipperOrders}$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Check if response is valid JSON
      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          _error = errorData['message']?.toString() ?? 'Không thể tải danh sách đơn hàng';
        } catch (_) {
          // Response is not JSON, use the raw body or a default message
          _error = response.body.isNotEmpty && response.body.length < 200
              ? response.body
              : 'Không thể tải danh sách đơn hàng';
        }
        _loading = false;
        notifyListeners();
        return false;
      }

      // Try to parse JSON response
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('fetchOrders: Invalid JSON response: ${response.body.substring(0, 200)}');
        _error = response.body.isNotEmpty && response.body.length < 200
            ? response.body
            : 'Phản hồi không hợp lệ từ máy chủ';
        _loading = false;
        notifyListeners();
        return false;
      }

      if (data['status'] == 'success') {
        final orderList = data['data']['orders'] as List<dynamic>;
        _orders = orderList
            .map<ShipperOrder>((item) => ShipperOrder.fromJson(item as Map<String, dynamic>))
            .toList();
        _loading = false;
        notifyListeners();
        return true;
      }

      _error = data['message']?.toString() ?? 'Không thể tải danh sách đơn hàng';
    } catch (error) {
      _error = 'Không thể kết nối tới máy chủ';
      debugPrint('fetchOrders error: $error');
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<ShipperOrder?> fetchOrderDetails(String token, int orderId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.shipperOrderDetails}/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Check if response is valid JSON
      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          _error = errorData['message']?.toString() ?? 'Không thể tải chi tiết đơn hàng';
        } catch (_) {
          // Response is not JSON, use the raw body or a default message
          _error = response.body.isNotEmpty && response.body.length < 200
              ? response.body
              : 'Không thể tải chi tiết đơn hàng';
        }
        _loading = false;
        notifyListeners();
        return null;
      }

      // Try to parse JSON response
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('fetchOrderDetails: Invalid JSON response: ${response.body.substring(0, 200)}');
        _error = response.body.isNotEmpty && response.body.length < 200
            ? response.body
            : 'Phản hồi không hợp lệ từ máy chủ';
        _loading = false;
        notifyListeners();
        return null;
      }

      if (data['status'] == 'success') {
        final order = ShipperOrder.fromJson(data['data']['order'] as Map<String, dynamic>);
        _currentOrder = order;
        final index = _orders.indexWhere((item) => item.id == order.id);
        if (index != -1) {
          _orders[index] = order;
        }
        _loading = false;
        notifyListeners();
        return order;
      }
      _error = data['message']?.toString() ?? 'Không thể tải chi tiết đơn hàng';
    } catch (error) {
      _error = 'Không thể kết nối tới máy chủ';
      debugPrint('fetchOrderDetails error: $error');
    }
    _loading = false;
    notifyListeners();
    return null;
  }

  Future<bool> updateOrderStatus(
    String token,
    int orderId,
    String status, {
    String? notes,
    String? reason, // US-18: Reason for failed delivery
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.shipperOrderDetails}/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['status'] == 'success') {
        final updatedStatus = data['data']['order']['status']?.toString() ?? status;
        final index = _orders.indexWhere((item) => item.id == orderId);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(status: updatedStatus);
        }
        if (_currentOrder != null && _currentOrder!.id == orderId) {
          _currentOrder = _currentOrder!.copyWith(status: updatedStatus);
        }
        _loading = false;
        notifyListeners();
        return true;
      }

      _error = data['message']?.toString() ?? 'Không thể cập nhật trạng thái';
    } catch (error) {
      _error = 'Không thể kết nối tới máy chủ';
      debugPrint('updateOrderStatus error: $error');
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  // US-17: Check-in location
  Future<bool> checkInLocation(String token, int orderId, double lat, double lng) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📡 checkInLocation: Sending request to API...');
      debugPrint('   URL: ${AppConfig.apiBaseUrl}${ApiEndpoints.shipperCheckIn}');
      debugPrint('   orderId: $orderId, lat: $lat, lng: $lng');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.shipperCheckIn}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'order_id': orderId,
          'lat': lat,
          'long': lng,
        }),
      );

      debugPrint('📥 checkInLocation: Response status: ${response.statusCode}');
      debugPrint('   Response body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          _error = errorData['message']?.toString() ?? 'Không thể check-in vị trí';
        } catch (_) {
          _error = response.body.isNotEmpty && response.body.length < 200
              ? response.body
              : 'Không thể check-in vị trí (HTTP ${response.statusCode})';
        }
        _loading = false;
        notifyListeners();
        return false;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] == 'success') {
        debugPrint('✅ checkInLocation: Success!');
        _loading = false;
        notifyListeners();
        return true;
      }

      _error = data['message']?.toString() ?? 'Không thể check-in vị trí';
    } catch (error) {
      _error = 'Không thể kết nối tới máy chủ: ${error.toString()}';
      debugPrint('❌ checkInLocation error: $error');
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetCurrent() {
    _currentOrder = null;
    notifyListeners();
  }
}


