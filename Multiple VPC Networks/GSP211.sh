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

# Derive regions from zones
export REGION_1=$(echo "$ZONE_1" | cut -d '-' -f 1-2)
export REGION_2=$(echo "$ZONE_2" | cut -d '-' -f 1-2)

echo "${GREEN_TEXT}Zone 1 identified: ${BOLD_TEXT}$ZONE_1${RESET_FORMAT}"
echo "${GREEN_TEXT}Region 1 derived: ${BOLD_TEXT}$REGION_1${RESET_FORMAT}"
echo "${GREEN_TEXT}Zone 2 identified: ${BOLD_TEXT}$ZONE_2${RESET_FORMAT}"
echo "${GREEN_TEXT}Region 2 derived: ${BOLD_TEXT}$REGION_2${RESET_FORMAT}"
echo

# --- Network Creation ---
echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Creating the 'managementnet' VPC network...${RESET_FORMAT}"
gcloud compute networks create managementnet --subnet-mode=custom

echo "${YELLOW_TEXT}${BOLD_TEXT} subnet for 'managementnet' in region ${REGION_1}...${RESET_FORMAT}"
gcloud compute networks subnets create managementsubnet-1 --network=managementnet --region=$REGION_1 --range=10.130.0.0/20

echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Creating the 'privatenet' VPC network...${RESET_FORMAT}"
gcloud compute networks create privatenet --subnet-mode=custom

echo "${YELLOW_TEXT}${BOLD_TEXT} Creating the first private subnet 'privatesubnet-1' in region ${REGION_1}...${RESET_FORMAT}"
gcloud compute networks subnets create privatesubnet-1 --network=privatenet --region=$REGION_1 --range=172.16.0.0/24

echo "${YELLOW_TEXT}${BOLD_TEXT} Creating the second private subnet 'privatesubnet-2' in region ${REGION_2}...${RESET_FORMAT}"
gcloud compute networks subnets create privatesubnet-2 --network=privatenet --region=$REGION_2 --range=172.20.0.0/20
echo

# --- Firewall Rule Creation ---
echo "${YELLOW_TEXT}${BOLD_TEXT}🛡️ Configuring firewall rule 'managementnet-allow-icmp-ssh-rdp' for management network...${RESET_FORMAT}"
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=managementnet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

echo "${YELLOW_TEXT}${BOLD_TEXT}🛡️ Configuring firewall rule 'privatenet-allow-icmp-ssh-rdp' for private network...${RESET_FORMAT}"
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=privatenet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0
echo

# --- Instance Creation ---
echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ Creating instance 'managementnet-vm-1' in zone ${ZONE_1}...${RESET_FORMAT}"
gcloud compute instances create managementnet-vm-1 --zone=$ZONE_1 --machine-type=e2-micro --subnet=managementsubnet-1

echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ Creating instance 'privatenet-vm-1' in zone ${ZONE_1}...${RESET_FORMAT}"
gcloud compute instances create privatenet-vm-1 --zone=$ZONE_1 --machine-type=e2-micro --subnet=privatesubnet-1

echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ Creating the multi-NIC 'vm-appliance' instance in zone ${ZONE_1}...${RESET_FORMAT}"
echo "${BLUE_TEXT}   Attaching interfaces to privatenet-1, managementsubnet-1, and mynetwork.${RESET_FORMAT}"
gcloud compute instances create vm-appliance \
--zone=$ZONE_1 \
--machine-type=e2-standard-4 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=privatesubnet-1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=managementsubnet-1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade With Us! 👇${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
