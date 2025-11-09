# Debug Authentication Flow
# Tests login and checks stored data

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  AUTHENTICATION FLOW DEBUG" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test credentials
$email = "test123@gmail.com"
$password = "Trongkhang205@"

Write-Host "Step 1: Testing Backend Login API" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Gray
$body = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" `
        -Method POST `
        -Body $body `
        -ContentType "application/json"
    
    Write-Host "[OK] Login successful (Status: $($response.StatusCode))" -ForegroundColor Green
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "  Email: $($data.data.user.email)" -ForegroundColor Cyan
    Write-Host "  Name: $($data.data.user.name)" -ForegroundColor Cyan
    Write-Host "  Role: $($data.data.user.role)" -ForegroundColor Cyan
    Write-Host "  Token: $($data.data.token.Substring(0, 30))..." -ForegroundColor Gray
    Write-Host ""
    
    $userRole = $data.data.user.role
    $userName = $data.data.user.name
    
} catch {
    Write-Host "[ERROR] Login failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "Step 2: Check Flutter App State" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Gray

# Check if app is running
$flutterProcess = Get-Process -Name "flutter_tools*" -ErrorAction SilentlyContinue
if ($flutterProcess) {
    Write-Host "[OK] Flutter app is running" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Flutter app may not be running" -ForegroundColor Yellow
    Write-Host "  Start with: flutter run -d chrome" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 3: Expected Navigation" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Gray

switch ($userRole) {
    "customer" {
        Write-Host "[INFO] Should navigate to: Customer Home Screen" -ForegroundColor Cyan
        Write-Host "  Route: /home" -ForegroundColor Gray
        Write-Host "  Screen: lib/screens/customer/home/home_screen.dart" -ForegroundColor Gray
    }
    "intake_staff" {
        Write-Host "[INFO] Should navigate to: Intake Staff Home Screen" -ForegroundColor Cyan
        Write-Host "  Route: /intake-home" -ForegroundColor Gray
        Write-Host "  Screen: lib/screens/intake/home/home_screen.dart" -ForegroundColor Gray
    }
    "driver" {
        Write-Host "[INFO] Should navigate to: Driver Home Screen" -ForegroundColor Cyan
        Write-Host "  Note: Not implemented yet" -ForegroundColor Yellow
    }
    "admin" {
        Write-Host "[INFO] Should navigate to: Admin Dashboard" -ForegroundColor Cyan
        Write-Host "  Note: Not implemented yet" -ForegroundColor Yellow
    }
    default {
        Write-Host "[WARNING] Unknown role: $userRole" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Step 4: Troubleshooting" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Gray

if ([string]::IsNullOrEmpty($userName)) {
    Write-Host "[WARNING] User name is empty in backend response" -ForegroundColor Yellow
    Write-Host "  This might cause UI issues" -ForegroundColor Gray
    Write-Host "  Fix: Update user in database with a name" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 5: Common Issues & Solutions" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Gray
Write-Host ""

Write-Host "Issue 1: 'No authenticated user, navigating to login...'" -ForegroundColor Red
Write-Host "  Cause: SharedPreferences not persisting data" -ForegroundColor Gray
Write-Host "  Solution: Clear browser cache and re-login" -ForegroundColor Green
Write-Host "    Chrome: DevTools > Application > Storage > Clear site data" -ForegroundColor Cyan
Write-Host ""

Write-Host "Issue 2: Stuck on splash screen" -ForegroundColor Red
Write-Host "  Cause: Token expired or invalid" -ForegroundColor Gray
Write-Host "  Solution: Clear storage and re-login" -ForegroundColor Green
Write-Host ""

Write-Host "Issue 3: Wrong screen after login" -ForegroundColor Red
Write-Host "  Cause: Role mismatch or routing issue" -ForegroundColor Gray
Write-Host "  Solution: Check console logs for role detection" -ForegroundColor Green
Write-Host ""

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  MANUAL TESTING STEPS" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Open Chrome DevTools (F12)" -ForegroundColor Yellow
Write-Host ""

Write-Host "2. Go to Application tab > Storage" -ForegroundColor Yellow
Write-Host "   Check for:" -ForegroundColor Gray
Write-Host "   - flutter.token" -ForegroundColor Cyan
Write-Host "   - flutter.user" -ForegroundColor Cyan
Write-Host "   - flutter.role" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. If data exists, verify it matches:" -ForegroundColor Yellow
Write-Host "   - Role: $userRole" -ForegroundColor Cyan
Write-Host "   - Email: $email" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. Watch Console tab for debug logs:" -ForegroundColor Yellow
Write-Host "   - 'Initializing app...'" -ForegroundColor Gray
Write-Host "   - 'User authenticated: ...'" -ForegroundColor Gray
Write-Host "   - 'Navigating to Customer Home...'" -ForegroundColor Gray
Write-Host ""

Write-Host "5. If issues persist:" -ForegroundColor Yellow
Write-Host "   a) Clear all site data" -ForegroundColor Cyan
Write-Host "   b) Refresh page (F5)" -ForegroundColor Cyan
Write-Host "   c) Login again with:" -ForegroundColor Cyan
Write-Host "      Email: $email" -ForegroundColor White
Write-Host "      Pass: $password" -ForegroundColor White
Write-Host ""

Write-Host "=====================================" -ForegroundColor Green
Write-Host "  Debug script complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Next: Run the app and check console logs" -ForegroundColor Yellow
Write-Host "  flutter run -d chrome" -ForegroundColor Cyan
