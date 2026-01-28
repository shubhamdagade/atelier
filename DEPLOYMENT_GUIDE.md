# Atelier MEP Portal - Cloud Run Deployment Guide

## 📋 Overview

This guide provides step-by-step instructions to containerize and deploy the Atelier MEP Portal to Google Cloud Run with enterprise security.

**Key Features:**
- ✅ Multi-stage Docker build (Vite + Express on port 8080)
- ✅ Public access to login page (`--allow-unauthenticated`)
- ✅ Firebase Admin SDK for token verification on all `/api/*` routes
- ✅ Role-based access control (L1, L2, L3, L4, SUPER_ADMIN)
- ✅ Secure secrets management with Google Secret Manager
- ✅ Auto-scaling and high availability

---

## 🔐 Security Architecture

### Public Access
- Login page (frontend) - `--allow-unauthenticated`
- `/api/health` endpoint - For health checks
- All other routes - **Requires valid Firebase ID token**

### Private Access
- All `/api/*` routes (except `/api/health`) - Protected by Firebase Auth
- Token verification happens in `verifyToken` middleware
- User role checked in `requireRole()` middleware

### Token Flow
```
1. User logs in via Firebase -> Gets ID token
2. Frontend sends requests with: Authorization: Bearer <idToken>
3. Backend verifies token with Firebase Admin SDK
4. Checks user role from database
5. Allows/denies access based on role
```

---

## 📦 Prerequisites

Before deploying, ensure you have:

1. **Google Cloud Project** with billing enabled
2. **gcloud CLI** installed locally
3. **Docker** installed locally
4. **Firebase Project** configured (with Admin SDK credentials)
5. **Cloud SQL PostgreSQL database** (or equivalent)
6. **Service account** with roles:
   - Cloud Run Admin
   - Cloud SQL Client
   - Secret Manager Secret Accessor
   - Artifact Registry Writer

### Install gcloud CLI
```bash
# macOS
brew install --cask google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Windows
# Download from: https://cloud.google.com/sdk/docs/install-gcloud-cli
```

### Login to GCP
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

---

## 🔑 Step 1: Setup Firebase Admin Credentials

### Option A: Store Credentials in Secret Manager (Recommended)

**1. Download Firebase Admin SDK Key:**
- Go to Firebase Console → Project Settings → Service Accounts
- Click "Generate New Private Key"
- Save as `firebase-admin-key.json`

**2. Create Secret in Google Secret Manager:**
```bash
# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com

# Create secret from JSON file
gcloud secrets create firebase-admin-sdk \
  --replication-policy="automatic" \
  --data-file=firebase-admin-key.json

# Verify secret created
gcloud secrets list
gcloud secrets versions access latest --secret=firebase-admin-sdk
```

**3. Grant Cloud Run Service Account Access:**
```bash
# Get the default Cloud Run service account email
PROJECT_ID=$(gcloud config get-value project)
CLOUD_RUN_SA="$PROJECT_ID@appspot.gserviceaccount.com"

# Grant permission to access this secret
gcloud secrets add-iam-policy-binding firebase-admin-sdk \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/secretmanager.secretAccessor"
```

### Option B: Store Credentials as Environment Variable

```bash
# Convert JSON to base64 (single line)
FIREBASE_SDK_B64=$(cat firebase-admin-key.json | jq -c . | base64 -w 0)

# Create secret
gcloud secrets create firebase-admin-sdk-b64 \
  --replication-policy="automatic" \
  --data-file=<(echo -n "$FIREBASE_SDK_B64")
```

---

## 🗄️ Step 2: Setup Cloud SQL Database

### Create Cloud SQL Instance
```bash
# Enable Cloud SQL API
gcloud services enable sqladmin.googleapis.com

# Create PostgreSQL instance (15.x recommended)
gcloud sql instances create atelier-postgres \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --availability-type=REGIONAL \
  --enable-bin-log

# Set root password
gcloud sql users set-password postgres \
  --instance=atelier-postgres \
  --password=YOUR_SECURE_PASSWORD

# Create database
gcloud sql databases create atelier \
  --instance=atelier-postgres

# Get connection name (needed later)
gcloud sql instances describe atelier-postgres --format="value(connectionName)"
# Output: PROJECT_ID:us-central1:atelier-postgres
```

