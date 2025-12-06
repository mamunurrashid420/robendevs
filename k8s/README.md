# 🚀 Kubernetes Deployment Setup

Complete Kubernetes manifests for deploying your Node.js-React-PostgreSQL application.

## 📁 Directory Structure

```
k8s/
├── namespace-dev.yaml              # Development namespace
├── app-configmap.yaml              # Non-sensitive configuration
├── app-secrets.yaml                # Sensitive data
├── postgres-pv.yaml                # PostgreSQL Persistent Volume
├── postgres-pvc.yaml               # PostgreSQL Persistent Volume Claim
├── postgres-deployment.yaml        # PostgreSQL deployment
├── postgres-service.yaml           # PostgreSQL service
├── backend-deployment.yaml         # Backend (Node.js) deployment
├── backend-service.yaml            # Backend service
├── frontend-deployment.yaml        # Frontend (React) deployment
├── frontend-service.yaml           # Frontend service
├── ingress-dev.yaml                # Ingress for API Gateway routing
├── kustomization.yaml              # Kustomize configuration
├── deploy.sh                       # Automated deployment script
├── cleanup.sh                      # Cleanup script
├── status.sh                       # Status check script
└── KUBERNETES_DEPLOYMENT.md        # Detailed documentation
```

## ⚙️ Components

### Infrastructure
- **Namespace**: `namespace-dev` - Isolated environment for development
- **Storage**: PostgreSQL uses PersistentVolume + PersistentVolumeClaim
- **Configuration**: ConfigMap for non-sensitive data, Secret for sensitive data

### Services
- **PostgreSQL**: ClusterIP service (internal only)
- **Backend**: LoadBalancer service (accessible externally)
- **Frontend**: LoadBalancer service (accessible externally)

### Deployments
- **PostgreSQL**: 1 replica, health checks, resource limits
- **Backend**: 2 replicas, rolling updates, health checks
- **Frontend**: 2 replicas, rolling updates, health checks

## 🚀 Quick Deployment

### Prerequisites
```bash
# Install kubectl
# Install Docker (if building images)
# Access to Kubernetes cluster (minikube, kind, EKS, GKE, AKS, etc.)
```

### Verify Kubernetes Connection
```bash
kubectl cluster-info
kubectl get nodes
```

### Option 1: Using Deployment Script (Recommended)
```bash
# Make script executable (Linux/Mac)
chmod +x k8s/deploy.sh

# Run deployment
./k8s/deploy.sh
```

### Option 2: Using kubectl apply
```bash
# Deploy everything at once
kubectl apply -f k8s/

# Or deploy step by step
kubectl apply -f k8s/namespace-dev.yaml
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/app-secrets.yaml
kubectl apply -f k8s/postgres-pv.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

### Option 3: Using Kustomize
```bash
kustomize build k8s/ | kubectl apply -f -
```

## ✅ Verify Deployment

### Check Status
```bash
# Using status script
chmod +x k8s/status.sh
./k8s/status.sh

# Or manually
kubectl get namespace namespace-dev
kubectl get all -n namespace-dev
kubectl get pvc -n namespace-dev
```

### Wait for Pods to be Ready
```bash
kubectl wait --for=condition=ready pod -l app=postgres -n namespace-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=backend -n namespace-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n namespace-dev --timeout=300s
```

### View Service Endpoints
```bash
kubectl get svc -n namespace-dev

