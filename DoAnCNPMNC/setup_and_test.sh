#!/bin/bash

# Food Delivery System - Setup and Test Script
echo "🚀 Food Delivery System - Setup and Test Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."
    
    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION"
    else
        print_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_success "npm found: $NPM_VERSION"
    else
        print_error "npm is not installed. Please install npm first."
        exit 1
    fi
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version | head -n 1)
        print_success "Flutter found: $FLUTTER_VERSION"
    else
        print_warning "Flutter is not installed. Mobile app cannot be tested."
    fi
    
    # Check PostgreSQL
    if command -v psql &> /dev/null; then
        PSQL_VERSION=$(psql --version)
        print_success "PostgreSQL found: $PSQL_VERSION"
    else
        print_warning "PostgreSQL is not installed. Please install PostgreSQL first."
    fi
}

# Setup backend
setup_backend() {
    print_status "Setting up backend..."
    
    cd backend
    
    # Install dependencies
    if [ ! -d "node_modules" ]; then
        print_status "Installing backend dependencies..."
        npm install
        if [ $? -eq 0 ]; then
            print_success "Backend dependencies installed successfully"
        else
            print_error "Failed to install backend dependencies"
            exit 1
        fi
    else
        print_success "Backend dependencies already installed"
    fi
    
    # Check if .env exists
    if [ ! -f ".env" ]; then
        if [ -f "config.env" ]; then
            cp config.env .env
            print_success "Created .env file from config.env"
        else
            print_error "config.env file not found"
            exit 1
        fi
    else
        print_success ".env file already exists"
    fi
    
    cd ..
}

# Setup Flutter app
setup_flutter() {
    if command -v flutter &> /dev/null; then
        print_status "Setting up Flutter app..."
        
        cd app_user
        
        # Get Flutter dependencies
        print_status "Getting Flutter dependencies..."
        flutter pub get
        if [ $? -eq 0 ]; then
            print_success "Flutter dependencies installed successfully"
        else
            print_error "Failed to install Flutter dependencies"
            exit 1
        fi
        
        cd ..
    else
        print_warning "Skipping Flutter setup - Flutter not installed"
    fi
}

# Test backend API
test_backend() {
    print_status "Testing backend API..."
    
    cd backend
    
    # Start backend in background
    print_status "Starting backend server..."
    npm start &
    BACKEND_PID=$!
    
    # Wait for server to start
    sleep 5
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -s http://localhost:3000/api/health > /dev/null; then
        print_success "Backend API is running and healthy"
    else
        print_error "Backend API health check failed"
        kill $BACKEND_PID 2>/dev/null
        exit 1
    fi
    
    # Test registration endpoint
    print_status "Testing registration endpoint..."
    REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/register \
        -H "Content-Type: application/json" \
        -d '{"email":"test@example.com","password":"123456","full_name":"Test User"}')
    
    if echo "$REGISTER_RESPONSE" | grep -q "success"; then
        print_success "Registration endpoint working"
    else
        print_warning "Registration endpoint test failed (might be expected if user exists)"
    fi
    
    # Stop backend
    kill $BACKEND_PID 2>/dev/null
    print_success "Backend server stopped"
    
    cd ..
}

# Test Flutter app
test_flutter() {
    if command -v flutter &> /dev/null; then
        print_status "Testing Flutter app..."
        
        cd app_user
        
        # Check Flutter doctor
        print_status "Running Flutter doctor..."
        flutter doctor
        
        # Analyze Flutter code
        print_status "Analyzing Flutter code..."
        flutter analyze
        if [ $? -eq 0 ]; then
            print_success "Flutter code analysis passed"
        else
            print_warning "Flutter code analysis found issues"
        fi
        
        cd ..
    else
        print_warning "Skipping Flutter tests - Flutter not installed"
    fi
}

# Test web admin
test_web_admin() {
    print_status "Testing web admin..."
    
    if [ -f "web_admin/index.html" ]; then
        print_success "Web admin files found"
        print_status "You can open web_admin/index.html in your browser to test"
    else
        print_error "Web admin files not found"
    fi
}

# Main execution
main() {
    echo ""
    print_status "Starting Food Delivery System setup and test..."
    echo ""
    
    check_requirements
    echo ""
    
    setup_backend
    echo ""
    
    setup_flutter
    echo ""
    
    test_backend
    echo ""
    
    test_flutter
    echo ""
    
    test_web_admin
    echo ""
    
    print_success "Setup and testing completed!"
    echo ""
    print_status "Next steps:"
    echo "1. Start PostgreSQL database"
    echo "2. Run 'cd backend && npm start' to start backend"
    echo "3. Open web_admin/index.html in browser for admin panel"
    echo "4. Run 'cd app_user && flutter run' for mobile app"
    echo ""
    print_status "For detailed instructions, see README.md"
}

# Run main function
main
