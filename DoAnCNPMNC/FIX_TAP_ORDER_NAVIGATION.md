# 🔧 FIX: TAP ĐƠN HÀNG KHÔNG HIỂN thị GÌ

## ❌ VẤN ĐỀ
Khi tap vào đơn hàng ở tab "Chờ nhận" trong OrdersScreen, không có gì xảy ra.

## ✅ NGUYÊN NHÂN
File `app_intake/lib/screens/orders/orders_screen.dart` có TODO nhưng chưa implement navigation:

```dart
onTap: () {
  // Navigate to order detail
  // TODO: Implement order detail screen  ← CHƯA LÀM
},
```

## 🔨 GIẢI PHÁP ĐÃ THỰC HIỆN

### **1. Thêm import OrderIntakeScreen**
```dart
import '../scan/order_intake_screen.dart';
```

### **2. Implement onTap handler**
```dart
onTap: () {
  // Navigate to OrderIntakeScreen for pending orders
  if (order.status == OrderStatus.pending) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderIntakeScreen(order: order),
      ),
    );
  } else {
    // Show order details in a dialog for non-pending orders
    _showOrderDetailsDialog(order);
  }
},
```

### **3. Thêm method _showOrderDetailsDialog()**
- Hiển thị dialog với thông tin chi tiết đơn hàng
- Áp dụng cho orders đã nhận (received/classified/ready)
- Hiển thị: Mã đơn, trạng thái, phí giao, địa chỉ, ngày tạo

### **4. Thêm helper method _buildDetailRow()**
- Format hiển thị label + value trong dialog

---

## 🎯 KẾT QUẢ

### **Đối với đơn hàng PENDING (Chờ nhận):**
```
Tap đơn hàng → Navigate to OrderIntakeScreen
↓
Màn hình nhập thông tin mở ra:
- Cân nặng
- Kích thước
- Loại hàng
- Chụp ảnh
- Nút "Xác nhận nhận hàng"
```

### **Đối với đơn hàng ĐÃ NHẬN (Received/Classified/Ready):**
```
Tap đơn hàng → Dialog hiển thị chi tiết
↓
Hiển thị thông tin:
- Mã đơn: ORD-xxx
- Trạng thái: Đã nhận/Đã phân loại/Sẵn sàng
- Phí giao: 50,000đ
- Địa chỉ lấy: xxx
- Địa chỉ giao: xxx
- Ngày tạo: 5 phút trước
- Nút "Đóng"
```

---

## 🧪 CÁCH TEST

### **Test 1: Pending orders (Chờ nhận)**

1. **Hot reload app_intake** (press 'r' in terminal)
2. **Login:** `warehouse@test.com` / `password123`
3. **Vào tab "Đơn hàng"** → Tab **"Chờ nhận"** (18 đơn)
4. **Tap vào 1 đơn bất kỳ**
5. ✅ **OrderIntakeScreen mở ra** với form nhập thông tin
6. Nhập:
   - Cân nặng: `2.5`
   - Kích thước: `Medium`
   - Loại hàng: `Food`
   - (Chụp ảnh optional)
7. **Bấm "Xác nhận nhận hàng"**
8. ✅ Thông báo thành công
9. ✅ Quay về OrdersScreen
10. ✅ Đơn chuyển sang tab "Đã nhận"

---

### **Test 2: Non-pending orders (Đã nhận/Đã phân loại)**

1. **Hot reload app_intake**
2. **Vào tab "Đơn hàng"** → Tab **"Đã phân loại"** (2 đơn)
3. **Tap vào 1 đơn**
4. ✅ **Dialog hiển thị** với thông tin chi tiết
5. ✅ Có nút "Đóng"
6. Bấm "Đóng" → Dialog đóng

---

## 📊 WORKFLOW ĐẦY ĐỦ

```
┌─────────────────────────────────────────────────────────┐
│  TAB "ĐƠN HÀNG" → TAB "CHỜ NHẬN" (18 đơn)              │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Tap vào đơn hàng
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Check order.status                                     │
│  → status == 'pending' ?                                │
└─────────────────────────────────────────────────────────┘
           │                           │
           │ YES                       │ NO
           ▼                           ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│  Navigate to:            │  │  Show Dialog:            │
│  OrderIntakeScreen       │  │  Order Details           │
│                          │  │                          │
│  - Nhập cân nặng         │  │  - Mã đơn                │
│  - Chọn kích thước       │  │  - Trạng thái            │
│  - Chọn loại hàng        │  │  - Phí giao              │
│  - Chụp 4 ảnh            │  │  - Địa chỉ               │
│  - "Xác nhận nhận hàng"  │  │  - Ngày tạo              │
│                          │  │  - Nút "Đóng"            │
└──────────────────────────┘  └──────────────────────────┘
           │
           │ Submit
           ▼
┌─────────────────────────────────────────────────────────┐
│  POST /api/warehouse/receive                            │
│  - Update status: received_at_warehouse                 │
│  - Save package info                                    │
└─────────────────────────────────────────────────────────┘
           │
           │ Success
           ▼
┌─────────────────────────────────────────────────────────┐
│  Navigate back to OrdersScreen                          │
│  - Refresh orders                                       │
│  - Order appears in "Đã nhận" tab                       │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 CODE CHANGES

### **File: `app_intake/lib/screens/orders/orders_screen.dart`**

**Added imports:**
```dart
import '../scan/order_intake_screen.dart';
```

**Modified `_buildOrderCard()` onTap:**
```dart
onTap: () {
  if (order.status == OrderStatus.pending) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderIntakeScreen(order: order),
      ),
    );
  } else {
    _showOrderDetailsDialog(order);
  }
},
```

**Added methods:**
- `_showOrderDetailsDialog(Order order)` - 64 lines
- `_buildDetailRow(String label, String value)` - 22 lines

---

## ⚠️ LƯU Ý

### **Pending orders (status='pending'):**
- ✅ Navigate to OrderIntakeScreen
- ✅ Có thể nhập thông tin và nhận hàng
- ✅ Chuyển status sang 'received_at_warehouse'

### **Non-pending orders:**
- ✅ Show dialog với thông tin chi tiết
- ❌ Không thể edit (read-only)
- 💡 Nếu cần edit sau này, tạo OrderDetailScreen riêng

---

## 🔄 NEXT STEPS (Optional)

### **Có thể cải tiến:**
1. Tạo OrderDetailScreen riêng thay vì dialog
2. Thêm actions: Print, Share, Cancel (nếu cần)
3. Hiển thị timeline trạng thái đơn hàng
4. Thêm photos preview nếu đã có ảnh

---

## 🎉 SUMMARY

**Đã fix:** ✅
- Tap đơn hàng pending → Mở OrderIntakeScreen
- Tap đơn hàng khác → Show dialog chi tiết
- Thêm navigation và dialog handlers
- Code compile không có lỗi

**Hãy hot reload app và test ngay!** (Press 'r' trong terminal Flutter)
