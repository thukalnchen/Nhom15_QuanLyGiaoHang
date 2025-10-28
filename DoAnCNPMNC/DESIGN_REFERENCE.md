# 🎨 Lalamove Design Quick Reference

## Màu sắc chính
```dart
AppColors.primary          = #F26522  // Cam Lalamove
AppColors.primaryDark      = #D64F0A  // Cam đậm
AppColors.secondary        = #2C3E50  // Xám xanh đậm
AppColors.success          = #10B981  // Xanh lá
AppColors.warning          = #F59E0B  // Vàng
AppColors.danger           = #EF4444  // Đỏ
AppColors.background       = #FAFAFA  // Xám nhạt
AppColors.lightGrey        = #F3F4F6  // Xám rất nhạt
```

## Icon Mapping
```dart
// FOOD → DELIVERY
Icons.restaurant           → Icons.local_shipping_rounded
Icons.shopping_cart        → Icons.receipt_long
Icons.add_shopping_cart    → Icons.inventory_2
Icons.fastfood             → Icons.inventory_2_outlined
Icons.store                → Icons.location_on
```

## Text Mapping
```dart
// FOOD TERMS → DELIVERY TERMS
"Nhà hàng"                → "Người gửi"
"Sản phẩm"                → "Kiện hàng"
"Món ăn"                  → "Gói hàng"
"Tạo đơn hàng"            → "Tạo đơn giao hàng"
"Đặt món"                 → "Gửi hàng"
"Thêm sản phẩm"           → "Thêm kiện hàng"
"Food Delivery"           → "Lalamove Express"
```

## Component Styles

### Cards
```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: AppColors.lightGrey, width: 1),
  ),
)
```

### Buttons
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: EdgeInsets.symmetric(vertical: 16),
    elevation: 2,
  ),
)
```

### Status Badges
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: AppUtils.getStatusColor(status),
    borderRadius: BorderRadius.circular(20), // pill shape
  ),
  child: Text(
    AppUtils.getStatusText(status),
    style: TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### Gradient Containers
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.primary, AppColors.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.3),
        blurRadius: 15,
        offset: Offset(0, 5),
      ),
    ],
  ),
)
```

### Icon Containers
```dart
Container(
  width: 50,
  height: 50,
  decoration: BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Icon(
    Icons.local_shipping_rounded,
    color: AppColors.primary,
    size: 28,
  ),
)
```

## Typography Scale
```dart
// Display Large
fontSize: 30, fontWeight: FontWeight.bold

// Headline
fontSize: 20-22, fontWeight: FontWeight.bold

// Title
fontSize: 16-18, fontWeight: FontWeight.bold

// Body
fontSize: 14-15, fontWeight: FontWeight.normal

// Caption
fontSize: 12-13, color: AppColors.grey

// Badge/Label
fontSize: 11, fontWeight: FontWeight.w600
```

## Spacing
```dart
// Micro spacing
4, 6, 8

// Small spacing
12, 16

// Medium spacing
20, 24

// Large spacing
30, 35, 40

// Extra large
50, 60
```

## Border Radius
```dart
// Small
8, 10

// Medium
12, 16

// Large
20, 30

// Pill (for badges)
999 or specific height/2
```

## Usage Examples

### Section Header
```dart
Widget _buildSectionHeader({
  required IconData icon,
  required String title,
  required Color color,
}) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      SizedBox(width: 12),
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),
      ),
    ],
  );
}
```

### Order Card
```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: AppColors.lightGrey, width: 1),
  ),
  child: ListTile(
    contentPadding: EdgeInsets.all(12),
    leading: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_shipping_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    ),
    title: Text('Delivery Order #123'),
    subtitle: Text('Sender Name'),
    trailing: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Delivered'),
    ),
  ),
)
```

---

Sử dụng guide này để maintain consistency trong design!
