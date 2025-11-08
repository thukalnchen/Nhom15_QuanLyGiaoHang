# 🧪 HƯỚNG DẪN TEST END-TO-END (App User → App Intake)

## 📋 Tổng quan

Test flow hoàn chỉnh từ khách hàng đặt hàng (app_user) đến nhân viên kho xử lý (app_intake).

```
Customer (app_user)
    ↓ Đặt hàng
Backend (PostgreSQL)
    ↓ Status: pending
Intake Staff (app_intake)
    ↓ Nhận → Phân loại → Phân tài xế
Driver (app_driver)
```

---

## 🚀 CHUẨN BỊ

### 1. Backend phải đang chạy
```bash
cd backend
npm start
```
✅ Server running tại `http://localhost:3000`

### 2. Database có sẵn:
- ✅ User account (customer)
- ✅ Intake staff account
- ✅ Driver account (cho assignment)

### 3. Tạo accounts nếu chưa có:

#### Customer Account:
```sql
-- Register qua app_user hoặc:
INSERT INTO users (email, password, full_name, phone, role)
VALUES (
  'customer@test.com',
  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5mYT5o7RBPfhe', -- password: test123
  'Test Customer',
  '0909123456',
  'customer'
);
```

#### Intake Staff (đã có):
- Email: `staff@intake.com`
- Password: `staff123`

#### Driver Account (nếu chưa có):
```bash
cd backend
node scripts/create-test-driver.js
```

---

## 📱 BƯỚC 1: ĐẶT HÀNG (App User)

### 1.1. Chạy app_user
```bash
cd app_user
flutter run -d chrome
# Hoặc
flutter run -d emulator-5554  # Android
```

### 1.2. Login
- Email: `customer@test.com`
- Password: `test123`

### 1.3. Tạo đơn hàng mới
1. Vào màn hình "Đặt hàng" / "New Order"
2. Điền thông tin:
   - **Restaurant name**: "Gà Rán KFC"
   - **Items**: 
     - Gà rán: 2 x 50,000đ
     - Pepsi: 1 x 15,000đ
   - **Total amount**: 115,000đ
   - **Delivery address**: "123 Nguyễn Văn Linh, Q7, TP.HCM"
   - **Phone**: "0909123456"
   - **Notes**: "Giao trước 12h"

3. **QUAN TRỌNG**: Thêm Customer Estimates (nếu có trong form):
   - **Estimated size**: Medium
   - **Requested vehicle**: Bike
   - **Estimated weight**: 2kg
   - **Special notes**: "Hàng dễ vỡ"

4. **Submit** → Đơn hàng được tạo với:
   - Status: `pending`
   - Order number: `ORD-1699XXXXX-ABCD1234`

5. **LƯU LẠI ORDER NUMBER** để test!

---

## 🏪 BƯỚC 2: XỬ LÝ TẠI KHO (App Intake)

### 2.1. Chạy app_intake
```bash
cd app_intake
flutter run -d chrome
# Hoặc chạy trên emulator/device khác
```

### 2.2. Login
- Email: `staff@intake.com`
- Password: `staff123`

### 2.3. Kiểm tra Dashboard
1. Vào **Tab "Tổng quan"**
2. Xem statistics:
   - ✅ "Đơn chờ nhận" phải có số > 0
   - ✅ Đơn hàng vừa tạo phải hiển thị

3. Pull-to-refresh nếu không thấy

---

### 2.4. Story #8: SCAN & RECEIVE

#### Option A: Quét QR Code
1. Tap **FloatingActionButton** (icon QR scanner)
2. **Scan Screen** mở ra
3. Quét QR code của order number
   - Hoặc nhập manual: `ORD-1699XXXXX-ABCD1234`
4. Auto navigate → **Order Intake Screen**

#### Option B: Từ danh sách orders
1. Vào **Tab "Đơn hàng"**
2. Tìm order vừa tạo (status: pending)
3. Tap vào order
4. Navigate → **Order Intake Screen**

#### Điền thông tin gói hàng:
1. **Customer Estimates** hiển thị (nếu có):
   - Size: Medium
   - Vehicle: Bike
   - Weight: 2kg
   - Notes: "Hàng dễ vỡ"

