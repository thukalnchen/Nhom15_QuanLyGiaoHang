# Import Zones and Routes Data to PostgreSQL Database
Write-Host "Importing zones and routes data..." -ForegroundColor Cyan

$env:PGPASSWORD = "1234567890kha"
$dbName = "food_delivery_db"
$dbUser = "postgres"
$dbHost = "localhost"
$dbPort = "5432"

$sqlFile = Join-Path $PSScriptRoot "create_zones_routes.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "Error: SQL file not found at $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "Executing SQL script: $sqlFile" -ForegroundColor Yellow

psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f $sqlFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nZones and routes data imported successfully!" -ForegroundColor Green
    Write-Host "`nDefault data created:" -ForegroundColor Cyan
    Write-Host "  - 5 zones (Q1, Q3, Q5, Thu Duc, Binh Thanh)" -ForegroundColor White
    Write-Host "  - 3 sample routes" -ForegroundColor White
} else {
    Write-Host "`nError importing data!" -ForegroundColor Red
    exit 1
}

$env:PGPASSWORD = ""
