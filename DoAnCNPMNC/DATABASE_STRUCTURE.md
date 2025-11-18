# 📊 Cấu Trúc Database - Lalamove App

## 🔌 Thông tin kết nối PostgreSQL (pgAdmin4)

### **File cấu hình:** `backend/config.env`
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_delivery_db
DB_USER=postgres
DB_PASSWORD="Trongkhang205@"
```

### **Cách xem database trong pgAdmin4:**
1. Mở pgAdmin4
2. Kết nối đến Server: `localhost:5432`
3. Tìm database: `food_delivery_db`
4. Mở mục **Schemas → public → Tables** để xem tất cả các bảng

---

## 📋 Các Table (Bảng) trong Database

### **File định nghĩa:** `backend/config/database.js`

Database được tạo tự động khi backend khởi động qua function `createTables()`.

---

## 1️⃣ **Table: `users`** - Bảng người dùng

**Mô tả:** Lưu thông tin tất cả người dùng (khách hàng, nhân viên kho, tài xế, admin)

| Cột | Kiểu dữ liệu | Mô tả | Ràng buộc |
|-----|-------------|-------|-----------|
| `id` | SERIAL | ID tự tăng | PRIMARY KEY |
| `email` | VARCHAR(255) | Email đăng nhập | UNIQUE, NOT NULL |
| `password` | VARCHAR(255) | Mật khẩu đã hash (bcrypt) | NOT NULL |
| `full_name` | VARCHAR(255) | Họ tên đầy đủ | NOT NULL |
| `phone` | VARCHAR(20) | Số điện thoại | |
| `address` | TEXT | Địa chỉ | |
| `role` | VARCHAR(20) | Vai trò: `customer`, `intake_staff`, `driver`, `admin` | DEFAULT 'customer' |
| `fcm_token` | TEXT | Firebase token cho push notification | |
| `created_at` | TIMESTAMP | Thời gian tạo | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Thời gian cập nhật | DEFAULT NOW() |

**Index:**
- `idx_users_email` trên cột `email`

---

## 2️⃣ **Table: `orders`** - Bảng đơn hàng

**Mô tả:** Lưu tất cả thông tin đơn hàng giao hàng

| Cột | Kiểu dữ liệu | Mô tả | Ràng buộc |
|-----|-------------|-------|-----------|
| `id` | SERIAL | ID đơn hàng | PRIMARY KEY |
| `order_number` | VARCHAR(50) | Mã đơn hàng (dạng: ORD-xxx) | UNIQUE, NOT NULL |
| `user_id` | INTEGER | ID khách hàng | FOREIGN KEY → users(id) |
| `restaurant_name` | VARCHAR(255) | Tên cửa hàng/người gửi | NOT NULL |
| `items` | JSONB | Danh sách món hàng (JSON) | NOT NULL |
| `total_amount` | DECIMAL(10,2) | Tổng tiền | NOT NULL |
| `delivery_fee` | DECIMAL(10,2) | Phí giao hàng | DEFAULT 0 |
| `status` | VARCHAR(50) | Trạng thái đơn hàng | DEFAULT 'pending' |
| `delivery_address` | TEXT | Địa chỉ giao hàng | NOT NULL |
| `delivery_phone` | VARCHAR(20) | SĐT người nhận | |
| `notes` | TEXT | Ghi chú | |
| `pickup_address` | TEXT | Địa chỉ lấy hàng | |
| `vehicle_type` | VARCHAR(50) | Loại xe: `bike`, `car`, `truck` | |
| **Thông tin thanh toán** | | | |
| `payment_status` | VARCHAR(50) | Trạng thái thanh toán | DEFAULT 'pending' |
| `payment_method` | VARCHAR(50) | Phương thức: `cash`, `card`, `momo` | |
| `refund_status` | VARCHAR(50) | Trạng thái hoàn tiền | |
| `refund_initiated_at` | TIMESTAMP | Thời gian bắt đầu hoàn tiền | |
| **Thông tin hủy đơn** | | | |
| `cancellation_reason` | TEXT | Lý do hủy | |
| `cancellation_type` | VARCHAR(50) | Loại hủy | |
| `cancelled_at` | TIMESTAMP | Thời gian hủy | |
| `cancelled_by` | INTEGER | Người hủy | FOREIGN KEY → users(id) |
| **Thông tin kho** | | | |
| `package_size` | VARCHAR(50) | Kích thước: `small`, `medium`, `large` | |
| `package_type` | VARCHAR(50) | Loại hàng: `document`, `food`, `fragile` | |
| `weight` | DECIMAL(10,2) | Cân nặng (kg) | |
| `description` | TEXT | Mô tả hàng hóa | |
| `images` | JSONB | Hình ảnh hàng hóa (JSON array) | |
| `warehouse_id` | INTEGER | ID kho | |
| `warehouse_name` | VARCHAR(255) | Tên kho | |
| `intake_staff_id` | INTEGER | ID nhân viên nhận hàng | FOREIGN KEY → users(id) |
| `intake_staff_name` | VARCHAR(255) | Tên nhân viên nhận hàng | |
| `received_at` | TIMESTAMP | Thời gian nhận hàng vào kho | |
| **Timestamp** | | | |
| `created_at` | TIMESTAMP | Thời gian tạo đơn | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Thời gian cập nhật | DEFAULT NOW() |

**Index:**
- `idx_orders_user_id` trên `user_id`
- `idx_orders_status` trên `status`
- `idx_orders_created_at` trên `created_at`

**Các trạng thái đơn hàng (`status`):**
- `pending` - Chờ xác nhận
- `confirmed` - Đã xác nhận
- `warehouse_received` - Đã nhận vào kho
- `preparing` - Đang chuẩn bị
- `ready_for_pickup` - Sẵn sàng lấy hàng
- `picked_up` - Đã lấy hàng
- `in_transit` - Đang giao
- `delivered` - Đã giao
- `cancelled` - Đã hủy
- `returned` - Đã trả lại

---

## 3️⃣ **Table: `order_status_history`** - Lịch sử trạng thái đơn hàng

**Mô tả:** Ghi lại mọi thay đổi trạng thái của đơn hàng

| Cột | Kiểu dữ liệu | Mô tả | Ràng buộc |
|-----|-------------|-------|-----------|
| `id` | SERIAL | ID | PRIMARY KEY |
| `order_id` | INTEGER | ID đơn hàng | FOREIGN KEY → orders(id) |
| `status` | VARCHAR(50) | Trạng thái mới | NOT NULL |
| `notes` | TEXT | Ghi chú về thay đổi | |
| `created_at` | TIMESTAMP | Thời gian thay đổi | DEFAULT NOW() |

---

## 4️⃣ **Table: `delivery_tracking`** - Theo dõi giao hàng

**Mô tả:** Lưu vị trí thời gian thực của tài xế khi giao hàng

| Cột | Kiểu dữ liệu | Mô tả | Ràng buộc |
|-----|-------------|-------|-----------|
| `id` | SERIAL | ID | PRIMARY KEY |
| `order_id` | INTEGER | ID đơn hàng | FOREIGN KEY → orders(id) |
| `shipper_id` | INTEGER | ID tài xế | FOREIGN KEY → users(id) |
| `latitude` | DECIMAL(10,8) | Vĩ độ | |
| `longitude` | DECIMAL(11,8) | Kinh độ | |
| `address` | TEXT | Địa chỉ hiện tại | |
| `status` | VARCHAR(50) | Trạng thái giao hàng | DEFAULT 'preparing' |
| `created_at` | TIMESTAMP | Thời gian tạo | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Thời gian cập nhật | DEFAULT NOW() |

**Index:**
- `idx_delivery_tracking_order_id` trên `order_id`

---

## 5️⃣ **Table: `notifications`** - Thông báo

**Mô tả:** Lưu tất cả thông báo của người dùng

**File migration:** `backend/scripts/migrate_notifications.sql`

| Cột | Kiểu dữ liệu | Mô tả | Ràng buộc |
|-----|-------------|-------|-----------|
| `id` | SERIAL | ID | PRIMARY KEY |
| `user_id` | INTEGER | ID người nhận | FOREIGN KEY → users(id) |
| `title` | VARCHAR(255) | Tiêu đề thông báo | NOT NULL |
| `body` | TEXT | Nội dung | NOT NULL |
| `type` | VARCHAR(50) | Loại: `general`, `order`, `payment`, `driver`, `system` | DEFAULT 'general' |
| `reference_id` | INTEGER | ID tham chiếu (order_id, ...) | |
| `data` | JSONB | Dữ liệu bổ sung (JSON) | DEFAULT '{}' |
| `is_read` | BOOLEAN | Đã đọc chưa | DEFAULT false |
| `read_at` | TIMESTAMP | Thời gian đọc | |
| `created_at` | TIMESTAMP | Thời gian tạo | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Thời gian cập nhật | DEFAULT NOW() |

**Index:**
- `idx_notifications_user_id` trên `user_id`
- `idx_notifications_is_read` trên `is_read`
- `idx_notifications_type` trên `type`
- `idx_notifications_created_at` trên `created_at`
- `idx_notifications_user_is_read` trên `(user_id, is_read)`

---

## 6️⃣ **Table: `complaints`** - Khiếu nại

**Mô tả:** Lưu các khiếu nại/phản hồi của khách hàng

**File migration:** `backend/scripts/migrate_complaints.sql`

| Cột | Kiểu dữ liệu | Mô tả | Ràng buộc |
|-----|-------------|-------|-----------|
| `id` | SERIAL | ID | PRIMARY KEY |
| `user_id` | INTEGER | ID người khiếu nại | FOREIGN KEY → users(id) |
| `order_id` | INTEGER | ID đơn hàng liên quan | FOREIGN KEY → orders(id) |
| `complaint_type` | VARCHAR(50) | Loại khiếu nại | NOT NULL, CHECK constraint |
| `subject` | VARCHAR(255) | Tiêu đề | NOT NULL |
| `description` | TEXT | Mô tả chi tiết | NOT NULL |
| `priority` | VARCHAR(20) | Độ ưu tiên: `low`, `medium`, `high`, `urgent` | DEFAULT 'medium' |
| `status` | VARCHAR(20) | Trạng thái: `open`, `in_progress`, `resolved`, `closed` | DEFAULT 'open' |
| `evidence_images` | JSONB | Hình ảnh bằng chứng (JSON array) | DEFAULT '[]' |
| `resolution_note` | TEXT | Ghi chú giải quyết | |
| `resolved_at` | TIMESTAMP | Thời gian giải quyết | |
| `resolved_by` | INTEGER | Người giải quyết | FOREIGN KEY → users(id) |
| `created_at` | TIMESTAMP | Thời gian tạo | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Thời gian cập nhật | DEFAULT NOW() |

**Loại khiếu nại (`complaint_type`):**
- `product_issue` - Vấn đề về hàng hóa
- `delivery_issue` - Vấn đề giao hàng
- `driver_issue` - Vấn đề tài xế
- `payment_issue` - Vấn đề thanh toán
- `service_issue` - Vấn đề dịch vụ
- `other` - Khác

**Index:**
- `idx_complaints_user_id` trên `user_id`
- `idx_complaints_order_id` trên `order_id`
- `idx_complaints_status` trên `status`
- `idx_complaints_priority` trên `priority`
- `idx_complaints_created_at` trên `created_at`

---

## 7️⃣ **Table: `complaint_responses`** - Phản hồi khiếu nại

**Mô tả:** Lưu lịch sử hội thoại của khiếu nại

| Cột | Kiểu dữ liệu | Mô tả | Ràng buộc |
|-----|-------------|-------|-----------|
| `id` | SERIAL | ID | PRIMARY KEY |
| `complaint_id` | INTEGER | ID khiếu nại | FOREIGN KEY → complaints(id) |
| `user_id` | INTEGER | ID người trả lời | FOREIGN KEY → users(id) |
| `user_role` | VARCHAR(20) | Vai trò: `customer`, `admin`, `intake_staff`, `driver` | NOT NULL |
| `message` | TEXT | Nội dung tin nhắn | NOT NULL |
| `attachments` | JSONB | File đính kèm (JSON array) | DEFAULT '[]' |
| `created_at` | TIMESTAMP | Thời gian gửi | DEFAULT NOW() |

**Index:**
- `idx_complaint_responses_complaint_id` trên `complaint_id`
- `idx_complaint_responses_created_at` trên `created_at`

---

## 🔧 Cách chạy Migration

### **Để tạo tables `notifications` và `complaints`:**

```bash
# Kết nối vào PostgreSQL
psql -U postgres -d food_delivery_db

