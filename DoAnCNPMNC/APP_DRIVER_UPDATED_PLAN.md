# 🚗 APP_DRIVER - CẬP NHẬT THEO PRODUCT BACKLOG

## 📊 MAPPING VỚI PRODUCT BACKLOG

### User Stories từ Product Backlog (Actor: Nhân viên giao hàng)

| ID | User Story | Priority | Status | Implementation |
|----|------------|----------|--------|----------------|
| 13 | Đăng nhập vào ứng dụng giao hàng | 2 | ✅ Planned | Phase 1: Login Screen |
| 14 | Xem danh sách đơn được giao | 3 | ✅ Planned | Phase 3: Available/Active Orders |
| 15 | Xem chi tiết đơn và bản đồ tuyến đường | 3 | ✅ Planned | Phase 3: Order Details + Phase 4: Map |
| 16 | Cập nhật trạng thái đơn (đang giao, giao thành công) | 3 | ✅ Planned | Phase 3: Delivery Flow |
| 17 | Check-in vị trí tự động để khách hàng theo dõi | 5 | ✅ Planned | Phase 4: Real-time Tracking |
| 18 | Ghi chú lý do khi không giao được / trả hàng | 2 | ⚠️ MISSING | **CẦN THÊM** |
| 19 | Xác nhận đã thu tiền COD | 2 | ⚠️ MISSING | **CẦN THÊM** |

---

## ⚠️ CẬP NHẬT: CHỨC NĂNG THIẾU

### 🔴 Priority 2: Ghi chú lý do khi không giao được (#18)

**Kịch bản:**
- Driver không thể giao hàng (khách không có nhà, địa chỉ sai, từ chối nhận...)
- Cần report issue và đổi status thành "failed_delivery" hoặc "returning"

**Implementation:**

#### 1. UI Changes
```dart
File: lib/screens/orders/report_issue_screen.dart (NEW)

Features:
- Danh sách lý do không giao được:
  □ Khách không có nhà
  □ Số điện thoại không liên lạc được
  □ Địa chỉ sai/không tìm thấy
  □ Khách từ chối nhận hàng
  □ Hàng hóa bị hư hỏng
  □ Khác (nhập tự do)
- Text field ghi chú chi tiết
- Chụp ảnh minh chứng (optional)
- Button: "Báo cáo vấn đề" / "Trả hàng"
```

#### 2. Delivery Flow Update
```dart
File: lib/screens/orders/delivery_flow_screen.dart (UPDATE)

Thêm button:
- "Báo cáo vấn đề" (tất cả các bước)
- Navigate to ReportIssueScreen
```

#### 3. Order Status New States
```dart
File: lib/utils/constants.dart (UPDATE)

Thêm status:
- statusFailedDelivery = 'failed_delivery'
- statusReturning = 'returning'
- statusReturned = 'returned'
```

#### 4. API Endpoint
```javascript
Backend: POST /api/orders/:orderId/report-issue

Request:
{
  "issue_type": "customer_not_home" | "wrong_address" | "customer_refused" | "damaged" | "other",
  "notes": "Chi tiết vấn đề",
  "photo": "base64_image" (optional)
}

Response:
{
  "status": "success",
  "data": {
    "order": {...},
    "new_status": "failed_delivery" | "returning"
  }
}
```

#### 5. Database Changes
```sql
-- Add to orders table
ALTER TABLE orders ADD COLUMN delivery_issue VARCHAR(100);
ALTER TABLE orders ADD COLUMN issue_notes TEXT;
ALTER TABLE orders ADD COLUMN issue_photo VARCHAR(255);
ALTER TABLE orders ADD COLUMN issue_reported_at TIMESTAMP;
```

---

### 🔴 Priority 2: Xác nhận đã thu tiền COD (#19)

**Kịch bản:**
- Khi giao hàng thành công, driver cần xác nhận đã thu tiền COD
- Nhập số tiền đã thu
- Hệ thống tracking số tiền COD driver đang giữ

**Implementation:**

