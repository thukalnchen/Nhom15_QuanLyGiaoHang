import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ===== APP CONFIG =====
class AppConfig {
  static const String appName = 'Lalamove';
  static const String appVersion = '1.0.0';
  
  // Auto-detect platform: localhost for Web, 10.0.2.2 for Android Emulator
  static final String apiBaseUrl = kIsWeb 
      ? 'http://localhost:3000/api'  // Web browser
      : 'http://10.0.2.2:3000/api';   // Android Emulator
  
  static final String socketUrl = kIsWeb
      ? 'http://localhost:3000'       // Web browser
      : 'http://10.0.2.2:3000';        // Android Emulator
}

// ===== COLORS (LALAMOVE THEME) =====
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFF26522); // Lalamove Orange
  static const Color primaryDark = Color(0xFFD45419);
  static const Color primaryLight = Color(0xFFF58C5C);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF212121);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Additional colors for app_user compatibility
  static const Color secondary = Color(0xFF2C3E50);
  static const Color danger = Color(0xFFEF4444); // Alias for error
  static const Color dark = Color(0xFF1F2937);
  static const Color light = Color(0xFFF8FAFC);
  static const Color lightGrey = Color(0xFFF3F4F6);
}

// ===== STORAGE KEYS =====
class StorageKeys {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
}

// ===== APP CONSTANTS =====
class AppConstants {
  // Auto-detect platform: localhost for Web, 10.0.2.2 for Android Emulator
  static final String apiBaseUrl = kIsWeb 
      ? 'http://localhost:3000/api'  // Web browser
      : 'http://10.0.2.2:3000/api';   // Android Emulator
  
  static final String socketUrl = kIsWeb
      ? 'http://localhost:3000'       // Web browser
      : 'http://10.0.2.2:3000';        // Android Emulator
  
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

// ===== APP TEXTS (Vietnamese Labels) =====
class AppTexts {
  static const String appName = 'Lalamove Express';
  static const String welcomeMessage = 'Giao hàng nhanh - An toàn - Tiện lợi';
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
  static const String createOrder = 'Tạo đơn giao hàng';
  static const String myOrders = 'Đơn hàng của tôi';
  static const String tracking = 'Theo dõi đơn hàng';
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
  static const String senderName = 'Người gửi';
  static const String totalAmount = 'Tổng tiền';
  static const String orderStatus = 'Trạng thái đơn hàng';
  static const String deliveryStatus = 'Trạng thái giao hàng';
  static const String orderDate = 'Ngày tạo đơn';
  static const String pickupAddress = 'Địa chỉ lấy hàng';
  static const String deliveryAddress = 'Địa chỉ giao hàng';
  static const String deliveryPhone = 'Số điện thoại người nhận';
  static const String senderPhone = 'Số điện thoại người gửi';
  static const String notes = 'Ghi chú';
  static const String packages = 'Kiện hàng';
  static const String quantity = 'Số lượng';
  static const String weight = 'Khối lượng';
  static const String price = 'Giá';
  static const String subtotal = 'Tạm tính';
  static const String deliveryFee = 'Phí giao hàng';
  static const String total = 'Tổng cộng';
  static const String addPackage = 'Thêm kiện hàng';
  static const String addItem = 'Thêm kiện hàng';
  static const String removePackage = 'Xóa kiện hàng';
  static const String selectSender = 'Chọn người gửi';
  static const String enterSenderName = 'Nhập tên người gửi';
  static const String enterPackageName = 'Nhập tên kiện hàng';
  static const String enterPrice = 'Nhập giá trị hàng hóa';
  static const String enterQuantity = 'Nhập số lượng';
  static const String enterWeight = 'Nhập khối lượng (kg)';
  static const String vehicleType = 'Loại xe';
  static const String distance = 'Khoảng cách';
  static const String estimatedTime = 'Thời gian dự kiến';
  static const String driverInfo = 'Thông tin tài xế';
  static const String driverName = 'Tên tài xế';
  static const String driverPhone = 'SĐT tài xế';
  static const String vehicleNumber = 'Biển số xe';
  static const String enterDeliveryAddress = 'Nhập địa chỉ giao hàng';
  static const String enterDeliveryPhone = 'Nhập số điện thoại';
  static const String enterNotes = 'Nhập ghi chú (tùy chọn)';
  static const String realTimeTracking = 'Theo dõi thời gian thực';
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

// ===== APP VALIDATORS =====
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

// ===== APP UTILS =====
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

// ===== API ENDPOINTS =====
class ApiEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String orders = '/orders';
  static const String tracking = '/tracking';
  static const String warehouse = '/warehouse';
}

// ===== USER ROLES =====
class UserRole {
  static const String customer = 'customer';
  static const String intakeStaff = 'intake_staff';
  static const String driver = 'driver';
  static const String admin = 'admin';
  
