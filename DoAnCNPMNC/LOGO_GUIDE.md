# 🖼️ Hướng dẫn thêm Logo Lalamove

## Bước 1: Chuẩn bị assets folder

1. Tạo thư mục trong project:
```
app_user/
  assets/
    images/
      lalamove_logo.png      (Logo chính)
      lalamove_icon.png      (Icon nhỏ)
```

2. Cập nhật `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true
  
  # Thêm phần này
  assets:
    - assets/images/
```

3. Chạy lệnh:
```bash
cd app_user
flutter pub get
```

## Bước 2: Logo cho Splash Screen

**File**: `lib/screens/splash_screen.dart`

**Tìm:**
```dart
child: const Icon(
  Icons.local_shipping_rounded,
  size: 80,
  color: AppColors.primary,
),
```

**Thay bằng:**
```dart
child: ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: Image.asset(
    'assets/images/lalamove_logo.png',
    width: 100,
    height: 100,
    fit: BoxFit.cover,
  ),
),
```

## Bước 3: Logo cho Login Screen

**File**: `lib/screens/auth/login_screen.dart`

**Tìm:**
```dart
child: const Icon(
  Icons.local_shipping_rounded,
  size: 60,
  color: Colors.white,
),
```

**Thay bằng:**
```dart
child: ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: Image.asset(
    'assets/images/lalamove_logo.png',
    width: 80,
    height: 80,
    fit: BoxFit.cover,
  ),
),
```

## Bước 4: Logo trong AppBar (Optional)

**File**: `lib/screens/home/home_screen.dart`

**Tìm:**
```dart
appBar: AppBar(
  title: const Text(AppTexts.appName),
```

**Thay bằng:**
```dart
appBar: AppBar(
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/images/lalamove_icon.png',
        width: 32,
        height: 32,
      ),
      const SizedBox(width: 8),
      const Text(AppTexts.appName),
    ],
  ),
```

## Bước 5: App Icon (Android & iOS)

### Android
1. Chuẩn bị icon sizes:
   - `mipmap-mdpi`: 48x48
   - `mipmap-hdpi`: 72x72
   - `mipmap-xhdpi`: 96x96
   - `mipmap-xxhdpi`: 144x144
   - `mipmap-xxxhdpi`: 192x192

2. Copy vào:
```
app_user/android/app/src/main/res/
  mipmap-mdpi/ic_launcher.png
  mipmap-hdpi/ic_launcher.png
  mipmap-xhdpi/ic_launcher.png
  mipmap-xxhdpi/ic_launcher.png
  mipmap-xxxhdpi/ic_launcher.png
```

### iOS
1. Chuẩn bị icon sizes (1024x1024)
2. Copy vào:
```
app_user/ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

## Tools tự động tạo icon

### Online Tools:
1. **AppIcon.co**: https://www.appicon.co/
2. **Icon Kitchen**: https://icon.kitchen/

### Flutter Package:
```bash
flutter pub add flutter_launcher_icons
```

**pubspec.yaml**:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/lalamove_logo.png"
  adaptive_icon_background: "#F26522"
  adaptive_icon_foreground: "assets/images/lalamove_icon.png"
```

**Chạy:**
```bash
flutter pub run flutter_launcher_icons
```

## Lưu ý về Logo

### Format
- **PNG** với background trong suốt (recommended)
- **SVG** có thể dùng với package `flutter_svg`

### Size recommendations
- **Splash logo**: 512x512px (export nhiều sizes)
- **App icon**: 1024x1024px
- **In-app logo**: 256x256px

### Colors
- Nên dùng logo **white** cho background màu cam
- Hoặc logo **orange** (#F26522) cho background trắng

## Alternative: Sử dụng SVG

1. Add package:
```yaml
dependencies:
  flutter_svg: ^2.0.9
```

2. Sử dụng:
```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/images/lalamove_logo.svg',
  width: 100,
  height: 100,
  color: Colors.white, // Tint color
)
```

## Placeholder hiện tại

Nếu chưa có logo thực, app đang dùng:
- ✅ `Icons.local_shipping_rounded` - Material icon xe tải
- ✅ Màu cam Lalamove (#F26522)
- ✅ Gradient orange background

**Trông khá professional và có thể sử dụng luôn!**

## Download Logo Lalamove (Reference)

⚠️ **Lưu ý bản quyền**: Logo Lalamove là tài sản của Lalamove company.

Để tham khảo design:
1. Google Images: "Lalamove logo"
2. Lalamove official website
3. Tự design logo tương tự với truck icon

## Tạo Logo đơn giản với Canva

1. Truy cập: https://www.canva.com
2. Chọn "Logo" template
3. Tìm icon "delivery truck" hoặc "shipping"
4. Đặt màu cam #F26522
5. Thêm text "Lalamove Express"
6. Export PNG 1024x1024

## Test sau khi thêm logo

```bash
# Clean build
cd app_user
flutter clean
flutter pub get

# Run app
flutter run

# Check assets
ls -la assets/images/
```

---

**Kết luận**: 
- Icon Material hiện tại đã đủ tốt ✅
- Thêm logo PNG nếu cần branding chính thức
- Ưu tiên: Functionality > Perfect logo

Happy coding! 🚀
