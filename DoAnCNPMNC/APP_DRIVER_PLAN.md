# 🚗 APP_DRIVER - Kế hoạch chi tiết

## 📋 TỔNG QUAN

App dành cho **tài xế giao hàng** (Driver/Shipper) để:
- Nhận đơn hàng từ hệ thống
- Cập nhật trạng thái giao hàng
- Điều hướng đến địa chỉ
- Quản lý thu nhập
- Theo dõi lịch sử giao hàng

---

## 🎯 CHỨC NĂNG CHÍNH

### 1️⃣ **Authentication & Profile**
- [x] Đăng ký tài khoản driver
  - Email, password
  - Full name, phone
  - Driver license (CMND/CCCD)
  - Vehicle type (xe máy, van 500kg, 750kg, 1000kg)
  - Vehicle plate number
  - Upload ảnh CMND, bằng lái, xe
- [x] Đăng nhập
- [x] Profile management
  - Xem thông tin cá nhân
  - Cập nhật avatar
  - Xem rating
  - Thống kê tổng đơn giao
- [x] Chế độ làm việc
  - Toggle ON/OFF (sẵn sàng nhận đơn)
  - Hiển thị trạng thái online/offline

---

### 2️⃣ **Dashboard & Order Management**

#### **Home Screen - Dashboard**
- Thống kê hôm nay:
  - Số đơn đã giao
  - Thu nhập hôm nay
  - Rating trung bình
  - Thời gian online
- Trạng thái hiện tại:
  - Đang rảnh / Đang giao hàng
  - Toggle online/offline
- Quick actions:
  - Xem đơn hàng mới
  - Đơn đang giao
  - Lịch sử
  - Thu nhập

#### **Nhận đơn hàng mới**
- Danh sách đơn hàng available
  - Hiển thị: Mã đơn, địa chỉ lấy/giao, khoảng cách, giá
  - Filter theo khoảng cách
  - Sort theo giá cao nhất
- Chi tiết đơn hàng:
  - Thông tin người gửi (tên, SĐT)
  - Địa chỉ lấy hàng + map
  - Thông tin người nhận (SĐT)
  - Địa chỉ giao hàng + map
  - Danh sách kiện hàng
  - Phí giao hàng
  - Khoảng cách ước tính
- Actions:
  - **Nhận đơn** (Accept)
  - **Từ chối** (Reject)

#### **Đơn đang giao**
- Xem đơn hàng đang thực hiện
- Trạng thái:
  1. **Đã nhận đơn** → Đang đến lấy hàng
  2. **Đã lấy hàng** → Đang giao hàng
  3. **Đã giao hàng** → Hoàn thành
- Actions cho từng trạng thái:
  - Cập nhật trạng thái
  - Gọi điện cho người gửi/nhận
  - Điều hướng (Google Maps/OpenStreetMap)
  - Chụp ảnh xác nhận (proof of delivery)
  - Ghi chú

---

### 3️⃣ **Delivery Flow - Quy trình giao hàng**

```
PENDING (Đơn mới)
    ↓
[Driver Accept] → ACCEPTED (Đã nhận đơn)
    ↓
[Đang đến lấy hàng] → EN_ROUTE_TO_PICKUP
    ↓
[Đã lấy hàng] → PICKED_UP (Chụp ảnh kiện hàng)
    ↓
[Đang giao hàng] → EN_ROUTE_TO_DELIVERY
    ↓
[Giao thành công] → DELIVERED (Chụp ảnh xác nhận, chữ ký)
    ↓
[Hoàn thành] → COMPLETED
```

**Các actions cần implement:**
- `acceptOrder(orderId)` - Nhận đơn
- `startPickup(orderId)` - Bắt đầu đến lấy hàng
- `confirmPickup(orderId, photo)` - Xác nhận đã lấy hàng
- `startDelivery(orderId)` - Bắt đầu giao hàng
- `confirmDelivery(orderId, photo, signature?)` - Xác nhận giao thành công
- `reportIssue(orderId, issue)` - Báo cáo vấn đề

---

### 4️⃣ **Map & Navigation**

#### **Real-time Location Tracking**
- Cập nhật vị trí driver real-time (Socket.IO)
- Gửi location mỗi 10-15 giây khi đang giao
- User có thể xem vị trí driver trên map

#### **Navigation**
- Hiển thị map với:
  - Vị trí hiện tại của driver (màu xanh)
  - Điểm lấy hàng (marker cam)
  - Điểm giao hàng (marker đỏ)
  - Route giữa các điểm
- Open in Google Maps / OpenStreetMap
- Ước tính thời gian đến

