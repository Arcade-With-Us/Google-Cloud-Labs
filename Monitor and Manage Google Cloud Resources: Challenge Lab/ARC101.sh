#!/bin/bash

# Define text colors and formatting
BLACK_TEXT=$(tput setaf 0)
RED_TEXT=$(tput setaf 1)
GREEN_TEXT=$(tput setaf 10) # Brighter Green
YELLOW_TEXT=$(tput setaf 3)
BLUE_TEXT=$(tput setaf 4)
MAGENTA_TEXT=$(tput setaf 5)
CYAN_TEXT=$(tput setaf 6)
WHITE_TEXT=$(tput setaf 7)

RESET_FORMAT=$(tput sgr0)
BOLD_TEXT=$(tput bold)
ITALIC_TEXT=$(tput sitm)
UNDERLINE_TEXT=$(tput smul)
clear # Clear the terminal screen

# --- Script Header ---
echo
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         STARTING EXECUTION...       ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# --- User Input ---
# Prompt user for necessary configuration values, displaying variable names in Cyan
read -p "${BOLD_TEXT}${WHITE_TEXT}Enter ${CYAN_TEXT}BUCKET_NAME${WHITE_TEXT}: ${RESET_FORMAT}" BUCKET_NAME
read -p "${BOLD_TEXT}${WHITE_TEXT}Enter ${CYAN_TEXT}TOPIC_NAME${WHITE_TEXT}: ${RESET_FORMAT}" TOPIC_NAME
read -p "${BOLD_TEXT}${WHITE_TEXT}Enter ${CYAN_TEXT}FUNCTION_NAME${WHITE_TEXT}: ${RESET_FORMAT}" FUNCTION_NAME
read -p "${BOLD_TEXT}${WHITE_TEXT}Enter ${CYAN_TEXT}REGION${WHITE_TEXT}: ${RESET_FORMAT}" REGION
read -p "${BOLD_TEXT}${WHITE_TEXT}Enter ${CYAN_TEXT}SECOND_USER${WHITE_TEXT}: ${RESET_FORMAT}" SECOND_USER
read -p "${BOLD_TEXT}${WHITE_TEXT}Enter your email for alert notifications (${CYAN_TEXT}ALERT_EMAIL${WHITE_TEXT}): ${RESET_FORMAT}" ALERT_EMAIL

