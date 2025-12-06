# Node.js-React.js-PostgreSQL Project

A comprehensive React-Node-Postgres boilerplate with complete server-client communication, CRUD operations, and Ant Design UI components. Uses Sequelize ORM for database management.

## Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Docker Setup](#docker-setup)
- [Local Development](#local-development)
- [Project Structure](#project-structure)

## Quick Start

### Docker (Recommended)

```bash
# Clone and navigate to project
git clone <repo-url>
cd node-react-postgres

# Create .env file (copy from .env.example if available)
cp .env.example .env

# Start all services
docker-compose up -d

# Access services
# Frontend: http://localhost:3000
# Backend API: http://localhost:8010
# PostgreSQL: localhost:5432
```

### Local Development

```bash
# Install root dependencies
npm install

# Terminal 1: Install and start backend
cd apiserver
npm install
npm start

# Terminal 2: Install and start frontend
cd client
npm install
npm start
```

## Prerequisites

### Option 1: Docker
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose (usually included with Docker Desktop)

### Option 2: Local Development
- Node.js (v16 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

## Docker Setup

### Configuration

Create a `.env` file in the project root:

```env
# Database
DB_USER=postgres
DB_PASS=postgres
DB_NAME=react_auth_db
DB_PORT=5432

# Backend
NODE_ENV=development
PORT_DEV=8010
API_VERSION=v1

# JWT Secrets
JWT_VERIFY_SECRET=your-secure-verify-secret-key
JWT_SESSION_SECRET=your-secure-session-secret-key
SESSION_COOKIE_NAME=sessionId
```

### Common Docker Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Rebuild images
docker-compose up -d --build

# Remove volumes (database data)
docker-compose down -v

# Execute command in running container
docker-compose exec backend node index.js
docker-compose exec postgres psql -U postgres -d react_auth_db
```

### Service Health

Check service status:

```bash
# All services
docker-compose ps

# Specific service health
docker inspect react-auth-backend
```

### Troubleshooting Docker

**Port Already in Use**
```bash
# Change ports in docker-compose.yaml or .env
# Or kill existing process on port
# Windows: netstat -ano | findstr :8010
# Mac/Linux: lsof -i :8010
```

**Database Connection Failed**
```bash
# Ensure postgres service is healthy
docker-compose logs postgres

# Verify environment variables
docker-compose config | grep -A 10 postgres
```

**Container Won't Start**
```bash
# Check logs
docker-compose logs <service-name>

# Rebuild and restart
docker-compose down && docker-compose up -d --build
```

## Local Development

### Setup Backend

```bash
cd apiserver

# Install dependencies
npm install

# Create .env file with required variables
cp example.env .env

# Create images folder for uploads
mkdir images

# Start development server
npm start
```

### Setup Frontend

```bash
cd client

# Install dependencies
npm install

# Start development server
npm start
```

The app will run on `http://localhost:3000` with backend API at `http://localhost:8010`.

## Project Structure

```
.
├── apiserver/              # Node.js Express backend
│   ├── controllers/        # Request handlers
│   ├── models/             # Sequelize models
│   ├── routes/             # API routes
│   ├── services/           # Business logic
│   ├── middleware/         # Custom middleware
│   ├── utils/              # Utility functions
│   ├── config/             # Configuration
│   └── package.json
├── client/                 # React frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/          # Page components
│   │   ├── services/       # API client services
│   │   ├── hooks/          # Custom hooks
│   │   ├── context/        # React context
│   │   └── utils/          # Utility functions
│   └── package.json
├── docker-compose.yaml     # Docker services definition
├── Dockerfile.backend      # Backend image build
├── Dockerfile.frontend     # Frontend image build
└── README.md               # This file
```

## Environment Variables

### Backend (.env in apiserver/)
- `NODE_ENV` - Environment (development/production)
- `PORT_DEV` - Server port
- `DB_HOST` - Database host
- `DB_USER` - Database user
- `DB_PASS` - Database password
- `DB_NAME` - Database name
- `DB_PORT` - Database port
- `JWT_VERIFY_SECRET` - Email verification JWT secret
- `JWT_SESSION_SECRET` - Session JWT secret
- `SESSION_COOKIE_NAME` - Cookie name for sessions

### Frontend (.env in client/)
- `REACT_APP_API_URL` - Backend API base URL

## Development Notes

- Backend runs on port 8010
- Frontend runs on port 3000
- PostgreSQL runs on port 5432
- All services communicate through Docker network
- Volume mounts enable hot-reload in development mode
- Database data persists in `postgres_data` volume

## License

ISC




