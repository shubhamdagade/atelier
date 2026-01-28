# Atelier MEP Portal - Containerization & Deployment Guide

## 🚀 Quick Start Deployment (5 minutes)

```bash
# 1. Make deployment script executable
chmod +x deploy-to-cloud-run.sh

# 2. Run automated deployment
./deploy-to-cloud-run.sh

# 3. Follow interactive prompts for setup
```

---

## 📋 What's New for Deployment

This package includes everything needed to containerize and deploy Atelier MEP Portal to Google Cloud Run:

### New Files Added
- ✅ **Dockerfile** - Multi-stage build (Vite + Express on port 8080)
- ✅ **.dockerignore** - Exclude unnecessary files from build
- ✅ **cloudbuild.yaml** - Automated CI/CD pipeline
- ✅ **DEPLOYMENT_GUIDE.md** - Complete step-by-step deployment instructions
- ✅ **SECRETS_MANAGEMENT.md** - Comprehensive secrets & environment variables guide
- ✅ **deploy-to-cloud-run.sh** - Automated deployment script

### Updated Files
- ✅ **package.json** - Added `firebase-admin` dependency
- ✅ **server/index.js** - Added Firebase Admin SDK auth middleware

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│           Google Cloud Run (Public Internet)            │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Docker Container (Multi-stage Build)             │ │
│  │                                                   │ │
│  │  Stage 1: Vite Frontend Build                     │ │
│  │  - Builds React app                              │ │
│  │  - Outputs to /dist                              │ │
│  │                                                   │ │
│  │  Stage 2: Express Backend + Static Files         │ │
│  │  - Node.js 20 Alpine runtime                     │ │
│  │  - Express.js API (port 8080)                    │ │
│  │  - Serves /dist as static files                  │ │
│  │  - Firebase Admin SDK for auth                   │ │
│  │                                                   │ │
│  └───────────────────────────────────────────────────┘ │
│                         ↕                               │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Environment & Secrets (Injected at Runtime)      │ │
│  │  - FIREBASE_ADMIN_SDK (Secret Manager)            │ │
│  │  - DB_HOST, DB_USER, DB_PASSWORD (Secrets)        │ │
│  │  - NODE_ENV=production (Literal)                  │ │
│  └───────────────────────────────────────────────────┘ │
│                         ↕                               │
│  ┌───────────────────────────────────────────────────┐ │
│  │  VPC Connector → Cloud SQL PostgreSQL             │ │
│  │  (Private network, no public IP exposed)          │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
         ↓ HTTP/HTTPS (Public Internet)
    ┌────────────────────────────────┐
    │  Users & AI Agents             │
    │  - Login page (no auth needed)  │
    │  - Protected API endpoints      │
    │  - Role-based access control    │
    └────────────────────────────────┘
```

---

## 🔐 Security Features

### Public Access (Allow Unauthenticated)
✅ **Login page** - Users can access to authenticate  
✅ **/api/health** - Health check for monitoring  

### Protected Access (Require Firebase Token)
🔒 **All /api/* routes** - Require valid Firebase ID token in Authorization header  
🔒 **User role validation** - Each request checked against database user_level  
🔒 **Database secrets** - Stored in Google Secret Manager (encrypted)  
🔒 **Firebase Admin SDK** - Verifies tokens server-side  

### Network Security
🛡️ **VPC Connector** - Cloud Run connects to Cloud SQL via private network  
🛡️ **Cloud SQL** - No public IP, only accessible via VPC  
🛡️ **HTTPS Only** - Cloud Run auto-enforces HTTPS  
🛡️ **CORS** - Configured for frontend origin  

---

## 📦 Docker Multi-Stage Build Details

### Stage 1: Frontend Builder
```dockerfile
FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci                           # Install all dependencies
COPY . ./                             # Copy source code
RUN npm run build                     # Build with Vite → /app/dist
```

### Stage 2: Production Runtime
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production         # Install only production dependencies
COPY server/ ./server/               # Copy backend code
COPY --from=frontend-builder /app/dist ./public  # Copy built frontend
# Express serves:
#   - Static files from /public (login page, assets)
#   - API endpoints via /api/*
# Listen on PORT 8080
```

