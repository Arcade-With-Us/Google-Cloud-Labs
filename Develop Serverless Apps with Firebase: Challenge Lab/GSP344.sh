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

export SERVICE_NAME=netflix-dataset-service

export FRNT_STG_SRV=frontend-staging-service

export FRNT_PRD_SRV=frontend-production-service

gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

gcloud services enable run.googleapis.com

gcloud firestore databases create --location=$REGION

git clone https://github.com/rosera/pet-theory.git

cd pet-theory/lab06/firebase-import-csv/solution
npm install
node index.js netflix_titles_original.csv

cd ~/pet-theory/lab06/firebase-rest-api/solution-01
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1
gcloud beta run deploy $SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 --allow-unauthenticated --region=$REGION

cd ~/pet-theory/lab06/firebase-rest-api/solution-02
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
gcloud beta run deploy $SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2 --allow-unauthenticated --region=$REGION

SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform=managed --region=$REGION --format="value(status.url)")

curl -X GET $SERVICE_URL/2019

cd ~/pet-theory/lab06/firebase-frontend/public

sed -i 's/^const REST_API_SERVICE = "data\/netflix\.json"/\/\/ const REST_API_SERVICE = "data\/netflix.json"/' app.js

sed -i "1i const REST_API_SERVICE = \"$SERVICE_URL/2020\"" app.js

npm install
cd ~/pet-theory/lab06/firebase-frontend
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1
gcloud beta run deploy $FRNT_STG_SRV --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1 --region=$REGION --quiet

gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1
gcloud beta run deploy $FRNT_PRD_SRV --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1 --region=$REGION --quiet

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
