# 🧪 Testing Guide - Lalamove App

## 📋 Overview

Comprehensive testing suite for the unified Lalamove app covering:
- ✅ Authentication flows
- ✅ Customer order management
- ✅ Intake staff workflows
- ✅ Profile & settings
- ✅ Notifications
- ✅ Search & filters
- ✅ Error handling
- ✅ State management
- ✅ UI/UX

---

## 🚀 Quick Start

### Run All Tests (Windows)
```powershell
.\run_tests.ps1
```

### Run All Tests (Linux/Mac)
```bash
chmod +x run_tests.sh
./run_tests.sh
```

### Run Specific Test File
```bash
flutter test test/integration_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

---

## 📁 Test Structure

```
test/
├── integration_test.dart          # 30 comprehensive integration tests
├── widget_test.dart               # Basic widget tests
├── providers/                     # Provider state management tests
│   ├── auth_provider_test.dart
│   └── order_provider_test.dart
├── screens/                       # Screen-specific tests
│   ├── login_screen_test.dart
│   └── home_screen_test.dart
└── services/                      # Service layer tests
    └── api_service_test.dart
```

---

## 🧪 Test Categories

### 1️⃣ Authentication Tests (5 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 1 | Splash Screen | Verifies splash screen displays on launch |
| 2 | Customer Login | Tests valid customer credentials |
| 3 | Intake Login | Tests valid intake staff credentials |
| 4 | Invalid Login | Tests error handling for wrong credentials |
| 5 | Registration | Tests new customer registration flow |

**Test Credentials:**
- Customer: `user@customer.com` / `password123`
- Intake Staff: `staff@intake.com` / `password123`

---

### 2️⃣ Customer Order Flow Tests (6 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 6 | Home → Orders | Navigation from home to orders list |
| 7 | Home → Create Order | Navigation to create order screen |
| 8 | Complete Order Flow | Full order creation with all fields |
| 9 | View Order Details | Tap on order to see details |
| 10 | Track Order | Access order tracking screen |
| 11 | Cancel Order | Order cancellation flow |

**Key Features Tested:**
- ✅ Navigation with named routes
- ✅ Form validation
- ✅ Order creation API
- ✅ Order status updates
- ✅ Real-time tracking

---

### 3️⃣ Intake Staff Flow Tests (5 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 12 | View Pending Orders | Display orders awaiting processing |
| 13 | QR Code Scanner | Open and use QR scanner |
| 14 | Process Order | Confirm order intake |
| 15 | Classify Package | Assign package classification |
| 16 | View Processed Orders | View completed intake tasks |

**Classifications:**
- Hàng thường (Regular)
- Hàng dễ vỡ (Fragile)
- Hàng giá trị cao (High value)
- Thực phẩm (Food)

---

### 4️⃣ Profile & Settings Tests (4 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 17 | View Profile | Access customer profile screen |
| 18 | Edit Profile | Update profile information |
| 19 | Customer Logout | Logout and return to login screen |
| 20 | Intake Logout | Intake staff logout flow |

**Verified:**
- ✅ Profile data persistence
- ✅ Logout clears navigation stack
- ✅ Returns to login screen
- ✅ Cannot navigate back after logout

---

### 5️⃣ Notification Tests (2 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 21 | Customer Notifications | View customer notifications |
| 22 | Intake Notifications | View intake staff notifications |

---

### 6️⃣ Search & Filter Tests (3 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 23 | Search Orders | Search by order ID or keyword |
| 24 | Filter by Status | Filter orders by status |
| 25 | Filter by Package Type | Filter packages by classification |

**Filter Options:**
- Tất cả (All)
- Chờ xử lý (Pending)
- Đang giao (In Transit)
- Đã giao (Delivered)
- Đã hủy (Cancelled)

---

### 7️⃣ Error Handling Tests (2 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 26 | Network Error | Handle API connection failures |
| 27 | Form Validation | Validate empty/invalid inputs |

**Error Scenarios:**
- ✅ No internet connection
- ✅ API timeout
- ✅ Invalid credentials
- ✅ Empty form fields
- ✅ Invalid phone format

---

### 8️⃣ State Management Tests (2 tests)

| # | Test Case | Description |
|---|-----------|-------------|
| 28 | Auth State Persistence | Login state persists across navigation |
| 29 | Order List Updates | Order list refreshes after creation |

**Providers Tested:**
- `AuthProvider` - Authentication state
- `OrderProvider` - Order management
- `WarehouseProvider` - Intake operations

---

### 9️⃣ UI/UX Tests (1 test)

| # | Test Case | Description |
|---|-----------|-------------|
| 30 | Dark Mode Toggle | Toggle dark/light theme |

---

## 🎯 Test Execution

### Prerequisites

1. **Backend Running**
   ```bash
   cd backend
   npm start
   ```

2. **Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Test Data**
   - Ensure test users exist in database
   - Have sample orders for testing

### Running Tests

#### All Tests
```bash
# Windows
.\run_tests.ps1

