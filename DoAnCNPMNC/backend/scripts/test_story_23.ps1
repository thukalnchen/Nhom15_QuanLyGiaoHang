# Test Story #23 - Pricing Policy API
Write-Host "Testing Story #23 - Pricing Policy API" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:3000/api"

# Step 1: Login as admin
Write-Host "1. Logging in as admin..." -ForegroundColor Yellow
$loginBody = @{
    email = "admin@fooddelivery.com"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.data.token
    Write-Host "   ✓ Login successful" -ForegroundColor Green
    Write-Host "   Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Login failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Get pricing tables
Write-Host "2. Getting pricing tables..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $pricingResponse = Invoke-RestMethod -Uri "$baseUrl/pricing/pricing" -Method Get -Headers $headers
    Write-Host "   ✓ Got $($pricingResponse.data.Count) pricing tables" -ForegroundColor Green
    
    foreach ($pricing in $pricingResponse.data) {
        Write-Host "   - $($pricing.vehicle_type): Base=$($pricing.base_price), PerKm=$($pricing.price_per_km)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Step 3: Update pricing
Write-Host "3. Updating bike pricing..." -ForegroundColor Yellow
try {
    $updateBody = @{
        vehicleType = "bike"
        basePrice = 20000
        pricePerKm = 3500
        minimumPrice = 20000
        surgeMultiplier = 1.0
        description = "Xe máy - Updated by test"
    } | ConvertTo-Json
    
    $updateResponse = Invoke-RestMethod -Uri "$baseUrl/pricing/pricing" -Method Put -Headers $headers -Body $updateBody
    Write-Host "   ✓ Updated successfully" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Step 4: Get surcharges
Write-Host "4. Getting surcharges..." -ForegroundColor Yellow
try {
    $surchargesResponse = Invoke-RestMethod -Uri "$baseUrl/pricing/surcharges" -Method Get -Headers $headers
    Write-Host "   ✓ Got $($surchargesResponse.data.Count) surcharges" -ForegroundColor Green
    
    foreach ($surcharge in $surchargesResponse.data) {
        Write-Host "   - $($surcharge.name): $($surcharge.value) ($($surcharge.type))" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}

Write-Host ""

# Step 5: Get discounts
Write-Host "5. Getting discounts..." -ForegroundColor Yellow
try {
    $discountsResponse = Invoke-RestMethod -Uri "$baseUrl/pricing/discounts" -Method Get -Headers $headers
    Write-Host "   ✓ Got $($discountsResponse.data.Count) discounts" -ForegroundColor Green
    
    foreach ($discount in $discountsResponse.data) {
        Write-Host "   - $($discount.code): $($discount.value) ($($discount.type))" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Story #23 API Test Complete!" -ForegroundColor Cyan
