#!/bin/bash

# Define color variables
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


clear
# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo "${CYAN_TEXT} ${BOLD_TEXT}Creating an API key named 'arcadecrew'.${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="arcadecrew"

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=arcadecrew")

export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

#Instructions before making image public
echo "${CYAN_TEXT} ${BOLD_TEXT}Making the image publically readable...${RESET_FORMAT}"

gsutil acl ch -u allUsers:R gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg

#Instructions before text detection
echo "${CYAN_TEXT} ${BOLD_TEXT}Performing TEXT_DETECTION on the image...${RESET_FORMAT}"

cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "TEXT_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o text-response.json

#Instructions before uploading text response
echo "${CYAN_TEXT} ${BOLD_TEXT}Uploading text-response.json to your bucket...${RESET_FORMAT}"

gsutil cp text-response.json gs://$PROJECT_ID-bucket

#Instructions before landmark detection
echo "${CYAN_TEXT} ${BOLD_TEXT}Performing LANDMARK_DETECTION on the image...${RESET_FORMAT}"

cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "LANDMARK_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o landmark-response.json

#Instructions before uploading landmark response
echo "${CYAN_TEXT} ${BOLD_TEXT}Uploading landmark-response.json to your bucket...${RESET_FORMAT}"

gsutil cp landmark-response.json gs://$PROJECT_ID-bucket

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
