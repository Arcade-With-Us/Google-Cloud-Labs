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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Attempting to retrieve your active Google Cloud Project ID.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}Project ID set to: ${BOLD_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo

echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the region: ${RESET_FORMAT}" REGION
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the Cloud Function name: ${RESET_FORMAT}" FUNCTION_NAME
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🛠️  Generating the necessary source code files for a sample Node.js Cloud Function.${RESET_FORMAT}"
mkdir -p cloud-function
cat > cloud-function/index.js <<EOF
exports.helloWorld = (req, res) => {
  res.send('Hello from Cloud Function!');
};
EOF

cat > cloud-function/package.json <<EOF
{
  "name": "cf-nodejs",
  "version": "1.0.0",
  "main": "index.js"
}
EOF
echo "${GREEN_TEXT}Source code files created successfully in 'cloud-function' directory.${RESET_FORMAT}"
echo

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀  Starting the deployment process for your Cloud Function: ${FUNCTION_NAME}.${RESET_FORMAT}"
gcloud functions deploy ${FUNCTION_NAME} \
  --gen2 \
  --runtime=nodejs20 \
  --region=${REGION} \
  --source=cloud-function \
  --entry-point=helloWorld \
  --trigger-http \
  --max-instances=5 \
  --allow-unauthenticated

echo -e "\n"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🏠  Changing current directory to your home directory.${RESET_FORMAT}"
cd ~
echo "${GREEN_TEXT}Current directory changed to: $(pwd)${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade With US! 👇${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
