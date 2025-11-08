import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  bool _isTracking = false;
  String? _error;
  
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String? get error => _error;
  
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  Future<bool> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _error = 'Cần quyền truy cập vị trí';
        notifyListeners();
        return false;
      }
      
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi lấy vị trí: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  void startTracking() {
    _isTracking = true;
    notifyListeners();
    // TODO: Implement real-time location tracking
  }
  
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }
}
