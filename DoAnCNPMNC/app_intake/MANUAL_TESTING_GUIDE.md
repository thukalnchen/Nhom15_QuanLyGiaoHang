# 🧪 Hướng Dẫn Test Manual - App Intake

## 📋 Prerequisites

### 1. Backend Running
```bash
cd backend
npm start
```
✅ Backend phải chạy ở `http://localhost:3000`

### 2. Database Ready
✅ Database đã có:
- 13 warehouse columns (migration done)
- Test orders với customer estimates
- Test driver account

### 3. Flutter App Config
Kiểm tra `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
// hoặc
static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android Emulator
```

---

## 🚀 Test Plan

### Test 1️⃣: Story #8 - Scan QR & Order Intake

#### Chuẩn bị:
1. Tạo test order trong database:
```bash
cd backend
node scripts/test-warehouse-flow.js
```
Hoặc tạo order qua app_user với customer estimates

2. Có QR code của order (order_number)

#### Steps:
1. **Mở app_intake** → Login với tài khoản intake staff
2. **Màn Home** → Tap "Quét QR"
3. **Scan Screen**:
   - ✅ Camera hiển thị
   - ✅ Overlay với khung scan hiển thị
   - ✅ Hướng dẫn "Di chuyển mã QR vào khung" hiển thị

4. **Quét QR code** (hoặc nhập order number thủ công):
   - ✅ App tự động tìm order
   - ✅ Navigate to Order Intake Screen

5. **Order Intake Screen**:
   - ✅ Order info hiển thị (pickup, delivery, recipient)
   - ✅ **Customer Estimates Card** (màu xanh) hiển thị:
     ```
     📦 Thông tin ước tính từ khách hàng:
     - Kích thước gói hàng: Medium
     - Loại xe yêu cầu: Xe ô tô
     💡 Thông tin trên chỉ mang tính tham khảo
     ```
   - ✅ Form nhập thông tin đã pre-fill với customer estimated size
   - ✅ Có thể chọn ảnh (4 photos max)
   - ✅ Nút "Xác nhận tiếp nhận" active khi đủ thông tin

6. **Xác nhận**:
   - Nhập/confirm package size, type, weight, description
   - Tap "Xác nhận tiếp nhận"
   - ✅ Loading indicator hiển thị
   - ✅ Success message "Đã tiếp nhận đơn hàng"
   - ✅ Navigate back to home/warehouse screen

7. **Verify in Database**:
```sql
SELECT order_number, status, warehouse_id, warehouse_name, 
       intake_staff_id, intake_staff_name, received_at,
       customer_estimated_size, customer_requested_vehicle
FROM orders 
WHERE order_number = 'TEST-xxx';
```
   - ✅ `status` = 'received_at_warehouse'
   - ✅ `warehouse_id`, `warehouse_name` filled
   - ✅ `intake_staff_id`, `intake_staff_name` filled
   - ✅ `received_at` = current timestamp
   - ✅ Customer estimates preserved

#### Expected Results:
- ✅ QR scan works smoothly
- ✅ Customer estimates displayed clearly with disclaimer
- ✅ Staff can confirm or override estimates
- ✅ Order status changes to 'received_at_warehouse'
- ✅ All warehouse fields populated

---

### Test 2️⃣: Story #9 - Classification

#### Chuẩn bị:
- Order đã received (status = 'received_at_warehouse')
- Order có customer_requested_vehicle

#### Steps:
1. **Warehouse Screen** → Tab "Cần phân loại"
   - ✅ List hiển thị orders có status = 'received_at_warehouse'
   - ✅ Mỗi order card hiển thị:
     - Order number, addresses
     - Package size badge
     - Customer estimated size (if available)
     - "Phân loại ngay" button

2. **Tap "Phân loại ngay"** trên 1 order:
   - ✅ Navigate to Classification Screen
   - ✅ Order info hiển thị ở trên

