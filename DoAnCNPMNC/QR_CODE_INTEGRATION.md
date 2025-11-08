# 📱 TÍCH HỢP QR CODE - HỆ THỐNG GIAO HÀNG

## 🎯 MỤC ĐÍCH
QR Code giúp nhân viên kho scan nhanh chóng để nhận hàng, tránh nhập sai mã đơn hàng.

---

## ✅ ĐÃ TÍCH HỢP

### **1. APP_USER - Hiển thị QR Code** 📱

#### **A. Package đã thêm:**
```yaml
dependencies:
  qr_flutter: ^4.1.0  # Generate QR codes
```

#### **B. Màn hình hiển thị:**
- **File:** `app_user/lib/screens/orders/order_details_screen.dart`
- **Vị trí:** Section "Mã QR đơn hàng" (sau "Thông tin đơn hàng")

#### **C. Cách hoạt động:**

1. **Khách hàng tạo đơn hàng** (LalamoveOrderSummaryScreen)
   ```
   - Điền thông tin
   - Bấm "Xác nhận đặt hàng"
   - Backend tạo order với order_number unique
   - VD: "ORD-1730885678901-A1B2C3D4"
   ```

2. **Xem đơn hàng** (OrdersScreen)
   ```
   - Tab "Đơn hàng"
   - Tap vào đơn hàng
   - Mở OrderDetailsScreen
   ```

3. **QR Code tự động hiển thị**
   ```
   ┌────────────────────────────────┐
   │  📋 Thông tin đơn hàng         │
   │  Mã đơn: ORD-1730...           │
   │  Thời gian: 08/11/2025         │
   └────────────────────────────────┘
   
   ┌────────────────────────────────┐
   │  📱 Mã QR đơn hàng             │
   │  ┌──────────────────────┐      │
   │  │                      │      │
   │  │    ███▀▀███ ▀██     │      │
   │  │    █ ▀▀▀ █ ▄▀▄      │      │
   │  │    █ ███ █ ██▀      │      │
   │  │    ▀▀▀▀▀▀▀ █ █      │      │
   │  │    QR CODE HERE      │      │
   │  │                      │      │
   │  └──────────────────────┘      │
   │                                │
   │  ORD-1730885678901-A1B2C3D4    │
   │  📱 Quét mã này tại kho        │
   │     để nhận hàng               │
   └────────────────────────────────┘
   ```

#### **D. Code implementation:**

```dart
// QR Code Section - For warehouse staff to scan
_buildSection(
  title: 'Mã QR đơn hàng',
  icon: Icons.qr_code_2,
  child: Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: QrImageView(
          data: order['order_code'] ?? order['order_number'] ?? '',
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.H, // High error correction
        ),
      ),
      const SizedBox(height: 12),
      // Order code text display
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          order['order_code'] ?? order['order_number'] ?? '',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '📱 Quét mã này tại kho để nhận hàng',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  ),
),
```

---

### **2. APP_INTAKE - Quét QR Code** 📷

#### **A. Package đã có:**
```yaml
dependencies:
  mobile_scanner: ^3.5.7  # QR/Barcode scanner
```

#### **B. Màn hình scan:**
- **File:** `app_intake/lib/screens/scan/scan_screen.dart`
- **Truy cập:** Bấm nút "Quét mã" (FloatingActionButton ở Home)

#### **C. Quy trình scan:**

1. **Mở scanner**
   ```dart
   - Bấm FAB "Quét mã" ở Home screen
   - Camera mở ra
   - Có nút bật/tắt đèn flash
   ```

2. **Quét QR code**
   ```dart
   - Hướng camera vào QR code trên app_user
   - Tự động detect và đọc
   - Parse order_code/order_number
   ```

