# APP INTAKE - ỨNG DỤNG NHÂN VIÊN NHẬN HÀNG

## 🎯 TỔNG QUAN

**app_intake** là ứng dụng di động dành cho nhân viên kho (Intake Staff) trong hệ thống quản lý giao hàng Lalamove. Đây là **ứng dụng quan trọng nhất** trong hệ thống vì nó là **cầu nối** giữa khách hàng (app_user) và tài xế (app_driver).

### Vai trò trong hệ thống
```
Customer (app_user) 
    ↓ Tạo đơn hàng
INTAKE STAFF (app_intake) ← BẠN ĐANG Ở ĐÂY
    ↓ Nhận → Phân loại → Phân tài xế
Driver (app_driver)
    ↓ Giao hàng
Delivered ✓
```

## 📋 CHỨC NĂNG CHÍNH (Product Backlog Stories 8-12)

### ✅ Story #8: Quét và nhập thông tin gói hàng
- **Mô tả**: Nhân viên kho quét mã QR đơn hàng và nhập thông tin chi tiết gói hàng
- **Screens**: `scan_screen.dart`, `order_intake_screen.dart`
- **Features**:
  - Quét mã QR/Barcode đơn hàng
  - Nhập cân nặng (weight)
  - Chọn kích thước gói (small/medium/large/extra_large)
  - Chọn loại hàng (document/parcel/food/fragile/liquid/electronics/clothing/other)
  - Chụp ảnh gói hàng (tối đa 4 ảnh)
  - Ghi chú đặc biệt
  - Xác nhận nhận hàng → Chuyển status: `pending` → `received_at_warehouse`

### ✅ Story #9: Phân loại gói hàng
- **Mô tả**: Phân loại gói hàng theo khu vực và đề xuất loại xe phù hợp
- **Screens**: `classification_screen.dart`, `warehouse_screen.dart`
- **Features**:
  - Tính toán khoảng cách giao hàng (từ pickup → delivery)
  - Tự động phân khu vực (zone_1/zone_2/zone_3/zone_4)
  - Đề xuất loại xe dựa theo:
    - Kích thước gói: small → bike, medium → car, large → van, extra_large → truck
    - Khu vực giao hàng
  - Cập nhật status: `received_at_warehouse` → `classified`

### ✅ Story #10: [Placeholder - Cần xem Product Backlog]
- Chờ thông tin từ Product Backlog

### ✅ Story #11: Tạo phiếu giao hàng/biên nhận
- **Mô tả**: In/Xuất biên nhận giao hàng cho tài xế
- **Screens**: `receipt_screen.dart`
- **Features**:
  - Tạo PDF biên nhận
  - In phiếu giao hàng (printing package)
  - Thông tin biên nhận:
    - Mã đơn hàng
    - Thông tin người gửi/nhận
    - Địa chỉ pickup/delivery
    - Kích thước, cân nặng gói hàng
    - Loại xe đề xuất
    - Phí giao hàng
    - COD (nếu có)
    - Chữ ký nhân viên kho

