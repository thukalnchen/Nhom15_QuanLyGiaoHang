# Import Pricing Data to PostgreSQL Database
# Run this script from the backend directory

Write-Host "Importing pricing data..." -ForegroundColor Cyan

# Set PostgreSQL connection details
$env:PGPASSWORD = "1234567890kha"
$dbName = "food_delivery_db"
$dbUser = "postgres"
$dbHost = "localhost"
$dbPort = "5432"

# Path to SQL file
$sqlFile = Join-Path $PSScriptRoot "create_pricing_tables.sql"

# Check if SQL file exists
if (-not (Test-Path $sqlFile)) {
    Write-Host "Error: SQL file not found at $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "Executing SQL script: $sqlFile" -ForegroundColor Yellow

# Execute SQL file
psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f $sqlFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nPricing data imported successfully!" -ForegroundColor Green
    Write-Host "`nDefault data created:" -ForegroundColor Cyan
    Write-Host "  - 5 vehicle types (bike, motorcycle, car, van, truck)" -ForegroundColor White
    Write-Host "  - 5 surcharge policies (giờ cao điểm, đêm, ngày lễ, xăng dầu, vượt quá 10km)" -ForegroundColor White
    Write-Host "  - 4 discount codes (NEWUSER, SAVE10K, FREESHIP, VIP20)" -ForegroundColor White
} else {
    Write-Host "`nError importing pricing data!" -ForegroundColor Red
    exit 1
}

# Clear password
$env:PGPASSWORD = ""
