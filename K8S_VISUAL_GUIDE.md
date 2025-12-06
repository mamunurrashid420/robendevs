# Kubernetes Deployment Visual Guide

## 📊 Complete System Overview

```
YOUR APPLICATION INFRASTRUCTURE
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              namespace-dev                              │   │
│  │                                                         │   │
│  │  ┌──────────────────┐      ┌──────────────────┐       │   │
│  │  │  FRONTEND (React) │      │  FRONTEND (React) │       │   │
│  │  │   Pod #1 - 3000   │      │   Pod #2 - 3000   │       │   │
│  │  │   (Running ✓)     │      │   (Running ✓)     │       │   │
│  │  └────────┬──────────┘      └────────┬──────────┘       │   │
│  │           │                           │                 │   │
│  │           │   Frontend Service        │                 │   │
│  │           │   (LoadBalancer)          │                 │   │
│  │           └───────┬───────────────────┘                 │   │
│  │                   │                                     │   │
│  │                   ↓ (External IP: pending)              │   │
│  │         ┌─────────────────────────┐                    │   │
│  │         │   FRONTEND EXTERNAL IP   │ → http://X.X.X.X  │   │
│  │         │   Port: 80 → 3000        │                    │   │
│  │         └─────────────────────────┘                    │   │
│  │                   ↓                                     │   │
│  │  ┌──────────────────┐      ┌──────────────────┐       │   │
│  │  │  BACKEND (Node)   │      │  BACKEND (Node)   │       │   │
│  │  │   Pod #1 - 8010   │      │   Pod #2 - 8010   │       │   │
│  │  │   (Running ✓)     │      │   (Running ✓)     │       │   │
│  │  └────────┬──────────┘      └────────┬──────────┘       │   │
│  │           │                           │                 │   │
│  │           │   Backend Service         │                 │   │
│  │           │   (LoadBalancer)          │                 │   │
│  │           └───────┬───────────────────┘                 │   │
│  │                   │                                     │   │
│  │                   ↓ (External IP: pending)              │   │
│  │         ┌─────────────────────────┐                    │   │
│  │         │   BACKEND EXTERNAL IP    │ → http://Y.Y.Y.Y  │   │
│  │         │   Port: 8010             │                    │   │
│  │         └─────────────────────────┘                    │   │
│  │                   ↓                                     │   │
│  │  ┌─────────────────────────────┐                       │   │
│  │  │    POSTGRES (Database)       │                       │   │
│  │  │    Pod - 5432                │                       │   │
│  │  │    (Running ✓)               │                       │   │
│  │  │    ├─ Database               │                       │   │
│  │  │    │  react_auth_db          │                       │   │
│  │  │    └─ User: postgres          │                       │   │
│  │  └────────┬──────────────────────┘                      │   │
│  │           │                                             │   │
│  │           │  Postgres Service                           │   │
│  │           │  (ClusterIP - Internal Only)                │   │
│  │           └─ Port: 5432                                 │   │
│  │                                                         │   │
│  │  ┌────────────────────────────────────┐               │   │
│  │  │  STORAGE                            │               │   │
│  │  │  PersistentVolume (PV)              │               │   │
│  │  │  ├─ Size: 10Gi                      │               │   │
│  │  │  ├─ Path: /mnt/data/postgres        │               │   │
│  │  │  └─ Retain on Delete                │               │   │
│  │  └────────────────────────────────────┘               │   │
│  │                                                         │   │
│  │  CONFIGURATION                                         │   │
│  │  ├─ ConfigMap: app-config (non-sensitive)             │   │
│  │  └─ Secrets: app-secrets (credentials)                │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Deployment Flow

```
1. RUN DEPLOY SCRIPT
   ./k8s/deploy.sh
        ↓
2. CREATE NAMESPACE
   kubectl apply -f k8s/namespace-dev.yaml
        ↓