3. **Tìm đơn hàng**
   ```dart
   Future<void> _onDetect(BarcodeCapture barcodeCapture) async {
     final orderCode = barcode.rawValue!;
     
     // Search order by code
     final order = await warehouseProvider.searchOrderByCode(
       authProvider.token!,
       orderCode,
     );
     
     if (order != null) {
       // Navigate to Order Intake Screen
       Navigator.push(context, OrderIntakeScreen(order: order));
     }
   }
   ```

4. **Nhập thông tin nhận hàng**
   ```
   → Order Intake Screen mở ra
   → Nhập cân nặng, kích thước, loại hàng, 4 ảnh
   → Bấm "Xác nhận nhận hàng"
   → Status: pending → received_at_warehouse
   ```

---

## 🔄 WORKFLOW ĐẦY ĐỦ

```
┌─────────────────────────────────────────────────────────────┐
│                   CUSTOMER (app_user)                       │
└─────────────────────────────────────────────────────────────┘
    │
    │ 1. Tạo đơn hàng
    │    - Điền địa chỉ, loại xe, dịch vụ
    │    - Bấm "Xác nhận đặt hàng"
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      BACKEND (Node.js)                      │
│  POST /api/orders                                           │
│  - Generate order_number: "ORD-{timestamp}-{uuid}"         │
│  - Insert vào database                                      │
│  - Return order data với order_number                       │
└─────────────────────────────────────────────────────────────┘
    │
    │ 2. Order được tạo với status: "pending"
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                   CUSTOMER (app_user)                       │
│  - Vào tab "Đơn hàng"                                       │
│  - Tap vào đơn vừa tạo                                      │
│  - OrderDetailsScreen hiển thị:                             │
│    + Thông tin đơn hàng                                     │
│    + QR CODE (encode order_number)  ← MỚI THÊM             │
│    + Tuyến đường                                            │
│    + Chi tiết giá                                           │
│  - Screenshot hoặc show QR cho nhân viên kho               │
└─────────────────────────────────────────────────────────────┘
    │
    │ 3. Đến kho giao hàng
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                 WAREHOUSE STAFF (app_intake)                │
│  - Mở app_intake                                            │
│  - Bấm nút "Quét mã" (FAB)                                  │
│  - Camera mở ra                                             │
│  - Quét QR code từ app_user của khách                       │
└─────────────────────────────────────────────────────────────┘
    │
    │ 4. QR Scanner đọc order_number
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      BACKEND (Node.js)                      │
│  GET /api/warehouse/orders/search?code={order_number}      │
│  - Tìm order trong database                                 │
│  - Return order details                                     │
└─────────────────────────────────────────────────────────────┘
    │
    │ 5. Order được tìm thấy
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                 WAREHOUSE STAFF (app_intake)                │
│  OrderIntakeScreen tự động mở:                              │
│  - Hiển thị thông tin đơn hàng                              │
│  - Nhập cân nặng THỰC TẾ                                    │
│  - Chọn kích thước THỰC TẾ                                  │
│  - Chọn loại hàng                                           │
│  - Chụp 4 ảnh gói hàng                                      │
│  - Bấm "Xác nhận nhận hàng"                                 │
└─────────────────────────────────────────────────────────────┘
    │
    │ 6. Submit nhận hàng
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      BACKEND (Node.js)                      │
│  POST /api/warehouse/receive                                │
│  - Update order:                                            │
│    + status: "received_at_warehouse"                        │
│    + package_size, package_type, weight                     │
│    + images[]                                               │
│  - Return success                                           │
└─────────────────────────────────────────────────────────────┘
    │
    │ ✅ ĐƠN HÀNG ĐÃ NHẬN VÀO KHO
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│         Tab "Kho hàng" → "Cần phân loại" (Story #9)        │
│  - Đơn hàng hiển thị ở đây                                  │
│  - Sẵn sàng cho bước Phân loại                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 DATABASE SCHEMA

### **Orders Table:**
```sql
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  order_number VARCHAR(50) UNIQUE NOT NULL,  -- Mã đơn hàng (dùng cho QR code)
  order_code VARCHAR(50),                     -- Alias (nếu có)
  user_id INTEGER,
  status VARCHAR(50) DEFAULT 'pending',
  
  -- Thông tin gói hàng (do khách ước lượng)
  customer_estimated_size VARCHAR(20),
  customer_requested_vehicle VARCHAR(20),
  
  -- Thông tin thực tế (do kho nhập sau khi scan)
  package_size VARCHAR(20),
  package_type VARCHAR(20),
  weight DECIMAL(10,2),
  package_images TEXT[],
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ...
);
```

### **Mối quan hệ:**
- `order_number` = Mã duy nhất cho QR code
- `order_code` = Alias (fallback nếu có)
- Warehouse staff scan → Tìm bằng `order_number` hoặc `order_code`

---

## 🧪 CÁCH TEST

### **Test 1: Tạo đơn hàng và xem QR code**

1. **Mở app_user (customer)**
   ```bash
   cd DoAnCNPMNC/app_user
   flutter run -d chrome
   ```

2. **Login và tạo đơn hàng**
   ```
   - Email: customer@test.com / Pass: password123
   - Tạo đơn hàng mới (LalamoveOrderSummaryScreen)
   - Điền đầy đủ thông tin
   - Bấm "Xác nhận đặt hàng"
   ```

3. **Xem QR code**
   ```
   - Vào tab "Đơn hàng"
   - Tap vào đơn vừa tạo
   - Cuộn xuống phần "Mã QR đơn hàng"
   - ✅ QR code hiển thị với order_number
   - ✅ Có text mã đơn dưới QR
   - ✅ Có hướng dẫn "Quét mã này tại kho..."
   ```

4. **Screenshot QR code** (để test bước sau)

---

### **Test 2: Quét QR code và nhận hàng**

1. **Mở app_intake (warehouse staff)**
   ```bash
   cd DoAnCNPMNC/app_intake
   flutter run -d chrome
   ```

2. **Login nhân viên kho**
   ```
   - Email: warehouse@test.com / Pass: password123
   - Vào Home screen
   ```

3. **Quét QR code**
   ```
   Option A: Quét QR thật (cần camera)
   - Bấm nút "Quét mã" (FAB góc dưới)
   - Camera mở ra
   - Hướng vào QR code từ app_user
   - Tự động detect và mở Order Intake Screen
   
   Option B: Nhập manual (không cần camera)
   - Tab "Đơn hàng" → "Chờ nhận"
   - Tap vào đơn hàng
   - Order Intake Screen mở ra
   ```

4. **Nhập thông tin nhận hàng**
   ```
   - Cân nặng: 2.5 kg
   - Kích thước: Medium
   - Loại hàng: Food
   - Chụp/chọn ảnh (không bắt buộc cho test)
   - Bấm "Xác nhận nhận hàng"
   ```

5. **Verify**
   ```
   ✅ Thông báo "Đã nhận đơn hàng thành công"
   ✅ Quay về màn hình trước
   ✅ Tab "Kho hàng" → "Cần phân loại" có đơn mới
   ✅ Trang chủ "Đã nhận: 1"
   ```

---

### **Test 3: Check database**

```bash
cd DoAnCNPMNC/backend
node scripts/check-orders.js
```

**Verify:**
```
✅ Order có order_number dạng: ORD-1730885678901-A1B2C3D4
✅ Status đã chuyển: pending → received_at_warehouse
✅ Có package_size, package_type, weight
```

---

## 🔧 TROUBLESHOOTING

### **Problem 1: QR code không hiển thị**

**Nguyên nhân:**
- Package `qr_flutter` chưa được cài
- Order data không có `order_number` hoặc `order_code`

**Solution:**
```bash
cd app_user
flutter pub get
flutter run
```

**Check data:**
```dart
// Trong order_details_screen.dart
print('Order data: ${order}');
print('Order number: ${order['order_number']}');
print('Order code: ${order['order_code']}');
```

---

### **Problem 2: Quét QR không tìm thấy đơn hàng**

**Nguyên nhân:**
- QR code encode sai format
- Backend API `/warehouse/orders/search` lỗi
- Order đã bị xóa/cancel

**Solution:**
```bash
# Check backend logs
cd backend
node server.js
# Xem console khi scan

