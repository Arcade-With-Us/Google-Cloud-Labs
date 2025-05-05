#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Start of the script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Collect user inputs
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter INSTANCE_NAME: ${RESET_FORMAT}" INSTANCE_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter FIREWALL_RULE: ${RESET_FORMAT}" FIREWALL_RULE

# Export variables after collecting input
export INSTANCE_NAME FIREWALL_RULE

# Display current authenticated user
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Checking authenticated accounts...${RESET_FORMAT}"
gcloud auth list

# Set default zone, region, and project
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Setting up default zone, region, and project...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export PORT=8082
export REGION="${ZONE%-*}"
gcloud config set project $DEVSHELL_PROJECT_ID
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

# Create VPC network
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating VPC network...${RESET_FORMAT}"
gcloud compute networks create nucleus-vpc --subnet-mode=auto

# Create a compute instance
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a compute instance...${RESET_FORMAT}"
gcloud compute instances create $INSTANCE_NAME \
          --network nucleus-vpc \
          --zone $ZONE  \
          --machine-type e2-micro  \
          --image-family debian-12  \
          --image-project debian-cloud 

# Create a startup script for the instance
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a startup script for the instance...${RESET_FORMAT}"
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

# Create an instance template
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating an instance template...${RESET_FORMAT}"
gcloud compute instance-templates create web-server-template --region=$ZONE --machine-type e2-medium --metadata-from-file startup-script=startup.sh --network nucleus-vpc

# Create a target pool
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a target pool...${RESET_FORMAT}"
gcloud compute target-pools create nginx-pool --region=$REGION

# Create a managed instance group
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a managed instance group...${RESET_FORMAT}"
gcloud compute instance-groups managed create web-server-group --region=$REGION --base-instance-name web-server --size 2 --template web-server-template

# Create a firewall rule
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a firewall rule...${RESET_FORMAT}"
gcloud compute firewall-rules create $FIREWALL_RULE --network nucleus-vpc --allow tcp:80

# Create an HTTP health check
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating an HTTP health check...${RESET_FORMAT}"
gcloud compute http-health-checks create http-basic-check

# Set named ports for the instance group
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Setting named ports for the instance group...${RESET_FORMAT}"
gcloud compute instance-groups managed \
set-named-ports web-server-group --region=$REGION \
--named-ports http:80

# Create a backend service
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a backend service...${RESET_FORMAT}"
gcloud compute backend-services create web-server-backend --protocol HTTP --http-health-checks http-basic-check --global

# Add backend to the backend service
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Adding backend to the backend service...${RESET_FORMAT}"
gcloud compute backend-services add-backend web-server-backend --instance-group web-server-group --instance-group-region $REGION --global

# Create a URL map
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a URL map...${RESET_FORMAT}"
gcloud compute url-maps create web-server-map --default-service web-server-backend

# Create a target HTTP proxy
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a target HTTP proxy...${RESET_FORMAT}"
gcloud compute target-http-proxies create http-lb-proxy --url-map web-server-map

# Create a forwarding rule
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a forwarding rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create http-content-rule --global --target-http-proxy http-lb-proxy --ports 80

# Create another forwarding rule for the firewall rule
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating another forwarding rule for the firewall rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create $FIREWALL_RULE --global --target-http-proxy http-lb-proxy --ports 80

# List forwarding rules
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Listing all forwarding rules...${RESET_FORMAT}"
gcloud compute forwarding-rules list

# End of the script
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