### ✅ Story #12: Xác nhận thu COD từ người gửi
- **Mô tả**: Thu tiền COD từ người gửi (nếu người gửi trả phí)
- **Screens**: `cod_collection_screen.dart`, `warehouse_screen.dart`
- **Features**:
  - Kiểm tra đơn hàng có COD (`is_cod = true`)
  - Xác định ai trả: `sender_pays` (người gửi) hoặc `receiver_pays` (người nhận)
  - Nếu `sender_pays`:
    - Thu tiền từ người gửi
    - Xác nhận đã thu: `cod_collected_at_warehouse = true`
    - Lưu thời gian thu: `cod_collected_at`
  - In biên nhận thu tiền
  - **LÚU Ý**: Nếu `receiver_pays`, tài xế sẽ thu khi giao hàng (Story #19 trong app_driver)

### 🔄 Story #21 (Integration): Phân tài xế
- **Mô tả**: Phân công tài xế cho đơn hàng (từ role Manager nhưng có thể được thực hiện bởi Intake Staff)
- **Screens**: `assignment_screen.dart`, `warehouse_screen.dart`
- **Features**:
  - Danh sách tài xế available (lọc theo `vehicle_type`)
  - Phân tài xế thủ công hoặc tự động
  - Cập nhật status: `classified` → `ready_for_pickup` → `assigned_to_driver`

## 🏗️ CẤU TRÚC DỰ ÁN

```
app_intake/
├── lib/
│   ├── main.dart                          ✅ DONE - Entry point với MultiProvider
│   ├── models/                            ✅ DONE
│   │   ├── user_model.dart               ✅ User model (intake_staff)
│   │   └── order_model.dart              ✅ Order model (đầy đủ fields)
│   ├── providers/                         ✅ DONE
│   │   ├── auth_provider.dart            ✅ Authentication, login/logout
│   │   └── warehouse_provider.dart       ✅ Warehouse operations (receive/classify/assign/COD)
│   ├── screens/                           🔄 IN PROGRESS
│   │   ├── splash/
│   │   │   └── splash_screen.dart        ✅ DONE - Splash với auto navigation
│   │   ├── auth/
│   │   │   └── login_screen.dart         ✅ DONE - Login cho intake staff
│   │   ├── home/
│   │   │   └── home_screen.dart          ✅ DONE - Dashboard với bottom navigation
│   │   ├── scan/                          ⏳ TODO
│   │   │   ├── scan_screen.dart          ⏳ QR Scanner (Story #8)
│   │   │   └── order_intake_screen.dart  ⏳ Nhập thông tin gói hàng (Story #8)
│   │   ├── orders/                        ⏳ TODO
│   │   │   ├── orders_screen.dart        ⏳ Danh sách đơn hàng
│   │   │   └── order_detail_screen.dart  ⏳ Chi tiết đơn hàng
│   │   ├── warehouse/                     ⏳ TODO
│   │   │   ├── warehouse_screen.dart     ⏳ Quản lý kho (Story #9, #12)
│   │   │   ├── classification_screen.dart ⏳ Phân loại gói hàng (Story #9)
│   │   │   ├── assignment_screen.dart    ⏳ Phân tài xế (Story #21)
│   │   │   ├── receipt_screen.dart       ⏳ Tạo biên nhận (Story #11)
│   │   │   └── cod_collection_screen.dart ⏳ Thu COD (Story #12)
│   │   └── profile/
│   │       └── profile_screen.dart       ✅ DONE - Thông tin cá nhân, đổi mật khẩu
│   ├── services/                          ✅ DONE
│   │   └── api_service.dart              ✅ All API endpoints (auth + warehouse)
│   ├── utils/                             ✅ DONE
│   │   └── constants.dart                ✅ Colors, statuses, validators, package types
│   └── widgets/                           ⏳ TODO
│       ├── order_card.dart               ⏳ Card hiển thị đơn hàng
│       ├── status_badge.dart             ⏳ Badge hiển thị trạng thái
│       ├── package_info_card.dart        ⏳ Thông tin gói hàng
│       └── image_picker_widget.dart      ⏳ Widget chọn/chụp ảnh
├── pubspec.yaml                           ✅ DONE - All dependencies installed
└── android/                               ✅ DONE - Android config
```

## 📦 DEPENDENCIES (122 packages installed)

### Core Dependencies
```yaml
# State management
provider: ^6.1.1                    ✅ State management

# HTTP & API
http: ^1.1.0                        ✅ REST API calls
socket_io_client: ^2.0.3+1          ✅ Real-time updates

# Local storage
shared_preferences: ^2.2.2          ✅ Save auth data

# QR Code & Scanning (Story #8)
qr_code_scanner: ^1.0.1             ✅ QR/Barcode scanner
mobile_scanner: ^3.5.5              ✅ Alternative scanner

# Camera & Images (Story #8)
image_picker: ^1.0.7                ✅ Chọn/chụp ảnh gói hàng
camera: ^0.10.5+9                   ✅ Camera access

# PDF & Printing (Story #11)
pdf: ^3.10.7                        ✅ Generate PDF receipts
printing: ^5.11.1                   ✅ Print receipts

# UI Components
flutter_svg: ^2.0.9                 ✅ SVG icons
cached_network_image: ^3.3.0        ✅ Cached images
flutter_spinkit: ^5.2.0             ✅ Loading indicators
fluttertoast: ^8.2.4                ✅ Toast messages

# Forms & Validation
form_field_validator: ^1.1.0        ✅ Form validators

# Date & Time
intl: ^0.18.1                       ✅ Date formatting

# Permissions
permission_handler: ^11.2.0         ✅ Camera, storage permissions
```

## 🔄 ORDER STATUS FLOW (Intake Staff)

```
pending                     ← Đơn hàng mới tạo từ customer
    ↓ Story #8: Scan + Nhập thông tin
received_at_warehouse       ← Đã nhận tại kho
    ↓ Story #9: Phân loại
classified                  ← Đã phân loại (zone + vehicle)
    ↓ Story #21: Phân tài xế
ready_for_pickup            ← Sẵn sàng cho tài xế lấy
    ↓ Story #21: Assign driver
assigned_to_driver          ← Đã phân tài xế → Chuyển sang app_driver
```

## 🎨 UI/UX DESIGN

### Theme (Lalamove Style)
- **Primary Color**: `#F26522` (Orange)
- **Secondary Color**: `#D45419` (Dark Orange)
- **Status Colors**:
  - Pending: `#FF9800` (Warning Orange)
  - Received: `#2196F3` (Info Blue)
  - Classified: `Purple`
  - Ready: `#4CAF50` (Success Green)
  - Error: `#F44336` (Red)

### Bottom Navigation (Home Screen)
1. 📊 **Tổng quan** (Dashboard) - Thống kê và quick actions
2. 📋 **Đơn hàng** (Orders) - Danh sách tất cả đơn hàng
3. 🏭 **Kho hàng** (Warehouse) - Quản lý kho, phân loại, phân tài xế
4. 👤 **Cá nhân** (Profile) - Thông tin cá nhân, đổi mật khẩu

### Floating Action Button
- 📷 **Quét mã** - Quick access to QR scanner (Story #8)

## 🔌 API ENDPOINTS

### Authentication
```
POST   /api/auth/login                     ✅ Login intake staff
PUT    /api/users/profile                  ✅ Update profile
PUT    /api/users/password                 ✅ Change password
```

### Warehouse Operations
```
GET    /api/warehouse/orders               ✅ Get all warehouse orders
GET    /api/warehouse/orders/search?code=  ✅ Search order by code
POST   /api/warehouse/receive              ✅ Receive order (Story #8)
POST   /api/warehouse/classify             ✅ Classify order (Story #9)
POST   /api/warehouse/assign-driver        ✅ Assign driver (Story #21)
GET    /api/warehouse/drivers/available    ✅ Get available drivers
POST   /api/warehouse/collect-cod          ✅ Collect COD (Story #12)
POST   /api/warehouse/generate-receipt     ✅ Generate receipt (Story #11)
GET    /api/warehouse/statistics           ✅ Get statistics
```

## 🚀 NEXT STEPS (TIẾP THEO)

### ⚠️ QUAN TRỌNG - Phải làm theo thứ tự:

#### 1. Backend API (PRIORITY 1 - CỰC KỲ QUAN TRỌNG)
Hiện tại backend **CHƯA CÓ** warehouse endpoints. Cần tạo:
```javascript
// backend/routes/warehouse.js       ← PHẢI TẠO
// backend/controllers/warehouseController.js  ← PHẢI TẠO
```

**Endpoints cần tạo**:
- ✅ POST /api/warehouse/receive
- ✅ POST /api/warehouse/classify
- ✅ POST /api/warehouse/assign-driver
- ✅ GET /api/warehouse/drivers/available
- ✅ POST /api/warehouse/collect-cod
- ✅ POST /api/warehouse/generate-receipt
- ✅ GET /api/warehouse/statistics

#### 2. Database Schema Updates (PRIORITY 1)
Bảng `orders` cần thêm cột:
```sql
ALTER TABLE orders ADD COLUMN warehouse_id VARCHAR(50);
ALTER TABLE orders ADD COLUMN warehouse_name VARCHAR(255);
ALTER TABLE orders ADD COLUMN intake_staff_id VARCHAR(50);
ALTER TABLE orders ADD COLUMN intake_staff_name VARCHAR(255);
ALTER TABLE orders ADD COLUMN received_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN classified_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN zone VARCHAR(20);
ALTER TABLE orders ADD COLUMN recommended_vehicle VARCHAR(20);
ALTER TABLE orders ADD COLUMN cod_payment_type VARCHAR(20);
ALTER TABLE orders ADD COLUMN cod_collected_at_warehouse BOOLEAN DEFAULT FALSE;
ALTER TABLE orders ADD COLUMN cod_collected_at TIMESTAMP;
```

#### 3. Screens Implementation (PRIORITY 2)
Thứ tự làm:

**A. Story #8 - Scan & Receive (Ưu tiên cao nhất)**
1. `scan_screen.dart` - Quét QR code
2. `order_intake_screen.dart` - Form nhập thông tin gói hàng

**B. Story #9 - Classification**
3. `classification_screen.dart` - Phân loại gói hàng
4. `warehouse_screen.dart` - Update để hiển thị classified orders

**C. Story #12 - COD Collection**
5. `cod_collection_screen.dart` - Thu COD từ người gửi

**D. Story #11 - Receipt Generation**
6. `receipt_screen.dart` - Tạo và in biên nhận

**E. Story #21 - Driver Assignment**
7. `assignment_screen.dart` - Phân tài xế

**F. Supporting Screens**
8. `order_detail_screen.dart` - Chi tiết đơn hàng
9. `orders_screen.dart` - Update danh sách đơn hàng

#### 4. Widgets Library (PRIORITY 3)
```dart
widgets/
  ├── order_card.dart              - Card hiển thị đơn hàng
  ├── status_badge.dart            - Badge trạng thái
  ├── package_info_card.dart       - Thông tin gói hàng
  ├── image_picker_widget.dart     - Chọn/chụp ảnh
  ├── driver_card.dart             - Card tài xế
  └── loading_overlay.dart         - Loading indicator
```

#### 5. Testing & Integration (PRIORITY 4)
- Test flow: pending → received → classified → ready → assigned
- Test COD collection: sender_pays vs receiver_pays
- Test QR scanner với real order codes
- Test PDF generation và printing
- Integration test với app_driver

## 📝 NOTES

### ⚠️ CRITICAL BLOCKERS
1. **Backend endpoints CHƯA CÓ** - Cần tạo ngay
2. **Database schema CHƯA UPDATE** - Cần alter tables
3. **Order code generation** - Cần format mã QR chuẩn

### 💡 RECOMMENDATIONS
1. Tạo backend endpoints trước khi làm screens
2. Test với mock data trong lúc chờ backend
3. Sử dụng `flutter run -d chrome` để test trên web browser (không cần device)
4. QR code format đề xuất: `ORDER-{timestamp}-{random}` (VD: `ORDER-20240115123045-A1B2C`)

### 🔗 INTEGRATION POINTS
- **app_user**: Nhận đơn hàng từ customer (status = pending)
- **app_driver**: Chuyển đơn hàng cho driver (status = assigned_to_driver)
- **web_admin**: Xem thống kê warehouse, quản lý intake staff
- **backend**: API endpoints cho tất cả operations

## ✅ SETUP COMPLETE

### What's Done (HOÀN THÀNH)
- ✅ Flutter project created
- ✅ 122 dependencies installed successfully
- ✅ Folder structure (12 directories)
- ✅ Models: User, Order
- ✅ Providers: AuthProvider, WarehouseProvider
- ✅ Services: ApiService (all endpoints defined)
- ✅ Utils: Constants, validators, colors, statuses
- ✅ Screens: Splash, Login, Home (Dashboard), Profile
- ✅ Theme: Lalamove colors (#F26522)
- ✅ Bottom Navigation: 4 tabs
- ✅ FAB: Quick scan button

### What's Next (TIẾP THEO)
1. **Backend API** ← BẮT ĐẦU TỪ ĐÂY
2. **Database Updates**
3. **Screens Implementation** (Stories 8, 9, 11, 12, 21)
4. **Testing & Integration**

---

**Status**: 🟡 FOUNDATION COMPLETE - READY FOR BACKEND + SCREENS IMPLEMENTATION

**Priority**: ⭐⭐⭐⭐⭐ HIGHEST - This app blocks the entire order flow

**Estimated Completion**: 40% (Foundation done, need backend + screens)
