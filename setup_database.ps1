# 🚀 Quick Setup Script for Database
# Run this script to setup database automatically

Write-Host "🗄️  Lalamove App - Database Setup Script" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Add PostgreSQL to PATH if not already there
$env:PATH += ";E:\linh Tinh\PostGres\bin"

# Configuration
$DB_NAME = "food_delivery_db"
$DB_USER = "postgres"
$BACKUP_FILE = "food_delivery_backup.sql"
$PROJECT_ROOT = $PSScriptRoot

# Check if PostgreSQL is installed
Write-Host "🔍 Checking PostgreSQL installation..." -ForegroundColor Yellow

$psqlPath = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psqlPath) {
    # Try common PostgreSQL installation paths
    $possiblePaths = @(
        ""E:\linh Tinh\PostGres\bin\psql.exe"",
        "C:\Program Files\PostgreSQL\15\bin\psql.exe",
        "C:\Program Files\PostgreSQL\16\bin\psql.exe",
        "C:\Program Files\PostgreSQL\17\bin\psql.exe",
        "C:\Program Files\PostgreSQL\18\bin\psql.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $psqlPath = $path
            break
        }
    }
    
    if (-not $psqlPath) {
        Write-Host "❌ PostgreSQL not found!" -ForegroundColor Red
        Write-Host "Please install PostgreSQL from: https://www.postgresql.org/download/" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ PostgreSQL found: $psqlPath" -ForegroundColor Green
Write-Host ""

# Get password
Write-Host "🔑 Enter PostgreSQL password for user 'postgres':" -ForegroundColor Yellow
$password = Read-Host -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$DB_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Set environment variable for password
$env:PGPASSWORD = $DB_PASSWORD

Write-Host ""
Write-Host "📋 Setup Options:" -ForegroundColor Cyan
Write-Host "1. Import from backup file (Recommended - Fast & Complete)" -ForegroundColor White
Write-Host "2. Create database and let backend initialize (Requires manual migration)" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Choose option (1 or 2)"

if ($choice -eq "1") {
    # Option 1: Import from backup
    Write-Host ""
    Write-Host "📦 Checking backup file..." -ForegroundColor Yellow
    
    $backupPath = Join-Path $PROJECT_ROOT $BACKUP_FILE
    if (-not (Test-Path $backupPath)) {
        Write-Host "❌ Backup file not found: $backupPath" -ForegroundColor Red
        Write-Host "Please ensure 'food_delivery_backup.sql' exists in project root" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Backup file found" -ForegroundColor Green
    Write-Host ""
    
    # Check if database exists
    Write-Host "🔍 Checking if database exists..." -ForegroundColor Yellow
    $dbExists = & $psqlPath -U $DB_USER -lqt | Select-String -Pattern $DB_NAME
    
    if ($dbExists) {
        Write-Host "⚠️  Database '$DB_NAME' already exists!" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to drop and recreate it? (yes/no)"
        
        if ($overwrite -eq "yes") {
            Write-Host "🗑️  Dropping existing database..." -ForegroundColor Yellow
            & $psqlPath -U $DB_USER -c "DROP DATABASE $DB_NAME;"
            Write-Host "✅ Database dropped" -ForegroundColor Green
        } else {
            Write-Host "❌ Setup cancelled" -ForegroundColor Red
            exit 0
        }
    }
    
    # Create database
    Write-Host "📝 Creating database '$DB_NAME'..." -ForegroundColor Yellow
    & $psqlPath -U $DB_USER -c "CREATE DATABASE $DB_NAME;"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database created successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create database" -ForegroundColor Red
        exit 1
    }
    
    # Import backup
    Write-Host "📥 Importing backup file..." -ForegroundColor Yellow
    Write-Host "This may take 1-2 minutes..." -ForegroundColor Gray
    
    & $psqlPath -U $DB_USER -d $DB_NAME -f $backupPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Backup imported successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to import backup" -ForegroundColor Red
        exit 1
    }
    
} elseif ($choice -eq "2") {
    # Option 2: Create empty database
    Write-Host ""
    Write-Host "📝 Creating empty database..." -ForegroundColor Yellow
    
    # Check if database exists
    $dbExists = & $psqlPath -U $DB_USER -lqt | Select-String -Pattern $DB_NAME
    
    if (-not $dbExists) {
        & $psqlPath -U $DB_USER -c "CREATE DATABASE $DB_NAME;"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Database created" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create database" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✅ Database already exists" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "⚠️  Important Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Start the backend server (it will create basic tables)" -ForegroundColor White
    Write-Host "   cd DoAnCNPMNC\backend" -ForegroundColor Gray
    Write-Host "   npm start" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Run migration scripts for additional tables:" -ForegroundColor White
    Write-Host "   psql -U postgres -d food_delivery_db -f DoAnCNPMNC\backend\scripts\migrate_notifications.sql" -ForegroundColor Gray
    Write-Host "   psql -U postgres -d food_delivery_db -f DoAnCNPMNC\backend\scripts\migrate_complaints.sql" -ForegroundColor Gray
    
} else {
    Write-Host "❌ Invalid choice" -ForegroundColor Red
    exit 1
}

# Verify tables
Write-Host ""
Write-Host "🔍 Verifying database setup..." -ForegroundColor Yellow

$tableCount = & $psqlPath -U $DB_USER -d $DB_NAME -c "\dt" | Select-String -Pattern "public |" | Measure-Object -Line

Write-Host "✅ Setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Database Information:" -ForegroundColor Cyan
Write-Host "  Database: $DB_NAME" -ForegroundColor White
Write-Host "  User: $DB_USER" -ForegroundColor White
Write-Host "  Tables: $($tableCount.Lines)" -ForegroundColor White
Write-Host ""

# Update backend config
Write-Host "🔧 Updating backend configuration..." -ForegroundColor Yellow
$configPath = Join-Path $PROJECT_ROOT "DoAnCNPMNC\backend\config.env"

if (Test-Path $configPath) {
    $configContent = Get-Content $configPath -Raw
    $configContent = $configContent -replace 'DB_PASSWORD=.*', "DB_PASSWORD=`"$DB_PASSWORD`""
    Set-Content -Path $configPath -Value $configContent
    Write-Host "✅ Backend config updated" -ForegroundColor Green
} else {
    Write-Host "⚠️  Backend config file not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Database setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📖 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Start backend server:" -ForegroundColor White
Write-Host "   cd DoAnCNPMNC\backend" -ForegroundColor Gray
Write-Host "   npm install" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Start Flutter app:" -ForegroundColor White
Write-Host "   cd DoAnCNPMNC\lalamove_app" -ForegroundColor Gray
Write-Host "   flutter pub get" -ForegroundColor Gray
Write-Host "   flutter run -d chrome" -ForegroundColor Gray
Write-Host ""

# Clean up
$env:PGPASSWORD = $null

Read-Host "Press Enter to exit"
