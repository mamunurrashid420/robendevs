#!/bin/bash

# Kubernetes Status Check Script
# Monitor deployment status

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

NAMESPACE="namespace-dev"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kubernetes Deployment Status${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check namespace
echo -e "${BLUE}1️⃣  Namespace Status:${NC}"
kubectl get namespace $NAMESPACE 2>/dev/null || echo "❌ Namespace not found"
echo ""

# Check Deployments
echo -e "${BLUE}2️⃣  Deployments:${NC}"
kubectl get deployments -n $NAMESPACE --no-headers 2>/dev/null || echo "❌ No deployments found"
echo ""

# Check Pods
echo -e "${BLUE}3️⃣  Pods:${NC}"
kubectl get pods -n $NAMESPACE -o wide 2>/dev/null || echo "❌ No pods found"
echo ""

# Check Services
echo -e "${BLUE}4️⃣  Services:${NC}"
kubectl get svc -n $NAMESPACE 2>/dev/null || echo "❌ No services found"
echo ""

# Check PVC
echo -e "${BLUE}5️⃣  Persistent Volume Claims:${NC}"
kubectl get pvc -n $NAMESPACE 2>/dev/null || echo "❌ No PVCs found"
echo ""

# Check Resource Usage
echo -e "${BLUE}6️⃣  Resource Usage:${NC}"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "⚠️  Metrics not available (metrics-server might not be running)"
echo ""

# Check Events
echo -e "${BLUE}7️⃣  Recent Events:${NC}"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || echo "❌ No events found"
echo ""

# Pod Status Details
echo -e "${BLUE}8️⃣  Pod Status Details:${NC}"
for pod in $(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    STATUS=$(kubectl get pod $pod -n $NAMESPACE -o jsonpath='{.status.phase}')
    echo "  $pod: $STATUS"
done
echo ""

echo -e "${BLUE}========================================${NC}"
echo "For more details:"
echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
echo "  kubectl logs <pod-name> -n $NAMESPACE"
echo "  kubectl logs <pod-name> -n $NAMESPACE -f  (follow)"
echo -e "${BLUE}========================================${NC}"
