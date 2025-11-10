import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String? _token;
  static const Duration _timeout = Duration(seconds: 12);

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = _safeDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${data['error'] ?? response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout after ${_timeout.inSeconds}s');
    } catch (e) {
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: _headers,
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = _safeDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${data['error'] ?? response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout after ${_timeout.inSeconds}s');
    } catch (e) {
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic>? body) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = _safeDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${data['error'] ?? response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout after ${_timeout.inSeconds}s');
    } catch (e) {
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  static Map<String, dynamic> _safeDecode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{'raw': body};
    }
  }
}

