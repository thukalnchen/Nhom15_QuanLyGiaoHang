# 👨‍💼 Hướng Dẫn Tài Khoản Admin

## ✅ Thiết Lập Hoàn Tất

### 1️⃣ Backend (Node.js)
- **File:** `controllers/authController.js`
- **Thay đổi:** Thêm `isAdmin` flag trong response login
- **Status:** ✅ Hoàn tất

### 2️⃣ Frontend (Flutter)
- **File tạo:** `lalamove_app/lib/screens/admin/admin_management_screen.dart`
- **File sửa:** `lalamove_app/lib/screens/auth/login_screen.dart`
- **Thay đổi:** 
  - Thêm `AdminManagementScreen` 
  - Thêm check `UserRole.admin` trong login
  - Auto-redirect admin → Admin Dashboard
- **Status:** ✅ Hoàn tất

### 3️⃣ Database
- **File:** `backend/scripts/create_admin.sql`
- **Status:** ✅ Script tạo sẵn

---

## 📝 Tạo Tài Khoản Admin

### Cách 1: Dùng Script SQL (Nhanh nhất)

```sql
-- Chạy trong PostgreSQL
INSERT INTO users (email, password, phone, name, role, created_at, status) 
VALUES (
  'admin@lalamove.com',
  'your_hashed_password',
  '0987654321',
  'Admin Lalamove',
  'admin',
  NOW(),
  'active'
) ON CONFLICT (email) DO UPDATE SET role = 'admin';
```

### Cách 2: Dùng API (Nếu có endpoint register)

```powershell
$adminData = @{
    email = "admin@lalamove.com"
    password = "Admin@123"
    phone = "0987654321"
    name = "Admin User"
    role = "admin"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3000/api/auth/register" `
                  -Body $adminData `
                  -Method POST `
                  -ContentType "application/json"
```

---

## 🔐 Thông Tin Tài Khoản

| Thông Tin | Giá Trị |
|-----------|--------|
| **Email** | `admin@lalamove.com` |
| **Password** | `Admin@123` hoặc tự đặt |
| **Phone** | `0987654321` |
| **Name** | `Admin Lalamove` |
| **Role** | `admin` |
| **Status** | `active` |

---

## 🎯 Chức Năng Admin Dashboard

Sau khi đăng nhập với role `admin`, bạn sẽ vào màn hình **Admin Management** với các tính năng:

### Story #20: Quản Lý Đơn Hàng
- ✅ Xem tất cả đơn hàng
- ✅ Cập nhật trạng thái đơn
- ✅ Xem chi tiết đơn hàng
- ✅ Thống kê đơn hàng

### Story #21: Gán Tài Xế
- ✅ Xem tài xế khả dụng
- ✅ Gán tài xế cho đơn
- ✅ Xem khối lượng công việc
- ✅ Reassign tài xế

### Story #22: Quản Lý Tuyến Đường
- ✅ Quản lý khu vực delivery
- ✅ Quản lý tuyến đường
- ✅ GPS-based zone detection
- ✅ Tìm kiếm khu vực

### Story #23: Chính Sách Giá
- ✅ Xem bảng giá
- ✅ Quản lý phí phụ
- ✅ Quản lý giảm giá
- ✅ Kiểm tra mã coupon

### Story #24: Báo Cáo
- ✅ Báo cáo doanh thu
- ✅ Thống kê giao hàng
- ✅ Hiệu suất tài xế
- ✅ Phân tích khách hàng
- ✅ Dashboard tổng quát

---

## 🔄 Quy Trình Đăng Nhập Admin

```
┌─────────────────────────────────────────────────────────────┐
│                   Login Screen                               │
│  Email: admin@lalamove.com                                  │
│  Password: Admin@123                                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│           Backend Login (authController.js)                  │
│  ✓ Check email & password                                    │
│  ✓ Generate JWT token                                        │
│  ✓ Return: { user: {..., isAdmin: true}, token: "..." }    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│        Frontend Check Role (login_screen.dart)               │
│  ✓ Kiểm tra user.role == 'admin'                            │
│  ✓ user.role == UserRole.admin                              │
│  ✓ Redirect → AdminManagementScreen                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│          Admin Dashboard (admin_management_screen.dart)      │
│  ✓ Hiển thị welcome message: "Chào mừng, Admin!"           │
│  ✓ Hiển thị 5 management sections (Story #20-24)           │
│  ✓ Navigation menu với logout                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧪 Test Admin Login

### 1. Chạy Backend
```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\backend"
npm start
# Output: 🚀 Server running on port 3000
```

### 2. Chạy Flutter
```powershell
cd "e:\linh Tinh\DoAn\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\lalamove_app"
flutter run -d chrome
```

### 3. Đăng Nhập
- Email: `admin@lalamove.com`
- Password: `Admin@123`

### 4. Kiểm Tra
- ✅ Xuất hiện Admin Dashboard
- ✅ Hiển thị 5 story sections
- ✅ Menu drawer với tên admin
- ✅ Nút logout hoạt động

---

## 📂 Files Đã Thay Đổi

| File | Thay Đổi | Status |
|------|---------|--------|
| `authController.js` | Thêm `isAdmin` flag | ✅ |
| `login_screen.dart` | Thêm `UserRole.admin` case | ✅ |
| `admin_management_screen.dart` | Tạo mới | ✅ |
| `create_admin.sql` | Tạo mới | ✅ |

---

## 💡 Lưu Ý

- Password trong database phải là hash (bcrypt)
- Role phải là string `'admin'`
- Frontend kiểm tra `user.role === 'admin'`
- Backend kiểm tra `authenticateToken` middleware
- Admin có quyền access tất cả routes

---

**Created:** November 12, 2025  
**Status:** ✅ Hoàn tất  
**Version:** 1.0

