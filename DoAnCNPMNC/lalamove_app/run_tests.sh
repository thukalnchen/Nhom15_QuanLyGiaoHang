#!/bin/bash

# Comprehensive Test Runner for Lalamove App
# Tests all major flows and features

echo "🧪 =================================="
echo "   LALAMOVE APP - TEST SUITE"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to app directory
cd "$(dirname "$0")"

echo "📂 Current directory: $(pwd)"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -n 1)${NC}"
echo ""

# Function to run tests
run_tests() {
    local test_file=$1
    local test_name=$2
    
    echo -e "${YELLOW}🧪 Running: $test_name${NC}"
    flutter test "$test_file" --reporter expanded
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name FAILED${NC}"
        return 1
    fi
}

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0

echo "=================================="
echo "📋 TEST CATEGORIES"
echo "=================================="
echo ""

# 1. Unit Tests
echo "1️⃣  UNIT TESTS"
if [ -f "test/widget_test.dart" ]; then
    run_tests "test/widget_test.dart" "Widget Tests"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
fi
echo ""

# 2. Integration Tests
echo "2️⃣  INTEGRATION TESTS"
if [ -f "test/integration_test.dart" ]; then
    run_tests "test/integration_test.dart" "Integration Tests"
    total_tests=$((total_tests + 1))
    [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
fi
echo ""

# 3. Provider Tests
echo "3️⃣  PROVIDER TESTS"
if [ -d "test/providers" ]; then
    for file in test/providers/*_test.dart; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            run_tests "$file" "Provider: $filename"
            total_tests=$((total_tests + 1))
            [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
        fi
    done
fi
echo ""

# 4. Screen Tests
echo "4️⃣  SCREEN TESTS"
if [ -d "test/screens" ]; then
    for file in test/screens/*_test.dart; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            run_tests "$file" "Screen: $filename"
            total_tests=$((total_tests + 1))
            [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
        fi
    done
fi
echo ""

# 5. Service Tests
echo "5️⃣  SERVICE TESTS"
if [ -d "test/services" ]; then
    for file in test/services/*_test.dart; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            run_tests "$file" "Service: $filename"
            total_tests=$((total_tests + 1))
            [ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
        fi
    done
fi
echo ""

# Summary
echo "=================================="
echo "📊 TEST SUMMARY"
echo "=================================="
echo -e "Total Tests:  $total_tests"
echo -e "${GREEN}Passed:       $passed_tests${NC}"
echo -e "${RED}Failed:       $failed_tests${NC}"
echo ""

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    exit 1
fi
