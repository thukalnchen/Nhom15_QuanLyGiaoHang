import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// API Service cho Stories #20-24 (Admin Management)
class AdminApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // ===== STORY #20: ORDERS MANAGEMENT =====

  static Future<List<Map<String, dynamic>>> getAllOrders(
    String token, {
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/orders-management?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';

      print('📡 [ADMIN API] getAllOrders: Calling $url');
      print('📡 [ADMIN API] Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [ADMIN API] Response status: ${response.statusCode}');
      print('📦 [ADMIN API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = List<Map<String, dynamic>>.from(data['data']['orders'] ?? []);
        print('✅ [ADMIN API] Loaded ${orders.length} orders');
        return orders;
      }
      print('❌ [ADMIN API] Failed with status ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ [ADMIN API] Lỗi getAllOrders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getOrderById(
    String token,
    String orderId,
  ) async {
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
      print('Lỗi getOrderById: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
    String token,
    String orderId,
    String status,
  ) async {
    try {
      final url = '$baseUrl/orders-management/$orderId/status';
      print('📡 [ADMIN API] updateOrderStatus: $url');
      print('📡 [ADMIN API] Status: $status');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      print('📥 [ADMIN API] Response status: ${response.statusCode}');
      print('📦 [ADMIN API] Response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Cập nhật thành công'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Cập nhật thất bại'};
      }
    } catch (e) {
      print('❌ [ADMIN API] Lỗi updateOrderStatus: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ===== STORY #21: DRIVER ASSIGNMENT =====

  static Future<List<Map<String, dynamic>>> getAvailableDriversAdmin(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver-assignment/available'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 [ADMIN API] Available drivers response: ${data['data']}');
        return List<Map<String, dynamic>>.from(data['data']['drivers'] ?? []);
      }
      print('❌ [ADMIN API] Get drivers failed: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Lỗi getAvailableDriversAdmin: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> assignDriverToOrder(
    String token,
    String orderId,
    String driverId,
  ) async {
    try {
      print('📡 [ADMIN API] assignDriverToOrder: $orderId → driver $driverId');
      
      final url = '$baseUrl/driver-assignment/orders/$orderId/assign';
      print('🌐 [ADMIN API] Request URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'driverId': driverId,
        }),
      );

      print('📥 [ADMIN API] Response status: ${response.statusCode}');
      print('📦 [ADMIN API] Response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Phân công tài xế thành công'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể phân công tài xế'
        };
      }
    } catch (e) {
      print('❌ [ADMIN API] Lỗi assignDriverToOrder: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverWorkload(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver-assignment/workload'),
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
      print('Lỗi getDriverWorkload: $e');
      return [];
    }
  }

  // ===== STORY #22: ROUTE MANAGEMENT =====

  static Future<List<Map<String, dynamic>>> getZones(String token) async {
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
        return List<Map<String, dynamic>>.from(data['data']['zones'] ?? []);
      }
      return [];
    } catch (e) {
      print('Lỗi getZones: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRoutes(String token) async {
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
        return List<Map<String, dynamic>>.from(data['data']['routes'] ?? []);
      }
      return [];
    } catch (e) {
      print('Lỗi getRoutes: $e');
      return [];
    }
  }

  // ===== STORY #23: PRICING POLICY =====

  static Future<List<Map<String, dynamic>>> getPricingTables(
    String token,
  ) async {
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
      print('Lỗi getPricingTables: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSurcharges(String token) async {
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
      print('Lỗi getSurcharges: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDiscounts(String token) async {
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
      print('Lỗi getDiscounts: $e');
      return [];
    }
  }

  // ===== STORY #24: REPORTING =====

  static Future<Map<String, dynamic>> getRevenueReport(
    String token, {
    String period = 'today',
  }) async {
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
      print('Lỗi getRevenueReport: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getDeliveryStats(String token) async {
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
      print('Lỗi getDeliveryStats: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverPerformance(
    String token,
  ) async {
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
      print('Lỗi getDriverPerformance: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getCustomerAnalytics(
    String token,
  ) async {
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
      print('Lỗi getCustomerAnalytics: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getDashboard(String token) async {
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
      print('Lỗi getDashboard: $e');
      return {};
    }
  }
}
