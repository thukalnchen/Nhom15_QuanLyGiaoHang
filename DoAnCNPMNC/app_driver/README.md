# 🚗 Lalamove Driver App

Ứng dụng dành cho **tài xế giao hàng** trong hệ thống Lalamove Express.

## 📱 Tính năng

### ✅ Đã implement (Skeleton)
- [x] Project structure
- [x] Constants & utilities
- [x] Splash screen
- [x] Authentication providers
- [x] Order provider
- [x] Location provider
- [x] Theme Lalamove (Orange #F26522)

### ⏳ Cần implement
- [ ] Login/Register screens
- [ ] Home Dashboard
- [ ] Available Orders List
- [ ] Order Details
- [ ] Accept/Reject Order
- [ ] Active Orders
- [ ] Delivery Flow (Pickup → Delivery → Complete)
- [ ] Map Integration
- [ ] Real-time Location Tracking
- [ ] Earnings Screen
- [ ] Profile & Settings

## 🗂️ Cấu trúc thư mục

```
lib/
├── main.dart
├── models/              (TODO)
├── providers/           ✅
│   ├── auth_provider.dart
│   ├── order_provider.dart
│   └── location_provider.dart
├── screens/
│   ├── splash/          ✅
│   ├── auth/            (TODO)
│   ├── home/            (TODO)
│   ├── orders/          (TODO)
│   ├── earnings/        (TODO)
│   ├── map/             (TODO)
│   └── profile/         (TODO)
├── services/            (TODO)
├── utils/               ✅
│   └── constants.dart
└── widgets/             (TODO)
```

## 🚀 Cài đặt

### 1. Install dependencies
```bash
cd app_driver
flutter pub get
```

### 2. Cấu hình API URL
Mở `lib/utils/constants.dart` và cập nhật:
```dart
static const String apiBaseUrl = 'http://YOUR_IP:3000/api';
```

### 3. Chạy app
```bash
flutter run
```

## 📋 Next Steps

### Phase 1: Authentication (Priority 1) 🔥
1. Tạo `lib/screens/auth/login_screen.dart`
2. Tạo `lib/screens/auth/register_screen.dart`
3. Form validation
4. Connect với AuthProvider

### Phase 2: Dashboard (Priority 2) 🔥
1. Tạo `lib/screens/home/home_screen.dart`
2. Statistics cards (earnings, deliveries, rating)
3. Online/Offline toggle
4. Quick actions

### Phase 3: Orders (Priority 3) 🔥
1. Available orders list
2. Order details screen
3. Accept/Reject functionality
4. Active orders screen
5. Delivery flow UI

### Phase 4: Advanced Features
1. Map integration (flutter_map)
2. Real-time location tracking
3. Socket.IO for notifications
4. Earnings analytics
5. Photo upload (POD)

## 🔌 Backend Requirements

Backend cần implement các endpoints sau:

```
POST   /api/auth/driver/register
POST   /api/auth/driver/login
GET    /api/driver/profile
PUT    /api/driver/status
GET    /api/orders/available
GET    /api/orders/active
POST   /api/orders/:id/accept
PUT    /api/orders/:id/status
GET    /api/driver/earnings
```

## 🎨 Design Guidelines

- **Colors**: Orange (#F26522) primary
- **Icons**: Material Icons (local_shipping, delivery_dining)
- **Typography**: Bold headers, clean body text
- **Spacing**: 16px standard, 24px sections

## 📝 Notes

- Backend API đang chạy tại `http://localhost:3000`
- Cần permission: Location, Camera, Storage
- Test với PostgreSQL database
- Real-time updates qua Socket.IO

## 🤝 Liên quan

- **Backend**: `../backend`
- **User App**: `../app_user`
- **Web Admin**: `../web_admin`

## 📚 Documentation

Chi tiết kế hoạch: `../APP_DRIVER_PLAN.md`

