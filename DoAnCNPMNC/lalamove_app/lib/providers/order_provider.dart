import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _currentOrder;
  String? _error;
  
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic>? get currentOrder => _currentOrder;
  String? get error => _error;
  
  Future<bool> createOrder({
    required String restaurantName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
    double deliveryFee = 0,
    String? deliveryPhone,
    String? notes,
    String? token,
    String? customerRequestedVehicle,
    String? customerEstimatedSize,
  }) async {
    if (token == null) {
      print('❌ createOrder: Token is null');
      return false;
    }
    
    print('📡 createOrder: Creating order...');
    print('   Token: ${token.substring(0, 20)}...');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.ordersEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'restaurant_name': restaurantName,
          'items': items,
          'total_amount': totalAmount,
          'delivery_fee': deliveryFee,
          'delivery_address': deliveryAddress,
          'delivery_phone': deliveryPhone,
          'notes': notes,
          if (customerRequestedVehicle != null) 'customer_requested_vehicle': customerRequestedVehicle,
          if (customerEstimatedSize != null) 'customer_estimated_size': customerEstimatedSize,
        }),
      );
      
      print('📥 createOrder: Status ${response.statusCode}');
      print('   Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ createOrder: Success!');
        if (data['status'] == 'success') {
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Tạo đơn hàng thất bại';
          print('❌ createOrder: ${_error}');
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Tạo đơn hàng thất bại';
        print('❌ createOrder: HTTP ${response.statusCode} - ${_error}');
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
      print('❌ createOrder: Exception - ${_error}');
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> getOrders({String? token, String? status}) async {
    if (token == null) {
      print('❌ getOrders: Token is null');
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      String url = '${AppConstants.apiBaseUrl}${AppConstants.ordersEndpoint}';
      if (status != null) {
        url += '?status=$status';
      }
      
      print('📡 getOrders: Fetching from $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📥 getOrders: Status ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 getOrders: Response data: ${data['status']}');
        
        if (data['status'] == 'success') {
          _orders = List<Map<String, dynamic>>.from(data['data']['orders']);
          print('✅ getOrders: Loaded ${_orders.length} orders');
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Lấy danh sách đơn hàng thất bại';
          print('❌ getOrders: Error - $_error');
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Lấy danh sách đơn hàng thất bại';
        print('❌ getOrders: HTTP ${response.statusCode} - $_error');
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
      print('❌ getOrders: Exception - $_error');
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> getOrderDetails(int orderId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.ordersEndpoint}/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _currentOrder = data['data']['order'];
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Lấy chi tiết đơn hàng thất bại';
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Lấy chi tiết đơn hàng thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> cancelOrder({
    required int orderId,
    required String reason,
    required String cancelType,
    String? token,
  }) async {
    // Get token from AuthProvider if not provided
    if (token == null) {
      _error = 'Vui lòng đăng nhập lại';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.ordersEndpoint}/$orderId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reason': reason,
          'cancel_type': cancelType,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          // Update local order if it's the current order
          if (_currentOrder != null && _currentOrder!['id'] == orderId) {
            _currentOrder!['status'] = 'cancelled';
          }
          
          // Update order in list
          final orderIndex = _orders.indexWhere((order) => order['id'] == orderId);
          if (orderIndex != -1) {
            _orders[orderIndex]['status'] = 'cancelled';
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Hủy đơn hàng thất bại';
        }
      } else if (response.statusCode == 400) {
        // Validation error or cannot cancel
        _error = data['message'] ?? 'Không thể hủy đơn hàng này';
        
        // If the error says order is being delivered or requires support
        if (data['requires_support'] == true) {
          _error = 'Đơn hàng đã xử lý quá lâu. Vui lòng liên hệ hỗ trợ để hủy.';
        } else if (data['current_status'] != null) {
          _error = 'Không thể hủy đơn hàng ở trạng thái: ${data['current_status']}';
        }
      } else if (response.statusCode == 404) {
        _error = 'Không tìm thấy đơn hàng hoặc bạn không có quyền hủy đơn này';
      } else {
        _error = data['message'] ?? 'Hủy đơn hàng thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> updateOrderStatus(int orderId, String status, String token, {String? notes}) async {
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
        body: json.encode({
          'status': status,
          'notes': notes,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Update local order if it's the current order
          if (_currentOrder != null && _currentOrder!['id'] == orderId) {
            _currentOrder!['status'] = status;
          }
          
          // Update order in list
          final orderIndex = _orders.indexWhere((order) => order['id'] == orderId);
          if (orderIndex != -1) {
            _orders[orderIndex]['status'] = status;
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Cập nhật trạng thái thất bại';
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Cập nhật trạng thái thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }
}
