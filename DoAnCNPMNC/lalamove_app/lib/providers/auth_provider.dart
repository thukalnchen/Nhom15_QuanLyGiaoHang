import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Alias for backward compatibility
  bool get isAuthenticated => _token != null && _user != null;
  
  // Role getters
  bool get isCustomer => _user?.isCustomer ?? false;
  bool get isIntakeStaff => _user?.isIntakeStaff ?? false;
  bool get isDriver => _user?.isDriver ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  // Load saved auth data from SharedPreferences
  Future<void> loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(StorageKeys.tokenKey);
      final userJson = prefs.getString(StorageKeys.userKey);
      
      if (_token != null && userJson != null) {
        final userData = json.decode(userJson);
        _user = User.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading auth data: $e');
    }
  }

  // Save auth data to SharedPreferences
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(StorageKeys.tokenKey, _token!);
      }
      if (_user != null) {
        await prefs.setString(StorageKeys.userKey, json.encode(_user!.toJson()));
        await prefs.setString(StorageKeys.roleKey, _user!.role);
      }
    } catch (e) {
      print('❌ Error saving auth data: $e');
    }
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.tokenKey);
      await prefs.remove(StorageKeys.userKey);
      await prefs.remove(StorageKeys.roleKey);
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    print('🔐 Login attempt: $email');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.login}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      print('📥 Login response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if response has success field
        if (data['status'] == 'success' || data['success'] == true) {
          // Handle both response formats
          if (data['data'] != null) {
            _token = data['data']['token'];
            _user = User.fromJson(data['data']['user']);
          } else {
            _token = data['token'];
            _user = User.fromJson(data['user']);
          }
          
          print('✅ Login successful!');
          print('   User ID: ${_user!.id}');
          print('   Email: ${_user!.email}');
          print('   Role: ${_user!.role}');
          print('   Token: ${_token!.substring(0, 20)}...');
          
          await _saveAuthData();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Đăng nhập thất bại';
        }
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      print('❌ Login error: $e');
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? address,
  }) async {
    print('📝 Register attempt: $email');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.register}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'address': address,
          // role is automatically set to 'customer' in backend
        }),
      );
      
      print('📥 Register response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' || data['success'] == true) {
          print('✅ Registration successful!');
          
          // Auto login after registration
          if (data['data'] != null && data['data']['token'] != null) {
            _token = data['data']['token'];
            _user = User.fromJson(data['data']['user']);
            await _saveAuthData();
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Đăng ký thất bại';
        }
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      print('❌ Register error: $e');
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    print('👋 Logging out...');
    
    _user = null;
    _token = null;
    _errorMessage = null;
    
    await _clearAuthData();
    notifyListeners();
    
    print('✅ Logout successful!');
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Update user profile (overloaded for backward compatibility)
  Future<bool> updateProfile(dynamic nameOrUpdates, {String? phone, String? address}) async {
    if (_user == null || _token == null) return false;
    
    // Handle both signatures:
    // 1. updateProfile(String fullName, {String? phone, String? address})
    // 2. updateProfile(Map<String, dynamic> updates)
    Map<String, dynamic> updates;
    if (nameOrUpdates is String) {
      updates = {'full_name': nameOrUpdates};
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
    } else if (nameOrUpdates is Map<String, dynamic>) {
      updates = nameOrUpdates;
    } else {
      return false;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.profile}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(updates),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _user = User.fromJson(data['data']['user']);
          await _saveAuthData();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      _errorMessage = 'Lỗi khi cập nhật thông tin';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