### Create Cloud SQL Proxy User (for Cloud Run)
```bash
# Create database user for Cloud Run
gcloud sql users create atelier-app \
  --instance=atelier-postgres \
  --password=YOUR_APP_PASSWORD

# Grant permissions
gcloud sql instances patch atelier-postgres \
  --database-flags=cloudsql_iam_authentication=on

# Create Cloud SQL IAM user (alternative to password)
gcloud sql users create atelier-app-iam \
  --instance=atelier-postgres \
  --type=CLOUD_IAM_SERVICE_ACCOUNT \
  --service-account-id=$CLOUD_RUN_SA
```

### Store Database Credentials in Secrets
```bash
# Store database password
echo -n "YOUR_APP_PASSWORD" | \
  gcloud secrets create db-password \
    --replication-policy="automatic" \
    --data-file=-

# Store database user
echo -n "atelier-app" | \
  gcloud secrets create db-user \
    --replication-policy="automatic" \
    --data-file=-

# Store database name
echo -n "atelier" | \
  gcloud secrets create db-name \
    --replication-policy="automatic" \
    --data-file=-

# Store connection name
echo -n "PROJECT_ID:us-central1:atelier-postgres" | \
  gcloud secrets create db-connection-name \
    --replication-policy="automatic" \
    --data-file=-

# Grant access
gcloud secrets add-iam-policy-binding db-password \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding db-user \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding db-name \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding db-connection-name \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/secretmanager.secretAccessor"
```

---

## 🐳 Step 3: Build and Push Docker Image

### Build Locally (Optional - for testing)
```bash
# Build image
docker build -t atelier-mep:latest .

# Test locally
docker run -p 8080:8080 \
  -e PORT=8080 \
  -e DB_HOST=localhost \
  -e DB_USER=postgres \
  -e DB_PASSWORD=password \
  -e DB_NAME=atelier \
  atelier-mep:latest

# Visit http://localhost:8080
```

### Push to Artifact Registry (Recommended)

**1. Enable Artifact Registry API:**
```bash
gcloud services enable artifactregistry.googleapis.com
```

**2. Create Repository:**
```bash
# Create Docker repository
gcloud artifacts repositories create atelier \
  --repository-format=docker \
  --location=us-central1 \
  --description="Atelier MEP Portal"

# Configure Docker authentication
gcloud auth configure-docker us-central1-docker.pkg.dev
```

**3. Build and Push:**
```bash
PROJECT_ID=$(gcloud config get-value project)
IMAGE_NAME="us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest"

# Build with tag
docker build -t $IMAGE_NAME .

# Push to Artifact Registry
docker push $IMAGE_NAME

# Verify pushed
gcloud artifacts docker images list us-central1-docker.pkg.dev/$PROJECT_ID/atelier
```

---

## 🚀 Step 4: Deploy to Cloud Run

### Enable Required APIs
```bash
gcloud services enable run.googleapis.com
gcloud services enable vpcconnector.googleapis.com  # For Cloud SQL connection
```

### Create VPC Connector (for Cloud SQL access)
```bash
gcloud compute networks vpc-accessors create atelier-vpc \
  --region=us-central1 \
  --network=default \
  --min-instances=2 \
  --max-instances=4 \
  --machine-type=e2-micro
```

### Deploy Service
```bash
PROJECT_ID=$(gcloud config get-value project)
IMAGE_NAME="us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest"

gcloud run deploy atelier-mep \
  --image=$IMAGE_NAME \
  --platform=managed \
  --region=us-central1 \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --timeout=60 \
  --max-instances=10 \
  --min-instances=1 \
  --service-account=$CLOUD_RUN_SA \
  --vpc-connector=atelier-vpc \
  --vpc-egress=all-traffic \
  \
  --set-env-vars=NODE_ENV=production,PORT=8080 \
  \
  --set-secrets="FIREBASE_ADMIN_SDK=firebase-admin-sdk:latest,\
DB_HOST=cloud-sql-connection-name:latest,\
DB_USER=db-user:latest,\
DB_PASSWORD=db-password:latest,\
DB_NAME=db-name:latest" \
  \
  --labels=app=atelier,environment=production
```

**Alternative: Using environment variables directly**
```bash
gcloud run deploy atelier-mep \
  --image=$IMAGE_NAME \
  --allow-unauthenticated \
  --set-env-vars=NODE_ENV=production,PORT=8080,\
DB_HOST="YOUR_CLOUD_SQL_PUBLIC_IP",\
DB_USER=atelier-app,\
DB_PASSWORD=YOUR_APP_PASSWORD,\
DB_NAME=atelier \
  ... [other flags]
```