#### 1. UI Changes
```dart
File: lib/screens/orders/delivery_flow_screen.dart (UPDATE)

Khi confirm delivery (COD order):
- Show dialog "Xác nhận thu tiền COD"
- Input field: Số tiền cần thu (read-only, từ order)
- Checkbox: "Đã thu đủ tiền"
- Input field: Số tiền thực tế thu được (nếu khác)
- Text field: Ghi chú (nếu thiếu/thừa)
- Button: "Xác nhận giao hàng & Thu COD"
```

#### 2. Order Details Display
```dart
File: lib/screens/orders/order_details_screen.dart (UPDATE)

Hiển thị:
- COD Amount (if payment_method = 'cod')
- Badge "COD" màu đỏ
- Icon tiền
```

#### 3. COD Tracking Screen (NEW)
```dart
File: lib/screens/earnings/cod_tracking_screen.dart (NEW)

Features:
- Tổng tiền COD đang giữ
- Danh sách đơn COD đã thu (chưa nộp)
- Button "Nộp tiền COD" (reconcile)
- Lịch sử nộp tiền
```

#### 4. API Endpoints
```javascript
// Confirm COD collection
POST /api/orders/:orderId/confirm-cod
{
  "cod_amount_collected": 250000,
  "notes": "Khách trả đủ"
}

// Get COD balance
GET /api/driver/cod-balance
Response: {
  "total_cod_holding": 1500000,
  "orders": [...]
}

// Submit COD reconciliation
POST /api/driver/cod-reconcile
{
  "amount": 1500000,
  "order_ids": [123, 456, 789]
}
```

#### 5. Database Changes
```sql
-- Add to orders table
ALTER TABLE orders ADD COLUMN payment_method VARCHAR(20) DEFAULT 'online';
ALTER TABLE orders ADD COLUMN cod_amount DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN cod_collected BOOLEAN DEFAULT false;
ALTER TABLE orders ADD COLUMN cod_collected_at TIMESTAMP;

-- Create COD tracking table
CREATE TABLE driver_cod_transactions (
    id SERIAL PRIMARY KEY,
    driver_id INTEGER REFERENCES users(id),
    order_id INTEGER REFERENCES orders(id),
    amount DECIMAL(10, 2) NOT NULL,
    type VARCHAR(20), -- 'collect' | 'reconcile'
    status VARCHAR(20), -- 'holding' | 'submitted'
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📋 CẬP NHẬT CHECKLIST

### 🔥 Phase 1: Authentication (1-2 ngày) - UNCHANGED
- [ ] Login Screen
- [ ] Register Screen

### 🔥 Phase 2: Dashboard (2-3 ngày) - UNCHANGED
- [ ] Home Dashboard
- [ ] Online/Offline toggle
- [ ] Statistics

### 🔥 Phase 3: Order Management (4-5 ngày) - **UPDATED**
- [ ] Available Orders Screen
- [ ] Order Details Screen (+ COD badge)
- [ ] Accept/Reject Order
- [ ] Active Orders Screen
- [ ] Delivery Flow Screen
  - [ ] Status updates
  - [ ] **NEW: Báo cáo vấn đề button**
  - [ ] **NEW: COD confirmation dialog**

### 🔥 Phase 3.5: Issue & COD (2-3 ngày) - **NEW**
- [ ] **Report Issue Screen**
  - [ ] Issue type selection
  - [ ] Notes input
  - [ ] Photo upload
  - [ ] Submit to API
- [ ] **COD Confirmation**
  - [ ] Dialog in delivery flow
  - [ ] Amount validation
  - [ ] COD tracking

### 🔥 Phase 4: Map & Navigation (2-3 ngày) - UNCHANGED
- [ ] Map Screen
- [ ] Real-time tracking
- [ ] Navigation

### Phase 5: Earnings & COD (2-3 ngày) - **UPDATED**
- [ ] Earnings Screen
- [ ] **NEW: COD Tracking Screen**
  - [ ] COD balance display
  - [ ] Holding orders list
  - [ ] Reconciliation flow
- [ ] Transaction history

### Phase 6: Profile (1 ngày) - UNCHANGED
- [ ] Profile Screen
- [ ] Settings

---

## 🛠️ BACKEND UPDATES NEEDED

### Priority 1 (Immediate)
```javascript
// Existing
POST   /api/auth/driver/register
POST   /api/auth/driver/login
GET    /api/orders/available
POST   /api/orders/:id/accept

