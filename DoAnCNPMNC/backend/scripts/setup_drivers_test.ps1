# ========================================
# SCRIPT SETUP DRIVERS TEST CHO APP INTAKE
# ========================================
# Chạy script SQL để tạo 15 tài xế test với đầy đủ vehicle_type

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP DRIVERS TEST CHO APP INTAKE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Database connection info
$DB_NAME = "food_delivery_db"
$DB_USER = "postgres"
$DB_PASSWORD = "your_password"  # Thay bằng password của bạn
$DB_HOST = "localhost"
$DB_PORT = "5432"

# Đường dẫn file SQL
$SQL_FILE = Join-Path $PSScriptRoot "create_test_drivers_for_intake.sql"

# Kiểm tra file SQL có tồn tại không
if (-not (Test-Path $SQL_FILE)) {
    Write-Host "ERROR: Không tìm thấy file SQL: $SQL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "1. Dang ket noi database: $DB_NAME..." -ForegroundColor Yellow

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $DB_PASSWORD

try {
    Write-Host "2. Dang chay script SQL..." -ForegroundColor Yellow
    
    # Run SQL script using psql
    $psqlCommand = "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f `"$SQL_FILE`""
    
    $result = Invoke-Expression $psqlCommand 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Success! Da tao 15 tai xe test" -ForegroundColor Green
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  THÔNG TIN ĐĂNG NHẬP" -ForegroundColor Cyan
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
        Write-Host "  PHAN BO LOAI XE" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Xe may (bike):     " -NoNewline -ForegroundColor Green
        Write-Host "8 tai xe (driver1-8)" -ForegroundColor White
        Write-Host "Van 500kg:          " -NoNewline -ForegroundColor Blue
        Write-Host "3 tai xe (driver9-11)" -ForegroundColor White
        Write-Host "Van 750kg:          " -NoNewline -ForegroundColor Magenta
        Write-Host "2 tai xe (driver12-13)" -ForegroundColor White
        Write-Host "Van 1000kg:         " -NoNewline -ForegroundColor Red
        Write-Host "2 tai xe (driver14-15)" -ForegroundColor White
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  HUONG DAN TEST" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Mo app intake (lalamove_app)" -ForegroundColor White
        Write-Host "2. Login voi tai khoan intake staff" -ForegroundColor White
        Write-Host "3. Vao man hinh Phan tai xe" -ForegroundColor White
        Write-Host "4. Chon don hang can phan tai xe" -ForegroundColor White
        Write-Host "5. Xem danh sach tai xe duoc loc theo vehicle_type" -ForegroundColor White
        Write-Host "6. Chon tai xe va xac nhan phan" -ForegroundColor White
        Write-Host ""
        
        # Display result
        Write-Host $result -ForegroundColor Gray
        
    } else {
        Write-Host ""
        Write-Host "ERROR: Loi khi chay SQL script!" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clear password from environment
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Hoan tat!" -ForegroundColor Green
Write-Host ""

# Pause de xem ket qua
Read-Host "Nhan Enter de thoat"
