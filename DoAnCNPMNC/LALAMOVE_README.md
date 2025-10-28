# 🚚 HỆ THỐNG QUẢN LÝ GIAO HÀNG - LALAMOVE EXPRESS

## 📋 GIỚI THIỆU

**Lalamove Express** là ứng dụng quản lý giao hàng chuyên nghiệp, được thiết kế theo phong cách Lalamove với giao diện hiện đại và thân thiện với người dùng.

### 🎯 Mục đích
- Quản lý đơn hàng giao nhận một cách hiệu quả
- Theo dõi trạng thái giao hàng real-time
- Kết nối người gửi và người nhận
- Tối ưu hóa quy trình logistics

---

## ✨ TÍNH NĂNG CHÍNH

### 👤 Quản lý người dùng
- ✅ Đăng ký/Đăng nhập với JWT authentication
- ✅ Quản lý thông tin cá nhân
- ✅ Lịch sử giao dịch

### 📦 Quản lý đơn hàng
- ✅ Tạo đơn giao hàng mới
- ✅ Chọn loại xe phù hợp (xe máy, ô tô, xe tải)
- ✅ Tính toán khoảng cách và giá tiền tự động
- ✅ Theo dõi trạng thái đơn hàng
- ✅ Hủy đơn hàng (nếu chưa được xác nhận)

### 🗺️ Tích hợp bản đồ
- ✅ Chọn điểm đón/trả trên bản đồ (OpenStreetMap)
- ✅ Hiển thị tuyến đường
- ✅ Tính toán khoảng cách chính xác

### 🔔 Real-time tracking
- ✅ Cập nhật vị trí shipper theo thời gian thực (Socket.IO)
- ✅ Thông báo trạng thái đơn hàng
- ✅ Chat với shipper (nếu cần)

---

## 🎨 THIẾT KẾ GIAO DIỆN

### Màu sắc chủ đạo
```
🟠 Primary Orange:    #F26522 (Lalamove Brand)
🟤 Primary Dark:      #D64F0A
⚫ Secondary:         #2C3E50
🟢 Success:          #10B981
🟡 Warning:          #F59E0B
🔴 Danger:           #EF4444
⚪ Background:       #FAFAFA
```

### Phong cách
- **Modern & Clean**: Giao diện đơn giản, dễ sử dụng
- **Professional**: Tập trung vào logistics và giao nhận
- **Brand Consistency**: Tuân thủ màu sắc và style của Lalamove

---

## 🛠️ CÔNG NGHỆ SỬ DỤNG

### Frontend (App User)
- **Framework**: Flutter 3.9.2+
- **State Management**: Provider
- **Maps**: Flutter Map + OpenStreetMap
- **HTTP Client**: http package
- **Real-time**: Socket.IO Client
- **Storage**: SharedPreferences

### Backend
- **Runtime**: Node.js 18.x
- **Framework**: Express.js
- **Database**: PostgreSQL 12+
- **Authentication**: JWT (jsonwebtoken)
- **Real-time**: Socket.IO
- **Security**: Helmet, CORS, Rate Limiting

### Database Schema
```sql
- users (id, username, email, password, role, phone, created_at)
- deliveries (id, user_id, pickup_location, dropoff_location, status, ...)
- tracking (id, delivery_id, latitude, longitude, timestamp)
```

---

## � CẤU TRÚC DỰ ÁN

```
DoAnCNPMNC/
├── app_user/               # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/        # Data models
│   │   ├── providers/     # State management
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API services
│   │   └── utils/         # Constants, helpers
│   └── pubspec.yaml
│
├── backend/               # Node.js API
│   ├── config/           # Database config
│   ├── controllers/      # Business logic
│   ├── middleware/       # Auth, validation
│   ├── routes/           # API endpoints
│   ├── scripts/          # Utility scripts
│   ├── server.js         # Entry point
│   └── package.json
│
├── web_admin/            # Admin Dashboard (HTML/JS)
│   ├── index.html
│   └── js/admin.js
│
└── HUONG_DAN_CHAY_UNG_DUNG.md  # Setup guide
```

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT VÀ CHẠY

### Xem chi tiết tại: [HUONG_DAN_CHAY_UNG_DUNG.md](./HUONG_DAN_CHAY_UNG_DUNG.md)

### Tóm tắt nhanh:

**1️⃣ Backend:**
```bash
cd backend
npm install
# Cấu hình config.env với thông tin PostgreSQL
npm run dev
```

**2️⃣ App User:**
```bash
cd app_user
flutter pub get
flutter run
```

**3️⃣ Web Admin:**
- Mở file `web_admin/index.html` trên trình duyệt

---

## � FLOW HOẠT ĐỘNG

