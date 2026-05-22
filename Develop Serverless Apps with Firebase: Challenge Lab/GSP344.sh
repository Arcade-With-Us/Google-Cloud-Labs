#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

gcloud auth list

# ── Project Setup ────────────────────────────────────────────
gcloud config set project $(gcloud projects list \
  --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)

# ── Dynamically Fetch Region from Lab ────────────────────────
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items.google-compute-default-region)")

# Fallback if region not detected
if [[ -z "$REGION" ]]; then
  REGION="us-east4"
fi

export REGION

export DATASET_SERVICE=netflix-dataset-service
export FRONTEND_STAGING_SERVICE=frontend-staging-service
export FRONTEND_PRODUCTION_SERVICE=frontend-production-service
export AR_REPO=rest-api-repo
export FRONTEND_REPO=frontend-repo

echo "${YELLOW_TEXT}${BOLD_TEXT}Project : $DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Region  : $REGION${RESET_FORMAT}"
echo

# Enable required APIs
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling APIs...${RESET_FORMAT}"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com

# Task 1 : Create Firestore database
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 1] Creating Firestore database in $REGION...${RESET_FORMAT}"
gcloud firestore databases create \
  --location=$REGION \
  --project=$DEVSHELL_PROJECT_ID || true
sleep 10

# Task 2 : Import CSV into Firestore
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 2] Importing Netflix CSV into Firestore...${RESET_FORMAT}"
rm -rf ~/pet-theory
git clone https://github.com/rosera/pet-theory.git

cd ~/pet-theory/lab06/firebase-import-csv/solution || exit
npm install
node index.js netflix_titles_original.csv

# Create Artifact Registry repository
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Artifact Registry repository: $AR_REPO...${RESET_FORMAT}"
gcloud artifacts repositories create $AR_REPO \
  --repository-format=docker \
  --location=$REGION \
  --description="REST API repo" || true

gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

# Task 3 : Deploy REST API v0.1
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 3] Building & Deploying REST API v0.1...${RESET_FORMAT}"
cd ~/pet-theory/lab06/firebase-rest-api/solution-01 || exit
npm install

gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.1 .

gcloud run deploy $DATASET_SERVICE \
  --image ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.1 \
  --allow-unauthenticated \
  --max-instances=1 \
  --region=$REGION \
  --quiet

SERVICE_URL=$(gcloud run services describe $DATASET_SERVICE \
  --region=$REGION \
  --format='value(status.url)')

echo "${GREEN_TEXT}Service URL: $SERVICE_URL${RESET_FORMAT}"
echo "${YELLOW_TEXT}Testing v0.1 endpoint...${RESET_FORMAT}"
curl -s $SERVICE_URL
echo

# Task 4 : Deploy REST API v0.2
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 4] Building & Deploying REST API v0.2...${RESET_FORMAT}"
cd ~/pet-theory/lab06/firebase-rest-api/solution-02 || exit
npm install

gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.2 .

gcloud run deploy $DATASET_SERVICE \
  --image ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$AR_REPO/rest-api:0.2 \
  --allow-unauthenticated \
  --max-instances=1 \
  --region=$REGION \
  --quiet

SERVICE_URL=$(gcloud run services describe $DATASET_SERVICE \
  --region=$REGION \
  --format='value(status.url)')

echo "${GREEN_TEXT}Service URL: $SERVICE_URL${RESET_FORMAT}"
echo "${YELLOW_TEXT}Testing v0.2 /2019 endpoint...${RESET_FORMAT}"
curl -s $SERVICE_URL/2019
echo

# Task 5 : Deploy Staging Frontend
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 5] Building & Deploying Staging Frontend...${RESET_FORMAT}"

gcloud artifacts repositories create $FRONTEND_REPO \
  --repository-format=docker \
  --location=$REGION \
  --description="Repository for Frontend images" || true

cd ~/pet-theory/lab06/firebase-frontend || exit

gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$FRONTEND_REPO/frontend-staging:0.1 .

gcloud run deploy $FRONTEND_STAGING_SERVICE \
  --image=${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$FRONTEND_REPO/frontend-staging:0.1 \
  --platform=managed \
  --region=$REGION \
  --allow-unauthenticated \
  --max-instances=1 \
  --quiet

STAGING_URL=$(gcloud run services describe $FRONTEND_STAGING_SERVICE \
  --region=$REGION \
  --format='value(status.url)')

# Task 6 : Deploy Production Frontend
echo
echo "${CYAN_TEXT}${BOLD_TEXT}[Task 6] Updating app.js and Deploying Production Frontend...${RESET_FORMAT}"

cd ~/pet-theory/lab06/firebase-frontend/public || exit
sed -i "s|https://netflix-dataset-service-abcdef-uc.a.run.app|$SERVICE_URL|g" app.js

cd .. || exit

gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$FRONTEND_REPO/frontend-production:0.1 .

gcloud run deploy $FRONTEND_PRODUCTION_SERVICE \
  --image=${REGION}-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$FRONTEND_REPO/frontend-production:0.1 \
  --platform=managed \
  --region=$REGION \
  --allow-unauthenticated \
  --max-instances=1 \
  --quiet

PROD_URL=$(gcloud run services describe $FRONTEND_PRODUCTION_SERVICE \
  --region=$REGION \
  --format='value(status.url)')
  
echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
