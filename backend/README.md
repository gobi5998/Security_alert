# Security Alert Backend API

A TypeScript-based REST API backend for the Security Alert Flutter application. This backend provides authentication, security alert management, malware reporting, and dashboard statistics.

## Features

- 🔐 **Authentication & Authorization**: JWT-based authentication with bcrypt password hashing
- 🚨 **Security Alerts**: CRUD operations for security alerts with severity levels and types
- 📊 **Malware Reports**: Comprehensive malware reporting system with status tracking
- 📈 **Dashboard Statistics**: Real-time threat statistics and risk assessment
- 🛡️ **Security**: Helmet, CORS, rate limiting, and input validation
- 📝 **Validation**: Request validation using Joi schemas
- 🗄️ **Mock Data**: In-memory data storage for development (easily replaceable with database)

## Tech Stack

- **Runtime**: Node.js
- **Language**: TypeScript
- **Framework**: Express.js
- **Authentication**: JWT + bcryptjs
- **Validation**: Joi
- **Security**: Helmet, CORS, express-rate-limit
- **Logging**: Morgan
- **Compression**: compression

## Prerequisites

- Node.js (v18 or higher)
- npm or yarn

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp env.example .env
   ```
   
   Edit `.env` file with your configuration:
   ```env
   PORT=3000
   NODE_ENV=development
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   JWT_EXPIRES_IN=7d
   CORS_ORIGIN=http://localhost:3000,http://localhost:8080
   ```

4. **Build the project**
   ```bash
   npm run build
   ```

5. **Start the server**
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

## Project Structure

```
src/
├── app.ts              # Express app configuration
├── server.ts           # Server startup and graceful shutdown
├── controllers/        # Request handlers
├── middleware/         # Custom middleware
├── models/            # Data models and services
├── routes/            # API routes
├── utils/             # Utility functions
└── index.ts           # (Removed - now using app.ts + server.ts)
```

## API Endpoints

### Authentication

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/login` | User login | No |
| POST | `/api/auth/register` | User registration | No |
| POST | `/api/auth/logout` | User logout | Yes |
| GET | `/api/auth/profile` | Get user profile | Yes |
| PUT | `/api/auth/profile` | Update user profile | Yes |

### Security Alerts

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/alerts` | Get all alerts | Yes |
| GET | `/api/alerts/:id` | Get alert by ID | Yes |
| POST | `/api/alerts` | Create new alert | Yes |
| PUT | `/api/alerts/:id` | Update alert | Yes |
| DELETE | `/api/alerts/:id` | Delete alert | Yes |
| PATCH | `/api/alerts/:id/resolve` | Resolve alert | Yes |
| GET | `/api/alerts/stats` | Get alert statistics | Yes |

### Malware Reports

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/reports` | Get all reports | Yes |
| GET | `/api/reports/:id` | Get report by ID | Yes |
| POST | `/api/reports` | Create new report | Yes |
| PUT | `/api/reports/:id` | Update report | Yes |
| DELETE | `/api/reports/:id` | Delete report | Yes |
| PATCH | `/api/reports/:id/submit` | Submit report | Yes |
| PATCH | `/api/reports/:id/process` | Process report | Yes |
| PATCH | `/api/reports/:id/resolve` | Resolve report | Yes |
| GET | `/api/reports/status/:status` | Get reports by status | Yes |
| GET | `/api/reports/stats` | Get report statistics | Yes |

