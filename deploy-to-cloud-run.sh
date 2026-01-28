#!/bin/bash

# Atelier MEP Portal - Cloud Run Deployment Script
# This script automates the entire deployment process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Functions
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  command -v gcloud &> /dev/null || { log_error "gcloud CLI not installed"; exit 1; }
  command -v docker &> /dev/null || { log_error "Docker not installed"; exit 1; }
  
  log_success "Prerequisites checked"
}

# Set GCP project
setup_gcp_project() {
  log_info "Setting up GCP project..."
  
  if [ -z "$GCP_PROJECT_ID" ]; then
    read -p "Enter GCP Project ID: " GCP_PROJECT_ID
  fi
  
  gcloud config set project $GCP_PROJECT_ID
  log_success "GCP Project set to: $GCP_PROJECT_ID"
}

# Enable APIs
enable_apis() {
  log_info "Enabling required APIs..."
  
  gcloud services enable \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    sqladmin.googleapis.com \
    secretmanager.googleapis.com \
    cloudbuild.googleapis.com \
    vpcconnector.googleapis.com
  
  log_success "APIs enabled"
}

# Setup Firebase Admin Credentials
setup_firebase_secrets() {
  log_info "Setting up Firebase Admin credentials..."
  
  if [ ! -f "firebase-admin-key.json" ]; then
    log_warning "firebase-admin-key.json not found"
    log_info "Please download from Firebase Console → Project Settings → Service Accounts"
    read -p "Press Enter after placing firebase-admin-key.json in current directory: "
  fi
  
  if [ ! -f "firebase-admin-key.json" ]; then
    log_error "firebase-admin-key.json not found. Cannot proceed."
    exit 1
  fi
  
  # Create secret
  gcloud secrets create firebase-admin-sdk \
    --replication-policy="automatic" \
    --data-file=firebase-admin-key.json 2>/dev/null || \
  gcloud secrets versions add firebase-admin-sdk \
    --data-file=firebase-admin-key.json
  
  log_success "Firebase Admin SDK stored in Secret Manager"
}

# Setup Cloud SQL
setup_cloud_sql() {
  log_info "Setting up Cloud SQL..."
  
  read -p "Enter Cloud SQL instance name [atelier-postgres]: " DB_INSTANCE
  DB_INSTANCE=${DB_INSTANCE:-atelier-postgres}
  
  read -p "Enter database name [atelier]: " DB_NAME
  DB_NAME=${DB_NAME:-atelier}
  
  read -p "Enter app username [atelier-app]: " DB_USER
  DB_USER=${DB_USER:-atelier-app}
  
  read -sp "Enter app user password: " DB_PASSWORD
  echo
  
  # Create Cloud SQL instance if it doesn't exist
  if ! gcloud sql instances describe $DB_INSTANCE &>/dev/null; then
    log_info "Creating Cloud SQL instance..."
    gcloud sql instances create $DB_INSTANCE \
      --database-version=POSTGRES_15 \
      --tier=db-f1-micro \
      --region=us-central1 \
      --availability-type=REGIONAL
    
    log_success "Cloud SQL instance created"
  else
    log_warning "Cloud SQL instance already exists"
  fi
  
  # Create database if it doesn't exist
  gcloud sql databases create $DB_NAME \
    --instance=$DB_INSTANCE 2>/dev/null || \
    log_warning "Database already exists"
  
  # Create user if it doesn't exist
  gcloud sql users create $DB_USER \
    --instance=$DB_INSTANCE \
    --password=$DB_PASSWORD 2>/dev/null || \
    gcloud sql users set-password $DB_USER \
      --instance=$DB_INSTANCE \
      --password=$DB_PASSWORD
  
  # Get connection name
  DB_CONNECTION=$(gcloud sql instances describe $DB_INSTANCE --format="value(connectionName)")
  
  # Store in secrets
  echo -n "$DB_CONNECTION" | gcloud secrets create db-connection-name \
    --replication-policy="automatic" \
    --data-file=- 2>/dev/null || \
  echo -n "$DB_CONNECTION" | gcloud secrets versions add db-connection-name \
    --data-file=-
  
  echo -n "$DB_NAME" | gcloud secrets create db-name \
    --replication-policy="automatic" \
    --data-file=- 2>/dev/null || \
  echo -n "$DB_NAME" | gcloud secrets versions add db-name \
    --data-file=-
  
  echo -n "$DB_USER" | gcloud secrets create db-user \
    --replication-policy="automatic" \
    --data-file=- 2>/dev/null || \
  echo -n "$DB_USER" | gcloud secrets versions add db-user \
    --data-file=-
  
  echo -n "$DB_PASSWORD" | gcloud secrets create db-password \
    --replication-policy="automatic" \
    --data-file=- 2>/dev/null || \
  echo -n "$DB_PASSWORD" | gcloud secrets versions add db-password \
    --data-file=-
  
  log_success "Cloud SQL configured and secrets stored"
}

