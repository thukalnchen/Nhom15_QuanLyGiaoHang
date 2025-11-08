# 🚀 HƯỚNG DẪN TIẾP TỤC PHÁT TRIỂN APP_INTAKE

## 📊 TÌNH TRẠNG HIỆN TẠI

### ✅ ĐÃ HOÀN THÀNH (40%)
1. **Project Setup** ✅
   - Flutter project created
   - 122 dependencies installed
   - Folder structure hoàn chỉnh

2. **Core Architecture** ✅
   - Models: `user_model.dart`, `order_model.dart`
   - Providers: `auth_provider.dart`, `warehouse_provider.dart`
   - Services: `api_service.dart` (all endpoints defined)
   - Utils: `constants.dart` (colors, statuses, validators)

3. **Basic Screens** ✅
   - Splash screen với auto navigation
   - Login screen (intake staff only)
   - Home screen (dashboard + bottom navigation)
   - Profile screen (user info + logout)
   - Placeholder screens (Scan, Orders, Warehouse)

### ⏳ ĐANG CHỜ (60%)
1. **Backend API** ⚠️ BLOCKER
2. **Database Schema Updates** ⚠️ BLOCKER
3. **Main Screens** (Stories 8, 9, 11, 12, 21)
4. **Widgets Library**
5. **Testing & Integration**

---

## 🎯 ROADMAP - 3 BƯỚC THỰC HIỆN

### 🔴 **BƯỚC 1: BACKEND API (PRIORITY 1 - BẮT BUỘC)**

#### Tạo Warehouse Routes & Controller

**File 1: `backend/routes/warehouse.js`**
```javascript
const express = require('express');
const router = express.Router();
const warehouseController = require('../controllers/warehouseController');
const auth = require('../middleware/auth');

// Middleware: Only intake_staff can access
const intakeStaffOnly = (req, res, next) => {
  if (req.user.role !== 'intake_staff') {
    return res.status(403).json({
      success: false,
      message: 'Chỉ nhân viên kho mới có quyền truy cập'
    });
  }
  next();
};

// All routes require authentication
router.use(auth);
router.use(intakeStaffOnly);

// Get warehouse orders
router.get('/orders', warehouseController.getWarehouseOrders);

// Search order by code (for QR scan)
router.get('/orders/search', warehouseController.searchOrderByCode);

// Story #8: Receive order
router.post('/receive', warehouseController.receiveOrder);

// Story #9: Classify order
router.post('/classify', warehouseController.classifyOrder);

// Story #21: Assign driver
router.post('/assign-driver', warehouseController.assignDriver);

// Get available drivers
router.get('/drivers/available', warehouseController.getAvailableDrivers);

// Story #12: Collect COD at warehouse
router.post('/collect-cod', warehouseController.collectCOD);

// Story #11: Generate receipt
router.post('/generate-receipt', warehouseController.generateReceipt);

// Statistics
router.get('/statistics', warehouseController.getStatistics);

module.exports = router;
```

