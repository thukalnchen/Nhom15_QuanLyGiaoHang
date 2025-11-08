const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: './config.env' });

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

async function createIntakeStaff() {
  console.log('\n👤 Creating Intake Staff Account...\n');

  try {
    // Hash password
    const password = 'staff123'; // Default password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Check if intake staff already exists
    const checkQuery = `
      SELECT * FROM users 
      WHERE email = 'staff@intake.com' OR role = 'intake_staff'
    `;
    const checkResult = await pool.query(checkQuery);

    if (checkResult.rows.length > 0) {
      console.log('⚠️  Intake staff account already exists:');
      const existingUser = checkResult.rows[0];
      console.log(`   Email: ${existingUser.email}`);
      console.log(`   Name: ${existingUser.full_name}`);
      console.log(`   Role: ${existingUser.role}`);
      console.log(`   Password: staff123 (default)\n`);
      await pool.end();
      return;
    }

    // Create intake staff account
    const insertQuery = `
      INSERT INTO users (
        email,
        password,
        full_name,
        phone,
        role,
        created_at
      ) VALUES (
        $1, $2, $3, $4, $5, NOW()
      ) RETURNING id, email, full_name, phone, role
    `;

    const values = [
      'staff@intake.com',
      hashedPassword,
      'Nhân Viên Kho',
      '0909123456',
      'intake_staff'
    ];

    const result = await pool.query(insertQuery, values);
    const user = result.rows[0];

    console.log('✅ Intake Staff Account Created Successfully!\n');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📧 Email:    staff@intake.com');
    console.log('🔑 Password: staff123');
    console.log('👤 Name:     Nhân Viên Kho');
    console.log('📱 Phone:    0909123456');
    console.log('🎭 Role:     intake_staff');
    console.log(`🆔 User ID:  ${user.id}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('💡 Use these credentials to login to app_intake:\n');
    console.log('   1. Open app_intake');
    console.log('   2. Login with:');
    console.log('      - Email: staff@intake.com');
    console.log('      - Password: staff123');
    console.log('   3. Start scanning orders!\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await pool.end();
  }
}

createIntakeStaff();
