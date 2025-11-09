# HƯỚNG DẪN CHẠY PROJECT - QUẢN LÝ GIAO HÀNG NHÓM 15

## 📋 MỤC LỤC
1. [Tổng quan hệ thống](#tổng-quan-hệ-thống)
2. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
3. [Cài đặt môi trường](#cài-đặt-môi-trường)
4. [Chạy Backend](#chạy-backend)
5. [Chạy App (lalamove_app)](#chạy-app)
6. [Chạy Web Admin (web_admin)](#chạy-web-admin)
8. [Tài khoản test](#tài-khoản-test)
9. [API Documentation](#api-documentation)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 TỔNG QUAN HỆ THỐNG

### Kiến trúc hệ thống
```
┌─────────────────┐
│  Flutter Apps   │
│  - Customer     │
│  - Driver       │
│  - Intake       │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Backend │ ← Node.js + Express
    │  API    │
    └────┬────┘
         │
    ┌────▼────────┐
    │ PostgreSQL  │ ← Database
    │  Database   │
    └─────────────┘
         │
    ┌────▼────────┐
    │  Web Admin  │ ← HTML/JS
    └─────────────┘
```

### Các ứng dụng trong project
- **Backend**: Node.js API server (port 3000)
- **lalamove_app**: Flutter app chính (hỗ trợ cả Customer và Driver với phân quyền role)
- **web_admin**: Web admin panel (HTML/CSS/JS)

---

## 💻 YÊU CẦU HỆ THỐNG

### Phần mềm cần cài đặt:
1. **Node.js** (v18 trở lên)
   - Download: https://nodejs.org/
   - Kiểm tra: `node --version` và `npm --version`

2. **PostgreSQL** (v12 trở lên)
   - Download: https://www.postgresql.org/download/
   - Kiểm tra: `psql --version`
   - **Password PostgreSQL**: `Trongkhang205@`

3. **Flutter SDK** (v3.0 trở lên)
   - Download: https://flutter.dev/docs/get-started/install
   - Kiểm tra: `flutter --version`
   - Chạy: `flutter doctor` để check thiếu gì

4. **Git**
   - Download: https://git-scm.com/
   - Kiểm tra: `git --version`

5. **VS Code** (khuyến nghị) hoặc Android Studio
   - VS Code: https://code.visualstudio.com/
   - Extensions khuyên dùng:
     - Flutter
     - Dart
     - PostgreSQL
     - REST Client

---

## 🔧 CÀI ĐẶT MÔI TRƯỜNG

> **Hướng dẫn này dành cho người mới clone project về máy lần đầu**

### Bước 1: Clone repository về máy
```bash
# Mở PowerShell hoặc Terminal
git clone https://github.com/thukalnchen/Nhom15_QuanLyGiaoHang.git

# Vào thư mục project
cd Nhom15_QuanLyGiaoHang
```

### Bước 2: Cài đặt PostgreSQL Database

#### 2.1. Khởi động PostgreSQL Service
```bash
# Kiểm tra PostgreSQL có chạy chưa
Get-Service -Name postgresql*

# Nếu Status = Stopped, thì start service
# Cách 1: Dùng PowerShell
Start-Service postgresql-x64-17

# Cách 2: Dùng Services GUI
# - Nhấn Windows + R → gõ "services.msc"
# - Tìm "postgresql-x64-17"
# - Right-click → Start
```

#### 2.2. Tạo Database
```bash
# Set password environment variable
$env:PGPASSWORD='Trongkhang205@'

# Kết nối vào PostgreSQL
psql -U postgres

# Trong psql prompt, chạy lệnh sau:
CREATE DATABASE food_delivery;

# Kiểm tra database đã tạo chưa
\l

# Thoát psql
\q
```

**⚠️ Lưu ý:** Password của PostgreSQL là `Trongkhang205@`

### Bước 3: Cài đặt Backend (Node.js)

#### 3.1. Vào thư mục backend
```bash
# Từ thư mục gốc project
cd DoAnCNPMNC/backend
```

#### 3.2. Cài đặt Node packages
```bash
# Cài đặt tất cả dependencies từ package.json
npm install

# Chờ khoảng 1-2 phút để npm tải về các packages
# Bạn sẽ thấy progress bar và danh sách packages được cài
```

**Packages sẽ được cài đặt:**
- express (Web framework)
- pg (PostgreSQL client)
- cors (Cross-Origin Resource Sharing)
- jsonwebtoken (JWT authentication)
- bcryptjs (Password hashing)
- pdfkit (PDF generation)
- nodemon (Auto-restart server khi code thay đổi)

#### 3.3. Kiểm tra file config
```bash
# Xem nội dung file config.env
cat config.env

# Hoặc mở bằng VS Code
code config.env
```

File `backend/config.env` phải có nội dung:
```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=Trongkhang205@
DB_NAME=food_delivery
JWT_SECRET=your-secret-key-here-change-in-production
JWT_EXPIRE=7d
NODE_ENV=development
```

**⚠️ QUAN TRỌNG:**
- `DB_PASSWORD` phải là `Trongkhang205@` (đúng với password PostgreSQL)
- `PORT=3000` - Backend sẽ chạy ở port này
- Không được commit file này lên Git (đã có trong .gitignore)

### Bước 4: Cài đặt Flutter App

#### 4.1. Vào thư mục Flutter app
```bash
# Quay lại thư mục gốc
cd ../..

# Vào thư mục lalamove_app
cd DoAnCNPMNC/lalamove_app
```

#### 4.2. Cài đặt Flutter dependencies
```bash
# Tải về tất cả packages từ pubspec.yaml
flutter pub get

# Chờ khoảng 30 giây - 1 phút
# Bạn sẽ thấy danh sách packages được download
```

**Packages sẽ được cài đặt:**
- provider (State management)
- http (API calls)
- shared_preferences (Local storage)
- intl (Date/Number formatting)
- pdf (PDF generation)
- google_maps_flutter (Maps - nếu có)
- geolocator (GPS location)

#### 4.3. Kiểm tra Flutter có hoạt động không
```bash
# Check Flutter doctor
flutter doctor

# Kích hoạt web support (nếu chưa có)
flutter config --enable-web

# Xem danh sách devices có thể chạy
flutter devices
```

**Kết quả mong đợi:**
```
2 connected devices:

Chrome (web) • chrome • web-javascript • Google Chrome
Edge (web)   • edge   • web-javascript • Microsoft Edge
```

### Bước 5: Kiểm tra cài đặt hoàn tất

#### 5.1. Kiểm tra Backend
```bash
# Vào thư mục backend (nếu chưa ở đó)
cd ../../backend

# Liệt kê các packages đã cài
npm list --depth=0

# Kiểm tra version
node --version
npm --version
```

#### 5.2. Kiểm tra Flutter
```bash
# Vào thư mục lalamove_app
cd ../lalamove_app

# Liệt kê packages
flutter pub deps

# Kiểm tra version
flutter --version
```

#### 5.3. Kiểm tra PostgreSQL
```bash
# Check service status
Get-Service postgresql-x64-17

# Kết nối thử
$env:PGPASSWORD='Trongkhang205@'
psql -U postgres -d food_delivery -c "SELECT version();"

# Nếu thành công sẽ hiển thị version của PostgreSQL
```

### Bước 6: Tóm tắt cấu trúc thư mục sau khi cài đặt

```
Nhom15_QuanLyGiaoHang/
├── DoAnCNPMNC/
│   ├── backend/
│   │   ├── node_modules/          ← ✅ Đã cài (npm install)
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   ├── config.env             ← ✅ Đã kiểm tra
│   │   └── server.js
│   │
│   ├── lalamove_app/
│   │   ├── .dart_tool/            ← ✅ Tự động tạo
│   │   ├── pubspec.yaml
│   │   ├── pubspec.lock
│   │   └── lib/
│   │
│   └── web_admin/
│       └── index.html
│
└── README.md
```

### ✅ Checklist hoàn thành cài đặt:

- [ ] Git đã clone project về máy
- [ ] PostgreSQL service đang chạy
- [ ] Database `food_delivery` đã được tạo
- [ ] Backend: `npm install` hoàn tất, có thư mục `node_modules/`
- [ ] Backend: File `config.env` có đúng config
- [ ] Flutter: `flutter pub get` hoàn tất
- [ ] Flutter doctor không có lỗi critical
- [ ] Chrome đã enable cho Flutter web

**🎉 Nếu tất cả đã ✅ → Bạn đã sẵn sàng chạy project!**

**➡️ Tiếp theo:** Đọc phần [Chạy Backend](#🚀-chạy-backend) để khởi động server

---

## 🚀 CHẠY BACKEND

### Bước 1: Khởi động PostgreSQL
- Mở **Services** (Windows + R → `services.msc`)
- Tìm "postgresql-x64-17" 
- Click **Start** nếu chưa chạy

### Bước 2: Chạy Backend Server
```bash
# Từ thư mục gốc project
cd DoAnCNPMNC/backend

# Chạy development mode (auto-restart khi có thay đổi)
npm run dev

# Hoặc chạy production mode
npm start
```

### Bước 3: Kiểm tra Backend
Mở browser và truy cập:
- **Health check**: http://localhost:3000/api/health
- **API test**: http://localhost:3000/api/test

Nếu thấy response JSON → Backend đã chạy thành công! ✅

### Database sẽ tự động tạo các bảng:
- `users` - Tài khoản người dùng
- `orders` - Đơn hàng
- `delivery_tracking` - Theo dõi giao hàng
- `notifications` - Thông báo
- `complaints` - Khiếu nại
- `complaint_responses` - Phản hồi khiếu nại

---

## 📱 CHẠY APP (lalamove_app)

### App này hỗ trợ 2 loại người dùng với phân quyền role:

#### 🛍️ **KHÁCH HÀNG (Customer)**
Chức năng chính:
- ✅ Đăng ký / Đăng nhập
- ✅ Tạo đơn hàng giao hàng
- ✅ Theo dõi đơn hàng real-time trên bản đồ
- ✅ Xem lịch sử đơn hàng
- ✅ Thanh toán online
- ✅ Đánh giá tài xế
- ✅ Nhận thông báo
- ✅ Khiếu nại đơn hàng
- ✅ Xuất hóa đơn PDF

#### 🚗 **TÀI XẾ (Driver)**
Chức năng chính:
- ✅ Đăng nhập với role "driver"
- ✅ Nhận đơn hàng mới
- ✅ Xem chi tiết đơn hàng
- ✅ Cập nhật trạng thái giao hàng
- ✅ Theo dõi vị trí GPS real-time
- ✅ Xem lịch sử giao hàng
- ✅ Báo cáo thu nhập

> **Lưu ý**: App sẽ tự động hiển thị UI phù hợp dựa trên `role` của user sau khi login:
> - `role: "customer"` → Hiển thị giao diện khách hàng
> - `role: "driver"` → Hiển thị giao diện tài xế

### Bước 1: Cài đặt dependencies
```bash
cd DoAnCNPMNC/lalamove_app
flutter pub get
```

### Bước 2: Chạy app
```bash
# Chạy trên Chrome (Web)
flutter run -d chrome

# Chạy trên Android emulator
flutter run -d emulator-5554

# Chạy trên device thật
flutter run
```

### Bước 3: Login với tài khoản test

#### Tài khoản Customer:
```
Email: test123@gmail.com
Password: 123456
Role: customer
```

#### Tài khoản Driver (cần tạo - xem phần [Tài khoản test](#tài-khoản-test)):
```
Email: driver1@gmail.com
Password: 123456
Role: driver
```

### Cấu trúc thư mục quan trọng:
```
lalamove_app/
├── lib/
│   ├── main.dart              # Entry point
│   ├── models/                # Data models
│   │   ├── order_model.dart
│   │   ├── complaint_model.dart
│   │   └── notification_model.dart
│   ├── providers/             # State management
│   │   ├── auth_provider.dart
│   │   ├── order_provider.dart
│   │   ├── complaint_provider.dart
│   │   └── notification_provider.dart
│   ├── screens/               # UI screens
│   │   ├── auth/              # Login/Register
│   │   ├── customer/          # Customer features
│   │   │   ├── home/
│   │   │   ├── orders/
│   │   │   ├── complaints/
│   │   │   └── notifications/
│   │   └── driver/            # Driver features
│   ├── services/              # API services
│   │   ├── api_service.dart
│   │   └── pdf_service.dart
│   ├── utils/                 # Utilities
│   │   ├── app_constants.dart # API URLs, constants
│   │   └── app_colors.dart
│   └── widgets/               # Reusable widgets
```

### File config quan trọng:
**`lib/utils/app_constants.dart`**
```dart
static const String apiBaseUrl = 'http://localhost:3000/api';
```
⚠️ **Đổi `localhost` thành IP máy backend nếu test trên device thật**

### Kiến trúc phân quyền Role-based:

App `lalamove_app` sử dụng **role-based UI** để hiển thị giao diện khác nhau cho từng loại người dùng:

```dart
// Trong main.dart hoặc routing logic
if (user.role == 'customer') {
  // Navigate to Customer Home Screen
  Navigator.pushReplacement(context, MaterialPageRoute(
    builder: (context) => CustomerHomeScreen()
  ));
} else if (user.role == 'driver') {
  // Navigate to Driver Home Screen
  Navigator.pushReplacement(context, MaterialPageRoute(
    builder: (context) => DriverHomeScreen()
  ));
}
```

#### Flow xử lý đơn hàng cho Driver:
```
1. Login với role "driver"
   ↓
2. Màn hình Driver Dashboard hiển thị
   ↓
3. Xem danh sách đơn hàng available (tab "Đơn mới")
   ↓
4. Chọn đơn → Accept (status: accepted)
   ↓
5. Đến lấy hàng → Click "Đã lấy hàng" (status: picked_up)
   ↓
6. Đang giao → GPS tracking (status: on_delivery)
   ↓
7. Đến nơi → Click "Hoàn thành" (status: delivered)
```

---

## 🌐 CHẠY WEB ADMIN (web_admin)

### Web này dành cho: QUẢN TRỊ VIÊN
Chức năng chính:
- ✅ Quản lý người dùng (khách hàng, tài xế)
- ✅ Quản lý đơn hàng
- ✅ Xem báo cáo thống kê
- ✅ Quản lý khiếu nại
- ✅ Cấu hình hệ thống

### Cách 1: Mở trực tiếp bằng browser
```bash
# Mở file HTML
DoAnCNPMNC/web_admin/index.html
```
Kéo thả file vào Chrome hoặc double-click

### Cách 2: Dùng Live Server (khuyên dùng)
```bash
# Cài đặt Live Server (nếu chưa có)
npm install -g live-server

# Chạy web server
cd DoAnCNPMNC/web_admin
live-server
```
Web sẽ mở tại: http://localhost:8080

### Login Web Admin
```
Username: admin
Password: admin123
```
(Hoặc dùng tài khoản có role="admin" trong database)

### Cấu trúc web_admin:
```
web_admin/
├── index.html           # Trang chính
├── login.html           # Trang đăng nhập
├── js/
│   ├── main.js         # Logic chính
│   ├── api.js          # API calls
│   └── charts.js       # Biểu đồ thống kê
├── css/
│   └── style.css       # Styles
└── README.md
```

### Config API trong web_admin:
File: `web_admin/js/api.js`
```javascript
const API_BASE_URL = 'http://localhost:3000/api';
```

### Features cần implement cho web_admin:
- [ ] Dashboard với charts (đơn hàng, doanh thu)
- [ ] Quản lý user (CRUD)
- [ ] Quản lý tài xế (approve, suspend)
- [ ] Xem chi tiết đơn hàng
- [ ] Xử lý khiếu nại
- [ ] Export báo cáo (Excel, PDF)
- [ ] Cấu hình phí giao hàng
- [ ] Quản lý thông báo hệ thống

---

## 👥 TÀI KHOẢN TEST

### Backend Database có sẵn:

#### Khách hàng (Customer)
```
Email: test123@gmail.com
Password: 123456
Role: customer
User ID: 5
```

#### Tài xế (Driver) - Cần tạo mới
```
Email: driver1@gmail.com
Password: 123456
Role: driver
```

#### Admin - Cần tạo mới
```
Email: admin@gmail.com
Password: admin123
Role: admin
```

### Cách tạo tài khoản mới qua API:

**1. Register qua Postman/Thunder Client:**
```http
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "email": "driver1@gmail.com",
  "password": "123456",
  "full_name": "Nguyễn Văn Tài Xế",
  "phone_number": "0912345678",
  "role": "driver"
}
```

**2. Update role thành admin (nếu cần):**
```sql
-- Chạy trong psql
UPDATE users SET role = 'admin' WHERE email = 'admin@gmail.com';
```

---

## 📚 API DOCUMENTATION

### Base URL
```
http://localhost:3000/api
```

### Authentication Endpoints

#### 1. Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "Nguyen Van A",
  "phone_number": "0901234567",
  "role": "customer"  // customer | driver | admin
}

Response 201:
{
  "success": true,
  "message": "Đăng ký thành công",
  "data": {
    "user": { ... },
    "token": "jwt_token_here"
  }
}
```

#### 2. Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "test123@gmail.com",
  "password": "123456"
}

Response 200:
{
  "success": true,
  "data": {
    "user": {
      "id": 5,
      "email": "test123@gmail.com",
      "full_name": "Test User",
      "role": "customer"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 3. Get Profile
```http
GET /api/auth/profile
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": { user object }
}
```

### Order Endpoints

#### 1. Create Order
```http
POST /api/orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "restaurant_name": "Nhà hàng ABC",
  "items": [
    {
      "name": "Phở bò",
      "quantity": 2,
      "price": 50000
    }
  ],
  "total_amount": 100000,
  "delivery_fee": 20000,
  "delivery_address": "123 Nguyễn Văn Linh, Q7, TP.HCM",
  "delivery_phone": "0901234567",
  "notes": "Gọi trước khi đến"
}

Response 201:
{
  "success": true,
  "data": { order object }
}
```

#### 2. Get My Orders
```http
GET /api/orders/my-orders?page=1&limit=10&status=all
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "orders": [ ... ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 50,
      "totalPages": 5
    }
  }
}
```

#### 3. Get Order Detail
```http
GET /api/orders/:orderId
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": { order object with tracking }
}
```

#### 4. Cancel Order
```http
POST /api/orders/:orderId/cancel
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Đặt nhầm địa chỉ",
  "cancellation_type": "customer"
}

Response 200:
{
  "success": true,
  "message": "Đơn hàng đã được hủy"
}
```

### Notification Endpoints (Story #5)

#### 1. Get My Notifications
```http
GET /api/notifications/my-notifications?page=1&limit=20&is_read=all
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 1,
        "title": "Đơn hàng mới",
        "message": "Đơn hàng ORDER-123 đã được tạo",
        "type": "order_created",
        "is_read": false,
        "created_at": "2025-11-09T10:30:00Z"
      }
    ],
    "pagination": { ... },
    "unread_count": 5
  }
}
```

#### 2. Mark as Read
```http
PUT /api/notifications/:notificationId/read
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "message": "Đã đánh dấu là đã đọc"
}
```

#### 3. Mark All as Read
```http
PUT /api/notifications/read-all
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "message": "Đã đánh dấu tất cả là đã đọc"
}
```

### Complaint Endpoints (Story #6)

#### 1. Create Complaint
```http
POST /api/complaints
Authorization: Bearer {token}
Content-Type: application/json