# --- Helper Function ---
# Function to print section headers
section() {
        local title="$1"
        # Define separator characters and length
        local separator_char="="
        local separator_length=60 # Adjust length as desired
        local separator_line=$(printf "%${separator_length}s" | tr ' ' "$separator_char")

        # Calculate padding for centering the title within the separator line
        local title_display=" $title " # Add spaces for visual padding
        local title_len=${#title_display}
        local padding_total=$((separator_length - title_len))
        local padding_left=$((padding_total / 2))
        local padding_right=$((padding_total - padding_left))

        # Ensure padding is not negative
        [[ $padding_left -lt 0 ]] && padding_left=0
        [[ $padding_right -lt 0 ]] && padding_right=0

        # Create padding strings
        local pad_left_str=$(printf "%${padding_left}s")
        local pad_right_str=$(printf "%${padding_right}s")

        echo # Blank line before section
        # Print the top separator line in Cyan
        echo "${CYAN_TEXT}${BOLD_TEXT}${separator_line}${RESET_FORMAT}"
        # Print the title centered (approximately) between separators, using White text for contrast
        echo "${CYAN_TEXT}${BOLD_TEXT}${separator_char}${pad_left_str}${WHITE_TEXT}${BOLD_TEXT}${title_display}${CYAN_TEXT}${BOLD_TEXT}${pad_right_str}${separator_char}${RESET_FORMAT}"
        # Print the bottom separator line in Cyan
        echo "${CYAN_TEXT}${BOLD_TEXT}${separator_line}${RESET_FORMAT}"
        echo # Blank line after section
}

# --- Task 1: Initial Setup ---
section "TASK 1: INITIAL SETUP"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Configuring compute region: ${BOLD_TEXT}${WHITE_TEXT}$REGION${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Activating necessary Google Cloud services..."
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

# --- Task 2: Storage Configuration ---
section "TASK 2: STORAGE CONFIGURATION"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Initializing storage bucket: ${BOLD_TEXT}${WHITE_TEXT}$BUCKET_NAME${RESET_FORMAT}"
# Retry loop for bucket creation
for i in {1..3}; do
        if gsutil mb -l $REGION gs://$BUCKET_NAME; then
                break # Success
        elif [ $i -eq 3 ]; then
                echo "${BOLD_TEXT}${RED_TEXT}✗ Error creating bucket after 3 attempts${RESET_FORMAT}"
                # Consider exiting here if bucket is critical: exit 1
        else
                echo "${BOLD_TEXT}${YELLOW_TEXT}⚠ Bucket creation failed, retrying in 10 seconds...${RESET_FORMAT}"
                sleep 10
        fi
done

echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Assigning storage permissions for user: ${BOLD_TEXT}${WHITE_TEXT}$SECOND_USER${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$SECOND_USER \
  --role=roles/storage.objectViewer || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error granting storage access${RESET_FORMAT}"
        # Consider exiting: exit 1
}

# --- Task 3: Pub/Sub Configuration ---
section "TASK 3: PUB/SUB CONFIGURATION"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Setting up Pub/Sub topic: ${BOLD_TEXT}${WHITE_TEXT}$TOPIC_NAME${RESET_FORMAT}"
gcloud pubsub topics create $TOPIC_NAME || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error creating Pub/Sub topic${RESET_FORMAT}"
        # Consider exiting: exit 1
}

# --- Function Setup ---
section "FUNCTION SETUP"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Preparing function source directory..."
# Create directory and change into it, handle potential errors
mkdir -p drabhishek && cd drabhishek || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error creating or entering directory 'drabhishek'${RESET_FORMAT}"
        exit 1 # Exit if directory setup fails
}

echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Generating function source files (index.js, package.json)..."
# Create index.js
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
  const topicName = "REPLACE_WITH_YOUR_TOPIC ID"; // This will be replaced by sed
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
                                  resolve(); // Resolve the promise on success
                                })
                                .catch(err => {
                                  console.error('ERROR:', err);
                                  reject(err); // Reject the promise on error
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

# Replace placeholder topic name in index.js
sed -i "16c\  const topicName = '$TOPIC_NAME';" index.js || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error updating topic name in index.js${RESET_FORMAT}"
        # Consider exiting: exit 1
}

# Create package.json
cat > package.json <<'EOF_END'
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

# --- IAM Configuration ---
section "IAM CONFIGURATION"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Adjusting IAM permissions for service accounts..."
export PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
# Get the KMS service account
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

# Grant Artifact Registry Reader role to KMS service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/artifactregistry.reader || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error configuring Artifact Registry access for KMS SA${RESET_FORMAT}"
        # Consider exiting: exit 1
}

echo "${YELLOW_TEXT}Waiting 30 seconds for IAM changes to propagate...${RESET_FORMAT}"
sleep 30

# Get the Cloud Storage service account for the project
STORAGE_SERVICE_ACCOUNT="service-$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')@gs-project-accounts.iam.gserviceaccount.com"

# Grant Pub/Sub Publisher role to the Cloud Storage service account
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
        --member="serviceAccount:$STORAGE_SERVICE_ACCOUNT" \
        --role="roles/pubsub.publisher" || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error configuring Pub/Sub permissions for Storage SA${RESET_FORMAT}"
        # Consider exiting: exit 1
}

