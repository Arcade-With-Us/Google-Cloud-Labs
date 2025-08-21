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
echo -n "${CYAN_TEXT}${BOLD_TEXT}Enter the Repository Name: ${RESET_FORMAT}"
read REPO
echo -n "${MAGENTA_TEXT}${BOLD_TEXT}Enter the Docker Image: ${RESET_FORMAT}"
read DCKR_IMG
echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter the Tag Name: ${RESET_FORMAT}"
read TAG

export REPO="$REPO"
export DCKR_IMG="$DCKR_IMG"
export TAG="$TAG"

echo "${CYAN_TEXT}${BOLD_TEXT}Retrieving region and zone details...${RESET_FORMAT}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${MAGENTA_TEXT}${BOLD_TEXT}Loading setup script...${RESET_FORMAT}"
source <(gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh)

echo "${GREEN_TEXT}${BOLD_TEXT}Downloading and unpacking application...${RESET_FORMAT}"
gsutil cp gs://spls/gsp318/valkyrie-app.tgz .
tar -xzf valkyrie-app.tgz
cd valkyrie-app

echo "${YELLOW_TEXT}${BOLD_TEXT}Generating Dockerfile...${RESET_FORMAT}"
cat > Dockerfile <<EOF
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}Building Docker image...${RESET_FORMAT}"
docker build -t $DCKR_IMG:$TAG .

echo "${MAGENTA_TEXT}${BOLD_TEXT}Running Step 1 script...${RESET_FORMAT}"
cd ..
./step1_v2.sh

echo "${CYAN_TEXT}${BOLD_TEXT}Starting Docker container...${RESET_FORMAT}"
cd valkyrie-app
docker run -d -p 8080:8080 $DCKR_IMG:$TAG

echo "${MAGENTA_TEXT}${BOLD_TEXT}Running Step 2 script...${RESET_FORMAT}"
cd ..
./step2_v2.sh

cd valkyrie-app

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up Artifact Repository...${RESET_FORMAT}"
gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="awesome lab" \
    --async

echo "${BLUE_TEXT}${BOLD_TEXT}Setting up Docker authentication...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

sleep 30

echo "${CYAN_TEXT}${BOLD_TEXT}Tagging and uploading Docker image...${RESET_FORMAT}"

Image_ID=$(docker images --format='{{.ID}}')

docker tag $Image_ID $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG

docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG

echo "${GREEN_TEXT}${BOLD_TEXT}Modifying Kubernetes deployment...${RESET_FORMAT}"
sed -i s#IMAGE_HERE#$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG#g k8s/deployment.yaml

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up Kubernetes cluster...${RESET_FORMAT}"
gcloud container clusters get-credentials valkyrie-dev --zone $ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}Deploying application to Kubernetes...${RESET_FORMAT}"
kubectl create -f k8s/deployment.yaml
kubectl create -f k8s/service.yaml

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