3. **Classification Screen**:
   - ✅ **Distance calculation** tự động (mock 12.5 km)
   - ✅ **Auto-suggest Zone**:
     - < 5km → Zone 1
     - 5-10km → Zone 2
     - 10-20km → Zone 3
     - > 20km → Zone 4
   - ✅ **Auto-suggest Vehicle** based on:
     - Package size (small/medium/large/extra_large)
     - Distance
   - ✅ **Customer Request Card** hiển thị:
     ```
     🚗 Khách hàng yêu cầu: Xe ô tô
     💡 Hệ thống đề xuất: Xe ô tô
     ```

4. **Scenario A: Match Customer Request**:
   - System suggests same vehicle as customer
   - ✅ No warning message
   - Tap "Xác nhận phân loại"
   - ✅ Success message
   - ✅ Navigate back

5. **Scenario B: Override Customer Request**:
   - Change vehicle to different type (e.g., bike instead of car)
   - Tap "Xác nhận phân loại"
   - ✅ **Confirmation Dialog** appears:
     ```
     ⚠️ Thay đổi loại xe
     Bạn đang chọn xe khác với yêu cầu của khách hàng.
     Phí giao hàng có thể thay đổi.
     ```
   - ✅ Can cancel or confirm
   - Tap "Xác nhận"
   - ✅ Success message

6. **Verify in Database**:
```sql
SELECT order_number, status, zone, recommended_vehicle, classified_at,
       customer_requested_vehicle
FROM orders 
WHERE order_number = 'TEST-xxx';
```
   - ✅ `status` = 'classified'
   - ✅ `zone` = 'zone_3'
   - ✅ `recommended_vehicle` filled
   - ✅ `classified_at` = current timestamp

#### Expected Results:
- ✅ Auto-suggestion works correctly
- ✅ Customer request comparison shown
- ✅ Override warning appears when needed
- ✅ Order status changes to 'classified'
- ✅ Zone and vehicle assigned

---

### Test 3️⃣: Story #21 - Driver Assignment

#### Chuẩn bị:
- Order đã classified (status = 'classified', có recommended_vehicle)
- Database có test driver:
```sql
INSERT INTO users (full_name, phone, email, password, role)
VALUES ('Nguyễn Tài Xế Test', '0923456789', 'driver@test.com', 'hashed', 'driver');
```

#### Steps:
1. **Warehouse Screen** → Tab "Đã phân loại"
   - ✅ List hiển thị orders có status = 'classified'
   - ✅ Mỗi order card hiển thị:
     - Order number, addresses
     - Zone badge (colored)
     - Recommended vehicle icon
     - "Phân tài xế" button

2. **Tap "Phân tài xế"** trên 1 order:
   - ✅ Navigate to Assignment Screen
   - ✅ Order info hiển thị ở trên
   - ✅ Recommended vehicle hiển thị

3. **Assignment Screen - Loading**:
   - ✅ Loading indicator while fetching drivers
   - ✅ Loading message "Đang tìm tài xế phù hợp..."

4. **Assignment Screen - Driver List**:
   - ✅ List drivers filtered by `vehicle_type = recommended_vehicle`
   - ✅ Each driver card shows:
     - Avatar (placeholder hoặc real)
     - Driver name
     - Phone number
     - Vehicle type icon
     - Current orders badge (if > 0)
   - ✅ Empty state if no drivers: "Không có tài xế phù hợp"

5. **Select Driver**:
   - Tap on a driver card
   - ✅ Card highlights (blue border + background)
   - ✅ Check icon appears
   - ✅ Can select only 1 driver at a time
   - ✅ "Phân công" button becomes enabled

6. **Assign Driver**:
   - Tap "Phân công"
   - ✅ **Confirmation Dialog** appears:
     ```
     Xác nhận phân công
     Phân đơn hàng TEST-xxx cho Nguyễn Tài Xế Test?
     ```
   - Tap "Xác nhận"
   - ✅ Loading indicator during API call
   - ✅ Success message "Đã phân công tài xế"
   - ✅ Navigate back to Warehouse Screen

