# 🚚 Lalamove App - Unified Application

## 📱 Tổng quan

App Flutter thống nhất cho **Lalamove Delivery System** với hỗ trợ nhiều roles:

- 👤 **Customer**: Đặt hàng, theo dõi đơn hàng
- 📦 **Intake Staff**: Nhận hàng, quét QR, phân loại
- 🚗 **Driver**: Nhận và giao hàng (coming soon)
- 👑 **Admin**: Quản trị hệ thống (coming soon)

## ✨ Tính năng chính

### 🔐 Authentication & Role Management
- ✅ Login/Register thống nhất
- ✅ Auto role detection từ backend
- ✅ Role-based navigation
- ✅ Secure token storage

### 👤 Customer Features
- ✅ Tạo đơn hàng giao hàng
- ✅ Xem danh sách đơn hàng
- ✅ Theo dõi trạng thái real-time
- ✅ Quản lý profile
- ✅ Tích hợp bản đồ
- ✅ Navigation với named routes

### 📦 Intake Staff Features
- ✅ Quét QR code nhận hàng
- ✅ Phân loại đơn hàng (small, medium, large)
- ✅ Chọn loại xe phù hợp
- ✅ Phân công tài xế
- ✅ Quản lý kho

## 🚀 Quick Start

```bash
# 1. Install dependencies
cd lalamove_app
flutter pub get

# 2. Run app
flutter run
```

## 🔑 Demo Accounts

**Customer**: `user@customer.com` / `password123`  
**Intake Staff**: `staff@intake.com` / `password123`


## � Quick Start

### Prerequisites
- Flutter SDK 3.9.2+
- Dart SDK 3.9.2+
- Node.js (cho backend)
- MongoDB

### 1. Clone & Setup
```bash
git clone <repository-url>
cd DoAnCNPMNC/lalamove_app
flutter pub get
```

### 2. Start Backend
```bash
cd ../backend
npm install
npm start
```

### 3. Run App
```bash
flutter run -d chrome
# hoặc
flutter run -d <device-id>
```

### 4. Run Tests
```powershell
# Windows
.\run_tests.ps1

# Linux/Mac
./run_tests.sh
```

## 🧪 Testing

Comprehensive test suite với 30+ tests covering:
- ✅ Authentication flows
- ✅ Customer order management
- ✅ Intake staff workflows
- ✅ Navigation & routing
- ✅ State management
- ✅ Error handling

**Xem chi tiết tại [TESTING_GUIDE.md](./TESTING_GUIDE.md)**

### Quick Test Commands
```bash
# Run all tests
flutter test

# Run integration tests
flutter test test/integration_test.dart

# Run with coverage
flutter test --coverage
```

## �📊 Architecture Flow

```
App Start → SplashScreen → Check Token
    ├─ Has Token → Detect Role
    │   ├─ customer → CustomerHomeScreen
    │   └─ intake_staff → IntakeHomeScreen
    └─ No Token → LoginScreen
```

### Named Routes
```dart
routes: {
  '/login', '/register',
  '/home', '/orders', '/create-order', '/tracking', '/profile',
  '/intake-home', '/intake-profile',
}
```

## 🔑 Test Credentials

| Role | Email | Password |
|------|-------|----------|
| Customer | user@customer.com | password123 |
| Intake Staff | staff@intake.com | password123 |

## 📁 Project Structure

```
lib/
├── main.dart                 # Entry point với routes
├── constants/               # App constants, colors, texts
├── models/                  # Data models (User, Order, etc.)
├── providers/               # State management (Provider)
├── screens/
│   ├── customer/           # Customer screens
│   │   ├── home/
│   │   ├── orders/
│   │   ├── create_order/
│   │   ├── tracking/
│   │   └── profile/
│   ├── intake/             # Intake staff screens
│   │   ├── home/
│   │   ├── orders/
│   │   └── profile/
│   └── common/             # Shared screens (Login, Splash)
├── services/               # API services
└── widgets/                # Reusable widgets

test/
├── integration_test.dart   # 30 comprehensive tests
├── providers/              # Provider tests
├── screens/                # Screen tests
└── services/               # Service tests
```

## 📝 Documentation

- � [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Hướng dẫn testing chi tiết
- 🚀 [QUICK_START.md](./QUICK_START.md) - Quick start guide

## ✅ Status

| Feature | Status |
|---------|--------|
| Authentication | ✅ Complete |
| Customer App | ✅ Complete |
| Intake Staff App | ✅ Complete |
| Navigation System | ✅ Complete |
| State Management | ✅ Complete |
| Testing Suite | ✅ Complete |
| Driver App | ⏳ Coming soon |
| Admin Panel | ⏳ Coming soon |

## 👥 Team

**Nhóm 15** - Quản lý giao hàng | CNPM NC

---

**Last Updated:** 2025-01-09  
**Version:** 1.0.0  
**Status:** ✅ Production Ready

