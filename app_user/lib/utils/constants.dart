import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dark = Color(0xFF1F2937);
  static const Color light = Color(0xFFF8FAFC);
  static const Color grey = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFF3F4F6);
}

class AppConstants {
  // Use 10.0.2.2 for Android Emulator, localhost for Web/iOS
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';
  static const String socketUrl = 'http://10.0.2.2:3000';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String ordersEndpoint = '/orders';
  static const String trackingEndpoint = '/tracking';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Order Status
  static const String statusPending = 'pending';
  static const String statusProcessing = 'processing';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';
  
  // Delivery Status
  static const String deliveryPreparing = 'preparing';
  static const String deliveryPickedUp = 'picked_up';
  static const String deliveryOnTheWay = 'on_the_way';
  static const String deliveryDelivered = 'delivered';
}

class AppTexts {
  static const String appName = 'Food Delivery';
  static const String welcomeMessage = 'Chào mừng đến với Food Delivery';
  static const String loginTitle = 'Đăng nhập';
  static const String registerTitle = 'Đăng ký';
  static const String emailHint = 'Nhập email của bạn';
  static const String passwordHint = 'Nhập mật khẩu';
  static const String fullNameHint = 'Nhập họ và tên';
  static const String phoneHint = 'Nhập số điện thoại';
  static const String addressHint = 'Nhập địa chỉ';
  static const String loginButton = 'Đăng nhập';
  static const String registerButton = 'Đăng ký';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String noAccount = 'Chưa có tài khoản?';
  static const String hasAccount = 'Đã có tài khoản?';
  static const String createOrder = 'Tạo đơn hàng';
  static const String myOrders = 'Đơn hàng của tôi';
  static const String tracking = 'Theo dõi giao hàng';
  static const String profile = 'Hồ sơ';
  static const String logout = 'Đăng xuất';
  static const String loading = 'Đang tải...';
  static const String error = 'Lỗi';
  static const String success = 'Thành công';
  static const String retry = 'Thử lại';
  static const String cancel = 'Hủy';
  static const String confirm = 'Xác nhận';
  static const String save = 'Lưu';
  static const String edit = 'Chỉnh sửa';
  static const String delete = 'Xóa';
  static const String view = 'Xem';
  static const String back = 'Quay lại';
  static const String next = 'Tiếp theo';
  static const String previous = 'Trước';
  static const String finish = 'Hoàn thành';
  static const String orderNumber = 'Mã đơn hàng';
  static const String restaurantName = 'Tên nhà hàng';
  static const String totalAmount = 'Tổng tiền';
  static const String orderStatus = 'Trạng thái đơn hàng';
  static const String deliveryStatus = 'Trạng thái giao hàng';
  static const String orderDate = 'Ngày đặt hàng';
  static const String deliveryAddress = 'Địa chỉ giao hàng';
  static const String deliveryPhone = 'Số điện thoại';
  static const String notes = 'Ghi chú';
  static const String items = 'Sản phẩm';
  static const String quantity = 'Số lượng';
  static const String price = 'Giá';
  static const String subtotal = 'Tạm tính';
  static const String deliveryFee = 'Phí giao hàng';
  static const String total = 'Tổng cộng';
  static const String addItem = 'Thêm sản phẩm';
  static const String removeItem = 'Xóa sản phẩm';
  static const String selectRestaurant = 'Chọn nhà hàng';
  static const String enterRestaurantName = 'Nhập tên nhà hàng';
  static const String enterItemName = 'Nhập tên sản phẩm';
  static const String enterPrice = 'Nhập giá';
  static const String enterQuantity = 'Nhập số lượng';
  static const String enterDeliveryAddress = 'Nhập địa chỉ giao hàng';
  static const String enterDeliveryPhone = 'Nhập số điện thoại';
  static const String enterNotes = 'Nhập ghi chú (tùy chọn)';
  static const String realTimeTracking = 'Theo dõi thời gian thực';
  static const String estimatedTime = 'Thời gian dự kiến';
  static const String currentLocation = 'Vị trí hiện tại';
  static const String deliveryRoute = 'Tuyến đường giao hàng';
  static const String mapView = 'Xem bản đồ';
  static const String listView = 'Xem danh sách';
  static const String refresh = 'Làm mới';
  static const String search = 'Tìm kiếm';
  static const String filter = 'Lọc';
  static const String sort = 'Sắp xếp';
  static const String all = 'Tất cả';
  static const String pending = 'Chờ xử lý';
  static const String processing = 'Đang xử lý';
  static const String shipped = 'Đang giao';
  static const String delivered = 'Đã giao';
  static const String cancelled = 'Đã hủy';
  static const String preparing = 'Chuẩn bị';
  static const String pickedUp = 'Đã lấy hàng';
  static const String onTheWay = 'Đang giao';
  static const String deliveredStatus = 'Đã giao';
}

class AppValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }
  
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
  
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Giá không được để trống';
    }
    if (double.tryParse(value) == null) {
      return 'Giá không hợp lệ';
    }
    if (double.parse(value) <= 0) {
      return 'Giá phải lớn hơn 0';
    }
    return null;
  }
  
  static String? quantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số lượng không được để trống';
    }
    if (int.tryParse(value) == null) {
      return 'Số lượng không hợp lệ';
    }
    if (int.parse(value) <= 0) {
      return 'Số lượng phải lớn hơn 0';
    }
    return null;
  }
}

class AppUtils {
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }
  
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  static String getStatusText(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppTexts.pending;
      case AppConstants.statusProcessing:
        return AppTexts.processing;
      case AppConstants.statusShipped:
        return AppTexts.shipped;
      case AppConstants.statusDelivered:
        return AppTexts.delivered;
      case AppConstants.statusCancelled:
        return AppTexts.cancelled;
      case AppConstants.deliveryPreparing:
        return AppTexts.preparing;
      case AppConstants.deliveryPickedUp:
        return AppTexts.pickedUp;
      case AppConstants.deliveryOnTheWay:
        return AppTexts.onTheWay;
      case AppConstants.deliveryDelivered:
        return AppTexts.deliveredStatus;
      default:
        return status;
    }
  }
  
  static Color getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
      case AppConstants.deliveryPreparing:
        return AppColors.warning;
      case AppConstants.statusProcessing:
      case AppConstants.deliveryPickedUp:
        return AppColors.primary;
      case AppConstants.statusShipped:
      case AppConstants.deliveryOnTheWay:
        return AppColors.secondary;
      case AppConstants.statusDelivered:
      case AppConstants.deliveryDelivered:
        return AppColors.success;
      case AppConstants.statusCancelled:
        return AppColors.danger;
      default:
        return AppColors.grey;
    }
  }
}
