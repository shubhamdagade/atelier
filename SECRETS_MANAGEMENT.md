# Atelier MEP Portal - Secrets & Environment Variables Management

## 🔐 Overview

This guide explains how to securely manage all sensitive configuration data (credentials, keys, database passwords) for Atelier MEP Portal on Google Cloud Run.

---

## 📋 Environment Variables Checklist

### Frontend Environment Variables
The frontend doesn't require secrets as it's served as static files. All sensitive data stays on backend.

### Backend Environment Variables

| Variable | Required | Type | Source | Example |
|----------|----------|------|--------|---------|
| `PORT` | ✅ Yes | Literal | Set to `8080` | `8080` |
| `NODE_ENV` | ✅ Yes | Literal | Set for environment | `production` |
| `FIREBASE_ADMIN_SDK` | ✅ Yes | Secret | Secret Manager | `{"type":"service_account",...}` |
| `DB_HOST` | ✅ Yes | Secret | Secret Manager | `project:region:instance` |
| `DB_USER` | ✅ Yes | Secret | Secret Manager | `atelier-app` |
| `DB_PASSWORD` | ✅ Yes | Secret | Secret Manager | `secure-random-password` |
| `DB_NAME` | ✅ Yes | Secret | Secret Manager | `atelier` |
| `FIREBASE_API_KEY` | ❌ Optional | Literal | Firebase Console | `AIzaSyD...` |
| `FRONTEND_URL` | ❌ Optional | Literal | Your domain | `https://atelier.company.com` |

---

## 🔑 Part 1: Firebase Admin SDK Credentials

### Step 1a: Download Firebase Admin Key

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Atelier project
3. Navigate to **Project Settings** (gear icon) → **Service Accounts** tab
4. Click **Generate New Private Key**
5. Save as `firebase-admin-key.json` (keep this file LOCAL, never commit to Git)

### Step 1b: Create Google Secret Manager Secret

```bash
# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com

# Create secret from JSON file
gcloud secrets create firebase-admin-sdk \
  --replication-policy="automatic" \
  --data-file=firebase-admin-key.json

# Verify secret created (first 100 chars)
gcloud secrets versions access latest --secret=firebase-admin-sdk | head -c 100
```

### Step 1c: Grant Cloud Run Access

```bash
PROJECT_ID=$(gcloud config get-value project)
CLOUD_RUN_SA="$PROJECT_ID@appspot.gserviceaccount.com"

gcloud secrets add-iam-policy-binding firebase-admin-sdk \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/secretmanager.secretAccessor"

# Verify binding
gcloud secrets get-iam-policy firebase-admin-sdk
```

### Step 1d: Reference in Cloud Run Deployment

```bash
gcloud run deploy atelier-mep \
  --image=... \
  --set-secrets="FIREBASE_ADMIN_SDK=firebase-admin-sdk:latest" \
  ...
```

---

## 🗄️ Part 2: Database Credentials

### Step 2a: Setup Cloud SQL PostgreSQL

```bash
# Enable Cloud SQL API
gcloud services enable sqladmin.googleapis.com

# Create instance
gcloud sql instances create atelier-postgres \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --availability-type=REGIONAL

# Create database
gcloud sql databases create atelier --instance=atelier-postgres

# Set root password
gcloud sql users set-password postgres \
  --instance=atelier-postgres \
  --password=ROOT_PASSWORD_HERE
```

### Step 2b: Create Application User

**Option A: Password-based (Simpler)**
```bash
# Create user with password
gcloud sql users create atelier-app \
  --instance=atelier-postgres \
  --password=APP_PASSWORD_HERE

# Grant connect permission
gcloud sql instances patch atelier-postgres \
  --database-flags=cloudsql_iam_authentication=on
```

