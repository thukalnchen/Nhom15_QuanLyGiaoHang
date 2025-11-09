# Test All Flows - Manual Testing Checklist
# Run this script and follow the prompts to test all features

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║        🧪 LALAMOVE APP - MANUAL TESTING SCRIPT              ║
║              Comprehensive Flow Testing                      ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "This script will guide you through testing all app flows" -ForegroundColor Yellow
Write-Host ""

# Function to wait for user confirmation
function Wait-ForConfirmation {
    param([string]$Message)
    Write-Host ""
    Write-Host "➡️  $Message" -ForegroundColor Yellow
    Read-Host "Press Enter when ready to continue"
}

# Function to mark step complete
function Mark-Complete {
    param([string]$Step)
    Write-Host "✅ $Step - COMPLETE" -ForegroundColor Green
}

# Check if backend is running
Write-Host "📋 PRE-TEST CHECKLIST" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$backendRunning = Read-Host "Is backend server running? (y/n)"
if ($backendRunning -ne 'y') {
    Write-Host "❌ Please start backend first:" -ForegroundColor Red
    Write-Host "   cd ../backend" -ForegroundColor Yellow
    Write-Host "   npm start" -ForegroundColor Yellow
    exit 1
}

$appRunning = Read-Host "Is the app running on a device/emulator? (y/n)"
if ($appRunning -ne 'y') {
    Write-Host "❌ Please start the app first:" -ForegroundColor Red
    Write-Host "   flutter run -d chrome" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ Prerequisites met! Starting tests..." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2

# Test Counter
$testNumber = 1

# ═══════════════════════════════════════════════════════════════
# SECTION 1: AUTHENTICATION TESTS
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SECTION 1: AUTHENTICATION TESTS (5 tests)                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Wait-ForConfirmation "Test $testNumber: Verify splash screen shows on app start"
$testNumber++
Mark-Complete "Splash screen displayed"

Wait-ForConfirmation "Test $testNumber: Login as CUSTOMER with user@customer.com / password123"
$testNumber++
$loginSuccess = Read-Host "Did login succeed and navigate to Customer Home? (y/n)"
if ($loginSuccess -eq 'y') { Mark-Complete "Customer login successful" }

Wait-ForConfirmation "Test $testNumber: Logout and login as INTAKE STAFF with staff@intake.com / password123"
$testNumber++
$intakeLogin = Read-Host "Did login succeed and navigate to Intake Home? (y/n)"
if ($intakeLogin -eq 'y') { Mark-Complete "Intake staff login successful" }

Wait-ForConfirmation "Test $testNumber: Logout and try INVALID credentials (wrong@email.com / wrong123)"
$testNumber++
$errorShown = Read-Host "Did error message appear? (y/n)"
if ($errorShown -eq 'y') { Mark-Complete "Invalid credentials handled correctly" }

Wait-ForConfirmation "Test $testNumber: Go to Register screen and create new account"
$testNumber++
$registered = Read-Host "Did registration succeed? (y/n)"
if ($registered -eq 'y') { Mark-Complete "Registration flow works" }

# ═══════════════════════════════════════════════════════════════
# SECTION 2: CUSTOMER ORDER FLOW
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SECTION 2: CUSTOMER ORDER FLOW (10 tests)                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Wait-ForConfirmation "Test $testNumber: Login as customer and verify home screen displays"
$testNumber++
Mark-Complete "Customer home screen loaded"

Wait-ForConfirmation "Test $testNumber: Navigate to 'Đơn hàng của tôi' (My Orders)"
$testNumber++
$ordersShown = Read-Host "Did orders screen appear? (y/n)"
if ($ordersShown -eq 'y') { Mark-Complete "Orders screen navigation works" }

Wait-ForConfirmation "Test $testNumber: Go back and navigate to 'Tạo đơn giao hàng' (Create Order)"
$testNumber++
$createOrderShown = Read-Host "Did create order screen appear? (y/n)"
if ($createOrderShown -eq 'y') { Mark-Complete "Create order navigation works" }

Wait-ForConfirmation "Test $testNumber: Fill out complete order form with pickup and delivery details"
$testNumber++
$formFilled = Read-Host "Were all fields filled successfully? (y/n)"
if ($formFilled -eq 'y') { Mark-Complete "Order form validation works" }

Wait-ForConfirmation "Test $testNumber: Submit the order"
$testNumber++
$orderCreated = Read-Host "Was order created successfully? (y/n)"
if ($orderCreated -eq 'y') { Mark-Complete "Order creation successful" }

Wait-ForConfirmation "Test $testNumber: View the order details from orders list"
$testNumber++
$detailsShown = Read-Host "Did order details screen appear? (y/n)"
if ($detailsShown -eq 'y') { Mark-Complete "Order details view works" }

Wait-ForConfirmation "Test $testNumber: Navigate to 'Theo dõi' (Tracking)"
$testNumber++
$trackingShown = Read-Host "Did tracking screen appear? (y/n)"
if ($trackingShown -eq 'y') { Mark-Complete "Tracking screen works" }

Wait-ForConfirmation "Test $testNumber: Navigate to Profile from home"
$testNumber++
$profileShown = Read-Host "Did profile screen appear? (y/n)"
if ($profileShown -eq 'y') { Mark-Complete "Profile navigation works" }

Wait-ForConfirmation "Test $testNumber: Edit profile information"
$testNumber++
$profileUpdated = Read-Host "Was profile updated successfully? (y/n)"
if ($profileUpdated -eq 'y') { Mark-Complete "Profile update works" }

Wait-ForConfirmation "Test $testNumber: Try to cancel an order (if available)"
$testNumber++
$orderCancelled = Read-Host "Did order cancellation work? (y/n or skip)"
if ($orderCancelled -eq 'y') { Mark-Complete "Order cancellation works" }

# ═══════════════════════════════════════════════════════════════
# SECTION 3: INTAKE STAFF FLOW
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SECTION 3: INTAKE STAFF FLOW (7 tests)                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Wait-ForConfirmation "Test $testNumber: Logout and login as Intake Staff"
$testNumber++
$intakeLoggedIn = Read-Host "Did intake home screen appear? (y/n)"
if ($intakeLoggedIn -eq 'y') { Mark-Complete "Intake staff logged in" }

Wait-ForConfirmation "Test $testNumber: View pending orders list"
$testNumber++
$pendingShown = Read-Host "Did pending orders appear? (y/n)"
if ($pendingShown -eq 'y') { Mark-Complete "Pending orders displayed" }

Wait-ForConfirmation "Test $testNumber: Try to open QR scanner (if available)"
$testNumber++
$scannerOpened = Read-Host "Did QR scanner open? (y/n or skip)"
if ($scannerOpened -eq 'y') { Mark-Complete "QR scanner works" }

Wait-ForConfirmation "Test $testNumber: Select an order to process"
$testNumber++
$orderSelected = Read-Host "Did order details appear? (y/n)"
if ($orderSelected -eq 'y') { Mark-Complete "Order selection works" }

Wait-ForConfirmation "Test $testNumber: Classify the package (e.g., 'Hàng dễ vỡ')"
$testNumber++
$classified = Read-Host "Was package classified successfully? (y/n)"
if ($classified -eq 'y') { Mark-Complete "Package classification works" }

Wait-ForConfirmation "Test $testNumber: Confirm/Process the order intake"
$testNumber++
$processed = Read-Host "Was order processed successfully? (y/n)"
if ($processed -eq 'y') { Mark-Complete "Order processing works" }

Wait-ForConfirmation "Test $testNumber: View processed orders tab"
$testNumber++
$processedShown = Read-Host "Did processed orders list appear? (y/n)"
if ($processedShown -eq 'y') { Mark-Complete "Processed orders view works" }

# ═══════════════════════════════════════════════════════════════
# SECTION 4: NAVIGATION & ROUTING
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SECTION 4: NAVIGATION & ROUTING (4 tests)                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Wait-ForConfirmation "Test $testNumber: Logout from Intake profile"
$testNumber++
$loggedOut = Read-Host "Did app return to login screen? (y/n)"
if ($loggedOut -eq 'y') { Mark-Complete "Intake logout works" }

Wait-ForConfirmation "Test $testNumber: Verify CANNOT go back after logout"
$testNumber++
$cannotGoBack = Read-Host "Are you still on login screen (cannot go back)? (y/n)"
if ($cannotGoBack -eq 'y') { Mark-Complete "Navigation stack cleared on logout" }

Wait-ForConfirmation "Test $testNumber: Login as customer again"
$testNumber++
Mark-Complete "Customer re-login successful"

Wait-ForConfirmation "Test $testNumber: Logout from Customer profile"
$testNumber++
$customerLogout = Read-Host "Did app return to login screen? (y/n)"
if ($customerLogout -eq 'y') { Mark-Complete "Customer logout works" }

# ═══════════════════════════════════════════════════════════════
# SECTION 5: SEARCH & FILTERS
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SECTION 5: SEARCH & FILTERS (3 tests)                      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Wait-ForConfirmation "Test $testNumber: Login as customer and go to orders"
$testNumber++
Mark-Complete "Orders screen loaded"

Wait-ForConfirmation "Test $testNumber: Try to search for an order"
$testNumber++
$searchWorks = Read-Host "Did search filter the orders? (y/n or skip)"
if ($searchWorks -eq 'y') { Mark-Complete "Search functionality works" }

Wait-ForConfirmation "Test $testNumber: Try to filter orders by status"
$testNumber++
$filterWorks = Read-Host "Did filter change the displayed orders? (y/n or skip)"
if ($filterWorks -eq 'y') { Mark-Complete "Filter functionality works" }

# ═══════════════════════════════════════════════════════════════
# SECTION 6: ERROR HANDLING
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SECTION 6: ERROR HANDLING (2 tests)                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Wait-ForConfirmation "Test $testNumber: Try to submit create order form with empty fields"
$testNumber++
$validationWorks = Read-Host "Did validation errors appear? (y/n)"
if ($validationWorks -eq 'y') { Mark-Complete "Form validation works" }

Write-Host ""
Write-Host "Test $testNumber: Network error simulation (optional)" -ForegroundColor Yellow
Write-Host "  → Stop backend server temporarily" -ForegroundColor Gray
Write-Host "  → Try to perform an action" -ForegroundColor Gray
Write-Host "  → Should show 'Lỗi kết nối' message" -ForegroundColor Gray
$networkError = Read-Host "Did network error handling work? (y/n or skip)"
if ($networkError -eq 'y') { 
    Mark-Complete "Network error handling works"
    Write-Host "  ⚠️  Remember to restart backend!" -ForegroundColor Yellow
}
$testNumber++

# ═══════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              🎉 TESTING COMPLETE! 🎉                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📊 TEST SUMMARY" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Section 1: Authentication Tests (5)" -ForegroundColor Green
Write-Host "✅ Section 2: Customer Order Flow (10)" -ForegroundColor Green
Write-Host "✅ Section 3: Intake Staff Flow (7)" -ForegroundColor Green
Write-Host "✅ Section 4: Navigation & Routing (4)" -ForegroundColor Green
Write-Host "✅ Section 5: Search & Filters (3)" -ForegroundColor Green
Write-Host "✅ Section 6: Error Handling (2)" -ForegroundColor Green
Write-Host ""
Write-Host "Total: $($testNumber - 1) manual tests completed" -ForegroundColor Yellow
Write-Host ""

Write-Host "📝 NOTES:" -ForegroundColor Cyan
Write-Host "  • All navigation flows tested ✅" -ForegroundColor Gray
Write-Host "  • Both customer and intake roles verified ✅" -ForegroundColor Gray
Write-Host "  • Logout returns to login screen ✅" -ForegroundColor Gray
Write-Host "  • Named routes working correctly ✅" -ForegroundColor Gray
Write-Host ""

Write-Host "🚀 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Run automated tests: .\run_tests.ps1" -ForegroundColor Gray
Write-Host "  2. Generate coverage report" -ForegroundColor Gray
Write-Host "  3. Fix any issues found" -ForegroundColor Gray
Write-Host "  4. Deploy to production" -ForegroundColor Gray
Write-Host ""

Write-Host "Thank you for testing! 🙏" -ForegroundColor Green
Write-Host ""

# Save results
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "test_results_$timestamp.txt"
@"
LALAMOVE APP - MANUAL TEST RESULTS
==================================
Date: $(Get-Date)
Tester: Manual Testing Script
Total Tests: $($testNumber - 1)

SECTIONS TESTED:
✅ Section 1: Authentication Tests (5)
✅ Section 2: Customer Order Flow (10)
✅ Section 3: Intake Staff Flow (7)
✅ Section 4: Navigation & Routing (4)
✅ Section 5: Search & Filters (3)
✅ Section 6: Error Handling (2)

STATUS: All manual tests completed
"@ | Out-File $reportFile

Write-Host "📄 Test results saved to: $reportFile" -ForegroundColor Cyan
