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

# Instruction before creating the script
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} Preparing the disk setup."
echo

cat > prepare_disk.sh <<'EOF_END'

gcloud services enable apikeys.googleapis.com

gcloud alpha services api-keys create --display-name="awesome" 

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

cat > request.json <<EOF

{
    "config": {
            "encoding":"FLAC",
            "languageCode": "en-US"
    },
    "audio": {
            "uri":"gs://cloud-samples-data/speech/brooklyn_bridge.flac"
    }
}

EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

cat result.json

EOF_END

# Instruction before transferring the script
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} Transferring the prepared script to the target instance."
echo

export ZONE=$(gcloud compute instances list linux-instance --format 'csv[no-heading](zone)')

gcloud compute scp prepare_disk.sh linux-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# Instruction before executing the script on the instance
echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} Executing the script on the target instance."
echo

gcloud compute ssh linux-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}              NOW CHECK SCORE TILL TASK 3              ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo

read -p "${RED_TEXT}${BOLD_TEXT}Have you checked the progress till TASK 3 (Y/N)?${RESET_FORMAT}" response

if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "${GREEN_TEXT}Proceeding with next steps!${RESET_FORMAT}"
else
        echo "${RED_TEXT}Please check the progress before proceeding.${RESET_FORMAT}"
fi

# Instruction before creating the second script
echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} Preparing the second script for processing a different audio file."
echo

cat > prepare_disk.sh <<'EOF_END'

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

rm -f request.json

cat >> request.json <<EOF

 {
    "config": {
            "encoding":"FLAC",
            "languageCode": "fr"
    },
    "audio": {
            "uri":"gs://cloud-samples-data/speech/corbeau_renard.flac"
    }
}

EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

cat result.json

EOF_END

# Instruction before transferring the second script
echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} Transferring the updated script to the target instance."
echo

export ZONE=$(gcloud compute instances list linux-instance --format 'csv[no-heading](zone)')

gcloud compute scp prepare_disk.sh linux-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# Instruction before executing the second script
echo "${CYAN_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} Executing the updated script on the target instance."
echo

gcloud compute ssh linux-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

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
