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

read -p "${CYAN_TEXT}Enter Public Billing Service name: ${RESET_FORMAT}" PUBLIC_BILLING_SERVICE
echo
read -p "${CYAN_TEXT}Enter Frontend Staging Service name: ${RESET_FORMAT}" FRONTEND_STAGING_SERVICE
echo
read -p "${CYAN_TEXT}Enter Private Billing Service name: ${RESET_FORMAT}" PRIVATE_BILLING_SERVICE
echo
read -p "${CYAN_TEXT}Enter Billing Service Account name: ${RESET_FORMAT}" BILLING_SERVICE_ACCOUNT
echo
read -p "${CYAN_TEXT}Enter Billing Prod Service name: ${RESET_FORMAT}" BILLING_PROD_SERVICE
echo
read -p "${CYAN_TEXT}Enter Frontend Service Account name: ${RESET_FORMAT}" FRONTEND_SERVICE_ACCOUNT
echo
read -p "${CYAN_TEXT}Enter Frontend Production Service name: ${RESET_FORMAT}" FRONTEND_PRODUCTION_SERVICE
echo

export PUBLIC_BILLING_SERVICE
export FRONTEND_STAGING_SERVICE
export PRIVATE_BILLING_SERVICE
export BILLING_SERVICE_ACCOUNT
export BILLING_PROD_SERVICE
export FRONTEND_SERVICE_ACCOUNT
export FRONTEND_PRODUCTION_SERVICE

echo "${BOLD_TEXT}${BLUE_TEXT}Setting up Google Cloud project environment...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set project \
$(gcloud projects list --format='value(PROJECT_ID)' \
--filter='qwiklabs-gcp')

gcloud config set run/region $REGION
gcloud config set run/platform managed
echo "${GREEN_TEXT}✓ Project configuration complete${RESET_FORMAT}"
echo "${BLUE_TEXT}Learn more at: https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"

echo "${BOLD_TEXT}${CYAN_TEXT}Fetching the source code repository...${RESET_FORMAT}"
git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07
echo "${GREEN_TEXT}✓ Repository cloned successfully${RESET_FORMAT}"

echo "${BOLD_TEXT}${YELLOW_TEXT}Deploying the Billing Staging API (v0.1)...${RESET_FORMAT}"
cd ~/pet-theory/lab07/unit-api-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.1
gcloud run deploy $PUBLIC_BILLING_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.1 --quiet
echo "${GREEN_TEXT}✓ Billing Staging API deployed${RESET_FORMAT}"

echo "${BOLD_TEXT}${MAGENTA_TEXT}Deploying the Staging Frontend...${RESET_FORMAT}"
cd ~/pet-theory/lab07/staging-frontend-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/frontend-staging:0.1
gcloud run deploy $FRONTEND_STAGING_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/frontend-staging:0.1 --quiet
echo "${GREEN_TEXT}✓ Staging Frontend deployed${RESET_FORMAT}"

echo "${BOLD_TEXT}${RED_TEXT}Deploying the Billing Staging API (v0.2 - Private)...${RESET_FORMAT}"
cd ~/pet-theory/lab07/staging-api-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.2
gcloud run deploy $PRIVATE_BILLING_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/billing-staging-api:0.2 --quiet
echo "${GREEN_TEXT}✓ Private Billing API deployed${RESET_FORMAT}"

echo "${BOLD_TEXT}${GREEN_TEXT}Provisioning the Billing IAM Service Account...${RESET_FORMAT}"
gcloud iam service-accounts create $BILLING_SERVICE_ACCOUNT --display-name "Billing Service Account Cloud Run"
echo "${GREEN_TEXT}✓ Billing Service Account created${RESET_FORMAT}"

echo "${BOLD_TEXT}${MAGENTA_TEXT}Deploying the Billing Production API...${RESET_FORMAT}"
cd ~/pet-theory/lab07/prod-api-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/billing-prod-api:0.1
gcloud run deploy $BILLING_PROD_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/billing-prod-api:0.1 --quiet
echo "${GREEN_TEXT}✓ Production Billing API deployed${RESET_FORMAT}"

echo "${BOLD_TEXT}${MAGENTA_TEXT}Provisioning the Frontend IAM Service Account...${RESET_FORMAT}"
gcloud iam service-accounts create $FRONTEND_SERVICE_ACCOUNT --display-name "Billing Service Account Cloud Run Invoker"
echo "${GREEN_TEXT}✓ Frontend Service Account created${RESET_FORMAT}"

echo "${BOLD_TEXT}${CYAN_TEXT}Deploying the Production Frontend...${RESET_FORMAT}"
cd ~/pet-theory/lab07/prod-frontend-billing
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/frontend-prod:0.1
gcloud run deploy $FRONTEND_PRODUCTION_SERVICE --image gcr.io/$DEVSHELL_PROJECT_ID/frontend-prod:0.1 --quiet
echo "${GREEN_TEXT}✓ Production Frontend deployed${RESET_FORMAT}"

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