{
  "order_id": 123,
  "title": "Tài xế giao hàng chậm",
  "description": "Đơn hàng giao quá 2 tiếng so với dự kiến",
  "complaint_type": "delivery_issue"
}

Response 201:
{
  "success": true,
  "data": { complaint object }
}
```

#### 2. Get My Complaints
```http
GET /api/complaints/my-complaints?page=1&limit=10&status=all
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "complaints": [ ... ],
    "pagination": { ... }
  }
}
```

#### 3. Get Complaint Detail
```http
GET /api/complaints/:complaintId
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "complaint": { ... },
    "responses": [ ... ]
  }
}
```

#### 4. Send Response
```http
POST /api/complaints/:complaintId/responses
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": "Tôi muốn được hoàn tiền"
}

Response 201:
{
  "success": true,
  "data": { response object }
}
```

### Receipt Endpoints (Story #11)

#### 1. Generate PDF Receipt
```http
GET /api/receipts/:orderId/pdf
Authorization: Bearer {token}

Response 200:
Content-Type: application/pdf
(File PDF download)
```

#### 2. Get Receipt Data
```http
GET /api/receipts/:orderId
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "order": { ... },
    "customer": { ... },
    "payment": { ... }
  }
}
```

---

## 🔍 TROUBLESHOOTING

### 1. Backend không khởi động được

**Lỗi: "Port 3000 already in use"**
```bash
# Windows - Kill process trên port 3000
Get-Process -Name node -ErrorAction SilentlyContinue | Stop-Process -Force

