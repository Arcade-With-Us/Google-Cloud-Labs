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

echo
echo "${BLUE}${BOLD}⚡ Initializing Load Balancer Configuration...${RESET}"
echo

# User Input Section
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ZONE CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
read -p "${YELLOW}${BOLD}Enter the ZONE (e.g., us-central1-a): ${RESET}" ZONE

# Validate Zone Input
if [[ -z "$ZONE" ]]; then
  echo "${RED}${BOLD}Error: Zone cannot be empty.${RESET}"
  exit 1
fi

export ZONE
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo "${CYAN}Selected Zone: ${WHITE}${BOLD}$ZONE${RESET}"
echo "${CYAN}Derived Region: ${WHITE}${BOLD}$REGION${RESET}"
echo

# Web Server Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ WEB SERVER SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating web server instances...${RESET}"

create_web_server() {
  local server_name=$1
  echo "${CYAN}Creating instance ${BOLD}$server_name${RESET}..."
  gcloud compute instances create $server_name \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: '"$server_name"'</h3>" | tee /var/www/html/index.html'
  echo "${GREEN}✅ Instance $server_name created successfully!${RESET}"
  echo
}

create_web_server "www1"
create_web_server "www2"
create_web_server "www3"

# Firewall Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ FIREWALL SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Configuring firewall rules...${RESET}"
gcloud compute firewall-rules create www-firewall-network-lb \
  --target-tags network-lb-tag \
  --allow tcp:80
echo "${GREEN}✅ Firewall rule created successfully!${RESET}"
echo

# Network Load Balancer Setup
echo "${GREEN}${BOLD}▬▬▬▬▬ NETWORK LOAD BALANCER ▬▬▬▬▬${RESET}"
echo "${YELLOW}Setting up network load balancer...${RESET}"

echo "${CYAN}Creating IP address...${RESET}"
gcloud compute addresses create network-lb-ip-1 --region $REGION

echo "${CYAN}Creating health check...${RESET}"
gcloud compute http-health-checks create basic-check

echo "${CYAN}Creating target pool...${RESET}"
gcloud compute target-pools create www-pool \
  --region $REGION \
  --http-health-check basic-check

echo "${CYAN}Adding instances to pool...${RESET}"
gcloud compute target-pools add-instances www-pool \
  --instances www1,www2,www3

echo "${CYAN}Creating forwarding rule...${RESET}"
gcloud compute forwarding-rules create www-rule \
  --region $REGION \
  --ports 80 \
  --address network-lb-ip-1 \
  --target-pool www-pool

IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region $REGION --format="json" | jq -r .IPAddress)
echo "${GREEN}✅ Network load balancer configured successfully!${RESET}"
echo "${CYAN}Load Balancer IP: ${WHITE}${BOLD}$IPADDRESS${RESET}"
echo

# HTTP Load Balancer Setup
echo "${GREEN}${BOLD}▬▬▬▬▬ HTTP LOAD BALANCER ▬▬▬▬▬${RESET}"
echo "${YELLOW}Setting up HTTP load balancer...${RESET}"

echo "${CYAN}Creating instance template...${RESET}"
gcloud compute instance-templates create lb-backend-template \
  --region=$REGION \
  --network=default \
  --subnet=default \
  --tags=allow-health-check \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    a2ensite default-ssl
    a2enmod ssl
    vm_hostname="$(curl -H "Metadata-Flavor:Google" \
    http://169.254.169.254/computeMetadata/v1/instance/name)"
    echo "Page served from: $vm_hostname" | \
    tee /var/www/html/index.html
    systemctl restart apache2'
echo "${GREEN}✅ Instance template created successfully!${RESET}"
echo

echo "${CYAN}Creating managed instance group...${RESET}"
gcloud compute instance-groups managed create lb-backend-group \
  --template=lb-backend-template \
  --size=2 \
  --zone=$ZONE
echo "${GREEN}✅ Managed instance group created successfully!${RESET}"
echo

echo "${CYAN}Configuring health check firewall...${RESET}"
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80
echo "${GREEN}✅ Firewall rule created successfully!${RESET}"
echo

echo "${CYAN}Creating global IP address...${RESET}"
gcloud compute addresses create lb-ipv4-1 --ip-version=IPV4 --global

echo "${CYAN}Creating health check...${RESET}"
gcloud compute health-checks create http http-basic-check --port 80

echo "${CYAN}Creating backend service...${RESET}"
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

echo "${CYAN}Adding backend to service...${RESET}"
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global

echo "${CYAN}Creating URL map...${RESET}"
gcloud compute url-maps create web-map-http --default-service web-backend-service

echo "${CYAN}Creating target HTTP proxy...${RESET}"
gcloud compute target-http-proxies create http-lb-proxy --url-map web-map-http

echo "${CYAN}Creating forwarding rule...${RESET}"
gcloud compute forwarding-rules create http-content-rule \
  --address=lb-ipv4-1 \
  --global \
  --target-http-proxy=http-lb-proxy \
  --ports=80
echo "${GREEN}✅ HTTP load balancer configured successfully!${RESET}"
echo

# Cleanup and Completion
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ CLEANUP ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Removing script for security...${RESET}"
rm -- "$0"
echo "${GREEN}✅ Script removed successfully!${RESET}"
echo

# Completion Message
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
