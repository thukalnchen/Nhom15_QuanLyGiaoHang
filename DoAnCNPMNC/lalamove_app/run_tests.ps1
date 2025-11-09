# Comprehensive Test Runner for Lalamove App
# PowerShell version for Windows

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "   LALAMOVE APP - TEST SUITE" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Change to app directory
Set-Location $PSScriptRoot

Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# Check if Flutter is installed
$flutterExists = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterExists) {
    Write-Host "[ERROR] Flutter is not installed!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Flutter found: $(flutter --version | Select-Object -First 1)" -ForegroundColor Green
Write-Host ""

# Function to run tests
function Run-Tests {
    param(
        [string]$TestFile,
        [string]$TestName
    )
    
    Write-Host "Running: $TestName" -ForegroundColor Yellow
    flutter test $TestFile --reporter expanded
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] $TestName" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        return $false
    }
}

# Initialize counters
$totalTests = 0
$passedTests = 0
$failedTests = 0

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TEST CATEGORIES" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 1. Unit Tests
Write-Host "1. UNIT TESTS" -ForegroundColor Cyan
if (Test-Path "test\widget_test.dart") {
    $totalTests++
    if (Run-Tests "test\widget_test.dart" "Widget Tests") {
        $passedTests++
    } else {
        $failedTests++
    }
}
Write-Host ""

# 2. Integration Tests
Write-Host "2. INTEGRATION TESTS" -ForegroundColor Cyan
if (Test-Path "test\integration_test.dart") {
    $totalTests++
    if (Run-Tests "test\integration_test.dart" "Integration Tests") {
        $passedTests++
    } else {
        $failedTests++
    }
}
Write-Host ""

# 3. Provider Tests
Write-Host "3. PROVIDER TESTS" -ForegroundColor Cyan
if (Test-Path "test\providers") {
    Get-ChildItem "test\providers\*_test.dart" | ForEach-Object {
        $totalTests++
        if (Run-Tests $_.FullName "Provider: $($_.Name)") {
            $passedTests++
        } else {
            $failedTests++
        }
    }
}
Write-Host ""

# 4. Screen Tests
Write-Host "4. SCREEN TESTS" -ForegroundColor Cyan
if (Test-Path "test\screens") {
    Get-ChildItem "test\screens\*_test.dart" | ForEach-Object {
        $totalTests++
        if (Run-Tests $_.FullName "Screen: $($_.Name)") {
            $passedTests++
        } else {
            $failedTests++
        }
    }
}
Write-Host ""

# 5. Service Tests
Write-Host "5. SERVICE TESTS" -ForegroundColor Cyan
if (Test-Path "test\services") {
    Get-ChildItem "test\services\*_test.dart" | ForEach-Object {
        $totalTests++
        if (Run-Tests $_.FullName "Service: $($_.Name)") {
            $passedTests++
        } else {
            $failedTests++
        }
    }
}
Write-Host ""

# Summary
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $totalTests" -ForegroundColor White
Write-Host "Passed:       $passedTests" -ForegroundColor Green
Write-Host "Failed:       $failedTests" -ForegroundColor Red
Write-Host ""

if ($failedTests -eq 0) {
    Write-Host "[SUCCESS] ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAILED] SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
