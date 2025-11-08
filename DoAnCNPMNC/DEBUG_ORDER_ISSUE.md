# 🔧 HƯỚNG DẪN FIX & TEST (App User → App Intake)

## ⚠️ VẤN ĐỀ HIỆN TẠI

User phản ánh: **"Đặt hàng xong → Vào đơn hàng → Không thấy đơn nào"**

---

## ✅ ĐÃ FIX

### 1. **Auto-reload orders sau khi tạo**
**File**: `app_user/lib/screens/orders/create_order_screen.dart`

```dart
if (success) {
  // ✅ Thêm dòng này: Tự động reload danh sách
  await orderProvider.getOrders(token: authProvider.token);
  
  Navigator.pop(context, true);
}
```

### 2. **Thêm debug logs**
**File**: `app_user/lib/providers/order_provider.dart`

```dart
Future<bool> getOrders({String? token, String? status}) async {
  // ✅ Thêm logs để debug
  print('📡 getOrders: Fetching...');
  print('📥 getOrders: Status ${response.statusCode}');
  print('✅ getOrders: Loaded ${_orders.length} orders');
}
```

---

## 🧪 CÁCH TEST (5 BƯỚC ĐƠN GIẢN)

### **BƯỚC 1: Đảm bảo Backend chạy**
```bash
# Terminal 1
cd backend
npm start
```
✅ Backend phải running tại `http://localhost:3000`

---

### **BƯỚC 2: Chạy App User**
App đang chạy tại: `http://127.0.0.1:55485`

✅ Nếu chưa chạy:
```bash
cd app_user
flutter run -d chrome
```

---

### **BƯỚC 3: Login & Tạo Order**

#### 3.1. Login
- Email: `customer@test.com`
- Password: `test123`

#### 3.2. Tạo đơn hàng
1. Tap "Đặt hàng" / "Create Order"
2. Điền thông tin:
   - Restaurant: "KFC Nguyễn Văn Linh"
   - Items: "Gà rán + Pepsi"
   - Total: 100,000đ
   - Address: "123 Nguyễn Văn Linh, Q7"
   - Phone: "0909123456"
3. Tap "Tạo đơn hàng"
4. ✅ Thấy toast: "Tạo đơn hàng thành công"

---

### **BƯỚC 4: Kiểm tra tab Đơn Hàng**

**✅ EXPECTED (Mong đợi)**:
- Order vừa tạo **PHẢI** hiển thị ngay
- Status: "Pending" (màu cam)
- Order number: `ORD-xxxxx`

**❌ NẾU KHÔNG THẤY**:
1. **Check Console Logs** (F12 → Console):
   ```
   📡 getOrders: Fetching from http://localhost:3000/api/orders
   📥 getOrders: Status 200
   ✅ getOrders: Loaded 1 orders
   ```

2. **Nếu thấy log "Token is null"**:
   - → Logout và login lại
   - Token expired

3. **Nếu thấy HTTP 401/403**:
   - → Backend authentication issue
   - Check token trong localStorage

4. **Nếu không có log nào**:
   - → OrdersScreen không gọi `_loadOrders()`
   - Hot restart app: `R` trong terminal

---

### **BƯỚC 5: Kiểm tra App Intake**

#### 5.1. Chạy App Intake
```bash
cd app_intake
flutter run -d chrome
```

#### 5.2. Login Intake
- Email: `staff@intake.com`
- Password: `staff123`

#### 5.3. Check Dashboard
1. Tab "Tổng quan"
   - ✅ "Đơn chờ nhận" phải > 0
2. Tab "Đơn hàng"
   - ✅ Thấy order vừa tạo (status: pending)
3. Tap refresh button nếu cần

---

## 🐛 DEBUG CHECKLIST

### ❌ Vấn đề: "Không thấy order trong App User"

**Kiểm tra theo thứ tự**:

#### 1. Backend running?
```bash
curl http://localhost:3000/api/health
```
✅ Phải trả về: `{"status":"success"}`

