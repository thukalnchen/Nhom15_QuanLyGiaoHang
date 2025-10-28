## 🔧 Sửa lỗi kết nối API

## ❌ Lỗi 1: Connection Timeout (ĐÃ SỬA ✅)
```
POST http://10.0.2.2:3000/api/auth/login net::ERR_CONNECTION_TIMED_OUT
```

**Nguyên nhân**: App chạy trên Web nhưng dùng URL Android Emulator

**Đã sửa**: Auto-detect platform trong `constants.dart`

---

## ❌ Lỗi 2: CORS Error (ĐÃ SỬA ✅)
```
Access to fetch at 'http://localhost:3000/api/auth/register' from origin 'http://localhost:64336' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present
```

**Nguyên nhân**: Backend chỉ allow CORS cho `localhost:3000`, không cho các ports khác

**Đã sửa**: Update `backend/server.js` để accept tất cả localhost origins

```javascript
// Cho phép tất cả localhost ports (development)
app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

---

## ✅ Đã sửa:

Đã cập nhật `app_user/lib/utils/constants.dart` để tự động detect platform:

```dart
// TỰ ĐỘNG CHỌN URL PHÙ HỢP:
- Web browser: http://localhost:3000/api
- Android Emulator: http://10.0.2.2:3000/api
```

## 🚀 Cách áp dụng thay đổi:

### Option 1: Hot Reload (Nhanh nhất)
Trong terminal Flutter app đang chạy, nhấn phím:
```
r
```

### Option 2: Hot Restart
Trong terminal Flutter app đang chạy, nhấn phím:
```
R
```

### Option 3: Stop & Restart
1. Trong terminal Flutter, nhấn `q` để stop
2. Chạy lại:
```bash
cd app_user
flutter run
```
Chọn `[2]: Chrome (chrome)`

---

## 📋 Checklist đảm bảo kết nối:

### 1. Backend đang chạy?
```bash
cd backend
node server.js
```

Bạn sẽ thấy:
```
✅ Connected to PostgreSQL database
✅ Database tables created successfully
🚀 Server is running on http://localhost:3000
```

### 2. Kiểm tra backend hoạt động:
Mở browser và vào:
```
http://localhost:3000/api/orders
```

Nếu thấy response (có thể là error 401 - OK!), backend đang hoạt động.

### 3. App đã update URL?
Sau khi hot reload/restart, thử login lại.

---

## 🎯 Test kết nối:

### Trong Flutter app:
1. Nhấn **Login** button
2. Nhập email & password test
3. Xem console log

### Nếu thành công:
✅ Không còn error `ERR_CONNECTION_TIMED_OUT`
✅ Có thể thấy response từ server (success hoặc error message)

### Nếu vẫn lỗi:

#### Lỗi 1: CORS Error
```
Access to XMLHttpRequest at 'http://localhost:3000/api/auth/login' 
from origin 'http://localhost:...' has been blocked by CORS policy
```

**Giải pháp**: Kiểm tra `backend/server.js` có enable CORS:
```javascript
app.use(cors());
```

#### Lỗi 2: Connection Refused
```
net::ERR_CONNECTION_REFUSED
```

**Giải pháp**: Backend chưa chạy, start lại:
```bash
cd backend
node server.js
```

#### Lỗi 3: 404 Not Found
```
GET http://localhost:3000/api/auth/login 404 (Not Found)
```

**Giải pháp**: Route chưa đúng, kiểm tra backend routes.

---

## 🔍 Debug Tips:

### 1. Xem log trong Flutter:
- Chrome DevTools: F12 → Console
- Xem network requests: F12 → Network tab

### 2. Xem log backend:
Terminal đang chạy `node server.js` sẽ hiện request logs

### 3. Test API trực tiếp:
Dùng Postman hoặc curl:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}'
```

---

## 📱 Platform URLs Reference:

| Platform | API URL | Note |
|----------|---------|------|
| Web (Chrome/Edge) | `http://localhost:3000/api` | ✅ Đã fix |
| Android Emulator | `http://10.0.2.2:3000/api` | ✅ Auto-detect |
| iOS Simulator | `http://localhost:3000/api` | Auto-detect |
| Physical Device | `http://YOUR_PC_IP:3000/api` | Cần update manual |

### Nếu dùng Physical Device:
1. Tìm IP máy tính:
```bash
ipconfig
# Tìm IPv4 Address, vd: 192.168.1.100
```

2. Update constants.dart:
```dart
static const String apiBaseUrl = 'http://192.168.1.100:3000/api';
```

---

## ✅ Kết luận:

**Đã sửa xong!** Chỉ cần:
1. Hot reload app (nhấn `r`)
2. Thử login lại
3. Backend đang chạy → App sẽ kết nối được!

---

**Last Updated**: 2025-10-28
**Status**: ✅ Fixed
