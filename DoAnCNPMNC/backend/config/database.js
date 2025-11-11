const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'food_delivery_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test database connection
const connectDB = async () => {
  try {
    const client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database');
    client.release();
    
    // Create tables if they don't exist
    await createTables();
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    throw error;
  }
};

// Create database tables
const createTables = async () => {
  try {
    // Users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        address TEXT,
        role VARCHAR(20) DEFAULT 'customer',
        status VARCHAR(20) DEFAULT 'active',
        fcm_token TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Shipper profiles table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS shipper_profiles (
        id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        vehicle_type VARCHAR(50),
        vehicle_plate VARCHAR(20),
        driver_license_number VARCHAR(50),
        identity_card_number VARCHAR(50),
        notes TEXT,
        approved_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Orders table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        order_number VARCHAR(50) UNIQUE NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        shipper_id INTEGER REFERENCES users(id),
        restaurant_name VARCHAR(255),
        items JSONB,
        total_amount DECIMAL(10,2) NOT NULL,
        delivery_fee DECIMAL(10,2) DEFAULT 0,
        status VARCHAR(50) DEFAULT 'pending',
        delivery_address TEXT NOT NULL,
        delivery_lat DECIMAL(10,7),
        delivery_lng DECIMAL(10,7),
        delivery_phone VARCHAR(20),
        pickup_address TEXT,
        pickup_lat DECIMAL(10,7),
        pickup_lng DECIMAL(10,7),
        recipient_name VARCHAR(255),
        recipient_phone VARCHAR(20),
        distance DECIMAL(10,2),
        duration VARCHAR(50),
        services JSONB DEFAULT '[]'::jsonb,
        base_fare DECIMAL(10,2),
        service_fee DECIMAL(10,2) DEFAULT 0,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Add cancellation columns if they don't exist
    await pool.query(`
      DO $$ 
      BEGIN
        BEGIN
          ALTER TABLE orders ADD COLUMN cancellation_reason TEXT;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN cancellation_type VARCHAR(50);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN cancelled_at TIMESTAMP;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN cancelled_by INTEGER REFERENCES users(id);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN payment_status VARCHAR(50) DEFAULT 'pending';
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN payment_method VARCHAR(50);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN refund_status VARCHAR(50);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN refund_initiated_at TIMESTAMP;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN pickup_address TEXT;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN pickup_lat DECIMAL(10,7);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN pickup_lng DECIMAL(10,7);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN delivery_lat DECIMAL(10,7);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN delivery_lng DECIMAL(10,7);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN shipper_id INTEGER REFERENCES users(id);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN vehicle_type VARCHAR(50);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN recipient_name VARCHAR(255);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN recipient_phone VARCHAR(20);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN distance DECIMAL(10,2);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN duration VARCHAR(50);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN services JSONB DEFAULT '[]'::jsonb;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN base_fare DECIMAL(10,2);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN service_fee DECIMAL(10,2) DEFAULT 0;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        -- Warehouse intake fields
        BEGIN
          ALTER TABLE orders ADD COLUMN package_size VARCHAR(50);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN package_type VARCHAR(50);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN weight DECIMAL(10,2);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN description TEXT;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN images JSONB;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN warehouse_id INTEGER;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN warehouse_name VARCHAR(255);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN intake_staff_id INTEGER REFERENCES users(id);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN intake_staff_name VARCHAR(255);
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE orders ADD COLUMN received_at TIMESTAMP;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
        
        BEGIN
          ALTER TABLE users ADD COLUMN fcm_token TEXT;
        EXCEPTION
          WHEN duplicate_column THEN NULL;
        END;
      END $$;
    `);

    // Relax constraints for delivery service compatibility
    await pool.query(`
      ALTER TABLE orders ALTER COLUMN restaurant_name DROP NOT NULL;
      ALTER TABLE orders ALTER COLUMN items DROP NOT NULL;
    `);

    // Order status history table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS order_status_history (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
        status VARCHAR(50) NOT NULL,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Delivery tracking table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS delivery_tracking (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
        shipper_id INTEGER REFERENCES users(id),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        address TEXT,
        status VARCHAR(50) DEFAULT 'preparing',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create indexes for better performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
      CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
      CREATE INDEX IF NOT EXISTS idx_orders_shipper_id ON orders(shipper_id);
      CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
      CREATE INDEX IF NOT EXISTS idx_delivery_tracking_order_id ON delivery_tracking(order_id);
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
      CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
      CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
    `);

    console.log('✅ Database tables created successfully');
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
    throw error;
  }
};

module.exports = {
  pool,
  connectDB,
  createTables
};