# Test API manually
curl -X GET "http://localhost:3000/api/warehouse/orders/search?code=ORD-1730885678901-A1B2C3D4" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### **Problem 3: Camera không mở được**

**Nguyên nhân:**
- Web không có quyền camera
- Mobile scanner không support web tốt

**Solution:**
```
1. Cho phép camera trong browser settings
2. Hoặc dùng Option B: Nhập manual từ danh sách
3. Test trên mobile device thật (Android/iOS)
```

---

## 📱 QR CODE FORMAT

### **Current format:**
```
Dữ liệu trong QR: "ORD-1730885678901-A1B2C3D4"
```

### **Có thể mở rộng thành JSON:**
```json
{
  "type": "order",
  "code": "ORD-1730885678901-A1B2C3D4",
  "timestamp": 1730885678901,
  "checksum": "A1B2C3D4"
}
```

**Để implement JSON format:**
```dart
// app_user - Generate QR
final qrData = jsonEncode({
  'type': 'order',
  'code': order['order_number'],
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});

QrImageView(data: qrData, ...)
```

```dart
// app_intake - Parse QR
final decoded = jsonDecode(barcodeValue);
if (decoded['type'] == 'order') {
  final orderCode = decoded['code'];
  // Search order...
}
```

---

## 🎯 NEXT STEPS

