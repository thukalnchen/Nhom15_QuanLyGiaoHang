# Simple Database Setup Script
# Add PostgreSQL to PATH
$env:PATH += ";D:\PostgreSQL\bin"

Write-Host "Database Setup Script" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DB_NAME = "food_delivery_db"
$DB_USER = "postgres"
$BACKUP_FILE = "food_delivery_backup.sql"
$PROJECT_ROOT = $PSScriptRoot
$psqlPath = "D:\PostgreSQL\bin"

Write-Host "Checking psql..." -ForegroundColor Yellow
if (Test-Path $psqlPath) {
    Write-Host "OK - psql found at: $psqlPath" -ForegroundColor Green
} else {
    Write-Host "ERROR - psql not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Enter PostgreSQL password for user 'postgres':" -ForegroundColor Yellow
$password = Read-Host -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$DB_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$env:PGPASSWORD = $DB_PASSWORD

Write-Host ""
Write-Host "Options:" -ForegroundColor Cyan
Write-Host "1. Import from backup file (Recommended)" -ForegroundColor White
Write-Host "2. Create empty database" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Choose option (1 or 2)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Checking backup file..." -ForegroundColor Yellow
    
    $backupPath = Join-Path $PROJECT_ROOT $BACKUP_FILE
    if (-not (Test-Path $backupPath)) {
        Write-Host "ERROR - Backup file not found: $backupPath" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "OK - Backup file found" -ForegroundColor Green
    Write-Host ""
    
    # Check if database exists
    Write-Host "Checking if database exists..." -ForegroundColor Yellow
    $dbList = & $psqlPath -U $DB_USER -lqt 2>$null
    $dbExists = $dbList -contains "*$DB_NAME*"
    
    if ($dbList -match $DB_NAME) {
        Write-Host "Database already exists!" -ForegroundColor Yellow
        $overwrite = Read-Host "Drop and recreate? (yes/no)"
        
        if ($overwrite -eq "yes") {
            Write-Host "Dropping existing database..." -ForegroundColor Yellow
            & $psqlPath -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>$null
            Write-Host "Database dropped" -ForegroundColor Green
        } else {
            Write-Host "Cancelled" -ForegroundColor Red
            exit 0
        }
    }
    
    # Create database
    Write-Host "Creating database '$DB_NAME'..." -ForegroundColor Yellow
    & $psqlPath -U $DB_USER -c "CREATE DATABASE $DB_NAME;" 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database created successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to create database" -ForegroundColor Red
        exit 1
    }
    
    # Import backup
    Write-Host "Importing backup file (this may take 1-2 minutes)..." -ForegroundColor Yellow
    & $psqlPath -U $DB_USER -d $DB_NAME -f $backupPath 2>$null
    
    if ($LASTEXITCODE -eq 0) {Write-Host "Backup imported successfully!" -ForegroundColor Green
    } else {
        Write-Host "Warning: There may have been some errors during import" -ForegroundColor Yellow
    }
    
} elseif ($choice -eq "2") {
    Write-Host ""
    Write-Host "Creating empty database..." -ForegroundColor Yellow
    
    & $psqlPath -U $DB_USER -c "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database created" -ForegroundColor Green
    } else {
        Write-Host "Failed to create database" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Start the backend server (it will create basic tables)" -ForegroundColor White
    Write-Host "2. Run migration scripts if needed" -ForegroundColor White
    
} else {
    Write-Host "Invalid choice" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Verifying database setup..." -ForegroundColor Yellow

$tableCount = & $psqlPath -U $DB_USER -d $DB_NAME -c "\dt" 2>$null | Measure-Object -Line

Write-Host "Setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Database: $DB_NAME" -ForegroundColor White
Write-Host "User: $DB_USER" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Start backend: cd DoAnCNPMNC\backend && npm install && npm start" -ForegroundColor White
Write-Host "2. Start Flutter: cd DoAnCNPMNC\lalamove_app && flutter pub get && flutter run -d chrome" -ForegroundColor White
Write-Host ""

$env:PGPASSWORD = $null

Read-Host "Press Enter to exit"