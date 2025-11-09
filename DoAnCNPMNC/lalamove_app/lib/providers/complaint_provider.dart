import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/complaint_model.dart';
import '../utils/constants.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  List<Complaint> get complaints => _complaints;

  Complaint? _currentComplaint;
  Complaint? get currentComplaint => _currentComplaint;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _currentPage = 1;
  int _totalPages = 1;
  String _currentFilter = 'all';

  // Get my complaints with pagination and filter
  Future<void> getMyComplaints({
    String token = '',
    int page = 1,
    int limit = 10,
    String status = 'all',
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
    _currentFilter = status;
    notifyListeners();

    try {
      final url = Uri.parse(
        '${AppConstants.apiBaseUrl}/complaints/my-complaints?page=$page&limit=$limit&status=$status',
      );

      print('📡 Fetching complaints: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          // Backend returns data nested in 'data' object
          final responseData = data['data'] ?? data;
          
          _complaints = (responseData['complaints'] as List)
              .map((json) => Complaint.fromJson(json))
              .toList();
          
          if (responseData['pagination'] != null) {
            _totalPages = responseData['pagination']['totalPages'] ?? responseData['pagination']['total_pages'];
          }
          
          print('✅ Loaded ${_complaints.length} complaints');
        } else {
          _error = data['message'] ?? 'Failed to load complaints';
          print('❌ Error: $_error');
        }
      } else if (response.statusCode == 401) {
        _error = 'Phiên đăng nhập đã hết hạn';
      } else {
        _error = 'Lỗi tải khiếu nại: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      print('❌ Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get complaint detail with conversation
  Future<void> getComplaintDetail({
    required int complaintId,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/complaints/$complaintId');
      
      print('📡 Fetching complaint detail: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          _currentComplaint = Complaint.fromJson(data['complaint']);
          print('✅ Loaded complaint detail with ${_currentComplaint?.responses?.length ?? 0} responses');
        } else {
          _error = data['message'] ?? 'Failed to load complaint detail';
        }
      } else if (response.statusCode == 404) {
        _error = 'Không tìm thấy khiếu nại';
      } else if (response.statusCode == 401) {
        _error = 'Phiên đăng nhập đã hết hạn';
      } else {
        _error = 'Lỗi tải chi tiết: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      print('❌ Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send reply to complaint
  Future<bool> sendReply({
    required int complaintId,
    required String message,
    required String token,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/complaints/$complaintId/respond');
      
      print('📡 Sending reply to complaint $complaintId');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'message': message}),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          print('✅ Reply sent successfully');
          // Refresh complaint detail to get new response
          await getComplaintDetail(complaintId: complaintId, token: token);
          return true;
        }
      }
      
      _error = 'Không thể gửi phản hồi';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      print('❌ Exception: $e');
      notifyListeners();
      return false;
    }
  }

  // Refresh current page
  Future<void> refresh(String token) async {
    await getMyComplaints(
      token: token,
      page: _currentPage,
      status: _currentFilter,
    );
  }

  // Load next page
  Future<void> loadNextPage(String token) async {
    if (_currentPage < _totalPages && !_isLoading) {
      await getMyComplaints(
        token: token,
        page: _currentPage + 1,
        status: _currentFilter,
      );
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear current complaint
  void clearCurrentComplaint() {
    _currentComplaint = null;
    notifyListeners();
  }
}