**File 2: `backend/controllers/warehouseController.js`**
```javascript
const db = require('../config/database');

// Get all warehouse orders (pending, received, classified, ready)
exports.getWarehouseOrders = async (req, res) => {
  try {
    const query = `
      SELECT * FROM orders 
      WHERE status IN ('pending', 'received_at_warehouse', 'classified', 'ready_for_pickup')
      ORDER BY created_at DESC
    `;
    
    const result = await db.query(query);
    
    res.json({
      success: true,
      orders: result.rows
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Search order by code (QR scan)
exports.searchOrderByCode = async (req, res) => {
  try {
    const { code } = req.query;
    
    const query = 'SELECT * FROM orders WHERE order_code = $1';
    const result = await db.query(query, [code]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng'
      });
    }
    
    res.json({
      success: true,
      order: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #8: Receive order at warehouse
exports.receiveOrder = async (req, res) => {
  try {
    const {
      order_id,
      package_size,
      package_type,
      weight,
      description,
      images
    } = req.body;
    
    const warehouseId = req.user.warehouse_id;
    const warehouseName = req.user.warehouse_name;
    const intakeStaffId = req.user.id;
    const intakeStaffName = req.user.name;
    
    const query = `
      UPDATE orders 
      SET 
        status = 'received_at_warehouse',
        package_size = $1,
        package_type = $2,
        weight = $3,
        description = $4,
        images = $5,
        warehouse_id = $6,
        warehouse_name = $7,
        intake_staff_id = $8,
        intake_staff_name = $9,
        received_at = NOW(),
        updated_at = NOW()
      WHERE id = $10 AND status = 'pending'
      RETURNING *
    `;
    
    const result = await db.query(query, [
      package_size,
      package_type,
      weight,
      description,
      JSON.stringify(images || []),
      warehouseId,
      warehouseName,
      intakeStaffId,
      intakeStaffName,
      order_id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể nhận đơn hàng. Đơn hàng không tồn tại hoặc đã được xử lý.'
      });
    }
    
    res.json({
      success: true,
      message: 'Đã nhận đơn hàng thành công',
      order: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #9: Classify order
exports.classifyOrder = async (req, res) => {
  try {
    const {
      order_id,
      zone,
      recommended_vehicle
    } = req.body;
    
    const query = `
      UPDATE orders 
      SET 
        status = 'classified',
        zone = $1,
        recommended_vehicle = $2,
        classified_at = NOW(),
        updated_at = NOW()
      WHERE id = $3 AND status = 'received_at_warehouse'
      RETURNING *
    `;
    
    const result = await db.query(query, [
      zone,
      recommended_vehicle,
      order_id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể phân loại. Đơn hàng chưa được nhận tại kho.'
      });
    }
    
    res.json({
      success: true,
      message: 'Đã phân loại đơn hàng thành công',
      order: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #21: Assign driver
exports.assignDriver = async (req, res) => {
  try {
    const { order_id, driver_id } = req.body;
    
    // Get driver info
    const driverQuery = 'SELECT * FROM users WHERE id = $1 AND role = \'driver\'';
    const driverResult = await db.query(driverQuery, [driver_id]);
    
    if (driverResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy tài xế'
      });
    }
    
    const driver = driverResult.rows[0];
    
    const query = `
      UPDATE orders 
      SET 
        status = 'assigned_to_driver',
        driver_id = $1,
        driver_name = $2,
        driver_phone = $3,
        vehicle_type = $4,
        assigned_at = NOW(),
        updated_at = NOW()
      WHERE id = $5 AND status IN ('classified', 'ready_for_pickup')
      RETURNING *
    `;
    
    const result = await db.query(query, [
      driver.id,
      driver.name,
      driver.phone,
      driver.vehicle_type,
      order_id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể phân tài xế. Đơn hàng chưa được phân loại.'
      });
    }
    
    res.json({
      success: true,
      message: 'Đã phân tài xế thành công',
      order: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Get available drivers
exports.getAvailableDrivers = async (req, res) => {
  try {
    const { vehicle_type } = req.query;
    
    let query = `
      SELECT id, name, phone, vehicle_type, vehicle_number
      FROM users 
      WHERE role = 'driver' AND is_active = true
    `;
    
    const params = [];
    if (vehicle_type) {
      query += ' AND vehicle_type = $1';
      params.push(vehicle_type);
    }
    
    query += ' ORDER BY name';
    
    const result = await db.query(query, params);
    
    res.json({
      success: true,
      drivers: result.rows
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #12: Collect COD at warehouse
exports.collectCOD = async (req, res) => {
  try {
    const { order_id, amount } = req.body;
    
    const query = `
      UPDATE orders 
      SET 
        cod_collected_at_warehouse = true,
        cod_collected_at = NOW(),
        updated_at = NOW()
      WHERE id = $1 
        AND is_cod = true 
        AND cod_payment_type = 'sender_pays'
        AND cod_collected_at_warehouse = false
      RETURNING *
    `;
    
    const result = await db.query(query, [order_id]);
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể thu COD. Đơn hàng không phải COD hoặc đã thu rồi.'
      });
    }
    
    res.json({
      success: true,
      message: 'Đã xác nhận thu COD thành công',
      order: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Story #11: Generate receipt (placeholder)
exports.generateReceipt = async (req, res) => {
  try {
    const { order_id } = req.body;
    
    const query = 'SELECT * FROM orders WHERE id = $1';
    const result = await db.query(query, [order_id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng'
      });
    }
    
    // TODO: Generate PDF receipt here
    
    res.json({
      success: true,
      message: 'Đã tạo biên nhận',
      order: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Get statistics
exports.getStatistics = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    
    const query = `
      SELECT 
        COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
        COUNT(*) FILTER (WHERE status = 'received_at_warehouse') as received_count,
        COUNT(*) FILTER (WHERE status = 'classified') as classified_count,
        COUNT(*) FILTER (WHERE status = 'ready_for_pickup') as ready_count,
        COUNT(*) FILTER (WHERE DATE(received_at) = $1) as today_received
      FROM orders
    `;
    
    const result = await db.query(query, [today]);
    
    res.json({
      success: true,
      statistics: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
```

