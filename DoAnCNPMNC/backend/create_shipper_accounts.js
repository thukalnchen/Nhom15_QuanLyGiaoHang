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
      { email: 'shipper1@test.com', name: 'Nguyễn Văn Shipper 1', phone: '0901111111', vehicle_type: 'motorcycle', vehicle_plate: '51A-11111' },
      { email: 'shipper2@test.com', name: 'Trần Thị Shipper 2', phone: '0902222222', vehicle_type: 'motorcycle', vehicle_plate: '51A-22222' },
      { email: 'shipper3@test.com', name: 'Lê Văn Shipper 3', phone: '0903333333', vehicle_type: 'van_500', vehicle_plate: '51A-33333' },
      { email: 'shipper.test@intake.com', name: 'Shipper Test Intake', phone: '0909999999', vehicle_type: 'motorcycle', vehicle_plate: '51A-99999' },
    ];

    for (const shipper of shippers) {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        
        // Insert or update user with approved status
        const result = await client.query(
          `INSERT INTO users (email, password, full_name, phone, role, status, created_at, updated_at)
           VALUES ($1, $2, $3, $4, 'shipper', 'approved', NOW(), NOW())
           ON CONFLICT (email) 
           DO UPDATE SET 
             role = 'shipper',
             full_name = EXCLUDED.full_name,
             phone = EXCLUDED.phone,
             password = EXCLUDED.password,
             status = 'approved',
             updated_at = NOW()
           RETURNING id, email, full_name, role, status`,
          [shipper.email, hashedPassword, shipper.name, shipper.phone]
        );
        
        const userId = result.rows[0].id;
        
        // Create or update shipper profile
        await client.query(
          `INSERT INTO shipper_profiles (user_id, vehicle_type, vehicle_plate, approved_at, created_at, updated_at)
           VALUES ($1, $2, $3, NOW(), NOW(), NOW())
           ON CONFLICT (user_id)
           DO UPDATE SET
             vehicle_type = EXCLUDED.vehicle_type,
             vehicle_plate = EXCLUDED.vehicle_plate,
             approved_at = NOW(),
             updated_at = NOW()`,
          [userId, shipper.vehicle_type || 'motorcycle', shipper.vehicle_plate || `PLATE-${userId}`]
        );
        
        await client.query('COMMIT');
        console.log('✅ Created/Updated:', result.rows[0]);
      } catch (error) {
        await client.query('ROLLBACK');
        console.error(`❌ Error creating shipper ${shipper.email}:`, error.message);
      } finally {
        client.release();
      }
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