# Hoặc dùng netstat
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

**Lỗi: "Cannot connect to PostgreSQL"**
```bash
# Check PostgreSQL có chạy không
Get-Service -Name postgresql*

# Restart PostgreSQL
Restart-Service postgresql-x64-17

# Hoặc check password trong config.env
DB_PASSWORD=Trongkhang205@
```

**Lỗi: "Database does not exist"**
```bash
# Tạo database
$env:PGPASSWORD='Trongkhang205@'
psql -U postgres -c "CREATE DATABASE food_delivery;"
```

### 2. Flutter app không build được

**Lỗi: "Pub get failed"**
```bash
# Clear cache và reinstall
flutter clean
flutter pub get
```

**Lỗi: "No devices found"**
```bash
# Check devices
flutter devices

# Bật Chrome cho web
flutter config --enable-web
```

**Lỗi: "SDK version mismatch"**
```bash
# Update Flutter
flutter upgrade
flutter pub upgrade
```

### 3. API call bị lỗi 401 Unauthorized

**Nguyên nhân**: Token hết hạn hoặc không valid

**Giải pháp**:
```dart
// Check token trong Flutter
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token');
print('Token: $token');

// Login lại để lấy token mới
```

### 4. CORS error khi gọi API từ web

**Lỗi**: "Access to fetch at 'http://localhost:3000/api' blocked by CORS"

