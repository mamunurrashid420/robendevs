# Kubernetes Deployment Guide

Complete Kubernetes deployment setup for your Node.js-React-PostgreSQL application.

## 📋 Files Structure

```
k8s/
├── namespace-dev.yaml           # Development namespace
├── app-configmap.yaml           # Non-sensitive configuration
├── app-secrets.yaml             # Sensitive data (secrets)
├── postgres-pv.yaml             # PostgreSQL persistent volume
├── postgres-pvc.yaml            # PostgreSQL persistent volume claim
├── postgres-deployment.yaml     # PostgreSQL deployment
├── postgres-service.yaml        # PostgreSQL service (internal)
├── backend-deployment.yaml      # Backend (Node.js) deployment
├── backend-service.yaml         # Backend service (LoadBalancer)
├── frontend-deployment.yaml     # Frontend (React) deployment
└── frontend-service.yaml        # Frontend service (LoadBalancer)
```

## 🚀 Quick Start

### 1. Create Namespace
```bash
kubectl apply -f k8s/namespace-dev.yaml
```

### 2. Create Configuration and Secrets
```bash
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/app-secrets.yaml
```

### 3. Create Storage (PostgreSQL)
```bash
kubectl apply -f k8s/postgres-pv.yaml
kubectl apply -f k8s/postgres-pvc.yaml
```

### 4. Deploy PostgreSQL
```bash
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
```

### 5. Deploy Backend
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
```

### 6. Deploy Frontend
```bash
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

### Deploy All at Once (Recommended)
```bash
kubectl apply -f k8s/
```

## ✅ Verify Deployment

### Check Namespace
```bash
kubectl get namespace namespace-dev
```

### Check Pods
```bash
kubectl get pods -n namespace-dev
kubectl get pods -n namespace-dev -w  # Watch mode
```

### Check Services
```bash
kubectl get svc -n namespace-dev
```

### Check Deployments
```bash
kubectl get deployments -n namespace-dev
```

### Check Persistent Volumes
```bash
kubectl get pv
kubectl get pvc -n namespace-dev
```

### Check Logs
```bash
# PostgreSQL logs
kubectl logs -n namespace-dev deployment/postgres-deployment

# Backend logs
kubectl logs -n namespace-dev deployment/backend-deployment
kubectl logs -n namespace-dev deployment/backend-deployment -c backend

# Frontend logs
kubectl logs -n namespace-dev deployment/frontend-deployment
kubectl logs -n namespace-dev deployment/frontend-deployment -c frontend

# Follow logs in real-time
kubectl logs -n namespace-dev deployment/backend-deployment -f
```

## 🔌 Access Services

### Get External IPs
```bash
kubectl get svc -n namespace-dev
```

### Access Frontend
```bash
# Get frontend service external IP
FRONTEND_IP=$(kubectl get svc frontend-service -n namespace-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend: http://$FRONTEND_IP"
```

### Access Backend
```bash
# Get backend service external IP
BACKEND_IP=$(kubectl get svc backend-service -n namespace-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Backend: http://$BACKEND_IP:8010"
```

### Port Forward (Local Development)
```bash
# Forward backend port
kubectl port-forward -n namespace-dev svc/backend-service 8010:8010

# Forward frontend port
kubectl port-forward -n namespace-dev svc/frontend-service 3000:80

# Forward database port
kubectl port-forward -n namespace-dev svc/postgres-service 5432:5432
```

## 🔐 Secrets Management

### View Secrets (Encoded)
```bash
kubectl get secret app-secrets -n namespace-dev -o yaml
```

### Update Secrets
```bash
# Delete old secret
kubectl delete secret app-secrets -n namespace-dev

# Create new secret (interactive)
kubectl create secret generic app-secrets \
  --from-literal=DB_USER=postgres \
  --from-literal=DB_PASS=yourpassword \
  --from-literal=JWT_VERIFY_SECRET=yoursecret \
  --from-literal=JWT_SESSION_SECRET=yoursecret \
  --from-literal=SESSION_ENCRYPT_SECRET=yourencryptionsecret \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=yourpassword \
  --from-literal=POSTGRES_DB=react_auth_db \
  -n namespace-dev
```

