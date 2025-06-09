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
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}             INITIATING EXECUTION          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo


gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud compute instances create blue --zone=$ZONE --project=$DEVSHELL_PROJECT_ID --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --tags=web-server,http-server --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

gcloud compute instances create green --zone=$ZONE --project=$DEVSHELL_PROJECT_ID --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

gcloud compute firewall-rules create allow-http-web-server --network=default --action=ALLOW --direction=INGRESS --source-ranges=0.0.0.0/0 --target-tags=web-server --rules=tcp:80,icmp

gcloud compute instances create test-vm --machine-type=e2-micro --subnet=default --zone=$ZONE

gcloud iam service-accounts create network-admin --description="Subscribe to Techcps" --display-name="Network-admin"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=roles/compute.networkAdmin

gcloud iam service-accounts keys create credentials.json --iam-account=network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

cat > blue.sh <<'EOF_CP'
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the blue server!</h1>" /var/www/html/index.nginx-debian.html
EOF_CP

gcloud compute scp blue.sh blue:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh blue --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/blue.sh" --ssh-flag="-o ConnectTimeout=60"

cat > green.sh <<'EOF_CP'
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the green server!</h1>" /var/www/html/index.nginx-debian.html
EOF_CP

gcloud compute scp green.sh green:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh green --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/green.sh"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade With Us! 👇${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