**File 3: Update `backend/server.js`**
```javascript
// Add this line with other route imports
const warehouseRoutes = require('./routes/warehouse');

// Add this line with other route registrations
app.use('/api/warehouse', warehouseRoutes);
```

#### Database Migration

**File: `backend/scripts/migrate-warehouse-fields.js`**
```javascript
const db = require('../config/database');

async function migrate() {
  try {
    console.log('Starting warehouse fields migration...');
    
    // Add new columns to orders table
    const queries = [
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS warehouse_id VARCHAR(50)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS warehouse_name VARCHAR(255)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS intake_staff_id VARCHAR(50)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS intake_staff_name VARCHAR(255)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS received_at TIMESTAMP`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS classified_at TIMESTAMP`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS zone VARCHAR(20)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS recommended_vehicle VARCHAR(20)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS cod_payment_type VARCHAR(20)`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS cod_collected_at_warehouse BOOLEAN DEFAULT FALSE`,
      `ALTER TABLE orders ADD COLUMN IF NOT EXISTS cod_collected_at TIMESTAMP`,
    ];
    
    for (const query of queries) {
      await db.query(query);
      console.log('✓', query);
    }
    
    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();
```

**Chạy migration:**
```bash
cd backend
node scripts/migrate-warehouse-fields.js
```

---

### 🟡 **BƯỚC 2: IMPLEMENT SCREENS (PRIORITY 2)**

Sau khi backend xong, làm theo thứ tự:

#### 2.1. Story #8 - Scan & Receive Order

**File: `lib/screens/scan/scan_screen.dart`**
- Import `mobile_scanner` package
- Scan QR code → Get order_code
- Call API: `searchOrderByCode()`
- Navigate to `OrderIntakeScreen`

**File: `lib/screens/scan/order_intake_screen.dart`**
- Form nhập thông tin:
  - Dropdown: Package size (small/medium/large/extra_large)
  - Dropdown: Package type (document/parcel/food/fragile...)
  - TextField: Weight (number input)
  - TextField: Description (optional)
  - ImagePicker: 4 photos max
- Button: "Xác nhận nhận hàng"
- Call API: `receiveOrder()`

#### 2.2. Story #9 - Classification

**File: `lib/screens/warehouse/classification_screen.dart`**
- Display order info
- Calculate distance (pickup → delivery)
- Auto-suggest:
  - Zone (based on distance)
  - Vehicle (based on package size)
- Allow manual override
- Button: "Phân loại"
- Call API: `classifyOrder()`

#### 2.3. Story #12 - COD Collection

**File: `lib/screens/warehouse/cod_collection_screen.dart`**
- Show only orders with `is_cod = true` AND `cod_payment_type = 'sender_pays'`
- Display COD amount
- Checkbox: "Đã thu tiền từ người gửi"
- Button: "Xác nhận"
- Call API: `collectCOD()`

#### 2.4. Story #21 - Driver Assignment

