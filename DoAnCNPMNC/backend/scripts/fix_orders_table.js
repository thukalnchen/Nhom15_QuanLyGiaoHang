// Script to add missing columns to orders table
require('dotenv').config({ path: require('path').join(__dirname, '../config.env') });
const { pool } = require('../config/database');

async function fixOrdersTable() {
  console.log('🔧 Fixing orders table schema...\n');
  
  const columns = [
    { name: 'sender_name', type: 'VARCHAR(255)', default: null },
    { name: 'sender_phone', type: 'VARCHAR(20)', default: null },
    { name: 'receiver_name', type: 'VARCHAR(255)', default: null },
    { name: 'receiver_phone', type: 'VARCHAR(20)', default: null },
    { name: 'pickup_location', type: 'TEXT', default: null },
    { name: 'delivery_location', type: 'TEXT', default: null },
    { name: 'vehicle_type', type: 'VARCHAR(50)', default: null },
    { name: 'payment_method', type: 'VARCHAR(50)', default: "'cod'" },
    { name: 'payment_status', type: 'VARCHAR(50)', default: "'pending'" },
    { name: 'customer_estimated_size', type: 'VARCHAR(50)', default: null },
    { name: 'customer_requested_vehicle', type: 'VARCHAR(50)', default: null },
  ];

  try {
    for (const column of columns) {
      // Check if column exists
      const checkResult = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='orders' AND column_name=$1
      `, [column.name]);

      if (checkResult.rows.length === 0) {
        // Column doesn't exist, add it
        const defaultClause = column.default ? ` DEFAULT ${column.default}` : '';
        const alterQuery = `ALTER TABLE orders ADD COLUMN ${column.name} ${column.type}${defaultClause}`;
        
        await pool.query(alterQuery);
        console.log(`✅ Added column: ${column.name} (${column.type})`);
      } else {
        console.log(`ℹ️  Column already exists: ${column.name}`);
      }
    }

    console.log('\n✅ Orders table schema fixed successfully!');
    console.log('\n📋 Current orders table structure:');
    
    const structureResult = await pool.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'orders'
      ORDER BY ordinal_position
    `);
    
    console.table(structureResult.rows);
    
  } catch (error) {
    console.error('❌ Error fixing orders table:', error.message);
    console.error(error);
  } finally {
    await pool.end();
  }
}

// Run the fix
fixOrdersTable();
