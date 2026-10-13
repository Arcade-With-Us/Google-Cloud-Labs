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


#!/bin/bash
set -e

# Get current lab details
read -rp "Enter PROJECT ID: " PROJECT_ID
read -rp "Enter ZONE (e.g. us-west1-b): " ZONE

export PROJECT_ID ZONE
REGION="${ZONE%-*}"
export REGION

if [[ -z "$PROJECT_ID" || -z "$ZONE" ]]; then
  echo "ERROR: Project ID and Zone are required."
  exit 1
fi

gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

echo "PROJECT ID: $PROJECT_ID | REGION: $REGION | ZONE: $ZONE"

# Resource names
BUCKET="${PROJECT_ID}-bucket"
DISK="mydisk"
VM="my-instance"

# Task 1: Create Cloud Storage bucket
if ! gcloud storage buckets describe "gs://$BUCKET" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://$BUCKET" \
    --project="$PROJECT_ID" \
    --location=US \
    --default-storage-class=STANDARD \
    --uniform-bucket-level-access
else
  echo "Bucket already exists: $BUCKET"
fi

# Task 2A: Create 200 GB balanced persistent disk
if ! gcloud compute disks describe "$DISK" --project="$PROJECT_ID" --zone="$ZONE" >/dev/null 2>&1; then
  gcloud compute disks create "$DISK" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --size=200GB \
    --type=pd-balanced
else
  echo "Disk already exists: $DISK"
fi

# Task 2B: Create VM with Debian 12 and 10 GB balanced boot disk
if ! gcloud compute instances describe "$VM" --project="$PROJECT_ID" --zone="$ZONE" >/dev/null 2>&1; then
  gcloud compute instances create "$VM" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --tags=http-server
else
  echo "VM already exists: $VM"
fi

# Task 2C: Attach persistent disk if not already attached
if ! gcloud compute instances describe "$VM" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --format="value(disks.source)" | grep -q "/disks/$DISK$"; then
  gcloud compute instances attach-disk "$VM" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --disk="$DISK" \
    --mode=rw
else
  echo "Disk $DISK is already attached."
fi

# Task 2D: Allow HTTP traffic
if ! gcloud compute firewall-rules describe allow-http --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud compute firewall-rules create allow-http \
    --project="$PROJECT_ID" \
    --network=default \
    --allow=tcp:80 \
    --target-tags=http-server
else
  echo "HTTP firewall rule already exists."
fi

# Task 3: Install and start NGINX
gcloud compute ssh "$VM" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --quiet \
  --command="sudo apt-get update && sudo apt-get install -y nginx && sudo systemctl enable --now nginx && sudo systemctl is-active nginx"

echo ""
echo "Infrastructure setup completed!"
echo "PROJECT ID: $PROJECT_ID"
echo "REGION: $REGION"
echo "ZONE: $ZONE"
echo "BUCKET: gs://$BUCKET"
echo "VM: $VM"
echo "DISK: $DISK (200 GB)"

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
