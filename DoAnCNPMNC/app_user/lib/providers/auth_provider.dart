import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences prefs;
  
  AuthProvider(this.prefs) {
    _loadUserData();
  }
  
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _error;
  
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  
  void _loadUserData() {
    _token = prefs.getString(AppConstants.tokenKey);
    final userData = prefs.getString(AppConstants.userKey);
    if (userData != null) {
      _user = json.decode(userData);
    }
    _isAuthenticated = _token != null && _user != null;
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    print('🔐 Login attempt: $email');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      print('📥 Login response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _token = data['data']['token'];
          _user = data['data']['user'];
          _isAuthenticated = true;
          
          print('✅ Login successful!');
          print('   User ID: ${_user!['id']}');
          print('   Email: ${_user!['email']}');
          print('   Token: ${_token!.substring(0, 20)}...');
          
          await prefs.setString(AppConstants.tokenKey, _token!);
          await prefs.setString(AppConstants.userKey, json.encode(_user));
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Đăng nhập thất bại';
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> register(String email, String password, String fullName, {String? phone, String? address}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'address': address,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _token = data['data']['token'];
          _user = data['data']['user'];
          _isAuthenticated = true;
          
          await prefs.setString(AppConstants.tokenKey, _token!);
          await prefs.setString(AppConstants.userKey, json.encode(_user));
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Đăng ký thất bại';
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> updateProfile(String fullName, {String? phone, String? address}) async {
    if (!_isAuthenticated) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'full_name': fullName,
          'phone': phone,
          'address': address,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _user = data['data']['user'];
          await prefs.setString(AppConstants.userKey, json.encode(_user));
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Cập nhật thất bại';
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Cập nhật thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<void> logout() async {
    print('🚪 Logging out...');
    print('   Clearing user: ${_user?['email']}');
    
    _token = null;
    _user = null;
    _isAuthenticated = false;
    _error = null;
    
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    
    print('✅ Logout complete - all data cleared');
    
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