### **Đã hoàn thành:** ✅
- [x] Thêm package `qr_flutter` vào app_user
- [x] Tạo QR code section trong OrderDetailsScreen
- [x] QR code hiển thị order_number
- [x] App_intake đã có QR scanner (mobile_scanner)
- [x] Workflow scan → search → receive đã hoạt động

### **Chưa làm:** ⏳
- [ ] Test QR code trên thiết bị thật (Android/iOS)
- [ ] In QR code ra giấy cho khách (print feature)
- [ ] Lưu lịch sử scan QR (audit log)
- [ ] Thêm logo công ty vào QR code
- [ ] Support nhiều định dạng QR (QR code, Barcode, etc.)

---

## 📚 TÀI LIỆU LIÊN QUAN

- `HUONG_DAN_NHAN_HANG.md` - Hướng dẫn quy trình nhận hàng
- `WAREHOUSE_WORKFLOW.md` - Workflow kho hàng đầy đủ
- `APP_INTAKE_SETUP.md` - Cấu trúc app_intake
- `STORY_9_CLASSIFICATION_COMPLETE.md` - Story #9 tiếp theo

---

## 💡 BEST PRACTICES

### **1. Error Correction Level**
```dart
QrImageView(
  errorCorrectionLevel: QrErrorCorrectLevel.H, // 30% data recovery
  // H = Highest (khuyên dùng cho logistics)
  // M = Medium (mặc định)
  // L = Low
)
```

### **2. QR Code Size**
```dart
size: 200.0,  // Đủ lớn để scan dễ dàng
// Không nên < 150 (quá nhỏ, khó scan)
// Không nên > 300 (lãng phí màn hình)
```

### **3. Background Color**
```dart
backgroundColor: Colors.white, // PHẢI LÀ MÀU SÁNG
foregroundColor: Colors.black, // Mặc định đen
```

### **4. Testing**
- Test trên nhiều camera (phone, tablet, scanner)
- Test dưới nhiều điều kiện ánh sáng
- Test với QR bị hư hỏng (30% còn đọc được nếu dùng level H)

---

**SUMMARY:** QR Code đã được tích hợp đầy đủ vào app_user và app_intake. Khách hàng có thể xem QR code trong chi tiết đơn hàng, nhân viên kho có thể quét để nhận hàng nhanh chóng! 🎉
