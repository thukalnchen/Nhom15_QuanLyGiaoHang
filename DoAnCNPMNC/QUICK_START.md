# Hướng dẫn cài đặt nhanh - Food Delivery System

## Yêu cầu hệ thống
- Node.js (v16 trở lên)
- PostgreSQL (v12 trở lên)
- Flutter SDK (v3.0 trở lên) - chỉ cần cho mobile app
- Git

## Cài đặt nhanh

### 1. Clone repository
```bash
git clone <repository-url>
cd DoAnCNPMNC
```

### 2. Chạy script tự động
**Windows:**
```cmd
setup_and_test.bat
```

**Linux/Mac:**
```bash
chmod +x setup_and_test.sh
./setup_and_test.sh
```

### 3. Cài đặt PostgreSQL
- Tải và cài đặt PostgreSQL từ https://www.postgresql.org/download/
- Tạo database: `CREATE DATABASE food_delivery_db;`
- Ghi nhớ username/password để cập nhật trong file `.env`

### 4. Cập nhật cấu hình
Chỉnh sửa file `backend/.env`:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_delivery_db
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

### 5. Chạy hệ thống

**Backend:**
```bash
cd backend
npm start
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
