#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'
BG_BLUE=$'\033[44m'
BG_MAGENTA=$'\033[45m'
BG_CYAN=$'\033[46m'
BG_WHITE=$'\033[47m'
DIM_TEXT=$'\033[2m'
BLINK_TEXT=$'\033[5m'
REVERSE_TEXT=$'\033[7m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📋 STEP 1: Checking Authentication Status${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}ℹ️  Displaying current authenticated accounts...${RESET_FORMAT}"
echo
gcloud auth list

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔧 STEP 2: Setting Up Project Configuration${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📊 Retrieving current project ID for configuration...${RESET_FORMAT}"
echo
export PROJECT_ID=$(gcloud config get-value project)

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⚡ STEP 3: Enabling Video Intelligence API${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🔌 Activating Google Cloud Video Intelligence service...${RESET_FORMAT}"
echo
gcloud services enable videointelligence.googleapis.com

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔐 STEP 4: Creating Service Account${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}👤 Setting up quickstart service account for API access...${RESET_FORMAT}"
echo
gcloud iam service-accounts create quickstart

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🗝️  STEP 5: Generating Service Account Keys${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📄 Creating JSON key file for authentication...${RESET_FORMAT}"
echo
gcloud iam service-accounts keys create key.json --iam-account quickstart@$PROJECT_ID.iam.gserviceaccount.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔑 STEP 6: Activating Service Account${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}✅ Switching to service account authentication...${RESET_FORMAT}"
echo
gcloud auth activate-service-account --key-file key.json

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🎫 STEP 7: Obtaining Access Token${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🔒 Generating bearer token for API requests...${RESET_FORMAT}"
echo
gcloud auth print-access-token

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📝 STEP 8: Creating API Request Payload${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📋 Preparing JSON request for video analysis...${RESET_FORMAT}"
echo
cat > request.json <<EOF
{
    "inputUri":"gs://spls/gsp154/video/train.mp4",
    "features": [
         "LABEL_DETECTION"
    ]
}
EOF

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀 STEP 9: Initiating Video Analysis${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🎥 Sending video to AI for label detection...${RESET_FORMAT}"
echo
RESPONSE=$(curl -s -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://videointelligence.googleapis.com/v1/videos:annotate" \
  -d @request.json)

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ STEP 10: Processing Wait Time${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🕰️  Allowing 30 seconds for video processing completion...${RESET_FORMAT}"
echo
for i in {30..1}; do
    printf "\r${YELLOW_TEXT}${BOLD_TEXT}⏳ Processing... ${i} seconds remaining${RESET_FORMAT}"
    sleep 1
done
printf "\r${GREEN_TEXT}${BOLD_TEXT}✅ Processing complete!                    ${RESET_FORMAT}\n"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔍 STEP 11: Extracting Operation Details${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📊 Parsing response to get operation identifier...${RESET_FORMAT}"
echo
OPERATION_NAME=$(echo "$RESPONSE" | grep -oP '"name":\s*"\K[^"]+')

export OPERATION_NAME

echo
echo "${CYAN_TEXT}${BOLD_TEXT}📈 STEP 12: Retrieving Final Results${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🎯 Fetching completed analysis results...${RESET_FORMAT}"
echo
curl -s -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://videointelligence.googleapis.com/v1/$OPERATION_NAME"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
