# 🚚 Hướng Dẫn Setup & Test Tính Năng Phân Tài Xế

## 📋 Tổng quan

Script này tạo **15 tài xế test** với đầy đủ thông tin để test tính năng phân tài xế trong **app intake (lalamove_app)**.

---

## 🗂️ Cấu trúc Database

### Table: `users`

Các cột quan trọng cho driver:

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `id` | INTEGER | ID tài xế |
| `email` | VARCHAR(255) | Email đăng nhập |
| `password` | VARCHAR(255) | Password (bcrypt hash) |
| `full_name` | VARCHAR(255) | Tên đầy đủ |
| `phone` | VARCHAR(20) | Số điện thoại |
| `address` | TEXT | Địa chỉ |
| `role` | VARCHAR(20) | Giá trị: **'driver'** |
| `vehicle_type` | VARCHAR(50) | Loại xe: bike, van_500, van_750, van_1000 |
| `vehicle_number` | VARCHAR(50) | Biển số xe |
| `vehicle_registration` | VARCHAR(50) | Đăng ký xe (giống vehicle_number) |

---

## 🚀 Cách Chạy

### Cách 1: Chạy PowerShell Script (Khuyến nghị)

```powershell
# 1. Mở PowerShell tại thư mục backend/scripts
cd DoAnCNPMNC/backend/scripts

# 2. Sửa password database trong file setup_drivers_test.ps1
# Tìm dòng: $DB_PASSWORD = "your_password"
# Thay "your_password" bằng password postgres của bạn

# 3. Chạy script
.\setup_drivers_test.ps1
```

### Cách 2: Chạy SQL Trực Tiếp

```bash
# Kết nối PostgreSQL
psql -U postgres -d food_delivery_db

# Chạy file SQL
\i 'C:/path/to/create_test_drivers_for_intake.sql'
```

### Cách 3: Dùng pgAdmin

1. Mở pgAdmin
2. Kết nối database `food_delivery_db`
3. Mở Query Tool
4. Copy nội dung file `create_test_drivers_for_intake.sql`
5. Paste và Execute (F5)

---

## 👥 Danh Sách Tài Xế Test

### 🔑 Thông Tin Đăng Nhập

- **Email**: `driver1@intake.test` đến `driver15@intake.test`
- **Password**: `Driver@123`
- **Role**: `driver`

### 🚗 Phân Bổ Loại Xe

| Loại Xe | Số Lượng | Drivers | Icon |
|---------|----------|---------|------|
| **Xe máy** (bike) | 8 | driver1 - driver8 | 🏍️ |
| **Van 500kg** (van_500) | 3 | driver9 - driver11 | 🚐 |
| **Van 750kg** (van_750) | 2 | driver12 - driver13 | 🚚 |
| **Van 1000kg** (van_1000) | 2 | driver14 - driver15 | 🚛 |

### 📝 Chi Tiết Từng Tài Xế

#### 🏍️ Xe Máy (8 drivers)

1. **Nguyễn Văn Anh** - 0901234501 - 59A-12301
2. **Trần Thị Bình** - 0902234502 - 59B-23402
3. **Lê Văn Cường** - 0903234503 - 59C-34503
4. **Phạm Thị Dung** - 0904234504 - 59D-45604
5. **Hoàng Văn Em** - 0905234505 - 59E-56705
6. **Võ Thị Phương** - 0906234506 - 59F-67806
7. **Đặng Văn Giang** - 0907234507 - 59G-78907
8. **Bùi Thị Hoa** - 0908234508 - 59H-89008

#### 🚐 Van 500kg (3 drivers)

9. **Ngô Văn Inh** - 0909234509 - 51I-90109
10. **Lý Thị Kim** - 0910234510 - 51K-01210
11. **Phan Văn Long** - 0911234511 - 51L-12311

#### 🚚 Van 750kg (2 drivers)

12. **Trương Văn Minh** - 0912234512 - 51M-23412
13. **Huỳnh Thị Nga** - 0913234513 - 51N-34513