**Giải pháp**: Backend đã config CORS trong `server.js`:
```javascript
app.use(cors({
  origin: '*',
  credentials: true
}));
```

Nếu vẫn lỗi, restart backend server.

### 5. Database schema lỗi

**Lỗi**: "column does not exist" hoặc "relation does not exist"

**Giải pháp**: Drop và tạo lại database
```sql
-- Trong psql
DROP DATABASE food_delivery;
CREATE DATABASE food_delivery;
\q

-- Restart backend để tự tạo tables
npm run dev
```

### 6. Flutter hot reload không work

```bash
# Stop app và rebuild
flutter clean
flutter run
```

### 7. Web admin không load được data

**Check console trong browser (F12)**:
- API URL có đúng không?
- Token có được gửi trong header không?
- Response status code là gì?

**Fix**: Đảm bảo backend đang chạy và API URL đúng trong `js/api.js`

---

## 📝 CHECKLIST TRƯỚC KHI BẮT ĐẦU

### Backend:
- [ ] PostgreSQL đã cài đặt và đang chạy
- [ ] Database `food_delivery` đã được tạo
- [ ] Node.js đã cài đặt (v18+)
- [ ] File `backend/config.env` có đúng config
- [ ] Chạy `npm install` trong thư mục backend
- [ ] Chạy `npm run dev` và thấy "Server running on port 3000"
- [ ] Test API: http://localhost:3000/api/health

