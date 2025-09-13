
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

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}|       .... Welcome to ARCADE WITH US Tutorials....     | ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read REGION
export REGION=$REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling required Google Cloud services...${RESET_FORMAT}"
(gcloud services enable cloudbuild.googleapis.com
gcloud services enable storage-component.googleapis.com
gcloud services enable run.googleapis.com) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Listing active Google Cloud account...${RESET_FORMAT}"
(gcloud auth list --filter=status:ACTIVE --format="value(account)") & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the repository...${RESET_FORMAT}"
(git clone https://github.com/Deleplace/pet-theory.git) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Navigating to the lab directory...${RESET_FORMAT}"
(cd pet-theory/lab03) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading the server.go file...${RESET_FORMAT}"
(curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Create%20PDFs%20with%20Go%20and%20Cloud%20Run/server.go) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Building the Go application...${RESET_FORMAT}"
(go build -o server) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Dockerfile...${RESET_FORMAT}"
(cat > Dockerfile <<EOF_END
FROM debian:buster
RUN apt-get update -y \
  && apt-get install -y libreoffice \
  && apt-get clean
WORKDIR /usr/src/app
COPY server .
CMD [ "./server" ]
EOF_END
) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Submitting the Cloud Build job...${RESET_FORMAT}"
(gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying the Cloud Run service...${RESET_FORMAT}"
(gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region $REGION \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed \
  --max-instances=3) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Cloud Storage notification...${RESET_FORMAT}"
(gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Pub/Sub Cloud Run invoker service account...${RESET_FORMAT}"
(gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker") & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy binding for the Cloud Run service...${RESET_FORMAT}"
(gcloud run services add-iam-policy-binding pdf-converter \
  --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region $REGION \
  --platform managed) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Getting the project number...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects list \
 --format="value(PROJECT_NUMBER)" \
 --filter="$GOOGLE_CLOUD_PROJECT") & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy binding for the Pub/Sub service account...${RESET_FORMAT}"
(gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator) & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Retrieving the Cloud Run service URL...${RESET_FORMAT}"
SERVICE_URL=$(gcloud run services describe pdf-converter \
  --platform managed \
  --region $REGION \
  --format "value(status.url)") & spinner

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Pub/Sub subscription...${RESET_FORMAT}"
(gcloud pubsub subscriptions create pdf-conv-sub \
  --topic new-doc \
  --push-endpoint=$SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com) & spinner


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
