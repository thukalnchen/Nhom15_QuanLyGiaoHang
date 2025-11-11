@echo off
REM Run Database Migration for Stories #20-24
REM Script: setup_stories_20_24.bat

echo.
echo ========================================
echo Stories #20-24 Database Setup
echo ========================================
echo.

REM Set PostgreSQL path
set PSQL_PATH=E:\linh Tinh\PostGres\bin\psql.exe
set DB_USER=postgres
set DB_NAME=food_delivery_db
set MIGRATION_FILE=scripts\migrate_stories_20_24.sql

REM Check if psql exists
if not exist "%PSQL_PATH%" (
    echo ERROR: PostgreSQL not found at %PSQL_PATH%
    pause
    exit /b 1
)

echo Checking migration file...
if not exist "%MIGRATION_FILE%" (
    echo ERROR: Migration file not found: %MIGRATION_FILE%
    pause
    exit /b 1
)

echo.
echo Running migration...
echo.

REM Set password
set PGPASSWORD=YOUR_PASSWORD_HERE

REM Run migration
"%PSQL_PATH%" -U %DB_USER% -d %DB_NAME% -f %MIGRATION_FILE%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS: Migration completed!
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Restart backend: npm start
    echo 2. Test APIs with Postman
    echo 3. Read guide: DoAnCNPMNC\STORIES_20_24_GUIDE.md
    echo.
) else (
    echo.
    echo ERROR: Migration failed!
    echo.
)

set PGPASSWORD=

pause
