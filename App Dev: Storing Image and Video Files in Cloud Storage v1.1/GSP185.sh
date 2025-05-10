#!/bin/bash

# Define color variables
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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Function to display colored messages
print_message() {
  echo -e "${BOLD_TEXT}${2}${1}${RESET_FORMAT}"
}

# Function to check command status
check_status() {
  if [ $? -eq 0 ]; then
    print_message "✅ $1" "${GREEN_TEXT}"
  else
    print_message "❌ $1" "${RED_TEXT}"
  fi
}

# Task 1: Reviewing the case study application
print_message "\n📋 TASK 1: REVIEWING THE CASE STUDY APPLICATION" "${YELLOW_TEXT}"

# Clone the repository
print_message "\n📦 Cloning the repository..." "${CYAN_TEXT}"
git clone https://github.com/GoogleCloudPlatform/training-data-analyst
check_status "Repository cloned successfully"

# Configure and run the case study application
print_message "\n🔧 Configuring the application..." "${CYAN_TEXT}"
cd ~/training-data-analyst/courses/developingapps/nodejs/cloudstorage/start
check_status "Changed directory successfully"

print_message "\n🚀 Running preparation script..." "${CYAN_TEXT}"
. prepare_environment.sh
check_status "Environment preparation completed"

# Task 3: Creating a Cloud Storage bucket
print_message "\n📋 TASK 3: CREATING A CLOUD STORAGE BUCKET" "${YELLOW_TEXT}"

print_message "\n🔧 Creating Cloud Storage bucket..." "${CYAN_TEXT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID-media
check_status "Cloud Storage bucket created"

print_message "\n🔧 Setting environment variables..." "${CYAN_TEXT}"
export GCLOUD_BUCKET=$DEVSHELL_PROJECT_ID-media
check_status "Environment variable set"

# Task 4: Adding objects to Cloud Storage
print_message "\n📋 TASK 4: ADDING OBJECTS TO CLOUD STORAGE" "${YELLOW_TEXT}"
print_message "\n${BOLD_TEXT}Modifying Code and Updating cloudstorage.js file" "${CYAN_TEXT}"

# Create the updated cloudstorage.js file
cat > server/gcp/cloudstorage.js << 'EOL'
// Copyright 2017, Google, Inc.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
'use strict';

const config = require('../config');

// Load the module for Cloud Storage
const Storage = require('@google-cloud/storage');

// Create the storage client
// The Storage(...) factory function accepts an options
// object which is used to specify which project's Cloud
// Storage buckets should be used via the projectId
// property.
// The projectId is retrieved from the config module.
// This module retrieves the project ID from the
// GCLOUD_PROJECT environment variable.

const storage = Storage({
 projectId: config.get('GCLOUD_PROJECT')
});

// Get the GCLOUD_BUCKET environment variable
// Recall that earlier you exported the bucket name into an
// environment variable.
// The config module provides access to this environment
// variable so you can use it in code

const GCLOUD_BUCKET = config.get('GCLOUD_BUCKET');

// Get a reference to the Cloud Storage bucket

const bucket = storage.bucket(GCLOUD_BUCKET);

function sendUploadToGCS (req, res, next) {
  if (!req.file) {
    return next();
  }

  const oname = Date.now() + req.file.originalname;
  // Get a reference to the new object
  const file = bucket.file(oname);

  // Create a stream to write the file into Cloud Storage
  const stream = file.createWriteStream({
    metadata: {
      contentType: req.file.mimetype
    }
  });

  // Attach event handler for error
  stream.on('error', (err) => {
    // If there's an error move to the next handler
    next(err);
  });

  // Attach event handler for finish
  stream.on('finish', () => {
    // Make the object publicly accessible
    file.makePublic().then(() => {
      // Set a new property on the file for the public URL for the object
      req.file.cloudStoragePublicUrl = `https://storage.googleapis.com/${GCLOUD_BUCKET}/${oname}`;
      // Invoke the next middleware handler
      next();
    });
  });

  // End the stream to upload the file's data
  stream.end(req.file.buffer);
}

