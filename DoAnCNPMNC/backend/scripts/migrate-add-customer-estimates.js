const { Pool } = require('pg');
require('dotenv').config({ path: './config.env' });

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

async function runMigration() {
  console.log('Starting migration: Add customer estimate fields...\n');

  try {
    // Add customer_estimated_size column
    console.log('⏳ Adding customer_estimated_size column...');
    await pool.query(`
      ALTER TABLE orders 
      ADD COLUMN IF NOT EXISTS customer_estimated_size VARCHAR(20)
    `);
    console.log('✅ customer_estimated_size column added\n');

    // Add customer_requested_vehicle column
    console.log('⏳ Adding customer_requested_vehicle column...');
    await pool.query(`
      ALTER TABLE orders 
      ADD COLUMN IF NOT EXISTS customer_requested_vehicle VARCHAR(20)
    `);
    console.log('✅ customer_requested_vehicle column added\n');

    // Verify columns exist
    const result = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'orders' 
      AND column_name IN ('customer_estimated_size', 'customer_requested_vehicle')
      ORDER BY column_name
    `);

    console.log('📋 Verification - Columns in orders table:');
    result.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type}`);
    });

    console.log('\n✅ Migration completed successfully!');
    console.log('Total columns added: 2');
    console.log('  - customer_estimated_size (VARCHAR 20)');
    console.log('  - customer_requested_vehicle (VARCHAR 20)');

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigration();
