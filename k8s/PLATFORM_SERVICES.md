# 🏗️ Platform Services Documentation

## Overview

This document describes the platform services architecture including Redis, RabbitMQ, Elasticsearch, and Read/Write database separation.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND SERVICE                                 │
│                           (Node.js Application)                              │
└─────────────────────────────────────────────────────────────────────────────┘
         │              │              │              │              │
         ▼              ▼              ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   Redis     │ │  RabbitMQ   │ │Elasticsearch│ │  Postgres   │ │  Postgres   │
│   Cache     │ │   Queue     │ │   Search    │ │   Primary   │ │   Replica   │
│  (Session)  │ │  (Tasks)    │ │  (Index)    │ │   (Write)   │ │   (Read)    │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
     :6379          :5672           :9200           :5432           :5432
```

## Services

### 1. Redis (Cache & Session Store)

**Purpose:**
- Session storage (fast access)
- Caching frequently accessed data
- Rate limiting counters
- Real-time features (pub/sub)

**Connection:**
```javascript
// Backend connection
const redis = require('redis');
const client = redis.createClient({
  url: `redis://${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`
});
```

**Kubernetes DNS:** `redis-service.dev.svc.cluster.local:6379`

### 2. RabbitMQ (Message Queue)

**Purpose:**
- Async task processing
- Email notifications
- Background jobs
- Microservice communication

**Connection:**
```javascript
// Backend connection
const amqp = require('amqplib');
const connection = await amqp.connect({
  hostname: process.env.RABBITMQ_HOST,
  port: process.env.RABBITMQ_PORT,
  username: process.env.RABBITMQ_USER,
  password: process.env.RABBITMQ_PASS
});
```

**Kubernetes DNS:** `rabbitmq-service.dev.svc.cluster.local:5672`

**Management UI:** `http://<node-ip>:15672` (port-forward required)

### 3. Elasticsearch (Search Engine)

**Purpose:**
- Full-text search
- Log aggregation
- Analytics
- Autocomplete

**Connection:**
```javascript
// Backend connection
const { Client } = require('@elastic/elasticsearch');
const client = new Client({
  node: `http://${process.env.ELASTICSEARCH_HOST}:${process.env.ELASTICSEARCH_PORT}`
});
```

**Kubernetes DNS:** `elasticsearch-service.dev.svc.cluster.local:9200`

**Health Check:**
```bash
curl http://elasticsearch-service:9200/_cluster/health
```

---

## 📊 Read/Write Database Separation

### Architecture

```
                    ┌─────────────────┐
                    │   Application   │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐          ┌─────────────────┐
    │  PRIMARY (Write) │─────────▶│  REPLICA (Read) │
    │  postgres-service│  Replication postgres-read │
    └─────────────────┘          └─────────────────┘
```

### Environment Variables

| Variable | Service | Purpose |
|----------|---------|---------|
| `DB_WRITE_URL` | postgres-service | INSERT, UPDATE, DELETE |
| `DB_READ_URL` | postgres-read-service | SELECT queries |

### Routing Logic

**Where routing logic lives:**

1. **Application Code (Recommended for simple setups)**
```javascript
// db/connection.js
const writePool = new Pool({ host: process.env.DB_WRITE_URL });
const readPool = new Pool({ host: process.env.DB_READ_URL });

// Usage
async function getUser(id) {
  return readPool.query('SELECT * FROM users WHERE id = $1', [id]);
}

async function createUser(data) {
  return writePool.query('INSERT INTO users ...', [data]);
}
```

2. **Database Proxy (PgBouncer, ProxySQL)**
```yaml
# Example: PgBouncer deployment
# Routes based on query type automatically
```

3. **ORM Configuration (Sequelize)**
```javascript
const sequelize = new Sequelize({
  replication: {
    read: [{ host: process.env.DB_READ_URL }],
    write: { host: process.env.DB_WRITE_URL }
  }
});
```

### Replication Lag

**What is Replication Lag?**
- Time delay between write on primary and availability on replica
- Typically milliseconds to seconds
- Can increase during high load

**Impact:**
```
User writes data → Primary updated → [LAG] → Replica updated
                                        │
                              User reads stale data
```

### Operations That MUST Hit Primary (Writer)

| Operation | Reason |
|-----------|--------|
| User registration | Immediate login required |
| Password change | Security critical |
| Payment processing | Consistency required |
| Order creation | User expects immediate confirmation |
| Session creation | Must be available immediately |
| Any read-after-write | User expects to see their changes |

### Operations Safe for Replica (Reader)

| Operation | Reason |
|-----------|--------|
| Dashboard analytics | Slight delay acceptable |
| Search results | Background indexing |
| Report generation | Historical data |
| Product listings | Cache-friendly |
| User profile view (by others) | Non-critical |

---

## 🚀 Deployment

### Deploy All Platform Services

```bash
# Apply secrets first
kubectl apply -f k8s/platform-secrets.yaml

# Deploy Redis
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/redis-service.yaml

# Deploy RabbitMQ
kubectl apply -f k8s/rabbitmq-deployment.yaml
kubectl apply -f k8s/rabbitmq-service.yaml

# Deploy Elasticsearch
kubectl apply -f k8s/elasticsearch-deployment.yaml
kubectl apply -f k8s/elasticsearch-service.yaml

# Deploy Postgres Replica
kubectl apply -f k8s/postgres-replica-deployment.yaml

# Verify
kubectl get pods -n dev
```

### Health Checks

```bash
# Redis
kubectl exec -it deployment/redis-deployment -n dev -- redis-cli ping

# RabbitMQ
kubectl exec -it deployment/rabbitmq-deployment -n dev -- rabbitmq-diagnostics check_running

# Elasticsearch
kubectl exec -it deployment/backend-deployment -n dev -- \
  curl -s http://elasticsearch-service:9200/_cluster/health

# Postgres Read
kubectl exec -it deployment/backend-deployment -n dev -- \
  nc -zv postgres-read-service 5432
```