2. **Nhập thông tin THỰC TẾ**:
   - **Cân nặng**: 2.5 kg
   - **Kích thước**: Medium
   - **Loại hàng**: Food
   - **Ghi chú**: "Đã kiểm tra kỹ"

3. **Upload ảnh** (tối đa 4):
   - Chụp ảnh gói hàng từ nhiều góc
   - Hoặc chọn từ thư viện

4. **Xác nhận nhận hàng**
   - Tap "Xác nhận nhận hàng"
   - ✅ Success message
   - ✅ Navigate back
   - ✅ Status: `pending` → `received_at_warehouse`

#### Verify:
- Vào **Tab "Kho hàng" → "Đã nhận"**
- ✅ Order hiển thị trong tab này
- ✅ Status badge: "Đã nhận tại kho"

---

### 2.5. Story #9: CLASSIFICATION

1. Từ **Tab "Kho hàng" → "Đã nhận"**
2. Tap vào order vừa nhận
3. Navigate → **Classification Screen**

#### Xem thông tin tự động:
- ✅ **Khoảng cách**: 12.5 km (auto-calculated)
- ✅ **Phí giao hàng**: 35,000đ (auto-calculated)
- ✅ **Khu vực**: zone_2 (5-15km)
- ✅ **Xe đề xuất**: Bike

#### So sánh với Customer Request:
- Customer requested: Bike
- System suggest: Bike
- ✅ Match! (Màu xanh)

#### Phân loại:
1. Nếu đồng ý với suggest:
   - Tap "Xác nhận phân loại"
   
2. Nếu muốn override:
   - Chọn zone khác: zone_3
   - Chọn xe khác: Car
   - ⚠️ Warning dialog: "Khác với gợi ý và yêu cầu khách hàng"
   - Confirm override

3. **Submit**
   - ✅ Success message
   - ✅ Status: `received_at_warehouse` → `classified`

#### Verify:
- Vào **Tab "Kho hàng" → "Đã phân loại"**
- ✅ Order hiển thị trong tab này
- ✅ Zone & Vehicle info hiển thị

---

### 2.6. Story #21: DRIVER ASSIGNMENT

1. Từ **Tab "Kho hàng" → "Đã phân loại"**
2. Tap vào order vừa phân loại
3. Navigate → **Assignment Screen**

#### Xem danh sách drivers:
- ✅ Chỉ hiển thị drivers có vehicle_type = "bike"
- ✅ Driver cards với thông tin:
  - Tên: "Nguyễn Văn A"
  - Phone: "0909888777"
  - Vehicle: Bike - 59A12345
  - Rating: ★★★★★ 4.8

#### Chọn driver:
1. Tap radio button chọn driver
2. Tap "Phân tài xế"
3. Confirm dialog
4. **Submit**
   - ✅ Success message
   - ✅ Status: `classified` → `ready_for_pickup` → `assigned_to_driver`

#### Verify:
- Vào **Tab "Kho hàng" → "Sẵn sàng giao"**
- ✅ Order hiển thị trong tab này
- ✅ Driver info hiển thị
- ✅ Status: "Đã phân tài xế"

---

## ✅ VERIFY HOÀN CHỈNH

### 1. Kiểm tra Dashboard
- Vào **Tab "Tổng quan"**
- Statistics đã cập nhật:
  - Đơn chờ nhận: -1
  - Đơn đã phân loại: -1
  - Đơn sẵn sàng giao: +1

### 2. Kiểm tra Database
```sql
SELECT 
  order_number,
  status,
  actual_weight,
  actual_size,
  delivery_zone,
  suggested_vehicle_type,
  assigned_driver_id
FROM orders
WHERE order_number = 'ORD-1699XXXXX-ABCD1234';
```

Kết quả mong đợi:
```
order_number          | ORD-1699XXXXX-ABCD1234
status                | assigned_to_driver
actual_weight         | 2.5
actual_size           | medium
delivery_zone         | zone_2
suggested_vehicle_type| bike
assigned_driver_id    | 3
```

### 3. Kiểm tra Order History
```sql
SELECT status, created_at, notes
FROM order_status_history
WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-1699XXXXX-ABCD1234')
ORDER BY created_at;
```

