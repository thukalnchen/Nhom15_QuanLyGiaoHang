const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');

async function createShipperAccounts() {
  try {
    const password = 'Shipper@123';
    const hashedPassword = await bcrypt.hash(password, 10);
    
    console.log('Creating shipper test accounts...');
    console.log('Password:', password);
    console.log('Hashed:', hashedPassword);
    console.log('');

    const shippers = [
      { email: 'shipper1@test.com', name: 'Nguyễn Văn Shipper 1', phone: '0901111111' },
      { email: 'shipper2@test.com', name: 'Trần Thị Shipper 2', phone: '0902222222' },
      { email: 'shipper3@test.com', name: 'Lê Văn Shipper 3', phone: '0903333333' },
      { email: 'shipper.test@intake.com', name: 'Shipper Test Intake', phone: '0909999999' },
    ];

    for (const shipper of shippers) {
      const result = await pool.query(
        `INSERT INTO users (email, password, full_name, phone, role, created_at, updated_at)
         VALUES ($1, $2, $3, $4, 'shipper', NOW(), NOW())
         ON CONFLICT (email) 
         DO UPDATE SET 
           role = 'shipper',
           full_name = EXCLUDED.full_name,
           phone = EXCLUDED.phone,
           password = EXCLUDED.password,
           updated_at = NOW()
         RETURNING id, email, full_name, role`,
        [shipper.email, hashedPassword, shipper.name, shipper.phone]
      );
      
      console.log('✅ Created/Updated:', result.rows[0]);
    }

    // Show all shipper accounts
    console.log('\n📋 All shipper accounts:');
    const allShippers = await pool.query(
      `SELECT id, email, full_name, phone, role, created_at 
       FROM users 
       WHERE role = 'shipper' 
       ORDER BY email`
    );
    
    console.table(allShippers.rows);

    console.log('\n🔑 Login credentials:');
    shippers.forEach(s => {
      console.log(`   Email: ${s.email}`);
      console.log(`   Password: ${password}`);
      console.log('');
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit();
  }
}

createShipperAccounts();
