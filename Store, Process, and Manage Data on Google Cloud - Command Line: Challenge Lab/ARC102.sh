#!/bin/bash

# Bright Foreground Colors
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

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}================================================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Please provide the following details for the setup:       ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}================================================================${RESET_FORMAT}"
echo


read -p "${MAGENTA_TEXT}${BOLD_TEXT}Enter BUCKET_NAME: ${RESET_FORMAT}" BUCKET_NAME
echo "${BLUE_TEXT}${BOLD_TEXT}You entered BUCKET_NAME: $BUCKET_NAME ${RESET_FORMAT}"
echo
read -p "${MAGENTA_TEXT}${BOLD_TEXT}Enter TOPIC_NAME: ${RESET_FORMAT}" TOPIC_NAME
echo "${BLUE_TEXT}${BOLD_TEXT}You entered TOPIC_NAME: $TOPIC_NAME ${RESET_FORMAT}"
echo
read -p "${MAGENTA_TEXT}${BOLD_TEXT}Enter FUNCTION_NAME: ${RESET_FORMAT}" FUNCTION_NAME
echo "${BLUE_TEXT}${BOLD_TEXT}You entered FUNCTION_NAME: $FUNCTION_NAME ${RESET_FORMAT}"
echo
read -p "${MAGENTA_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
echo "${BLUE_TEXT}${BOLD_TEXT}You entered REGION: $REGION ${RESET_FORMAT}"
echo


gcloud config set compute/region $REGION
export PROJECT_ID=$(gcloud config get-value project)


gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating GCS Bucket: gs://$BUCKET_NAME in $REGION      ${RESET_FORMAT}"
echo

gsutil mb -l $REGION gs://$BUCKET_NAME

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating Pub/Sub Topic: $TOPIC_NAME                      ${RESET_FORMAT}"
echo

gcloud pubsub topics create $TOPIC_NAME



PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Granting Pub/Sub Publisher role to the service account ${RESET_FORMAT}"
echo

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher
  
echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating required Files and Directories                   ${RESET_FORMAT}"
echo

mkdir ~/arcadecrew && cd $_
touch index.js && touch package.json


cat > index.js <<'EOF_END'
/* globals exports, require */
//jshint strict: false
//jshint esversion: 6
"use strict";
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

exports.thumbnail = (event, context) => {
  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "REPLACE_WITH_YOUR_TOPIC ID";
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
};
EOF_END


sed -i '16c\  const topicName = "'$TOPIC_NAME'";' index.js



cat > package.json <<EOF_END
{
    "name": "thumbnails",
    "version": "1.0.0",
    "description": "Create Thumbnail of uploaded image",
    "scripts": {
      "start": "node index.js"
    },
    "dependencies": {
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

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Deploying Google Cloud Functions                         ${RESET_FORMAT}"
echo


  
  deploy_function () {
    gcloud functions deploy $FUNCTION_NAME \
      --gen2 \
      --runtime nodejs20 \
      --entry-point thumbnail \
      --source . \
      --region $REGION \
      --trigger-bucket $BUCKET_NAME \
      --allow-unauthenticated \
      --trigger-location $REGION \
      --max-instances 5 \
      --quiet
  }
    
    # Variables
    SERVICE_NAME="$FUNCTION_NAME"
    
    while true; do
      deploy_function
    
      if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null; then
        echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Run service is created. Exiting the loop.${RESET_FORMAT}"
        break
      else
        echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for Cloud Run service to be created...${RESET_FORMAT}"
        sleep 10
      fi
    done

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Downloading test Image                                       ${RESET_FORMAT}"
echo

wget https://storage.googleapis.com/cloud-training/arc102/wildlife.jpg

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Copying test Image to GCS                                 ${RESET_FORMAT}"
echo


gsutil cp wildlife.jpg gs://$BUCKET_NAME
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
