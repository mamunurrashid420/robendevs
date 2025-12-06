# ✅ Kubernetes Deployment Checklist

Complete checklist for deploying your application to Kubernetes.

## 🔧 Pre-Deployment Setup

### Local Environment
- [ ] Docker installed and running
- [ ] kubectl installed (v1.24+)
- [ ] Kubernetes cluster available (minikube, kind, or cloud cluster)
- [ ] kubectl can connect to cluster (`kubectl cluster-info`)
- [ ] Docker images built and pushed to registry (optional for local testing)

### Repository
- [ ] All Docker and Docker Compose files are clean
- [ ] Code is committed to git
- [ ] Environment variables are properly configured
- [ ] No hardcoded secrets in code

## 📋 Pre-Deployment Checklist

### Kubernetes Manifests
- [ ] All YAML files exist in `k8s/` directory
- [ ] Namespace is defined
- [ ] ConfigMap contains correct environment variables
- [ ] Secrets contain correct sensitive values
- [ ] PV/PVC created for database persistence
- [ ] Resource requests/limits are set appropriately
- [ ] Health checks (liveness/readiness probes) are configured
- [ ] Service selectors match pod labels
- [ ] Image references are correct

### Configuration Values
- [ ] Database credentials are updated in `app-secrets.yaml`
- [ ] JWT secrets are changed from defaults
- [ ] Encryption secrets are properly set
- [ ] API URLs are correct for your environment
- [ ] Image names match your Docker registry

## 🚀 Deployment Process

### Step 1: Namespace Creation
```bash
kubectl apply -f k8s/namespace-dev.yaml
```
- [ ] Namespace created successfully
- [ ] Run: `kubectl get namespace namespace-dev`

### Step 2: Configuration
```bash
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/app-secrets.yaml
```
- [ ] ConfigMap created
- [ ] Secrets created (verify with: `kubectl get secret app-secrets -n namespace-dev`)

### Step 3: Storage
```bash
kubectl apply -f k8s/postgres-pv.yaml
kubectl apply -f k8s/postgres-pvc.yaml
```
- [ ] PV created (verify: `kubectl get pv`)
- [ ] PVC created (verify: `kubectl get pvc -n namespace-dev`)
- [ ] PVC bound to PV (Status should be "Bound")

### Step 4: PostgreSQL
```bash
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
```
- [ ] PostgreSQL pod is running
- [ ] Service is created
- [ ] Port 5432 is exposed
- [ ] Database is healthy (check logs: `kubectl logs -n namespace-dev deployment/postgres-deployment`)

### Step 5: Backend
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
```
- [ ] Backend pod(s) are running (2 replicas)
- [ ] Service is created (LoadBalancer or NodePort)
- [ ] Pod logs show no errors
- [ ] Health checks are passing
- [ ] Can connect to PostgreSQL

### Step 6: Frontend
```bash
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```
- [ ] Frontend pod(s) are running (2 replicas)
- [ ] Service is created (LoadBalancer or NodePort)
- [ ] React build completes successfully
- [ ] Frontend serves on port 3000

## ✅ Post-Deployment Verification

### Pod Status
```bash
kubectl get pods -n namespace-dev
```
- [ ] All pods are in "Running" state
- [ ] No pods in "CrashLoopBackOff" or "Pending"
- [ ] Ready column shows correct counts (1/1 for single containers)

### Services
```bash
kubectl get svc -n namespace-dev
```
- [ ] All services are created
- [ ] postgres-service is ClusterIP
- [ ] backend-service is LoadBalancer/NodePort with external IP
- [ ] frontend-service is LoadBalancer/NodePort with external IP

### Logs Check
- [ ] PostgreSQL logs show no errors
  ```bash
  kubectl logs -n namespace-dev deployment/postgres-deployment
  ```
- [ ] Backend logs show server started
  ```bash
  kubectl logs -n namespace-dev deployment/backend-deployment
  ```
- [ ] Frontend logs show build completed
  ```bash
  kubectl logs -n namespace-dev deployment/frontend-deployment
  ```

### Health Checks
- [ ] Liveness probes passing
- [ ] Readiness probes passing
  ```bash
  kubectl describe pod -n namespace-dev <pod-name>
  ```

### Storage
- [ ] PVC is bound and in use
  ```bash
  kubectl get pvc -n namespace-dev
  ```
- [ ] Database has data
  ```bash
  kubectl exec -it -n namespace-dev deployment/postgres-deployment -- \
    psql -U postgres -d react_auth_db -c "\l"
  ```

## 🔌 Connectivity Testing

### Test Database Connection from Backend
```bash
kubectl exec -it -n namespace-dev deployment/backend-deployment -- sh
# Inside pod:
nc -zv postgres-service.namespace-dev.svc.cluster.local 5432
```
- [ ] Connection successful

### Test Backend API
```bash
# Option 1: Port forward
kubectl port-forward -n namespace-dev svc/backend-service 8010:8010

