import 'package:flutter/material.dart';

// API Configuration
class AppConstants {
  static const String apiBaseUrl = 'http://localhost:3000/api';
  
  // Auth endpoints
  static const String loginEndpoint = '/auth/driver/login';
  static const String registerEndpoint = '/auth/driver/register';
  static const String profileEndpoint = '/driver/profile';
  
  // Order endpoints
  static const String availableOrdersEndpoint = '/orders/available';
  static const String activeOrdersEndpoint = '/orders/active';
  static const String ordersEndpoint = '/orders';
  
  // Driver endpoints
  static const String driverStatusEndpoint = '/driver/status';
  static const String driverLocationEndpoint = '/driver/location';
  static const String earningsEndpoint = '/driver/earnings';
  
  // Order statuses
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusEnRouteToPickup = 'en_route_to_pickup';
  static const String statusPickedUp = 'picked_up';
  static const String statusEnRouteToDelivery = 'en_route_to_delivery';
  static const String statusDelivered = 'delivered';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusFailedDelivery = 'failed_delivery'; // #18 - Không giao được
  static const String statusReturning = 'returning'; // #18 - Đang trả hàng
  static const String statusReturned = 'returned'; // #18 - Đã trả hàng
  
  // Payment methods
  static const String paymentOnline = 'online';
  static const String paymentCOD = 'cod'; // #19 - Cash on Delivery
  
  // Storage keys
  static const String tokenKey = 'driver_auth_token';
  static const String userKey = 'driver_user_data';
  static const String onlineStatusKey = 'driver_online_status';
  
  // Socket events
  static const String socketConnect = 'connect';
  static const String socketDisconnect = 'disconnect';
  static const String socketLocationUpdate = 'driver:location-update';
  static const String socketOrderAssigned = 'driver:order-assigned';
  static const String socketOrderStatusChanged = 'order:status-changed';
}

// Colors (Lalamove Style)
class AppColors {
  static const Color primary = Color(0xFFF26522); // Orange
  static const Color primaryDark = Color(0xFFD64F0A); // Dark Orange
  static const Color secondary = Color(0xFF2C3E50); // Dark Blue/Gray
  
  static const Color success = Color(0xFF27AE60); // Green
  static const Color danger = Color(0xFFE74C3C); // Red
  static const Color warning = Color(0xFFF39C12); // Yellow
  static const Color info = Color(0xFF3498DB); // Blue
  
  static const Color dark = Color(0xFF2C3E50);
  static const Color grey = Color(0xFF95A5A6);
  static const Color lightGrey = Color(0xFFECF0F1);
  static const Color background = Color(0xFFF8F9FA);
  
  // Status colors
  static const Color statusIdle = Color(0xFF95A5A6); // Gray
  static const Color statusOnline = Color(0xFF27AE60); // Green
  static const Color statusBusy = Color(0xFFF39C12); // Orange
  static const Color statusOffline = Color(0xFF7F8C8D); // Dark Gray
}

// Text constants
class AppTexts {
  // App
  static const String appName = 'Lalamove Driver';
  static const String appTagline = 'Giao hàng - Kiếm tiền dễ dàng';
  
  // Auth
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String logout = 'Đăng xuất';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String fullName = 'Họ và tên';
  static const String phone = 'Số điện thoại';
  static const String driverLicense = 'CMND/CCCD';
  static const String vehicleType = 'Loại xe';
  static const String vehiclePlate = 'Biển số xe';
  
  // Dashboard
  static const String dashboard = 'Trang chủ';
  static const String todayEarnings = 'Thu nhập hôm nay';
  static const String todayDeliveries = 'Đơn giao hôm nay';
  static const String averageRating = 'Đánh giá TB';
  static const String onlineTime = 'Thời gian online';
  static const String goOnline = 'Bật nhận đơn';
  static const String goOffline = 'Tắt nhận đơn';
  
  // Orders
  static const String availableOrders = 'Đơn hàng có sẵn';
  static const String activeOrders = 'Đơn đang giao';
  static const String orderHistory = 'Lịch sử giao hàng';
  static const String orderDetails = 'Chi tiết đơn hàng';
  static const String acceptOrder = 'Nhận đơn';
  static const String rejectOrder = 'Từ chối';
  static const String pickupLocation = 'Điểm lấy hàng';
  static const String deliveryLocation = 'Điểm giao hàng';
  static const String distance = 'Khoảng cách';
  static const String deliveryFee = 'Phí giao hàng';
  static const String packageInfo = 'Thông tin kiện hàng';
  
