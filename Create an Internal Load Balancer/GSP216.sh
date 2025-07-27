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
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

change_zone_automatically() {
    if [[ -z "$ZONE_1" ]]; then
        echo "Could not retrieve the current zone. Exiting."
        return 1
    fi

    echo "Current Zone (ZONE_1): $ZONE_1"
    zone_prefix=${ZONE_1::-1}
    last_char=${ZONE_1: -1}
    valid_chars=("b" "c" "d")
    new_char=$last_char
    for char in "${valid_chars[@]}"; do
        if [[ $char != "$last_char" ]]; then
            new_char=$char
            break
        fi
    done
    ZONE_2="${zone_prefix}${new_char}"
    export ZONE_2
    echo "New Zone (ZONE_2) is now set to: $ZONE_2"
}

echo "${CYAN_TEXT}${BOLD_TEXT}📍 Fetching default GCP zone and region...${RESET_FORMAT}"
export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${MAGENTA_TEXT}${BOLD_TEXT}🛡️  Configuring firewall rule 'app-allow-http' for network ${YELLOW_TEXT}${BOLD_TEXT}my-internal-app${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT} to permit HTTP traffic...${RESET_FORMAT}"
gcloud compute firewall-rules create app-allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=10.10.0.0/16 \
    --target-tags=lb-backend

echo "${RED_TEXT}${BOLD_TEXT}🩺 Setting up firewall rule 'app-allow-health-check' for network ${YELLOW_TEXT}${BOLD_TEXT}my-internal-app${RESET_FORMAT}${RED_TEXT}${BOLD_TEXT} to allow health checks...${RESET_FORMAT}"
gcloud compute firewall-rules create app-allow-health-check \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=lb-backend

echo "${GREEN_TEXT}${BOLD_TEXT}📄 Generating instance template 'instance-template-1' in region ${YELLOW_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${GREEN_TEXT}${BOLD_TEXT} for subnet ${YELLOW_TEXT}${BOLD_TEXT}subnet-a${RESET_FORMAT}${GREEN_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
gcloud compute instance-templates create instance-template-1 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region=$REGION