7. **Verify in Warehouse Screen**:
   - Tab "Đã phân loại": Order không còn trong list
   - Tab "Sẵn sàng": Order xuất hiện trong list
   - ✅ Order shows driver info

8. **Verify in Database**:
```sql
SELECT order_number, status, user_id, vehicle_type
FROM orders 
WHERE order_number = 'TEST-xxx';
```
   - ✅ `status` = 'assigned_to_driver'
   - ✅ `user_id` = driver's ID
   - ✅ `vehicle_type` = driver's vehicle type

#### Expected Results:
- ✅ Driver filtering by vehicle type works
- ✅ Driver cards display correctly
- ✅ Selection state works (highlight + check)
- ✅ Assignment confirmation dialog works
- ✅ Order status changes to 'assigned_to_driver'
- ✅ Order moves to "Sẵn sàng" tab

---

## 🔄 End-to-End Flow Test

### Complete Workflow:
```
1. Create order with estimates (app_user or script)
   ↓
2. Scan QR → Receive at warehouse (Story #8)
   ↓ Status: pending → received_at_warehouse
3. Classify → Auto-suggest zone/vehicle (Story #9)
   ↓ Status: received_at_warehouse → classified
4. Assign driver (Story #21)
   ↓ Status: classified → assigned_to_driver
   ✅ Complete!
```

### Steps:
1. **Create Order** (via backend script):
```bash
cd backend
node scripts/test-warehouse-flow.js
```
Note order number: `TEST-xxx`

2. **App Intake - Scan & Receive**:
   - Scan QR → Order Intake Screen
   - Verify customer estimates displayed
   - Confirm receipt
   - ✅ Order moves to "Cần phân loại" tab

3. **Classify**:
   - From "Cần phân loại" tab → Tap "Phân loại ngay"
   - Verify auto-suggestions
   - Confirm classification
   - ✅ Order moves to "Đã phân loại" tab

4. **Assign Driver**:
   - From "Đã phân loại" tab → Tap "Phân tài xế"
   - Select driver
   - Confirm assignment
   - ✅ Order moves to "Sẵn sàng" tab

5. **Final Verification**:
```sql
SELECT 
  order_number, 
  status,
  customer_estimated_size,
  customer_requested_vehicle,
  warehouse_name,
  intake_staff_name,
  received_at,
  zone,
  recommended_vehicle,
  classified_at,
  user_id,
  vehicle_type
FROM orders 
WHERE order_number = 'TEST-xxx';
```

Expected:
```
✅ status = 'assigned_to_driver'
✅ All warehouse fields populated
✅ Customer estimates preserved
✅ Zone and vehicle assigned
✅ Driver assigned
✅ All timestamps recorded
```

---

## 🐛 Common Issues & Fixes

### Issue 1: "Connection refused"
**Cause:** Backend không chạy hoặc URL sai

**Fix:**
1. Start backend: `cd backend && npm start`
2. Check `api_service.dart` baseUrl
3. Android emulator: use `10.0.2.2` instead of `localhost`

### Issue 2: "Order not found"
**Cause:** Order chưa tồn tại hoặc đã có status khác 'pending'

**Fix:**
1. Create new test order
2. Check order status in database
3. Reset order: `UPDATE orders SET status = 'pending' WHERE order_number = 'TEST-xxx'`

### Issue 3: "No drivers available"
**Cause:** Không có driver với vehicle_type phù hợp

**Fix:**
1. Create test driver:
```sql
INSERT INTO users (full_name, phone, email, password, role)
VALUES ('Test Driver', '0999999999', 'driver@test.com', 'hashed', 'driver');
```

### Issue 4: QR Scanner không hoạt động
**Cause:** Camera permissions chưa được cấp

