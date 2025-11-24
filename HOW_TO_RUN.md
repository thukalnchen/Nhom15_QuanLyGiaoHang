# 🚀 Hướng Dẫn Chạy Project

## 📋 Yêu Cầu Trước

- **Node.js** v16+
- **PostgreSQL** 12+ (tại `E:\linh Tinh\PostGres\bin`)
- **Flutter** SDK (cho mobile)
- **Git** (optional)

---

## 🔧 Bước 1: Thiết Lập Database

### Windows PowerShell

```powershell
cd "E:\linh Tinh\PostGres\bin"

# Kết nối PostgreSQL
.\psql -U postgres

# Trong psql:
CREATE DATABASE food_delivery_db;
\q  # Thoát psql
```

### Hoặc Chạy Script Tự Động

```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\mockdata"

# Chạy script import data
.\import_mockdata.ps1
```

---

## 📦 Bước 2: Thiết Lập Backend

### 1. Cài Đặt Dependencies

```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\backend"

npm install
```

### 2. Kiểm Tra File Config

Đảm bảo tồn tại `config.env`:

```env
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/food_delivery_db
JWT_SECRET=your_secret_key
PORT=5000
NODE_ENV=development
```

### 3. Chạy Database Migration

```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\backend"

# Chạy migration cho Stories #20-24
psql -U postgres -d food_delivery_db -f scripts/migrate_stories_20_24.sql
```

### 4. Khởi Động Backend Server

```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\backend"

npm start
```

**Output mong đợi:**
```
Server running on port 5000
Database connected successfully
```

---

## 📱 Bước 3: Chạy Flutter App

### Lựa Chọn 1: Chạy trên Web (Dễ Nhất)

```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\lalamove_app"

flutter pub get

flutter run -d chrome
```

### Lựa Chọn 2: Chạy trên Android Emulator

```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\lalamove_app"

flutter pub get

flutter run
```

### Lựa Chọn 3: Chạy App Giao Hàng (Driver/Deliverer)

**App Giao Hàng (cho Tài xế và Người giao hàng):**
```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\app_giaohang"

flutter pub get

flutter run -d chrome
```

> **Lưu ý:** 
> - `lalamove_app` đã tích hợp chức năng User (Khách hàng) và Intake (Tiếp nhận)
> - `app_giaohang` thay thế cho app_driver và app_deliverer cũ

---

## 🌐 Bước 4: Kiểm Tra API

### Sử Dụng Postman

1. Mở Postman
2. Import collection từ file (nếu có)
3. Test các endpoints:

**Ví dụ - Orders Management (Story #20):**
```
GET http://localhost:5000/api/orders
Authorization: Bearer {token}
```

**Ví dụ - Pricing Policy (Story #23):**
```
GET http://localhost:5000/api/pricing/tables
Authorization: Bearer {token}
```

### Hoặc Sử Dụng cURL

```powershell
$headers = @{
    "Authorization" = "Bearer YOUR_JWT_TOKEN"
    "Content-Type" = "application/json"
}

# Test Orders Endpoint
Invoke-WebRequest -Uri "http://localhost:5000/api/orders" `
                  -Headers $headers `
                  -Method GET
```

---

## 🎯 Full Setup Script (Tất Cả 1 Lần)

```powershell
# 1. Thiết lập Backend
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\backend"
npm install

# 2. Thiết lập Database
psql -U postgres -d food_delivery_db -f scripts/migrate_stories_20_24.sql

# 3. Chạy Backend (mở terminal mới)
npm start

# 4. Thiết lập Flutter (mở terminal mới)
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\lalamove_app"
flutter pub get
flutter run -d chrome

# Hoàn tất! ✅
```

---

## 🐛 Xử Lý Lỗi Thường Gặp

### Lỗi: PostgreSQL không tìm thấy

```powershell
# Thêm PostgreSQL vào PATH
$env:PATH += ";E:\linh Tinh\PostGres\bin"

# Hoặc sử dụng full path
& "E:\linh Tinh\PostGres\bin\psql" -U postgres
```

### Lỗi: Port 5000 đã được sử dụng

```powershell
# Tìm process dùng port 5000
netstat -ano | findstr :5000

# Kill process
taskkill /PID {PID} /F

# Hoặc đổi port trong config.env
PORT=5001
```

### Lỗi: Flutter không tìm thấy

```powershell
# Kiểm tra Flutter version
flutter --version

# Cập nhật Flutter
flutter upgrade

# Kiểm tra setup
flutter doctor
```

### Lỗi: Database connection

```powershell
# Kiểm tra PostgreSQL đang chạy
Get-Process postgres

# Hoặc khởi động lại PostgreSQL Service
Get-Service *postgres* | Start-Service
```

---

## 📊 Cấu Trúc Project

```
DoAnCNPMNC/
├── backend/                 ← Node.js Express API
│   ├── server.js           ← Entry point
│   ├── controllers/        ← Business logic
│   ├── routes/            ← API endpoints
│   ├── config/            ← Configuration
│   └── scripts/           ← Database scripts
│
├── lalamove_app/          ← Flutter main app (tích hợp User + Intake)
│   ├── lib/
│   │   ├── screens/       ← All UI screens
│   │   │   ├── user/      ← User screens (Khách hàng)
│   │   │   └── intake/    ← Intake screens (Tiếp nhận)
│   │   ├── widgets/       ← Reusable components
│   │   ├── services/      ← API services
│   │   └── main.dart      ← Entry point
│
└── app_giaohang/          ← App giao hàng (Driver + Deliverer)
    └── lib/
        ├── screens/       ← Driver & Deliverer screens
        └── services/      ← API services
```

---

## ✅ Verification Checklist

- [ ] PostgreSQL cài đặt & chạy
- [ ] Database `food_delivery_db` tồn tại
- [ ] Backend dependencies cài đặt (`npm install`)
- [ ] Backend server chạy port 5000
- [ ] Flutter SDK cài đặt
- [ ] Flutter app chạy thành công
- [ ] Có thể đăng nhập được
- [ ] Có thể fetch data từ API
- [ ] Screens hiển thị đúng

---

## 🎓 Tài Liệu Bổ Sung

- **Backend API**: `DoAnCNPMNC/STORIES_20_24_GUIDE.md`
- **Flutter Screens**: `lalamove_app/lib/screens/STORIES_20_24_SCREENS_README.md`
- **Database Schema**: `DoAnCNPMNC/backend/scripts/migrate_stories_20_24.sql`
- **Test Data**: `mockdata/import_mockdata.ps1`

---

## 📞 Liên Hệ

Nếu có lỗi, kiểm tra:
1. Console output
2. Tài liệu bổ sung
3. Scripts setup
4. Database connection

---

**Cập Nhật:** November 12, 2025  
**Status:** ✅ Sẵn sàng chạy  
**Version:** 1.0

