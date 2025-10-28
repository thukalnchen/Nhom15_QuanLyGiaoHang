@echo off
REM Food Delivery System - Setup and Test Script for Windows
echo 🚀 Food Delivery System - Setup and Test Script
echo ==============================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed. Please install Node.js first.
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo [SUCCESS] Node.js found: %NODE_VERSION%
)

REM Check if npm is installed
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] npm is not installed. Please install npm first.
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
    echo [SUCCESS] npm found: %NPM_VERSION%
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Flutter is not installed. Mobile app cannot be tested.
) else (
    echo [SUCCESS] Flutter found
)

echo.
echo [INFO] Setting up backend...

cd backend

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo [INFO] Installing backend dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install backend dependencies
        pause
        exit /b 1
    ) else (
        echo [SUCCESS] Backend dependencies installed successfully
    )
) else (
    echo [SUCCESS] Backend dependencies already installed
)

REM Create .env file if it doesn't exist
if not exist ".env" (
    if exist "config.env" (
        copy config.env .env >nul
        echo [SUCCESS] Created .env file from config.env
    ) else (
        echo [ERROR] config.env file not found
        pause
        exit /b 1
    )
) else (
    echo [SUCCESS] .env file already exists
)

cd ..

echo.
echo [INFO] Setting up Flutter app...

REM Check if Flutter is available
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    cd app_user
    
    echo [INFO] Getting Flutter dependencies...
    flutter pub get
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install Flutter dependencies
        pause
        exit /b 1
    ) else (
        echo [SUCCESS] Flutter dependencies installed successfully
    )
    
    cd ..
) else (
    echo [WARNING] Skipping Flutter setup - Flutter not installed
)

echo.
echo [SUCCESS] Setup completed!
echo.
echo [INFO] Next steps:
echo 1. Start PostgreSQL database
echo 2. Run 'cd backend ^&^& npm start' to start backend
echo 3. Open web_admin/index.html in browser for admin panel
echo 4. Run 'cd app_user ^&^& flutter run' for mobile app
echo.
echo [INFO] For detailed instructions, see README.md
echo.
pause
