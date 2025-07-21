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

read -p "${CYAN_TEXT}${BOLD_TEXT}Enter your GCP region: ${RESET_FORMAT}" LOCATION
export LOCATION

echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${CYAN_TEXT}Creating a Pub/Sub schema using Avro format.${RESET_FORMAT}"
echo
gcloud pubsub schemas create city-temp-schema \
        --type=avro \
        --definition='{                                             
            "type" : "record",                               
            "name" : "Avro",                                 
            "fields" : [                                     
            {                                                
                "name" : "city",                             
                "type" : "string"                            
            },                                               
            {                                                
                "name" : "temperature",                      
                "type" : "double"                            
            },                                               
            {                                                
                "name" : "pressure",                         
                "type" : "int"                               
            },                                               
            {                                                
                "name" : "time_position",                    
                "type" : "string"                            
            }                                                
        ]                                                    
    }'

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${GREEN_TEXT}Creating a Pub/Sub topic with JSON message encoding.${RESET_FORMAT}"
echo
gcloud pubsub topics create temp-topic \
        --message-encoding=JSON \
        --schema=temperature-schema

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${MAGENTA_TEXT}Enabling required Google Cloud services.${RESET_FORMAT}"
echo
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${BLUE_TEXT}Creating Node.js function code that processes Pub/Sub messages.${RESET_FORMAT}"
echo
cat > index.js <<'EOF_END'
const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent callback with the Functions Framework that will
// be executed when the Pub/Sub trigger topic receives a message.
functions.cloudEvent('helloPubSub', cloudEvent => {
  // The Pub/Sub message is passed as the CloudEvent's data payload.
  const base64name = cloudEvent.data.message.data;

  const name = base64name
    ? Buffer.from(base64name, 'base64').toString()
    : 'World';

  console.log(`Hello, ${name}!`);
});
EOF_END

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${YELLOW_TEXT}Creating package.json with required dependencies.${RESET_FORMAT}"
echo
cat > package.json <<'EOF_END'
{
  "name": "gcf_hello_world",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF_END

echo
echo "${RED_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${RED_TEXT}Deploying the Cloud Function with Pub/Sub trigger.${RESET_FORMAT}"
echo
deploy_function() {
gcloud functions deploy gcf-pubsub \
  --gen2 \
  --runtime=nodejs22 \
  --region=$LOCATION \
  --source=. \
  --entry-point=helloPubSub \
  --trigger-topic gcf-topic \
  --quiet
  }

deploy_success=false

echo "${CYAN_TEXT}${BOLD_TEXT}Deployment Status:${RESET_FORMAT} ${CYAN_TEXT}Attempting to deploy function...${RESET_FORMAT}"
echo
while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "${GREEN_TEXT}${BOLD_TEXT}Success:${RESET_FORMAT} ${GREEN_TEXT}Function deployed successfully...${RESET_FORMAT}"
        deploy_success=true
    else
        echo "${YELLOW_TEXT}${BOLD_TEXT}Retrying:${RESET_FORMAT} ${YELLOW_TEXT}Deployment failed, will retry in 20 seconds...${RESET_FORMAT}"
        sleep 20
    fi
done

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
