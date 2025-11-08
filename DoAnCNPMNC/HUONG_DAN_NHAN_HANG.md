# 📦 HƯỚNG DẪN NHẬN HÀNG - APP INTAKE

## 🎯 MỤC ĐÍCH
Nhân viên kho nhận gói hàng từ khách hàng, nhập thông tin THỰC TẾ và chụp ảnh để lưu vào hệ thống.

---

## ✅ QUY TRÌNH NHẬN HÀNG (2 CÁCH)

### **CÁCH 1: QUÉT MÃ QR** ⚡ (Nhanh nhất - Khuyên dùng)

```
1. Mở app_intake → Màn hình Home
2. Bấm nút "Quét mã" (icon QR scanner - floating button góc dưới)
3. Camera mở → Quét QR code trên đơn hàng
4. Tự động mở màn hình "Nhận hàng" (Order Intake Screen)
5. Nhập thông tin thực tế ↓
```

### **CÁCH 2: TỪ DANH SÁCH ĐƠN HÀNG** 📋

```
1. Mở app_intake → Bấm "Đơn hàng" ở bottom nav
2. Chọn tab "Chờ nhận" (18 đơn đang chờ)
3. Tap vào 1 đơn hàng bất kỳ
4. Tự động mở màn hình "Nhận hàng" (Order Intake Screen)
5. Nhập thông tin thực tế ↓
```

---

## 📝 NHẬP THÔNG TIN THỰC TẾ

Khi màn hình **Order Intake Screen** mở ra:

### **A. Thông tin đơn hàng hiển thị:**
- ✅ Mã đơn hàng (Order Code)
- ✅ Thông tin người gửi
- ✅ Thông tin người nhận
- ✅ Địa chỉ lấy/giao hàng
- ⭕ Ước lượng của khách (nếu có):
  - Size dự kiến
  - Cân nặng dự kiến
  - Loại xe
  - Ghi chú

### **B. Bạn cần nhập:**

1. **📏 Kích thước** (Bắt buộc)
   ```
   □ Small        (< 20cm)
   □ Medium       (20-40cm)
   □ Large        (40-60cm)
   □ Extra Large  (> 60cm)
   ```

2. **⚖️ Cân nặng thực tế** (Bắt buộc)
   ```
   Ví dụ: 2.5 (kg)
   ```

3. **📦 Loại hàng** (Bắt buộc)
   ```
   □ Food         (Thực phẩm)
   □ Electronics  (Điện tử)
   □ Documents    (Tài liệu)
   □ Fragile      (Hàng dễ vỡ)
   □ Other        (Khác)
   ```

4. **📷 Chụp ảnh** (Tối đa 4 ảnh)
   ```
   - Ảnh 1: Toàn cảnh gói hàng
   - Ảnh 2: Nhãn địa chỉ
   - Ảnh 3: Mã đơn hàng/QR code
   - Ảnh 4: Tình trạng gói hàng
   
   Có thể:
   - Chụp ảnh ngay (Camera)
   - Chọn từ thư viện
   - Xóa ảnh đã chọn
   ```

5. **📝 Ghi chú** (Không bắt buộc)
   ```
   Ví dụ:
   - "Đã kiểm tra kỹ, không bị hư hỏng"
   - "Khách yêu cầu giao cẩn thận"
   - "Gói hàng ướt một góc"
   ```

### **C. Xác nhận nhận hàng:**
```
6. Kiểm tra lại tất cả thông tin
7. Bấm nút "Xác nhận nhận hàng" màu xanh
8. ✅ Thông báo thành công
9. ✅ Tự động quay về màn hình trước
10. ✅ Status đơn hàng: pending → received_at_warehouse
```

---

## 🔄 SAU KHI NHẬN HÀNG

### **Đơn hàng sẽ chuyển sang:**

```
Tab "Đơn hàng" → "Đã nhận"
     ↓
Tab "Kho hàng" → "Cần phân loại"
     ↓
Sẵn sàng cho Story #9: Classification (Phân loại)
```

### **Kiểm tra:**
1. Vào **Tab "Kho hàng"**
2. Chọn tab **"Cần phân loại"**
3. ✅ Đơn hàng vừa nhận sẽ hiển thị ở đây
4. ✅ Status badge: "Đã nhận tại kho" (màu cam)

---

## ⚠️ LƯU Ý QUAN TRỌNG

### ❌ **KHÔNG THỂ**:
- Chỉnh sửa status trực tiếp từ "Chờ nhận" → "Đã nhận"
- Bỏ qua bước nhập thông tin thực tế
- Nhận hàng mà không chụp ảnh (cần ít nhất 1 ảnh)

### ✅ **PHẢI**:
- Qua màn hình Order Intake Screen
- Nhập đầy đủ: Cân nặng + Kích thước + Loại hàng
- Chụp ảnh để làm bằng chứng
- Xác nhận nhận hàng bằng nút "Xác nhận"

