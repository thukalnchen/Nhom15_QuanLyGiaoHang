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

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['status'] == 'success') {
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

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['status'] == 'success') {
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetCurrent() {
    _currentOrder = null;
    notifyListeners();
  }
}


