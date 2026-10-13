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

# 1. Get project ID, region, and zone from lab configuration
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
export REGION=$(gcloud config get-value compute/region 2>/dev/null)
export ZONE=$(gcloud config get-value compute/zone 2>/dev/null)

# 2. Set required lab defaults if not configured
export REGION=${REGION:-us-west1}
export ZONE=${ZONE:-us-west1-b}

# 3. Display detected configuration
echo "PROJECT ID: $PROJECT_ID | REGION: $REGION | ZONE: $ZONE"

# 4. Validate project ID
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "ERROR: No active project found."
  exit 1
fi

# 5. Set gcloud configuration
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# 6. Define resource names AFTER detecting project and zone
BUCKET="${PROJECT_ID}-bucket"
DISK="mydisk"
VM="my-instance"

# Task 1: Create Cloud Storage bucket in US multi-region
if ! gcloud storage buckets describe "gs://$BUCKET" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://$BUCKET" \
    --project="$PROJECT_ID" \
    --location=US \
    --default-storage-class=STANDARD
else
  echo "Bucket already exists: $BUCKET"
fi

# Task 2A: Create 200 GB balanced persistent disk
if ! gcloud compute disks describe "$DISK" \
  --project="$PROJECT_ID" --zone="$ZONE" >/dev/null 2>&1; then
  gcloud compute disks create "$DISK" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --size=200GB \
    --type=pd-balanced
else
  echo "Disk already exists: $DISK"
fi

# Task 2B: Create VM with Debian 12 and balanced 10 GB boot disk
if ! gcloud compute instances describe "$VM" \
  --project="$PROJECT_ID" --zone="$ZONE" >/dev/null 2>&1; then
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

# Task 2D: Configure HTTP firewall access
if ! gcloud compute firewall-rules describe allow-http \
  --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud compute firewall-rules create allow-http \
    --project="$PROJECT_ID" \
    --network=default \
    --allow=tcp:80 \
    --target-tags=http-server
else
  echo "HTTP firewall rule already exists."
fi

# 7. Display completion information
echo ""
echo "Infrastructure setup completed!"
echo "PROJECT ID: $PROJECT_ID"
echo "REGION: $REGION"
echo "ZONE: $ZONE"
echo "BUCKET: gs://$BUCKET"
echo "VM: $VM"
echo "DISK: $DISK (200 GB)"
echo ""
echo "Next, connect to the VM:"

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for 15 seconds for the changes to take effect...${RESET_FORMAT}"
sleep 15

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Preparing the 'prepare_disk.sh' script ========================== ${RESET_FORMAT}"
echo
cat > prepare_disk.sh <<'EOF_END'

sudo apt update && sudo apt upgrade -y
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx

EOF_END

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Copying the script to the instance ========================== ${RESET_FORMAT}"
echo

gcloud compute scp prepare_disk.sh my-instance:/tmp --project=$PROJECT_ID --zone=$ZONE --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Executing the script on the instance ========================== ${RESET_FORMAT}"
echo

gcloud compute ssh my-instance --project=$PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"
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