# Output example:
# NAME               TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
# postgres-service   ClusterIP      10.0.0.1       <none>           5432/TCP
# backend-service    LoadBalancer   10.0.0.2       192.168.1.100    8010:32000/TCP
# frontend-service   LoadBalancer   10.0.0.3       192.168.1.101    80:32001/TCP
```

## 🌐 Access Services

### Frontend
```bash
# Get external IP
FRONTEND_IP=$(kubectl get svc frontend-service -n namespace-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend: http://$FRONTEND_IP"

# Or port forward
kubectl port-forward -n namespace-dev svc/frontend-service 3000:80
# Then visit: http://localhost:3000
```

### Backend API
```bash
# Get external IP
BACKEND_IP=$(kubectl get svc backend-service -n namespace-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Backend: http://$BACKEND_IP:8010"

# Or port forward
kubectl port-forward -n namespace-dev svc/backend-service 8010:8010
# Then visit: http://localhost:8010/api/v1/auth/check-auth
```

### Database
```bash
# Port forward to localhost
kubectl port-forward -n namespace-dev svc/postgres-service 5432:5432

# Connect with psql
psql -h localhost -U postgres -d react_auth_db
# Password: postgres (default, change in app-secrets.yaml)
```

## 🔍 Monitoring & Troubleshooting

### View Logs
```bash
# PostgreSQL logs
kubectl logs -n namespace-dev deployment/postgres-deployment

# Backend logs
kubectl logs -n namespace-dev deployment/backend-deployment -f

# Frontend logs
kubectl logs -n namespace-dev deployment/frontend-deployment -f

# Specific pod
kubectl logs -n namespace-dev <pod-name> -f
```

### Execute Commands in Pod
```bash
# Interactive shell in backend
kubectl exec -it -n namespace-dev deployment/backend-deployment -- sh

# Execute single command
kubectl exec -n namespace-dev deployment/postgres-deployment -- psql -U postgres -d react_auth_db -c "SELECT version();"
```

### Describe Pod
```bash
kubectl describe pod -n namespace-dev <pod-name>
```

### Check Events
```bash
kubectl get events -n namespace-dev --sort-by='.lastTimestamp'
```

## 🔐 Secrets Management

### View Secret Values (Base64 Encoded)
```bash
kubectl get secret app-secrets -n namespace-dev -o yaml
```

### Update Secrets
```bash
# Edit interactively
kubectl edit secret app-secrets -n namespace-dev

# Or recreate
kubectl delete secret app-secrets -n namespace-dev
kubectl create secret generic app-secrets \
  --from-literal=DB_USER=postgres \
  --from-literal=DB_PASS=newpassword \
  --from-literal=JWT_VERIFY_SECRET=newsecret \
  --from-literal=JWT_SESSION_SECRET=newsecret \
  --from-literal=SESSION_ENCRYPT_SECRET=newencryptionsecret \
  -n namespace-dev
```

## 📈 Scaling

### Manual Scaling
```bash
# Scale backend to 3 replicas
kubectl scale deployment backend-deployment --replicas=3 -n namespace-dev

# Scale frontend to 3 replicas
kubectl scale deployment frontend-deployment --replicas=3 -n namespace-dev
```

### Auto-scaling (HPA)
```bash
# Requires metrics-server installed
kubectl autoscale deployment backend-deployment --min=2 --max=5 --cpu-percent=80 -n namespace-dev

# Check HPA status
kubectl get hpa -n namespace-dev
```

## 🔄 Rolling Updates

### Update Image
```bash
kubectl set image deployment/backend-deployment backend=yourusername/backend:v2 -n namespace-dev
```

### Check Rollout History
```bash
kubectl rollout history deployment/backend-deployment -n namespace-dev
```

### Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/backend-deployment -n namespace-dev

# Rollback to specific revision
kubectl rollout undo deployment/backend-deployment --to-revision=2 -n namespace-dev
```

## 🗑️ Cleanup

### Using Cleanup Script
```bash
chmod +x k8s/cleanup.sh
./k8s/cleanup.sh
```

### Manual Cleanup
```bash
# Delete specific resource
kubectl delete deployment backend-deployment -n namespace-dev

# Delete entire namespace (and all resources)
kubectl delete namespace namespace-dev
```

## 📊 Resource Management

### View Current Resources
```bash
kubectl get resourcequota -n namespace-dev
kubectl get limits -n namespace-dev
```

### Resource Requests/Limits
Current settings:
- **PostgreSQL**: 256Mi request / 512Mi limit (memory)
- **Backend**: 256Mi request / 512Mi limit (memory)
- **Frontend**: 512Mi request / 1Gi limit (memory)

Adjust in respective deployment YAML files if needed.

## 🔌 Network Policies (Optional)

For production, add network policies:
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
  namespace: namespace-dev
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8010
EOF
```

## 🔒 Security Improvements

### For Production:
1. **Use private Docker registry**
2. **Use sealed-secrets or external-secrets operator**
3. **Configure RBAC properly**
4. **Use network policies**
5. **Set resource quotas**
6. **Use persistent volumes properly**
7. **Enable pod security policies**
8. **Configure ingress with TLS**
9. **Use ConfigMap only for non-sensitive data**
10. **Implement pod disruption budgets**

## 📚 Useful Commands

```bash
# General
kubectl version                              # Check version
kubectl cluster-info                         # Cluster information
kubectl get nodes                            # List nodes

# Namespace operations
kubectl get namespace                        # List namespaces
kubectl create namespace test                # Create namespace
kubectl delete namespace test                # Delete namespace

# Pod operations
kubectl get pods -n namespace-dev            # List pods
kubectl describe pod <pod-name> -n namespace-dev
kubectl logs <pod-name> -n namespace-dev -f
kubectl exec -it <pod-name> -n namespace-dev -- sh

# Deployment operations
kubectl get deployments -n namespace-dev
kubectl describe deployment <name> -n namespace-dev
kubectl scale deployment <name> --replicas=3 -n namespace-dev
kubectl rollout status deployment/<name> -n namespace-dev

# Service operations
kubectl get svc -n namespace-dev
kubectl describe svc <service-name> -n namespace-dev
kubectl port-forward svc/<service-name> 8080:8080 -n namespace-dev
```

## 🆘 Troubleshooting

### Pod stuck in Pending
```bash
kubectl describe pod <pod-name> -n namespace-dev
# Check: CPU/memory requests, PVC status, node availability
```

### Pod in CrashLoopBackOff
```bash
kubectl logs <pod-name> -n namespace-dev
# Check: application logs for startup errors
```

### Service External IP stuck on \<pending\>
```bash
# For minikube
minikube tunnel

# For cloud platforms (GKE, EKS, AKS)
# External IP should appear automatically
```

### Database connection failed
```bash
# Verify postgres service is running
kubectl get svc postgres-service -n namespace-dev

# Check if backend can reach database
kubectl exec -it deployment/backend-deployment -n namespace-dev -- \
  nc -zv postgres-service.namespace-dev.svc.cluster.local 5432
```

## 🌐 Ingress Controller & API Gateway

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL TRAFFIC                                │
│                         http://node-react.local                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INGRESS CONTROLLER                                 │
│                         (nginx-ingress-controller)                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │  Routing Rules:                                                         ││
│  │    /              → frontend-service:80                                 ││
│  │    /api/*         → backend-service:8010                                ││
│  │    /health        → backend-service:8010                                ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
                          │                           │
              ┌───────────┘                           └───────────┐
              ▼                                                   ▼
┌─────────────────────────────┐                 ┌─────────────────────────────┐
│    FRONTEND SERVICE         │                 │     BACKEND SERVICE         │
│    (ClusterIP:80)           │                 │     (ClusterIP:8010)        │
└─────────────────────────────┘                 └─────────────────────────────┘
              │                                               │
              ▼                                               ▼
┌─────────────────────────────┐                 ┌─────────────────────────────┐
│    FRONTEND PODS            │                 │     BACKEND PODS            │
│    (React App - port 3000)  │                 │     (Node.js - port 8010)   │
│    ┌─────┐  ┌─────┐        │                 │     ┌─────┐  ┌─────┐       │
│    │Pod 1│  │Pod 2│        │                 │     │Pod 1│  │Pod 2│       │
│    └─────┘  └─────┘        │                 │     └─────┘  └─────┘       │
└─────────────────────────────┘                 └─────────────────────────────┘
                                                              │
                                                              ▼
                                                ┌─────────────────────────────┐
                                                │    POSTGRES SERVICE         │
                                                │    (ClusterIP:5432)         │
                                                └─────────────────────────────┘
                                                              │
                                                              ▼
                                                ┌─────────────────────────────┐
                                                │    POSTGRES POD             │
                                                │    (PostgreSQL - port 5432) │
                                                │    ┌─────────────┐          │
                                                │    │   Pod 1     │          │
                                                │    │ + PVC Data  │          │
                                                │    └─────────────┘          │
                                                └─────────────────────────────┘
```

### Request Flow: Browser → Database

```
1. User types: http://node-react.local/api/v1/users

2. DNS Resolution (local hosts file):
   node-react.local → Ingress Controller External IP

3. Ingress Controller receives request:
   - Matches path /api/*
   - Routes to backend-service:8010

4. Kubernetes Service (backend-service):
   - ClusterIP load balances across backend pods
   - Uses iptables/IPVS for traffic distribution

5. Backend Pod:
   - Express.js handles /api/v1/users
   - Needs database connection

6. DNS Resolution (Kubernetes Internal):
   postgres-service.dev.svc.cluster.local → Postgres ClusterIP

7. Postgres Service → Postgres Pod:
   - Query executed
   - Response returned up the chain
```

### Install Nginx Ingress Controller

```bash
# For Minikube
minikube addons enable ingress

# For bare-metal/cloud clusters using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# Verify installation
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### Deploy Ingress

```bash
# Apply ingress manifest
kubectl apply -f k8s/ingress-dev.yaml

# Verify ingress
kubectl get ingress -n dev
kubectl describe ingress app-ingress -n dev
```

### Configure Local Hosts File

```bash
# Get Ingress Controller External IP
kubectl get svc -n ingress-nginx

# For Minikube
minikube ip

# Add to hosts file:
# Linux/Mac: /etc/hosts
# Windows: C:\Windows\System32\drivers\etc\hosts

# Add this line:
<INGRESS_IP>  node-react.local
```

### Kubernetes DNS Resolution

Kubernetes uses CoreDNS for internal service discovery:

| Service | Internal DNS Name | Resolves To |
|---------|-------------------|-------------|
| Backend | `backend-service.dev.svc.cluster.local` | Backend ClusterIP |
| Frontend | `frontend-service.dev.svc.cluster.local` | Frontend ClusterIP |
| Postgres | `postgres-service.dev.svc.cluster.local` | Postgres ClusterIP |

**DNS Format**: `<service-name>.<namespace>.svc.cluster.local`

**Short forms within same namespace**:
- `backend-service` (same namespace)
- `backend-service.dev` (cross-namespace)

### Ingress vs Service vs Pod

| Component | Purpose | Scope | Example |
|-----------|---------|-------|---------|
| **Pod** | Runs container(s) | Single instance | One Node.js container |
| **Service** | Load balances pods | Cluster internal | Routes to all backend pods |
| **Ingress** | External HTTP routing | Cluster external | Routes `/api` to backend-service |

```
Internet → Ingress (L7 routing) → Service (L4 load balancing) → Pod (application)
```

## 🔧 Debugging Guide

### 1. Ingress Reachable but Backend Not Working

```bash
# Step 1: Check Ingress configuration
kubectl describe ingress app-ingress -n dev

# Step 2: Verify backend service exists and has endpoints
kubectl get svc backend-service -n dev
kubectl get endpoints backend-service -n dev

# Step 3: Check if backend pods are running
kubectl get pods -n dev -l app=backend

# Step 4: Test backend directly (port-forward)
kubectl port-forward svc/backend-service 8010:8010 -n dev
curl http://localhost:8010/health

# Step 5: Check Ingress Controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Step 6: Test from inside cluster
kubectl run debug --rm -it --image=curlimages/curl -- sh
curl http://backend-service.dev.svc.cluster.local:8010/health
```

### 2. Frontend Can't Talk to Backend

```bash
# Step 1: Check if frontend can resolve backend DNS
kubectl exec -it deployment/frontend-deployment -n dev -- nslookup backend-service.dev.svc.cluster.local

# Step 2: Check network connectivity
kubectl exec -it deployment/frontend-deployment -n dev -- wget -qO- http://backend-service.dev.svc.cluster.local:8010/health

# Step 3: Check CORS configuration in backend
# Verify REACT_APP_API_URL in frontend matches backend URL

# Step 4: Check network policies (if any)
kubectl get networkpolicies -n dev

# Step 5: Verify services are in same namespace
kubectl get svc -n dev
```

### 3. Database Connection Issues

```bash
# Step 1: Check postgres pod is running
kubectl get pods -n dev -l app=postgres

# Step 2: Check postgres service
kubectl get svc postgres-service -n dev
kubectl get endpoints postgres-service -n dev

# Step 3: Test connection from backend
kubectl exec -it deployment/backend-deployment -n dev -- \
  nc -zv postgres-service.dev.svc.cluster.local 5432

# Step 4: Check backend environment variables
kubectl exec -it deployment/backend-deployment -n dev -- env | grep DB_
```

## 🏗️ Microservices Evolution

### Current Architecture (Monolithic Backend)

```
Ingress → backend-service → All API endpoints in one service
```

### Future Microservices Architecture

```
                           ┌─────────────────┐
                           │   API Gateway   │
                           │   (Ingress)     │
                           └────────┬────────┘
                                    │
        ┌───────────────┬───────────┼───────────┬───────────────┐
        ▼               ▼           ▼           ▼               ▼
┌───────────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐
│ Auth Service  │ │User Service│ │Order Svc │ │Payment Svc│ │Notification│
│ /api/auth/*   │ │/api/users/*│ │/api/orders│ │/api/pay/* │ │/api/notify│
└───────────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘
        │               │           │               │               │
        ▼               ▼           ▼               ▼               ▼
    ┌───────┐       ┌───────┐   ┌───────┐       ┌───────┐       ┌───────┐
    │Auth DB│       │User DB│   │Order DB│      │Pay DB │       │ Redis │
    └───────┘       └───────┘   └───────┘       └───────┘       └───────┘
```

### Implementation Steps

1. **Split backend into microservices**:
   ```yaml
   # auth-service-deployment.yaml
   # user-service-deployment.yaml
   # order-service-deployment.yaml
   ```

2. **Update Ingress for multiple backends**:
   ```yaml
   spec:
     rules:
     - host: node-react.local
       http:
         paths:
         - path: /api/auth
           backend:
             service:
               name: auth-service
               port: 8011
         - path: /api/users
           backend:
             service:
               name: user-service
               port: 8012
         - path: /api/orders
           backend:
             service:
               name: order-service
               port: 8013
   ```

3. **Add service mesh (optional)**:
   - Istio or Linkerd for service-to-service communication
   - mTLS, traffic management, observability

4. **Implement API Gateway features**:
   - Rate limiting per service
   - Authentication at gateway level
   - Request/response transformation
   - Circuit breaker patterns

## 📖 Documentation

See `KUBERNETES_DEPLOYMENT.md` for detailed documentation.

## 🤝 Support

For issues or questions:
1. Check the logs: `kubectl logs -f deployment/<name> -n dev`
2. Describe the resource: `kubectl describe <resource-type> <name> -n dev`
3. Check events: `kubectl get events -n dev --sort-by='.lastTimestamp'`
4. Run status script: `./k8s/status.sh`

Happy Kubernetes deployment! 🚀
