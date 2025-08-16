#!/bin/bash

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

clear

echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo -n "${CYAN_TEXT}${BOLD_TEXT}Enter TOPIC Name: ${RESET_FORMAT}"
read TOPIC_ID
echo "${GREEN_TEXT}${BOLD_TEXT}You entered TOPIC Name: ${RESET_FORMAT}${TOPIC_ID}"
echo
echo -n "${CYAN_TEXT}${BOLD_TEXT}Enter MESSAGE: ${RESET_FORMAT}"
read MESSAGE
echo "${GREEN_TEXT}${BOLD_TEXT}You entered MESSAGE: ${RESET_FORMAT}${MESSAGE}"
echo
echo -n "${CYAN_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}"
read REGION
echo "${GREEN_TEXT}${BOLD_TEXT}You entered REGION: ${RESET_FORMAT}${REGION}"
echo
PROJECT_ID=$(gcloud config get-value project)
echo "${CYAN_TEXT}${BOLD_TEXT}Using PROJECT_ID: ${RESET_FORMAT}${PROJECT_ID}"

export BUCKET_NAME="${PROJECT_ID}-bucket"
echo "${CYAN_TEXT}${BOLD_TEXT}Bucket Name will be: ${RESET_FORMAT}${BUCKET_NAME}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Disabling Dataflow API if already enabled...${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling required APIs: Dataflow and Cloud Scheduler...${RESET_FORMAT}"
gcloud services enable dataflow.googleapis.com
gcloud services enable cloudscheduler.googleapis.com

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket: ${RESET_FORMAT}gs://${BUCKET_NAME}"
gsutil mb gs://$BUCKET_NAME

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Pub/Sub topic: ${RESET_FORMAT}${TOPIC_ID}"
gcloud pubsub topics create $TOPIC_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating App Engine application in region: ${RESET_FORMAT}${REGION}"
gcloud app create --region=$REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Waiting for App Engine setup to complete...${RESET_FORMAT}"
sleep 100

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Cloud Scheduler job to publish messages to the topic...${RESET_FORMAT}"
gcloud scheduler jobs create pubsub arcadewithus --schedule="* * * * *" \
  --topic=$TOPIC_ID --message-body="$MESSAGE"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Waiting for the Scheduler job to be ready...${RESET_FORMAT}"
sleep 20

echo "${YELLOW_TEXT}${BOLD_TEXT}Running the Cloud Scheduler job manually for testing...${RESET_FORMAT}"
gcloud scheduler jobs run arcadewithus

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a script to run Pub/Sub to GCS pipeline...${RESET_FORMAT}"
cat > run_pubsub_to_gcs_arcadewithus.sh <<EOF_CP
#!/bin/bash

# Set environment variables
export PROJECT_ID=$PROJECT_ID
export REGION=$REGION
export TOPIC_ID=$TOPIC_ID
export BUCKET_NAME=$BUCKET_NAME

# Clone the repository and navigate to the required directory
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd python-docs-samples/pubsub/streaming-analytics

# Install dependencies
pip install -U -r requirements.txt

# Run the Python script with parameters
python PubSubToGCS.py \
  --project=$PROJECT_ID \
  --region=$REGION \
  --input_topic=projects/$PROJECT_ID/topics/$TOPIC_ID \
  --output_path=gs://$BUCKET_NAME/samples/output \
  --runner=DataflowRunner \
  --window_size=2 \
  --num_shards=2 \
  --temp_location=gs://$BUCKET_NAME/temp
EOF_CP

chmod +x run_pubsub_to_gcs_arcadecrew.sh

echo "${YELLOW_TEXT}${BOLD_TEXT}Running the Pub/Sub to GCS pipeline script inside a Docker container...${RESET_FORMAT}"
docker run -it \
  -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID \
  -v "$(pwd)/run_pubsub_to_gcs_arcadecrew.sh:/run_pubsub_to_gcs_arcadecrew.sh" \
  python:3.7 \
  /bin/bash -c "/run_pubsub_to_gcs_arcadecrew.sh"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