**Option B: IAM-based (More Secure)**
```bash
PROJECT_ID=$(gcloud config get-value project)
CLOUD_RUN_SA="$PROJECT_ID@appspot.gserviceaccount.com"

# Create IAM user
gcloud sql users create atelier-app-iam \
  --instance=atelier-postgres \
  --type=CLOUD_IAM_SERVICE_ACCOUNT \
  --service-account-id=$CLOUD_RUN_SA

# Enable IAM authentication
gcloud sql instances patch atelier-postgres \
  --database-flags=cloudsql_iam_authentication=on
```

### Step 2c: Store Database Credentials in Secrets

```bash
# Store database host (connection name: PROJECT_ID:REGION:INSTANCE)
PROJECT_ID=$(gcloud config get-value project)
DB_CONNECTION_NAME="$PROJECT_ID:us-central1:atelier-postgres"

echo -n "$DB_CONNECTION_NAME" | \
  gcloud secrets create db-connection-name \
    --replication-policy="automatic" \
    --data-file=-

# Store database name
echo -n "atelier" | \
  gcloud secrets create db-name \
    --replication-policy="automatic" \
    --data-file=-

# Store database user
echo -n "atelier-app" | \
  gcloud secrets create db-user \
    --replication-policy="automatic" \
    --data-file=-

# Store database password (ONLY if using password-based auth)
echo -n "YOUR_APP_PASSWORD_HERE" | \
  gcloud secrets create db-password \
    --replication-policy="automatic" \
    --data-file=-

# Verify secrets created
gcloud secrets list --filter="db-"
```

### Step 2d: Grant Cloud Run Access to Database Secrets

```bash
PROJECT_ID=$(gcloud config get-value project)
CLOUD_RUN_SA="$PROJECT_ID@appspot.gserviceaccount.com"

for secret in db-connection-name db-name db-user db-password; do
  gcloud secrets add-iam-policy-binding $secret \
    --member="serviceAccount:$CLOUD_RUN_SA" \
    --role="roles/secretmanager.secretAccessor"
done

# Verify bindings
gcloud secrets get-iam-policy db-password
```

### Step 2e: Reference in Cloud Run Deployment

```bash
gcloud run deploy atelier-mep \
  --image=... \
  --set-secrets=\
"DB_HOST=db-connection-name:latest,\
DB_NAME=db-name:latest,\
DB_USER=db-user:latest,\
DB_PASSWORD=db-password:latest" \
  ...
```

---

## 🌐 Part 3: Firebase Web Configuration (Frontend)

### Step 3a: Get Firebase Web Config

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select Atelier project
3. Project Settings → **Your apps** section
4. Click your web app → Copy config
5. Should look like:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyD...",
  authDomain: "atelier-xxx.firebaseapp.com",
  projectId: "atelier-xxx",
  storageBucket: "atelier-xxx.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc..."
};
```

### Step 3b: Update Frontend Firebase Configuration

Update [src/lib/firebase.js](src/lib/firebase.js):
```javascript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyD_INSERT_YOUR_API_KEY_HERE",
  authDomain: "atelier-xxx.firebaseapp.com",
  projectId: "atelier-xxx",
  storageBucket: "atelier-xxx.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc..."
};

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
```

⚠️ **Note:** Firebase Web config is NOT sensitive (it's embedded in frontend code). The sensitive part is the API key which is restricted to specific domains in Firebase Console.

---

## 🔗 Part 4: Cloud SQL Connection String

### Build Connection String for Cloud Run

Cloud Run can connect to Cloud SQL via:

**Option A: Cloud SQL Auth Proxy (Automatic)**
```
postgresql://atelier-app:PASSWORD@/atelier?host=/cloudsql/PROJECT_ID:REGION:INSTANCE
```

**Option B: TCP Connection (Public IP)**
```
postgresql://atelier-app:PASSWORD@CLOUD_SQL_PUBLIC_IP:5432/atelier
```

**Option C: Unix Socket (VPC Connector)**
```
postgresql://atelier-app:PASSWORD@/atelier?hostaddr=/cloudsql/PROJECT_ID:REGION:INSTANCE
```

### Update Connection in Backend

Backend code in [server/db.js](server/db.js) uses environment variables:
```javascript
import pkg from 'pg';
const { Pool } = pkg;