# Chạy script SQL
\i backend/scripts/migrate_notifications.sql
\i backend/scripts/migrate_complaints.sql
```

**Hoặc trong pgAdmin4:**
1. Chọn database `food_delivery_db`
2. Click chuột phải → **Query Tool**
3. Mở file `.sql` và Execute (F5)

---

## 🔍 Các câu lệnh SQL hữu ích

### **Xem tất cả tables:**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

### **Xem cấu trúc một table:**
```sql
SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users';
```

### **Xem số lượng records:**
```sql
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM notifications;
```

### **Xem user và role:**
```sql
SELECT id, email, full_name, role, created_at 
FROM users 
ORDER BY created_at DESC;
```

### **Xem đơn hàng gần đây:**
```sql
SELECT id, order_number, status, total_amount, created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;
```

### **Xem khiếu nại đang mở:**
```sql
SELECT c.*, u.full_name as user_name, o.order_number
FROM complaints c
JOIN users u ON c.user_id = u.id
JOIN orders o ON c.order_id = o.id
WHERE c.status IN ('open', 'in_progress')
ORDER BY c.priority DESC, c.created_at DESC;
```

---

## 📊 Sơ đồ quan hệ (ERD)

```
users (1) ----< (N) orders
users (1) ----< (N) notifications
users (1) ----< (N) complaints
orders (1) ----< (N) order_status_history
orders (1) ----< (1) delivery_tracking
orders (1) ----< (N) complaints
complaints (1) ----< (N) complaint_responses
```

---

## 🎯 Lưu ý quan trọng

1. **Tables tự động tạo:** Các bảng `users`, `orders`, `order_status_history`, `delivery_tracking` được tạo tự động khi backend khởi động

2. **Migration thủ công:** Bảng `notifications` và `complaints` cần chạy migration SQL thủ công

3. **Backup database:**
```bash
pg_dump -U postgres food_delivery_db > backup.sql
```

4. **Restore database:**
```bash
psql -U postgres food_delivery_db < backup.sql
```

5. **Connection pooling:** Backend sử dụng connection pool với max 20 connections

---

## 📞 Hỗ trợ

Nếu có vấn đề với database:
1. Check backend logs khi khởi động
2. Kiểm tra kết nối trong pgAdmin4
3. Verify credentials trong `backend/config.env`
4. Check PostgreSQL service đang chạy: `services.msc`
