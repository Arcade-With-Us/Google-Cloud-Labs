#!/bin/bash
# Define text formatting variables
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

# Clear the screen for a fresh start
clear

# Display initial banner
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

# --- Fetching Instance Details ---
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Fetching zone information for existing instances...${RESET_FORMAT}"
export ZONE_1=$(gcloud compute instances list mynet-vm-1 --format 'csv[no-heading](zone)' 2>/dev/null)
export ZONE_2=$(gcloud compute instances list mynet-vm-2 --format 'csv[no-heading](zone)' 2>/dev/null)

# Check if zones were found
if [ -z "$ZONE_1" ] || [ -z "$ZONE_2" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: Could not retrieve zone information for mynet-vm-1 or mynet-vm-2. Please ensure these instances exist.${RESET_FORMAT}"
    exit 1
fi

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

echo -n "${YELLOW_TEXT}${BOLD_TEXT}Please enter the zone: ${RESET_FORMAT}"
read ZONE
export ZONE

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the 'blue' VM instance...${RESET_FORMAT}"
gcloud compute instances create blue --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --tags=web-server,http-server --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the 'green' VM instance...${RESET_FORMAT}"
gcloud compute instances create green --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --create-disk=auto-delete=yes,boot=yes,device-name=blue,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a firewall rule to allow HTTP traffic...${RESET_FORMAT}"
gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create allow-http-web-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80,icmp --source-ranges=0.0.0.0/0 --target-tags=web-server

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a test VM instance...${RESET_FORMAT}"
gcloud compute instances create test-vm --machine-type=f1-micro --subnet=default --zone=$ZONE

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a service account for network administration...${RESET_FORMAT}"
gcloud iam service-accounts create network-admin --description="Service account for Network Admin role" --display-name="Network-admin"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Assigning the Network Admin role to the service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=roles/compute.networkAdmin

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating a key for the service account...${RESET_FORMAT}"
gcloud iam service-accounts keys create credentials.json --iam-account=network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a script to configure the 'blue' server...${RESET_FORMAT}"
cat > bluessh.sh <<'EOF_END'
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the blue server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END

echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying the script to the 'blue' server...${RESET_FORMAT}"
gcloud compute scp bluessh.sh blue:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing the script on the 'blue' server...${RESET_FORMAT}"
gcloud compute ssh blue --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/bluessh.sh" --ssh-flag="-o ConnectTimeout=60"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a script to configure the 'green' server...${RESET_FORMAT}"
cat > greenssh.sh <<'EOF_END'
sudo apt-get install nginx-light -y
sudo sed -i "14c\<h1>Welcome to the green server!</h1>" /var/www/html/index.nginx-debian.html
EOF_END

echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying the script to the 'green' server...${RESET_FORMAT}"
gcloud compute scp greenssh.sh green:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing the script on the 'green' server...${RESET_FORMAT}"
gcloud compute ssh green --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/greenssh.sh"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade With Us! 👇${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