#### 2. User đã login?
- F12 → Application → Local Storage
- Tìm key: `auth_token`
- ✅ Phải có token

#### 3. Order có tạo thành công?
```bash
# Terminal
cd backend
node scripts/test-order-flow.js
```
✅ Phải pass hết 3 steps

#### 4. Console có error?
- F12 → Console
- Tìm error màu đỏ
- Check network tab (Status 4xx/5xx)

#### 5. Pull to refresh
- Kéo xuống tab "Đơn hàng" để refresh
- Hoặc tap nút refresh (⟳)

---

## 🔍 DEBUG LOGS REFERENCE

### ✅ LOGS ĐÚNG (Expected Logs)
```
📡 getOrders: Fetching from http://localhost:3000/api/orders
📥 getOrders: Status 200
📦 getOrders: Response data: success
✅ getOrders: Loaded 1 orders
```

### ❌ LOGS LỖI (Error Logs)

#### Lỗi 1: Token null
```
❌ getOrders: Token is null
```
**Fix**: Logout → Login lại

#### Lỗi 2: HTTP 401
```
📥 getOrders: Status 401
❌ getOrders: HTTP 401 - Unauthorized
```
**Fix**: Token expired, login lại

#### Lỗi 3: Connection Error
```
❌ getOrders: Exception - Failed to connect
```
**Fix**: Check backend running, check API URL

#### Lỗi 4: Parse Error
```
❌ getOrders: Exception - Unexpected token
```
**Fix**: Backend trả wrong format, check backend logs

---

## 📊 VERIFY DATABASE

### Check Order trong Database
```sql
-- Kiểm tra orders của user
SELECT 
  id,
  order_number,
  user_id,
  restaurant_name,
  status,
  created_at
FROM orders
WHERE user_id = 6  -- customer@test.com
ORDER BY created_at DESC
LIMIT 5;
```

**Expected**:
```
id | order_number          | user_id | status  | created_at
---|-----------------------|---------|---------|-------------------
1  | ORD-1762581273764-... | 6       | pending | 2025-11-08 12:00
```

---

## 🎯 QUICK FIX ACTIONS

### Fix 1: Clear cache & restart
```bash
# Terminal
cd app_user
flutter clean
flutter pub get
flutter run -d chrome
```

### Fix 2: Force refresh orders
```dart
// Add button in OrdersScreen
ElevatedButton(
  onPressed: () async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.getOrders(token: authProvider.token);
  },
  child: Text('Force Refresh'),
)
```

### Fix 3: Check auth token
```dart
// Add debug in initState
@override
void initState() {
  super.initState();
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  print('🔑 Auth Token: ${authProvider.token?.substring(0, 20)}...');
  print('👤 User ID: ${authProvider.user?.id}');
  _loadOrders();
}
```

---

## ✅ SUCCESS CRITERIA

### App User
- [x] Login thành công
- [x] Tạo order thành công (toast success)
- [x] Order hiển thị trong tab "Đơn Hàng"
- [x] Order có order_number
- [x] Status = pending
- [x] Có thể tap vào order xem detail

### App Intake
- [x] Login thành công
- [x] Dashboard "Đơn chờ nhận" > 0
- [x] Order hiển thị trong tab "Đơn hàng"
- [x] Order status = pending
- [x] Có thể quét QR hoặc tap vào order

---

## 📞 SUPPORT

Nếu vẫn gặp vấn đề:

1. **Export logs**:
   ```bash
   F12 → Console → Right click → Save as... → console.log
   ```

2. **Check backend logs**:
   ```bash
   cd backend
   npm start
   # Copy all console output
   ```

3. **Database query**:
   ```sql
   SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;
   ```

4. **Share**:
   - Console logs
   - Backend logs  
   - Database result
   - Screenshots

---

**Last Updated**: November 8, 2025
**Version**: 1.0.1
**Status**: ✅ Fixed & Ready for Testing
