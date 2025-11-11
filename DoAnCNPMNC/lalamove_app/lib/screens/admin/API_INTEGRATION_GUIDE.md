# 🔌 Hướng Dẫn Kết Nối API - Stories #20-24

## ✅ Hoàn Tất

- ✅ **admin_api_service.dart** - Service layer cho tất cả 5 stories
- ✅ **5 Admin Screens** - Story #20-24 có chức năng cơ bản
- ✅ **Backend APIs** - 28+ endpoints hoàn tất

---

## 📁 File Được Tạo

```
lib/
├── services/
│   └── admin_api_service.dart    ← NEW (API Service)
└── screens/admin/
    ├── admin_management_screen.dart      (Dashboard)
    ├── story_20_orders_list.dart         (Orders Management)
    ├── story_21_driver_assignment.dart   (Driver Assignment)
    ├── story_22_route_management.dart    (Route Management)
    ├── story_23_pricing_policy.dart      (Pricing Policy)
    └── story_24_reporting.dart           (Reporting)
```

---

## 🚀 Cách Kết Nối API

### **Step 1: Import AdminApiService**

```dart
import 'services/admin_api_service.dart';
```

### **Step 2: Sử Dụng trong Screens**

#### **Story #20: Orders List**

```dart
class _OrdersListScreenState extends State<OrdersListScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    final token = 'your_token_here'; // Get from AuthProvider
    final orders = await AdminApiService.getAllOrders(token);
    
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  // Sử dụng _orders thay vì mock data
}
```

#### **Story #21: Driver Assignment**

```dart
Future<void> _loadDrivers() async {
  final token = 'your_token_here';
  final drivers = await AdminApiService.getAvailableDriversAdmin(token);
  
  setState(() => _drivers = drivers);
}

Future<void> _assignDriver(String orderId, String driverId) async {
  final token = 'your_token_here';
  final success = await AdminApiService.assignDriverToOrder(
    token,
    orderId,
    driverId,
  );
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gán tài xế thành công')),
    );
  }
}
```

#### **Story #22: Route Management**

```dart
Future<void> _loadZones() async {
  final token = 'your_token_here';
  final zones = await AdminApiService.getZones(token);
  
  setState(() => _zones = zones);
}

Future<void> _loadRoutes() async {
  final token = 'your_token_here';
  final routes = await AdminApiService.getRoutes(token);
  
  setState(() => _routes = routes);
}
```

#### **Story #23: Pricing Policy**

```dart
Future<void> _loadPricing() async {
  final token = 'your_token_here';
  
  final pricingTables = await AdminApiService.getPricingTables(token);
  final surcharges = await AdminApiService.getSurcharges(token);
  final discounts = await AdminApiService.getDiscounts(token);
  
  setState(() {
    _pricingTables = pricingTables;
    _surcharges = surcharges;
    _discounts = discounts;
  });
}
```

#### **Story #24: Reporting**

```dart
Future<void> _loadDashboard() async {
  final token = 'your_token_here';
  
  final dashboard = await AdminApiService.getDashboard(token);
  final revenue = await AdminApiService.getRevenueReport(token);
  final delivery = await AdminApiService.getDeliveryStats(token);
  final drivers = await AdminApiService.getDriverPerformance(token);
  final customers = await AdminApiService.getCustomerAnalytics(token);
  
  setState(() {
    _dashboardData = dashboard;
    _revenueData = revenue;
    _deliveryData = delivery;
    _driverData = drivers;
    _customerData = customers;
  });
}
```

---

## 🔑 Lấy Token

### Từ AuthProvider

```dart
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final token = authProvider.token; // Lấy token từ provider
        // Sử dụng token để gọi API
        return ...;
      },
    );
  }
}
```

---

## 📊 API Methods Available

### **Story #20: Orders Management**
```dart
AdminApiService.getAllOrders(token, page, limit, status)
AdminApiService.getOrderById(token, orderId)
AdminApiService.updateOrderStatus(token, orderId, status)
```

### **Story #21: Driver Assignment**
```dart
AdminApiService.getAvailableDriversAdmin(token)
AdminApiService.assignDriverToOrder(token, orderId, driverId)
AdminApiService.getDriverWorkload(token)
```

### **Story #22: Route Management**
```dart
AdminApiService.getZones(token)
AdminApiService.getRoutes(token)
```

### **Story #23: Pricing Policy**
```dart
AdminApiService.getPricingTables(token)
AdminApiService.getSurcharges(token)
AdminApiService.getDiscounts(token)
```

### **Story #24: Reporting**
```dart
AdminApiService.getRevenueReport(token, period)
AdminApiService.getDeliveryStats(token)
AdminApiService.getDriverPerformance(token)
AdminApiService.getCustomerAnalytics(token)
AdminApiService.getDashboard(token)
```

---

## ⚙️ Configuration

**Backend URL:**
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

Nếu backend chạy trên port khác, sửa trong `admin_api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:YOUR_PORT/api';
```

---

## 🧪 Test API Connection

### 1. Đảm bảo Backend Chạy
```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\backend"
npm start
# Output: 🚀 Server running on port 3000
```

### 2. Đảm bảo Flutter App Chạy
```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\lalamove_app"
flutter run -d chrome
```

### 3. Đăng Nhập Admin
- Email: `admin@lalamove.com`
- Password: `Admin@123`

### 4. Bấm vào từng Screen để Test
- Nếu data hiển thị → API kết nối thành công ✅
- Nếu không hiển thị → Check console log

---

## 🐛 Troubleshooting

### Lỗi: "Unable to connect to the remote server"
- ✅ Check backend đang chạy trên port 3000
- ✅ Check URL đúng
- ✅ Check firewall không block

### Lỗi: "401 Unauthorized"
- ✅ Check token hợp lệ
- ✅ Check header Authorization đúng format

### Lỗi: "Empty data từ API"
- ✅ Check backend endpoint có dữ liệu
- ✅ Check database có dữ liệu

---

## 📝 Tiếp Theo

1. **Update tất cả 5 screens** để gọi API thay vì mock data
2. **Thêm error handling** và loading states
3. **Thêm Provider** để state management
4. **Test thực tế** với dữ liệu từ database

---

**Trạng thái:** ✅ API Service Layer Hoàn Tất  
**Screens:** ✅ 5/5 Screens Created  
**Endpoints:** ✅ 28+ Backend Endpoints Ready  

---

**Bạn chỉ cần thay **mock data** bằng **API calls** trong từng screen!**

