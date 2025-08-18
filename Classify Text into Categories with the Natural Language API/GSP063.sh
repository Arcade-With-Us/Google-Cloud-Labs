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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Please enter your API key: ${RESET_FORMAT}" KEY
export KEY

# Enabling the required API
echo "${YELLOW_TEXT}${BOLD_TEXT}---> Enabling the Natural Language API...${RESET_FORMAT}"
gcloud services enable language.googleapis.com

# Fetching the zone
echo "${MAGENTA_TEXT}${BOLD_TEXT}---> Fetching the zone of your compute instance...${RESET_FORMAT}"
ZONE="$(gcloud compute instances list --project=$DEVSHELL_PROJECT_ID --format='value(ZONE)')"

# Adding metadata to the instance
echo "${CYAN_TEXT}${BOLD_TEXT}---> Adding metadata (API_KEY) to the compute instance...${RESET_FORMAT}"
gcloud compute instances add-metadata linux-instance --metadata API_KEY="$KEY" --project=$DEVSHELL_PROJECT_ID --zone=$ZONE

# Creating the prepare_disk.sh script
echo "${GREEN_TEXT}${BOLD_TEXT}---> Creating the prepare_disk.sh script...${RESET_FORMAT}"
cat > prepare_disk.sh <<'EOF_END'

API_KEY=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/API_KEY)

export API_KEY="$API_KEY"  # Export the API key to the script

cat > request.json <<EOF
{
    "document":{
      "type":"PLAIN_TEXT",
      "content":"A Smoky Lobster Salad With a Tapa Twist. This spin on the Spanish pulpo a la gallega skips the octopus, but keeps the sea salt, olive oil, pimentón and boiled potatoes."
    }
  }
EOF


curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json

  curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json > result.json

EOF_END

# Copying the script to the instance
echo "${MAGENTA_TEXT}${BOLD_TEXT}---> Copying the prepare_disk.sh script to the compute instance...${RESET_FORMAT}"
gcloud compute scp prepare_disk.sh linux-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# Executing the script on the instance
echo "${CYAN_TEXT}${BOLD_TEXT}---> Executing the prepare_disk.sh script on the compute instance...${RESET_FORMAT}"
gcloud compute ssh linux-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="export API_KEY=$KEY && bash /tmp/prepare_disk.sh"

# Creating BigQuery dataset and table
echo "${YELLOW_TEXT}${BOLD_TEXT}---> Creating BigQuery dataset and table for storing classification results...${RESET_FORMAT}"
bq --location=US mk --dataset $DEVSHELL_PROJECT_ID:news_classification_dataset

bq mk --table $DEVSHELL_PROJECT_ID:news_classification_dataset.article_data article_text:STRING,category:STRING,confidence:FLOAT

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
