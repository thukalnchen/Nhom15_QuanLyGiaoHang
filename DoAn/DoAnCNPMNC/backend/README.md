# Backend API - Delivery Management System

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file:
```
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=delivery_db
DB_USER=postgres
DB_PASSWORD=postgres
JWT_SECRET=your_secret_key_here_change_in_production
JWT_EXPIRES_IN=7d
```

3. Create database and run schema:
```bash
# Connect to PostgreSQL and run:
# CREATE DATABASE delivery_db;

# Then run the schema file:
psql -U postgres -d delivery_db -f config/db-schema.sql
```

4. Start server:
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user (returns JWT token)

### Orders
- `GET /api/users/me/orders` - Get user's orders (requires authentication)

### Feedbacks
- `POST /api/feedbacks` - Create feedback/complaint (requires authentication)

### Notifications
- `GET /api/users/me/notifications` - Get user's notifications (requires authentication)
- `PATCH /api/users/me/notifications/:id/read` - Mark notification as read (requires authentication)

## Authentication

All protected routes require JWT token in Authorization header:
```
Authorization: Bearer <token>
```

## Database Schema

The database includes the following tables:
- `users` - User accounts
- `orders` - Delivery orders
- `order_items` - Items in each order
- `feedbacks` - User feedbacks/complaints
- `notifications` - User notifications

Database triggers automatically:
- Create notifications when order status changes
- Update `updated_at` timestamps
- Generate tracking numbers for orders

