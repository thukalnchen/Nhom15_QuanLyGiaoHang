require('dotenv').config({ path: './config.env' });
const readline = require('readline');
const bcrypt = require('bcryptjs');
const { pool } = require('../config/database');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

async function upsertAdmin(email, password, fullName) {
  const client = await pool.connect();
  try {
    const hashedPassword = await bcrypt.hash(password, 12);

    await client.query('BEGIN');

    const existing = await client.query(
      `SELECT id FROM users WHERE email = $1`,
      [email]
    );

    if (existing.rows.length > 0) {
      await client.query(
        `UPDATE users
         SET password = $1,
             full_name = $2,
             role = 'admin',
             status = 'active',
             updated_at = CURRENT_TIMESTAMP
         WHERE email = $3`,
        [hashedPassword, fullName, email]
      );
      console.log(`🔁 Updated existing admin: ${email}`);
    } else {
      await client.query(
        `INSERT INTO users (email, password, full_name, role, status)
         VALUES ($1, $2, $3, 'admin', 'active')`,
        [email, hashedPassword, fullName]
      );
      console.log(`✅ Created new admin account: ${email}`);
    }

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error creating admin:', error.message);
  } finally {
    client.release();
    await pool.end();
    rl.close();
  }
}

async function main() {
  const email = (await ask('Admin email: ')).trim();
  const password = (await ask('Admin password: ')).trim();
  const fullNameInput = await ask('Full name (optional, default "Administrator"): ');
  const fullName = fullNameInput.trim() || 'Administrator';

  if (!email || !password) {
    console.error('❌ Email và password là bắt buộc.');
    process.exit(1);
  }

  await upsertAdmin(email, password, fullName);
}

main();