  static String getDisplayName(String role) {
    switch (role) {
      case customer:
        return 'Khách hàng';
      case intakeStaff:
        return 'Nhân viên nhận hàng';
      case driver:
        return 'Tài xế';
      case admin:
        return 'Quản trị viên';
      default:
        return role;
    }
  }
  
  static bool isCustomer(String? role) => role == customer;
  static bool isIntakeStaff(String? role) => role == intakeStaff;
  static bool isDriver(String? role) => role == driver;
  static bool isAdmin(String? role) => role == admin;
}

// ===== ORDER STATUS =====
class OrderStatus {
  // Common statuses
  static const String pending = 'pending';
  static const String cancelled = 'cancelled';
  
  // Warehouse statuses
  static const String receivedAtWarehouse = 'received_at_warehouse';
  static const String classified = 'classified';
  static const String readyForPickup = 'ready_for_pickup';
  
  // Delivery statuses
  static const String assignedToDriver = 'assigned_to_driver';
  static const String inTransit = 'in_transit';
  static const String delivered = 'delivered';
  static const String failedDelivery = 'failed_delivery';
  static const String returning = 'returning';
  static const String returned = 'returned';
  
  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Chờ xử lý';
      case receivedAtWarehouse:
        return 'Đã nhận tại kho';
      case classified:
        return 'Đã phân loại';
      case readyForPickup:
        return 'Sẵn sàng giao';
      case assignedToDriver:
        return 'Đã phân tài xế';
      case inTransit:
        return 'Đang giao';
      case delivered:
        return 'Đã giao';
      case cancelled:
        return 'Đã hủy';
      case failedDelivery:
        return 'Giao thất bại';
      case returning:
        return 'Đang hoàn trả';
      case returned:
        return 'Đã hoàn trả';
      default:
        return status;
    }
  }
  
  // Alias for backward compatibility
  static String getStatusName(String status) => getDisplayName(status);
  
  static Color getStatusColor(String status) {
    switch (status) {
      case pending:
        return AppColors.warning;
      case receivedAtWarehouse:
      case classified:
        return AppColors.info;
      case readyForPickup:
        return Colors.purple;
      case assignedToDriver:
      case inTransit:
        return AppColors.primary;
      case delivered:
        return AppColors.success;
      case cancelled:
      case failedDelivery:
        return AppColors.error;
      case returning:
      case returned:
        return AppColors.greyDark;
      default:
        return AppColors.grey;
    }
  }
}

// ===== TEXT STYLES =====
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}

// ===== SPACING =====
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ===== RADIUS =====
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 999.0;
}

// ===== PACKAGE SIZE =====
class PackageSize {
  static const String small = 'small';
  static const String medium = 'medium';
  static const String large = 'large';
  static const String extraLarge = 'extra_large';
  
  static String getDisplayName(String size) {
    switch (size) {
      case small:
        return 'Nhỏ (< 5kg)';
      case medium:
        return 'Trung bình (5-15kg)';
      case large:
        return 'Lớn (15-30kg)';
      case extraLarge:
        return 'Cực lớn (> 30kg)';
      default:
        return size;
    }
  }
  