### Get Service URL
```bash
gcloud run services describe atelier-mep --region=us-central1 --format="value(status.url)"
# Output: https://atelier-mep-xxxxxxxxxxxx-uc.a.run.app
```

---

## ✅ Step 5: Verify Deployment

### Check Service Status
```bash
# Describe service
gcloud run services describe atelier-mep --region=us-central1

# View logs
gcloud run services logs read atelier-mep --region=us-central1 --limit=50

# Real-time logs
gcloud run services logs read atelier-mep --region=us-central1 --stream
```

### Test Endpoints
```bash
SERVICE_URL=$(gcloud run services describe atelier-mep \
  --region=us-central1 --format="value(status.url)")

# Test health check (public, no auth needed)
curl $SERVICE_URL/api/health

# Test login page (public)
curl $SERVICE_URL/

# Try accessing protected endpoint without token (should fail)
curl $SERVICE_URL/api/projects
# Response: {"error":"Unauthorized","message":"No token provided..."}

# Get Firebase ID token for testing
# (After logging in on the frontend or via Firebase REST API)
curl -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=YOUR_FIREBASE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email":"your-email@example.com",
    "password":"your-password",
    "returnSecureToken":true
  }'

# Extract "idToken" from response, then test protected endpoint
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  $SERVICE_URL/api/projects
# Response: [{"id":1,"name":"Project Name",...}]
```

---

## 🔧 Step 6: Environment Variables Configuration

### Backend Environment Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `PORT` | Literal | Must be `8080` for Cloud Run |
| `NODE_ENV` | Literal | Set to `production` |
| `FIREBASE_ADMIN_SDK` | Secret Manager | Firebase service account JSON |
| `DB_HOST` | Secret Manager OR Literal | Cloud SQL connection name or IP |
| `DB_USER` | Secret Manager | Database user (e.g., `atelier-app`) |
| `DB_PASSWORD` | Secret Manager | Database password (encrypted) |
| `DB_NAME` | Secret Manager OR Literal | Database name (e.g., `atelier`) |

### How to Pass Secrets to Cloud Run

**Method 1: Using Secret Manager (Recommended)**
```bash
gcloud run deploy atelier-mep \
  --image=$IMAGE \
  --set-secrets="FIREBASE_ADMIN_SDK=firebase-admin-sdk:latest,\
DB_USER=db-user:latest,\
DB_PASSWORD=db-password:latest"
```

**Method 2: Using Environment Variables (Less Secure)**
```bash
gcloud run deploy atelier-mep \
  --image=$IMAGE \
  --set-env-vars="FIREBASE_ADMIN_SDK='{\"type\":\"service_account\",...}',\
DB_USER=atelier-app,\
DB_PASSWORD=secure-password-here"
```

**Method 3: Using `.env` file (Development Only)**
```bash
# Create .env file locally (never commit to Git!)
cat > .env << EOF
NODE_ENV=production
PORT=8080
FIREBASE_ADMIN_SDK=$(cat firebase-admin-key.json | jq -c .)
DB_HOST=cloudsql:project:region:instance
DB_USER=atelier-app
DB_PASSWORD=secure-password
DB_NAME=atelier
EOF

# Load in development (NOT for production)
npm run dev
```

---

## 🔄 Step 7: Continuous Deployment (CI/CD)

### Using cloudbuild.yaml

Create `cloudbuild.yaml` in repository root:
```yaml
steps:
  # Step 1: Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    id: 'build'
    args: ['build', '-t', 'us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:$SHORT_SHA', '.']

  # Step 2: Push to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    id: 'push'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:$SHORT_SHA']

  # Step 3: Deploy to Cloud Run
  - name: 'gcr.io/cloud-builders/gke-deploy'
    id: 'deploy'
    args:
      - run
      - --filename=.
      - --image=us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:$SHORT_SHA
      - --location=us-central1
      - --config=cloudbuild-deploy.yaml

images:
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:$SHORT_SHA'

options:
  machineType: 'N1_HIGHCPU_8'
```

### Enable Cloud Build
```bash
gcloud services enable cloudbuild.googleapis.com

# Connect GitHub repository
gcloud builds connect --repository-name=atelier --repository-owner=ajitkumarjha-alt --region=us-central1

# Create build trigger
gcloud builds triggers create github \
  --name=atelier-deploy \
  --repo-name=atelier \
  --repo-owner=ajitkumarjha-alt \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

---

## 📊 Step 8: Monitoring & Logs

### View Logs
```bash
# Recent logs (last 50 entries)
gcloud run services logs read atelier-mep --region=us-central1 --limit=50

