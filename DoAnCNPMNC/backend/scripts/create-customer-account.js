const bcrypt = require('bcryptjs');
const { pool } = require('../config/database');

async function createCustomerAccount() {
  try {
    console.log('Creating customer account...');
    
    // Hash password
    const hashedPassword = await bcrypt.hash('test123', 12);
    
    // Check if user exists
    const existing = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      ['customer@test.com']
    );
    
    if (existing.rows.length > 0) {
      console.log('✅ Customer account already exists!');
      console.log('   Email: customer@test.com');
      console.log('   Password: test123');
      console.log('   User ID:', existing.rows[0].id);
      return;
    }
    
    // Create user
    const result = await pool.query(
      `INSERT INTO users (email, password, full_name, phone, address, role)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, email, full_name, role`,
      [
        'customer@test.com',
        hashedPassword,
        'Test Customer',
        '0909123456',
        '123 Test Street, Ho Chi Minh City',
        'customer'
      ]
    );
    
    const user = result.rows[0];
    console.log('✅ Customer account created successfully!');
    console.log('   User ID:', user.id);
    console.log('   Email:', user.email);
    console.log('   Name:', user.full_name);
    console.log('   Role:', user.role);
    console.log('\n📝 Login credentials:');
    console.log('   Email: customer@test.com');
    console.log('   Password: test123');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit();
  }
}

createCustomerAccount();
