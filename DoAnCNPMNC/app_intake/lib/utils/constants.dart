import 'package:flutter/material.dart';

// ===== APP CONFIG =====
class AppConfig {
  static const String appName = 'Lalamove Intake';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';
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
}

// ===== ORDER STATUS =====
class OrderStatus {
  // Warehouse-specific statuses
  static const String pending = 'pending'; // Chờ nhận hàng
  static const String receivedAtWarehouse = 'received_at_warehouse'; // Đã nhận tại kho
  static const String classified = 'classified'; // Đã phân loại
  static const String readyForPickup = 'ready_for_pickup'; // Sẵn sàng giao
  
  // Driver statuses (for reference)
  static const String assignedToDriver = 'assigned_to_driver';
  static const String inTransit = 'in_transit';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
  static const String failedDelivery = 'failed_delivery';
  static const String returning = 'returning';
  static const String returned = 'returned';
  
  // Status display names
  static String getStatusName(String status) {
    switch (status) {
      case pending:
        return 'Chờ nhận hàng';
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
  
  // Status colors
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
        return Colors.orange;
      default:
        return AppColors.grey;
    }
  }
}

// ===== PACKAGE CLASSIFICATION =====
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

// ===== VEHICLE TYPES =====
class VehicleType {
  static const String bike = 'bike';
  static const String car = 'car';
  static const String van = 'van';
  static const String truck = 'truck';
  
  static String getDisplayName(String type) {
    switch (type) {
      case bike:
        return 'Xe máy';
      case car:
        return 'Ô tô';
      case van:
        return 'Xe tải nhỏ';
      case truck:
        return 'Xe tải lớn';
      default:
        return type;
    }
  }
  
  static IconData getIcon(String type) {
    switch (type) {
      case bike:
        return Icons.two_wheeler;
      case car:
        return Icons.directions_car;
      case van:
        return Icons.local_shipping;
      case truck:
        return Icons.fire_truck;
      default:
        return Icons.local_shipping;
    }
  }
  
  // Recommend vehicle based on package size
  static String recommendVehicle(String packageSize) {
    switch (packageSize) {
      case PackageSize.small:
        return bike;
      case PackageSize.medium:
        return car;
      case PackageSize.large:
        return van;
      case PackageSize.extraLarge:
        return truck;
      default:
        return bike;
    }
  }
  
  static List<String> getAllVehicles() {
    return [bike, car, van, truck];
  }
}

// ===== COD PAYMENT =====
class CODPaymentType {
  static const String senderPays = 'sender_pays'; // Người gửi trả
  static const String receiverPays = 'receiver_pays'; // Người nhận trả
  
  static String getDisplayName(String type) {
    switch (type) {
      case senderPays:
        return 'Người gửi trả';
      case receiverPays:
        return 'Người nhận trả';
      default:
        return type;
    }
  }
}

// ===== DELIVERY ZONES =====
class DeliveryZone {
  static const String zone1 = 'zone_1'; // < 5km
  static const String zone2 = 'zone_2'; // 5-10km
  static const String zone3 = 'zone_3'; // 10-20km
  static const String zone4 = 'zone_4'; // > 20km
  
  static String getDisplayName(String zone) {
    switch (zone) {
      case zone1:
        return 'Khu vực 1 (< 5km)';
      case zone2:
        return 'Khu vực 2 (5-10km)';
      case zone3:
        return 'Khu vực 3 (10-20km)';
      case zone4:
        return 'Khu vực 4 (> 20km)';
      default:
        return zone;
    }
  }
  
  static String getZoneFromDistance(double distance) {
    if (distance < 5) return zone1;
    if (distance < 10) return zone2;
    if (distance < 20) return zone3;
    return zone4;
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

// ===== TEXT STYLES =====
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
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

// ===== BORDER RADIUS =====
class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double round = 999.0;
}

// ===== ZONE INFO (for classification screen) =====
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

// ===== VEHICLE INFO (for classification screen) =====
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