Kết quả mong đợi:
```
status                  | created_at           | notes
------------------------|----------------------|-------------------
pending                 | 2025-11-08 10:00:00  | Order created
received_at_warehouse   | 2025-11-08 10:05:00  | Received at warehouse
classified              | 2025-11-08 10:10:00  | Classified
assigned_to_driver      | 2025-11-08 10:15:00  | Assigned to driver
```

---

## 🎯 CHECKLIST CUỐI CÙNG

### App User ✅
- [x] Login thành công
- [x] Tạo đơn hàng với customer estimates
- [x] Nhận order number
- [x] Order status = pending

### App Intake ✅
- [x] Login thành công
- [x] Order hiển thị trong dashboard
- [x] Scan QR / Tìm order
- [x] Nhập thông tin thực tế
- [x] Upload ảnh
- [x] Nhận hàng → Status: received_at_warehouse
- [x] Phân loại → Auto calculate → Status: classified
- [x] Phân tài xế → Select driver → Status: assigned_to_driver

### Database ✅
- [x] Order status updated correctly
- [x] Order history recorded
- [x] All warehouse fields populated:
  - actual_weight, actual_size, actual_package_type
  - delivery_zone, delivery_distance, calculated_delivery_fee
  - suggested_vehicle_type
  - assigned_driver_id
  - received_at_warehouse_at
  - classified_at

---

## 🐛 TROUBLESHOOTING

### Vấn đề 1: Order không hiển thị trong app_intake
**Nguyên nhân**:
- Backend không chạy
- API URL khác nhau giữa app_user và app_intake
- Token expired

**Giải pháp**:
```bash
# Kiểm tra backend
curl http://localhost:3000/api/warehouse/orders

# Kiểm tra constants
# app_user/lib/utils/constants.dart
# app_intake/lib/utils/constants.dart
# Đảm bảo cùng baseUrl
```

### Vấn đề 2: Không quét được QR
**Nguyên nhân**:
- Web không support camera
- Quyền camera bị deny

**Giải pháp**:
- Dùng manual input
- Test trên mobile device/emulator
- Check browser permissions

### Vấn đề 3: Driver list rỗng
**Nguyên nhân**:
- Chưa có driver trong database
- Driver vehicle_type không match

**Giải pháp**:
```bash
cd backend
node scripts/create-test-driver.js
```

### Vấn đề 4: API lỗi 401 Unauthorized
**Nguyên nhân**:
- Token expired
- Token không đúng format

**Giải pháp**:
- Logout và login lại
- Check Bearer token trong API calls

---

## 📊 EXPECTED RESULTS

### Timeline hoàn chỉnh:
```
T+0:00  Customer đặt hàng (app_user)
        → Status: pending

T+0:05  Staff scan QR (app_intake)
        → Navigate to Order Intake

T+0:10  Staff nhập info + upload ảnh
        → Submit receive
        → Status: received_at_warehouse

T+0:15  Staff phân loại
        → Auto calculate zone/vehicle
        → Submit classify
        → Status: classified

T+0:20  Staff phân tài xế
        → Load available drivers
        → Select + assign
        → Status: assigned_to_driver

T+0:25  Driver nhận việc (app_driver)
        → Pickup → Delivering → Delivered
```

### Data flow:
```
app_user (Frontend)
    ↓ POST /api/orders
Backend (API)
    ↓ INSERT orders (status: pending)
PostgreSQL (Database)
    ↓ GET /api/warehouse/orders
app_intake (Frontend)
    ↓ POST /api/warehouse/receive
    ↓ POST /api/warehouse/classify
    ↓ POST /api/warehouse/assign
PostgreSQL (Database)
    ↓ UPDATE orders (status: assigned_to_driver)
app_driver (Frontend)
```

---

## 🎉 KẾT LUẬN

Nếu tất cả các bước trên hoạt động tốt:
- ✅ **Flow hoàn chỉnh từ customer → intake → driver**
- ✅ **Tất cả features core đã sẵn sàng**
- ✅ **Database sync đúng giữa 2 apps**
- ✅ **Ready for production!**

**Next steps**:
1. Test nhiều orders khác nhau
2. Test edge cases (orders không hợp lệ, driver không có sẵn)
3. Test concurrent users
4. Performance testing
5. Deploy to staging environment

---

**Được tạo bởi**: Team 15
**Ngày**: November 8, 2025
**Version**: 1.0.0
