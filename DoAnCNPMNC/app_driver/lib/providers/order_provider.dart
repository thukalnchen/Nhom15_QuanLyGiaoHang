import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableOrders = [];
  List<Map<String, dynamic>> _activeOrders = [];
  Map<String, dynamic>? _currentOrder;
  String? _error;
  
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get availableOrders => _availableOrders;
  List<Map<String, dynamic>> get activeOrders => _activeOrders;
  Map<String, dynamic>? get currentOrder => _currentOrder;
  String? get error => _error;
  
  Future<bool> getAvailableOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.availableOrdersEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _availableOrders = List<Map<String, dynamic>>.from(data['data']['orders']);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Lấy danh sách đơn hàng thất bại';
        }
      } else {
        _error = 'Lỗi tải đơn hàng';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> getActiveOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.activeOrdersEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _activeOrders = List<Map<String, dynamic>>.from(data['data']['orders']);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Lấy đơn đang giao thất bại';
        }
      } else {
        _error = 'Lỗi tải đơn hàng';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> acceptOrder(int orderId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.ordersEndpoint}/$orderId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Remove from available orders
          _availableOrders.removeWhere((order) => order['id'] == orderId);
          // Refresh active orders
          await getActiveOrders(token);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Nhận đơn thất bại';
        }
      } else {
        _error = 'Nhận đơn thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> updateOrderStatus(int orderId, String status, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.ordersEndpoint}/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Update local order status
          final orderIndex = _activeOrders.indexWhere((o) => o['id'] == orderId);
          if (orderIndex != -1) {
            _activeOrders[orderIndex]['status'] = status;
          }
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Cập nhật trạng thái thất bại';
        }
      } else {
        _error = 'Cập nhật trạng thái thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
