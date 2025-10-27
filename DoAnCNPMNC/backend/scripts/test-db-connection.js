/* Quick DB connection test */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', 'config.env') });
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

(async () => {
  try {
    const pwd = process.env.DB_PASSWORD;
    console.log('PWD typeof:', typeof pwd, 'len:', pwd ? pwd.length : 0);
    const client = await pool.connect();
    const r = await client.query('SELECT version(), current_database(), current_user');
    console.log('✅ Connected.');
    console.log('DB:', r.rows[0].current_database, 'User:', r.rows[0].current_user);
    client.release();
    await pool.end();
    process.exit(0);
  } catch (e) {
    console.error('❌ Connection failed:', e.code, e.message);
    await pool.end();
    process.exit(1);
  }
})();
