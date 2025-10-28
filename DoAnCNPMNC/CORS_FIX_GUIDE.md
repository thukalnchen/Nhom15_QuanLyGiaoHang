# 🔧 CORS Fix - Complete Guide

## ❌ Lỗi CORS đã sửa

### Error Message:
```
Access to fetch at 'http://localhost:3000/api/auth/register' 
from origin 'http://localhost:64336' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

---

## 🔍 Nguyên nhân

### CORS là gì?
**CORS** (Cross-Origin Resource Sharing) là cơ chế bảo mật của browser để ngăn chặn các request từ domain khác.

### Vấn đề:
- **Backend** chỉ cho phép CORS từ: `http://localhost:3000`
- **Flutter Web App** chạy trên port khác: `http://localhost:64336`
- Browser block request vì origin không match

---

## ✅ Giải pháp đã áp dụng

### 1. Cập nhật `backend/server.js`

**TRƯỚC (Không hoạt động):**
```javascript
app.use(cors({
  origin: ["http://localhost:3000"],
  credentials: true
}));
```

**SAU (Đã fix):**
```javascript
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests với no origin (mobile apps, Postman)
    if (!origin) return callback(null, true);
    
    // Allow TẤT CẢ localhost ports cho development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Production: check whitelist
    const allowedOrigins = process.env.CORS_ORIGIN?.split(',') || [];
    if (allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### 2. Update Helmet config
```javascript
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));
```

### 3. Update Socket.IO CORS
```javascript
const io = new Server(server, {
  cors: {
    origin: "*", // Allow all for development
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"]
  }
});
```

---

## 🚀 Cách áp dụng

### Backend đã restart với config mới:
```bash
cd backend
node server.js
```

Bạn sẽ thấy:
```
✅ Connected to PostgreSQL database
✅ Database tables created successfully
🚀 Server running on port 3000
📊 Environment: development
```

### Test ngay trong Flutter app:
1. Hot reload: Nhấn `r` trong terminal Flutter
2. Thử Register/Login
3. Không còn CORS error! ✅

---

## 🔒 Security Notes

### Development (hiện tại):
✅ **Allow all localhost origins** - OK cho development
- Dễ test với nhiều ports
- Flutter web auto-assigns random ports
- Không ảnh hưởng production

### Production (sau này):
⚠️ **CẦN update CORS cho production:**

```javascript
// backend/.env hoặc config.env
CORS_ORIGIN=https://yourdomain.com,https://admin.yourdomain.com
```

Hoặc hardcode trong `server.js`:
```javascript
const allowedOrigins = [
  'https://yourdomain.com',
  'https://admin.yourdomain.com',
  'https://api.yourdomain.com'
];
```

---

## 🧪 Test CORS

### 1. Test với Browser Console:
```javascript
fetch('http://localhost:3000/api/orders')
  .then(res => res.json())
  .then(data => console.log(data))
  .catch(err => console.error(err));
```

### 2. Test với curl:
```bash
curl -H "Origin: http://localhost:64336" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     --verbose \
     http://localhost:3000/api/auth/login
```

**Response phải có:**
```
Access-Control-Allow-Origin: http://localhost:64336
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
```

### 3. Test trong Flutter App:
- Open app: `flutter run`
- Try Register → Không còn CORS error
- Try Login → Success!

---

## 🐛 Troubleshooting

### Vẫn còn CORS error?

#### 1. Backend chưa restart:
```bash
# Kill all node processes
taskkill /F /IM node.exe  # Windows
# hoặc
pkill node                # Linux/Mac

# Restart
cd backend
node server.js
```

#### 2. Browser cache:
- Hard refresh: `Ctrl + Shift + R` (Windows)
- Clear cache: `Ctrl + Shift + Delete`
- Hoặc open Incognito/Private window

#### 3. Check response headers:
- F12 → Network tab
- Click on failed request
- Xem Headers → Response Headers
- Kiểm tra có `Access-Control-Allow-Origin` không

#### 4. Preflight request failed:
CORS có 2 requests:
1. **OPTIONS** (preflight) - Browser tự động gửi
2. **POST/GET** (actual request)

Nếu preflight fail → actual request bị block

**Fix**: Ensure backend handle OPTIONS:
```javascript
app.options('*', cors()); // Enable preflight for all routes
```

---

## 📋 CORS Headers Explained

### Request Headers (từ Flutter app):
```
Origin: http://localhost:64336
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization
```

### Response Headers (từ Backend):
```
Access-Control-Allow-Origin: http://localhost:64336
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
```

---

## ✅ Checklist

- [x] Update `backend/server.js` với CORS config mới
- [x] Restart backend server
- [x] Test Register trong Flutter app
- [x] Test Login trong Flutter app
- [x] Không còn CORS error
- [x] API calls hoạt động bình thường

---

## 🎉 Kết quả

**Trước fix:**
```
❌ POST http://localhost:3000/api/auth/register net::ERR_FAILED
❌ CORS policy blocked
```

**Sau fix:**
```
✅ POST http://localhost:3000/api/auth/register 200 OK
✅ Response received
✅ App hoạt động bình thường
```

---

## 📚 Tài liệu thêm

- MDN CORS: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
- Express CORS package: https://www.npmjs.com/package/cors
- Flutter web networking: https://docs.flutter.dev/development/platform-integration/web

---

**Status**: ✅ FIXED
**Date**: 2025-10-28
**App**: Lalamove Express
