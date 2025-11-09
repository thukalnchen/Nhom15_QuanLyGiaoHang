flui# 🎯 QUICK TEST - Story #6 Complaints

## 🚀 Test ngay trong 5 phút!

### Step 1: Tạo test data qua Postman

```http
### 1. Login để lấy token
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "test123@gmail.com",
  "password": "123456"
}

### Copy token từ response vào đây: YOUR_TOKEN_HERE


### 2. Tạo complaint 1
POST http://localhost:3000/api/complaints
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "order_id": 1,
  "title": "Hàng bị hỏng",
  "description": "Hàng hóa bị hư hại khi giao đến. Yêu cầu hoàn tiền."
}


### 3. Tạo complaint 2
POST http://localhost:3000/api/complaints
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "order_id": 2,
  "title": "Giao hàng muộn",
  "description": "Đơn hàng giao muộn 2 ngày so với cam kết. Tôi rất không hài lòng."
}


### 4. Tạo complaint 3
POST http://localhost:3000/api/complaints
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "order_id": 3,
  "title": "Sai địa chỉ giao hàng",
  "description": "Tài xế giao sai địa chỉ. Tôi phải tự đi lấy hàng."
}


### 5. Gửi phản hồi admin (complaint_id = 1)
POST http://localhost:3000/api/complaints/1/respond
Content-Type: application/json
Authorization: Bearer YOUR_ADMIN_TOKEN

{
  "message": "Chúng tôi đã nhận được khiếu nại của bạn. Xin lỗi vì sự bất tiện này. Chúng tôi sẽ xử lý trong 24h."
}


### 6. Gửi phản hồi customer (complaint_id = 1)
POST http://localhost:3000/api/complaints/1/respond
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE

{
  "message": "Tôi cần được hoàn tiền sớm nhất có thể."
}


### 7. Update status processing (complaint_id = 1)
PUT http://localhost:3000/api/complaints/1/status
Content-Type: application/json
Authorization: Bearer YOUR_ADMIN_TOKEN

{
  "status": "processing",
  "admin_note": "Đã liên hệ với tài xế"
}


### 8. Update status resolved (complaint_id = 1)
PUT http://localhost:3000/api/complaints/1/status
Content-Type: application/json
Authorization: Bearer YOUR_ADMIN_TOKEN

{
  "status": "resolved",
  "admin_note": "Đã hoàn tiền cho khách hàng"
}
```

---

### Step 2: Test trên Flutter App

#### Cách test nhanh (Chrome DevTools Console):

1. **Mở app trên Chrome** (đã chạy)
2. **Mở DevTools** (F12)
3. **Paste code này vào Console:**

```javascript
// Test 1: Import ComplaintListScreen
console.log('📱 Testing Complaint List Screen...');

// Test 2: Check if data loads
fetch('http://localhost:3000/api/complaints/my-complaints?page=1&limit=10&status=all', {
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN_HERE',
    'Content-Type': 'application/json'
  }
})
.then(res => res.json())
.then(data => {
  console.log('✅ Complaints loaded:', data.complaints.length);
  console.log('📦 First complaint:', data.complaints[0]);
})
.catch(err => console.error('❌ Error:', err));
```

#### Hoặc test bằng cách thêm button tạm:

**File:** `lib/screens/customer/home/home_screen.dart`

Thêm code này vào một nơi nào đó trong body (ví dụ trong ListView):

```dart
// TEST: Button tạm để test Complaints
Card(
  child: ListTile(
    leading: Icon(Icons.report_problem, color: Colors.red),
    title: Text('🧪 TEST: Khiếu nại của tôi'),
    subtitle: Text('Click để test Story #6'),
    trailing: Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComplaintListScreen(),
        ),
      );
    },
  ),
),
```

**Nhớ import:**
```dart
import '../complaints/complaint_list_screen.dart';
```

---

### Step 3: Test Checklist

Sau khi mở Complaint List Screen:

