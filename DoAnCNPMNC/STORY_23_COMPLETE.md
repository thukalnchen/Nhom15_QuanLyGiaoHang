# Story #23 - Pricing Policy Management

## ✅ Hoàn thành

### Backend API Endpoints
- `GET /api/pricing/pricing` - Lấy bảng giá theo loại xe
- `PUT /api/pricing/pricing` - Cập nhật giá (UPSERT)
- `GET /api/pricing/surcharges` - Lấy danh sách phụ phí
- `POST /api/pricing/surcharges` - Thêm phụ phí mới
- `PUT /api/pricing/surcharges/:id` - Cập nhật phụ phí
- `DELETE /api/pricing/surcharges/:id` - Xóa phụ phí
- `GET /api/pricing/discounts` - Lấy danh sách giảm giá
- `POST /api/pricing/discounts` - Thêm mã giảm giá
- `PUT /api/pricing/discounts/:id` - Cập nhật mã giảm giá
- `DELETE /api/pricing/discounts/:id` - Xóa mã giảm giá
- `POST /api/pricing/discounts/validate` - Validate mã giảm giá

### Database Tables
1. **pricing_tables**: Giá cơ bản theo loại xe
   - vehicle_type, base_price, price_per_km, minimum_price, surge_multiplier
2. **surcharges**: Phụ phí (giờ cao điểm, đêm, xăng dầu...)
   - name, type (percentage/fixed/multiplier), value
3. **discounts**: Mã giảm giá
   - code, name, type, value, min_order_value, max_discount, usage_limit

### Flutter UI
- **3 tabs**: Bảng Giá | Phụ Phí | Giảm Giá
- **CRUD Operations**: View, Add, Edit, Delete cho tất cả
- **Real-time data** từ PostgreSQL
- **Form validation** đầy đủ

### Files Modified
- `backend/controllers/pricingPolicyController.js` - Fixed table/column names
- `backend/routes/pricingPolicy.js` - Added delete endpoints
- `backend/scripts/create_pricing_tables.sql` - Migration script
- `lalamove_app/lib/services/admin_api_service.dart` - Added 10+ API methods
- `lalamove_app/lib/screens/admin/story_23_pricing_policy.dart` - Full rewrite with real data

## Test
1. Backend đang chạy: `http://localhost:3000`
2. Login: `admin@lalamove.com` / `admin123`
3. Test API bằng Postman hoặc script
4. Flutter app: Vào Admin Dashboard → Chính Sách Giá

## Dữ liệu mặc định
- 4 loại xe: bike, car, van, truck
- 3 surcharges (giờ cao điểm 20%, đêm 30%, xăng dầu 5000 VND)
- 3 discount codes (NEWUSER 20%, SAVE10K, FREESHIP)
