# 🚀 CI/CD Pipeline Documentation

## Overview

This CI/CD pipeline automatically builds, tests, and deploys the application to different Kubernetes namespaces based on branch naming conventions.

## Branch → Environment Mapping

| Branch Pattern | Namespace | Environment | Use Case |
|----------------|-----------|-------------|----------|
| `master` / `main` | `dev` | Development | Active development, testing |
| `pre-release/v*` | `preprod` | Pre-production | Staging, QA testing |
| `release/v*` | `release` | Production | Live production environment |

## Pipeline Stages

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Build &   │────▶│  Docker Build   │────▶│    Deploy to    │
│    Test     │     │   & Push        │     │   Kubernetes    │
└─────────────┘     └─────────────────┘     └─────────────────┘
      │                    │                       │
      ▼                    ▼                       ▼
 • npm install         • Build images         • Apply manifests
 • npm run build       • Tag with SHA         • Update deployments
 • npm test           • Push to registry      • Verify rollout
```

## Image Tagging Strategy

Images are tagged with: `<branch-name>-<short-commit-sha>`

Examples:
- `main-a1b2c3d`
- `pre-release-v1.0-e4f5g6h`
- `release-v1.0-i7j8k9l`

This allows:
- Easy identification of which commit is deployed
- Simple rollback to any previous version
- Multiple versions coexisting in the registry

---

## 🔐 Secrets Management

### Required GitHub Secrets

Configure these in: **Repository → Settings → Secrets and variables → Actions**

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKER_USERNAME` | Docker Hub username | `mamunurrashid123` |
| `DOCKER_PASSWORD` | Docker Hub access token | `dckr_pat_xxx` |
| `KUBE_CONFIG` | Base64 encoded kubeconfig | See below |

### How to Generate KUBE_CONFIG Secret

```bash
# 1. Get your kubeconfig
cat ~/.kube/config

# 2. Base64 encode it
cat ~/.kube/config | base64 -w 0

# 3. Copy the output and add as KUBE_CONFIG secret in GitHub
```

### Security Best Practices

1. **Use Docker Access Tokens** instead of passwords
   ```
   Docker Hub → Account Settings → Security → New Access Token
   ```

2. **Use service account for Kubernetes**
   ```bash
   # Create a service account for CI/CD
   kubectl create serviceaccount github-actions -n kube-system
   kubectl create clusterrolebinding github-actions-admin \
     --clusterrole=cluster-admin \
     --serviceaccount=kube-system:github-actions
   ```

3. **Rotate secrets regularly**

4. **Use GitHub Environments** for additional protection
   - Require approval for production deployments
   - Add environment-specific secrets

---

## 🔄 Rollback Strategy

### Method 1: Kubernetes Rollout Undo (Recommended)

```bash
# View deployment history
kubectl rollout history deployment/backend-deployment -n dev

# Rollback to previous version
kubectl rollout undo deployment/backend-deployment -n dev

# Rollback to specific revision
kubectl rollout undo deployment/backend-deployment -n dev --to-revision=2

# Check rollback status
kubectl rollout status deployment/backend-deployment -n dev
```

### Method 2: Re-deploy Previous Image Tag

```bash
# Find previous image tags in Docker Hub or GitHub Actions history

# Update deployment with previous tag
kubectl set image deployment/backend-deployment \
  backend=mamunurrashid123/react-auth-backend:main-abc1234 \
  -n dev

# Or edit deployment directly
kubectl edit deployment/backend-deployment -n dev
```

### Method 3: Re-run Previous GitHub Actions Workflow

1. Go to **Actions** tab in GitHub
2. Find the successful workflow run you want to rollback to
3. Click **Re-run all jobs**

### Rollback Verification

```bash
# Check current image
kubectl get deployment backend-deployment -n dev -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check pod status
kubectl get pods -n dev -l app=backend

# Check logs
kubectl logs -f deployment/backend-deployment -n dev
```

---

## 🛡️ Safety Features

### Deployment Safeguards

1. **Build validation before deployment**
   - Tests must pass
   - Docker build must succeed

2. **Rollout status check**
   - Pipeline waits for successful rollout
   - Fails if deployment doesn't become ready

3. **Health checks**
   - Kubernetes liveness/readiness probes
   - Automatic pod restart on failure

### Adding Manual Approval (Production)

```yaml
# Add to deploy job for production
environment:
  name: production
  url: https://your-app.com

# Configure in GitHub:
# Settings → Environments → production → Required reviewers
```

---

## 🔧 Troubleshooting

### Pipeline Fails at Docker Push

```bash
# Check Docker credentials
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# Verify image exists
docker images | grep react-auth
```

### Pipeline Fails at Kubernetes Deploy

```bash
# Test kubeconfig locally
export KUBECONFIG=~/.kube/config
kubectl get nodes

# Check namespace exists
kubectl get namespace dev

# Check pod events
kubectl describe pod -n dev -l app=backend
```

### Deployment Not Updating

```bash
# Force rollout restart
kubectl rollout restart deployment/backend-deployment -n dev

# Check image pull policy
kubectl get deployment backend-deployment -n dev -o yaml | grep imagePullPolicy
```