3. CREATE CONFIGURATION
   ├─ ConfigMap (app-config)
   └─ Secrets (app-secrets)
        ↓
4. CREATE STORAGE
   ├─ PersistentVolume (postgres-pv)
   └─ PersistentVolumeClaim (postgres-pvc)
        ↓
5. DEPLOY DATABASE
   ├─ Deployment (postgres)
   └─ Service (postgres-service)
        ↓ (Wait for health check)
        ↓
6. DEPLOY BACKEND
   ├─ Deployment (2 replicas)
   └─ Service (LoadBalancer)
        ↓
7. DEPLOY FRONTEND
   ├─ Deployment (2 replicas)
   └─ Service (LoadBalancer)
        ↓
8. VERIFY
   kubectl get all -n namespace-dev
        ↓
DEPLOYMENT COMPLETE ✅
```

---

## 📦 Pod Lifecycle

```
NORMAL POD LIFECYCLE:
═════════════════════

Pending
  ↓ (Waiting for resources)
ContainerCreating
  ↓ (Starting container)
Running
  ↓ (Liveness + Readiness checks)
✓ Ready for traffic
  ↓ (Pod serving requests)
Running (Stable)

ON POD FAILURE:
══════════════

Running → CrashLoopBackOff
           ↓
           Restart (automatic)
           ↓
           Back to Running


WITH UPDATES:
═════════════

Running (v1)
  ↓ (New deployment triggered)
Running (v1) + Running (v2)  ← Rolling update
  ↓
Running (v2)  ← Old replicas terminated
  ↓
Ready (v2)  ← New version serving traffic
```

---

## 🔐 Data Flow (Requests)

```
USER BROWSER
    ↓
    └─ http://frontend-service-ip
        ↓
        └─ Frontend Service (LoadBalancer)
            ↓
            ├─ Routes to Frontend Pod #1
            │   ↓
            │   React App
            │   ↓
            │   Makes API call to /api/v1/auth/check-auth
            │   ↓
            │   http://backend-service:8010
            │
            └─ Routes to Frontend Pod #2
                (Same as above)

                ↓
                
        Backend Service (LoadBalancer)
            ↓
            ├─ Routes to Backend Pod #1
            │   ↓
            │   Node.js Application
            │   ↓
            │   Queries Database
            │   ↓
            │   postgres-service:5432
            │
            └─ Routes to Backend Pod #2
                (Same as above)

                ↓

        PostgreSQL Database
            ↓
            Persistent Volume
            ↓
            /mnt/data/postgres (Host filesystem)

DATABASE RESPONSE:
════════════════

PostgreSQL
    ↓
    PersistentVolume
    ↓
    Backend Pod
    ↓
    Backend Service
    ↓
    Frontend Pod
    ↓
    React Application
    ↓
    Browser
    ↓
    USER
```

---

## ⚙️ Health Check Workflow

```
POD STARTUP
═══════════

1. Container Starts
   ↓
2. Application Initializes
   (Node.js loads, connects to DB)
   ↓
3. Readiness Probe Begins
   Every 5 seconds:
   - Check /api/v1/auth/check-auth
   - Timeout: 3 seconds
   - Success: 1 check needed
   ↓
4. Status: Ready
   (Traffic can be sent)
   ↓
5. Liveness Probe Begins
   Every 10 seconds:
   - Check /api/v1/auth/check-auth
   - Timeout: 5 seconds
   - Failures: 3 consecutive = restart
   ↓
READY FOR TRAFFIC

FAILURE DETECTION:
══════════════════

Request Fails
    ↓
Liveness probe fails (3 times)
    ↓
Container is automatically restarted
    ↓
New pod takes over
    ↓
Service routes traffic to new pod
    ↓
APPLICATION RECOVERS (Automatic)
```

---

## 📊 Scaling Visualization

```
BEFORE SCALING:
═══════════════
Backend Deployment (2 replicas)
├─ Pod #1: Running
└─ Pod #2: Running

