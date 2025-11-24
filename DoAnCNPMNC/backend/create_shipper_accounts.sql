-- Create test shipper accounts for app_giaohang testing
-- Password: Shipper@123 (hashed with bcryptjs)
-- Hash: $2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6

INSERT INTO users (email, password, full_name, phone, role, created_at, updated_at)
VALUES 
  ('shipper1@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Nguyễn Văn Shipper 1', '0901111111', 'shipper', NOW(), NOW()),
  ('shipper2@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Trần Thị Shipper 2', '0902222222', 'shipper', NOW(), NOW()),
  ('shipper3@test.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Lê Văn Shipper 3', '0903333333', 'shipper', NOW(), NOW()),
  ('shipper.test@intake.com', '$2a$10$HZd7K6fGLZuGkUS7e08zeO7BAQ3dRw.LKTEKZXn1hnKC.xQzOTMj6', 'Shipper Test Intake', '0909999999', 'shipper', NOW(), NOW())
ON CONFLICT (email) DO UPDATE 
SET 
  role = 'shipper',
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  password = EXCLUDED.password,
  updated_at = NOW();

-- Verify created accounts
SELECT 
  id, 
  email, 
  full_name, 
  phone, 
  role,
  created_at
FROM users 
WHERE email IN ('shipper1@test.com', 'shipper2@test.com', 'shipper3@test.com', 'shipper.test@intake.com')
ORDER BY email;