### Dashboard

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/dashboard/stats` | Get dashboard statistics | Yes |
| GET | `/api/dashboard/threats` | Get threat history | Yes |
| GET | `/api/dashboard/risk-score` | Get risk score | Yes |
| GET | `/api/dashboard/resolution-rate` | Get resolution rate | Yes |

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Server health check |

## Data Models

### User
```typescript
interface IUser {
  id: string;
  username: string;
  email: string;
  password?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### Security Alert
```typescript
interface ISecurityAlert {
  id: string;
  title: string;
  description: string;
  severity: AlertSeverity; // 'low' | 'medium' | 'high' | 'critical'
  type: AlertType; // 'spam' | 'malware' | 'fraud' | 'phishing' | 'other'
  timestamp: Date;
  isResolved: boolean;
  location?: string;
  malwareType?: string;
  infectedDeviceType?: string;
  operatingSystem?: string;
  detectionMethod?: string;
  fileName?: string;
  name?: string;
  systemAffected?: string;
  metadata?: Record<string, any>;
  userId?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### Malware Report
```typescript
interface IMalwareReport {
  id: string;
  malwareType?: string;
  infectedDeviceType?: string;
  operatingSystem?: string;
  detectionMethod?: string;
  location?: string;
  fileName?: string;
  name?: string;
  systemAffected?: string;
  alertSeverityLevel?: string;
  userId?: string;
  status: 'pending' | 'submitted' | 'processed' | 'resolved';
  createdAt: Date;
  updatedAt: Date;
}
```

### Dashboard Stats
```typescript
interface IDashboardStats {
  totalAlerts: number;
  resolvedAlerts: number;
  pendingAlerts: number;
  alertsByType: Record<string, number>;
  alertsBySeverity: Record<string, number>;
  threatTrendData: number[];
  threatBarData: number[];
  riskScore: number;
}
```

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

### Example Login Request
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "demo_user",
    "password": "123456"
  }'
```

### Example Response
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "1",
    "username": "demo_user",
    "email": "demo@example.com",
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## Error Handling

The API returns consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": "Validation errors (if applicable)"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized
- `404` - Not Found
- `409` - Conflict (duplicate data)
- `429` - Too Many Requests (rate limiting)
- `500` - Internal Server Error

## Development

### Available Scripts

```bash
# Development
npm run dev          # Start development server with hot reload
npm run build        # Build TypeScript to JavaScript
npm start            # Start production server

# Testing
npm test             # Run tests
npm run test:watch   # Run tests in watch mode

# Linting
npm run lint         # Run ESLint
npm run lint:fix     # Fix ESLint errors
```

### Architecture Overview

The backend follows a clean separation of concerns:

- **`app.ts`**: Express application configuration, middleware setup, and route registration
- **`server.ts`**: Server startup, port configuration, and graceful shutdown handling
- **Controllers**: Business logic and request/response handling
- **Models**: Data models and service layer
- **Routes**: API endpoint definitions
- **Middleware**: Authentication, validation, and other middleware functions

### Adding Database Support

Currently, the API uses in-memory storage. To add database support:

1. Install your preferred database driver (e.g., `pg` for PostgreSQL, `mongoose` for MongoDB)
2. Update the service classes in `src/models/` to use database queries
3. Add database connection configuration to `.env`
4. Update the app configuration in `app.ts` to establish database connections

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `development` |
| `JWT_SECRET` | JWT signing secret | Required |
| `JWT_EXPIRES_IN` | JWT expiration time | `7d` |
| `CORS_ORIGIN` | Allowed CORS origins | `http://localhost:3000,http://localhost:8080` |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window | `900000` (15 minutes) |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `100` |
| `BCRYPT_ROUNDS` | Password hashing rounds | `12` |

## Security Features

- **Helmet**: Security headers
- **CORS**: Cross-origin resource sharing
- **Rate Limiting**: Prevent abuse
- **Input Validation**: Joi schemas
- **Password Hashing**: bcryptjs
- **JWT**: Secure token-based authentication
- **Request Size Limits**: Prevent large payload attacks

## Testing

The API includes comprehensive test coverage. Run tests with:

```bash
npm test
```

## Deployment

### Production Build

```bash
npm run build
npm start
```

### Docker (Optional)

Create a `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY dist ./dist

EXPOSE 3000

CMD ["npm", "start"]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details 