SCALE COMMAND:
kubectl scale deployment backend-deployment --replicas=4

SCALING UP (In Progress):
═════════════════════════
Backend Deployment (4 replicas)
├─ Pod #1: Running ✓
├─ Pod #2: Running ✓
├─ Pod #3: ContainerCreating
└─ Pod #4: Pending

AFTER SCALING:
══════════════
Backend Deployment (4 replicas)
├─ Pod #1: Running ✓
├─ Pod #2: Running ✓
├─ Pod #3: Running ✓
└─ Pod #4: Running ✓

Service distributes load:
├─ Pod #1: 25% traffic
├─ Pod #2: 25% traffic
├─ Pod #3: 25% traffic
└─ Pod #4: 25% traffic

SCALE DOWN:
kubectl scale deployment backend-deployment --replicas=2

├─ Pod #1: Running ✓
├─ Pod #2: Running ✓
├─ Pod #3: Terminating
└─ Pod #4: Terminating
```

---

## 🔄 Rolling Update Process

```
VERSION UPGRADE:
════════════════

Before: All Pods v1.0
├─ Pod #1: v1.0 (Running)
├─ Pod #2: v1.0 (Running)
└─ Service: Routes to v1.0

Update Command:
kubectl set image deployment/backend backend=myimage:v2

During Update: Rolling
├─ Pod #1: v1.0 (Running)
├─ Pod #2: v1.0 (Running)
├─ Pod #3: v2.0 (Starting)
└─ Service: Routes to both v1.0 and v2.0

Continuing...
├─ Pod #1: v1.0 (Terminating)
├─ Pod #2: v2.0 (Running)
├─ Pod #3: v2.0 (Running)
└─ Service: Routes to v2.0 (some v1.0)

After Update: All v2.0
├─ Pod #1: v2.0 (Running)
├─ Pod #2: v2.0 (Running)
├─ Pod #3: v2.0 (Running)
└─ Service: Routes only to v2.0

ZERO DOWNTIME ✓
No traffic loss during update!
```

---

## 🔒 Data Persistence

```
DATABASE STORAGE HIERARCHY:
═════════════════════════════

PostgreSQL Pod (Replica: 1)
    ↓
    Container: postgres:14-alpine
    ↓
    Volume Mount: /var/lib/postgresql/data
    ↓
    PersistentVolume (Type: emptyDir for dev)
    ↓
    Host Filesystem: /mnt/data/postgres
    ↓
    Data Files:
    ├─ Database Tables
    ├─ Indexes
    ├─ Write-Ahead Logs
    └─ Configuration

POD RESTART SCENARIO:
════════════════════

Scenario: Pod crashes
    ↓
Kubernetes detects crash (failed health check)
    ↓
Pod is automatically restarted
    ↓
New pod mounts same PersistentVolume
    ↓
Old data is still there! ✓
    ↓
PostgreSQL continues with existing data

POD DELETION SCENARIO:
═════════════════════

Scenario: Pod is deleted (deployment still active)
    ↓
Kubernetes controller detects missing pod
    ↓
New pod is automatically created
    ↓
New pod mounts same PersistentVolume
    ↓
All data preserved! ✓

PERSISTENCE GUARANTEE:
════════════════════

✅ Pod restarts: Data preserved
✅ Pod moves to another node: Data persists
✅ Pod deleted and recreated: Data intact
✅ Cluster update: Data available
❌ Namespace deleted: Data can be retained (depends on reclaim policy)
```

---

## 🎯 Service Types

```
POSTGRES SERVICE (ClusterIP)
════════════════════════════

Backend Pod          Frontend Pod
    ↓                    ↓
    └──→ postgres-service ←──
         (ClusterIP)
         Port: 5432
         ↓
         Only accessible INSIDE cluster
         ✓ Backend can access
         ✗ Internet cannot access
         ✓ Most secure for database


BACKEND SERVICE (LoadBalancer)
══════════════════════════════

