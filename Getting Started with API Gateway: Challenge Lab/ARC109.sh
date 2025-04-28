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

echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION: ${RESET_FORMAT}"
read REGION
export REGION=$REGION

echo "${GREEN_TEXT}${BOLD_TEXT}Enabling the API Gateway service...${RESET_FORMAT}"
gcloud services enable apigateway.googleapis.com --project=$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}Waiting for the service to be enabled...${RESET_FORMAT}"
sleep 15

echo "${BLUE_TEXT}${BOLD_TEXT}Creating a directory for the Cloud Function...${RESET_FORMAT}"
mkdir lol
cd lol

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the initial Cloud Function files...${RESET_FORMAT}"
cat > index.js <<EOF
/**
 * Responds to any HTTP request.
 *
 * @param {!express:Request} req HTTP request context.
 * @param {!express:Response} res HTTP response context.
 */
exports.helloWorld = (req, res) => {
    let message = req.query.message || req.body.message || 'Hello World!';
    res.status(200).send(message);
};
EOF

cat > package.json <<EOF
{
    "name": "sample-http",
    "version": "0.0.1"
}
EOF

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for the setup to stabilize...${RESET_FORMAT}"
sleep 45

echo "${CYAN_TEXT}${BOLD_TEXT}Fetching the project number...${RESET_FORMAT}"
export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="json(projectNumber)" --quiet | jq -r '.projectNumber')

echo "${BLUE_TEXT}${BOLD_TEXT}Retrieving the service account for KMS...${RESET_FORMAT}"
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

echo "${MAGENTA_TEXT}${BOLD_TEXT}Checking IAM policy bindings...${RESET_FORMAT}"
IAM_POLICY=$(gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID --format=json)

if [[ "$IAM_POLICY" == *"$SERVICE_ACCOUNT"* && "$IAM_POLICY" == *"roles/artifactregistry.reader"* ]]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}IAM binding exists:${RESET_FORMAT} $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
else
    echo "${RED_TEXT}${BOLD_TEXT}IAM binding does not exist:${RESET_FORMAT} $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
    
    echo "${CYAN_TEXT}${BOLD_TEXT}Creating IAM binding...${RESET_FORMAT}"
    gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/artifactregistry.reader

    echo "${GREEN_TEXT}${BOLD_TEXT}IAM binding created:${RESET_FORMAT} $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
fi

echo "${BLUE_TEXT}${BOLD_TEXT}Deploying the initial Cloud Function...${RESET_FORMAT}"
gcloud functions deploy GCFunction --region=$REGION --runtime=nodejs22 --trigger-http --gen2 --allow-unauthenticated --entry-point=helloWorld --max-instances 5 --source=./

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a Pub/Sub topic...${RESET_FORMAT}"
gcloud pubsub topics create demo-topic

echo "${CYAN_TEXT}${BOLD_TEXT}Updating the Cloud Function to include Pub/Sub integration...${RESET_FORMAT}"
cat > index.js <<EOF_CP
/**
 * Responds to any HTTP request.
 *
 * @param {!express:Request} req HTTP request context.
 * @param {!express:Response} res HTTP response context.
 */
const {PubSub} = require('@google-cloud/pubsub');
const pubsub = new PubSub();
const topic = pubsub.topic('demo-topic');
exports.helloWorld = (req, res) => {
    
    // Send a message to the topic
    topic.publishMessage({data: Buffer.from('Hello from Cloud Functions!')});
    res.status(200).send("Message sent to Topic demo-topic!");
};
EOF_CP

cat > package.json <<EOF_CP
{
    "name": "sample-http",
    "version": "0.0.1",
    "dependencies": {
        "@google-cloud/pubsub": "^3.4.1"
    }
}
EOF_CP

echo "${BLUE_TEXT}${BOLD_TEXT}Redeploying the updated Cloud Function...${RESET_FORMAT}"
gcloud functions deploy GCFunction --region=$REGION --runtime=nodejs22 --trigger-http --gen2 --allow-unauthenticated --entry-point=helloWorld --max-instances 5 --source=./

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the OpenAPI specification file...${RESET_FORMAT}"
cat > openapispec.yaml <<EOF_CP
swagger: '2.0'
info:
    title: GCFunction API
    description: Sample API on API Gateway with a Google Cloud Functions backend
    version: 1.0.0
schemes:
    - https
produces:
    - application/json
paths:
    /GCFunction:
        get:
            summary: gcfunction
            operationId: gcfunction
            x-google-backend:
                address: https://$REGION-$DEVSHELL_PROJECT_ID.cloudfunctions.net/GCFunction
            responses:
             '200':
                    description: A successful response
                    schema:
                        type: string
EOF_CP

echo "${CYAN_TEXT}${BOLD_TEXT}Fetching the project number again...${RESET_FORMAT}"
export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="value(projectNumber)")

echo "${BLUE_TEXT}${BOLD_TEXT}Generating a unique API ID...${RESET_FORMAT}"
export API_ID="gcfunction-api-$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-8} | head -n 1)"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the API Gateway...${RESET_FORMAT}"
gcloud api-gateway apis create $API_ID --project=$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}Creating the API configuration...${RESET_FORMAT}"
gcloud api-gateway api-configs create gcfunction-api --api=$API_ID --openapi-spec=openapispec.yaml --project=$DEVSHELL_PROJECT_ID --backend-auth-service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com

echo "${BLUE_TEXT}${BOLD_TEXT}Deploying the API Gateway...${RESET_FORMAT}"
gcloud api-gateway gateways create gcfunction-api --api=$API_ID --api-config=gcfunction-api --location=$REGION --project=$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