# Setup service account
setup_service_account() {
  log_info "Setting up service account..."
  
  # Get or create service account
  SA_NAME="atelier-cloud-run"
  SA_EMAIL="$SA_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com"
  
  if ! gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
    gcloud iam service-accounts create $SA_NAME \
      --display-name="Atelier Cloud Run Service Account"
  fi
  
  # Grant required roles
  gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/cloudsql.client"
  
  gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/secretmanager.secretAccessor"
  
  gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/logging.logWriter"
  
  # Grant secret access
  for secret in firebase-admin-sdk db-connection-name db-name db-user db-password; do
    gcloud secrets add-iam-policy-binding $secret \
      --member="serviceAccount:$SA_EMAIL" \
      --role="roles/secretmanager.secretAccessor" 2>/dev/null || true
  done
  
  log_success "Service account configured: $SA_EMAIL"
}

# Setup Artifact Registry
setup_artifact_registry() {
  log_info "Setting up Artifact Registry..."
  
  gcloud artifacts repositories create atelier \
    --repository-format=docker \
    --location=us-central1 \
    --description="Atelier MEP Portal" 2>/dev/null || \
    log_warning "Artifact Registry repository already exists"
  
  gcloud auth configure-docker us-central1-docker.pkg.dev
  
  log_success "Artifact Registry configured"
}

# Setup VPC Connector
setup_vpc_connector() {
  log_info "Setting up VPC connector for Cloud SQL..."
  
  gcloud compute networks vpc-accessors create atelier-vpc \
    --region=us-central1 \
    --network=default \
    --min-instances=2 \
    --max-instances=4 \
    --machine-type=e2-micro 2>/dev/null || \
    log_warning "VPC connector already exists"
  
  log_success "VPC connector ready"
}

# Build and push Docker image
build_and_push_image() {
  log_info "Building Docker image..."
  
  IMAGE_NAME="us-central1-docker.pkg.dev/$GCP_PROJECT_ID/atelier/atelier-mep:latest"
  
  docker build -t $IMAGE_NAME .
  
  log_success "Docker image built"
  
  log_info "Pushing image to Artifact Registry..."
  docker push $IMAGE_NAME
  
  log_success "Image pushed: $IMAGE_NAME"
}

# Deploy to Cloud Run
deploy_cloud_run() {
  log_info "Deploying to Cloud Run..."
  
  IMAGE_NAME="us-central1-docker.pkg.dev/$GCP_PROJECT_ID/atelier/atelier-mep:latest"
  SA_EMAIL="atelier-cloud-run@$GCP_PROJECT_ID.iam.gserviceaccount.com"
  
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
    --service-account=$SA_EMAIL \
    --vpc-connector=atelier-vpc \
    --vpc-egress=all-traffic \
    --set-env-vars=NODE_ENV=production,PORT=8080 \
    --set-secrets=FIREBASE_ADMIN_SDK=firebase-admin-sdk:latest,\
DB_HOST=db-connection-name:latest,\
DB_USER=db-user:latest,\
DB_PASSWORD=db-password:latest,\
DB_NAME=db-name:latest \
    --labels=app=atelier,environment=production
  
  log_success "Cloud Run deployment complete"
}

# Get service URL
get_service_url() {
  log_info "Retrieving service URL..."
  
  SERVICE_URL=$(gcloud run services describe atelier-mep \
    --region=us-central1 \
    --format="value(status.url)")
  
  log_success "Service URL: $SERVICE_URL"
  echo ""
  log_info "Access your application at: $SERVICE_URL"
}

# Main deployment flow
main() {
  echo -e "${BLUE}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║   Atelier MEP Portal - Cloud Run Deployment Script   ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  
  check_prerequisites
  setup_gcp_project
  enable_apis
  
  log_info "Starting deployment process..."
  echo ""
  
  setup_firebase_secrets
  setup_cloud_sql
  setup_service_account
  setup_artifact_registry
  setup_vpc_connector
  
  read -p "Ready to build and deploy Docker image? (y/n) " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    build_and_push_image
    deploy_cloud_run
    get_service_url
    
    echo ""
    log_success "🎉 Deployment complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Visit the service URL to access your application"
    echo "  2. Login with your Firebase credentials"
    echo "  3. Monitor logs: gcloud run services logs read atelier-mep --region=us-central1 --stream"
    echo ""
  else
    log_warning "Deployment cancelled"
  fi
}

# Error handling
trap 'log_error "Deployment failed"; exit 1' ERR

# Run main function
main "$@"