Internet
    ↓
    └──→ backend-service (LoadBalancer)
         External IP: Y.Y.Y.Y
         External Port: 8010
         ↓
         Internal Port: 8010
         ↓
         Backend Pod #1 or #2
         ✓ Accessible from Internet
         ✓ Load balanced


FRONTEND SERVICE (LoadBalancer)
═══════════════════════════════

User Browser
    ↓
    └──→ frontend-service (LoadBalancer)
         External IP: X.X.X.X
         External Port: 80
         ↓
         Internal Port: 3000
         ↓
         Frontend Pod #1 or #2
         ✓ Accessible from Internet
         ✓ Load balanced
```

---

## 📈 Complete Request Flow

```
USER INTERACTION:
════════════════

1. User opens browser
   ↓
   http://frontend-service-ip

2. Frontend Service (LoadBalancer)
   ├─ Chooses Frontend Pod (round-robin)
   │  └─ http://X.X.X.X:80 → frontend-pod:3000
   ↓

3. React Application Loads
   ├─ User sees login form
   ├─ User enters credentials
   └─ Click "Login"
   ↓

4. API Call from Frontend
   └─ POST /api/v1/auth/login
      ↓
      http://backend-service-ip:8010
   ↓

5. Backend Service (LoadBalancer)
   ├─ Chooses Backend Pod (round-robin)
   │  └─ http://Y.Y.Y.Y:8010 → backend-pod:8010
   ↓

6. Node.js Application Processes
   ├─ Validates credentials
   ├─ Queries database
   │  └─ postgres-service:5432 → PostgreSQL
   ├─ Generates JWT token
   └─ Returns response
   ↓

7. Database Operation
   ├─ PostgreSQL Pod
   ├─ Searches tables in /mnt/data/postgres
   └─ Returns user record
   ↓

8. Response Flow (Reverse)
   ├─ Backend sends response
   ├─ Frontend receives token
   ├─ Stores in localStorage
   ├─ Redirects to dashboard
   └─ User logged in ✓
```

---

## 🚀 Deployment Summary

```
FILES DEPLOYED: 18
═════════════════

YAML Manifests: 11
├─ 1 Namespace
├─ 1 ConfigMap
├─ 1 Secret
├─ 2 Storage (PV + PVC)
├─ 2 PostgreSQL (Deployment + Service)
├─ 2 Backend (Deployment + Service)
└─ 2 Frontend (Deployment + Service)

Helper Files: 3
├─ deploy.sh (automatic deployment)
├─ cleanup.sh (remove everything)
└─ status.sh (monitor status)

Documentation: 5
├─ README.md
├─ KUBERNETES_DEPLOYMENT.md
├─ DEPLOYMENT_CHECKLIST.md
├─ FILE_INVENTORY.md
└─ K8S_SUMMARY.md

Management: 1
└─ kustomization.yaml

TOTAL PODS: 4
════════════

✓ PostgreSQL: 1 pod (stateful)
✓ Backend: 2 pods (scalable)
✓ Frontend: 2 pods (scalable)
✓ Init containers: As needed

RESOURCES ALLOCATED: ~10Gi Storage + RAM/CPU
═════════════════════════════════════════════

Database: 256Mi-512Mi RAM, 250m-500m CPU, 10Gi Storage
Backend: 256Mi-512Mi RAM, 250m-500m CPU
Frontend: 512Mi-1Gi RAM, 250m-500m CPU

SERVICES CREATED: 5
═══════════════════

✓ PostgreSQL (ClusterIP - internal)
✓ Backend (LoadBalancer - external)
✓ Frontend (LoadBalancer - external)
✓ Built-in Kubernetes DNS
✓ Health checks & monitoring

STATUS: READY FOR DEPLOYMENT ✅
════════════════════════════════

Run: ./k8s/deploy.sh
```

---

Congratulations! Your complete Kubernetes infrastructure is ready! 🎉
