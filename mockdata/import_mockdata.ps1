# ========================================
# IMPORT ALL MOCK DATA
# PowerShell Version for Windows
# ========================================

param(
    [string]$DBUser = "postgres",
    [string]$DBName = "food_delivery_db",
    [string]$DBHost = "localhost",
    [string]$DBPort = "5432",
    [string]$DBPassword = ""
)

# Colors for output (Windows 10+ support)
$Global:COLOR_GREEN = "`e[32m"
$Global:COLOR_RED = "`e[31m"
$Global:COLOR_YELLOW = "`e[33m"
$Global:COLOR_RESET = "`e[0m"

function Write-Success {
    param([string]$Message)
    Write-Host "$COLOR_GREEN[✓] $Message$COLOR_RESET"
}

function Write-Error {
    param([string]$Message)
    Write-Host "$COLOR_RED[✗] $Message$COLOR_RESET"
}

function Write-Info {
    param([string]$Message)
    Write-Host "$COLOR_YELLOW[i] $Message$COLOR_RESET"
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "$COLOR_YELLOW========================================$COLOR_RESET"
    Write-Host "$COLOR_YELLOW$Message$COLOR_RESET"
    Write-Host "$COLOR_YELLOW========================================$COLOR_RESET"
    Write-Host ""
}

# Set password environment variable
if ($DBPassword) {
    $env:PGPASSWORD = $DBPassword
} else {
    Write-Info "No password provided. Make sure PostgreSQL is set up without password or use -DBPassword parameter"
}

# Files to import in order
$Files = @(
    "mockdata/01_users.sql",
    "mockdata/02_orders.sql",
    "mockdata/03_notifications.sql",
    "mockdata/04_complaints.sql",
    "mockdata/05_complaint_responses.sql",
    "mockdata/06_order_status_history.sql",
    "mockdata/07_payments.sql",
    "mockdata/08_ratings_reviews.sql",
    "mockdata/09_promotions_vouchers.sql"
)

# Track results
$Success = 0
$Failed = 0
$Total = $Files.Count

# Display header and database info
Write-Header "📊 IMPORT MOCK DATA - PostgreSQL"

Write-Info "Database Configuration:"
Write-Host "  Host: $DBHost"
Write-Host "  Port: $DBPort"
Write-Host "  Database: $DBName"
Write-Host "  User: $DBUser"
Write-Host ""

# Import each file
$Current = 0
foreach ($File in $Files) {
    $Current++
    
    # Check if file exists
    if (-not (Test-Path $File)) {
        Write-Error "[$Current/$Total] File not found: $File"
        $Failed++
        continue
    }
    
    Write-Info "[$Current/$Total] Importing $File..."
    
    # Run psql command
    $Arguments = @(
        "-h", $DBHost,
        "-p", $DBPort,
        "-U", $DBUser,
        "-d", $DBName,
        "-f", $File
    )
    
    try {
        $Output = psql.exe $Arguments 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "[$Current/$Total] Successfully imported $File"
            $Success++
        } else {
            Write-Error "[$Current/$Total] Error importing $File"
            Write-Host $Output -ForegroundColor Red
            $Failed++
        }
    } catch {
        Write-Error "[$Current/$Total] Exception: $($_.Exception.Message)"
        $Failed++
    }
}

# Summary
Write-Header "📊 IMPORT SUMMARY"

Write-Success "Successful: $Success/$Total"
if ($Failed -gt 0) {
    Write-Error "Failed: $Failed/$Total"
}

Write-Host ""

# Show statistics
if ($Failed -eq 0) {
    Write-Success "All mock data imported successfully! 🎉"
    Write-Host ""
    Write-Info "Total records imported:"
    Write-Host ""
    
    $QueryResult = psql.exe -h $DBHost -p $DBPort -U $DBUser -d $DBName -c @"
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL
SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL
SELECT 'complaint_responses', COUNT(*) FROM complaint_responses
UNION ALL
SELECT 'order_status_history', COUNT(*) FROM order_status_history
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'ratings_reviews', COUNT(*) FROM ratings_reviews
UNION ALL
SELECT 'promotions_vouchers', COUNT(*) FROM promotions_vouchers
ORDER BY table_name;
"@
    
    $QueryResult | ForEach-Object { Write-Host $_ }
} else {
    Write-Error "Some files failed to import. Please check the errors above."
    exit 1
}

# Clean up
if ($env:PGPASSWORD) {
    Remove-Item env:PGPASSWORD
}

Write-Host ""
Write-Success "Import process completed!"