### Flutter Apps (lalamove_app):
- [ ] Flutter SDK đã cài đặt
- [ ] Chạy `flutter doctor` không có lỗi critical
- [ ] Chrome đã được enable: `flutter config --enable-web`
- [ ] Chạy `flutter pub get` trong app folder
- [ ] File `lib/utils/app_constants.dart` có đúng API URL
- [ ] Có tài khoản test để login (customer và driver)

### Web Admin:
- [ ] File `web_admin/js/api.js` có đúng API URL
- [ ] Có tài khoản admin để login
- [ ] Browser hỗ trợ ES6+

---

## 🎓 THÔNG TIN QUAN TRỌNG CHO NGƯỜI LÀM WEB_ADMIN

### Về phân quyền trong lalamove_app:

App `lalamove_app` đã được thiết kế để hỗ trợ **cả Customer và Driver** trong cùng 1 app:
- Sau khi login, app sẽ check `user.role`
- Nếu `role == "customer"` → Hiển thị UI cho khách hàng (tạo đơn, theo dõi, thanh toán...)
- Nếu `role == "driver"` → Hiển thị UI cho tài xế (nhận đơn, giao hàng, GPS tracking...)

### API Endpoints cho Driver (đã có sẵn trong backend):

```javascript
// Driver Orders Management
GET /api/driver/orders              // Danh sách đơn hàng available
GET /api/driver/orders/:id          // Chi tiết đơn hàng
POST /api/driver/orders/:id/accept  // Nhận đơn
POST /api/driver/orders/:id/pickup  // Đã lấy hàng
POST /api/driver/orders/:id/complete // Hoàn thành giao hàng
PUT /api/driver/location            // Update vị trí GPS real-time

// Driver Profile & Statistics
GET /api/driver/profile
PUT /api/driver/profile
GET /api/driver/statistics          // Thống kê thu nhập, số đơn
GET /api/driver/earnings?from=&to=  // Doanh thu theo thời gian
```

