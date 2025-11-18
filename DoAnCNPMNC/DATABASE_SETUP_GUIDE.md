# 🗄️ Hướng dẫn Setup Database cho Lalamove App

## 📋 Mục lục
1. [Cài đặt PostgreSQL](#1-cài-đặt-postgresql)
2. [Tạo Database](#2-tạo-database)
3. [Import Database (Khuyến nghị)](#3-import-database-khuyến-nghị)
4. [Hoặc: Tự động tạo từ Backend](#4-hoặc-tự-động-tạo-từ-backend)
5. [Kiểm tra Database](#5-kiểm-tra-database)
6. [Troubleshooting](#6-troubleshooting)

---

## 1️⃣ Cài đặt PostgreSQL

### **Windows:**
1. Download PostgreSQL từ: https://www.postgresql.org/download/windows/
2. Chọn phiên bản **PostgreSQL 14+**
3. Cài đặt với các thông số:
   - Port: `5432` (mặc định)
   - User: `postgres`
   - Password: `Trongkhang205@` (hoặc password của bạn)
4. Cài đặt kèm **pgAdmin 4**

### **macOS:**
```bash
brew install postgresql@14
brew services start postgresql@14
```

### **Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

---

## 2️⃣ Tạo Database

### **Cách 1: Dùng pgAdmin 4 (Đơn giản nhất)**

1. Mở **pgAdmin 4**
2. Kết nối vào server PostgreSQL (localhost)
3. Click chuột phải vào **Databases** → **Create** → **Database...**
4. Nhập:
   - Database name: `food_delivery_db`
   - Owner: `postgres`
5. Click **Save**

### **Cách 2: Dùng Command Line**

```bash
# Kết nối vào PostgreSQL
psql -U postgres

# Tạo database
CREATE DATABASE food_delivery_db;

# Thoát
\q
```

---

## 3️⃣ Import Database (Khuyến nghị) ⭐

### **📦 File backup có sẵn:** `food_delivery_backup.sql`

File này chứa:
- ✅ Tất cả tables với đầy đủ cấu trúc
- ✅ Tất cả columns và constraints
- ✅ Tất cả indexes
- ✅ Dữ liệu mẫu (nếu có)

### **Cách 1: Import bằng pgAdmin 4**

1. Mở **pgAdmin 4**
2. Chọn database **food_delivery_db**
3. Click chuột phải → **Restore...**
4. Chọn file: `food_delivery_backup.sql`
5. Format: **Plain**
6. Click **Restore**

### **Cách 2: Import bằng Command Line**

```bash
# Di chuyển vào thư mục chứa file backup
cd C:\Workspace\CNPM_nc\Nhom15_QuanLyGiaoHang

# Restore database
psql -U postgres -d food_delivery_db -f food_delivery_backup.sql
```

### **Windows PowerShell:**
```powershell
cd C:\Workspace\CNPM_nc\Nhom15_QuanLyGiaoHang
& "C:\Program Files\PostgreSQL\14\bin\psql.exe" -U postgres -d food_delivery_db -f food_delivery_backup.sql
```

**⏱️ Thời gian:** Khoảng 1-2 phút

**✅ Kết quả:** Database có đầy đủ tables:
- `users`
- `orders`
- `order_status_history`
- `delivery_tracking`
- `notifications`
- `complaints`
- `complaint_responses`

---

## 4️⃣ Hoặc: Tự động tạo từ Backend

Nếu không dùng file backup, backend sẽ tự động tạo tables khi khởi động.

### **Bước 1: Cấu hình Backend**

Mở file `backend/config.env`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_delivery_db
DB_USER=postgres
DB_PASSWORD=Trongkhang205@    # ← Đổi thành password của bạn
```

### **Bước 2: Khởi động Backend**

```bash
cd DoAnCNPMNC/backend
npm install
npm start
```

**Output mong đợi:**
```
✅ Connected to PostgreSQL database
✅ Database tables created successfully
🚀 Server running on port 3000
```

### **Bước 3: Chạy Migration thủ công**

Backend chỉ tạo tự động 4 tables cơ bản. Bạn cần chạy thêm migration cho `notifications` và `complaints`:

```bash
# Trong psql
psql -U postgres -d food_delivery_db

# Chạy migration
\i DoAnCNPMNC/backend/scripts/migrate_notifications.sql
\i DoAnCNPMNC/backend/scripts/migrate_complaints.sql

# Kiểm tra
\dt

# Thoát
\q
```

---

## 5️⃣ Kiểm tra Database

### **Trong pgAdmin 4:**

1. Mở pgAdmin 4
2. **Servers** → **PostgreSQL** → **Databases** → **food_delivery_db**
3. **Schemas** → **public** → **Tables**

Bạn phải thấy 7 tables:
- ✅ complaint_responses
- ✅ complaints
- ✅ delivery_tracking
- ✅ notifications
- ✅ order_status_history
- ✅ orders
- ✅ users

### **Kiểm tra bằng SQL:**

```sql
-- Liệt kê tất cả tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Đếm số lượng records
SELECT 
  (SELECT COUNT(*) FROM users) as users_count,
  (SELECT COUNT(*) FROM orders) as orders_count,
  (SELECT COUNT(*) FROM notifications) as notifications_count,
  (SELECT COUNT(*) FROM complaints) as complaints_count;

-- Xem cấu trúc table users
\d users

-- Xem cấu trúc table orders
\d orders
```

### **Test kết nối từ Backend:**

```bash
cd DoAnCNPMNC/backend
node -e "const {pool} = require('./config/database'); pool.query('SELECT NOW()', (err, res) => { console.log(err ? '❌ Error' : '✅ Connected:', res.rows[0]); pool.end(); });"
```

---

## 6️⃣ Troubleshooting

### ❌ **Lỗi: "database does not exist"**

**Giải pháp:**
```bash
psql -U postgres
CREATE DATABASE food_delivery_db;
\q
```

### ❌ **Lỗi: "password authentication failed"**

**Giải pháp:**
1. Kiểm tra password trong `backend/config.env`
2. Reset password PostgreSQL:
```bash
psql -U postgres
ALTER USER postgres PASSWORD 'Trongkhang205@';
```

### ❌ **Lỗi: "connection refused"**

**Giải pháp:**
1. Kiểm tra PostgreSQL service đang chạy:
   - Windows: `services.msc` → tìm "PostgreSQL"
   - Mac: `brew services list`
   - Linux: `sudo systemctl status postgresql`

2. Kiểm tra port 5432:
```bash
netstat -an | findstr 5432
```

### ❌ **Lỗi: "permission denied for schema public"**

**Giải pháp:**
```sql
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
```

### ❌ **Backend không tạo được tables**

**Giải pháp:**
1. Check logs khi start backend
2. Xóa database và tạo lại:
```sql
DROP DATABASE food_delivery_db;
CREATE DATABASE food_delivery_db;
```
3. Import lại từ file backup

### ❌ **Thiếu tables `notifications` hoặc `complaints`**

**Giải pháp:**
```bash
cd DoAnCNPMNC/backend/scripts
psql -U postgres -d food_delivery_db -f migrate_notifications.sql
psql -U postgres -d food_delivery_db -f migrate_complaints.sql
```

---

## 📦 Tạo Backup Database (Cho Dev khác)

### **Backup toàn bộ:**
```bash
# Backup schema + data
pg_dump -U postgres food_delivery_db > food_delivery_backup.sql

# Chỉ backup schema (không có data)
pg_dump -U postgres --schema-only food_delivery_db > schema_only.sql
```

### **Backup từng table:**
```bash
pg_dump -U postgres -t users food_delivery_db > users_backup.sql
pg_dump -U postgres -t orders food_delivery_db > orders_backup.sql
```

---

## 🎯 Setup Checklist

Checklist cho người mới setup:

- [ ] Đã cài PostgreSQL 14+
- [ ] Đã cài pgAdmin 4
- [ ] Đã tạo database `food_delivery_db`
- [ ] Đã import file `food_delivery_backup.sql` HOẶC
- [ ] Đã chạy backend để tạo tables tự động
- [ ] Đã chạy migration cho `notifications` và `complaints`
- [ ] Đã kiểm tra có đủ 7 tables
- [ ] Đã cập nhật `backend/config.env` với password đúng
- [ ] Đã test kết nối backend → database thành công
- [ ] Backend start không có lỗi

---

## 📖 Tài liệu liên quan

- **Cấu trúc chi tiết:** Xem file `DATABASE_STRUCTURE.md`
- **Backend config:** `backend/config/database.js`
- **Migration scripts:** `backend/scripts/`

---

## 💡 Tips

1. **Dùng file backup:** Nhanh nhất và đảm bảo đúng cấu trúc 100%
2. **Backup thường xuyên:** Sau mỗi lần thay đổi schema
3. **Version control:** Commit file `.sql` vào git để team dùng chung
4. **Environment variables:** Mỗi dev có thể dùng password riêng trong `.env`
5. **Sample data:** Có thể thêm dữ liệu mẫu để test

---

## 🆘 Cần hỗ trợ?

Nếu gặp vấn đề:
1. Check PostgreSQL logs: `pg_log` folder
2. Check backend logs khi start
3. Dùng pgAdmin 4 Query Tool để test SQL trực tiếp
4. Google error message cụ thể

---

**🎉 Chúc bạn setup thành công!**
