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


clear
# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Step 1: Create bucket1.json
echo "${RED_TEXT}${BOLD_TEXT}Creating bucket1.json...${RESET_FORMAT}"
cat > bucket1.json <<EOF
{  
   "name": "$DEVSHELL_PROJECT_ID-bucket-1",
   "location": "us",
   "storageClass": "multi_regional"
}
EOF

# Step 2: Create bucket1
echo "${GREEN_TEXT}${BOLD_TEXT}Creating bucket1...${RESET_FORMAT}"
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" --data-binary @bucket1.json "https://storage.googleapis.com/storage/v1/b?project=$DEVSHELL_PROJECT_ID"

# Instructions before Step 3
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}  Bucket1 has been created. Now creating Bucket2.${RESET_FORMAT}"
echo ""

# Step 3: Create bucket2.json
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating bucket2.json...${RESET_FORMAT}"
cat > bucket2.json <<EOF
{  
   "name": "$DEVSHELL_PROJECT_ID-bucket-2",
   "location": "us",
   "storageClass": "multi_regional"
}
EOF

# Step 4: Create bucket2
echo "${BLUE_TEXT}${BOLD_TEXT}Creating bucket2...${RESET_FORMAT}"
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" --data-binary @bucket2.json "https://storage.googleapis.com/storage/v1/b?project=$DEVSHELL_PROJECT_ID"

# Instructions before Step 5
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}  Bucket2 has been created. Now Downloading the world.jpeg file.${RESET_FORMAT}"
echo ""

# Step 5: Download the image file
echo "${MAGENTA_TEXT}${BOLD_TEXT}Downloading the image file...${RESET_FORMAT}"
curl -LO https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Use%20APIs%20to%20Work%20with%20Cloud%20Storage%20Challenge%20Lab/world.jpeg

# Instructions before Step 6
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}  Image file has been downloaded. Now Uploading image to bucket1.${RESET_FORMAT}"
echo ""

# Step 6: Upload image file to bucket1
echo "${CYAN_TEXT}${BOLD_TEXT}Uploading the image file to bucket1...${RESET_FORMAT}"
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: image/jpeg" --data-binary @world.jpeg "https://storage.googleapis.com/upload/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o?uploadType=media&name=world.jpeg"

# Instructions before Step 7
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}  Image has been uploaded to bucket1. Now copying it to bucket2.${RESET_FORMAT}"
echo ""

# Step 7: Copy the image from bucket1 to bucket2
echo "${RED_TEXT}${BOLD_TEXT}Copying the image from bucket1 to bucket2...${RESET_FORMAT}"
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" --data '{"destination": "$DEVSHELL_PROJECT_ID-bucket-2"}' "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o/world.jpeg/copyTo/b/$DEVSHELL_PROJECT_ID-bucket-2/o/world.jpeg"

# Instructions before Step 8
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}  Image copied to bucket2. Now Setting public access for image in bucket1.${RESET_FORMAT}"
echo ""

# Step 8: Set public access for the image
echo "${GREEN_TEXT}${BOLD_TEXT}Setting public access for the image...${RESET_FORMAT}"
cat > public_access.json <<EOF
{
  "entity": "allUsers",
  "role": "READER"
}
EOF


curl -X POST --data-binary @public_access.json -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o/world.jpeg/acl"


read -p "${YELLOW_TEXT}${BOLD_TEXT}Have you checked the progress till TASK 4? (y/n) ${RESET_FORMAT}" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Great! Let's continue..."
else
    echo "Please check the progress and run the script again."
fi

# Instructions before Step 9
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}  Public access set. Now Deleting the image from bucket1.${RESET_FORMAT}"
echo ""

# Step 9: Delete the image from bucket1
echo "${BOLD_TEXT}${CYAN_TEXT}Deleting the image from bucket1...${RESET_FORMAT}"
curl -X DELETE -H "Authorization: Bearer $(gcloud auth print-access-token)" "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1/o/world.jpeg"

# Instructions before Step 10
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}  Image deleted from bucket1. Now deleting bucket1.${RESET_FORMAT}"
echo ""

# Step 10: Delete bucket1
echo "${BOLD_TEXT}${BLUE_TEXT}Deleting bucket1...${RESET_FORMAT}"
curl -X DELETE -H "Authorization: Bearer $(gcloud auth print-access-token)" "https://storage.googleapis.com/storage/v1/b/$DEVSHELL_PROJECT_ID-bucket-1"
