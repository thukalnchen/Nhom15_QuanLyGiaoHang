-- Create Admin User for Lalamove
-- Password: Admin@123 (bcrypt hashed)

INSERT INTO users (email, password, phone, name, role, created_at, status) 
VALUES (
  'admin@lalamove.com', 
  '$2b$10$YourBcryptHashedPasswordHere', 
  '0987654321', 
  'Admin Lalamove', 
  'admin', 
  NOW(), 
  'active'
) ON CONFLICT (email) DO UPDATE SET role = 'admin';

-- Verify
SELECT id, email, name, role, status, created_at FROM users WHERE email = 'admin@lalamove.com';
