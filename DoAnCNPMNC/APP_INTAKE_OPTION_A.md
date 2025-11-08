# Option A — Phương án đề xuất: Customer ước lượng (estimate) + Intake staff xác nhận

Tài liệu này mô tả chi tiết Phương án 1 (khuyến nghị) và cách triển khai, cùng các ví dụ thực tế. Mục tiêu: giữ trải nghiệm khách hàng (cho họ ước lượng), đồng thời đảm bảo dữ liệu chính xác và công bằng bằng cách cho phép nhân viên kho xác nhận/ghi đè, kèm cơ chế điều chỉnh phí.

---

## 1. Tóm tắt luồng nghiệp vụ (miêu tả yêu cầu của bạn)

1. Customer tạo đơn (app_user):
   - Customer nhập ước lượng: `customer_estimated_size = 'medium'`, `customer_requested_vehicle = 'car'`
   - API lưu các trường này với đơn hàng dưới dạng "ước lượng" (not final).

2. Intake Staff nhận hàng (app_intake):
   - Hệ thống hiển thị: "Customer ước lượng: MEDIUM, yêu cầu: CAR"
   - Staff cân & kiểm tra thực tế: cân 8kg, kích thước thực tế MEDIUM, loại hàng = Fragile, tính khoảng cách = 12km → zone_3
   - Hệ thống đề xuất vehicle = CAR (vì > 10km + fragile)
   - Staff xác nhận: `package_size='medium'`, `recommended_vehicle='car'`

3. Nếu Customer ước lượng SAI:
   - Customer: ước lượng SMALL + BIKE
   - Staff cân: 25kg → thực tế LARGE
   - Hệ thống đề xuất VAN
   - Staff override: `package_size='large'`, `recommended_vehicle='van'`
   - Kết quả: phí được điều chỉnh (recompute) — và hệ thống lưu trace: who changed, khi nào, reason

---

## 2. Thiết kế dữ liệu (Database)

Bổ sung 2 cột cho bảng `orders` để lưu ước lượng từ customer (không ghi đè giá cuối):

- `customer_estimated_size VARCHAR(20)`
- `customer_requested_vehicle VARCHAR(20)`

Lưu ý: giữ nguyên các cột hiện tại dùng bởi intake staff (chính thức):
- `package_size VARCHAR(20)`
- `package_type VARCHAR(20)`
- `weight DECIMAL(10,2)`
- `recommended_vehicle VARCHAR(20)`

Ví dụ ALTER script (Postgres):

```sql
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_estimated_size VARCHAR(20);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_requested_vehicle VARCHAR(20);
```

Ghi chú: nếu muốn lưu audit trail thêm, tạo bảng `order_change_logs` để lưu: order_id, field, old_value, new_value, changed_by, reason, timestamp.

---

## 3. API changes

1. Order creation (app_user):
   - Endpoint: `POST /api/orders` (hoặc hiện có)
   - Payload thêm:
     - `customer_estimated_size` (optional)
     - `customer_requested_vehicle` (optional)
   - Backend: validate (allowed values), save to DB as estimate fields

2. Warehouse receive (intake) endpoint: `POST /api/warehouse/receive`
   - Payload (existing): orderId, images, etc.
   - Thêm/ensure backend nhận và lưu các trường đã xác nhận từ staff:
     - `package_size` (confirmed)
     - `package_type` (confirmed)
     - `weight`
     - `recommended_vehicle` (final suggestion after staff confirmation)
   - Backend sẽ gọi pricing logic để tính lại `final_price` dựa trên confirmed data, cập nhật order, và lưu audit record nếu giá thay đổi do staff override.

3. Classification endpoint: `POST /api/warehouse/classify`
   - Giữ nguyên cách hoạt động nhưng cần hiển thị customer estimates khi trả về order data.

4. Optional: Add endpoint to fetch `customer_estimates` for admin/audit.

---

## 4. UI changes

A. app_user (Customer)
- UI labels: thay "Chọn kích thước" → "Ước lượng kích thước (tùy chọn)"
- Thêm disclaimer nhỏ: "Kích thước/giá cuối cùng có thể thay đổi sau khi nhân viên kho kiểm tra"
- Khi gửi order, gửi `customer_estimated_size` và `customer_requested_vehicle`.
- Không chặn checkout nếu không có estimate (estimate optional).

B. app_intake (Intake staff)
- `order_intake_screen.dart` (Receive): hiển thị block "Customer estimate":
  - "Khách ước lượng: MEDIUM (yêu cầu: CAR)"
  - Mặc định các dropdown/chọn sẽ lấy giá trị estimate làm default value