### Tạo đơn hàng
```
1. Người dùng đăng nhập
2. Chọn điểm đón trên bản đồ
3. Chọn điểm trả trên bản đồ
4. Hệ thống tính khoảng cách tự động
5. Chọn loại xe
6. Hệ thống tính giá tiền
7. Xác nhận đơn hàng
8. Đơn hàng được tạo với trạng thái "Pending"
```

### Theo dõi đơn hàng
```
1. Người dùng vào màn hình "Đơn hàng"
2. Chọn đơn cần theo dõi
3. Xem chi tiết và trạng thái
4. Nhận cập nhật real-time qua Socket.IO
```

---

## 🔒 BẢO MẬT

- ✅ **JWT Authentication**: Xác thực người dùng an toàn
- ✅ **Password Hashing**: Mã hóa mật khẩu với bcrypt
- ✅ **CORS Protection**: Chống truy cập trái phép
- ✅ **Rate Limiting**: Giới hạn request để tránh spam
- ✅ **Input Validation**: Kiểm tra dữ liệu đầu vào với Joi
- ✅ **SQL Injection Prevention**: Sử dụng prepared statements

---

## 📈 TRẠNG THÁI ĐƠN HÀNG

| Status | Mô tả | Màu sắc |
|--------|-------|---------|
| `pending` | Chờ xác nhận | 🟡 Orange |
| `confirmed` | Đã xác nhận | 🔵 Blue |
| `picked_up` | Đã lấy hàng | 🟣 Purple |
| `in_transit` | Đang giao | 🔵 Blue |
| `delivered` | Đã giao | 🟢 Green |
| `cancelled` | Đã hủy | 🔴 Red |

---

## 🚗 LOẠI XE VÀ GIÁ CƯỚC

| Loại xe | Icon | Mô tả | Giá cơ bản |
|---------|------|-------|------------|
| Xe máy | 🏍️ | Giao hàng nhỏ, nhanh | 15,000₫/km |
| Ô tô 4 chỗ | 🚗 | Hàng vừa và lớn | 20,000₫/km |
| Ô tô 7 chỗ | 🚙 | Hàng cồng kềnh | 25,000₫/km |
| Xe tải nhỏ | 🚚 | Hàng nặng, số lượng lớn | 30,000₫/km |

*Công thức: `Tổng tiền = Khoảng cách (km) × Đơn giá`*

---

## � TÀI LIỆU THAM KHẢO

### Documentation Files
- 📘 [HUONG_DAN_CHAY_UNG_DUNG.md](./HUONG_DAN_CHAY_UNG_DUNG.md) - Hướng dẫn setup và chạy
- 📋 [CHANGES_SUMMARY.md](./CHANGES_SUMMARY.md) - Tổng kết thay đổi
- 🎨 [DESIGN_REFERENCE.md](./DESIGN_REFERENCE.md) - Tài liệu thiết kế
- � [QUICK_START.md](./QUICK_START.md) - Hướng dẫn nhanh

### API Documentation
- Xem chi tiết API endpoints trong `backend/routes/`
- Base URL: `http://localhost:3000/api`

---

## 🧪 TESTING

### Backend Tests
```bash
cd backend
npm test
```

### Flutter Tests
```bash
cd app_user
flutter test
```

---

## 🤝 ĐÓNG GÓP

### Quy trình
1. Fork repository
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`
3. Commit changes: `git commit -m "Add tính năng XYZ"`
4. Push to branch: `git push origin feature/ten-tinh-nang`
5. Tạo Pull Request

### Code Style
- **Flutter**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **JavaScript**: Follow [Airbnb Style Guide](https://github.com/airbnb/javascript)
- **Commit messages**: Clear và descriptive

---

## 🐛 BÁO LỖI VÀ HỖ TRỢ

Nếu gặp vấn đề:
1. Kiểm tra [HUONG_DAN_CHAY_UNG_DUNG.md](./HUONG_DAN_CHAY_UNG_DUNG.md)
2. Xem phần "Khắc phục sự cố"
3. Tạo issue trên GitHub với mô tả chi tiết

---

## � TEAM PHÁT TRIỂN

**Nhóm 15 - Công Nghệ Phần Mềm NC**
- Môn học: Công nghệ phần mềm nâng cao
- Năm học: 2024-2025

---

## 📄 LICENSE

Dự án giáo dục - Educational Purpose Only

---

## 🎉 ACKNOWLEDGMENTS

- Lalamove cho design inspiration
- OpenStreetMap cho map service
- Flutter & Node.js communities

---

**💡 Version:** 1.0.0  
**📅 Last Updated:** October 2025  
**✅ Status:** Production Ready

**🚀 Happy Coding!**
