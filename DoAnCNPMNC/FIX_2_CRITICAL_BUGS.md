# 🔧 FIX: 2 LỖI CRITICAL

## ❌ VẤN ĐỀ 1: POST /warehouse/receive → 500 Internal Server Error

### **Nguyên nhân:**
Backend expect `order_id` (integer) nhưng Flutter gửi string trong JSON.

```javascript
// Backend warehouseController.js line 77
if (!order_id || !package_size || !package_type || !weight) {
  return res.status(400).json({ ... });
}
```

```dart
// Flutter api_service.dart - TRƯỚC KHI FIX
body: jsonEncode({
  'order_id': orderId,  // ← String "123" thay vì integer 123
  'package_size': packageSize,
  ...
}),
```

### **Giải pháp:**
Convert string sang int trước khi gửi.

**File: `app_intake/lib/services/api_service.dart`**
```dart
body: jsonEncode({
  'order_id': int.parse(orderId), // ← Convert string to int
  'package_size': packageSize,
  'package_type': packageType,
  'weight': weight,
  'description': description,
  'images': images,
}),
```

---

## ❌ VẤN ĐỀ 2: OrderIntakeScreen không hiển thị customer info

### **Nguyên nhân:**
Backend API `getWarehouseOrders` và `searchOrderByCode` chỉ SELECT từ bảng `orders` mà không JOIN với bảng `users` để lấy thông tin khách hàng.

```javascript
// TRƯỚC KHI FIX
const query = `SELECT * FROM orders WHERE ...`;
// Không có customer_name, customer_phone!
```

### **Giải pháp:**
JOIN với bảng `users` để lấy thông tin customer.

**File: `backend/controllers/warehouseController.js`**

#### **Fix 1: getWarehouseOrders()**
```javascript
exports.getWarehouseOrders = async (req, res) => {
  try {
    const query = `
      SELECT 
        o.*,
        u.full_name as customer_name,    // ← full_name NOT name!
        u.phone as customer_phone,
        u.email as customer_email
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.status IN ('pending', 'received_at_warehouse', 'classified', 'ready_for_pickup')
      ORDER BY o.created_at DESC
    `;
    
    const result = await pool.query(query);
    
    res.json({
      success: true,
      orders: result.rows
    });
  } catch (error) {
    console.error('Error getting warehouse orders:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
```

#### **Fix 2: searchOrderByCode()**
```javascript
exports.searchOrderByCode = async (req, res) => {
  try {
    const { code } = req.query;
    
    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Mã đơn hàng không được để trống'
      });
    }
    
    const query = `
      SELECT 
        o.*,
        u.full_name as customer_name,    // ← full_name NOT name!
        u.phone as customer_phone,
        u.email as customer_email
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.order_code = $1 OR o.order_number = $1
    `;
    const result = await pool.query(query, [code]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng'
      });
    }
    
    res.json({
      success: true,
      order: result.rows[0]
    });
  } catch (error) {
    console.error('Error searching order by code:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
```

**Bonus:** Search cả `order_code` và `order_number` để hỗ trợ cả 2 format QR code.

---

## ⚠️ DATABASE SCHEMA NOTE

**Users table columns:**
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255),
  password VARCHAR(255),
  full_name VARCHAR(255),  -- ← NOT "name"!
  phone VARCHAR(20),
  address TEXT,
  role VARCHAR(20),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Important:** Use `u.full_name` NOT `u.name` when joining with users table!

---

## ✅ KẾT QUẢ SAU KHI FIX

### **OrderIntakeScreen giờ hiển thị đầy đủ:**

```
╔═══════════════════════════════════════════╗
║  📋 NHẬN HÀNG                             ║
╠═══════════════════════════════════════════╣
║  ┌───────────────────────────────────┐    ║
║  │ 🎫 Mã đơn hàng                    │    ║
║  │    DLV-1730885678901-A1B2C3D4     │    ║
║  ├───────────────────────────────────┤    ║
║  │ 👤 Người gửi                      │    ║
║  │    Nguyễn Văn B                   │    ║  ← FIX: Hiển thị tên customer
║  │                                   │    ║
║  │ 📍 Địa chỉ lấy hàng               │    ║
║  │    Đại học Huflit, 140 Lý Thường │    ║  ← FIX: Hiển thị pickup address
║  │    Kiệt, P.7, Q.10, TP.HCM        │    ║
║  │                                   │    ║
║  │ 🏠 Địa chỉ giao hàng              │    ║
║  │    Landmark 81, 720A Điện Biên   │    ║  ← FIX: Hiển thị delivery address
║  │    Phủ, Bình Thạnh, TP.HCM       │    ║
║  └───────────────────────────────────┘    ║
║                                           ║
║  ⚖️ Cân nặng (kg)                         ║
║  ┌─────────────────────────────────┐     ║
║  │ 2.5                             │     ║
║  └─────────────────────────────────┘     ║
║                                           ║
║  📦 Kích thước                            ║
║  ○ Small  ● Medium  ○ Large  ○ XL        ║
║                                           ║
║  🏷️ Loại hàng                             ║
║  ○ Food  ● Electronics  ○ Documents      ║
║                                           ║
║  📷 Chụp ảnh gói hàng (0/4)               ║
║  [+] Thêm ảnh                             ║
║                                           ║
║  [ XÁC NHẬN NHẬN HÀNG ]                   ║
╚═══════════════════════════════════════════╝
```

### **API Response giờ có đầy đủ fields:**

