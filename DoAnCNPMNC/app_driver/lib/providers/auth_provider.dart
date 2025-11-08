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
  bool _isOnline = false;
  
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  bool get isOnline => _isOnline;
  
  void _loadUserData() {
    _token = prefs.getString(AppConstants.tokenKey);
    final userData = prefs.getString(AppConstants.userKey);
    if (userData != null) {
      _user = json.decode(userData);
    }
    _isOnline = prefs.getBool(AppConstants.onlineStatusKey) ?? false;
    _isAuthenticated = _token != null && _user != null;
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
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
      
      if (response.statusCode == 200) {
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
  
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String driverLicense,
    required String vehicleType,
    required String vehiclePlate,
  }) async {
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
          'driver_license': driverLicense,
          'vehicle_type': vehicleType,
          'vehicle_plate': vehiclePlate,
          'role': 'driver',
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
  
  Future<void> toggleOnlineStatus() async {
    if (_token == null) return;
    
    _isOnline = !_isOnline;
    await prefs.setBool(AppConstants.onlineStatusKey, _isOnline);
    notifyListeners();
    
    // TODO: Call API to update online status on server
    try {
      await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.driverStatusEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'is_online': _isOnline}),
      );
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }
  
  Future<void> logout() async {
    _token = null;
    _user = null;
    _isAuthenticated = false;
    _isOnline = false;
    
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.onlineStatusKey);
    
    notifyListeners();
  }
}