### Screens trong lalamove_app:

```
lib/screens/
├── auth/
│   ├── login_screen.dart           # Chung cho cả customer và driver
│   └── register_screen.dart
├── customer/                        # UI cho khách hàng
│   ├── home/
│   ├── orders/
│   ├── complaints/
│   └── notifications/
└── driver/                          # UI cho tài xế
    ├── home/
    │   └── driver_home_screen.dart # Dashboard tài xế
    ├── orders/
    │   ├── available_orders_tab.dart   # Đơn mới
    │   ├── my_orders_tab.dart          # Đơn đã nhận
    │   └── order_detail_screen.dart
    ├── map/
    │   └── delivery_map_screen.dart    # GPS tracking
    └── profile/
        ├── driver_profile_screen.dart
        └── earnings_screen.dart        # Thống kê thu nhập
```

---

### Cho người làm WEB_ADMIN:

#### 1. Cấu trúc HTML pages:
```
web_admin/
├── login.html              # Trang login
├── index.html              # Dashboard chính
├── users.html              # Quản lý users
├── drivers.html            # Quản lý tài xế
├── orders.html             # Quản lý đơn hàng
├── complaints.html         # Quản lý khiếu nại
├── settings.html           # Cấu hình hệ thống
└── reports.html            # Báo cáo thống kê
```