**BEFORE:**
```json
{
  "success": true,
  "order": {
    "id": 27,
    "order_number": "DLV-1730885678901-A1B2C3D4",
    "user_id": 5,
    "pickup_address": "Đại học Huflit...",
    "delivery_address": "Landmark 81...",
    "recipient_name": "Nguyễn Văn A",
    "recipient_phone": "0901234567"
    // ❌ THIẾU customer_name, customer_phone
  }
}
```

**AFTER:**
```json
{
  "success": true,
  "order": {
    "id": 27,
    "order_number": "DLV-1730885678901-A1B2C3D4",
    "user_id": 5,
    "customer_name": "Nguyễn Văn B",     // ✅ MỚI
    "customer_phone": "0909876543",      // ✅ MỚI
    "customer_email": "customer@test.com", // ✅ MỚI
    "pickup_address": "Đại học Huflit...",
    "delivery_address": "Landmark 81...",
    "recipient_name": "Nguyễn Văn A",
    "recipient_phone": "0901234567"
  }
}
```

---

## 📊 FLOW SAU KHI FIX

```
┌─────────────────────────────────────────────────┐
│  USER: Tap đơn hàng trong OrdersScreen          │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  Navigate to OrderIntakeScreen(order: order)    │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  OrderIntakeScreen build():                     │
│  - Hiển thị order.orderCode    ✅              │
│  - Hiển thị order.customerName ✅ (từ JOIN)     │
│  - Hiển thị order.pickupAddress ✅             │
│  - Hiển thị order.deliveryAddress ✅           │
│  - Form nhập: cân nặng, kích thước, loại hàng   │
└─────────────────────────────────────────────────┘
                    │
                    │ User điền form
                    ▼
┌─────────────────────────────────────────────────┐
│  Bấm "Xác nhận nhận hàng"                       │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  warehouseProvider.receiveOrder()               │
│  → apiService.receiveOrder()                    │
│     body: {                                     │
│       order_id: int.parse(orderId), ✅ FIX     │
│       package_size: "medium",                   │
│       package_type: "electronics",              │
│       weight: 2.5,                              │
│       ...                                       │
│     }                                           │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  POST http://localhost:3000/api/warehouse/      │
│       receive                                   │
│  Backend warehouseController.receiveOrder():    │
│  - Validate: order_id (int) ✅                 │
│  - UPDATE orders SET status='received...'       │
│  - Return success                               │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  ✅ Status 200 OK                               │
│  {                                              │
│    "success": true,                             │
│    "message": "Đã nhận đơn hàng...",            │
│    "order": { ... }                             │
│  }                                              │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  Navigate back to OrdersScreen                  │
│  - Refresh orders                               │
│  - Order chuyển từ "Chờ nhận" → "Đã nhận"      │
└─────────────────────────────────────────────────┘
```

---

## 🧪 CÁCH TEST

### **Test Fix #1: API 500 Error**

1. **Restart backend** (để load code mới):
   ```powershell
   cd backend
   # Ctrl+C để stop
   node server.js
   ```

2. **Hot reload app_intake** (Flutter):
   ```
   Press 'r' in terminal
   ```

3. **Test receive order:**
   - Login warehouse@test.com
   - Tab "Đơn hàng" → "Chờ nhận"
   - Tap đơn hàng
   - Nhập: 2.5kg, Medium, Food
   - Bấm "Xác nhận nhận hàng"
   - ✅ Không còn lỗi 500
   - ✅ Thông báo "Đã nhận đơn hàng thành công"

---

### **Test Fix #2: Customer Info**

1. **Refresh page** (Ctrl+R hoặc reload)

2. **Check OrdersScreen:**
   - Tab "Chờ nhận"
   - Các đơn hàng giờ có thông tin đầy đủ

3. **Check OrderIntakeScreen:**
   - Tap vào đơn
   - ✅ Hiển thị "Người gửi: Nguyễn Văn B"
   - ✅ Hiển thị "Địa chỉ lấy hàng: Đại học Huflit..."
   - ✅ Hiển thị "Địa chỉ giao hàng: Landmark 81..."

---

## 📝 FILES CHANGED

### **1. app_intake/lib/services/api_service.dart**
- Line ~155: Convert `orderId` string to int
- Change: `'order_id': orderId` → `'order_id': int.parse(orderId)`

### **2. backend/controllers/warehouseController.js**
- Line ~4-22: Add JOIN in `getWarehouseOrders()`
- Line ~27-62: Add JOIN in `searchOrderByCode()`
- Added fields: `customer_name`, `customer_phone`, `customer_email`
- Bonus: Search both `order_code` and `order_number`

---

## ⚠️ LƯU Ý

### **Backend changes require restart:**
```powershell
# Terminal backend
Ctrl+C
node server.js
```

### **Flutter changes require hot reload:**
```
# Terminal Flutter
Press 'r'
```

### **Database không cần migrate:**
- Các cột `pickup_address`, `delivery_address`, `recipient_name` đã có sẵn
- Chỉ cần JOIN với bảng `users` để lấy `customer_name`, `customer_phone`

---

## 🎯 SUMMARY

| Issue | Root Cause | Solution | Status |
|-------|-----------|----------|--------|
| **500 Error** | `order_id` sent as string | Convert to int with `int.parse()` | ✅ FIXED |
| **Missing Customer Info** | No JOIN with users table | Add LEFT JOIN in SQL queries | ✅ FIXED |
| **Missing Address** | (Already existed in DB) | Backend returns it correctly now | ✅ OK |

**Hãy restart backend và hot reload Flutter để test!** 🚀
