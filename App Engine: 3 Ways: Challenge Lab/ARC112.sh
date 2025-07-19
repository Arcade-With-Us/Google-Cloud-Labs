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

gcloud services enable appengine.googleapis.com

cat > prepare_disk.sh <<'EOF_END'

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/appengine/standard_python3/hello_world

EOF_END

export ZONE=$(gcloud compute instances list lab-setup --format 'csv[no-heading](zone)')

export REGION="${ZONE%-*}"

gcloud compute scp prepare_disk.sh lab-setup:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh lab-setup --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/appengine/standard_python3/hello_world

gcloud app create --region=$REGION

yes | gcloud app deploy

sed -i 's/Hello World!/'"$MESSAGE"'/g' main.py

yes | gcloud app deploy

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
