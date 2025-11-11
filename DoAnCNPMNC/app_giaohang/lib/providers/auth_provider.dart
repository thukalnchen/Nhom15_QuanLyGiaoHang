import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  ShipperUser? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  ShipperUser? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(StorageKeys.token);
    final savedUser = prefs.getString(StorageKeys.user);

    if (savedToken != null && savedUser != null) {
      try {
        final decoded = json.decode(savedUser) as Map<String, dynamic>;
        _token = savedToken;
        _user = ShipperUser.fromJson(decoded);
      } catch (error) {
        debugPrint('loadSession decode error: $error');
        await prefs.remove(StorageKeys.token);
        await prefs.remove(StorageKeys.user);
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.login}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'role': 'shipper',
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'success') {
        final payload = data['data'] as Map<String, dynamic>;
        final userData = payload['user'] as Map<String, dynamic>;
        _token = payload['token']?.toString();
        _user = ShipperUser.fromJson(userData);
        if (!_user!.isShipper) {
          _error = 'Tài khoản không có quyền truy cập ứng dụng shipper';
          _user = null;
          _token = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(StorageKeys.token, _token!);
        await prefs.setString(StorageKeys.user, json.encode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (response.statusCode == 403) {
        final code = data['code']?.toString();
        if (code == 'SHIPPER_PENDING') {
          _error = AppTexts.shipperPendingMessage;
        } else {
          _error = data['message']?.toString() ?? 'Tài khoản shipper không hợp lệ';
        }
      } else {
        _error = data['message']?.toString() ?? 'Đăng nhập thất bại';
      }
    } catch (error) {
      _error = 'Không thể kết nối tới máy chủ. Vui lòng thử lại.';
      debugPrint('login error: $error');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> registerShipper({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? address,
    required String vehicleType,
    required String vehiclePlate,
    required String driverLicenseNumber,
    required String identityCardNumber,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.registerShipper}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'address': address?.trim(),
          'vehicle_type': vehicleType.trim(),
          'vehicle_plate': vehiclePlate.trim().toUpperCase(),
          'driver_license_number': driverLicenseNumber.trim(),
          'identity_card_number': identityCardNumber.trim(),
          'notes': notes?.trim(),
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['status'] == 'success') {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = data['message']?.toString() ?? 'Đăng ký thất bại';
    } catch (error) {
      _error = 'Không thể kết nối tới máy chủ. Vui lòng thử lại.';
      debugPrint('registerShipper error: $error');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.token);
    await prefs.remove(StorageKeys.user);
    _user = null;
    _token = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