#### 2. JavaScript modules:
```javascript
// js/api.js
const API_BASE_URL = 'http://localhost:3000/api';

class API {
  static async login(email, password) { ... }
  static async getUsers(page, limit) { ... }
  static async getOrders(filters) { ... }
  static async updateUser(userId, data) { ... }
  static async deleteUser(userId) { ... }
}

// js/auth.js
class Auth {
  static saveToken(token) {
    localStorage.setItem('admin_token', token);
  }
  
  static getToken() {
    return localStorage.getItem('admin_token');
  }
  
  static logout() {
    localStorage.removeItem('admin_token');
    window.location.href = 'login.html';
  }
}

// js/dashboard.js
async function loadDashboardStats() {
  // Load statistics
  const stats = await API.getDashboardStats();
  
  // Update UI
  document.getElementById('total-users').textContent = stats.totalUsers;
  document.getElementById('total-orders').textContent = stats.totalOrders;
  // ...
  
  // Render charts
  renderOrdersChart(stats.ordersData);
  renderRevenueChart(stats.revenueData);
}
```

#### 3. API Endpoints cho admin:
```javascript
// Users Management
GET /api/admin/users?page=1&limit=20&role=all
GET /api/admin/users/:userId
PUT /api/admin/users/:userId
DELETE /api/admin/users/:userId
POST /api/admin/users/:userId/suspend

// Drivers Management
GET /api/admin/drivers?status=all
PUT /api/admin/drivers/:driverId/approve
PUT /api/admin/drivers/:driverId/suspend
GET /api/admin/drivers/:driverId/statistics

// Orders Management
GET /api/admin/orders?status=all&from=&to=
GET /api/admin/orders/:orderId
PUT /api/admin/orders/:orderId/status
DELETE /api/admin/orders/:orderId

// Complaints Management
GET /api/admin/complaints?status=all
GET /api/admin/complaints/:complaintId
PUT /api/admin/complaints/:complaintId/resolve
POST /api/admin/complaints/:complaintId/response

// Statistics & Reports
GET /api/admin/dashboard/stats
GET /api/admin/reports/revenue?from=&to=
GET /api/admin/reports/orders?from=&to=
GET /api/admin/reports/drivers?from=&to=
```

#### 4. Sample HTML structure:
```html
<!-- users.html -->
<!DOCTYPE html>
<html>
<head>
  <title>Quản lý người dùng - Admin</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="container">
    <aside class="sidebar">
      <nav>
        <a href="index.html">Dashboard</a>
        <a href="users.html" class="active">Users</a>
        <a href="drivers.html">Drivers</a>
        <a href="orders.html">Orders</a>
        <a href="complaints.html">Complaints</a>
      </nav>
    </aside>
    
    <main class="content">
      <header>
        <h1>Quản lý người dùng</h1>
        <button onclick="showAddUserModal()">+ Thêm user</button>
      </header>
      
      <section class="filters">
        <input type="search" id="search" placeholder="Tìm kiếm...">
        <select id="roleFilter">
          <option value="all">Tất cả</option>
          <option value="customer">Khách hàng</option>
          <option value="driver">Tài xế</option>
          <option value="admin">Admin</option>
        </select>
      </section>
      
      <table id="usersTable">
        <thead>
          <tr>
            <th>ID</th>
            <th>Email</th>
            <th>Tên</th>
            <th>Số điện thoại</th>
            <th>Role</th>
            <th>Ngày tạo</th>
            <th>Hành động</th>
          </tr>
        </thead>
        <tbody>
          <!-- Loaded by JS -->
        </tbody>
      </table>
      
      <div class="pagination" id="pagination">
        <!-- Loaded by JS -->
      </div>
    </main>
  </div>
  
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/users.js"></script>
</body>
</html>
```

