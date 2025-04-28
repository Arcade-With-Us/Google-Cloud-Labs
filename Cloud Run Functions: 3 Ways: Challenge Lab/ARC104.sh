#!/bin/bash

# Bright Foreground Colors
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

read -p "Enter Function Name: " FUNCTION_NAME
echo

read -p "Enter HTTP Function Name: " HTTP_FUNCTION
echo

read -p "Enter Region: " REGION
echo


export HTTP_FUNCTION=$HTTP_FUNCTION
export FUNCTION_NAME=$FUNCTION_NAME
export REGION=$REGION

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} ========================== Enabling GCP services, please wait for 30 seconds... ========================== ${RESET_FORMAT}"
echo
sleep 30
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== GCP services enabled successfully! ========================== ${RESET_FORMAT}"
echo

PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$DEVSHELL_PROJECT_ID" --format='value(project_number)')

SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== IAM Policy Binding added successfully! ========================== ${RESET_FORMAT}"
echo

gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID

export BUCKET="gs://$DEVSHELL_PROJECT_ID"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Bucket created successfully! ========================== ${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT} ========================== Creating directory and files for cloud event trigger function... ========================== ${RESET_FORMAT}"
echo

mkdir ~/$FUNCTION_NAME && cd $_
touch index.js && touch package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.cloudEvent('$FUNCTION_NAME', (cloudevent) => {
  console.log('A new event in your Cloud Storage bucket has been logged!');
  console.log(cloudevent);
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_function() {
  gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime nodejs20 \
  --entry-point $FUNCTION_NAME \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 2 \
  --quiet
}

# Loop until the Cloud Run service is created
echo
echo "${YELLOW_TEXT}${BOLD_TEXT} ========================== Deploying Cloud Event function ... ========================== ${RESET_FORMAT}"
echo
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Run service is created
  if gcloud run services describe $FUNCTION_NAME --region $REGION &> /dev/null; then
    echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Cloud Event function deployed successfully! ========================== ${RESET_FORMAT}"
    break
  else
    echo "${YELLOW_TEXT}${BOLD_TEXT} ========================== Waiting for Cloud Event function to be created... ========================== ${RESET_FORMAT}"
    sleep 10
  fi
done

cd ..

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} ========================== Creating directory and files for HTTP trigger function... ========================== ${RESET_FORMAT}"
echo

mkdir ~/HTTP_FUNCTION && cd $_
touch index.js && touch package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.http('$HTTP_FUNCTION', (req, res) => {
  res.status(200).send('awesome lab');
});
EOF


cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_function() {
  gcloud functions deploy $HTTP_FUNCTION \
  --gen2 \
  --runtime nodejs20 \
  --entry-point $HTTP_FUNCTION \
  --source . \
  --region $REGION \
  --trigger-http \
  --timeout 600s \
  --max-instances 2 \
  --min-instances 1 \
  --quiet
}
echo
echo "${YELLOW_TEXT}${BOLD_TEXT} ========================== Deploying HTTP function ... ========================== ${RESET_FORMAT}"
echo
# Loop until the Cloud Run service is created
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Run service is created
  if gcloud run services describe $HTTP_FUNCTION --region $REGION &> /dev/null; then
    echo "${GREEN_TEXT}${BOLD_TEXT} ========================== HTTP function deployed successfully! ========================== ${RESET_FORMAT}"
    break
  else
    echo "${YELLOW_TEXT}${BOLD_TEXT} ========================== Waiting for HTTP function to be created... ========================== ${RESET_FORMAT}"
    sleep 10
  fi
done

echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