# Linux/Mac
./run_tests.sh
```

#### Specific Category
```bash
# Integration tests only
flutter test test/integration_test.dart

# Provider tests only
flutter test test/providers/

# Screen tests only
flutter test test/screens/
```

#### With Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

#### Watch Mode
```bash
flutter test --watch
```

---

## 📊 Test Results

### Expected Output

```
🧪 ==================================
   LALAMOVE APP - TEST SUITE
==================================

✅ Flutter found: Flutter 3.9.2

==================================
📋 TEST CATEGORIES
==================================

1️⃣  UNIT TESTS
🧪 Running: Widget Tests
✅ Widget Tests PASSED

2️⃣  INTEGRATION TESTS
🧪 Running: Integration Tests
✅ Integration Tests PASSED
   • Authentication Tests: 5/5 ✅
   • Customer Order Flow: 6/6 ✅
   • Intake Staff Flow: 5/5 ✅
   • Profile & Settings: 4/4 ✅
   • Notifications: 2/2 ✅
   • Search & Filter: 3/3 ✅
   • Error Handling: 2/2 ✅
   • State Management: 2/2 ✅
   • UI/UX: 1/1 ✅

==================================
📊 TEST SUMMARY
==================================
Total Tests:  30
Passed:       30
Failed:       0

🎉 ALL TESTS PASSED! 🎉
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Test Timeout
```
Error: Test timed out after 30 seconds
```
**Solution:**
- Increase timeout in test file
- Check if backend is running
- Verify network connectivity

#### 2. Widget Not Found
```
Error: No widget found matching text "Login"
```
**Solution:**
- Verify screen is rendered
- Check widget keys
- Use `pumpAndSettle()` to wait for animations

#### 3. Provider Not Found
```
Error: Could not find Provider<AuthProvider>
```
**Solution:**
- Wrap test widget with `MultiProvider`
- Provide all required providers

#### 4. Network Error
```
Error: SocketException: Failed to connect
```
**Solution:**
- Start backend server first
- Check `config.env` settings
- Verify API endpoints

---

## 📝 Writing New Tests

### Test Template

```dart
testWidgets('Test description', (WidgetTester tester) async {
  // 1. Setup
  await tester.pumpWidget(const LalamoveApp());
  await tester.pumpAndSettle();
  
  // 2. Action
  await tester.tap(find.text('Button'));
  await tester.pumpAndSettle();
  
  // 3. Assert
  expect(find.text('Expected Result'), findsOneWidget);
});
```

### Best Practices

1. **Use Descriptive Names**
   ```dart
   testWidgets('Customer can create order successfully', ...)
   ```

2. **Test One Thing**
   - Each test should verify one specific behavior

3. **Use Helper Functions**
   ```dart
   Future<void> _loginAsCustomer(WidgetTester tester) async {
     // Login logic
   }
   ```

4. **Clean Up**
   ```dart
   tearDown(() {
     // Clean up after each test
   });
   ```

5. **Mock External Dependencies**
   ```dart
   when(mockApiService.getOrders()).thenReturn(mockOrders);
   ```

---

## 🔄 Continuous Integration

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Flutter Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
      - run: flutter pub get
      - run: flutter test
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
        with:
          file: coverage/lcov.info
```

---

## 📈 Coverage Goals

| Category | Target | Current |
|----------|--------|---------|
| Overall | 80% | TBD |
| Providers | 90% | TBD |
| Screens | 70% | TBD |
| Services | 85% | TBD |

---

## 🎓 Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Provider Testing](https://pub.dev/packages/provider#testing)

---

## ✅ Test Checklist

Before pushing code:

- [ ] All tests pass locally
- [ ] New features have tests
- [ ] Coverage above 80%
- [ ] No flaky tests
- [ ] Tests run in < 5 minutes

---

**Last Updated:** 2025-01-09
**Version:** 1.0.0
**Status:** ✅ Ready for Testing