#### 5. Sample JavaScript for users page:
```javascript
// js/users.js
let currentPage = 1;
const limit = 20;

async function loadUsers() {
  try {
    const role = document.getElementById('roleFilter').value;
    const search = document.getElementById('search').value;
    
    const response = await fetch(
      `${API_BASE_URL}/admin/users?page=${currentPage}&limit=${limit}&role=${role}&search=${search}`,
      {
        headers: {
          'Authorization': `Bearer ${Auth.getToken()}`
        }
      }
    );
    
    if (response.status === 401) {
      Auth.logout();
      return;
    }
    
    const data = await response.json();
    
    if (data.success) {
      renderUsersTable(data.data.users);
      renderPagination(data.data.pagination);
    }
  } catch (error) {
    console.error('Error loading users:', error);
    alert('Lỗi tải danh sách users');
  }
}

function renderUsersTable(users) {
  const tbody = document.querySelector('#usersTable tbody');
  tbody.innerHTML = '';
  
  users.forEach(user => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${user.id}</td>
      <td>${user.email}</td>
      <td>${user.full_name}</td>
      <td>${user.phone_number || '-'}</td>
      <td><span class="badge ${user.role}">${user.role}</span></td>
      <td>${new Date(user.created_at).toLocaleDateString('vi-VN')}</td>
      <td>
        <button onclick="editUser(${user.id})">Sửa</button>
        <button onclick="deleteUser(${user.id})" class="danger">Xóa</button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

async function deleteUser(userId) {
  if (!confirm('Bạn có chắc muốn xóa user này?')) return;
  
  try {
    const response = await fetch(`${API_BASE_URL}/admin/users/${userId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${Auth.getToken()}`
      }
    });
    
    const data = await response.json();
    
    if (data.success) {
      alert('Xóa thành công');
      loadUsers();
    } else {
      alert('Lỗi: ' + data.message);
    }
  } catch (error) {
    alert('Lỗi xóa user');
  }
}

// Load on page ready
document.addEventListener('DOMContentLoaded', () => {
  // Check auth
  if (!Auth.getToken()) {
    window.location.href = 'login.html';
    return;
  }
  
  loadUsers();
  
  // Event listeners
  document.getElementById('search').addEventListener('input', debounce(loadUsers, 500));
  document.getElementById('roleFilter').addEventListener('change', loadUsers);
});
```

#### 6. Charts với Chart.js:
```html
<!-- Thêm vào index.html -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<div class="charts">
  <canvas id="ordersChart"></canvas>
  <canvas id="revenueChart"></canvas>
</div>
```

```javascript
// js/charts.js
function renderOrdersChart(data) {
  const ctx = document.getElementById('ordersChart').getContext('2d');
  
  new Chart(ctx, {
    type: 'line',
    data: {
      labels: data.labels, // ['1/11', '2/11', '3/11', ...]
      datasets: [{
        label: 'Số đơn hàng',
        data: data.values, // [10, 15, 20, ...]
        borderColor: 'rgb(75, 192, 192)',
        tension: 0.1
      }]
    },
    options: {
      responsive: true,
      plugins: {
        title: {
          display: true,
          text: 'Đơn hàng theo ngày'
        }
      }
    }
  });
}

function renderRevenueChart(data) {
  const ctx = document.getElementById('revenueChart').getContext('2d');
  
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: data.labels,
      datasets: [{
        label: 'Doanh thu (VNĐ)',
        data: data.values,
        backgroundColor: 'rgba(54, 162, 235, 0.5)',
        borderColor: 'rgb(54, 162, 235)',
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            callback: function(value) {
              return value.toLocaleString('vi-VN') + ' đ';
            }
          }
        }
      }
    }
  });
}
```

---

