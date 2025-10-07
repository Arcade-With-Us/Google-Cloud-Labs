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

gcloud auth list
export PROJECT_ID=$(gcloud config get-value project)
gcloud services enable videointelligence.googleapis.com
gcloud iam service-accounts create quickstart
gcloud iam service-accounts keys create key.json --iam-account quickstart@$PROJECT_ID.iam.gserviceaccount.com
gcloud auth activate-service-account --key-file key.json
gcloud auth print-access-token

cat > request.json <<EOF
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "LABEL_DETECTION"
   ]
}
EOF

RESPONSE=$(curl -s -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://videointelligence.googleapis.com/v1/videos:annotate" \
  -d @request.json)

sleep 10
OPERATION_NAME=$(echo "$RESPONSE" | grep -oP '"name":\s*"\K[^"]+')
export OPERATION_NAME

curl -s -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://videointelligence.googleapis.com/v1/$OPERATION_NAME"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
