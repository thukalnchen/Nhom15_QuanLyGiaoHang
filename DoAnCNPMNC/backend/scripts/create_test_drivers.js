const { pool } = require('../config/database');
const bcrypt = require('bcrypt');

async function createTestDrivers() {
  try {
    console.log('🚀 Creating 10 test drivers...');

    // Hash password
    const password = await bcrypt.hash('Driver@123', 10);
    console.log('🔐 Password hashed successfully');

    const drivers = [
      { email: 'driver1@test.com', name: 'Nguyễn Văn An', phone: '0901234567', address: '123 Nguyễn Huệ, Q.1, TP.HCM', vehicle: '59A-12345', vehicleType: 'motorcycle' },
      { email: 'driver2@test.com', name: 'Trần Thị Bình', phone: '0902234567', address: '456 Lê Lợi, Q.1, TP.HCM', vehicle: '59B-23456', vehicleType: 'motorcycle' },
      { email: 'driver3@test.com', name: 'Lê Văn Cường', phone: '0903234567', address: '789 Điện Biên Phủ, Q.3, TP.HCM', vehicle: '51C-34567', vehicleType: 'van_500' },
      { email: 'driver4@test.com', name: 'Phạm Thị Dung', phone: '0904234567', address: '321 Võ Văn Tần, Q.3, TP.HCM', vehicle: '59D-45678', vehicleType: 'motorcycle' },
      { email: 'driver5@test.com', name: 'Hoàng Văn Em', phone: '0905234567', address: '654 Pasteur, Q.1, TP.HCM', vehicle: '51E-56789', vehicleType: 'van_750' },
      { email: 'driver6@test.com', name: 'Võ Thị Phương', phone: '0906234567', address: '987 Cách Mạng Tháng 8, Q.10, TP.HCM', vehicle: '59F-67890', vehicleType: 'motorcycle' },
      { email: 'driver7@test.com', name: 'Đặng Văn Giang', phone: '0907234567', address: '147 Lý Thường Kiệt, Q.10, TP.HCM', vehicle: '51G-78901', vehicleType: 'van_1000' },
      { email: 'driver8@test.com', name: 'Bùi Thị Hoa', phone: '0908234567', address: '258 Nguyễn Thị Minh Khai, Q.1, TP.HCM', vehicle: '59H-89012', vehicleType: 'motorcycle' },
      { email: 'driver9@test.com', name: 'Ngô Văn Inh', phone: '0909234567', address: '369 Hai Bà Trưng, Q.3, TP.HCM', vehicle: '51I-90123', vehicleType: 'van_500' },
      { email: 'driver10@test.com', name: 'Lý Thị Kim', phone: '0910234567', address: '741 Trần Hưng Đạo, Q.5, TP.HCM', vehicle: '59K-01234', vehicleType: 'motorcycle' },
    ];

    let inserted = 0;
    let skipped = 0;

    for (const driver of drivers) {
      try {
        await pool.query(
          `INSERT INTO users (email, password, full_name, phone, address, role, vehicle_registration, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, 'driver', $6, NOW(), NOW())
           ON CONFLICT (email) DO NOTHING`,
          [driver.email, password, driver.name, driver.phone, driver.address, driver.vehicle]
        );
        
        console.log(`✅ Created driver: ${driver.name} (${driver.email})`);
        inserted++;
      } catch (error) {
        if (error.code === '23505') { // Unique violation
          console.log(`⏭️  Skipped (already exists): ${driver.email}`);
          skipped++;
        } else {
          throw error;
        }
      }
    }

    console.log('\n📊 Summary:');
    console.log(`   ✅ Inserted: ${inserted}`);
    console.log(`   ⏭️  Skipped: ${skipped}`);
    console.log(`   📧 Email: driver1@test.com to driver10@test.com`);
    console.log(`   🔑 Password: Driver@123`);
    console.log('\n🎉 Done!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating drivers:', error);
    process.exit(1);
  }
}

createTestDrivers();