**Fix:**
1. Check `AndroidManifest.xml` có permission CAMERA
2. Request runtime permission
3. Test trên real device (emulator có thể không support camera)

### Issue 5: Customer estimates không hiển thị
**Cause:** Order chưa có customer_estimated_size/customer_requested_vehicle

**Fix:**
1. Create order với estimates:
```sql
UPDATE orders 
SET customer_estimated_size = 'medium',
    customer_requested_vehicle = 'car'
WHERE order_number = 'TEST-xxx';
```

---

## 📊 Test Checklist

### Story #8: Scan & Receive
- [ ] QR scanner works
- [ ] Manual order search works
- [ ] Customer estimates card displays
- [ ] Form validation works
- [ ] Image picker works (4 photos)
- [ ] Submit button enabled/disabled correctly
- [ ] API call successful
- [ ] Success message shown
- [ ] Navigation back works
- [ ] Database updated correctly

### Story #9: Classification
- [ ] "Cần phân loại" tab shows correct orders
- [ ] Classification screen navigation works
- [ ] Distance calculation works
- [ ] Zone auto-suggestion correct (4 tiers)
- [ ] Vehicle auto-suggestion correct
- [ ] Customer request comparison shown
- [ ] Override warning appears when needed
- [ ] Confirmation dialog works
- [ ] API call successful
- [ ] Success message shown
- [ ] Database updated correctly
- [ ] Order moves to "Đã phân loại" tab

### Story #21: Driver Assignment
- [ ] "Đã phân loại" tab shows correct orders
- [ ] Assignment screen navigation works
- [ ] Driver list loads correctly
- [ ] Vehicle filtering works
- [ ] Driver cards display all info
- [ ] Empty state shows if no drivers
- [ ] Selection state works (highlight + check)
- [ ] Only one driver selectable
- [ ] "Phân công" button state correct
- [ ] Confirmation dialog works
- [ ] API call successful
- [ ] Success message shown
- [ ] Database updated correctly
- [ ] Order moves to "Sẵn sàng" tab

### End-to-End Flow
- [ ] Complete workflow: pending → received → classified → assigned
- [ ] All status transitions work
- [ ] All data preserved through workflow
- [ ] Customer estimates visible at each step
- [ ] All timestamps recorded
- [ ] No data loss
- [ ] UI smooth and responsive

---

## 🎯 Performance Checks

- [ ] App launches in < 3 seconds
- [ ] QR scan responds in < 1 second
- [ ] Order search responds in < 2 seconds
- [ ] Driver list loads in < 2 seconds
- [ ] API calls complete in < 3 seconds
- [ ] No memory leaks (test with multiple cycles)
- [ ] No crashes during normal flow
- [ ] Handles network errors gracefully

---

## 📱 Device Testing

### Recommended Test Devices:
- [ ] Android Emulator (API 30+)
- [ ] Real Android device
- [ ] iOS Simulator (optional)
- [ ] Real iOS device (optional)

### Network Conditions:
- [ ] WiFi connection
- [ ] Mobile data (if available)
- [ ] Slow 3G (simulate)
- [ ] Offline mode (error handling)

---

## ✅ Sign-Off

**Tested by:** _______________  
**Date:** _______________  
**Result:** [ ] PASS / [ ] FAIL  

**Notes:**
_____________________________________________
_____________________________________________
_____________________________________________

---

## 🚀 Ready for Production?

All tests passed? Congratulations! 🎉

**Deployment Checklist:**
- [ ] All manual tests passed
- [ ] Backend tests passed
- [ ] Database migrations applied
- [ ] API endpoints documented
- [ ] Environment variables configured
- [ ] Error handling tested
- [ ] Performance acceptable
- [ ] Security review done
- [ ] User documentation ready

**Next Steps:**
1. Deploy backend to production server
2. Update `api_service.dart` with production URL
3. Build release APK/IPA
4. Test on production environment
5. Train staff on new features
6. Monitor for issues

🎉 **Good luck with your deployment!**
