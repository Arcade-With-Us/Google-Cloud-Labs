#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Initializing GKE with Cloud SQL PostgreSQL Demo...${RESET_FORMAT}"
echo

# Display current authentication
gcloud auth list

# Set zone and region
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

echo "${BLUE_TEXT}Project: $PROJECT_ID${RESET_FORMAT}"
echo "${BLUE_TEXT}Region: $REGION${RESET_FORMAT}"
echo "${BLUE_TEXT}Zone: $ZONE${RESET_FORMAT}"
echo

# Configure compute settings
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

# Download and extract demo files
echo "${GREEN_TEXT}Downloading GKE Cloud SQL PostgreSQL demo files...${RESET_FORMAT}"
gsutil cp gs://spls/gsp449/gke-cloud-sql-postgres-demo.tar.gz .
tar -xzvf gke-cloud-sql-postgres-demo.tar.gz

cd gke-cloud-sql-postgres-demo

# Get current user email for PostgreSQL admin
PG_EMAIL=$(gcloud config get-value account)
echo "${GREEN_TEXT}Setting up PostgreSQL with admin email: $PG_EMAIL${RESET_FORMAT}"

# Run the creation script
echo "${YELLOW_TEXT}Creating GKE cluster with Cloud SQL PostgreSQL...${RESET_FORMAT}"
./create.sh dbadmin $PG_EMAIL

echo "${GREEN_TEXT}Waiting for resources to be provisioned...${RESET_FORMAT}"
sleep 10

# Get pod ID and expose service
POD_ID=$(kubectl --namespace default get pods -o name | cut -d '/' -f 2)
echo "${GREEN_TEXT}Exposing pod: $POD_ID${RESET_FORMAT}"

kubectl expose pod $POD_ID --port=80 --type=LoadBalancer

echo "${GREEN_TEXT}Getting service information...${RESET_FORMAT}"
kubectl get svc

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
