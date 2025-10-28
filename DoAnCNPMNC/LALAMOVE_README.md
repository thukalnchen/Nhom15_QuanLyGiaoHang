# 🚚 Lalamove Express - Delivery Management App

## 📱 Giới thiệu

App quản lý giao hàng online theo phong cách **Lalamove**, được chuyển đổi từ food delivery app.

## ✨ Thay đổi chính

### 🎨 Design
- **Màu chủ đạo**: Cam Lalamove (#F26522)
- **Icons**: Delivery-focused (truck, packages, shipping)
- **Theme**: Professional logistics service

### 📝 Terminology
- ✅ Người gửi (thay vì Nhà hàng)
- ✅ Kiện hàng (thay vì Sản phẩm)
- ✅ Đơn giao hàng (thay vì Đơn đặt món)

### 🖼️ UI Components
- Gradient orange headers
- Delivery truck icons
- Modern card designs
- Status badges with colors

## 📂 Files đã chỉnh sửa

```
app_user/lib/
  ✅ main.dart
  ✅ utils/constants.dart
  ✅ screens/
      ✅ splash_screen.dart
      ✅ auth/login_screen.dart
      ✅ home/home_screen.dart
      ✅ orders/create_order_screen.dart
      ✅ orders/orders_screen.dart
```

## 🚀 Chạy App

```bash
cd app_user
flutter pub get
flutter run
```

## 📚 Tài liệu

- 📋 **[CHANGES_SUMMARY.md](./CHANGES_SUMMARY.md)** - Tổng kết chi tiết các thay đổi
- 🎨 **[DESIGN_REFERENCE.md](./DESIGN_REFERENCE.md)** - Quick reference cho design
- 📘 **[LALAMOVE_REDESIGN_GUIDE.md](./LALAMOVE_REDESIGN_GUIDE.md)** - Hướng dẫn hoàn thiện
- 🖼️ **[LOGO_GUIDE.md](./LOGO_GUIDE.md)** - Hướng dẫn thêm logo

## 🎯 Features

### Đã hoàn thành ✅
- [x] Splash screen với branding mới
- [x] Login/Register với theme Lalamove
- [x] Home screen với delivery icons
- [x] Create delivery order form
- [x] Orders list với status
- [x] Lalamove color scheme
- [x] Delivery-focused terminology

### Có thể thêm (Optional) 🔧
- [ ] Real logo assets
- [ ] Enhanced tracking screen
- [ ] Vehicle type selection
- [ ] Photo proof delivery
- [ ] Rating system

## 🎨 Màu sắc

```css
Primary:        #F26522 (Lalamove Orange)
Primary Dark:   #D64F0A
Secondary:      #2C3E50
Success:        #10B981
Warning:        #F59E0B
Danger:         #EF4444
```

## 📱 Screenshots

### Before (Food Delivery)
- 🍽️ Purple theme
- 🛒 Restaurant focus
- Food ordering UI

### After (Lalamove Style)
- 🚚 Orange theme
- 📦 Logistics focus
- Professional delivery UI

## 🔧 Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Backend**: Node.js + Express
- **Database**: MySQL
- **UI**: Material Design 3

## 👨‍💻 Development

### Prerequisites
```bash
Flutter SDK >= 3.0.0
Dart >= 3.0.0
```

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  shared_preferences: ^2.0.0
  fluttertoast: ^8.0.0
  http: ^1.0.0
```

### Build
```bash
# Debug build
flutter run

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

## 📝 Notes

- **Database**: Không cần thay đổi schema, chỉ UI thay đổi
- **Backend**: Field names giữ nguyên (vd: `restaurant_name`)
- **Display**: Frontend mapping terminology mới

## 🤝 Contributing

1. Đọc [LALAMOVE_REDESIGN_GUIDE.md](./LALAMOVE_REDESIGN_GUIDE.md)
2. Follow design patterns trong [DESIGN_REFERENCE.md](./DESIGN_REFERENCE.md)
3. Maintain màu sắc consistency
4. Test thoroughly trước khi commit

## 📞 Support

Nếu cần hỗ trợ thêm:
- Logo assets
- Additional screens
- Feature enhancements
- Bug fixes

## 📄 License

Educational project - Nhóm 15 CNPM

---

**Made with ❤️ for Lalamove-style delivery app**

**Version**: 1.0  
**Last Updated**: 2025  
**Status**: ✅ Ready for use
