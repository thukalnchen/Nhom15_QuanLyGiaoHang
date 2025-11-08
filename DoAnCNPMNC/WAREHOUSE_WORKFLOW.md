# WAREHOUSE WORKFLOW - Quy Trình Kho Hàng

## 📊 TRẠNG THÁI ĐỐN HÀNG (Order Status)

### 1. **pending** - Chờ nhận hàng
- Đơn hàng mới được tạo từ app_user
- Chưa được nhận tại kho
- **Hiển thị ở:** 
  - Trang chủ: Card "Chờ nhận"
  - Tab "Đơn hàng" → Tab "Chờ nhận"

### 2. **received_at_warehouse** - Đã nhận tại kho
- Nhân viên kho đã scan QR và nhập thông tin (cân nặng, kích thước, loại hàng, 4 ảnh)
- **Story #8: Scan & Receive Orders**
- **Hiển thị ở:** 
  - Tab "Kho hàng" → Tab "Cần phân loại" ← ĐÂY LÀ CHỖ PHÂN LOẠI
  - Trang chủ: Card "Đã nhận"

### 3. **classified** - Đã phân loại
- Đã tính toán khoảng cách, phí, vùng, loại xe
- **Story #9: Classification**
- **Hiển thị ở:** 
  - Tab "Kho hàng" → Tab "Đã phân loại"
  - Trang chủ: Card "Đã phân loại"

### 4. **ready_for_pickup** - Sẵn sàng giao
- Đã phân tài xế
- **Story #21: Driver Assignment**
- **Hiển thị ở:** 
  - Tab "Kho hàng" → Tab "Sẵn sàng giao"
  - Trang chủ: Card "Sẵn sàng"

---

## 🔄 QUY TRÌNH HOÀN CHỈNH

```
┌─────────────────────────────────────────────────────────────┐
│  APP_USER: Khách hàng tạo đơn hàng                          │
│  Status: pending                                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  APP_INTAKE: Nhân viên kho quét QR                          │
│  → Scan Screen (Story #8)                                   │
│  → Nhập thông tin: weight, size, type, 4 photos            │
│  → API: POST /warehouse/receive                             │
│  Status: pending → received_at_warehouse                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  APP_INTAKE: Phân loại đơn hàng                             │
│  → Tab "Kho hàng" → Tab "Cần phân loại"                    │
│  → Classification Screen (Story #9)                          │
│  → Tự động tính: distance, fee, zone, vehicle              │
│  → API: POST /warehouse/classify                            │
│  Status: received_at_warehouse → classified                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  APP_INTAKE: Phân tài xế                                    │
│  → Tab "Kho hàng" → Tab "Đã phân loại"                     │
│  → Assignment Screen (Story #21)                             │
│  → Load available drivers filtered by vehicle_type          │
│  → API: POST /warehouse/assign-driver                       │
│  Status: classified → ready_for_pickup                      │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  APP_DRIVER: Tài xế nhận hàng và giao                       │
│  Status: assigned_to_driver → in_transit → delivered       │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 THAO TÁC NHANH (Quick Actions)

### Trang chủ có 4 nút:

1. **Quét mã** (QR Scanner)
   - Navigate → Scan Screen
   - Scan QR để tìm đơn hàng
   - Nhập thông tin nhận hàng

2. **Nhận hàng** (Receive)
   - Navigate → Tab "Đơn hàng" 
   - Xem danh sách orders pending
   - Chọn order để nhận

3. **Phân loại** (Classification)
   - Navigate → Tab "Kho hàng" → Tab "Cần phân loại"
   - Xem orders đã nhận (received_at_warehouse)
   - Chọn order để phân loại

4. **Phân tài xế** (Assignment)
   - Navigate → Tab "Kho hàng" → Tab "Đã phân loại"
   - Xem orders đã phân loại (classified)
   - Chọn order để phân tài xế

---

## ⚠️ LƯU Ý QUAN TRỌNG

### Tại sao Tab "Cần phân loại" trống?

**Tab "Cần phân loại" chỉ hiển thị orders có status = "received_at_warehouse"**

Logs của bạn cho thấy:
```
Pending: 18      ← Orders chưa nhận
Received: 0      ← KHÔNG CÓ orders đã nhận → Tab "Cần phân loại" TRỐNG
Classified: 2    ← Orders đã phân loại
```

**Để có orders trong tab "Cần phân loại":**

1. Chọn 1 order từ tab "Đơn hàng" (status = pending)
2. Quét QR hoặc click vào order
3. Nhập thông tin: weight, size, type, 4 photos
4. Bấm "Nhận hàng" → Status thành "received_at_warehouse"
5. Order sẽ xuất hiện trong tab "Cần phân loại"

---

## 📝 TEST FLOW ĐỀ XUẤT

### Bước 1: Tạo order mới (app_user)
```
✅ Order created with status: pending
```

### Bước 2: Nhận hàng (app_intake)
```
1. Vào tab "Đơn hàng" → Tab "Chờ nhận"
2. Chọn order vừa tạo
3. Hoặc: Bấm "Quét mã" → Scan QR
4. Nhập thông tin nhận hàng
5. Bấm "Nhận hàng"
✅ Status: pending → received_at_warehouse
```

### Bước 3: Phân loại (app_intake)
```
1. Vào tab "Kho hàng" → Tab "Cần phân loại"
2. Chọn order vừa nhận
3. Xem thông tin tự động tính (distance, fee, zone, vehicle)
4. Bấm "Phân loại"
✅ Status: received_at_warehouse → classified
```

### Bước 4: Phân tài xế (app_intake)
```
1. Vào tab "Kho hàng" → Tab "Đã phân loại"
2. Chọn order vừa phân loại
3. Chọn tài xế từ danh sách available drivers
4. Bấm "Phân công"
✅ Status: classified → ready_for_pickup
```

---

## 🐛 TROUBLESHOOTING

### Tab "Cần phân loại" trống?
→ Cần có orders với status = "received_at_warehouse"
→ Phải nhận hàng trước (Story #8)

### Tab "Đã phân loại" có orders nhưng không phân được tài xế?
→ Check xem có available drivers không
→ Check vehicle_type có match không

### Quick Actions không hoạt động?
→ ✅ ĐÃ FIX - Buttons giờ navigate đúng screens

---

## 🎓 SUMMARY

- **Pending** (18) → Cần nhận hàng (Story #8)
- **Received** (0) → Cần phân loại (Story #9) ← TRỐNG VÌ CHƯA NHẬN HÀNG
- **Classified** (2) → Cần phân tài xế (Story #21)
- **Ready** (0) → Đã phân tài xế, sẵn sàng giao

**Workflow tuần tự: Nhận → Phân loại → Phân tài xế**
