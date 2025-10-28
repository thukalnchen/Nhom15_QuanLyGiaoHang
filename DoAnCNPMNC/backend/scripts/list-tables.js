require('dotenv').config({ path: './config.env' });
const { pool } = require('../config/database');

async function listTables() {
  try {
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('\n📊 Tables in database:');
    console.log('='.repeat(50));
    result.rows.forEach(r => console.log(`- ${r.table_name}`));
    console.log('='.repeat(50));
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    await pool.end();
  }
}

listTables();