# --- Function Deployment ---
section "FUNCTION DEPLOYMENT"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Initiating Cloud Function deployment..."
# Function to encapsulate deployment command for retries
deploy_function() {
        gcloud functions deploy $FUNCTION_NAME \
        --gen2 \
        --runtime=nodejs20 \
        --region=$REGION \
        --source=. \
        --entry-point=thumbnail \
        --trigger-bucket=$BUCKET_NAME \
        --quiet # Suppress interactive prompts
}

# Retry loop for function deployment
for i in {1..3}; do
        if deploy_function; then
                break # Success
        elif [ $i -eq 3 ]; then
                echo "${BOLD_TEXT}${RED_TEXT}✗ Failed to deploy function after 3 attempts${RESET_FORMAT}"
                # Consider exiting: exit 1
        else
                echo "${BOLD_TEXT}${YELLOW_TEXT}⚠ Deployment failed, retrying in 60 seconds...${RESET_FORMAT}"
                sleep 60
        fi
done

# --- Testing ---
section "TESTING FUNCTION"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Fetching sample image for testing..."
# Download test image, handle potential errors
wget -q https://storage.googleapis.com/cloud-training/arc101/travel.jpg || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error downloading test image${RESET_FORMAT}"
        # Consider exiting: exit 1
}

echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Copying sample image to the bucket..."
# Retry loop for uploading test image
for i in {1..3}; do
        if gsutil cp travel.jpg gs://$BUCKET_NAME; then
                break # Success
        elif [ $i -eq 3 ]; then
                echo "${BOLD_TEXT}${RED_TEXT}✗ Error uploading test image after 3 attempts${RESET_FORMAT}"
                # Consider exiting: exit 1
        else
                echo "${BOLD_TEXT}${YELLOW_TEXT}⚠ Upload failed, retrying in 10 seconds...${RESET_FORMAT}"
                sleep 10
        fi
done

# --- Task 4: Alerting Policy ---
section "TASK 4: ALERTING POLICY"
echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Establishing notification channel for alerts..."
# Create email notification channel, capture its name, handle errors
CHANNEL_NAME=$(gcloud alpha monitoring channels create \
        --display-name="Email alerts" \
        --type=email \
        --channel-labels=email_address=$ALERT_EMAIL \
        --format="value(name)") || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error creating notification channel${RESET_FORMAT}"
        # Consider exiting: exit 1
}

echo "${BOLD_TEXT}${CYAN_TEXT}✓${RESET_FORMAT} Defining alerting policy for active function instances..."

# Create JSON file for the alerting policy definition
cat > active-instances-policy.json <<EOF_END
{
  "displayName": "Active Cloud Function Instances Alert",
  "combiner": "OR",
  "conditions": [
        {
          "displayName": "Cloud Function - Active Instances > 0",
          "conditionThreshold": {
                "filter": "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/active_instances\"",
                "aggregations": [
                  {
                        "alignmentPeriod": "60s",
                        "perSeriesAligner": "ALIGN_MAX"
                  }
                ],
                "comparison": "COMPARISON_GT",
                "thresholdValue": 0,
                "duration": "60s",
                "trigger": {
                   "count": 1
                }
          }
        }
  ],
  "alertStrategy": {
        "autoClose": "604800s"
  },
  "notificationChannels": ["$CHANNEL_NAME"]
}
EOF_END

# Create the monitoring policy using the JSON file, handle errors
gcloud alpha monitoring policies create --policy-from-file="active-instances-policy.json" || {
        echo "${BOLD_TEXT}${RED_TEXT}✗ Error creating alerting policy${RESET_FORMAT}"
        # Consider exiting: exit 1
}

exit 0 # Explicitly exit with success code
        

# --- Completion Message ---
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!       ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

# Optional: Add promotional message or next steps
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Find more helpful resources at:${RESET_FORMAT} ${BLUE_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo

# Clean up temporary files if needed (optional)
# rm -f travel.jpg active-instances-policy.json index.js package.json
# cd ..
# rm -rf drabhishek

exit 0 # Explicitly exit with success code
