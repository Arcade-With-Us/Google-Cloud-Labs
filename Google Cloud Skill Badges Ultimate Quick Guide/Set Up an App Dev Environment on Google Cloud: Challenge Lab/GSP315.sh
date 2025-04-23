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
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}           INITIATING EXECUTION...          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the USER_2: ${RESET_FORMAT}" USER_2
export USER_2
echo "${MAGENTA_TEXT}${BOLD_TEXT}USER_2 set to: ${USER_2}${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE
export ZONE
echo "${MAGENTA_TEXT}${BOLD_TEXT}ZONE set to: ${ZONE}${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the TOPIC: ${RESET_FORMAT}" TOPIC
export TOPIC
echo "${MAGENTA_TEXT}${BOLD_TEXT}TOPIC set to: ${TOPIC}${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the FUNCTION: ${RESET_FORMAT}" FUNCTION
export FUNCTION
echo "${MAGENTA_TEXT}${BOLD_TEXT}FUNCTION set to: ${FUNCTION}${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}Environment variables have been successfully set:${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}USER_2=${USER_2}${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}ZONE=${ZONE}${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}TOPIC=${TOPIC}${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}FUNCTION=${FUNCTION}${RESET_FORMAT}"
echo ""

export REGION="${ZONE%-*}"

echo "${CYAN_TEXT}${BOLD_TEXT}Enabling required Google Cloud services...${RESET_FORMAT}"
gcloud services enable \
    artifactregistry.googleapis.com \
    cloudfunctions.googleapis.com \
    cloudbuild.googleapis.com \
    eventarc.googleapis.com \
    run.googleapis.com \
    logging.googleapis.com \
    pubsub.googleapis.com

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for services to be enabled...${RESET_FORMAT}"
sleep 30

echo "${CYAN_TEXT}${BOLD_TEXT}Fetching project number...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')

echo "${CYAN_TEXT}${BOLD_TEXT}Adding IAM policy bindings for Eventarc...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
        --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
        --role=roles/eventarc.eventReceiver

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for IAM policy binding to take effect...${RESET_FORMAT}"
sleep 20

echo "${CYAN_TEXT}${BOLD_TEXT}Fetching service account for KMS...${RESET_FORMAT}"
SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $DEVSHELL_PROJECT_ID)"

echo "${CYAN_TEXT}${BOLD_TEXT}Adding IAM policy bindings for Pub/Sub publisher...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT}" \
        --role='roles/pubsub.publisher'

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for IAM policy binding to take effect...${RESET_FORMAT}"
sleep 20

echo "${CYAN_TEXT}${BOLD_TEXT}Adding IAM policy bindings for Service Account Token Creator...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
        --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
        --role=roles/iam.serviceAccountTokenCreator

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for IAM policy binding to take effect...${RESET_FORMAT}"
sleep 20

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID-bucket

echo "${CYAN_TEXT}${BOLD_TEXT}Creating Pub/Sub topic: $TOPIC...${RESET_FORMAT}"
gcloud pubsub topics create $TOPIC

echo "${CYAN_TEXT}${BOLD_TEXT}Setting up the Cloud Function code...${RESET_FORMAT}"
mkdir lol
cd lol

cat > index.js <<'EOF_END'
const functions = require('@google-cloud/functions-framework');
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

