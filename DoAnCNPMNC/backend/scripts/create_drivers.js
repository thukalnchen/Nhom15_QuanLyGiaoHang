const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '../config.env' });

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '1234567890kha',
  database: process.env.DB_NAME || 'food_delivery_db',
});

const drivers = [
  {
    email: 'driver1@lalamove.com',
    password: 'Driver@123',
    full_name: 'Nguyễn Văn An',
    phone: '0901234567',
    address: '123 Nguyễn Huệ, Q1, TP.HCM',
    vehicle_registration: '59A-12345'
  },
  {
    email: 'driver2@lalamove.com',
    password: 'Driver@123',
    full_name: 'Trần Thị Bình',
    phone: '0901234568',
    address: '456 Lê Lợi, Q1, TP.HCM',
    vehicle_registration: '59B-67890'
  },
  {
    email: 'driver3@lalamove.com',
    password: 'Driver@123',
    full_name: 'Lê Văn Cường',
    phone: '0901234569',
    address: '789 Trần Hưng Đạo, Q5, TP.HCM',
    vehicle_registration: '59C-11111'
  },
  {
    email: 'driver4@lalamove.com',
    password: 'Driver@123',
    full_name: 'Phạm Thị Dung',
    phone: '0901234570',
    address: '321 Võ Văn Tần, Q3, TP.HCM',
    vehicle_registration: '59D-22222'
  },
  {
    email: 'driver5@lalamove.com',
    password: 'Driver@123',
    full_name: 'Hoàng Văn Em',
    phone: '0901234571',
    address: '654 Nguyễn Thị Minh Khai, Q3, TP.HCM',
    vehicle_registration: '59E-33333'
  },
  {
    email: 'driver6@lalamove.com',
    password: 'Driver@123',
    full_name: 'Võ Thị Phượng',
    phone: '0901234572',
    address: '987 Cách Mạng Tháng 8, Q10, TP.HCM',
    vehicle_registration: '59F-44444'
  },
  {
    email: 'driver7@lalamove.com',
    password: 'Driver@123',
    full_name: 'Đặng Văn Giang',
    phone: '0901234573',
    address: '147 Lý Thường Kiệt, Q11, TP.HCM',
    vehicle_registration: '59G-55555'
  },
  {
    email: 'driver8@lalamove.com',
    password: 'Driver@123',
    full_name: 'Bùi Thị Hồng',
    phone: '0901234574',
    address: '258 Điện Biên Phủ, Q3, TP.HCM',
    vehicle_registration: '59H-66666'
  },
  {
    email: 'driver9@lalamove.com',
    password: 'Driver@123',
    full_name: 'Ngô Văn Ích',
    phone: '0901234575',
    address: '369 Hai Bà Trưng, Q1, TP.HCM',
    vehicle_registration: '59I-77777'
  },
  {
    email: 'driver10@lalamove.com',
    password: 'Driver@123',
    full_name: 'Cao Thị Kim',
    phone: '0901234576',
    address: '741 Pasteur, Q3, TP.HCM',
    vehicle_registration: '59K-88888'
  }
];

async function createDrivers() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Starting to create 10 drivers...\n');
    
    for (const driver of drivers) {
      // Hash password
      const hashedPassword = await bcrypt.hash(driver.password, 10);
      
      // Check if driver already exists
      const existingUser = await client.query(
        'SELECT id FROM users WHERE email = $1',
        [driver.email]
      );
      
      if (existingUser.rows.length > 0) {
        console.log(`⚠️  Driver ${driver.email} already exists, skipping...`);
        continue;
      }
      
      // Insert driver
      const result = await client.query(
        `INSERT INTO users (email, password, full_name, phone, address, role, vehicle_registration)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, email, full_name`,
        [
          driver.email,
          hashedPassword,
          driver.full_name,
          driver.phone,
          driver.address,
          'driver',
          driver.vehicle_registration
        ]
      );
      
      console.log(`✅ Created driver: ${result.rows[0].full_name} (${result.rows[0].email})`);
    }
    
    console.log('\n🎉 All drivers created successfully!');
    console.log('\n📋 Login credentials:');
    console.log('   Email: driver1@lalamove.com to driver10@lalamove.com');
    console.log('   Password: Driver@123');
    
  } catch (error) {
    console.error('❌ Error creating drivers:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

createDrivers();
