-- Update admin password with bcrypt hash
UPDATE users SET password = '$2a$10$VIC15BH/OqKYM567L79LrucmQ4aB5rQfBaN.eVykxu5NJQIM853Ba' 
WHERE email = 'admin@lalamove.com';

-- Verify
SELECT id, email, role FROM users WHERE email = 'admin@lalamove.com';