---

### 5️⃣ **Earnings & History**

#### **Thu nhập**
- Tổng thu nhập:
  - Hôm nay
  - Tuần này
  - Tháng này
  - Tổng cộng
- Chi tiết:
  - Danh sách đơn đã giao
  - Phí giao từng đơn
  - Hoa hồng (nếu có)
- Thống kê:
  - Biểu đồ thu nhập theo ngày/tuần/tháng
  - Số đơn giao trung bình/ngày

#### **Lịch sử giao hàng**
- Danh sách tất cả đơn đã giao
- Filter:
  - Theo ngày
  - Theo trạng thái
  - Theo thu nhập
- Chi tiết từng đơn

---

### 6️⃣ **Notifications**

- Đơn hàng mới phù hợp (gần vị trí hiện tại)
- Nhắc nhở cập nhật trạng thái
- Thông báo từ admin
- Rating từ khách hàng

---

### 7️⃣ **Settings**

- Thông tin cá nhân
- Thông tin xe
- Ngôn ngữ
- Thông báo
- Đăng xuất

---

## 🗂️ PROJECT STRUCTURE

```
app_driver/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── driver.dart
│   │   ├── order.dart
│   │   ├── earning.dart
│   │   └── delivery_status.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── order_provider.dart
│   │   ├── location_provider.dart
│   │   ├── earning_provider.dart
│   │   └── socket_provider.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── verification_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart (Dashboard)
│   │   │   └── online_toggle.dart
│   │   ├── orders/
│   │   │   ├── available_orders_screen.dart
│   │   │   ├── active_orders_screen.dart
│   │   │   ├── order_details_screen.dart
│   │   │   ├── delivery_flow_screen.dart
│   │   │   └── history_screen.dart
│   │   ├── earnings/
│   │   │   ├── earnings_screen.dart
│   │   │   └── earnings_details_screen.dart
│   │   ├── map/
│   │   │   ├── map_screen.dart
│   │   │   └── navigation_screen.dart
│   │   └── profile/
│   │       ├── profile_screen.dart
│   │       ├── edit_profile_screen.dart
│   │       └── settings_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── location_service.dart
│   │   ├── socket_service.dart
│   │   └── notification_service.dart
│   ├── utils/
│   │   ├── constants.dart
│   │   └── helpers.dart
│   └── widgets/
│       ├── order_card.dart
│       ├── stat_card.dart
│       ├── status_stepper.dart
│       └── map_widget.dart
├── pubspec.yaml
└── README.md
```

---

## 🎨 UI/UX DESIGN

### **Color Scheme (Lalamove Style)**
```dart
Primary: #F26522 (Orange)
Secondary: #2C3E50 (Dark Blue)
Success: #27AE60 (Green)
Danger: #E74C3C (Red)
Warning: #F39C12 (Yellow)
Info: #3498DB (Blue)

// Status colors
Idle: #95A5A6 (Gray)
Online: #27AE60 (Green)
Busy: #F39C12 (Orange)
Offline: #7F8C8D (Dark Gray)
```

### **Icons**
- Dashboard: `Icons.dashboard`
- Orders: `Icons.receipt_long`
- Earnings: `Icons.account_balance_wallet`
- Map: `Icons.map`
- Profile: `Icons.person`
- Online/Offline: `Icons.toggle_on` / `Icons.toggle_off`
- Accept: `Icons.check_circle`
- Reject: `Icons.cancel`
- Navigation: `Icons.navigation`
- Call: `Icons.phone`

---

## 📱 SCREENS PRIORITY

### **Phase 1: Core (MVP)** 🔥
1. Splash Screen
2. Login/Register
3. Home Dashboard
4. Available Orders List
5. Order Details
6. Accept/Reject Order
7. Active Order (đơn đang giao)
8. Update Status Flow
9. Profile

### **Phase 2: Enhanced**
1. Map Integration
2. Real-time Location
3. Navigation
4. Earnings Screen
5. History Screen
6. Notifications

### **Phase 3: Advanced**
1. Photo Upload (POD)
2. Rating System
3. Analytics/Charts
4. Multi-language
5. Offline Mode

---

## 🔌 API ENDPOINTS CẦN TẠO/SỬA

### **Backend cần thêm:**

