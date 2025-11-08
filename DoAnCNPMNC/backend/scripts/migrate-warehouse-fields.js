const { Pool } = require('pg');
require('dotenv').config({ path: './config.env' });

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'food_delivery_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
});

async function migrate() {
  try {
    console.log('Starting warehouse fields migration...');
    console.log('=====================================\n');
    
    // Add new columns to orders table
    const queries = [
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS warehouse_id VARCHAR(50)`,
        desc: 'Adding warehouse_id column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS warehouse_name VARCHAR(255)`,
        desc: 'Adding warehouse_name column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS intake_staff_id VARCHAR(50)`,
        desc: 'Adding intake_staff_id column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS intake_staff_name VARCHAR(255)`,
        desc: 'Adding intake_staff_name column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS received_at TIMESTAMP`,
        desc: 'Adding received_at column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS classified_at TIMESTAMP`,
        desc: 'Adding classified_at column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS zone VARCHAR(20)`,
        desc: 'Adding zone column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS recommended_vehicle VARCHAR(20)`,
        desc: 'Adding recommended_vehicle column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS cod_payment_type VARCHAR(20)`,
        desc: 'Adding cod_payment_type column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS cod_collected_at_warehouse BOOLEAN DEFAULT FALSE`,
        desc: 'Adding cod_collected_at_warehouse column'
      },
      {
        sql: `ALTER TABLE orders ADD COLUMN IF NOT EXISTS cod_collected_at TIMESTAMP`,
        desc: 'Adding cod_collected_at column'
      },
    ];
    
    for (const query of queries) {
      console.log(`⏳ ${query.desc}...`);
      await pool.query(query.sql);
      console.log(`✅ ${query.desc} - SUCCESS\n`);
    }
    
    console.log('=====================================');
    console.log('✅ Migration completed successfully!');
    console.log('Total columns added: 11');
    console.log('=====================================');
    
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error);
    await pool.end();
    process.exit(1);
  }
}

// Run migration
migrate();
