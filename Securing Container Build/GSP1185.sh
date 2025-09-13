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

echo "${MAGENTA_TEXT}${BOLD_TEXT}Retrieving Project ID, Project Number, Zone, and Region...${RESET_FORMAT}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "${GREEN_TEXT}${BOLD_TEXT}Project ID: ${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Project Number: ${PROJECT_NUMBER}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Zone: ${ZONE}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Region: ${REGION}${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling the Artifact Registry API...${RESET_FORMAT}"

gcloud services enable artifactregistry.googleapis.com

echo "${GREEN_TEXT}${BOLD_TEXT}Artifact Registry API enabled.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the Java Docs Samples repository...${RESET_FORMAT}"

git clone https://github.com/GoogleCloudPlatform/java-docs-samples
cd java-docs-samples/container-registry/container-analysis

echo "${GREEN_TEXT}${BOLD_TEXT}Repository cloned successfully and directory changed to container-analysis.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Maven repository named container-dev-java-repo...${RESET_FORMAT}"

gcloud artifacts repositories create container-dev-java-repo \
    --repository-format=maven \
    --location=$REGION \
    --description="Java package repository for Container Dev Workshop"

echo "${GREEN_TEXT}${BOLD_TEXT}Container Dev Java Repository created successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Describing the newly created repository...${RESET_FORMAT}"

gcloud artifacts repositories describe container-dev-java-repo \
    --location=$REGION

echo "${GREEN_TEXT}${BOLD_TEXT}Container Dev Java Repository described.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}Creating a remote Maven repository for caching Maven Central...${RESET_FORMAT}"

gcloud artifacts repositories create maven-central-cache \
    --project=$PROJECT_ID \
    --repository-format=maven \
    --location=$REGION \
    --description="Remote repository for Maven Central caching" \
    --mode=remote-repository \
    --remote-repo-config-desc="Maven Central" \
    --remote-mvn-repo=MAVEN-CENTRAL

echo "${GREEN_TEXT}${BOLD_TEXT}Maven Central Cache created successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the policy.json file for the virtual repository...${RESET_FORMAT}"

cat > ./policy.json << EOF
[
  {
    "id": "private",
    "repository": "projects/${PROJECT_ID}/locations/$REGION/repositories/container-dev-java-repo",
    "priority": 100
  },
  {
    "id": "central",
    "repository": "projects/${PROJECT_ID}/locations/$REGION/repositories/maven-central-cache",
    "priority": 80
  }
]

EOF

echo "${GREEN_TEXT}${BOLD_TEXT}policy.json file created successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Virtual Maven Repository...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Please wait this will take some time...${RESET_FORMAT}"

gcloud artifacts repositories create virtual-maven-repo \
    --project=${PROJECT_ID} \
    --repository-format=maven \
    --mode=virtual-repository \
    --location=$REGION \
    --description="Virtual Maven Repo" \
    --upstream-policy-file=./policy.json

echo "${GREEN_TEXT}${BOLD_TEXT}Virtual Maven Repository created successfully.${RESET_FORMAT}"

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
