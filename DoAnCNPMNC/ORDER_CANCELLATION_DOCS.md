# 🚫 Order Cancellation Feature - Documentation

## 📋 Overview
Tính năng hủy đơn hàng cho phép khách hàng hủy đơn với validation đầy đủ, tracking lý do, và hỗ trợ hoàn tiền.

---

## ✅ Features Implemented

### 🔧 Backend (Node.js/Express)

#### **1. API Endpoints**

##### **POST /api/orders/:orderId/cancel**
Hủy đơn hàng với validation đầy đủ

**Request:**
```json
{
  "reason": "Tôi đã đặt nhầm địa chỉ giao hàng",
  "cancel_type": "wrong_address"
}
```

**Valid Cancel Types:**
- `customer_request` - Yêu cầu của khách hàng
- `out_of_stock` - Hết hàng
- `wrong_address` - Địa chỉ sai
- `duplicate_order` - Đơn hàng trùng lặp
- `change_mind` - Thay đổi ý định
- `other` - Lý do khác

**Response (Success):**
```json
{
  "status": "success",
  "message": "Order cancelled successfully",
  "data": {
    "order": {
      "id": 1,
      "order_number": "ORD-123456",
      "status": "cancelled",
      "cancellation_reason": "Tôi đã đặt nhầm địa chỉ giao hàng",
      "cancellation_type": "wrong_address",
      "cancelled_at": "2025-10-28T15:30:00.000Z",
      "refund_status": "pending",
      "updated_at": "2025-10-28T15:30:00.000Z"
    }
  }
}
```

**Response (Error - Cannot Cancel):**
```json
{
  "status": "error",
  "message": "Cannot cancel order with status: delivered",
  "current_status": "delivered"
}
```

**Response (Error - Requires Support):**
```json
{
  "status": "error",
  "message": "This order has been processing for too long. Please contact support to cancel.",
  "current_status": "processing",
  "requires_support": true
}
```

---

##### **GET /api/orders/stats/cancellations**
Lấy thống kê hủy đơn (Admin only)

**Query Parameters:**
- `startDate` (optional): Ngày bắt đầu (YYYY-MM-DD)
- `endDate` (optional): Ngày kết thúc (YYYY-MM-DD)

**Response:**
```json
{
  "status": "success",
  "data": {
    "total_cancelled": 25,
    "by_type": [
      { "type": "change_mind", "count": 10 },
      { "type": "wrong_address", "count": 8 },
      { "type": "duplicate_order", "count": 4 },
      { "type": "out_of_stock", "count": 2 },
      { "type": "other", "count": 1 }
    ]
  }
}
```

---

#### **2. Validation Rules**

| Rule | Description |
|------|-------------|
| **Reason Length** | Minimum 5 characters |
| **Cancel Type** | Must be one of valid types |
| **Order Ownership** | User must own the order |
| **Status Check** | Cannot cancel if status is: `delivered`, `cancelled`, `shipped`, `in_transit` |
| **Time Limit** | If status is `processing` for > 30 minutes, requires admin approval |
| **Permission** | Only order owner can cancel |

---

#### **3. Database Schema Changes**

**New Columns in `orders` table:**
```sql
ALTER TABLE orders ADD COLUMN cancellation_reason TEXT;
ALTER TABLE orders ADD COLUMN cancellation_type VARCHAR(50);
ALTER TABLE orders ADD COLUMN cancelled_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN cancelled_by INTEGER REFERENCES users(id);
ALTER TABLE orders ADD COLUMN payment_status VARCHAR(50) DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN payment_method VARCHAR(50);
ALTER TABLE orders ADD COLUMN refund_status VARCHAR(50);
ALTER TABLE orders ADD COLUMN refund_initiated_at TIMESTAMP;
```

---

#### **4. Business Logic**

**Cancellation Flow:**
```
1. Validate request (reason, cancel_type)
2. Check order exists & user owns it
3. Validate order status (cannot cancel if delivered/shipped/cancelled)
4. Check time constraints (processing > 30 min requires support)
5. BEGIN TRANSACTION
   a. Update order status to 'cancelled'
   b. Add cancellation details (reason, type, timestamp)
   c. Add to order_status_history
   d. Update delivery_tracking status
   e. If paid, initiate refund (set refund_status to 'pending')
6. COMMIT TRANSACTION
7. Return success response
```

**Refund Logic:**
- If `payment_status = 'paid'`, set `refund_status = 'pending'`
- Set `refund_initiated_at = CURRENT_TIMESTAMP`
- TODO: Integrate with payment gateway for actual refund

---

### 📱 Frontend (Flutter)

#### **1. CancelOrderScreen**
Full-featured cancellation UI với:
- Order information display
- Radio buttons for cancel type selection
- Text field for detailed reason (min 5 chars, max 500 chars)
- Warning box about irreversible action
- Confirmation dialog
- Loading state during submission
- Error handling với user-friendly messages

**Location:** `app_user/lib/screens/orders/cancel_order_screen.dart`

**Features:**
- ✅ Form validation
- ✅ Status checking (cannot cancel delivered/shipped orders)
- ✅ Confirmation dialog
- ✅ Loading indicator
- ✅ Success/error notifications
- ✅ Auto-refresh order list after cancellation

---

#### **2. OrdersScreen Integration**
- "Hủy" button on order cards (only for cancellable orders)
- Opens `CancelOrderScreen` on click
- Auto-refreshes list after successful cancellation