**File: `lib/screens/warehouse/assignment_screen.dart`**
- Display classified orders
- For each order:
  - Show recommended_vehicle
  - Load available drivers (filter by vehicle_type)
  - Dropdown: Select driver
  - Button: "Phân tài xế"
  - Call API: `assignDriver()`

#### 2.5. Story #11 - Receipt Generation

**File: `lib/screens/warehouse/receipt_screen.dart`**
- Use `pdf` package to generate PDF
- Include:
  - Order code, QR code
  - Pickup/Delivery addresses
  - Package info (size, weight, type)
  - Recommended vehicle
  - COD info
  - Intake staff signature
- Button: "In biên nhận" (use `printing` package)

---

### 🟢 **BƯỚC 3: WIDGETS & POLISH (PRIORITY 3)**

#### Widgets Library

**File: `lib/widgets/order_card.dart`**
```dart
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  
  // Display order info in a nice card
}
```

**File: `lib/widgets/status_badge.dart`**
```dart
class StatusBadge extends StatelessWidget {
  final String status;
  
  // Color-coded badge for order status
}
```

**File: `lib/widgets/package_info_card.dart`**
```dart
class PackageInfoCard extends StatelessWidget {
  final Order order;
  
  // Display package details (size, weight, type, images)
}
```

---

## 🧪 TESTING CHECKLIST

### Unit Tests
- [ ] AuthProvider login/logout
- [ ] WarehouseProvider receive/classify/assign
- [ ] Order model fromJson/toJson
- [ ] Validators (phone, weight, order code)

### Integration Tests
- [ ] Login → Dashboard
- [ ] Scan QR → Receive order
- [ ] Receive → Classify → Assign flow
- [ ] COD collection
- [ ] Receipt generation

### E2E Flow Tests
```
1. Customer creates order (app_user) → status: pending
2. Intake staff scans QR (app_intake) → status: received_at_warehouse
3. Classify package → status: classified
4. Collect COD (if sender_pays) → cod_collected_at_warehouse: true
5. Assign driver → status: assigned_to_driver
6. Driver picks up (app_driver) → status: in_transit
7. Deliver → status: delivered
```

---

## 💡 TIPS & BEST PRACTICES

### For Backend Development
1. **Error Handling**: Wrap all DB queries in try-catch
2. **Validation**: Validate input data before DB operations
3. **Transactions**: Use DB transactions for multi-step operations
4. **Logging**: Log all important operations (receive, classify, assign)

### For Flutter Development
1. **Loading States**: Always show loading indicator during API calls
2. **Error Messages**: Show user-friendly error messages
3. **Offline Handling**: Consider caching data with `shared_preferences`
4. **Image Optimization**: Compress images before upload

### For Testing
1. **Mock Data**: Create test orders with QR codes
2. **Real Devices**: Test QR scanner on real Android/iOS device
3. **Network Errors**: Test offline scenarios
4. **Permissions**: Test camera/storage permissions

---

## 🚨 COMMON ISSUES & SOLUTIONS

### Issue 1: QR Scanner không hoạt động
**Solution**: 
- Check permissions in `AndroidManifest.xml`
- Test on real device (not emulator)
- Use `mobile_scanner` instead of `qr_code_scanner`

### Issue 2: Backend API CORS errors
**Solution**: 
- Check CORS configuration in `server.js`
- Allow mobile app origins

### Issue 3: Database migration fails
**Solution**: 
- Check PostgreSQL connection
- Run migrations one by one
- Check column names (case-sensitive)

---

## 📞 SUPPORT

Nếu gặp vấn đề, kiểm tra:
1. ✅ Backend server đang chạy (`npm start`)
2. ✅ Database đã migrate
3. ✅ Flutter dependencies installed (`flutter pub get`)
4. ✅ API endpoints đúng URL

---

**Status**: 📝 GUIDE READY - BẮT ĐẦU TỪ BƯỚC 1 (BACKEND API)

**Next Action**: Tạo `backend/routes/warehouse.js` và `backend/controllers/warehouseController.js`