- Nếu staff chỉnh sửa (override) khác biệt với estimate: show confirm dialog + show expected fee change (if possible)
- `classification_screen.dart`:
  - Hiển thị so sánh: Customer estimate vs Confirmed
  - Hiển thị reason/warning nếu chênh lệch lớn

---

## 5. Pricing & Business Rules

- **Quy tắc tính giá**: luôn dùng `confirmed` data (package_size, recommended_vehicle, zone) để tính giá cuối.
- **Thông báo cho khách**: nếu price thay đổi do staff override, bạn có thể
  - (A) Gửi thông báo tự động (SMS/Email/in-app) nói rõ lý do thay đổi và số tiền mới.
  - (B) Nếu change % lớn hơn threshold (ví dụ > 20%), gọi/nhắc confirm từ khách (business decision).
- **Tolerance policy (gợi ý)**:
  - Nếu weight/size chênh < 20% so với estimate → auto accept, chỉ cập nhật giá
  - Nếu chênh >= 20% → require staff to mark `notified_customer = true` or `hold_for_confirmation` (tùy chọn)
- **Audit**: lưu `order_change_logs` khi staff override: (field, old, new, staff_id, note, timestamp)

---

## 6. UX examples (tương tự yêu cầu của bạn)

### A. Case 1 — Estimate đúng
- Customer: estimated_size=MEDIUM, requested_vehicle=CAR
- Staff sees estimates, cân 8kg → package_size=MEDIUM
- System suggest vehicle CAR (fragile + 12km)
- Staff confirms → final price computed with MEDIUM/CAR/zone_3
- No dispute.

### B. Case 2 — Estimate sai
- Customer: estimated_size=SMALL, requested_vehicle=BIKE
- Staff cân 25kg → package_size=LARGE
- System suggests VAN
- Staff override to VAN → final price recalculated (more expensive)
- System logs change; send notification to customer with reason & new price
- Optionally: if price increased > threshold, hold order for customer ACK

---

## 7. Implementation steps (kỹ thuật) — tối ưu, dễ làm

1. **DB Migration** (quick):
   - Add `customer_estimated_size`, `customer_requested_vehicle`
   - Optional: create `order_change_logs` table

2. **Backend changes** (small, iterative):
   - Update order create handler to accept & save estimates
   - Update warehouse receive handler to accept confirmed fields and recalc price
   - Add audit logging when confirmed fields differ from estimates

3. **Frontend (app_user)** (tiny):
   - Change labels + send extra fields; add small disclaimer

4. **Frontend (app_intake)** (medium):
   - Show estimates in `order_intake_screen.dart` (we already created this file)
   - Pre-fill dropdowns with customer estimate and allow override
   - On override, show a dialog about price change (if available)

5. **Pricing & notifications** (business logic):
   - Ensure backend recalculates final price and sends notification when price increases beyond configured threshold.

6. **Testing**:
   - Smoke test: create order with estimate → receive in app_intake → confirm same/different → verify data and price
   - Edge tests: missing estimates, malformed values, large overrides

---

## 8. Files to edit (quick list)

- Backend
  - `backend/scripts/migrate-add-customer-estimates.js` (new)
  - `backend/controllers/orderController.js` (update create)
  - `backend/controllers/warehouseController.js` (update receive)
  - `backend/services/pricing.js` (ensure uses confirmed data)

- Frontend (app_user)
  - `app_intake/...` or `app_user/...` (where order is created): update UI & API payload

- Frontend (app_intake)
  - `app_intake/lib/screens/scan/order_intake_screen.dart` (show customer estimate block)
  - `app_intake/lib/screens/warehouse/classification_screen.dart` (show comparison)
  - `app_intake/lib/providers/warehouse_provider.dart` (make sure receiveOrder() accepts confirmed fields and images)

---

## 9. Recommendation (kết luận ngắn)

Giữ cho customer có thể **ước lượng** (không bắt buộc) là tốt nhất cho UX. Đừng xóa các story liên quan ở nhân viên nhận hàng — thay vào đó, tích hợp rõ ràng: "Customer estimate" (tham khảo) + "Confirmed" (chính thức). Điều này vừa đảm bảo UX tốt cho khách vừa đảm bảo chính xác khi tính phí.

Nếu bạn đồng ý, tôi sẽ bắt tay vào: 
1) Tạo migration script và chạy (thêm 2 cột)
2) Cập nhật backend để order creation lưu estimate
3) Cập nhật `order_intake_screen.dart` để hiển thị estimate (mặc định đã tạo, tôi sẽ cập nhật)

Bạn đồng ý tôi bắt đầu triển khai (thực hiện todo list) chứ? Nếu đồng ý, tôi sẽ chạy migration và cập nhật các file cần thiết theo thứ tự an toàn (migrations → backend → frontend → tests).