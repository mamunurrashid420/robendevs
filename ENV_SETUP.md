# How to Create and Configure .env Files

This guide explains how to set up environment variables for your project.

## Quick Setup (Recommended)

### Step 1: Copy the Example File

**Windows (PowerShell):**
```powershell
Copy-Item .env.example .env
```

**Mac/Linux (Bash):**
```bash
cp .env.example .env
```

### Step 2: Edit the .env File

Open `.env` in your text editor and update values as needed:

```env
# Database Configuration
DB_USER=postgres
DB_PASS=postgres
DB_NAME=react_auth_db
DB_PORT=5432

# Backend Server
NODE_ENV=development
PORT_DEV=8010
API_VERSION=v1

# JWT Secrets (Change these in production!)
JWT_VERIFY_SECRET=your-secure-verify-secret-key-change-this
JWT_SESSION_SECRET=your-secure-session-secret-key-change-this

# Session
SESSION_COOKIE_NAME=sessionId

# URLs
API_URL_DEV=http://localhost:8010
CLIENT_URL_DEV=http://localhost:3000

# Frontend
REACT_APP_API_URL=http://localhost:8010
```

### Step 3: Use It

#### Docker Setup
```bash
docker-compose up -d
```

#### Local Development
The `.env` file in the root directory is used by `docker-compose`.

For local development (without Docker), create `.env` files in each directory:

**apiserver/.env:**
```env
NODE_ENV=development
PORT_DEV=8010
DB_HOST=localhost
DB_USER=postgres
DB_PASS=postgres
DB_NAME=react_auth_db
DB_PORT=5432
API_VERSION=v1
JWT_VERIFY_SECRET=your-secret
JWT_SESSION_SECRET=your-secret
SESSION_COOKIE_NAME=sessionId
API_URL_DEV=http://localhost:8010
CLIENT_URL_DEV=http://localhost:3000
```

**client/.env:**
```env
REACT_APP_API_URL=http://localhost:8010
```

## Manual Creation

### If You Don't Have .env.example

#### Step 1: Create Empty File

**Windows (PowerShell):**
```powershell
New-Item -Path ".env" -ItemType File
```

**Mac/Linux:**
```bash
touch .env
```

#### Step 2: Add Content

Open the file with any text editor (VS Code, Notepad, etc.) and paste this content:

```env
# Database Configuration
DB_USER=postgres
DB_PASS=postgres
DB_NAME=react_auth_db
DB_PORT=5432

# Backend Server
NODE_ENV=development
PORT_DEV=8010
API_VERSION=v1

# JWT Secrets
JWT_VERIFY_SECRET=dev-verify-secret-key
JWT_SESSION_SECRET=dev-session-secret-key
SESSION_COOKIE_NAME=sessionId

# URLs
API_URL_DEV=http://localhost:8010
CLIENT_URL_DEV=http://localhost:3000

# Frontend
REACT_APP_API_URL=http://localhost:8010
```

## Important Notes

⚠️ **Security**
- Never commit `.env` file to Git (should be in `.gitignore`)
- Always use strong secrets in production
- Regenerate secrets when deploying to production

✅ **Development vs Production**
- Use simple values for development
- Use strong, random values for production
- Example secure secret generation:

**Linux/Mac:**
```bash
openssl rand -base64 32
```

**PowerShell:**
```powershell
[Convert]::ToBase64String([System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(32))
```

## Troubleshooting

### Variables Not Loading
- Check file is named exactly `.env` (not `.env.txt` or `.env.example`)
- Ensure file is in project root directory
- Restart Docker or dev server after changes

### Database Connection Failed
```bash
# Verify environment variables are set
docker-compose config | grep DB_

# Check postgres service
docker-compose logs postgres
```

### Port Already in Use
Change `PORT_DEV=8010` to available port (e.g., `8011`)

## File Locations

```
project-root/
├── .env                 ← Root .env (for docker-compose)
├── .env.example         ← Template file
├── apiserver/
│   └── .env             ← Backend .env (for local dev)
└── client/
    └── .env             ← Frontend .env (for local dev)
```

## Environment Variables Reference

| Variable | Purpose | Default |
|----------|---------|---------|
| `DB_USER` | PostgreSQL username | postgres |
| `DB_PASS` | PostgreSQL password | postgres |
| `DB_NAME` | Database name | react_auth_db |
| `DB_PORT` | Database port | 5432 |
| `NODE_ENV` | Environment | development |
| `PORT_DEV` | Backend server port | 8010 |
| `API_VERSION` | API version | v1 |
| `JWT_VERIFY_SECRET` | Email verification secret | - |
| `JWT_SESSION_SECRET` | Session JWT secret | - |
| `SESSION_COOKIE_NAME` | Cookie name | sessionId |
| `REACT_APP_API_URL` | Frontend API URL | http://localhost:8010 |
