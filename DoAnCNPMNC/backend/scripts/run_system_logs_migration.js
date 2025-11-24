require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  try {
    console.log('🔄 Running system_logs table migration...');
    
    // Read SQL file
    const sqlPath = path.join(__dirname, 'create_system_logs_table.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Execute SQL
    await pool.query(sql);
    
    console.log('✅ System logs table created successfully!');
    console.log('📋 Table: system_logs');
    console.log('📋 Columns: id, user_id, action, target_type, target_id, ip_address, user_agent, details, created_at');
    
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    await pool.end();
    process.exit(1);
  }
}

runMigration();