const pool = new Pool({
  host: process.env.DB_HOST,      // e.g., project:region:instance
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER,      // e.g., atelier-app
  password: process.env.DB_PASSWORD,  // from Secret Manager
  database: process.env.DB_NAME,   // e.g., atelier
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});
```

---

## 📝 Part 5: Environment Variable References

### Complete Deployment Command Template

```bash
PROJECT_ID=$(gcloud config get-value project)
IMAGE="us-central1-docker.pkg.dev/$PROJECT_ID/atelier/atelier-mep:latest"
CLOUD_RUN_SA="$PROJECT_ID@appspot.gserviceaccount.com"

gcloud run deploy atelier-mep \
  --image=$IMAGE \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated \
  \
  # Literal environment variables
  --set-env-vars=\
"NODE_ENV=production,\
PORT=8080,\
FIREBASE_API_KEY=AIzaSyD_YOUR_KEY_HERE,\
FRONTEND_URL=https://atelier.company.com" \
  \
  # Secret environment variables (from Secret Manager)
  --set-secrets=\
"FIREBASE_ADMIN_SDK=firebase-admin-sdk:latest,\
DB_HOST=db-connection-name:latest,\
DB_USER=db-user:latest,\
DB_PASSWORD=db-password:latest,\
DB_NAME=db-name:latest" \
  \
  # Resource limits
  --memory=512Mi \
  --cpu=1 \
  --timeout=60 \
  --max-instances=10 \
  --min-instances=1 \
  \
  # Networking
  --service-account=$CLOUD_RUN_SA \
  --vpc-connector=atelier-vpc \
  --vpc-egress=all-traffic \
  \
  # Labels
  --labels=app=atelier,environment=production
```

---

## 🔄 Part 6: Updating Secrets

### Update Firebase Admin SDK
```bash
gcloud secrets versions add firebase-admin-sdk \
  --data-file=firebase-admin-key.json

# New version becomes :latest automatically
gcloud secrets list --format="table(name, created, updated)"
```

### Update Database Password
```bash
# Generate new secure password
NEW_PASSWORD=$(openssl rand -base64 32)
echo "New password: $NEW_PASSWORD"

# Update Cloud SQL password
gcloud sql users set-password atelier-app \
  --instance=atelier-postgres \
  --password=$NEW_PASSWORD

# Update secret
echo -n "$NEW_PASSWORD" | \
  gcloud secrets versions add db-password \
    --data-file=-

# Restart Cloud Run service to reload secrets
gcloud run deploy atelier-mep \
  --image=CURRENT_IMAGE \
  --region=us-central1 \
  --no-gen2
```

### View Secret Version History
```bash
# List all versions of a secret
gcloud secrets versions list firebase-admin-sdk

# View specific version (not latest)
gcloud secrets versions access v1 --secret=firebase-admin-sdk

# Delete old version if needed
gcloud secrets versions destroy v0 --secret=firebase-admin-sdk
```

---

## 🛡️ Part 7: Security Best Practices

### ✅ DO:
- ✅ Store all sensitive data in Secret Manager
- ✅ Use `--set-secrets` flag in Cloud Run deployment
- ✅ Rotate secrets regularly (passwords every 90 days)
- ✅ Use service accounts with minimal permissions
- ✅ Enable Secret Manager audit logging
- ✅ Keep local key files in `.gitignore`
- ✅ Use IAM authentication when possible (avoid passwords)

### ❌ DON'T:
- ❌ Commit sensitive files to Git (firebase-admin-key.json, .env)
- ❌ Hardcode secrets in code
- ❌ Use `--set-env-vars` for secrets (use `--set-secrets` instead)
- ❌ Share secret files via email or chat
- ❌ Use weak passwords for database users
- ❌ Grant unnecessary service account permissions
- ❌ Log or print secret values

### Secret Rotation Checklist
- [ ] Generate new Firebase Admin Key
- [ ] Upload new key to Secret Manager
- [ ] Generate new database password
- [ ] Update database user password
- [ ] Update Secret Manager with new password
- [ ] Redeploy Cloud Run service
- [ ] Delete old keys from local machine
- [ ] Verify service still works with new secrets

---

## 🔍 Part 8: Debugging Secrets Issues

### Verify Secret Exists
```bash
gcloud secrets describe firebase-admin-sdk
gcloud secrets versions list firebase-admin-sdk
```

### Check Service Account Has Access
```bash
gcloud secrets get-iam-policy firebase-admin-sdk

