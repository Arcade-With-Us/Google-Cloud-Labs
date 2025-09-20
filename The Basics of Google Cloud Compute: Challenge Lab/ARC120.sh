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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE: ${RESET_FORMAT}" ZONE

echo "${MAGENTA_TEXT}${BOLD_TEXT}You entered: $ZONE${RESET_FORMAT}"

export ZONE=$ZONE

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}ERROR: No project ID found. Set your project ID using 'gcloud config set project PROJECT_ID'.${RESET_FORMAT}"
    exit 1
fi

# Define bucket name
BUCKET_NAME="${PROJECT_ID}-bucket"
echo

# Check if the bucket already exists
if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}Bucket '${BUCKET_NAME}' already exists.${RESET_FORMAT}"
else
    # Create the Cloud Storage bucket in the US multi-region
    echo "${BLUE_TEXT}${BOLD_TEXT}Creating Cloud Storage bucket: ${BUCKET_NAME}${RESET_FORMAT}"
    if gcloud storage buckets create "gs://${BUCKET_NAME}" --location=US --uniform-bucket-level-access; then
        echo "${GREEN_TEXT}${BOLD_TEXT}Bucket '${BUCKET_NAME}' created successfully.${RESET_FORMAT}"
    else
        echo "${RED_TEXT}${BOLD_TEXT}Failed to create bucket '${BUCKET_NAME}'. Check your permissions and try again.${RESET_FORMAT}"
        exit 1
    fi
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating the Compute Engine Instance 'my-instance' ========================== ${RESET_FORMAT}"
echo

gcloud compute instances create my-instance \
    --machine-type=e2-medium \
    --zone=$ZONE \
    --image-project=debian-cloud \
    --image-family=debian-11 \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --create-disk=size=100GB,type=pd-standard,mode=rw,device-name=additional-disk \
    --tags=http-server

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating a Persistent Disk 'mydisk' ========================== ${RESET_FORMAT}"
echo
gcloud compute disks create mydisk \
    --size=200GB \
    --zone=$ZONE

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Attaching 'mydisk' to 'my-instance' ========================== ${RESET_FORMAT}"
echo
gcloud compute instances attach-disk my-instance \
    --disk=mydisk \
    --zone=$ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for 15 seconds for the changes to take effect...${RESET_FORMAT}"
sleep 15

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Preparing the 'prepare_disk.sh' script ========================== ${RESET_FORMAT}"
echo
cat > prepare_disk.sh <<'EOF_END'

sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx

EOF_END

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Copying the script to the instance ========================== ${RESET_FORMAT}"
echo

gcloud compute scp prepare_disk.sh my-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Executing the script on the instance ========================== ${RESET_FORMAT}"
echo

gcloud compute ssh my-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"
echo

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
