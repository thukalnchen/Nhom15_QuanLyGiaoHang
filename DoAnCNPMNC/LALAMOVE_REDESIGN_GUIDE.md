# 🚚 Hướng dẫn chuyển đổi App sang phong cách Lalamove

## ✅ Đã hoàn thành

### 1. **Màu sắc & Branding** ✓
- Đã đổi màu chính sang **#F26522** (Lalamove Orange)
- Đã cập nhật theme trong `main.dart`
- Đã thêm màu `primaryDark` và `background`

### 2. **Terminologies (Thuật ngữ)** ✓
Đã đổi trong `constants.dart`:
- ❌ "Nhà hàng" → ✅ "Người gửi"
- ❌ "Sản phẩm/Món ăn" → ✅ "Kiện hàng"
- ❌ "Tạo đơn hàng" → ✅ "Tạo đơn giao hàng"
- ❌ "Food Delivery" → ✅ "Lalamove Express"

### 3. **Icons & Visuals** ✓
Đã thay đổi:
- ❌ `Icons.restaurant` → ✅ `Icons.local_shipping_rounded`
- ❌ `Icons.shopping_cart` → ✅ `Icons.receipt_long`
- ❌ `Icons.add_shopping_cart` → ✅ `Icons.inventory_2`

### 4. **Screens đã chỉnh sửa** ✓
- ✅ `splash_screen.dart` - Logo và welcome message
- ✅ `main.dart` - Theme và title
- ✅ `home_screen.dart` - Welcome banner, quick actions, recent orders
- ✅ `create_order_screen.dart` - Form người gửi, kiện hàng
- ✅ `orders_screen.dart` - List view với icon delivery
- ✅ `login_screen.dart` - Logo và branding
- ✅ `constants.dart` - Toàn bộ text constants

---

## 🔧 Cần chỉnh sửa thêm (Optional)

### 1. **Register Screen** 
File: `app_user/lib/screens/auth/register_screen.dart`
- Đổi logo tương tự login screen
- Đổi icon từ `Icons.restaurant` → `Icons.local_shipping_rounded`

### 2. **Order Details Screen**
File: `app_user/lib/screens/orders/order_details_screen.dart`
- Đổi "Nhà hàng" → "Người gửi/Điểm lấy hàng"
- Đổi "Sản phẩm" → "Kiện hàng"
- Icon từ `Icons.restaurant` → `Icons.local_shipping_rounded`

### 3. **Tracking Screen**
File: `app_user/lib/screens/tracking/tracking_screen.dart`
- Đổi icon delivery
- Cập nhật map markers (nếu có)
- Đổi text "Giao đồ ăn" → "Giao hàng"

### 4. **Profile Screen**
File: `app_user/lib/screens/profile/profile_screen.dart`
- Có thể giữ nguyên hoặc thêm options liên quan đến delivery

---

## 📱 Thêm Assets (Hình ảnh)

### Logo Lalamove
Nếu bạn có logo thực:
1. Tạo thư mục: `app_user/assets/images/`
2. Thêm file logo: `lalamove_logo.png`
3. Cập nhật `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
```

4. Thay icon trong splash_screen.dart:
```dart
// Thay vì Icon widget
Image.asset(
  'assets/images/lalamove_logo.png',
  width: 80,
  height: 80,
)
```

---

## 🎨 Màu sắc chính đã áp dụng

```dart
// Primary colors
AppColors.primary = #F26522 (Lalamove Orange)
AppColors.primaryDark = #D64F0A (Darker Orange)
AppColors.secondary = #2C3E50 (Dark Blue/Gray)

// Status colors
AppColors.success = #10B981 (Green)
AppColors.warning = #F59E0B (Yellow)
AppColors.danger = #EF4444 (Red)
```

---

## 🔄 Backend Changes (Nếu cần)

File `backend/controllers/orderController.js` có thể cần đổi:
- Field `restaurant_name` → `sender_name` hoặc giữ nguyên (vì đây chỉ là UI change)

Nếu muốn đổi database schema:
```sql
ALTER TABLE orders CHANGE restaurant_name sender_name VARCHAR(255);
```

**Khuyến nghị**: Giữ nguyên database, chỉ đổi UI display text.

---

## 📝 Checklist hoàn thiện

- [x] Màu sắc Lalamove
- [x] Logo delivery truck
- [x] Text constants
- [x] Home screen
- [x] Create order screen
- [x] Orders list screen
- [x] Login screen
- [ ] Register screen (optional)
- [ ] Order details screen (optional)
- [ ] Tracking screen (optional)
- [ ] Thêm logo assets (nếu có)

---

## 🚀 Test App

Chạy app để xem kết quả:
```bash
cd app_user
flutter run
```

---

## 📸 Screenshots cần thiết

Nếu bạn có screenshots của Lalamove app, vui lòng cung cấp để tôi có thể điều chỉnh thêm:
1. Home screen
2. Create delivery order screen
3. Order tracking screen
4. Color palette reference

---

## 💡 Lưu ý

- **Database**: Không cần thay đổi database schema, chỉ thay đổi UI
- **API**: Backend vẫn dùng field `restaurant_name`, frontend sẽ hiển thị là "Người gửi"
- **Icons**: Đã sử dụng Material Icons built-in, không cần download thêm
- **Fonts**: Sử dụng default system fonts, có thể thêm Google Fonts nếu muốn

---

Made with ❤️ for Lalamove-style delivery app