**Helper Method:**
```dart
bool _canCancelOrder(String status) {
  final cannotCancelStatuses = ['delivered', 'cancelled', 'shipped', 'in_transit'];
  return !cannotCancelStatuses.contains(status);
}
```

---

#### **3. OrderProvider Method**

**`cancelOrder()` method:**
```dart
Future<bool> cancelOrder({
  required int orderId,
  required String reason,
  required String cancelType,
  String? token,
}) async
```

**Features:**
- HTTP POST request to `/api/orders/:orderId/cancel`
- JWT authentication
- Error handling với specific messages
- Local state update (order status → 'cancelled')
- Returns `true` on success, `false` on failure

---

## 🧪 Testing

### **Test Script**
**Location:** `backend/scripts/test-cancellation.js`

**Run:**
```bash
cd backend
node scripts/test-cancellation.js
```

**Tests:**
1. ✅ Database schema validation
2. ✅ Find test order
3. ✅ Simulate cancellation
4. ✅ Status history update
5. ✅ Cancellation statistics
6. ✅ Rollback (restore original state)

---

### **Manual Testing Steps**

**1. Test Successful Cancellation:**
```bash
# Login and get token
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Cancel order
curl -X POST http://localhost:3000/api/orders/1/cancel \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "reason": "Test cancellation",
    "cancel_type": "customer_request"
  }'
```

**2. Test Validation Errors:**
```bash
# Missing reason
curl -X POST http://localhost:3000/api/orders/1/cancel \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"cancel_type": "customer_request"}'

# Invalid cancel_type
curl -X POST http://localhost:3000/api/orders/1/cancel \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "reason": "Test",
    "cancel_type": "invalid_type"
  }'
```

**3. Test Status Validation:**
```bash
# Try to cancel delivered order (should fail)
curl -X POST http://localhost:3000/api/orders/DELIVERED_ORDER_ID/cancel \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "reason": "Test cancellation",
    "cancel_type": "customer_request"
  }'
```

---

## 📊 Cancellation Statistics

**Query Example:**
```sql
-- Get cancellation stats by type
SELECT 
  cancellation_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM orders
WHERE status = 'cancelled'
GROUP BY cancellation_type
ORDER BY count DESC;

-- Get cancellation rate by date
SELECT 
  DATE(cancelled_at) as date,
  COUNT(*) as cancellations
FROM orders
WHERE status = 'cancelled'
  AND cancelled_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(cancelled_at)
ORDER BY date DESC;
```

---

## 🔒 Security Considerations

1. **Authentication:** All endpoints require valid JWT token
2. **Authorization:** Users can only cancel their own orders
3. **Validation:** Input validation on both frontend and backend
4. **SQL Injection Prevention:** Parameterized queries
5. **Transaction Safety:** Use database transactions for data consistency
6. **Rate Limiting:** Apply rate limiting to prevent abuse

---

## 🚀 Future Enhancements

### **Planned Features:**

1. **Admin Override:**
   - Allow admins to cancel any order
   - Override time constraints
   - Force cancellation with special notes

2. **Automatic Refunds:**
   - Integration with payment gateways (Momo, ZaloPay, VNPay)
   - Automatic refund processing
   - Refund status tracking (pending → processing → completed)

3. **Cancellation Fees:**
   - Apply cancellation fee based on order status
   - Different fee tiers (pending: 0%, processing: 10%, etc.)
   - Fee calculation in response

4. **Email Notifications:**
   - Send email when order is cancelled
   - Include cancellation reason and refund details
   - Estimated refund time

5. **Analytics Dashboard:**
   - Cancellation trends over time
   - Top cancellation reasons
   - Refund metrics
   - Customer cancellation patterns

6. **Appeal Process:**
   - Allow customers to appeal cancellation rejection
   - Admin review queue
   - Communication thread

---

## 📝 API Error Codes

| Status Code | Meaning | Example |
|-------------|---------|---------|
| 200 | Success | Order cancelled |
| 400 | Bad Request | Invalid cancel_type, reason too short |
| 401 | Unauthorized | Missing/invalid token |
| 404 | Not Found | Order doesn't exist or not owned by user |
| 500 | Server Error | Database error |

---

## 🎯 Usage Examples

### **Flutter App:**
```dart
// In OrdersScreen or OrderDetailsScreen
final orderProvider = Provider.of<OrderProvider>(context, listen: false);
final authProvider = Provider.of<AuthProvider>(context, listen: false);

final success = await orderProvider.cancelOrder(
  orderId: order['id'],
  reason: 'Changed my mind about delivery time',
  cancelType: 'change_mind',
  token: authProvider.token,
);

if (success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Order cancelled successfully')),
  );
  // Refresh orders list
  await orderProvider.getOrders(token: authProvider.token);
}
```

---

## ✅ Checklist

- [x] Backend API implementation
- [x] Database schema migration
- [x] Input validation
- [x] Business logic validation
- [x] Transaction handling
- [x] Error handling
- [x] Flutter UI screen
- [x] OrderProvider method
- [x] Integration with OrdersScreen
- [x] Test script
- [x] Documentation
- [ ] Payment gateway integration (TODO)
- [ ] Email notifications (TODO)
- [ ] Admin dashboard integration (TODO)

---

## 📞 Support

For questions or issues:
1. Check logs: `backend/logs/` (if logging enabled)
2. Review error messages in API response
3. Check database state: `SELECT * FROM orders WHERE status = 'cancelled'`
4. Contact development team

---

**Version:** 1.0.0  
**Last Updated:** October 28, 2025  
**Author:** Development Team