#### ✅ Complaint List Screen
- [ ] Hiển thị 5 tabs (Tất cả, Chờ xử lý, Đang xử lý, Đã giải quyết, Đã từ chối)
- [ ] Hiển thị danh sách 3 complaints đã tạo
- [ ] Mỗi card hiển thị: Order ID, Title, Description, Status, Date
- [ ] Click tab "Chờ xử lý" → chỉ hiển thị pending complaints
- [ ] Pull to refresh → reload data
- [ ] Click vào một complaint → navigate to detail

#### ✅ Complaint Detail Screen
- [ ] Hiển thị header với status badge
- [ ] Hiển thị order info (order code, addresses)
- [ ] Hiển thị title & description
- [ ] Hiển thị conversation (2 messages nếu đã tạo ở Step 1)
- [ ] Admin messages: bên trái, màu xanh, có badge "👨‍💼 Admin"
- [ ] Customer messages: bên phải, màu primary
- [ ] Reply box: có text field + send button
- [ ] Type "Test reply từ Flutter" → click send
- [ ] Toast hiển thị "✅ Đã gửi phản hồi"
- [ ] Message mới xuất hiện trong conversation
- [ ] Auto scroll to bottom

---

### Step 4: Test với Postman (Backend APIs)

```http
### Get my complaints
GET http://localhost:3000/api/complaints/my-complaints?status=all
Authorization: Bearer YOUR_TOKEN

Expected: List of 3 complaints


### Get complaint detail (ID = 1)
GET http://localhost:3000/api/complaints/1
Authorization: Bearer YOUR_TOKEN

Expected: Complaint with order info & responses


### Send reply
POST http://localhost:3000/api/complaints/1/respond
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "message": "Test từ Postman"
}

Expected: Success response + new message in responses


### Update status (Admin only - cần admin token)
PUT http://localhost:3000/api/complaints/1/status
Authorization: Bearer YOUR_ADMIN_TOKEN
Content-Type: application/json

{
  "status": "resolved",
  "admin_note": "Test resolved"
}

Expected: Status updated
```

---

## 🎉 Kết quả mong đợi

### Backend:
- ✅ 3 complaints created
- ✅ Conversations với multiple responses
- ✅ Status updates working
- ✅ APIs return correct data

### Flutter:
- ✅ Complaint List Screen hiển thị đúng
- ✅ Tabs filter working
- ✅ Navigation to detail working
- ✅ Complaint Detail Screen hiển thị đầy đủ info
- ✅ Conversation UI đẹp
- ✅ Send reply working
- ✅ Auto refresh after send

---

## 🐛 Troubleshooting

### Lỗi 401 Unauthorized:
```
→ Token hết hạn
→ Fix: Login lại để lấy token mới
```

### Lỗi "No route":
```
→ Chưa import ComplaintListScreen
→ Fix: Check import statements
```

### Lỗi "Token is not valid":
```
→ Copy sai token hoặc token có space
→ Fix: Copy lại token, remove spaces
```

### Data không hiển thị:
```
→ Backend chưa chạy hoặc chưa có data
→ Fix: 
  1. Check backend: http://localhost:3000
  2. Tạo complaints qua Postman trước
```

---

## ⚡ Super Quick Test (1 phút)

1. **Backend có chạy không?**
   ```
   http://localhost:3000/api/health
   → Phải return { "status": "ok" }
   ```

2. **Có complaints không?**
   ```sql
   SELECT * FROM complaints;
   → Phải có ít nhất 1 row
   ```

3. **Flutter app có chạy không?**
   ```
   Chrome → http://localhost:XXXXX
   → Phải thấy app UI
   ```

4. **ComplaintProvider có register không?**
   ```dart
   // Check main.dart
   ChangeNotifierProvider(create: (_) => ComplaintProvider()),
   → Phải có dòng này
   ```

---

## ✨ Success Criteria

✅ **Story #6 = 100% Complete nếu:**
- Backend APIs work (test bằng Postman)
- Flutter screens render without errors
- Can navigate List → Detail
- Can send replies
- Data displays correctly
- No console errors

---

## 📞 Need Help?

Check logs:
```bash
# Backend logs
cd backend
npm run dev

# Flutter logs
# Check Chrome DevTools Console (F12)

# Database
psql -U postgres -d food_delivery
SELECT * FROM complaints;
SELECT * FROM complaint_responses;
```

---

**Chúc test thành công! 🎊**
