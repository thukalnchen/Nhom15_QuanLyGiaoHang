# Admin Panel - Hệ thống quản lý giao hàng

## 🚀 Hướng dẫn sử dụng

### Cách 1: Đăng nhập Demo (Không cần Backend)

1. Mở file `web_admin/login.html` trong trình duyệt
2. Click nút **"Đăng nhập Demo"**
3. Hệ thống sẽ tự động tạo dữ liệu mẫu và chuyển sang trang admin

**Lưu ý:** Ở chế độ Demo, tất cả dữ liệu là giả lập và không kết nối với database thực.

### Cách 2: Đăng nhập với Backend (Dữ liệu thực)

#### Bước 1: Khởi động Backend Server

```bash
cd backend
node server.js
```

Server sẽ chạy tại: `http://localhost:3000`

#### Bước 2: Tạo tài khoản Admin

Sử dụng API để đăng ký tài khoản:

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin",
    "email": "admin@example.com",
    "password": "admin123",
    "phone": "0987654321",
    "address": "123 Admin Street"
  }'
```

Hoặc dùng Postman/Thunder Client với:
- URL: `POST http://localhost:3000/api/auth/register`
- Body (JSON):
```json
{
  "name": "Admin",
  "email": "admin@example.com",
  "password": "admin123",
  "phone": "0987654321",
  "address": "123 Admin Street"
}
```

#### Bước 3: Đăng nhập

1. Mở `web_admin/login.html`
2. Nhập thông tin:
   - Email: `admin@example.com`
   - Password: `admin123`
3. Click "Đăng nhập"

## 📋 Tính năng

### ✅ Dashboard
- Thống kê tổng quan (Tổng đơn, Đã giao, Đang xử lý, Doanh thu)
- Biểu đồ đơn hàng 7 ngày
- Biểu đồ phân bổ trạng thái
- Bảng đơn hàng gần đây

### ✅ Quản lý đơn hàng
- Danh sách tất cả đơn hàng
- Lọc theo trạng thái
- Xem chi tiết đơn hàng
- Cập nhật trạng thái đơn hàng
- Real-time updates qua Socket.IO

### ✅ Theo dõi giao hàng
- Danh sách đơn hàng đang giao
- Vị trí real-time của shipper
- Thông tin chi tiết từng đơn

### ✅ Quản lý người dùng
- Danh sách người dùng
- Thông tin chi tiết user
- Lịch sử đơn hàng

### ✅ Thống kê Analytics
- Doanh thu theo ngày
- Top nhà hàng
- Phân tích xu hướng
- Filter theo thời gian (7/30/90 ngày)

## 🎨 Giao diện

- **Responsive Design**: Hoạt động tốt trên mọi thiết bị
- **Real-time Updates**: Tự động cập nhật khi có thay đổi
- **Beautiful Charts**: Biểu đồ đẹp mắt với Chart.js
- **Modern UI**: Giao diện hiện đại với Bootstrap 5

## 🔐 Bảo mật

- JWT Authentication
- Token stored in localStorage/sessionStorage
- Auto redirect khi session hết hạn
- CORS protection

## 🛠️ Công nghệ sử dụng

### Frontend
- HTML5, CSS3, JavaScript (ES6+)
- Bootstrap 5
- Chart.js
- Socket.IO Client
- Font Awesome Icons

### Backend API Endpoints
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/register` - Đăng ký
- `GET /api/admin/stats` - Dashboard statistics
- `GET /api/admin/orders` - Danh sách đơn hàng
- `GET /api/admin/orders/:id` - Chi tiết đơn hàng
- `PUT /api/admin/orders/:id/status` - Cập nhật trạng thái
- `GET /api/admin/deliveries/active` - Đơn hàng đang giao
- `GET /api/admin/users` - Danh sách người dùng
- `GET /api/admin/analytics` - Thống kê chi tiết

## 📱 Screenshots

### Login Page
- Giao diện đăng nhập đẹp mắt
- Hỗ trợ Demo mode

### Dashboard
- 4 stat cards với gradient đẹp
- 2 biểu đồ trực quan
- Bảng đơn hàng gần đây

### Order Management
- Bảng danh sách đầy đủ
- Filter theo trạng thái
- Modal chi tiết với khả năng cập nhật

## 🐛 Troubleshooting

### Lỗi 401 Unauthorized
- Kiểm tra token còn hạn không
- Thử đăng xuất và đăng nhập lại
- Hoặc dùng chế độ Demo

### Lỗi CORS
- Đảm bảo backend đang chạy
- Kiểm tra cấu hình CORS trong `server.js`

### Không load được dữ liệu
- Kiểm tra backend server đang chạy
- Mở Console (F12) để xem lỗi chi tiết
- Thử dùng chế độ Demo để kiểm tra giao diện

## 📞 Support

Nếu gặp vấn đề, hãy:
1. Kiểm tra Console (F12) để xem lỗi
2. Đảm bảo backend đang chạy
3. Thử chế độ Demo trước
4. Liên hệ team để được hỗ trợ

## 📝 Notes

- Chế độ Demo: Dữ liệu giả lập, không cần backend
- Chế độ Production: Kết nối database thực qua API
- Auto-refresh: Tự động làm mới mỗi 30 giây (chỉ ở chế độ Production)
- Real-time: Socket.IO cập nhật ngay lập tức khi có thay đổi