# Should show:
# serviceAccount: PROJECT_ID@appspot.gserviceaccount.com
# roles: roles/secretmanager.secretAccessor
```

### View Cloud Run Environment Variables
```bash
gcloud run services describe atelier-mep \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env[*])"
```

### Check Cloud Run Logs for Secret Errors
```bash
gcloud run services logs read atelier-mep \
  --region=us-central1 \
  --limit=50 \
  | grep -i "secret\|permission\|authentication"
```

### Test Secret Access from Cloud Run
```bash
# SSH into a running revision (if enabled)
gcloud run revisions exec --region=us-central1 \
  --service=atelier-mep \
  -- /bin/sh

# Inside container, test environment variable
echo $FIREBASE_ADMIN_SDK | head -c 100
```

---

## 📊 Part 9: Secret Monitoring & Audit

### Enable Secret Manager Audit Logging
```bash
# Grant Cloud Run service account audit logging role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$CLOUD_RUN_SA" \
  --role="roles/logging.logWriter"

# View audit logs
gcloud logging read "resource.type=secretmanager.googleapis.com" \
  --limit=50 \
  --format=json
```

### Create Secret Access Alerts
```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Secret Manager Access Alert" \
  --condition-display-name="Unusual secret access" \
  --condition-expression='resource.type = "secretmanager.googleapis.com"'
```

---

## 📚 Part 10: Local Development with Secrets

### Option A: Using .env File (Development Only)

Create `.env` file (NEVER commit):
```bash
NODE_ENV=development
PORT=3001
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=atelier
FIREBASE_ADMIN_SDK=$(cat firebase-admin-key.json | jq -c .)
```

Load in development:
```bash
npm run dev
# dotenv is already in dependencies
```

### Option B: Using Export Commands

```bash
export NODE_ENV=development
export PORT=3001
export DB_HOST=localhost
export DB_USER=postgres
export DB_PASSWORD=postgres
export FIREBASE_ADMIN_SDK=$(cat firebase-admin-key.json | jq -c .)

npm run dev
```

### Option C: Using Local Docker

```bash
docker build -t atelier-dev .

docker run -p 8080:8080 \
  -e NODE_ENV=development \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e DB_NAME=atelier \
  -e FIREBASE_ADMIN_SDK="$(cat firebase-admin-key.json | jq -c .)" \
  atelier-dev
```

### .gitignore (Ensure Secrets Never Committed)
```
# Local environment files
.env
.env.local
.env.*.local

# Firebase keys
*firebase-admin-key.json
firebase-key.json

# Cloud secrets
*-credentials.json
*-service-account.json

# OS files
.DS_Store
thumbs.db
```

---

## ✅ Final Verification Checklist

Before deploying to production:

- [ ] Firebase Admin Key stored in Secret Manager
- [ ] Database credentials stored in Secret Manager
- [ ] Cloud Run service account has access to all secrets
- [ ] Dockerfile exposes port 8080
- [ ] Backend reads all environment variables from process.env
- [ ] Frontend has correct Firebase config
- [ ] Cloud SQL VPC connector configured
- [ ] Health check endpoint returns 200
- [ ] Protected endpoints return 401 without token
- [ ] Protected endpoints work with valid token
- [ ] All secrets are labeled and documented
- [ ] Audit logging enabled for secrets

---

**Last Updated:** January 28, 2026  
**Version:** 1.0  
**Status:** Production Ready ✅
