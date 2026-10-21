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
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo ""

# Instructions for API Key
echo "${YELLOW_TEXT} ${BOLD_TEXT} STEP 1: Enter your Google Cloud API Key: ${RESET_FORMAT}"
read -p "${BLUE_TEXT} ${BOLD_TEXT}API Key: ${RESET_FORMAT}" USER_API_KEY

# Input Validation
while [[ -z "$USER_API_KEY" ]]; do
    echo "${RED_TEXT} ${BOLD_TEXT}ERROR: API Key cannot be empty. Please enter a valid API Key.${RESET_FORMAT}"
    read -p "${BLUE_TEXT} ${BOLD_TEXT}API Key: ${RESET_FORMAT}" USER_API_KEY
done

export API_KEY="$USER_API_KEY"

echo "${GREEN_TEXT}${BOLD_TEXT}API Key Set Successfully!${RESET_FORMAT}"
echo ""

export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project)
export BUCKET_NAME="${GOOGLE_CLOUD_PROJECT}-speech"

# Create the bucket if it does not exist already
gcloud storage buckets create gs://${BUCKET_NAME} --location=us

# Create the English transcription request
cat <<EOF > request.json
{
  "config": {
    "encoding": "LINEAR16",
    "languageCode": "en-US",
    "audioChannelCount": 2
  },
  "audio": {
    "uri": "gs://spls/arc131/question_en.wav"
  }
}
EOF

# Call the API for English transcription
curl "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json > speech_response_en.json

# Create the Spanish transcription request
cat > request_sp.json <<'EOF'
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "es-ES"
  },
  "audio": {
    "uri": "gs://spls/arc131/multi_es.flac"
  }
}
EOF

# Call the API for Spanish transcription
curl -s -X POST \
  "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  --data-binary @request_sp.json \
  -o response_sp.json

# Upload all four files for lab verification
gcloud storage cp request.json "gs://${BUCKET_NAME}/request.json"
gcloud storage cp speech_response_en.json "gs://${BUCKET_NAME}/speech_response_en.json"
gcloud storage cp request_sp.json "gs://${BUCKET_NAME}/request_sp.json"
gcloud storage cp response_sp.json "gs://${BUCKET_NAME}/response_sp.json"

# Display the transcription results
echo "===== ENGLISH TRANSCRIPTION ====="
cat speech_response_en.json
echo
echo "===== SPANISH TRANSCRIPTION ====="
cat response_sp.json
echo
echo "===== ALL COMMANDS COMPLETED ====="

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
