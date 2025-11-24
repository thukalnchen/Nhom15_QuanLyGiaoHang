import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String appName = 'Lalamove Shipper';
  static const String appVersion = '1.0.0';
  
  // IMPORTANT: Set these for your development environment
  static const String laptopIp = '192.168.1.173'; // ⚠️ Your laptop's IP
  static const bool usePhysicalDevice = true;     // ⚠️ false for Android Emulator

  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return usePhysicalDevice ? 'http://$laptopIp:3000/api' : 'http://10.0.2.2:3000/api';
  }

  static String get socketUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return usePhysicalDevice ? 'http://$laptopIp:3000' : 'http://10.0.2.2:3000';
  }
}

class ApiEndpoints {
  static const String login = '/auth/login';
  static const String registerShipper = '/auth/register/shipper';
  static const String shipperOrders = '/shippers/me/orders';
  static const String shipperOrderDetails = '/shippers/orders';
  static const String shipperCheckIn = '/shippers/me/check-in';
}

class StorageKeys {
  static const String token = 'shipper_auth_token';
  static const String user = 'shipper_user';
}

class AppColors {
  static const Color primary = Color(0xFFF26522);
  static const Color primaryDark = Color(0xFFD45419);
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF212121);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFACC15);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double round = 999;
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.black,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.grey,
  );
}

class AppTexts {
  static const String loginTitle = 'Đăng nhập Shipper';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String remember = 'Ghi nhớ đăng nhập';
  static const String login = 'Đăng nhập';
  static const String orders = 'Đơn giao hàng';
  static const String logout = 'Đăng xuất';
  static const String status = 'Trạng thái';
  static const String pickupAddress = 'Điểm lấy hàng';
  static const String deliveryAddress = 'Điểm giao hàng';
  static const String recipient = 'Người nhận';
  static const String customer = 'Khách hàng';
  static const String call = 'Gọi';
  static const String startDelivery = 'Bắt đầu giao';
  static const String deliveredSuccess = 'Giao thành công';
  static const String deliveredFailed = 'Giao thất bại';
  static const String loading = 'Đang tải...';
  static const String noOrders = 'Hiện chưa có đơn nào được gán cho bạn.';
  static const String registerShipperTitle = 'Đăng ký tài khoản Shipper';
  static const String fullName = 'Họ và tên';
  static const String phone = 'Số điện thoại';
  static const String vehicleType = 'Loại xe';
  static const String vehiclePlate = 'Biển số xe';
  static const String driverLicense = 'Số giấy phép lái xe';
  static const String identityCard = 'Số CCCD/CMND';
  static const String optionalNotes = 'Ghi chú (tùy chọn)';
  static const String createAccount = 'Đăng ký';
  static const String haveAccount = 'Đã có tài khoản?';
  static const String goToLogin = 'Đăng nhập ngay';
  static const String noAccount = 'Chưa có tài khoản?';
  static const String goToRegister = 'Đăng ký tài khoản';
  static const String shipperPendingMessage = 'Tài khoản của bạn đang chờ quản trị viên duyệt. Vui lòng quay lại sau.';
  static const String registerSuccessMessage = 'Đăng ký thành công! Vui lòng chờ quản trị viên duyệt hồ sơ trước khi đăng nhập.';
}

class OrderStatus {
  static const String pending = 'pending';
  static const String assigned = 'assigned_to_driver';
  static const String inTransit = 'in_transit';
  static const String delivered = 'delivered';
  static const String failed = 'failed_delivery';
  static const String returning = 'returning';

  static Color color(String status) {
    switch (status) {
      case assigned:
      case inTransit:
        return AppColors.info;
      case delivered:
        return AppColors.success;
      case failed:
        return AppColors.danger;
      case returning:
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Chờ xử lý';
      case assigned:
        return 'Đã nhận đơn';
      case inTransit:
        return 'Đang giao';
      case delivered:
        return 'Đã giao thành công';
      case failed:
        return 'Giao thất bại';
      case returning:
        return 'Đang hoàn trả';
      default:
        return status;
    }
  }
}


