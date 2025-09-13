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

gcloud config set compute/zone $ZONE

gcloud services enable cloudbuild.googleapis.com

gcloud services enable container.googleapis.com

git clone https://github.com/googlecodelabs/monolith-to-microservices.git

cd ~/monolith-to-microservices
./setup.sh

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/${MON_IDENT}:1.0.0 .

gcloud container clusters create $CLUSTER --num-nodes 3

kubectl create deployment $MON_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$MON_IDENT:1.0.0

kubectl expose deployment $MON_IDENT --type=LoadBalancer --port 80 --target-port 8080

cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/$ORD_IDENT:1.0.0 .

cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/$PROD_IDENT:1.0.0 .

kubectl create deployment $ORD_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$ORD_IDENT:1.0.0

kubectl expose deployment $ORD_IDENT --type=LoadBalancer --port 80 --target-port 8081

kubectl create deployment $PROD_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$PROD_IDENT:1.0.0
kubectl expose deployment $PROD_IDENT --type=LoadBalancer --port 80 --target-port 8082

cd ~/monolith-to-microservices/react-app
cd ~/monolith-to-microservices/microservices/src/frontend

gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/$FRONT_IDENT:1.0.0 .

kubectl create deployment $FRONT_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$FRONT_IDENT:1.0.0
kubectl expose deployment $FRONT_IDENT --type=LoadBalancer --port 80 --target-port 8080

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