## 🔧 Configuration Management

### View ConfigMap
```bash
kubectl get configmap app-config -n namespace-dev -o yaml
```

### Update ConfigMap
```bash
kubectl edit configmap app-config -n namespace-dev
```

## 📊 Scaling

### Scale Backend Replicas
```bash
kubectl scale deployment backend-deployment --replicas=3 -n namespace-dev
```

### Scale Frontend Replicas
```bash
kubectl scale deployment frontend-deployment --replicas=3 -n namespace-dev
```

### Auto-scaling (HPA)
```bash
kubectl autoscale deployment backend-deployment --min=2 --max=5 --cpu-percent=80 -n namespace-dev
```

## 🗑️ Delete Resources

### Delete Everything
```bash
kubectl delete namespace namespace-dev
```

### Delete Specific Resources
```bash
kubectl delete deployment backend-deployment -n namespace-dev
kubectl delete service backend-service -n namespace-dev
kubectl delete pvc postgres-pvc -n namespace-dev
```

## 🧪 Testing Deployment

### Check Pod Status
```bash
kubectl describe pod -n namespace-dev <pod-name>
```

### Execute Commands in Pod
```bash
# Bash in backend pod
kubectl exec -it -n namespace-dev deployment/backend-deployment -- sh

# Bash in database pod
kubectl exec -it -n namespace-dev deployment/postgres-deployment -- bash

# Check database connection
kubectl exec -it -n namespace-dev deployment/postgres-deployment -- psql -U postgres -c "SELECT version();"
```

### Test Backend Health
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh

# From inside the debug pod:
curl http://backend-service.namespace-dev.svc.cluster.local:8010/api/v1/auth/check-auth
```

## 📈 Monitoring and Logs

### View Events
```bash
kubectl get events -n namespace-dev
kubectl get events -n namespace-dev --sort-by='.lastTimestamp'
```

### Get Pod Details
```bash
kubectl describe pod -n namespace-dev <pod-name>
```

### Check Resource Usage
```bash
kubectl top pod -n namespace-dev
kubectl top node
```

## 🔄 Rolling Updates

### Update Image
```bash
kubectl set image deployment/backend-deployment backend=yourregistry/backend:v2 -n namespace-dev
```

### Rollback
```bash
kubectl rollout history deployment/backend-deployment -n namespace-dev
kubectl rollout undo deployment/backend-deployment -n namespace-dev
kubectl rollout undo deployment/backend-deployment --to-revision=1 -n namespace-dev
```

## 🐛 Troubleshooting

### Pod Stuck in Pending
```bash
kubectl describe pod <pod-name> -n namespace-dev
# Check: resource requests, PVC availability, node capacity
```

### Pod Crash Loop
```bash
kubectl logs <pod-name> -n namespace-dev
# Check: application errors, missing environment variables
```

### Database Connection Error
```bash
kubectl logs -n namespace-dev deployment/backend-deployment
# Check: DB_HOST points to postgres-service.namespace-dev.svc.cluster.local
```

### Service Not Accessible
```bash
kubectl get svc -n namespace-dev
kubectl get endpoints -n namespace-dev
# Check: service selector matches pod labels
```

## 📝 Important Notes

1. **Images**: Update image references in deployments to use Docker registry
2. **Storage**: hostPath PV requires node directory. Change for production
3. **Replicas**: Adjust replicas based on load
4. **Resources**: Adjust CPU/Memory requests and limits
5. **Secrets**: Never commit secrets.yaml to git (use sealed-secrets or external-secrets)
6. **Environment**: Update ConfigMap/Secrets for production values

## 🏭 Production Considerations

- Use private Docker registry
- Use sealed-secrets or external-secrets operator
- Configure ingress instead of LoadBalancer
- Set up persistent volumes properly
- Configure resource quotas and limits
- Set up network policies
- Enable RBAC
- Configure monitoring and alerting
- Use namespaces for multi-tenancy
- Configure pod disruption budgets

## 📚 Useful Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
