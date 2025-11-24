# Setup Drivers Test Script
# Simple version without Vietnamese accents

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP DRIVERS TEST FOR APP INTAKE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Database connection info
$DB_NAME = "food_delivery_db"
$DB_USER = "postgres"
$DB_PASSWORD = "Trongkhang205@"
$DB_HOST = "localhost"
$DB_PORT = "5432"

# SQL file path
$SQL_FILE = Join-Path $PSScriptRoot "create_test_drivers_for_intake.sql"

# Check if SQL file exists
if (-not (Test-Path $SQL_FILE)) {
    Write-Host "ERROR: SQL file not found: $SQL_FILE" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "1. Connecting to database: $DB_NAME..." -ForegroundColor Yellow

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $DB_PASSWORD

try {
    Write-Host "2. Running SQL script..." -ForegroundColor Yellow
    
    # Run SQL script using psql
    $psqlCommand = "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f `"$SQL_FILE`""
    
    $result = Invoke-Expression $psqlCommand 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "SUCCESS! Created 15 test drivers" -ForegroundColor Green
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  LOGIN INFO" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Email: " -NoNewline -ForegroundColor Yellow
        Write-Host "driver1@intake.test to driver15@intake.test" -ForegroundColor White
        Write-Host "Password: " -NoNewline -ForegroundColor Yellow
        Write-Host "Driver@123" -ForegroundColor White
        Write-Host "Role: " -NoNewline -ForegroundColor Yellow
        Write-Host "driver" -ForegroundColor White
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  VEHICLE DISTRIBUTION" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Bike (bike):     " -NoNewline -ForegroundColor Green
        Write-Host "8 drivers (driver1-8)" -ForegroundColor White
        Write-Host "Van 500kg:       " -NoNewline -ForegroundColor Blue
        Write-Host "3 drivers (driver9-11)" -ForegroundColor White
        Write-Host "Van 750kg:       " -NoNewline -ForegroundColor Magenta
        Write-Host "2 drivers (driver12-13)" -ForegroundColor White
        Write-Host "Van 1000kg:      " -NoNewline -ForegroundColor Red
        Write-Host "2 drivers (driver14-15)" -ForegroundColor White
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  HOW TO TEST" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Open app intake (lalamove_app)" -ForegroundColor White
        Write-Host "2. Login with intake staff account" -ForegroundColor White
        Write-Host "3. Go to Assignment screen" -ForegroundColor White
        Write-Host "4. Select an order to assign driver" -ForegroundColor White
        Write-Host "5. See drivers filtered by vehicle_type" -ForegroundColor White
        Write-Host "6. Select driver and confirm" -ForegroundColor White
        Write-Host ""
        
        # Display result
        Write-Host $result -ForegroundColor Gray
        
    } else {
        Write-Host ""
        Write-Host "ERROR: Failed to run SQL script!" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
} finally {
    # Clear password from environment
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Completed!" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