echo "${BLUE_TEXT}${BOLD_TEXT}📄 Creating instance template 'instance-template-2' in region ${YELLOW_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT} for subnet ${YELLOW_TEXT}${BOLD_TEXT}subnet-b${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
gcloud compute instance-templates create instance-template-2 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-b \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region=$REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️  Calculating and assigning the secondary zone based on ${CYAN_TEXT}${BOLD_TEXT}$ZONE_1${RESET_FORMAT}${YELLOW_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
change_zone_automatically

echo "${MAGENTA_TEXT}${BOLD_TEXT}🏗️  Building managed instance group 'instance-group-1' in zone ${YELLOW_TEXT}${BOLD_TEXT}$ZONE_1${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT} using template ${CYAN_TEXT}${BOLD_TEXT}instance-template-1${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
gcloud beta compute instance-groups managed create instance-group-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --base-instance-name=instance-group-1 \
    --size=1 \
    --template=instance-template-1 \
    --zone=$ZONE_1 \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair

echo "${CYAN_TEXT}${BOLD_TEXT}⚖️  Applying autoscaling settings to 'instance-group-1' in zone ${YELLOW_TEXT}${BOLD_TEXT}$ZONE_1${RESET_FORMAT}${CYAN_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
gcloud beta compute instance-groups managed set-autoscaling instance-group-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE_1 \
    --cool-down-period=45 \
    --max-num-replicas=5 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8

echo "${RED_TEXT}${BOLD_TEXT}🏗️  Constructing managed instance group 'instance-group-2' in zone ${YELLOW_TEXT}${BOLD_TEXT}$ZONE_2${RESET_FORMAT}${RED_TEXT}${BOLD_TEXT} using template ${CYAN_TEXT}${BOLD_TEXT}instance-template-2${RESET_FORMAT}${RED_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
gcloud beta compute instance-groups managed create instance-group-2 \
    --project=$DEVSHELL_PROJECT_ID \
    --base-instance-name=instance-group-2 \
    --size=1 \
    --template=instance-template-2 \
    --zone=$ZONE_2 \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair

echo "${GREEN_TEXT}${BOLD_TEXT}⚖️  Configuring autoscaling for 'instance-group-2' in zone ${YELLOW_TEXT}${BOLD_TEXT}$ZONE_2${RESET_FORMAT}${GREEN_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
gcloud beta compute instance-groups managed set-autoscaling instance-group-2 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE_2 \
    --cool-down-period=45 \
    --max-num-replicas=5 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8

echo "${BLUE_TEXT}${BOLD_TEXT}💻 Launching utility VM 'utility-vm' in zone ${YELLOW_TEXT}${BOLD_TEXT}$ZONE_1${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT} within subnet ${CYAN_TEXT}${BOLD_TEXT}subnet-a${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
gcloud compute instances create utility-vm \
    --zone $ZONE_1 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --private-network-ip 10.10.20.50

echo "${YELLOW_TEXT}${BOLD_TEXT}❤️  Establishing health check 'my-ilb-health-check' in region ${CYAN_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${YELLOW_TEXT}${BOLD_TEXT} for project ${CYAN_TEXT}${BOLD_TEXT}$DEVSHELL_PROJECT_ID${RESET_FORMAT}${YELLOW_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -d '{
    "checkIntervalSec": 5,
    "description": "",
    "healthyThreshold": 2,
    "name": "my-ilb-health-check",
    "region": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 2
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/healthChecks"

echo "${GREEN_TEXT}${BOLD_TEXT}⏳ Waiting for health check setup...${RESET_FORMAT}"
total_seconds=30
bar_width=40
for (( i=1; i<=$total_seconds; i++ )); do
    # Calculate progress
    percentage=$(( i * 100 / total_seconds ))
    filled_width=$(( i * bar_width / total_seconds ))
    empty_width=$(( bar_width - filled_width ))

    # Build the progress bar string
    bar="["
    for (( j=0; j<$filled_width; j++ )); do bar+="#"; done
    for (( j=0; j<$empty_width; j++ )); do bar+="-"; done
    bar+="]"

    # Print the progress bar with percentage, using carriage return \r
    printf "\r${GREEN_TEXT}${BOLD_TEXT}%s %d%%${RESET_FORMAT}" "$bar" "$percentage"

    # Wait for 1 second
    sleep 1
done
# Print a newline at the end to ensure subsequent output starts on a new line
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}⚙️  Defining backend service 'my-ilb' in region ${YELLOW_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT} for project ${CYAN_TEXT}${BOLD_TEXT}$DEVSHELL_PROJECT_ID${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}, linking instance groups from zones ${CYAN_TEXT}${BOLD_TEXT}$ZONE_1${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT} and ${CYAN_TEXT}${BOLD_TEXT}$ZONE_2${RESET_FORMAT}${MAGENTA_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -d '{
    "backends": [
      {
        "balancingMode": "CONNECTION",
        "failover": false,
        "group": "projects/'"$DEVSHELL_PROJECT_ID"'/zones/'"$ZONE_1"'/instanceGroups/instance-group-1"
      },
      {
        "balancingMode": "CONNECTION",
        "failover": false,
        "group": "projects/'"$DEVSHELL_PROJECT_ID"'/zones/'"$ZONE_2"'/instanceGroups/instance-group-2"
      }
    ],
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "failoverPolicy": {},
    "healthChecks": [
      "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/healthChecks/my-ilb-health-check"
    ],
    "loadBalancingScheme": "INTERNAL",
    "logConfig": {
      "enable": false
    },
    "name": "my-ilb",
    "network": "projects/'"$DEVSHELL_PROJECT_ID"'/global/networks/my-internal-app",
    "protocol": "TCP",
    "region": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'",
    "sessionAffinity": "NONE"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices"

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for backend service setup...${RESET_FORMAT}"
total_seconds=20
bar_width=40
for (( i=1; i<=$total_seconds; i++ )); do
    # Calculate progress
    percentage=$(( i * 100 / total_seconds ))
    filled_width=$(( i * bar_width / total_seconds ))
    empty_width=$(( bar_width - filled_width ))

    # Build the progress bar string
    bar="["
    for (( j=0; j<$filled_width; j++ )); do bar+="#"; done
    for (( j=0; j<$empty_width; j++ )); do bar+="-"; done
    bar+="]"

    # Print the progress bar with percentage, using carriage return \r
    printf "\r${BLUE_TEXT}${BOLD_TEXT}%s %d%%${RESET_FORMAT}" "$bar" "$percentage"

    # Wait for 1 second
    sleep 1
done
# Print a newline at the end to ensure subsequent output starts on a new line
echo

echo "${RED_TEXT}${BOLD_TEXT}➡️  Setting up forwarding rule 'my-ilb-forwarding-rule' in region ${YELLOW_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${RED_TEXT}${BOLD_TEXT} for project ${CYAN_TEXT}${BOLD_TEXT}$DEVSHELL_PROJECT_ID${RESET_FORMAT}${RED_TEXT}${BOLD_TEXT}, targeting backend service ${CYAN_TEXT}${BOLD_TEXT}my-ilb${RESET_FORMAT}${RED_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
 curl -X POST -H "Content-Type: application/json" \
 -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
 -d '{
   "IPAddress": "10.10.30.5",
   "IPProtocol": "TCP",
   "allowGlobalAccess": false,
   "backendService": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/backendServices/my-ilb",
   "description": "",
   "ipVersion": "IPV4",
   "loadBalancingScheme": "INTERNAL",
   "name": "my-ilb-forwarding-rule",
   "networkTier": "PREMIUM",
   "ports": [
     "80"
   ],
   "region": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'",
   "subnetwork": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/subnetworks/subnet-b"
 }' \
 "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/forwardingRules"

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
