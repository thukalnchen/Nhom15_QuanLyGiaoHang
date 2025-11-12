## Sprint 4 – Hướng dẫn tính năng Shipper

### 1. Schema & Migration

- Bổ sung/điều chỉnh:
  - `users.fcm_token`, `users.status` (giá trị: `active`, `pending`, `approved`, `rejected`, `suspended`)
  - `orders.shipper_id`, `pickup_lat`, `pickup_lng`, `delivery_lat`, `delivery_lng`
  - `orders.recipient_name`, `recipient_phone`, `distance`, `duration`, `services`, `base_fare`, `service_fee`
  - Bảng `shipper_profiles`: `vehicle_type`, `vehicle_plate`, `driver_license_number`, `identity_card_number`, `notes`, `approved_at`
- Chạy lại backend (server tự tạo/ALTER) để đồng bộ schema.
- Script gán đơn thử nghiệm: `node backend/scripts/assign-order-to-shipper.js` (chỉ cho phép shipper `approved`).

### 2. API mới / cập nhật

| Method | Endpoint | Mục đích |
|--------|----------|----------|
| `POST` | `/api/auth/register/shipper` | Shipper tự đăng ký tài khoản (status mặc định `pending`) |
| `GET` | `/api/shippers/me/orders` | Lấy danh sách đơn của shipper đang đăng nhập (filter `status`) |
| `GET` | `/api/shippers/orders/:id` | Chi tiết đơn hàng (địa điểm, khách hàng, lịch sử) |
| `PATCH` | `/api/shippers/orders/:id/status` | Cập nhật trạng thái (`DELIVERING`, `DELIVERED_SUCCESS`, `DELIVERY_FAILED`, ...) |
| `GET` | `/api/admin/shippers` | Danh sách shipper + trạng thái duyệt |
| `GET` | `/api/admin/shippers/:id` | Chi tiết hồ sơ shipper |
| `PATCH` | `/api/admin/shippers/:id/status` | Duyệt / từ chối / tạm khóa shipper, gửi notification |

- Các endpoint shipper yêu cầu JWT role `shipper` (hoặc `admin` cho QA).
- Admin routes yêu cầu JWT + role `admin` (middleware `authorizeRoles`).
- Cập nhật trạng thái đơn: ghi lịch sử, đồng bộ `delivery_tracking`, bắn thông báo (FCM nếu cấu hình).

### 3. Ứng dụng Flutter (`app_giaohang`)

- Provider pattern tương tự `lalamove_app`.
- Luồng chính:
  1. Splash: đọc session lưu.
  2. Login: POST `/auth/login` (gửi `role: 'shipper'`; chặn login nếu status ≠ `approved`).
  3. Home: GET `/api/shippers/me/orders` với filter trạng thái.
  4. Detail: thông tin khách/shipper + Google Maps (2 marker) + timeline.
  5. Action button: PATCH status (ghi chú khi giao thất bại).
- Đăng ký shipper:
  - `RegisterShipperScreen` -> POST `/auth/register/shipper`.
  - Thông báo chờ duyệt, điều hướng về login.
- Thư mục:
  - `lib/utils/constants.dart`: token màu, text, endpoint.
  - `lib/providers/`: `AuthProvider` (login + register shipper), `OrderProvider`.
  - `lib/screens/`: `splash`, `auth/login`, `auth/register_shipper`, `home`, `orders/order_detail`.

### 4. Web Admin (`web_admin`)

- Sidebar thêm mục **Shipper**.
- Danh sách shipper: lọc theo trạng thái (`pending`, `approved`, `rejected`, `suspended`), xem chi tiết hồ sơ.
- Modal chi tiết: thông tin tài khoản, phương tiện, giấy tờ, ghi chú nội bộ.
- Hành động duyệt/từ chối/tạm khóa gọi `/api/admin/shippers/:id/status`, đồng thời gửi notification tới shipper.
- Script `assign-order-to-shipper.js` kiểm tra role + status `approved` trước khi gán.

### 5. Google Maps

- Android: cập nhật `android/app/src/main/res/values/strings.xml` với API key.
- iOS: cần cấu hình thêm trong `AppDelegate.swift` (TODO sprint sau).
- Nếu chưa có key: màn hình chi tiết hiển thị placeholder cảnh báo.

### 6. Kiểm thử nhanh

1. **Tạo/đặt lại tài khoản admin (nếu cần)**:
   ```bash
   node backend/scripts/create-admin.js
   ```
   → nhập email/mật khẩu mong muốn, script sẽ tự hash và đảm bảo role `admin`, status `active`.
2. **Đăng ký shipper**: mở app `app_giaohang`, chọn “Chưa có tài khoản? Đăng ký…”, điền form và submit.
3. **Duyệt hồ sơ trên web**:
   - Đăng nhập web admin.
   - Vào mục **Shipper**, mở hồ sơ `pending`, cập nhật ghi chú nếu cần và bấm **Duyệt**.