# Option 2: Use service external IP
BACKEND_IP=$(kubectl get svc backend-service -n namespace-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test endpoint
curl http://localhost:8010/api/v1/auth/check-auth
# or
curl http://$BACKEND_IP:8010/api/v1/auth/check-auth
```
- [ ] API responds (may return 401, that's OK)

### Test Frontend
```bash
# Get frontend service IP
FRONTEND_IP=$(kubectl get svc frontend-service -n namespace-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$FRONTEND_IP"

# Or port forward
kubectl port-forward -n namespace-dev svc/frontend-service 3000:80
echo "http://localhost:3000"
```
- [ ] Frontend loads in browser
- [ ] No console errors
- [ ] Can see login page

## 🧪 Functional Testing

### User Registration
- [ ] Navigate to signup page
- [ ] Fill in user information
- [ ] Click register
- [ ] Verify email link appears (check backend logs)
- [ ] Click verification link

### User Login
- [ ] Navigate to login page
- [ ] Enter credentials
- [ ] Verify redirect to dashboard

### Features Testing
- [ ] User can view profile
- [ ] User can update profile
- [ ] User can create skills
- [ ] User can view skills
- [ ] User can update skills
- [ ] User can delete skills
- [ ] User can logout

## 📊 Performance Monitoring

### Check Resource Usage
```bash
kubectl top pods -n namespace-dev
kubectl top nodes
```
- [ ] Memory usage is within limits
- [ ] CPU usage is reasonable
- [ ] No resource warnings

### Scaling Test
```bash
kubectl scale deployment backend-deployment --replicas=3 -n namespace-dev
```
- [ ] Additional replicas start successfully
- [ ] Load distributes across replicas
- [ ] No errors in any replica

### Scale Back
```bash
kubectl scale deployment backend-deployment --replicas=2 -n namespace-dev
```
- [ ] Replicas terminate gracefully

## 🔐 Security Checklist

### Secrets
- [ ] Secrets are stored in Kubernetes Secrets (not ConfigMap)
- [ ] Default values are changed
- [ ] Secrets file is not committed to git
- [ ] Consider using sealed-secrets for production

### Network
- [ ] Database service is ClusterIP only (not exposed externally)
- [ ] Backend/Frontend are LoadBalancer (accessible externally)
- [ ] Services have appropriate selectors

### Images
- [ ] No hardcoded credentials in images
- [ ] Images are from trusted sources
- [ ] Consider using private registry for production

## 📈 Production Readiness

### For Production Deployment:
- [ ] Use persistent volumes properly configured
- [ ] Enable RBAC and service accounts
- [ ] Configure resource quotas
- [ ] Set up monitoring and logging
- [ ] Enable network policies
- [ ] Use sealed-secrets or external-secrets
- [ ] Configure ingress with TLS
- [ ] Set up backups for database
- [ ] Enable pod disruption budgets
- [ ] Configure HPA for auto-scaling
- [ ] Set up alerting for pod failures
- [ ] Document runbooks for common issues
- [ ] Test disaster recovery procedures

## 🔄 Update/Rollback Testing

### Update Deployment
```bash
kubectl set image deployment/backend-deployment \
  backend=yourusername/backend:v2 -n namespace-dev
```
- [ ] New pods start successfully
- [ ] Old pods are terminated
- [ ] Service continues to run

### Check Rollout Status
```bash
kubectl rollout status deployment/backend-deployment -n namespace-dev
```
- [ ] Rollout completes successfully

### Rollback if Needed
```bash
kubectl rollout undo deployment/backend-deployment -n namespace-dev
```
- [ ] Rollback succeeds
- [ ] Original version runs again

## 🧹 Cleanup (When Done)

```bash
./k8s/cleanup.sh
# or
kubectl delete namespace namespace-dev
```
- [ ] Namespace is deleted
- [ ] All resources are removed
- [ ] PV is retained (for manual cleanup if needed)

## 📝 Documentation

- [ ] Updated README with deployment steps
- [ ] Documented any custom configurations
- [ ] Created runbook for common operations
- [ ] Added troubleshooting guide for team
- [ ] Documented scaling procedures

## 🆘 Troubleshooting Notes

Record any issues encountered and solutions:

| Issue | Root Cause | Solution | Status |
|-------|-----------|----------|--------|
| | | | |
| | | | |

---

## ✨ Completion

- [ ] All checks passed
- [ ] Application is fully functional
- [ ] All services are healthy
- [ ] Ready for use/production

**Deployment Date**: _______________

**Deployed By**: _______________

**Notes**: 

___________________________________________________________________

___________________________________________________________________

___________________________________________________________________

