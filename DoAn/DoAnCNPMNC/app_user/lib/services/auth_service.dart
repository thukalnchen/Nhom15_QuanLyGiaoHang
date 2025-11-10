import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';

  // Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? address,
  }) async {
    final response = await ApiService.post(ApiConfig.register, {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'address': address,
    });

    if (response['token'] != null) {
      await saveToken(response['token']);
      if (response['user'] != null) {
        await saveUser(response['user']);
      }
    }

    return response;
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await ApiService.post(ApiConfig.login, {
      'email': email,
      'password': password,
    });

    if (response['token'] != null) {
      final String token = response['token'];
      ApiService.setToken(token);

      if (rememberMe) {
        await saveToken(token);
        if (response['user'] != null) {
          await saveUser(response['user']);
        }
      } else {
        await _clearPersistedSessionData();
      }
    } else if (!rememberMe) {
      await _clearPersistedSessionData();
    }

    await setRememberMePreference(rememberMe, email: rememberMe ? email : null);

    return response;
  }

  static Future<void> setRememberMePreference(bool rememberMe, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    if (rememberMe && email != null && email.isNotEmpty) {
      await prefs.setString(_rememberedEmailKey, email);
    } else {
      await prefs.remove(_rememberedEmailKey);
    }
  }

  static Future<bool> getRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberedEmailKey);
  }

  static Future<void> _clearPersistedSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Register and remember preference when token is returned
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    ApiService.setToken(token);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save user
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(userData);
    await prefs.setString(_userKey, userJson);
  }

  // Get user
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getToken();
    if (token != null) {
      ApiService.setToken(token);
    }
    // User data sẽ được lấy từ API khi cần
    return null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    ApiService.setToken(null);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