// [START exports]
module.exports = {
  sendUploadToGCS
};
// [END exports]
EOL
check_status "Updated cloudstorage.js file"

echo -e "${CYAN_TEXT}${BOLD_TEXT}Installing Multer...${RESET_FORMAT}"

# Create the corrected cloudstorage.js file with Multer
cat > ~/training-data-analyst/courses/developingapps/nodejs/cloudstorage/start/server/gcp/cloudstorage.js << 'EOL'
// Copyright 2017, Google, Inc.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
'use strict';

const config = require('../config');

// Import multer for handling file uploads
const Multer = require('multer');

// Configure multer for memory storage
const multer = Multer({
  storage: Multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Load the module for Cloud Storage
const Storage = require('@google-cloud/storage');

// Create the storage client
const storage = Storage({
  projectId: config.get('GCLOUD_PROJECT')
});

// Get the GCLOUD_BUCKET environment variable
const GCLOUD_BUCKET = config.get('GCLOUD_BUCKET');

// Get a reference to the Cloud Storage bucket
const bucket = storage.bucket(GCLOUD_BUCKET);

function sendUploadToGCS(req, res, next) {
  if (!req.file) {
    return next();
  }

  const oname = Date.now() + req.file.originalname;
  // Get a reference to the new object
  const file = bucket.file(oname);

  // Create a stream to write the file into Cloud Storage
  const stream = file.createWriteStream({
    metadata: {
      contentType: req.file.mimetype
    }
  });

  // Attach event handler for error
  stream.on('error', (err) => {
    // If there's an error move to the next handler
    next(err);
  });

  // Attach event handler for finish
  stream.on('finish', () => {
    // Make the object publicly accessible
    file.makePublic().then(() => {
      // Set a new property on the file for the public URL for the object
      req.file.cloudStoragePublicUrl = `https://storage.googleapis.com/${GCLOUD_BUCKET}/${oname}`;
      // Invoke the next middleware handler
      next();
    });
  });

  // End the stream to upload the file's data
  stream.end(req.file.buffer);
}

// [START exports]
module.exports = {
  sendUploadToGCS,
  multer // Export the configured multer middleware
};
// [END exports]
EOL

# Start the application
print_message "\n🚀 Starting the application..." "${CYAN_TEXT}"
print_message "\nThe application will be started. Complete these manual steps:" "${BOLD_TEXT}${YELLOW_TEXT}"
print_message "1. Download the Google Cloud Storage Logo to your local machine from TASK 4" "${YELLOW_TEXT}"
print_message "2. Click Web Preview > Preview on port 8080 in Cloud Shell" "${YELLOW_TEXT}"
print_message "3. Click Create Question link and fill out the form with:" "${YELLOW_TEXT}"
print_message "   - Author: Your Name" "${YELLOW_TEXT}"
print_message "   - Quiz: Google Cloud Platform" "${YELLOW_TEXT}"
print_message "   - Title: Which product does this logo relate to?" "${YELLOW_TEXT}"
print_message "   - Image: Upload the Google-Cloud-Storage-Logo.svg file" "${YELLOW_TEXT}"
print_message "   - Answer 1: App Engine" "${YELLOW_TEXT}"
print_message "   - Answer 2: Cloud Storage (select this as correct answer)" "${YELLOW_TEXT}"
print_message "   - Answer 3: Compute Engine" "${YELLOW_TEXT}"
print_message "   - Answer 4: Container Engine" "${YELLOW_TEXT}"
print_message "4. Click Save" "${YELLOW_TEXT}"
print_message "5. Return to Cloud Console > Navigation menu > Cloud Storage" "${YELLOW_TEXT}"
print_message "6. Verify your new object in the bucket named ${DEVSHELL_PROJECT_ID}-media" "${YELLOW_TEXT}"

print_message "\nStarting the application now. Press Ctrl+C when you've completed verification." "${CYAN_TEXT}"
npm start

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
