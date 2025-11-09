# 🚀 HƯỚNG DẪN SETUP NHANH - 3 STORIES MỚI

## ⚡ QUICK START (10 phút)

### 1️⃣ Backend Setup (5 phút)

```bash
cd backend

# Đã cài dependencies rồi ✅
# npm install firebase-admin nodemailer pdfkit

# Tạo thư mục uploads
mkdir -p uploads/receipts
mkdir -p uploads/complaints

# Chạy database migrations
psql -U postgres -d food_delivery_db -f scripts/migrate_notifications.sql
psql -U postgres -d food_delivery_db -f scripts/migrate_complaints.sql

# Khởi động lại server
npm run dev
```

### 2️⃣ Flutter Setup (5 phút)

```bash
cd ../lalamove_app

# Cài dependencies
flutter pub get

# Chạy app
flutter run -d chrome
```

---

## 🔥 TEST NGAY

### Test Story #5: Notifications

1. **Xem notification history:**
   - Thêm route vào `main.dart`:
   ```dart
   '/notifications': (context) => NotificationHistoryScreen(),
   ```
   - Navigate: `Navigator.pushNamed(context, '/notifications')`

2. **Test API:**
   ```bash
   # Get notifications
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/notifications
   
   # Get unread count
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/notifications/unread-count
   ```

### Test Story #11: PDF Receipt

1. **Generate PDF:**
   ```bash
   curl -X POST http://localhost:3000/api/warehouse/generate-receipt \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"order_id": 1}'
   ```

2. **Xem PDF:**
   - Mở: `http://localhost:3000/uploads/receipts/receipt_ORD-XXX_timestamp.pdf`

### Test Story #6: Complaints

1. **Create complaint từ order detail:**
   - Thêm button "Khiếu nại" trong order detail screen
   - Navigate to CreateComplaintScreen

2. **Test API:**
   ```bash
   # Get my complaints
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/complaints/my-complaints
   ```

---

## 🔧 CẤU HÌNH FIREBASE (Optional - cho push notifications)

### Bước 1: Tạo Firebase Project
1. Vào https://console.firebase.google.com
2. Tạo project mới: "LalamoveApp"
3. Add Android/iOS app

### Bước 2: Download Config Files
**Android:**
- Download `google-services.json`
- Copy vào `lalamove_app/android/app/`

**iOS:**
- Download `GoogleService-Info.plist`
- Copy vào `lalamove_app/ios/Runner/`

### Bước 3: Firebase Admin (Backend)
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save file as `firebase-service-account.json`
4. Add to `backend/config.env`:
   ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
   ```

### Bước 4: Test
```bash
# Trong Flutter app, sau khi login
# FCM token sẽ tự động lưu vào database

# Test từ Firebase Console:
# Cloud Messaging → Send test message
```

---

## 📦 HOÀN THIỆN STORY #6 (5% còn lại)

### Tạo các file còn thiếu:

#### 1. Complaint Model
```dart
// lib/models/complaint_model.dart
class ComplaintModel {
  final int id;
  final int orderId;
  final String complaintType;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final List<String> evidenceImages;
  final DateTime createdAt;
  
  ComplaintModel({...});
  
  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(...);
  }
}
```

#### 2. Complaint Provider
```dart
// lib/providers/complaint_provider.dart
class ComplaintProvider with ChangeNotifier {
  List<ComplaintModel> _complaints = [];
  
  Future<bool> createComplaint({...}) async {
    // Gọi API POST /api/complaints
    // Upload images using multipart/form-data
  }
  
  Future<void> fetchComplaints() async {
    // Gọi API GET /api/complaints/my-complaints
  }
}
```

#### 3. Complaint List Screen
```dart
// lib/screens/customer/complaints/complaint_list_screen.dart
class ComplaintListScreen extends StatelessWidget {
  // Hiển thị danh sách complaints
  // Filter by status
  // Navigate to detail
}
```

#### 4. Complaint Detail Screen
```dart
// lib/screens/customer/complaints/complaint_detail_screen.dart
class ComplaintDetailScreen extends StatelessWidget {
  // Hiển thị complaint detail
  // Hiển thị conversation history
  // Add response
}
```

---

## ✅ CHECKLIST HOÀN THÀNH

### Backend ✅
- [x] Install dependencies
- [x] Create uploads folders
- [x] Run database migrations
- [x] Test APIs với Postman
- [x] Verify PDF generation
- [x] Verify file uploads work

### Flutter
- [x] Install dependencies (`flutter pub get`)
- [ ] Add notification routes
- [ ] Setup Firebase (optional)
- [ ] Complete Story #6 screens (5 files)
- [ ] Test all flows

### Testing
- [ ] Test notifications
- [ ] Test PDF receipt download
- [ ] Test complaint creation
- [ ] Test image upload
- [ ] Test on real devices

---

## 🐛 TROUBLESHOOTING

### Backend

**Problem:** Cannot find module 'pdfkit'
```bash
cd backend
npm install pdfkit
```

**Problem:** ENOENT: no such file or directory 'uploads/receipts'
```bash
mkdir -p uploads/receipts uploads/complaints
```

**Problem:** Database migration error
```bash
# Check if tables exist
psql -U postgres -d food_delivery_db -c "\dt"

# Drop if needed
psql -U postgres -d food_delivery_db -c "DROP TABLE IF EXISTS notifications CASCADE;"
```

### Flutter

**Problem:** firebase_messaging not found
```bash
flutter pub get
flutter clean
flutter pub get
```

**Problem:** Build error on Android
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

---

## 📞 SUPPORT

Nếu gặp vấn đề:
1. Check file `STORY_IMPLEMENTATION_COMPLETE.md` (chi tiết đầy đủ)
2. Check API logs: `backend/server.js`
3. Check Flutter logs: `flutter logs`

---

## 🎯 KẾT QUẢ MONG ĐỢI

Sau khi setup xong:

✅ Backend có 15 API endpoints mới  
✅ Database có 2 tables mới (notifications, complaints)  
✅ Flutter có notification history screen  
✅ Flutter có complaint creation screen  
✅ PDF receipts được tạo tự động  
✅ Push notifications hoạt động (nếu setup Firebase)  

---

**Happy Coding! 🚀**