**Benefits:**
- ✅ Only production dependencies in final image (~200MB vs ~400MB)
- ✅ Frontend and backend bundled together
- ✅ No need for separate Nginx server
- ✅ Single deployment unit

---

## 🚀 Step-by-Step Deployment

### Option 1: Automated Script (Recommended)
```bash
# Download Firebase Admin Key from Firebase Console
# Save as firebase-admin-key.json in project root

# Run deployment script
./deploy-to-cloud-run.sh

# Follow prompts for:
# - GCP Project ID
# - Cloud SQL instance name
# - Database credentials
```

### Option 2: Manual Step-by-Step

**1. Setup Prerequisites**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com artifactregistry.googleapis.com
```

**2. Setup Secrets**
```bash
# Create Firebase Admin SDK secret
gcloud secrets create firebase-admin-sdk \
  --data-file=firebase-admin-key.json

# Create database secrets
echo -n "your-password" | gcloud secrets create db-password --data-file=-
echo -n "project:region:instance" | gcloud secrets create db-connection-name --data-file=-
echo -n "atelier-app" | gcloud secrets create db-user --data-file=-
echo -n "atelier" | gcloud secrets create db-name --data-file=-

# Grant Cloud Run access
PROJECT_ID=$(gcloud config get-value project)
SA="$PROJECT_ID@appspot.gserviceaccount.com"
gcloud secrets add-iam-policy-binding firebase-admin-sdk \
  --member="serviceAccount:$SA" \
  --role="roles/secretmanager.secretAccessor"
```

**3. Setup Cloud SQL**
```bash
# Create PostgreSQL instance
gcloud sql instances create atelier-postgres \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1

# Create database
gcloud sql databases create atelier --instance=atelier-postgres

# Create app user
gcloud sql users create atelier-app \
  --instance=atelier-postgres \
  --password=SECURE_PASSWORD_HERE
```

**4. Build Docker Image**
```bash
docker build -t atelier-mep:latest .

# Test locally
docker run -p 8080:8080 \
  -e NODE_ENV=production \
  -e PORT=8080 \
  -e DB_HOST=localhost \
  atelier-mep:latest

# Visit http://localhost:8080
```

**5. Push to Artifact Registry**
```bash
gcloud artifacts repositories create atelier \
  --repository-format=docker \
  --location=us-central1

gcloud auth configure-docker us-central1-docker.pkg.dev

PROJECT_ID=$(gcloud config get-value project)
docker tag atelier-mep:latest \
  us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest

docker push us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest
```

**6. Deploy to Cloud Run**
```bash
PROJECT_ID=$(gcloud config get-value project)
IMAGE="us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest"

gcloud run deploy atelier-mep \
  --image=$IMAGE \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --max-instances=10 \
  --set-env-vars=NODE_ENV=production,PORT=8080 \
  --set-secrets=FIREBASE_ADMIN_SDK=firebase-admin-sdk:latest,\
DB_HOST=db-connection-name:latest,\
DB_USER=db-user:latest,\
DB_PASSWORD=db-password:latest,\
DB_NAME=db-name:latest
```

**7. Get Service URL**
```bash
gcloud run services describe atelier-mep \
  --region=us-central1 \
  --format="value(status.url)"

# Output: https://atelier-mep-xxxxx-uc.a.run.app
```

---

## 🔑 Environment Variables & Secrets

### Required Environment Variables

| Variable | Type | Source | Description |
|----------|------|--------|-------------|
| `PORT` | Literal | Set to 8080 | Cloud Run requires this |
| `NODE_ENV` | Literal | Set to production | Enables optimizations |
| `FIREBASE_ADMIN_SDK` | Secret | Secret Manager | Firebase credentials JSON |
| `DB_HOST` | Secret | Secret Manager | Cloud SQL connection name |
| `DB_USER` | Secret | Secret Manager | Database username |
| `DB_PASSWORD` | Secret | Secret Manager | Database password |
| `DB_NAME` | Secret | Secret Manager | Database name |

### How to Pass Secrets to Cloud Run

**Using Secret Manager (Recommended):**
```bash
gcloud run deploy atelier-mep \
  --image=$IMAGE \
  --set-secrets=\
