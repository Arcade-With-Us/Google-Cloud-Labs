# Define color codes
YELLOW='\033[0;33m'
BG_RED=`tput setab 1`
TEXT_GREEN=`tput setab 2`
TEXT_RED=`tput setaf 1`

BOLD=`tput bold`
RESET=`tput sgr0`

NC='\033[0m'

echo "${BG_RED}${BOLD}Starting Execution${RESET}"

# Prompt the user for region input with colored text
echo -e "${YELLOW}${BOLD}Please enter the region:${RESET}"
read REGION

# Set up other environment variables
export SERVICE_NAME=netflix-dataset-service
export FRNT_STG_SRV=frontend-staging-service
export FRNT_PRD_SRV=frontend-production-service

# Set project and enable necessary services
gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud services enable run.googleapis.com

# Create Firestore database in the specified region
gcloud firestore databases create --location=$REGION

# Clone the required repository and install dependencies
git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab06/firebase-import-csv/solution
npm install
node index.js netflix_titles_original.csv

# Build and deploy REST API version 0.1
cd ~/pet-theory/lab06/firebase-rest-api/solution-01
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1
gcloud beta run deploy $SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 --allow-unauthenticated --region=$REGION

# Build and deploy REST API version 0.2
cd ~/pet-theory/lab06/firebase-rest-api/solution-02
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
gcloud beta run deploy $SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2 --allow-unauthenticated --region=$REGION

# Get the service URL for REST API
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform=managed --region=$REGION --format="value(status.url)")

# Test the REST API with curl
curl -X GET $SERVICE_URL/2019

# Modify frontend app.js file to use REST API service URL
cd ~/pet-theory/lab06/firebase-frontend/public
sed -i 's/^const REST_API_SERVICE = "data\/netflix\.json"/\/\/ const REST_API_SERVICE = "data\/netflix.json"/' app.js
sed -i "1i const REST_API_SERVICE = \"$SERVICE_URL/2020\"" app.js

# Build and deploy frontend service
npm install
cd ~/pet-theory/lab06/firebase-frontend
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1
gcloud beta run deploy $FRNT_STG_SRV --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1 --region=$REGION --quiet

gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1
gcloud beta run deploy $FRNT_PRD_SRV --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1 --region=$REGION --quiet

# Final message
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
