require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');

async function checkTableStructure() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'orders' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Orders table structure:');
    console.log('='.repeat(80));
    result.rows.forEach(col => {
      const maxLen = col.character_maximum_length ? `(${col.character_maximum_length})` : '';
      const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
      console.log(`- ${col.column_name.padEnd(25)} ${col.data_type}${maxLen.padEnd(10)} ${nullable}`);
    });
    console.log('='.repeat(80));
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    await pool.end();
  }
}

checkTableStructure();
