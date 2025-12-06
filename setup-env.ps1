#!/usr/bin/env pwsh

# Color output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

Write-Info "=== Project Setup Script ==="
Write-Info ""

# Check if .env already exists
if (Test-Path ".env") {
    Write-Error ".env file already exists!"
    $response = Read-Host "Overwrite? (y/n)"
    if ($response -ne "y") {
        Write-Info "Setup cancelled."
        exit
    }
}

# Create .env file
Write-Info "Creating .env file..."
$envContent = @"
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
JWT_VERIFY_SECRET=dev-verify-secret-key
JWT_SESSION_SECRET=dev-session-secret-key

# Session
SESSION_COOKIE_NAME=sessionId

# URLs
API_URL_DEV=http://localhost:8010
CLIENT_URL_DEV=http://localhost:3000

# Frontend
REACT_APP_API_URL=http://localhost:8010
"@

Set-Content -Path ".env" -Value $envContent
Write-Success ".env file created successfully!"
Write-Info ""

# Create apiserver/.env for local development
Write-Info "Creating apiserver/.env..."
$apiEnvContent = @"
NODE_ENV=development
PORT_DEV=8010
DB_HOST=localhost
DB_USER=postgres
DB_PASS=postgres
DB_NAME=react_auth_db
DB_PORT=5432
API_VERSION=v1
JWT_VERIFY_SECRET=dev-verify-secret-key
JWT_SESSION_SECRET=dev-session-secret-key
SESSION_COOKIE_NAME=sessionId
API_URL_DEV=http://localhost:8010
CLIENT_URL_DEV=http://localhost:3000
"@

Set-Content -Path "apiserver\.env" -Value $apiEnvContent
Write-Success "apiserver/.env file created successfully!"
Write-Info ""

# Create client/.env for local development
Write-Info "Creating client/.env..."
$clientEnvContent = @"
REACT_APP_API_URL=http://localhost:8010
"@

Set-Content -Path "client\.env" -Value $clientEnvContent
Write-Success "client/.env file created successfully!"
Write-Info ""

Write-Success "=== Setup Complete ==="
Write-Info "Next steps:"
Write-Info "1. Review .env files for your environment"
Write-Info "2. For Docker: run 'docker-compose up -d'"
Write-Info "3. For local dev: install dependencies and run 'npm start'"
Write-Info ""
Write-Info "Documentation: See ENV_SETUP.md for more details"
