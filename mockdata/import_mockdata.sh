#!/bin/bash

# ========================================
# IMPORT ALL MOCK DATA
# Linux/Mac Version
# ========================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database settings
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-food_delivery_db}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}📊 IMPORT MOCK DATA - PostgreSQL${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Array of SQL files in order
FILES=(
    "mockdata/01_users.sql"
    "mockdata/02_orders.sql"
    "mockdata/03_notifications.sql"
    "mockdata/04_complaints.sql"
    "mockdata/05_complaint_responses.sql"
    "mockdata/06_order_status_history.sql"
    "mockdata/07_payments.sql"
    "mockdata/08_ratings_reviews.sql"
    "mockdata/09_promotions_vouchers.sql"
)

# Count total files
TOTAL_FILES=${#FILES[@]}
CURRENT=0
SUCCESS=0
FAILED=0

echo -e "${YELLOW}Database Info:${NC}"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Import each file
for file in "${FILES[@]}"; do
    CURRENT=$((CURRENT + 1))
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}[${CURRENT}/${TOTAL_FILES}] ❌ File not found: $file${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    echo -e "${YELLOW}[${CURRENT}/${TOTAL_FILES}] Importing $file...${NC}"
    
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}[${CURRENT}/${TOTAL_FILES}] ✅ Successfully imported $file${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}[${CURRENT}/${TOTAL_FILES}] ❌ Error importing $file${NC}"
        # Try again with error output
        echo -e "${RED}Details:${NC}"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$file"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# Summary
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}📊 IMPORT SUMMARY${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}✅ Success: $SUCCESS/${TOTAL_FILES}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Failed: $FAILED/${TOTAL_FILES}${NC}"
fi
echo ""

# Show stats
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All mock data imported successfully! 🎉${NC}"
    echo ""
    echo "Total records imported:"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME << EOF
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
EOF
else
    echo -e "${RED}Some files failed to import. Please check the errors above.${NC}"
    exit 1
fi