"FIREBASE_ADMIN_SDK=firebase-admin-sdk:latest,\
DB_HOST=db-connection-name:latest,\
DB_USER=db-user:latest,\
DB_PASSWORD=db-password:latest,\
DB_NAME=db-name:latest"
```

**Using Environment Variables (Less Secure):**
```bash
gcloud run deploy atelier-mep \
  --image=$IMAGE \
  --set-env-vars=\
"DB_HOST=10.0.0.1,\
DB_USER=atelier-app,\
DB_PASSWORD=secure-password"
```

See **SECRETS_MANAGEMENT.md** for detailed setup instructions.

---

## 🧪 Testing Deployment

### Test Health Check
```bash
curl https://atelier-mep-xxxxx-uc.a.run.app/api/health
# Response: {"status":"ok","timestamp":"2026-01-28T..."}
```

### Test Public Access (Login Page)
```bash
curl https://atelier-mep-xxxxx-uc.a.run.app/
# Returns HTML login page
```

### Test Protected Endpoint (Without Token)
```bash
curl https://atelier-mep-xxxxx-uc.a.run.app/api/projects
# Response: {"error":"Unauthorized","message":"No token provided..."}
```

### Test Protected Endpoint (With Token)
```bash
# Get Firebase ID token (after login)
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  https://atelier-mep-xxxxx-uc.a.run.app/api/projects
# Response: [{"id":1,"name":"Project Name",...}]
```

---

## 📊 Monitoring & Logs

### View Real-Time Logs
```bash
gcloud run services logs read atelier-mep \
  --region=us-central1 \
  --stream
```

### View Last 50 Log Entries
```bash
gcloud run services logs read atelier-mep \
  --region=us-central1 \
  --limit=50
```

### Setup Uptime Monitoring
```bash
gcloud monitoring uptime-checks create atelier \
  --display-name="Atelier Health Check" \
  --resource-type=uptime-url \
  --monitored-resource-path="//https://SERVICE_URL/api/health"
```

### View Metrics
```bash
# CPU usage
gcloud monitoring metrics-list --filter="resource.type=cloud_run_revision"

# Check Cloud Run service metrics
gcloud run services describe atelier-mep \
  --region=us-central1 \
  --format=json
```

---

## 🔄 CI/CD Pipeline (Cloud Build)

Automated deployment on every git push:

```bash
# Enable Cloud Build API
gcloud services enable cloudbuild.googleapis.com

# Connect GitHub repository
gcloud builds connect \
  --repository-name=atelier \
  --repository-owner=ajitkumarjha-alt

# Create build trigger
gcloud builds triggers create github \
  --name=atelier-deploy \
  --repo-name=atelier \
  --repo-owner=ajitkumarjha-alt \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

**How it works:**
1. You push code to `main` branch
2. Cloud Build automatically:
   - Builds Docker image
   - Pushes to Artifact Registry
   - Deploys to Cloud Run
3. Service updated without manual intervention

---

## 🐳 Local Docker Testing

### Build Locally
```bash
docker build -t atelier-mep:latest .
```

### Run Locally with Database
```bash
# Using Docker Compose (create docker-compose.yml)
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: atelier
    ports:
      - "5432:5432"

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      NODE_ENV: development
      PORT: 8080
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: atelier
      FIREBASE_ADMIN_SDK: ${FIREBASE_ADMIN_SDK}
    depends_on:
      - postgres

# Start
docker-compose up
```

### Test the Container
```bash
# Health check
curl http://localhost:8080/api/health

# Login page
curl http://localhost:8080/

# Protected endpoint (should fail)
curl http://localhost:8080/api/projects
```

---

## 🔧 Troubleshooting

### Docker Build Fails
```bash
# Clean Docker cache
docker system prune -a

# Build with no cache
docker build --no-cache -t atelier-mep:latest .

# Check build output
docker build -t atelier-mep:latest . 2>&1 | tail -50
```

### Cloud Run Deployment Fails
```bash
# Check Cloud Run logs
gcloud run services logs read atelier-mep --region=us-central1 --limit=100

# View service details
gcloud run services describe atelier-mep --region=us-central1

# Verify secrets exist
gcloud secrets list | grep -E "firebase|db-"

# Check service account permissions
gcloud secrets get-iam-policy firebase-admin-sdk
```

