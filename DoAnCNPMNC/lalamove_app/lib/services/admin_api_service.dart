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
        Uri.parse('$baseUrl/route-management/zones'),
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

  static Future<Map<String, dynamic>> createZone(
    String token,
    Map<String, dynamic> zoneData,
  ) async {
    try {
      print('Creating zone with data: $zoneData');
      final response = await http.post(
        Uri.parse('$baseUrl/route-management/zones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(zoneData),
      );

      print('Create zone response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Lỗi không xác định'};
      }
    } catch (e) {
      print('Lỗi createZone: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateZone(
    String token,
    int zoneId,
    Map<String, dynamic> zoneData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/route-management/zones/$zoneId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(zoneData),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Lỗi không xác định'};
      }
    } catch (e) {
      print('Lỗi updateZone: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> deleteZone(
    String token,
    int zoneId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/route-management/zones/$zoneId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi deleteZone: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getRoutes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/route-management/routes'),
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

  static Future<Map<String, dynamic>> createRoute(
    String token,
    Map<String, dynamic> routeData,
  ) async {
    try {
      print('Creating route with data: $routeData');
      final response = await http.post(
        Uri.parse('$baseUrl/route-management/routes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(routeData),
      );

      print('Create route response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Lỗi không xác định'};
      }
    } catch (e) {
      print('Lỗi createRoute: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateRoute(
    String token,
    int routeId,
    Map<String, dynamic> routeData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/route-management/routes/$routeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(routeData),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Lỗi không xác định'};
      }
    } catch (e) {
      print('Lỗi updateRoute: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== STORY #23: PRICING POLICY =====

  static Future<List<Map<String, dynamic>>> getPricingTables(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pricing/pricing'),
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

  static Future<bool> updatePricing(
    String token,
    Map<String, dynamic> pricingData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pricing/pricing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(pricingData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi updatePricing: $e');
      return false;
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

  static Future<bool> createSurcharge(
    String token,
    Map<String, dynamic> surchargeData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pricing/surcharges'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(surchargeData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Lỗi createSurcharge: $e');
      return false;
    }
  }

  static Future<bool> updateSurcharge(
    String token,
    int surchargeId,
    Map<String, dynamic> surchargeData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pricing/surcharges/$surchargeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(surchargeData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi updateSurcharge: $e');
      return false;
    }
  }

  static Future<bool> deleteSurcharge(
    String token,
    int surchargeId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pricing/surcharges/$surchargeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi deleteSurcharge: $e');
      return false;
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

  static Future<bool> createDiscount(
    String token,
    Map<String, dynamic> discountData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pricing/discounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(discountData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Lỗi createDiscount: $e');
      return false;
    }
  }

  static Future<bool> updateDiscount(
    String token,
    int discountId,
    Map<String, dynamic> discountData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pricing/discounts/$discountId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(discountData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi updateDiscount: $e');
      return false;
    }
  }

  static Future<bool> deleteDiscount(
    String token,
    int discountId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pricing/discounts/$discountId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi deleteDiscount: $e');
      return false;
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