# Real-time streaming
gcloud run services logs read atelier-mep --region=us-central1 --stream

# JSON format (for parsing)
gcloud run services logs read atelier-mep --region=us-central1 --limit=100 --format=json
```

### Setup Alerts
```bash
# Create uptime check
gcloud monitoring uptime-checks create atelier-health \
  --display-name="Atelier Health Check" \
  --resource-type=uptime-url \
  --monitored-resource-path="//https://SERVICE_URL/api/health" \
  --check-interval=60
```

### Custom Metrics
Add to backend logs:
```javascript
// Log usage metrics
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration_ms: duration,
      user_level: req.user?.userLevel || 'anonymous'
    }));
  });
  next();
});
```

---

## 🆘 Troubleshooting

### Issue: "Permission denied" when accessing secrets
```bash
# Verify service account permissions
gcloud secrets get-iam-policy firebase-admin-sdk

# Grant access again
gcloud secrets add-iam-policy-binding firebase-admin-sdk \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/secretmanager.secretAccessor"
```

### Issue: Cloud Run can't connect to Cloud SQL
```bash
# Verify VPC connector exists
gcloud compute networks vpc-accessors list --region=us-central1

# Check Cloud SQL instance is accessible
gcloud sql instances describe atelier-postgres

# Re-deploy with VPC connector
gcloud run deploy atelier-mep \
  --image=$IMAGE \
  --vpc-connector=atelier-vpc \
  --vpc-egress=all-traffic
```

### Issue: "Firebase Admin SDK not initialized"
```bash
# Verify secret contains valid JSON
gcloud secrets versions access latest --secret=firebase-admin-sdk | head -c 100

# Verify service account has secretAccessor role
gcloud secrets get-iam-policy firebase-admin-sdk | grep $CLOUD_RUN_SA

# Verify environment variable name matches
grep "FIREBASE_ADMIN_SDK" server/index.js
```

### Issue: Database connection fails
```bash
# Test Cloud SQL connection locally
gcloud sql connect atelier-postgres --user=atelier-app

# Check database credentials in Cloud Run
gcloud run services describe atelier-mep --region=us-central1 --format=json | jq '.spec.template.spec.containers[0].env'

# Verify database user exists and has permissions
gcloud sql users list --instance=atelier-postgres
```

---

## 📝 Summary of Deployment Process

| Step | Command | Purpose |
|------|---------|---------|
| 1 | Create secrets in Secret Manager | Store credentials securely |
| 2 | Setup Cloud SQL PostgreSQL | Create production database |
| 3 | Build Docker image | Create containerized app |
| 4 | Push to Artifact Registry | Store container image |
| 5 | Deploy to Cloud Run | Launch service publicly |
| 6 | Configure environment vars | Connect secrets to service |
| 7 | Setup CI/CD pipeline | Auto-deploy on git push |
| 8 | Monitor logs and alerts | Observe service health |

---

## 🔒 Security Checklist

- ✅ Firebase Admin SDK stored in Secret Manager (encrypted)
- ✅ Database credentials stored in Secret Manager
- ✅ All `/api/*` routes protected by Firebase token verification
- ✅ Role-based access control enforced on backend
- ✅ Cloud Run service allows unauthenticated access only to login page
- ✅ Cloud SQL instance has public IP disabled (private network only)
- ✅ VPC connector restricts Cloud Run to internal database network
- ✅ Logs are centralized in Cloud Logging (audit trail)
- ✅ Service account has minimum required permissions
- ✅ HTTPS enforced by Cloud Run (automatic)
- ✅ CORS configured for frontend domain

---

## 🎯 Next Steps

1. **Test Deployment:**
   - Login at https://YOUR_CLOUD_RUN_URL
   - Verify projects load correctly
   - Test role-based access restrictions

2. **Configure Domain:**
   ```bash
   gcloud run services update atelier-mep \
     --platform=managed \
     --region=us-central1 \
     --update-env-vars=FRONTEND_URL=https://your-domain.com
   ```

3. **Setup SSL Certificate:**
   - Cloud Run automatically uses HTTPS
   - Configure custom domain in Cloud Run console

4. **Scale Configuration:**
   - Adjust `--min-instances` and `--max-instances` based on traffic
   - Monitor CPU/memory usage in Cloud Run metrics

5. **Backup Database:**
   ```bash
   gcloud sql backups create \
     --instance=atelier-postgres \
     --description="Daily backup"
   ```

---

**Last Updated:** January 28, 2026  
**Version:** 1.0  
**Status:** Production Ready ✅