### Database Connection Issues
```bash
# Test Cloud SQL connection
gcloud sql connect atelier-postgres --user=atelier-app

# Check database exists
gcloud sql databases list --instance=atelier-postgres

# Check user exists
gcloud sql users list --instance=atelier-postgres

# View database logs
gcloud sql operations list --instance=atelier-postgres --limit=10
```

### Service Returns 500 Errors
```bash
# Check detailed logs
gcloud run services logs read atelier-mep --region=us-central1 --stream

# Verify all secrets are loaded
gcloud run services describe atelier-mep --region=us-central1 --format=json | \
  jq '.spec.template.spec.containers[0].env'

# Test health check
curl https://SERVICE_URL/api/health -v
```

---

## 📈 Scaling & Performance

### Adjust Resource Limits
```bash
# Increase memory to 1GB
gcloud run deploy atelier-mep \
  --image=CURRENT_IMAGE \
  --region=us-central1 \
  --memory=1Gi

# Increase CPU
gcloud run deploy atelier-mep \
  --image=CURRENT_IMAGE \
  --region=us-central1 \
  --cpu=2

# Set auto-scaling limits
gcloud run deploy atelier-mep \
  --image=CURRENT_IMAGE \
  --region=us-central1 \
  --min-instances=2 \
  --max-instances=50
```

### Monitor Performance
```bash
# View request latency
gcloud monitoring read "resource.type=cloud_run_revision AND metric.type=run.googleapis.com/request_latencies"

# View concurrent requests
gcloud monitoring read "resource.type=cloud_run_revision AND metric.type=run.googleapis.com/request_count"
```

---

## 🔄 Updating Deployment

### Update Docker Image
```bash
# Make code changes
# Rebuild and push
docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest .
docker push us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest

# Deploy new version
gcloud run deploy atelier-mep \
  --image=us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest \
  --region=us-central1
```

### Update Secrets
```bash
# Update Firebase Admin SDK
gcloud secrets versions add firebase-admin-sdk \
  --data-file=firebase-admin-key.json

# Restart service to load new secret
gcloud run deploy atelier-mep \
  --image=CURRENT_IMAGE \
  --region=us-central1 \
  --no-gen2  # Force restart without changing image
```

### Rollback to Previous Version
```bash
# List revisions
gcloud run revisions list --service=atelier-mep --region=us-central1

# Route traffic to previous revision
gcloud run services update-traffic atelier-mep \
  --to-revisions=PREVIOUS_REVISION_ID=100 \
  --region=us-central1
```

---

## ✅ Deployment Checklist

Before going live:

- [ ] Docker builds without errors
- [ ] Docker image runs locally on port 8080
- [ ] Login page accessible without authentication
- [ ] Protected endpoints return 401 without token
- [ ] Protected endpoints work with valid Firebase token
- [ ] Database credentials stored in Secret Manager
- [ ] Firebase Admin SDK credentials stored in Secret Manager
- [ ] Cloud Run service account has access to all secrets
- [ ] Health check endpoint returns 200
- [ ] Service URL is accessible from public internet
- [ ] Logs show no errors
- [ ] Monitoring and alerts configured
- [ ] Backup strategy for Cloud SQL database
- [ ] SSL/HTTPS enabled (automatic)

---

## 📚 Additional Resources

- **DEPLOYMENT_GUIDE.md** - Complete step-by-step deployment walkthrough
- **SECRETS_MANAGEMENT.md** - Detailed secrets and environment variables guide
- **AI_AGENT_PROJECT_SUMMARY.md** - Project structure and architecture overview
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Google Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)

---

## 📞 Support & Debugging

If deployment fails:

1. Check **Troubleshooting** section above
2. Review **Cloud Run logs**: `gcloud run services logs read atelier-mep --stream`
3. Verify **secrets**: `gcloud secrets list | grep atelier`
4. Test **database**: `gcloud sql connect atelier-postgres --user=atelier-app`
5. Review **DEPLOYMENT_GUIDE.md** for step-by-step instructions

---

**Status:** ✅ Production Ready  
**Last Updated:** January 28, 2026  
**Version:** 1.0
