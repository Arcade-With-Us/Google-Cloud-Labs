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

git clone \
   https://github.com/GoogleCloudPlatform/data-science-on-gcp/

cd data-science-on-gcp/03_sqlstudio

export PROJECT_ID=$(gcloud info --format='value(config.project)')
export BUCKET=${PROJECT_ID}-ml

gsutil cp create_table.sql \
    gs://$BUCKET/create_table.sql

gcloud sql instances create flights \
    --database-version=POSTGRES_13 --cpu=2 --memory=8GiB \
    --region=$REGION --root-password=Passw0rd

export ADDRESS=$(curl -s http://ipecho.net/plain)/32

gcloud sql instances patch flights --authorized-networks $ADDRESS --quiet

export INSTANCE_NAME=flights
export DATABASE_NAME=bts
export SQL_FILE=create_table.sql

# Create a database
gcloud sql databases create $DATABASE_NAME --instance=$INSTANCE_NAME

SERVICE_ACCOUNT_EMAIL=$(gcloud sql instances describe $INSTANCE_NAME --format='value(serviceAccountEmailAddress)')

gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:roles/storage.objectViewer gs://$BUCKET

# Import the SQL file into the database
gcloud sql import sql $INSTANCE_NAME \
    gs://$BUCKET/$SQL_FILE \
    --database=$DATABASE_NAME \
    --quiet

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
