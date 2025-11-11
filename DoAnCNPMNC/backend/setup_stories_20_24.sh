#!/bin/bash

# Run Database Migration for Stories #20-24
# Script: setup_stories_20_24.sh

echo ""
echo "========================================"
echo "Stories #20-24 Database Setup"
echo "========================================"
echo ""

# Configuration
DB_USER="postgres"
DB_NAME="food_delivery_db"
MIGRATION_FILE="scripts/migrate_stories_20_24.sql"

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "ERROR: Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "Checking database connection..."
echo ""

# Run migration
psql -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "SUCCESS: Migration completed!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Restart backend: npm start"
    echo "2. Test APIs with Postman"
    echo "3. Read guide: DoAnCNPMNC/STORIES_20_24_GUIDE.md"
    echo ""
else
    echo ""
    echo "ERROR: Migration failed!"
    echo ""
    exit 1
fi
