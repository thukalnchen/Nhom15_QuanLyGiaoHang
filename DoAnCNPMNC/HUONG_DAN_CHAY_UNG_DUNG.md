# 🚀 HƯỚNG DẪN CHẠY ỨNG DỤNG QUẢN LÝ GIAO HÀNG

## 📋 MỤC LỤC
1. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
2. [Cài đặt Backend](#cài-đặt-backend)
3. [Cài đặt App User (Flutter)](#cài-đặt-app-user-flutter)
4. [Khắc phục sự cố](#khắc-phục-sự-cố)

---

## 🖥️ YÊU CẦU HỆ THỐNG

### Backend
- **Node.js**: >= 14.x (khuyến nghị 18.x trở lên)
- **PostgreSQL**: >= 12.x
- **npm** hoặc **yarn**

### App User (Flutter)
- **Flutter SDK**: >= 3.9.2
- **Android Studio** (cho Android) hoặc **Xcode** (cho iOS)
- **VS Code** với extension Flutter (tùy chọn)

---

## 🔧 CÀI ĐẶT BACKEND

### Bước 1: Cài đặt PostgreSQL

1. **Tải và cài đặt PostgreSQL** từ https://www.postgresql.org/download/
2. **Khởi động PostgreSQL** và tạo database:

```sql
-- Mở psql hoặc pgAdmin
CREATE DATABASE food_delivery_db;
```

### Bước 2: Cấu hình Backend

1. **Mở terminal** và di chuyển vào thư mục backend:

```bash
cd DoAnCNPMNC/backend
```

2. **Cài đặt dependencies**:

```bash
npm install
```

3. **Cấu hình file `config.env`**:

Mở file `backend/config.env` và cập nhật thông tin database:

```env
# Environment Variables
NODE_ENV=development
PORT=3000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_delivery_db
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD  # ⚠️ Thay bằng mật khẩu PostgreSQL của bạn

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=24h

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:5500

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### Bước 3: Tạo bảng Database (nếu cần)

Chạy script để kiểm tra kết nối database:

```bash
node scripts/test-db-connection.js
```

### Bước 4: Chạy Backend Server

#### Chế độ Development (tự động restart khi có thay đổi):

```bash
npm run dev
```

#### Chế độ Production:

```bash
npm start
```

**✅ Backend sẽ chạy tại:** `http://localhost:3000`

**Kiểm tra:**
- Mở trình duyệt và truy cập: http://localhost:3000
- Bạn sẽ thấy thông báo server đang chạy

---

## 📱 CÀI ĐẶT APP USER (FLUTTER)

### Bước 1: Cài đặt Flutter SDK

1. **Tải Flutter** từ https://flutter.dev/docs/get-started/install
2. **Thêm Flutter vào PATH** (theo hướng dẫn trên trang chủ)
3. **Kiểm tra cài đặt**:

```bash
flutter doctor
```

Đảm bảo tất cả các mục quan trọng đều có dấu ✓

### Bước 2: Cấu hình App User

1. **Mở terminal** và di chuyển vào thư mục app_user:

```bash
cd DoAnCNPMNC/app_user
```

2. **Cài đặt dependencies**:

```bash
flutter pub get
```

### Bước 3: Cấu hình API URL

Mở file `lib/utils/constants.dart` và kiểm tra cấu hình:

```dart
class AppConstants {
  // Auto-detect platform
  static final String apiBaseUrl = kIsWeb 
      ? 'http://localhost:3000/api'      // Web browser
      : 'http://10.0.2.2:3000/api';       // Android Emulator
  
  static final String socketUrl = kIsWeb
      ? 'http://localhost:3000'           // Web browser
      : 'http://10.0.2.2:3000';           // Android Emulator
}
```

**📌 Lưu ý quan trọng:**
- **Android Emulator**: Sử dụng `10.0.2.2` (không phải `localhost`)
- **iOS Simulator**: Sử dụng `localhost`
- **Thiết bị thật**: Sử dụng IP máy tính của bạn (vd: `192.168.1.100`)

**Để lấy IP máy tính:**
- **Windows**: Mở CMD và gõ `ipconfig`, tìm IPv4 Address
- **Mac/Linux**: Mở Terminal và gõ `ifconfig` hoặc `ip addr`

### Bước 4: Chạy App User

#### Chạy trên Web:

```bash
flutter run -d chrome
```

#### Chạy trên Android Emulator:

1. **Khởi động Android Emulator** từ Android Studio
2. **Chạy app**:

```bash
flutter run
```

#### Chạy trên iOS Simulator (chỉ trên Mac):

```bash
flutter run -d iphone
```

#### Chạy trên thiết bị thật:

1. **Bật USB Debugging** trên điện thoại
2. **Kết nối USB** với máy tính
3. **Cập nhật IP** trong `constants.dart`:

```dart
static final String apiBaseUrl = 'http://192.168.1.100:3000/api'; // IP máy tính của bạn
static final String socketUrl = 'http://192.168.1.100:3000';
```

4. **Chạy app**:

```bash
flutter run
```

---

## 🔥 QUY TRÌNH CHẠY HOÀN CHỈNH

### 1️⃣ Khởi động PostgreSQL
Đảm bảo PostgreSQL đang chạy

### 2️⃣ Chạy Backend
```bash
cd DoAnCNPMNC/backend
npm run dev
```
✅ Đợi đến khi thấy: `Server is running on port 3000`

### 3️⃣ Chạy App User
Mở terminal mới:
```bash
cd DoAnCNPMNC/app_user
flutter run
```

### 4️⃣ Kiểm tra kết nối
- Mở app và thử đăng ký/đăng nhập
- Kiểm tra console của backend để xem request

---

## 🛠️ KHẮC PHỤC SỰ CỐ

### ❌ Backend không kết nối được Database

**Lỗi**: `ECONNREFUSED` hoặc `password authentication failed`

**Giải pháp:**
1. Kiểm tra PostgreSQL đang chạy
2. Kiểm tra thông tin trong `config.env` (đặc biệt là `DB_PASSWORD`)
3. Thử kết nối bằng psql:
   ```bash
   psql -U postgres -d food_delivery_db
   ```

### ❌ App không kết nối được Backend

**Lỗi**: `SocketException` hoặc `Connection refused`

**Giải pháp:**
1. **Kiểm tra Backend đang chạy** tại http://localhost:3000
2. **Trên Android Emulator**: Dùng `10.0.2.2` thay vì `localhost`
3. **Trên thiết bị thật**: 
   - Đảm bảo điện thoại và máy tính cùng mạng WiFi
   - Cập nhật IP máy tính trong `constants.dart`
   - Tắt firewall nếu cần

### ❌ Flutter dependencies lỗi

**Giải pháp:**
```bash
flutter clean
flutter pub get
```

### ❌ CORS Error

**Giải pháp:**
Backend đã cấu hình CORS cho tất cả localhost. Nếu vẫn lỗi, kiểm tra `config.env`:
```env
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://10.0.2.2:3000
```

### ❌ Port 3000 đã được sử dụng

**Giải pháp:**
Thay đổi PORT trong `config.env`:
```env
PORT=3001
```

Và cập nhật trong `app_user/lib/utils/constants.dart`:
```dart
static final String apiBaseUrl = kIsWeb 
    ? 'http://localhost:3001/api'
    : 'http://10.0.2.2:3001/api';
```

---

## 📞 THÔNG TIN LIÊN HỆ

Nếu gặp vấn đề, hãy kiểm tra:
1. Console của Backend (để xem log lỗi)
2. Console của Flutter (để xem log app)
3. Network tab trong Browser DevTools (nếu chạy web)

---

## 🎯 TÍNH NĂNG CHÍNH

### Backend API:
- ✅ Authentication (Register/Login)
- ✅ Order Management (Create/Read/Update/Delete)
- ✅ Real-time Tracking (Socket.IO)
- ✅ User Management

### App User:
- ✅ Đăng ký/Đăng nhập
- ✅ Tạo đơn hàng
- ✅ Theo dõi đơn hàng real-time
- ✅ Quản lý hồ sơ người dùng
- ✅ Tích hợp bản đồ (OpenStreetMap)

---

**🎉 Chúc bạn chạy ứng dụng thành công!**
