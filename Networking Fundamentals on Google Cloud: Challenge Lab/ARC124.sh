#!/bin/bash

# Bright Foreground Colors
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

read -p "${BLUE_TEXT}${BOLD_TEXT}Enter ZONE: ${RESET_FORMAT}" ZONE

# Extract Region from Zone
REGION=$(echo $ZONE | cut -d'-' -f1,2)

# Validate Region Input (Basic Validation)
if [[ -z "$REGION" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Region cannot be empty.${RESET_FORMAT}"
  exit 1
fi

export REGION=$REGION
export ZONE=$ZONE

echo "Region: $REGION"
echo "Zone: $ZONE"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Compute Engine instances...${RESET_FORMAT}"
echo
gcloud compute instances create web1 \
--zone=$ZONE \
--machine-type=e2-small \
--tags=network-lb-tag \
--image-family=debian-11 \
--image-project=debian-cloud \
--metadata=startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: web1</h3>" | tee /var/www/html/index.html'
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Instance web1 created successfully.${RESET_FORMAT}"
echo
gcloud compute instances create web2 \
--zone=$ZONE \
--machine-type=e2-small \
--tags=network-lb-tag \
--image-family=debian-11 \
--image-project=debian-cloud \
--metadata=startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: web2</h3>" | tee /var/www/html/index.html'
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Instance web2 created successfully.${RESET_FORMAT}"
echo

gcloud compute instances create web3 \
--zone=$ZONE \
--machine-type=e2-small \
--tags=network-lb-tag \
--image-family=debian-11 \
--image-project=debian-cloud \
--metadata=startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: web3</h3>" | tee /var/www/html/index.html'

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Instance web3 created successfully.${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Setting up firewall rules...${RESET_FORMAT}"
echo

gcloud compute firewall-rules create www-firewall-network-lb --allow tcp:80 --target-tags network-lb-tag
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Firewall rule www-firewall-network-lb created successfully.${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Configuring Load Balancer...${RESET_FORMAT}"
echo




gcloud compute addresses create network-lb-ip-1 \
    --region=$REGION  



gcloud compute http-health-checks create basic-check


 gcloud compute target-pools create www-pool \
    --region=$REGION  --http-health-check basic-check


gcloud compute target-pools add-instances www-pool \
    --instances web1,web2,web3 --zone=$ZONE
    

gcloud compute forwarding-rules create www-rule \
    --region=$REGION \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Load balancer setup completed.${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Fetching Load Balancer IP Address...${RESET_FORMAT}"
echo
IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region=$REGION  --format="json" | jq -r .IPAddress)

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating instance templates and backend services...${RESET_FORMAT}"
echo
#TASK 3

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

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Instance template created.${RESET_FORMAT}"
echo


echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Managed Instance Group...${RESET_FORMAT}"
echo
gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=$ZONE 

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Managed instance group created.${RESET_FORMAT}"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Firewall Rules...${RESET_FORMAT}"
echo

gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80



gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global



gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global




gcloud compute health-checks create http http-basic-check \
  --port 80



gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global



gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global



gcloud compute url-maps create web-map-http \
    --default-service web-backend-service




gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http


gcloud compute forwarding-rules create http-content-rule \
    --address=lb-ipv4-1\
    --global \
    --target-http-proxy=http-lb-proxy \
    --ports=80


echo
echo "${GREEN_TEXT}${BOLD_TEXT}Firewall rules created.${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Load Balancer IP Address: ${IPADDRESS}${RESET_FORMAT}"
echo


echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