#### 🚛 Van 1000kg (2 drivers)

14. **Đinh Văn Phúc** - 0914234514 - 51P-45614
15. **Mai Thị Quỳnh** - 0915234515 - 51Q-56715

---

## 🧪 Hướng Dẫn Test

### Bước 1: Setup Database

```bash
# Chạy script tạo drivers
.\setup_drivers_test.ps1
```

### Bước 2: Khởi động Backend

```bash
cd backend
npm start
```

### Bước 3: Test trong App Intake

1. **Mở app intake** (lalamove_app)
2. **Login** với tài khoản intake staff
3. **Quét QR** hoặc nhập mã đơn hàng
4. **Phân loại đơn** → Chọn zone và recommended_vehicle
5. **Vào màn hình Phân tài xế**
6. **Quan sát**:
   - Danh sách tài xế được lọc theo `vehicle_type`
   - Hiển thị số đơn đang giao của mỗi tài xế
   - Có thể chọn và phân tài xế

### Bước 4: Kiểm Tra API

#### API 1: Lấy danh sách tài xế

```bash
# Lấy tất cả drivers
GET http://192.168.1.173:3000/api/warehouse/drivers/available

# Lọc theo loại xe
GET http://192.168.1.173:3000/api/warehouse/drivers/available?vehicle_type=bike
GET http://192.168.1.173:3000/api/warehouse/drivers/available?vehicle_type=van_500
```

**Response:**
```json
{
  "success": true,
  "drivers": [
    {
      "id": 123,
      "name": "Nguyễn Văn Anh",
      "phone": "0901234501",
      "vehicle_type": "bike",
      "vehicle_number": "59A-12301",
      "vehicle_registration": "59A-12301",
      "current_orders": 0
    }
  ]
}
```

#### API 2: Phân tài xế

```bash
POST http://192.168.1.173:3000/api/warehouse/assign-driver
Content-Type: application/json
Authorization: Bearer <token>

{
  "order_id": "order_123",
  "driver_id": "driver_456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Đã phân tài xế thành công",
  "order": { ... }
}
```

---

## 🔍 Troubleshooting

### Lỗi: "column vehicle_type does not exist"

**Nguyên nhân**: Database chưa có cột `vehicle_type`

**Giải pháp**: Script SQL đã bao gồm `ALTER TABLE` để thêm cột này. Chạy lại script.

### Lỗi: "password authentication failed"

**Nguyên nhân**: Password database sai

**Giải pháp**: 
1. Mở file `setup_drivers_test.ps1`
2. Sửa `$DB_PASSWORD = "your_password"`
3. Thay bằng password thật của PostgreSQL

### Không thấy tài xế trong app

**Kiểm tra**:
1. Backend có đang chạy không?
2. IP address có đúng không? (192.168.1.173)
3. Token authentication có hợp lệ không?
4. Kiểm tra console log trong app để xem lỗi API

### Tài xế không được lọc theo vehicle_type

**Kiểm tra**:
1. Đơn hàng đã được phân loại với `recommended_vehicle` chưa?
2. Backend API có truyền parameter `vehicle_type` đúng không?
3. Check response từ API: `console.log(drivers)`

---

## 📊 Kiểm Tra Database

### Query kiểm tra tài xế đã tạo

```sql
-- Xem tất cả drivers
SELECT 
  id,
  email,
  full_name,
  phone,
  vehicle_type,
  vehicle_number
FROM users 
WHERE email LIKE 'driver%@intake.test'
ORDER BY vehicle_type, full_name;

-- Đếm số drivers theo loại xe
SELECT 
  vehicle_type,
  COUNT(*) as count
FROM users 
WHERE email LIKE 'driver%@intake.test'
GROUP BY vehicle_type
ORDER BY vehicle_type;
```

### Query kiểm tra số đơn đang giao

