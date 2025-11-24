import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;

  // ===== AUTH ENDPOINTS =====

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      // Check HTTP status code
      if (response.statusCode == 200 && data['status'] == 'success') {
        // Transform backend response to expected format
        return {
          'success': true,
          'user': data['data']['user'],
          'token': data['data']['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // ===== WAREHOUSE ENDPOINTS =====

  Future<Map<String, dynamic>> getWarehouseOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/warehouse/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> searchOrderByCode(String token, String orderCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/warehouse/orders/search?code=$orderCode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Story #8: Receive order at warehouse
  Future<Map<String, dynamic>> receiveOrder({
    required String token,
    required String orderId,
    required String packageSize,
    required String packageType,
    required double weight,
    String? description,
    List<String>? images,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/warehouse/receive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': int.parse(orderId), // Convert string to int
          'package_size': packageSize,
          'package_type': packageType,
          'weight': weight,
          'description': description,
          'images': images,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Story #9: Classify order
  Future<Map<String, dynamic>> classifyOrder({
    required String token,
    required String orderId,
    required String zone,
    required String recommendedVehicle,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/warehouse/classify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'zone': zone,
          'recommended_vehicle': recommendedVehicle,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Story #12: Collect COD at warehouse (from sender)
  Future<Map<String, dynamic>> collectCODAtWarehouse({
    required String token,
    required String orderId,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/warehouse/collect-cod'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'amount': amount,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Story #11: Generate receipt/delivery note
  Future<Map<String, dynamic>> generateReceipt({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/warehouse/generate-receipt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/warehouse/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // ===== STORY #20: ORDERS MANAGEMENT =====

  Future<List<Map<String, dynamic>>> getAllOrders(String token, {int page = 1, int limit = 10, String? status}) async {
    try {
      String url = '$baseUrl/orders-management?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getOrderById(String token, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders-management/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateOrderStatus(String token, String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders-management/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== STORY #21: DRIVER ASSIGNMENT =====

  /// Get available drivers filtered by vehicle_type
  /// Backend: GET /warehouse/drivers/available?vehicle_type=bike
  Future<List<Map<String, dynamic>>> getAvailableDrivers(
    String token,
    String vehicleType,
  ) async {
    try {
      print('📡 API getAvailableDrivers: vehicleType=$vehicleType');
      final url = '$baseUrl/warehouse/drivers/available?vehicle_type=$vehicleType';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 API Response status: ${response.statusCode}');
      print('📥 API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend returns { success: true, drivers: [...] }
        if (data['success'] == true && data['drivers'] != null) {
          final drivers = List<Map<String, dynamic>>.from(data['drivers']);
          print('✅ API getAvailableDrivers: ${drivers.length} drivers');
          return drivers;
        }
        print('⚠️ API getAvailableDrivers: No drivers in response');
        return [];
      }
      print('❌ API getAvailableDrivers: status ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ getAvailableDrivers error: $e');
      return [];
    }
  }

  /// Assign driver to order
  /// Backend: POST /warehouse/assign-driver
  Future<bool> assignDriver(String token, String orderId, String driverId) async {
    try {
      print('📡 API assignDriver: orderId=$orderId, driverId=$driverId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/warehouse/assign-driver'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'driver_id': driverId,
        }),
      );

      print('📥 API assignDriver status: ${response.statusCode}');
      print('📥 API assignDriver body: ${response.body}');

      final data = jsonDecode(response.body);
      final success = response.statusCode == 200 && data['success'] == true;
      print(success ? '✅ API assignDriver: success' : '❌ API assignDriver: failed');
      return success;
    } catch (e) {
      print('❌ assignDriver error: $e');
      return false;
    }
  }

  // ===== STORY #22: ROUTE MANAGEMENT =====

  Future<List<Map<String, dynamic>>> getZones(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes/zones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRoutes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== STORY #23: PRICING POLICY =====

  Future<List<Map<String, dynamic>>> getPricingTables(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pricing/tables'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSurcharges(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pricing/surcharges'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDiscounts(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pricing/discounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== STORY #24: REPORTING =====

  Future<Map<String, dynamic>> getRevenueReport(String token, {String period = 'today'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/revenue?period=$period'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getDeliveryStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/delivery-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getDriverPerformance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/driver-performance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getCustomerAnalytics(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/customer-analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getDashboard(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