// NEW - REQUIRED
POST   /api/orders/:id/report-issue     // #18
POST   /api/orders/:id/confirm-cod      // #19
```

### Priority 2 (Soon)
```javascript
GET    /api/orders/active
PUT    /api/orders/:id/status

// NEW - COD Tracking
GET    /api/driver/cod-balance
POST   /api/driver/cod-reconcile
GET    /api/driver/cod-history
```

---

## ⏱️ UPDATED TIME ESTIMATE

| Phase | Tasks | Old Estimate | New Estimate |
|-------|-------|--------------|--------------|
| Phase 1 | Authentication | 1-2 ngày | 1-2 ngày |
| Phase 2 | Dashboard | 2-3 ngày | 2-3 ngày |
| Phase 3 | Orders | 3-4 ngày | **4-5 ngày** |
| **Phase 3.5** | **Issue & COD** | - | **2-3 ngày** ⚠️ NEW |
| Phase 4 | Map | 2-3 ngày | 2-3 ngày |
| Phase 5 | Earnings + COD | 1-2 ngày | **2-3 ngày** |
| Phase 6 | Profile | 1 ngày | 1 ngày |
| **TOTAL** | | **12-18 ngày** | **15-22 ngày** |

---

## 🎯 UPDATED PRIORITY ORDER

### Must Have (MVP)
1. ✅ Login (#13) - Priority 2
2. ✅ Xem danh sách đơn (#14) - Priority 3
3. ✅ Xem chi tiết & map (#15) - Priority 3
4. ✅ Cập nhật trạng thái (#16) - Priority 3
5. ⚠️ **Báo cáo vấn đề (#18) - Priority 2** - THÊM VÀO MVP
6. ⚠️ **Xác nhận COD (#19) - Priority 2** - THÊM VÀO MVP

### Should Have
7. ✅ Real-time tracking (#17) - Priority 5

---

## 📝 IMPLEMENTATION NOTES

### Report Issue Flow
```
Driver gặp vấn đề
    ↓
Tap "Báo cáo vấn đề"
    ↓
Chọn loại vấn đề + ghi chú
    ↓
(Optional) Chụp ảnh
    ↓
Submit → Order status = "failed_delivery"
    ↓
Admin xử lý (reassign driver / return to sender)
```

### COD Flow
```
Order có payment_method = 'COD'
    ↓
Driver giao hàng thành công
    ↓
Tap "Xác nhận giao hàng"
    ↓
Dialog: "Xác nhận thu COD XXXđ"
    ↓
Checkbox "Đã thu tiền"
    ↓
Confirm → Order completed + COD tracked
    ↓
COD balance tăng lên
    ↓
Cuối ngày: Driver nộp tiền COD cho admin
```

---

## ✅ KẾT LUẬN

### Kế hoạch ban đầu:
- ✅ Đã cover 5/7 user stories (71%)
- ❌ Thiếu 2 user stories priority 2 quan trọng

### Sau khi cập nhật:
- ✅ Cover đủ 7/7 user stories (100%)
- ✅ Đúng với Product Backlog
- ⚠️ Thời gian tăng thêm 3-4 ngày (từ 12-18 → 15-22 ngày)

### Next Steps:
1. ✅ Cập nhật `constants.dart` với new statuses
2. ✅ Implement Phase 1 (Authentication) như cũ
3. ✅ Implement Phase 2 (Dashboard) như cũ
4. ⚠️ Phase 3 thêm Report Issue & COD features
5. ⚠️ Backend cần implement 2 API mới: report-issue & confirm-cod

**Recommendation:** Làm theo thứ tự Priority trong Product Backlog để đảm bảo MVP hoàn chỉnh!
