import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class WarehouseProvider with ChangeNotifier {
  List<Order> _pendingOrders = []; // Chờ nhận hàng
  List<Order> _receivedOrders = []; // Đã nhận tại kho
  List<Order> _classifiedOrders = []; // Đã phân loại
  List<Order> _readyOrders = []; // Sẵn sàng giao
  
  Order? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get pendingOrders => _pendingOrders;
  List<Order> get receivedOrders => _receivedOrders;
  List<Order> get classifiedOrders => _classifiedOrders;
  List<Order> get readyOrders => _readyOrders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService = ApiService();

  // Load all orders
  Future<void> loadOrders(String token) async {
    print('📡 loadOrders: Fetching warehouse orders...');
    print('   Token: ${token.substring(0, 20)}...');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getWarehouseOrders(token);
      print('📥 loadOrders: Response received');
      print('   Success: ${response['success']}');

      if (response['success']) {
        final List<dynamic> ordersData = response['orders'] ?? [];
        print('📦 loadOrders: Total orders: ${ordersData.length}');
        
        final List<Order> allOrders = ordersData.map((json) => Order.fromJson(json)).toList();

        // Classify orders by status
        _pendingOrders = allOrders.where((o) => o.status == OrderStatus.pending).toList();
        _receivedOrders = allOrders.where((o) => o.status == OrderStatus.receivedAtWarehouse).toList();
        _classifiedOrders = allOrders.where((o) => o.status == OrderStatus.classified).toList();
        _readyOrders = allOrders.where((o) => o.status == OrderStatus.readyForPickup).toList();

        print('✅ loadOrders: Orders classified:');
        print('   Pending: ${_pendingOrders.length}');
        print('   Received: ${_receivedOrders.length}');
        print('   Classified: ${_classifiedOrders.length}');
        print('   Ready: ${_readyOrders.length}');

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = response['message'] ?? 'Không thể tải danh sách đơn hàng';
        print('❌ loadOrders: ${_errorMessage}');
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      print('❌ loadOrders: Exception - ${_errorMessage}');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search order by code (QR scan)
  Future<Order?> searchOrderByCode(String token, String orderCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.searchOrderByCode(token, orderCode);

      _isLoading = false;
      if (response['success']) {
        _currentOrder = Order.fromJson(response['order']);
        notifyListeners();
        return _currentOrder;
      } else {
        _errorMessage = response['message'] ?? 'Không tìm thấy đơn hàng';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Receive order at warehouse (Story #8)
  Future<bool> receiveOrder({
    required String token,
    required String orderId,
    required String packageSize,
    required String packageType,
    required double weight,
    String? description,
    List<String>? images,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.receiveOrder(
        token: token,
        orderId: orderId,
        packageSize: packageSize,
        packageType: packageType,
        weight: weight,
        description: description,
        images: images,
      );

      _isLoading = false;
      if (response['success']) {
        // Update order in lists
        final updatedOrder = Order.fromJson(response['order']);
        _pendingOrders.removeWhere((o) => o.id == orderId);
        _receivedOrders.add(updatedOrder);
        _currentOrder = updatedOrder;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Không thể nhận hàng';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Classify order (Story #9)
  Future<bool> classifyOrder({
    required String token,
    required String orderId,
    required String zone,
    required String recommendedVehicle,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.classifyOrder(
        token: token,
        orderId: orderId,
        zone: zone,
        recommendedVehicle: recommendedVehicle,
      );

      _isLoading = false;
      if (response['success']) {
        final updatedOrder = Order.fromJson(response['order']);
        _receivedOrders.removeWhere((o) => o.id == orderId);
        _classifiedOrders.add(updatedOrder);
        _currentOrder = updatedOrder;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Không thể phân loại';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get available drivers (Story #21)
  Future<List<Map<String, dynamic>>> getAvailableDrivers({
    required String token,
    String? vehicleType,
  }) async {
    try {
      final response = await _apiService.getAvailableDrivers(token, vehicleType: vehicleType);
      
      if (response['success']) {
        final List<dynamic> driversData = response['drivers'] ?? [];
        return driversData.cast<Map<String, dynamic>>();
      } else {
        _errorMessage = response['message'] ?? 'Không thể tải danh sách tài xế';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  // Assign driver (Story #21 integration)
  Future<bool> assignDriver({
    required String token,
    required String orderId,
    required String driverId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.assignDriver(
        token: token,
        orderId: orderId,
        driverId: driverId,
      );

      _isLoading = false;
      if (response['success']) {
        final updatedOrder = Order.fromJson(response['order']);
        _classifiedOrders.removeWhere((o) => o.id == orderId);
        _readyOrders.add(updatedOrder);
        _currentOrder = updatedOrder;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Không thể phân tài xế';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Collect COD from sender (Story #12)
  Future<bool> collectCOD({
    required String token,
    required String orderId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.collectCODAtWarehouse(
        token: token,
        orderId: orderId,
        amount: amount,
      );

      _isLoading = false;
      if (response['success']) {
        final updatedOrder = Order.fromJson(response['order']);
        
        // Update order in appropriate list
        _updateOrderInLists(updatedOrder);
        _currentOrder = updatedOrder;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Không thể xác nhận COD';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper: Update order in lists
  void _updateOrderInLists(Order updatedOrder) {
    final orderId = updatedOrder.id;
    
    // Remove from all lists first
    _pendingOrders.removeWhere((o) => o.id == orderId);
    _receivedOrders.removeWhere((o) => o.id == orderId);
    _classifiedOrders.removeWhere((o) => o.id == orderId);
    _readyOrders.removeWhere((o) => o.id == orderId);
    
    // Add to appropriate list
    switch (updatedOrder.status) {
      case OrderStatus.pending:
        _pendingOrders.add(updatedOrder);
        break;
      case OrderStatus.receivedAtWarehouse:
        _receivedOrders.add(updatedOrder);
        break;
      case OrderStatus.classified:
        _classifiedOrders.add(updatedOrder);
        break;
      case OrderStatus.readyForPickup:
        _readyOrders.add(updatedOrder);
        break;
    }
  }

  // Get order by ID
  Order? getOrderById(String orderId) {
    final allOrders = [..._pendingOrders, ..._receivedOrders, ..._classifiedOrders, ..._readyOrders];
    try {
      return allOrders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Set current order
  void setCurrentOrder(Order? order) {
    _currentOrder = order;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _pendingOrders.clear();
    _receivedOrders.clear();
    _classifiedOrders.clear();
    _readyOrders.clear();
    _currentOrder = null;
    _errorMessage = null;
    notifyListeners();
  }
}
