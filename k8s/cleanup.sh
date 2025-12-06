#!/bin/bash

# Kubernetes Cleanup Script
# Remove entire application stack from Kubernetes

set -e

echo "🗑️  Starting Kubernetes Cleanup..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Confirm deletion
read -p "Are you sure you want to delete the entire namespace-dev? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 1
fi

echo -e "${RED}⚠️  Deleting all resources in namespace-dev...${NC}"
echo ""

kubectl delete namespace namespace-dev --ignore-not-found=true

echo ""
echo -e "${GREEN}✅ Namespace and all resources deleted${NC}"
echo ""

# Verify deletion
echo "Remaining namespaces:"
kubectl get namespace | grep namespace-dev || echo "namespace-dev successfully removed"
