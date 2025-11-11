# Lalamove Shipper App

Ứng dụng Flutter dành cho nhân viên giao hàng (shipper). App kết nối tới backend Node.js để hiển thị các đơn hàng được gán, xem chi tiết, theo dõi bản đồ và cập nhật trạng thái giao.

## Yêu cầu môi trường

- Flutter 3.19+ (Dart 3.x)
- Android Studio / Xcode để build app
- Backend service chạy tại `http://localhost:3000` (có thể cập nhật trong `lib/utils/constants.dart`)
- Google Maps API Key (hiển thị bản đồ)

## Cài đặt

```bash
flutter pub get
```

### Cấu hình API

- Với Android emulator, app mặc định gọi `http://10.0.2.2:3000/api`
- Với iOS simulator, chỉnh lại hằng số `AppConfig.apiBaseUrl` nếu cần

### Google Maps

1. Lấy API key từ Google Cloud Console
2. Cập nhật giá trị trong `android/app/src/main/res/values/strings.xml`:
   ```xml
   <string name="google_maps_api_key">YOUR_REAL_KEY</string>
   ```
3. Với iOS, thêm key vào `ios/Runner/AppDelegate.swift` (chưa cấu hình sẵn)

Nếu chưa có key, app vẫn chạy nhưng bản đồ sẽ hiển thị placeholder.

## Luồng chức năng

- **Đăng ký shipper** (`POST /api/auth/register/shipper`): điền thông tin cá nhân + phương tiện trên màn hình đăng ký. Trạng thái mặc định `pending`, cần admin duyệt trước khi đăng nhập.
- **Đăng nhập** bằng tài khoản có role `shipper`. Backend từ chối nếu user không phải shipper hoặc chưa được duyệt.
- **Danh sách đơn hàng** (`GET /api/shippers/me/orders`): hiển thị các đơn được gán, có filter theo trạng thái.
- **Chi tiết đơn** (`GET /api/shippers/orders/:id`): bao gồm thông tin khách hàng, người nhận, ghi chú, bản đồ 2 điểm pickup/delivery, lịch sử trạng thái.
- **Cập nhật trạng thái** (`PATCH /api/shippers/orders/:id/status`): các nút
  - `Bắt đầu giao` → `DELIVERING`
  - `Giao thành công` → `DELIVERED_SUCCESS`
  - `Giao thất bại` → `DELIVERY_FAILED` (yêu cầu ghi chú)

Sau khi cập nhật, backend ghi log lịch sử và gửi thông báo cho khách hàng.

## Chạy ứng dụng

```bash
flutter run
```

## Kiểm thử nhanh

1. Nếu chưa có admin hoặc muốn reset mật khẩu, chạy `node backend/scripts/create-admin.js` và nhập email/mật khẩu mong muốn.
2. Đăng ký tài khoản shipper mới trong app (màn hình “Chưa có tài khoản? Đăng ký…”).
3. Đăng nhập web admin, vào mục **Shipper** và duyệt hồ sơ vừa tạo.
4. Đăng nhập lại app shipper để xác thực luồng pending/approved.
5. Gán đơn hàng cho shipper bằng script (nếu chưa có dữ liệu):
   ```bash
   node backend/scripts/assign-order-to-shipper.js
   ```
6. Kiểm tra luồng hiển thị/cập nhật trạng thái.

## Cấu trúc thư mục

```
lib/
├── models/          # Định nghĩa ShipperUser, ShipperOrder
├── providers/       # AuthProvider (login/register), OrderProvider
├── screens/         # splash, auth (login/register), home, order detail
└── utils/           # constants (theme, API endpoints)
```

## Ghi chú

- Nếu backend chạy trên domain khác, cập nhật lại `AppConfig.apiBaseUrl` và `AppConfig.socketUrl`.
- Tránh commit khóa Google Maps thật vào repo. Sử dụng `.env` hoặc secret manager cho môi trường production.
