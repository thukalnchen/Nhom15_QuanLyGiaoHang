# QuanLyGiaoHang
Đề án môn Công nghệ phần mềm nâng cao. App Quản Lý Giao Hàng.

## TEAM DEVELOPMENT STRUCTURE

| No. | Name | Account | Roles | Date Start | Date End |
|-----|------|---------|-------|------------|----------|
| 1 | Trần Trọng Khang | https://github.com/thukalnchen | Scrum Master | 11/9/2025 | 19/11/2025 |
| 2 | Lê Quang Khải | https://github.com/QuangKhai117 | Product Owner | 11/9/2025 | 19/11/2025 |
| 3 | Giản Duy Khanh | https://github.com/GianDuyKhanh | Dev | 11/9/2025 | 19/11/2025 |
| 4 | Văn Ngọc Kha | https://github.com/kha004 | Dev | 11/9/2025 | 19/11/2025 |

## Cấu trúc dự án

```
DoAnCNPMNC/
├── backend/                 # Backend API (Node.js + Express + PostgreSQL)
├── app_user/               # Mobile App - Customer (Flutter)
├── app_intake/             # Mobile App - Intake Staff (Flutter)
├── app_driver/             # Mobile App - Driver (Flutter)
├── app_deliverer/          # Mobile App - Deliverer (Flutter)
├── app_giaohang/           # Mobile App - Shipper (Flutter)
├── lalamove_app/           # Unified Mobile App (Flutter)
└── web_admin/              # Web Admin Panel (HTML + Bootstrap)
```

## Tính năng chính

### Backend API
- ✅ Đăng ký/Đăng nhập với JWT
- ✅ Quản lý đơn hàng (CRUD)
- ✅ Theo dõi vị trí realtime với Socket.IO
- ✅ Xác thực và phân quyền
- ✅ Cơ sở dữ liệu PostgreSQL
- ✅ Quản lý kho (Warehouse)
- ✅ Quản lý khiếu nại (Complaints)
- ✅ Thông báo (Notifications)

### Mobile Apps (Flutter)
- ✅ Đăng ký/Đăng nhập
- ✅ Tạo đơn hàng
- ✅ Xem danh sách và chi tiết đơn hàng
- ✅ Theo dõi giao hàng
- ✅ Quản lý hồ sơ cá nhân
- ✅ Quét QR code (Intake Staff)
- ✅ Phân loại đơn hàng (Intake Staff)

### Web Admin Panel
- ✅ Dashboard với thống kê
- ✅ Quản lý đơn hàng
- ✅ Theo dõi vị trí realtime
- ✅ Quản lý người dùng
- ✅ Giao diện responsive với Bootstrap

## Cài đặt và chạy

### 1. Backend Setup

```bash
cd backend
npm install
```

**Tạo file cấu hình:**

Tạo file `config.env` từ file mẫu `config.env.example`:

```bash
# Windows
copy config.env.example config.env

# Linux/Mac
cp config.env.example config.env
```

Cập nhật thông tin database trong `config.env`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_delivery_db
DB_USER=postgres
DB_PASSWORD=your_password_here
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

**Chạy backend:**

```bash
npm run dev
```

Backend sẽ chạy tại: `http://localhost:3000`

### 2. Database Setup

Tạo database PostgreSQL:

```sql
CREATE DATABASE food_delivery_db;
```

Backend sẽ tự động tạo các bảng khi khởi động lần đầu.

### 3. Mobile App Setup

Chọn một trong các app để chạy:

#### Option 1: Unified App (lalamove_app)
```bash
cd lalamove_app
flutter pub get
flutter run
```

#### Option 2: Individual Apps
```bash
# Customer App
cd app_user
flutter pub get
flutter run

# Intake Staff App
cd app_intake
flutter pub get
flutter run

# Driver App
cd app_driver
flutter pub get
flutter run
```

**Cập nhật API URL** trong `lib/utils/constants.dart` nếu cần:

```dart
static const String apiBaseUrl = 'http://your-backend-url:3000/api';
```

### 4. Web Admin Setup

Mở file `web_admin/index.html` trong trình duyệt hoặc sử dụng live server.

Cập nhật API URL trong `js/admin.js` nếu cần:

```javascript
this.apiBaseUrl = 'http://your-backend-url:3000/api';
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `GET /api/auth/profile` - Lấy thông tin profile
- `PUT /api/auth/profile` - Cập nhật profile

### Orders
- `POST /api/orders` - Tạo đơn hàng
- `GET /api/orders` - Lấy danh sách đơn hàng
- `GET /api/orders/:id` - Lấy chi tiết đơn hàng
- `PUT /api/orders/:id/status` - Cập nhật trạng thái đơn hàng

### Tracking
- `PUT /api/tracking/:orderId/location` - Cập nhật vị trí
- `GET /api/tracking/:orderId/location` - Lấy vị trí hiện tại
- `GET /api/tracking/:orderId/history` - Lấy lịch sử vị trí

## Cấu trúc Database

### Users Table
- id, email, password, full_name, phone, address, role, created_at, updated_at

### Orders Table
- id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at

### Order Status History Table
- id, order_id, status, notes, created_at

### Delivery Tracking Table
- id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at

## Socket.IO Events

### Client Events
- `join-order` - Tham gia theo dõi đơn hàng
- `leave-order` - Rời khỏi theo dõi đơn hàng

### Server Events
- `location-update` - Cập nhật vị trí mới
- `order-status-update` - Cập nhật trạng thái đơn hàng

## Công nghệ sử dụng

### Backend
- Node.js
- Express.js
- PostgreSQL
- Socket.IO
- JWT
- bcryptjs
- Joi (validation)

### Mobile App
- Flutter
- Provider (state management)
- HTTP (API calls)
- Socket.IO Client
- Shared Preferences
- Google Maps Flutter (sẵn sàng tích hợp)

### Web Admin
- HTML5
- CSS3
- Bootstrap 5
- JavaScript (ES6+)
- Chart.js
- Socket.IO Client

## Tính năng trong tương lai

- [ ] Tích hợp Google Maps cho tracking
- [ ] Push notifications
- [ ] Payment integration
- [ ] Restaurant management
- [ ] Rating and reviews
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Offline support

## Troubleshooting

### Lỗi kết nối database
- Kiểm tra PostgreSQL đang chạy
- Kiểm tra thông tin kết nối trong `config.env`
- Đảm bảo database đã được tạo

### Lỗi CORS
- Kiểm tra CORS_ORIGIN trong `config.env`
- Thêm domain của bạn vào danh sách allowed origins

### Lỗi Flutter
- Chạy `flutter clean` và `flutter pub get`
- Kiểm tra API URL trong constants.dart
- Đảm bảo backend đang chạy

### File cấu hình bị thiếu
- Đảm bảo đã tạo file `backend/config.env` từ `backend/config.env.example`
- Kiểm tra các file `.local.properties` không được commit (đúng như mong muốn)

## Lưu ý quan trọng

⚠️ **File cấu hình:** File `backend/config.env` chứa thông tin nhạy cảm và không được commit vào git. Hãy tạo file này từ `backend/config.env.example` sau khi clone repository.

⚠️ **File local:** Các file như `local.properties` và `.vscode/settings.json` chứa đường dẫn local và không nên được commit. Chúng đã được thêm vào `.gitignore`.

## Liên hệ

Nếu có vấn đề hoặc câu hỏi, vui lòng tạo issue trong repository.

## License

MIT License