### 💡 **TẠI SAO?**
- Cần thông tin THỰC TẾ để tính phí chính xác
- Ảnh chụp làm bằng chứng tình trạng hàng khi nhận
- Tránh tranh chấp sau này
- Đảm bảo quy trình minh bạch

---

## 📊 HIỆN TRẠNG DATABASE

Hiện tại bạn có **26 đơn hàng**:

| Status | Số lượng | Ý nghĩa |
|--------|----------|---------|
| **pending** | 18 | Chờ nhận hàng vào kho |
| **received_at_warehouse** | 0 | Đã nhận, chờ phân loại |
| **classified** | 2 | Đã phân loại, chờ phân tài xế |
| **ready_for_pickup** | 0 | Đã phân tài xế, chờ lấy hàng |

**→ TAB "CẦN PHÂN LOẠI" TRỐNG vì không có đơn nào ở trạng thái `received_at_warehouse`**

---

## 🧪 TEST NGAY:

### **Bước 1: Chọn 1 đơn hàng để test**
```bash
cd C:\Workspace\CNPM_nc\Nhom15_QuanLyGiaoHang\DoAnCNPMNC\backend
node scripts/check-orders.js
```
→ Lấy order_code của 1 đơn **pending**

### **Bước 2: Nhận hàng**
**Option A: Quét QR**
1. Bấm "Quét mã"
2. Scan QR code (hoặc nhập manual order_code)
3. Nhập thông tin → Xác nhận

**Option B: Từ danh sách**
1. Tab "Đơn hàng" → "Chờ nhận"
2. Tap vào đơn hàng
3. Nhập thông tin → Xác nhận

### **Bước 3: Kiểm tra**
```
1. Tab "Kho hàng" → "Cần phân loại"
   ✅ Có 1 đơn mới nhận
   
2. Trang chủ → "Đã nhận"
   ✅ Tăng từ 0 → 1
   
3. Tab "Đơn hàng" → "Đã nhận"
   ✅ Có 1 đơn với badge cam "Đã nhận"
```

---

## 🔗 WORKFLOW ĐẦY ĐỦ

```
┌────────────────────────────────────────────────────────────┐
│                    QUY TRÌNH WAREHOUSE                     │
└────────────────────────────────────────────────────────────┘

1. PENDING (18 đơn)
   └─► Khách đặt hàng qua app_user
       Status: "pending"
       ↓
       
2. RECEIVE (Story #8) ← BẠN Đang Ở ĐÂY
   └─► Quét QR hoặc chọn từ danh sách
   └─► Nhập: Cân nặng, kích thước, loại hàng, 4 ảnh
   └─► Xác nhận nhận hàng
       Status: "received_at_warehouse"
       ↓
       
3. CLASSIFY (Story #9)
   └─► Tab "Cần phân loại" hiển thị đơn
   └─► Hệ thống tự tính phí dựa trên thông tin thực tế
   └─► Phân loại đơn hàng
       Status: "classified"
       ↓
       
4. ASSIGN DRIVER (Story #21)
   └─► Tab "Đã phân loại" hiển thị đơn
   └─► Chọn tài xế phù hợp
   └─► Phân công giao hàng
       Status: "ready_for_pickup"
       ↓
       
5. DELIVERY (app_driver)
   └─► Tài xế lấy hàng và giao
       Status: "delivered"
```

---

## 💬 CÂU HỎI THƯỜNG GẶP

### Q1: Tại sao không cho phép chỉnh sửa status trực tiếp?
**A:** Vì cần thu thập thông tin THỰC TẾ (cân nặng, kích thước, ảnh) để:
- Tính phí chính xác
- Có bằng chứng pháp lý
- Đảm bảo minh bạch

### Q2: Có bắt buộc phải chụp đủ 4 ảnh không?
**A:** Không bắt buộc, nhưng khuyên dùng để có bằng chứng đầy đủ.

### Q3: Nếu không có QR code scanner thì sao?
**A:** Dùng **Cách 2** - chọn từ danh sách đơn hàng ở tab "Chờ nhận".

### Q4: Sau khi nhận xong làm gì tiếp?
**A:** Chuyển sang **Story #9** - Vào tab "Cần phân loại" để phân loại đơn.

---

## 📚 TÀI LIỆU LIÊN QUAN

- `WAREHOUSE_WORKFLOW.md` - Quy trình kho hàng đầy đủ
- `END_TO_END_TEST_GUIDE.md` - Hướng dẫn test toàn bộ
- `APP_INTAKE_SETUP.md` - Cấu trúc app_intake
- `STORY_9_CLASSIFICATION_COMPLETE.md` - Story #9 tiếp theo

---

**NEXT STEP:** Sau khi nhận hàng xong → Đọc file `STORY_9_CLASSIFICATION_COMPLETE.md` để học cách phân loại! 🚀