functions.cloudEvent('$FUNCTION_NAME', cloudEvent => {
    const event = cloudEvent.data;

    console.log(`Event: ${event}`);
    console.log(`Hello ${event.bucket}`);

    const fileName = event.name;
    const bucketName = event.bucket;
    const size = "64x64"
    const bucket = gcs.bucket(bucketName);
    const topicName = "$TOPIC_NAME";
    const pubsub = new PubSub();
    if ( fileName.search("64x64_thumbnail") == -1 ){
        // doesn't have a thumbnail, get the filename extension
        var filename_split = fileName.split('.');
        var filename_ext = filename_split[filename_split.length - 1];
        var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
        if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
            // only support png and jpg at this point
            console.log(`Processing Original: gs://${bucketName}/${fileName}`);
            const gcsObject = bucket.file(fileName);
            let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
            let gcsNewObject = bucket.file(newFilename);
            let srcStream = gcsObject.createReadStream();
            let dstStream = gcsNewObject.createWriteStream();
            let resize = imagemagick().resize(size).quality(90);
            srcStream.pipe(resize).pipe(dstStream);
            return new Promise((resolve, reject) => {
                dstStream
                    .on("error", (err) => {
                        console.log(`Error: ${err}`);
                        reject(err);
                    })
                    .on("finish", () => {
                        console.log(`Success: ${fileName} → ${newFilename}`);
                            // set the content-type
                            gcsNewObject.setMetadata(
                            {
                                contentType: 'image/'+ filename_ext.toLowerCase()
                            }, function(err, apiResponse) {});
                            pubsub
                                .topic(topicName)
                                .publisher()
                                .publish(Buffer.from(newFilename))
                                .then(messageId => {
                                    console.log(`Message ${messageId} published.`);
                                })
                                .catch(err => {
                                    console.error('ERROR:', err);
                                });
                    });
            });
        }
        else {
            console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
        }
    }
    else {
        console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
    }
});
EOF_END

sed -i "8c\functions.cloudEvent('$FUNCTION', cloudEvent => { " index.js

sed -i "18c\  const topicName = '$TOPIC';" index.js

cat > package.json <<EOF_END
{
        "name": "thumbnails",
        "version": "1.0.0",
        "description": "Create Thumbnail of uploaded image",
        "scripts": {
            "start": "node index.js"
        },
        "dependencies": {
            "@google-cloud/functions-framework": "^3.0.0",
            "@google-cloud/pubsub": "^2.0.0",
            "@google-cloud/storage": "^5.0.0",
            "fast-crc32c": "1.0.4",
            "imagemagick-stream": "4.1.1"
        },
        "devDependencies": {},
        "engines": {
            "node": ">=4.3.2"
        }
    }
EOF_END

PROJECT_ID=$(gcloud config get-value project)
BUCKET_SERVICE_ACCOUNT="${PROJECT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "${CYAN_TEXT}${BOLD_TEXT}Adding IAM policy bindings for Pub/Sub publisher...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$BUCKET_SERVICE_ACCOUNT \
    --role=roles/pubsub.publisher

# Your existing deployment command
deploy_function() {
        echo "${CYAN_TEXT}${BOLD_TEXT}Deploying Cloud Function: $FUNCTION...${RESET_FORMAT}"
        gcloud functions deploy $FUNCTION \
        --gen2 \
        --runtime nodejs20 \
        --trigger-resource $DEVSHELL_PROJECT_ID-bucket \
        --trigger-event google.storage.object.finalize \
        --entry-point $FUNCTION \
        --region=$REGION \
        --source . \
        --quiet
}

# Variables
SERVICE_NAME="$FUNCTION"

# Loop until the Cloud Run service is created
while true; do
    # Run the deployment command
    deploy_function

    # Check if Cloud Run service is created
    if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null; then
        echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Run service is created. Exiting the loop.${RESET_FORMAT}"
        break
    else
        echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for Cloud Run service to be created...${RESET_FORMAT}"
        sleep 20
    fi
done

echo "${CYAN_TEXT}${BOLD_TEXT}Downloading sample image...${RESET_FORMAT}"
curl -o map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg

echo "${CYAN_TEXT}${BOLD_TEXT}Uploading sample image to Cloud Storage bucket...${RESET_FORMAT}"
gsutil cp map.jpg gs://$DEVSHELL_PROJECT_ID-bucket/map.jpg

echo "${CYAN_TEXT}${BOLD_TEXT}Removing IAM policy binding for user: $USER_2...${RESET_FORMAT}"
gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:$USER_2 \
--role=roles/viewer

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