4. **Đăng nhập app sau khi duyệt**: đăng nhập lại, kéo làm mới danh sách.
5. **Gán đơn thử nghiệm** (nếu chưa có):
   ```bash
   node backend/scripts/assign-order-to-shipper.js
   ```
6. **Luồng giao hàng**:
   - Xem danh sách, mở chi tiết -> xác minh bản đồ + thông tin người nhận.
   - Bấm “Bắt đầu giao” / “Giao thành công” / “Giao thất bại”.
   - Kiểm tra DB: `orders.status`, `order_status_history`, `delivery_tracking.status`.
   - Xác minh khách hàng nhận notification (nếu client có FCM token).

### 7. Ghi chú

- Tính năng phân công tự động (US-21) chưa triển khai → tạm gán thủ công (SQL/script).
- Bản đồ hiện chỉ hiển thị marker pickup/delivery; routing sẽ phát triển sau.
- Nếu Firebase Admin chưa cấu hình, thông báo push sẽ được log cảnh báo và bỏ qua.
## Sprint 4 – Hướng dẫn tính năng Shipper

### 1. Schema & Migration

- Cột bổ sung:
  - `users.fcm_token`
  - `orders.shipper_id`, `pickup_lat`, `pickup_lng`, `delivery_lat`, `delivery_lng`
  - `orders.recipient_name`, `recipient_phone`, `distance`, `duration`, `services`, `base_fare`, `service_fee`
- Chạy lại backend (server tự đảm nhiệm `ALTER TABLE`) để cập nhật cấu trúc.
- Script hỗ trợ gán đơn cho shipper: `node backend/scripts/assign-order-to-shipper.js`

### 2. API mới

| Method | Endpoint | Ghi chú |
|--------|----------|---------|
| `GET` | `/api/shippers/me/orders` | Lấy danh sách đơn được gán cho shipper đang đăng nhập (có filter `status`) |
| `GET` | `/api/shippers/orders/:id` | Chi tiết đơn (pickup/delivery, customer info, lịch sử trạng thái) |
| `PATCH` | `/api/shippers/orders/:id/status` | Cập nhật trạng thái (`DELIVERING`, `DELIVERED_SUCCESS`, `DELIVERY_FAILED`, ...) |

- Các endpoint yêu cầu JWT và role `shipper` (hoặc `admin` cho mục đích kiểm thử).
- Mỗi lần cập nhật trạng thái, backend ghi lịch sử, đồng bộ `delivery_tracking` và gửi thông báo cho khách hàng (`notifications` + FCM nếu cấu hình).

### 3. Ứng dụng Flutter (`app_giaohang`)

- Provider-based architecture tương tự `lalamove_app`.
- Luồng chính:
  1. Splash -> kiểm tra session
  2. Login -> POST `/auth/login` kèm `role: 'shipper'`
  3. Home -> GET `/api/shippers/me/orders` + filter trạng thái
  4. Detail -> hiển thị thông tin + Google Maps (2 markers) + lịch sử
  5. Actions -> PATCH status (gửi ghi chú khi thất bại)
- Thư mục chính:
  - `lib/utils/constants.dart` : theme, endpoints, text
  - `lib/providers/` : `AuthProvider`, `OrderProvider`
  - `lib/screens/` : `splash`, `auth/login`, `home`, `orders/order_detail`

### 4. Google Maps

- Android: cập nhật `android/app/src/main/res/values/strings.xml` với API key.
- iOS: cần thêm key vào `AppDelegate.swift` (TODO cho sprint sau).
- Nếu chưa cấu hình, màn hình chi tiết hiển thị placeholder.

### 5. Kiểm thử nhanh

1. Tạo tài khoản role `shipper` (insert DB hoặc script riêng).
2. Gán đơn:
   ```bash
   node backend/scripts/assign-order-to-shipper.js
   ```
3. Đăng nhập app shipper, pull-to-refresh danh sách đơn.
4. Mở chi tiết -> xem bản đồ, thông tin khách hàng.
5. Cập nhật trạng thái -> kiểm tra:
   - Bảng `orders` đổi `status`
   - Bảng `order_status_history` thêm dòng
   - Bảng `delivery_tracking` đồng bộ `status`
   - Người dùng khách hàng nhận notification (nếu đã lưu FCM token)

### 6. Ghi chú

- Luồng phân công tự động (US-21) chưa triển khai → tạm gán thủ công qua script hoặc SQL.
- Map chỉ hiển thị điểm pickup/delivery; routing sẽ bổ sung ở sprint sau.
- Nếu chưa cấu hình Firebase Admin, thông báo push sẽ bị bỏ qua (có log cảnh báo).


