#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Project Setup Script ===${NC}"
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${RED}.env file already exists!${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Setup cancelled.${NC}"
        exit 1
    fi
fi

# Create .env file
echo -e "${CYAN}Creating .env file...${NC}"
cat > .env << 'EOF'
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
EOF
echo -e "${GREEN}.env file created successfully!${NC}"
echo ""

# Create apiserver/.env for local development
echo -e "${CYAN}Creating apiserver/.env...${NC}"
cat > apiserver/.env << 'EOF'
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
EOF
echo -e "${GREEN}apiserver/.env file created successfully!${NC}"
echo ""

# Create client/.env for local development
echo -e "${CYAN}Creating client/.env...${NC}"
cat > client/.env << 'EOF'
REACT_APP_API_URL=http://localhost:8010
EOF
echo -e "${GREEN}client/.env file created successfully!${NC}"
echo ""

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo -e "${CYAN}Next steps:${NC}"
echo "1. Review .env files for your environment"
echo "2. For Docker: run 'docker-compose up -d'"
echo "3. For local dev: install dependencies and run 'npm start'"
echo ""
echo "Documentation: See ENV_SETUP.md for more details"