```sql
-- Xem số đơn đang giao của mỗi driver
SELECT 
  u.full_name,
  u.phone,
  u.vehicle_type,
  COUNT(o.id) FILTER (WHERE o.status IN ('assigned_to_driver', 'picked_up', 'in_delivery')) as current_orders
FROM users u
LEFT JOIN orders o ON o.driver_id = u.id
WHERE u.email LIKE 'driver%@intake.test'
GROUP BY u.id, u.full_name, u.phone, u.vehicle_type
ORDER BY current_orders DESC;
```

---

## 🎯 Test Cases

### Test Case 1: Hiển thị đúng loại xe

**Steps**:
1. Tạo đơn hàng với `recommended_vehicle = 'bike'`
2. Phân loại đơn
3. Vào màn hình phân tài xế
4. **Expected**: Chỉ hiển thị 8 tài xế xe máy

### Test Case 2: Sắp xếp theo số đơn đang giao

**Steps**:
1. Phân 2 đơn cho driver1
2. Phân 1 đơn cho driver2
3. Tạo đơn mới với `recommended_vehicle = 'bike'`
4. **Expected**: driver3-8 hiển thị trước, driver2 kế tiếp, driver1 cuối cùng

### Test Case 3: Phân tài xế thành công

**Steps**:
1. Chọn tài xế driver1
2. Nhấn "Xác nhận phân tài xế"
3. **Expected**: 
   - Hiển thị dialog xác nhận
   - Sau khi xác nhận: thông báo thành công
   - Quay về màn hình trước
   - Đơn có status = 'assigned_to_driver'

### Test Case 4: Không có tài xế khả dụng

**Steps**:
1. Xóa hết drivers có `vehicle_type = 'van_1000'`
2. Tạo đơn với `recommended_vehicle = 'van_1000'`
3. **Expected**: Hiển thị "Không có tài xế khả dụng"

---

## 📱 Screenshots Flow

```
[Login Intake] 
    ↓
[Home Screen] 
    ↓
[Scan QR / Nhập mã đơn]
    ↓
[Phân loại đơn]
    → Chọn zone
    → Chọn recommended_vehicle: bike
    ↓
[Classified Orders List]
    → Tap đơn vừa phân loại
    ↓
[Warehouse Screen]
    → Tap "Phân tài xế"
    ↓
[Assignment Screen] ✨
    → Hiển thị 8 tài xế xe máy
    → Hiển thị số đơn đang giao
    → Chọn driver1
    ↓
[Confirmation Dialog]
    → Xác nhận
    ↓
[Success] 
    → Quay về màn hình trước
```

---

## 🔗 API Endpoints

### Warehouse Controller

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/warehouse/drivers/available` | Lấy danh sách tài xế |
| POST | `/api/warehouse/assign-driver` | Phân tài xế cho đơn |
| POST | `/api/warehouse/classify` | Phân loại đơn hàng |
| GET | `/api/warehouse/orders/classified` | Lấy đơn đã phân loại |

---

## 💡 Tips

1. **Sử dụng Hot Reload**: Sau khi sửa code Flutter, nhấn `R` để hot reload
2. **Clear Cache**: Nếu không thấy thay đổi, restart app với `Shift + R`
3. **Check Logs**: Luôn xem terminal logs để debug
4. **Postman**: Test API riêng trước khi test trong app
5. **Database Client**: Dùng pgAdmin hoặc DBeaver để xem data realtime

---

## 📞 Support

Nếu gặp vấn đề, kiểm tra:

1. ✅ Backend đang chạy
2. ✅ Database có drivers test
3. ✅ IP address đúng
4. ✅ Token authentication hợp lệ
5. ✅ App có quyền truy cập network

---

## 📚 References

- [Backend Controller](../controllers/warehouseController.js)
- [Flutter Assignment Screen](../../app_intake/lib/screens/warehouse/assignment_screen.dart)
- [API Service](../../app_intake/lib/services/api_service.dart)
- [Warehouse Provider](../../app_intake/lib/providers/warehouse_provider.dart)

---

**Happy Testing! 🎉**
