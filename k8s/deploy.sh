#!/bin/bash

# Kubernetes Deployment Script
# Deploy entire application stack to Kubernetes

set -e

echo "🚀 Starting Kubernetes Deployment..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

K8S_DIR="./k8s"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}❌ kubectl is not installed${NC}"
    echo "Install kubectl from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check Kubernetes cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}❌ Cannot connect to Kubernetes cluster${NC}"
    echo "Make sure your Kubernetes cluster is running"
    exit 1
fi

echo -e "${GREEN}✅ Kubernetes cluster is accessible${NC}"
echo ""

# Step 1: Create namespace
echo -e "${BLUE}Step 1: Creating namespace...${NC}"
kubectl apply -f $K8S_DIR/namespace-dev.yaml
echo -e "${GREEN}✅ Namespace created${NC}"
echo ""

# Step 2: Create ConfigMap and Secrets
echo -e "${BLUE}Step 2: Creating ConfigMap and Secrets...${NC}"
kubectl apply -f $K8S_DIR/app-configmap.yaml
kubectl apply -f $K8S_DIR/app-secrets.yaml
echo -e "${GREEN}✅ ConfigMap and Secrets created${NC}"
echo ""

# Step 3: Create Storage
echo -e "${BLUE}Step 3: Creating Storage (PV/PVC)...${NC}"
kubectl apply -f $K8S_DIR/postgres-pv.yaml
kubectl apply -f $K8S_DIR/postgres-pvc.yaml
echo -e "${GREEN}✅ Storage created${NC}"
echo ""

# Step 4: Deploy PostgreSQL
echo -e "${BLUE}Step 4: Deploying PostgreSQL...${NC}"
kubectl apply -f $K8S_DIR/postgres-deployment.yaml
kubectl apply -f $K8S_DIR/postgres-service.yaml
echo -e "${GREEN}✅ PostgreSQL deployed${NC}"
echo ""

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n namespace-dev --timeout=300s || true
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
echo ""

# Step 5: Deploy Backend
echo -e "${BLUE}Step 5: Deploying Backend...${NC}"
kubectl apply -f $K8S_DIR/backend-deployment.yaml
kubectl apply -f $K8S_DIR/backend-service.yaml
echo -e "${GREEN}✅ Backend deployed${NC}"
echo ""

# Step 6: Deploy Frontend
echo -e "${BLUE}Step 6: Deploying Frontend...${NC}"
kubectl apply -f $K8S_DIR/frontend-deployment.yaml
kubectl apply -f $K8S_DIR/frontend-service.yaml
echo -e "${GREEN}✅ Frontend deployed${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo "📊 Checking deployment status..."
kubectl get deployments -n namespace-dev
echo ""

echo "🔌 Service Status:"
kubectl get svc -n namespace-dev
echo ""

echo "📦 Pod Status:"
kubectl get pods -n namespace-dev
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Wait for all pods to be in Running state"
echo "2. Get service IPs: kubectl get svc -n namespace-dev"
echo "3. Check logs: kubectl logs -n namespace-dev deployment/backend-deployment"
echo "4. Forward ports: kubectl port-forward -n namespace-dev svc/backend-service 8010:8010"
echo ""

echo -e "${BLUE}Monitor deployment:${NC}"
echo "kubectl get pods -n namespace-dev -w"
echo ""
