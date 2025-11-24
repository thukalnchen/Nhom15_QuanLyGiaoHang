# 🚀 HƯỚNG DẪN SETUP NHANH - LALAMOVE APP

## 📦 Yêu cầu hệ thống

- ✅ Node.js 16+ ([Download](https://nodejs.org/))
- ✅ PostgreSQL 14+ ([Download](https://www.postgresql.org/download/))
- ✅ Flutter 3.x ([Download](https://flutter.dev/))
- ✅ Git ([Download](https://git-scm.com/))

---

## ⚡ Setup Nhanh (3 Bước)

### **Bước 1: Clone Project**
```bash
git clone https://github.com/thukalnchen/Nhom15_QuanLyGiaoHang.git
cd Nhom15_QuanLyGiaoHang
```

### **Bước 2: Setup Database (QUAN TRỌNG!)**

#### **Cách 1: Tự động (Khuyến nghị)** ⭐
```powershell
# Chạy script setup tự động
.\setup_database.ps1
```
Script sẽ:
- ✅ Kiểm tra PostgreSQL
- ✅ Tạo database `food_delivery_db`
- ✅ Import tất cả tables từ file backup
- ✅ Cấu hình backend tự động

#### **Cách 2: Thủ công**
```bash
# 1. Tạo database
psql -U postgres
CREATE DATABASE food_delivery_db;
\q

# 2. Import backup
psql -U postgres -d food_delivery_db -f food_delivery_backup.sql

# 3. Cập nhật password trong backend/config.env
```

### **Bước 3: Khởi động ứng dụng**

#### **Terminal 1 - Backend:**
```bash
cd DoAnCNPMNC/backend
npm install
npm start
```

Thấy dòng này là thành công:
```
✅ Connected to PostgreSQL database
✅ Database tables created successfully
🚀 Server running on port 3000
```

#### **Terminal 2 - Flutter App:**
```bash
cd DoAnCNPMNC/lalamove_app
flutter pub get
flutter run -d chrome    # Chạy trên web
# hoặc
flutter run              # Chạy trên mobile
```

---

## 🗂️ Cấu trúc Project

```
Nhom15_QuanLyGiaoHang/
├── DoAnCNPMNC/
│   ├── backend/              # Node.js Backend API
│   │   ├── config/
│   │   │   ├── database.js   # Định nghĩa tables
│   │   │   └── config.env    # Cấu hình DB (cập nhật password ở đây)
│   │   ├── controllers/      # Logic xử lý
│   │   ├── routes/           # API endpoints
│   │   ├── scripts/          # SQL migration scripts
│   │   └── server.js         # Entry point
│   │
│   └── lalamove_app/         # Flutter App
│       ├── lib/
│       │   ├── models/       # Data models
│       │   ├── providers/    # State management
│       │   ├── screens/      # UI screens
│       │   └── services/     # API services
│       └── pubspec.yaml
│
├── food_delivery_backup.sql  # ⭐ Database backup (QUAN TRỌNG!)
├── setup_database.ps1        # Script setup tự động
├── DATABASE_SETUP_GUIDE.md   # Hướng dẫn chi tiết
└── DATABASE_STRUCTURE.md     # Cấu trúc database
```

---

## 🔧 Cấu hình Database

### **File: `backend/config.env`**

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_delivery_db
DB_USER=postgres
DB_PASSWORD="YOUR_PASSWORD_HERE"    # ← Đổi thành password của bạn

# Backend Server
PORT=3000
```

**⚠️ Lưu ý:** Phải cập nhật `DB_PASSWORD` đúng với password PostgreSQL của bạn!

---

## 📊 Database Tables

App sử dụng **7 tables chính:**

| Table | Mô tả |
|-------|-------|
| `users` | Thông tin người dùng (customer, driver, staff, admin) |
| `orders` | Đơn hàng |
| `order_status_history` | Lịch sử trạng thái đơn hàng |
| `delivery_tracking` | Theo dõi vị trí giao hàng |
| `notifications` | Thông báo |
| `complaints` | Khiếu nại |
| `complaint_responses` | Phản hồi khiếu nại |

**📖 Chi tiết:** Xem file `DATABASE_STRUCTURE.md`

---

## 🎯 Tài khoản Test

Sau khi setup database từ file backup, bạn có thể dùng các tài khoản test:

| Email | Password | Role |
|-------|----------|------|
| `admin@test.com` | `123456` | Admin |
| `staff@test.com` | `123456` | Intake Staff |
| `driver@test.com` | `123456` | Driver |
| `customer@test.com` | `123456` | Customer |

*(Nếu không có data, bạn cần đăng ký tài khoản mới trong app)*

---

## 🐛 Troubleshooting

### ❌ **Backend không kết nối được database**

**Lỗi:** `Database connection failed`

**Giải pháp:**
1. Kiểm tra PostgreSQL đang chạy:
   ```bash
   # Windows
   services.msc    # Tìm "PostgreSQL"
   ```

2. Kiểm tra password trong `backend/config.env`

3. Test kết nối:
   ```bash
   psql -U postgres -d food_delivery_db
   ```

### ❌ **Port 3000 đã được sử dụng**

**Lỗi:** `EADDRINUSE: address already in use :::3000`

**Giải pháp:**
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F

# macOS/Linux
lsof -ti:3000 | xargs kill -9
```

### ❌ **Flutter không kết nối được backend**

**Giải pháp:**
1. Kiểm tra backend đang chạy (http://localhost:3000)
2. Kiểm tra URL trong Flutter app: `lib/utils/constants.dart`
```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:3000';
}
```

### ❌ **Thiếu tables trong database**

**Giải pháp:**

Option 1 - Import lại từ backup:
```bash
psql -U postgres -d food_delivery_db -f food_delivery_backup.sql
```

Option 2 - Chạy migration:
```bash
cd DoAnCNPMNC/backend/scripts
psql -U postgres -d food_delivery_db -f migrate_notifications.sql
psql -U postgres -d food_delivery_db -f migrate_complaints.sql
```

---

## 📱 Chạy App trên các Platform

### **Web (Chrome):**
```bash
cd DoAnCNPMNC/lalamove_app
flutter run -d chrome
```

### **Android:**
```bash
flutter run -d <device_id>
```

### **iOS (macOS only):**
```bash
flutter run -d ios
```

### **Windows Desktop:**
```bash
flutter run -d windows
```

---

## 🔍 Kiểm tra Database

### **Trong pgAdmin 4:**
1. Mở pgAdmin 4
2. Servers → PostgreSQL → Databases → `food_delivery_db`
3. Schemas → public → Tables

### **Bằng SQL:**
```sql
-- Liệt kê tất cả tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Đếm số records
SELECT 
  (SELECT COUNT(*) FROM users) as users,
  (SELECT COUNT(*) FROM orders) as orders;

-- Xem users
SELECT id, email, role FROM users;
```

---

## 📚 Tài liệu

- 📖 **Setup Database:** `DATABASE_SETUP_GUIDE.md`
- 📊 **Cấu trúc Database:** `DATABASE_STRUCTURE.md`
- 📝 **API Documentation:** Coming soon...
- 🎨 **UI Mockups:** `DoAnCNPMNC/UI_Mockups/`

---

## 🆘 Cần Hỗ trợ?

1. **Check logs:**
   - Backend: Terminal output
   - Flutter: Debug console
   - PostgreSQL: `pg_log` folder

2. **Common issues:** Xem phần Troubleshooting ở trên

3. **Database issues:** Xem `DATABASE_SETUP_GUIDE.md`

---

## 👥 Team

**Nhóm 15 - Quản lý Giao Hàng**
- Branch: `trongkhang_branch`
- Repository: [Nhom15_QuanLyGiaoHang](https://github.com/thukalnchen/Nhom15_QuanLyGiaoHang)

---

## ✅ Checklist Setup

- [ ] Đã cài đặt PostgreSQL
- [ ] Đã cài đặt Node.js
- [ ] Đã cài đặt Flutter
- [ ] Đã clone project
- [ ] Đã chạy `setup_database.ps1` HOẶC import backup thủ công
- [ ] Đã cập nhật password trong `backend/config.env`
- [ ] Backend chạy thành công (port 3000)
- [ ] Đã kiểm tra có đủ 7 tables trong database
- [ ] Flutter app chạy thành công
- [ ] Đã test đăng ký/đăng nhập

---

**🎉 Chúc bạn setup thành công!**

Nếu gặp vấn đề, hãy check các file hướng dẫn chi tiết hoặc liên hệ team.
