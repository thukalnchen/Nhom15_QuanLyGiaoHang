# 🚀 Hướng dẫn cài đặt nhanh - Lalamove Express

> **App đã được chuyển đổi sang phong cách Lalamove! 🚚**

## 📋 Yêu cầu hệ thống
- **Node.js** (v16 trở lên)
- **PostgreSQL** (v12 trở lên)
- **Flutter SDK** (v3.0 trở lên)
- **Git**

---

## ⚡ Quick Start (3 Bước)

### Bước 1: Backend
```bash
cd backend
npm install
node server.js
```

### Bước 2: Flutter App
```bash
cd app_user
flutter pub get
flutter run
# Chọn [2]: Chrome
```

### Bước 3: Test
- App mở trong Chrome browser
- Login hoặc Register account
- Tạo đơn giao hàng đầu tiên!

**Done! 🎉**

---

## 🔧 Setup Chi tiết

### 1. Cài đặt PostgreSQL
- Tải và cài đặt PostgreSQL từ https://www.postgresql.org/download/
- Tạo database: `CREATE DATABASE food_delivery_db;` (hoặc `delivery_app`)
- Ghi nhớ username/password để cập nhật trong file `config.env`

### 2. Cấu hình Backend
Tạo/Chỉnh sửa file `backend/config.env`:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_delivery_db
DB_USER=postgres
DB_PASSWORD=your_password_here
JWT_SECRET=your-secret-key-change-this
PORT=3000
```

### 3. Cài đặt Backend Dependencies
```bash
cd backend
npm install
```

### 4. Chạy Backend
```bash
node server.js
```

**Chờ thấy:**
```
✅ Connected to PostgreSQL database
✅ Database tables created successfully
🚀 Server is running on http://localhost:3000
```

**Web Admin:**
- Mở file `web_admin/index.html` trong trình duyệt

**Mobile App:**
```bash
cd app_user
flutter run
```

## Kiểm tra hoạt động

1. **Backend API:** http://localhost:3000/api/health
2. **Web Admin:** Mở `web_admin/index.html`
3. **Mobile App:** Chạy trên emulator/device

## Troubleshooting

### Lỗi kết nối database
- Kiểm tra PostgreSQL đang chạy
- Kiểm tra thông tin trong `.env`
- Đảm bảo database đã được tạo

### Lỗi Flutter
```bash
cd app_user
flutter clean
flutter pub get
flutter run
```

### Lỗi backend
```bash
cd backend
npm install
npm start
```

## Tính năng đã hoàn thành

✅ **Backend:**
- API đăng ký/đăng nhập với JWT
- CRUD đơn hàng
- Theo dõi vị trí realtime (Socket.IO)
- Database schema hoàn chỉnh

✅ **Mobile App:**
- Đăng ký/đăng nhập
- Tạo đơn hàng
- Xem danh sách đơn hàng
- Chi tiết đơn hàng
- Theo dõi giao hàng
- Quản lý hồ sơ

✅ **Web Admin:**
- Dashboard với thống kê
- Quản lý đơn hàng
- Theo dõi realtime
- Giao diện responsive

## API Testing

Sử dụng Postman hoặc curl để test API:

**Đăng ký:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456","full_name":"Test User"}'
```

**Đăng nhập:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'
```

## Liên hệ hỗ trợ

Nếu gặp vấn đề, vui lòng:
1. Kiểm tra README.md chi tiết
2. Chạy script setup_and_test để kiểm tra
3. Tạo issue trong repository