  static List<String> getAllSizes() {
    return [small, medium, large, extraLarge];
  }
}

// ===== PACKAGE TYPE =====
class PackageType {
  static const String document = 'document';
  static const String parcel = 'parcel';
  static const String food = 'food';
  static const String fragile = 'fragile';
  static const String liquid = 'liquid';
  static const String electronics = 'electronics';
  static const String clothing = 'clothing';
  static const String other = 'other';
  
  static String getDisplayName(String type) {
    switch (type) {
      case document:
        return 'Tài liệu';
      case parcel:
        return 'Hàng hóa';
      case food:
        return 'Thực phẩm';
      case fragile:
        return 'Hàng dễ vỡ';
      case liquid:
        return 'Chất lỏng';
      case electronics:
        return 'Điện tử';
      case clothing:
        return 'Quần áo';
      case other:
        return 'Khác';
      default:
        return type;
    }
  }
  
  static IconData getIcon(String type) {
    switch (type) {
      case document:
        return Icons.description;
      case parcel:
        return Icons.inventory_2;
      case food:
        return Icons.restaurant;
      case fragile:
        return Icons.warning;
      case liquid:
        return Icons.water_drop;
      case electronics:
        return Icons.devices;
      case clothing:
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }
  
  static List<String> getAllTypes() {
    return [document, parcel, food, fragile, liquid, electronics, clothing, other];
  }
}

// ===== VALIDATORS =====
class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
  
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cân nặng không được để trống';
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0) {
      return 'Cân nặng phải lớn hơn 0';
    }
    return null;
  }
  
  static String? validateOrderCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mã đơn hàng không được để trống';
    }
    if (value.length < 6) {
      return 'Mã đơn hàng không hợp lệ';
    }
    return null;
  }
}

// ===== ZONE INFO =====
class ZoneInfo {
  static String getDisplayName(String zone) {
    switch (zone) {
      case 'zone_1':
        return 'Khu vực 1 (< 5km)';
      case 'zone_2':
        return 'Khu vực 2 (5-10km)';
      case 'zone_3':
        return 'Khu vực 3 (10-20km)';
      case 'zone_4':
        return 'Khu vực 4 (> 20km)';
      default:
        return zone;
    }
  }
  
  static Color getColor(String zone) {
    switch (zone) {
      case 'zone_1':
        return AppColors.success;
      case 'zone_2':
        return AppColors.info;
      case 'zone_3':
        return AppColors.warning;
      case 'zone_4':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }
  
  static List<String> getAllZones() {
    return ['zone_1', 'zone_2', 'zone_3', 'zone_4'];
  }
}

// ===== VEHICLE INFO =====
class VehicleInfo {
  static String getDisplayName(String vehicle) {
    switch (vehicle) {
      case 'bike':
        return 'Xe máy';
      case 'car':
        return 'Ô tô';
      case 'van':
        return 'Xe tải nhỏ';
      case 'truck':
        return 'Xe tải lớn';
      default:
        return vehicle;
    }
  }
  
  static IconData getIcon(String vehicle) {
    switch (vehicle) {
      case 'bike':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      case 'van':
        return Icons.local_shipping;
      case 'truck':
        return Icons.fire_truck;
      default:
        return Icons.local_shipping;
    }
  }
  
  static String getDescription(String vehicle) {
    switch (vehicle) {
      case 'bike':
        return 'Phù hợp gói hàng nhỏ, giao nhanh trong nội thành';
      case 'car':
        return 'Phù hợp gói hàng trung bình, an toàn hơn xe máy';
      case 'van':
        return 'Phù hợp gói hàng lớn, chở được nhiều đơn cùng lúc';
      case 'truck':
        return 'Phù hợp gói hàng cực lớn, hàng cồng kềnh';
      default:
        return '';
    }
  }
  
  static List<String> getAllVehicles() {
    return ['bike', 'car', 'van', 'truck'];
  }
}