```javascript
// Driver routes
POST   /api/auth/driver/register      // Đăng ký driver
POST   /api/auth/driver/login         // Login driver
GET    /api/driver/profile            // Xem profile
PUT    /api/driver/profile            // Cập nhật profile
PUT    /api/driver/status             // Toggle online/offline
POST   /api/driver/location           // Cập nhật vị trí

// Order management
GET    /api/orders/available          // Lấy đơn hàng có sẵn
POST   /api/orders/:id/accept         // Nhận đơn
POST   /api/orders/:id/reject         // Từ chối đơn
GET    /api/orders/active             // Đơn đang giao
PUT    /api/orders/:id/status         // Cập nhật trạng thái
POST   /api/orders/:id/pickup         // Xác nhận lấy hàng
POST   /api/orders/:id/deliver        // Xác nhận giao hàng
POST   /api/orders/:id/issue          // Báo cáo vấn đề

// Earnings
GET    /api/driver/earnings           // Thống kê thu nhập
GET    /api/driver/earnings/history   // Lịch sử thu nhập

// Real-time
Socket: driver:location-update        // Cập nhật vị trí
Socket: driver:order-assigned         // Nhận đơn mới
Socket: order:status-changed          // Thay đổi trạng thái
```

---

## 📊 DATABASE CHANGES

### **Thêm vào bảng `users`:**
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS driver_license VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_plate VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_lat DECIMAL(10, 8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_lng DECIMAL(11, 8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS rating DECIMAL(3, 2) DEFAULT 5.0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_deliveries INTEGER DEFAULT 0;
```

### **Bảng mới: `driver_earnings`**
```sql
CREATE TABLE driver_earnings (
    id SERIAL PRIMARY KEY,
    driver_id INTEGER REFERENCES users(id),
    order_id INTEGER REFERENCES orders(id),
    amount DECIMAL(10, 2) NOT NULL,
    commission DECIMAL(10, 2) DEFAULT 0,
    net_earning DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **Bảng mới: `driver_locations`**
```sql
CREATE TABLE driver_locations (
    id SERIAL PRIMARY KEY,
    driver_id INTEGER REFERENCES users(id),
    order_id INTEGER REFERENCES orders(id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🧪 TESTING SCENARIOS

1. **Driver register & login**
2. **Toggle online → Nhận thông báo đơn mới**
3. **Xem danh sách đơn available**
4. **Accept đơn → Chuyển sang Active**
5. **Cập nhật status flow: Accepted → Picking up → Picked up → Delivering → Delivered**
6. **Real-time location tracking**
7. **Hoàn thành đơn → Thu nhập tăng**
8. **Xem lịch sử & earnings**

---

## 📦 DEPENDENCIES (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State management
  provider: ^6.1.1
  
  # HTTP & WebSocket
  http: ^1.1.0
  socket_io_client: ^2.0.3+1
  
  # Local storage
  shared_preferences: ^2.2.2
  
  # Location
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Maps
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  # or google_maps_flutter: ^2.5.0
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  
  # Utils
  intl: ^0.18.1
  fluttertoast: ^8.2.4
  
  # Image
  image_picker: ^1.0.7
  
  # Charts (for earnings)
  fl_chart: ^0.66.0
  
  # Permissions
  permission_handler: ^11.2.0
```

---

## ⚡ QUICK START STEPS

1. **Tạo Flutter project:**
   ```bash
   cd DoAnCNPMNC
   flutter create app_driver
   ```

2. **Copy structure từ app_user**
3. **Thay đổi UI/UX cho driver**
4. **Implement core features (Phase 1)**
5. **Test với backend**
6. **Add map & real-time (Phase 2)**

---

## 🎯 SUCCESS METRICS

- [ ] Driver có thể đăng ký & đăng nhập
- [ ] Driver toggle online/offline
- [ ] Nhận được danh sách đơn hàng mới
- [ ] Accept/reject đơn hàng
- [ ] Cập nhật trạng thái giao hàng đầy đủ
- [ ] Real-time location tracking hoạt động
- [ ] Xem thu nhập chính xác
- [ ] UI/UX mượt mà, không lag
- [ ] Integration với app_user hoàn chỉnh

---

## 📝 NOTES

- **Priority cao nhất:** Delivery flow (accept → pickup → deliver)
- **Real-time tracking:** Quan trọng cho UX
- **Offline support:** Driver có thể mất mạng, cần cache
- **Battery optimization:** Location tracking tốn pin, cần optimize
- **Security:** Xác thực driver (CMND, bằng lái) trước khi cho active

---

## 🚀 NEXT STEPS

1. ✅ Tạo project structure
2. ⏳ Setup dependencies
3. ⏳ Implement Authentication
4. ⏳ Build Dashboard
5. ⏳ Order management
6. ⏳ Delivery flow
7. ⏳ Map integration
8. ⏳ Testing E2E

**Estimated time:** 2-3 weeks for full implementation
