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

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 PHASE 1: Configuring Compute Zone Settings${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])") 

echo "${BLUE_TEXT}${BOLD_TEXT}🌟 PHASE 2: Activating Compute Engine Services${RESET_FORMAT}"
gcloud services enable compute.googleapis.com

echo "${GREEN_TEXT}${BOLD_TEXT}⏳ Waiting for services to initialize...${RESET_FORMAT}"
for ((i=15; i>=1; i--)); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r🕐 $i seconds remaining...${RESET_FORMAT}"
  sleep 1
done
echo -e "\n${GREEN_TEXT}${BOLD_TEXT}✅ Services ready!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🏗️ PHASE 3: Deploying Virtual Machine Instance${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🖥️ Creating a new VM instance named 'instance-1' using REST API...${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}⚙️ Configuration: n1-standard-1 machine type with Debian 11 OS${RESET_FORMAT}"
curl -X POST "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"instance-1\",
    \"machineType\": \"zones/$ZONE/machineTypes/n1-standard-1\",
    \"networkInterfaces\": [{}],
    \"disks\": [{
      \"type\": \"PERSISTENT\",
      \"boot\": true,
      \"initializeParams\": {
        \"sourceImage\": \"projects/debian-cloud/global/images/family/debian-11\"
      }
    }]
  }"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚦        CHECK PROGRESS FOR TASK 2        🚦${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

while true; do
  echo
  echo -n "${BOLD_TEXT}${YELLOW_TEXT}Have you checked your progress for Task 2 ? (Y/N): ${RESET_FORMAT}"
  read -r user_input
  if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
    echo
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Great! Proceeding to the next steps...${RESET_FORMAT}"
    echo
    break
  elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
    echo
    echo "${RED_TEXT}${BOLD_TEXT}❌ Please check your progress for Task 2 and then press Y to continue.${RESET_FORMAT}"
  else
    echo
    echo "${MAGENTA_TEXT}${BOLD_TEXT}⚠️ Invalid input. Please enter Y or N.${RESET_FORMAT}"
  fi
done

echo "${RED_TEXT}${BOLD_TEXT}🗑️ PHASE 4: Cleanup Operation - Removing VM Instance${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🔥 Deleting 'instance-1' to complete the API demonstration...${RESET_FORMAT}"
curl -X DELETE \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/instance-1"

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