  // Status
  static const String pending = 'Chờ tài xế';
  static const String accepted = 'Đã nhận đơn';
  static const String pickingUp = 'Đang đến lấy hàng';
  static const String pickedUp = 'Đã lấy hàng';
  static const String delivering = 'Đang giao hàng';
  static const String delivered = 'Đã giao hàng';
  static const String completed = 'Hoàn thành';
  static const String cancelled = 'Đã hủy';
  
  // Actions
  static const String startPickup = 'Bắt đầu lấy hàng';
  static const String confirmPickup = 'Xác nhận đã lấy hàng';
  static const String startDelivery = 'Bắt đầu giao hàng';
  static const String confirmDelivery = 'Xác nhận đã giao';
  static const String callCustomer = 'Gọi khách hàng';
  static const String navigate = 'Dẫn đường';
  static const String takePhoto = 'Chụp ảnh';
  static const String reportIssue = 'Báo cáo vấn đề'; // #18
  static const String confirmCOD = 'Xác nhận thu COD'; // #19
  
  // Earnings
  static const String earnings = 'Thu nhập';
  static const String totalEarnings = 'Tổng thu nhập';
  static const String todayTotal = 'Hôm nay';
  static const String weekTotal = 'Tuần này';
  static const String monthTotal = 'Tháng này';
  
  // COD - #19
  static const String codTracking = 'Quản lý COD';
  static const String codBalance = 'Tiền COD đang giữ';
  static const String codCollected = 'Đã thu COD';
  static const String submitCOD = 'Nộp tiền COD';
  
  // Issue Reporting - #18
  static const String deliveryIssue = 'Vấn đề giao hàng';
  static const String customerNotHome = 'Khách không có nhà';
  static const String wrongAddress = 'Địa chỉ sai';
  static const String customerRefused = 'Khách từ chối nhận';
  static const String itemDamaged = 'Hàng hóa hư hỏng';
  static const String cannotContact = 'Không liên lạc được';
  static const String otherIssue = 'Lý do khác';
  
  // Profile
  static const String profile = 'Tài khoản';
  static const String editProfile = 'Sửa thông tin';
  static const String settings = 'Cài đặt';
  static const String vehicleInfo = 'Thông tin xe';
  static const String statistics = 'Thống kê';
  
  // Messages
  static const String noOrdersAvailable = 'Không có đơn hàng mới';
  static const String noActiveOrders = 'Không có đơn đang giao';
  static const String orderAcceptedSuccess = 'Đã nhận đơn hàng thành công';
  static const String orderRejectedSuccess = 'Đã từ chối đơn hàng';
  static const String locationPermissionRequired = 'Cần quyền truy cập vị trí';
}

// Validators
class AppValidators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
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
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
}

// Utilities
class AppUtils {
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}₫';
  }
  
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
  
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  
  static Color getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.warning;
      case AppConstants.statusAccepted:
      case AppConstants.statusEnRouteToPickup:
        return AppColors.info;
      case AppConstants.statusPickedUp:
      case AppConstants.statusEnRouteToDelivery:
        return AppColors.primary;
      case AppConstants.statusDelivered:
      case AppConstants.statusCompleted:
        return AppColors.success;
      case AppConstants.statusCancelled:
      case AppConstants.statusFailedDelivery:
        return AppColors.danger;
      case AppConstants.statusReturning:
      case AppConstants.statusReturned:
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }
  
  static String getStatusText(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppTexts.pending;
      case AppConstants.statusAccepted:
        return AppTexts.accepted;
      case AppConstants.statusEnRouteToPickup:
        return AppTexts.pickingUp;
      case AppConstants.statusPickedUp:
        return AppTexts.pickedUp;
      case AppConstants.statusEnRouteToDelivery:
        return AppTexts.delivering;
      case AppConstants.statusDelivered:
        return AppTexts.delivered;
      case AppConstants.statusCompleted:
        return AppTexts.completed;
      case AppConstants.statusCancelled:
        return AppTexts.cancelled;
      case AppConstants.statusFailedDelivery:
        return 'Giao thất bại';
      case AppConstants.statusReturning:
        return 'Đang trả hàng';
      case AppConstants.statusReturned:
        return 'Đã trả hàng';
      default:
        return status;
    }
  }
  
  static IconData getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'van_500':
      case 'van_750':
      case 'van_1000':
        return Icons.local_shipping;
      default:
        return Icons.delivery_dining;
    }
  }
  
  static String getVehicleText(String vehicleType) {
    switch (vehicleType) {
      case 'motorcycle':
        return 'Xe máy';
      case 'van_500':
        return 'Van 500kg';
      case 'van_750':
        return 'Van 750kg';
      case 'van_1000':
        return 'Van 1000kg';
      default:
        return 'Xe giao hàng';
    }
  }
}
