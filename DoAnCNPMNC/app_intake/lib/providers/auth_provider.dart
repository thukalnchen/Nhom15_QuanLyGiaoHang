import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _user != null;

  final ApiService _apiService = ApiService();

  // Load saved auth data
  Future<void> loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');
      
      if (_token != null && userJson != null) {
        // Parse user data
        final userData = userJson.split('|');
        if (userData.length >= 6) {
          _user = User(
            id: userData[0],
            name: userData[1],
            email: userData[2],
            phone: userData[3],
            role: userData[4],
            warehouseId: userData.length > 5 ? userData[5] : null,
            warehouseName: userData.length > 6 ? userData[6] : null,
            createdAt: DateTime.now(),
          );
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading auth data: $e');
    }
  }

  // Save auth data
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      }
      if (_user != null) {
        final userData = '${_user!.id}|${_user!.name}|${_user!.email}|${_user!.phone}|${_user!.role}|${_user!.warehouseId ?? ''}|${_user!.warehouseName ?? ''}';
        await prefs.setString('user_data', userData);
      }
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        
        // Verify role
        if (_user?.role != 'intake_staff') {
          _errorMessage = 'Tài khoản không có quyền truy cập ứng dụng này';
          _token = null;
          _user = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        await _saveAuthData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Đăng nhập thất bại';
        _isLoading = false;
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

  // Logout
  Future<void> logout() async {
    _user = null;
    _token = null;
    _errorMessage = null;
    await _clearAuthData();
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    if (_user == null || _token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        token: _token!,
        name: name,
        email: email,
        phone: phone,
      );

      if (response['success']) {
        _user = User.fromJson(response['user']);
        await _saveAuthData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Cập nhật thất bại';
        _isLoading = false;
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

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.changePassword(
        token: _token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;
      if (response['success']) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Đổi mật khẩu thất bại';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
