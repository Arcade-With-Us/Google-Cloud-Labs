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
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Set Project ID
echo "${YELLOW_TEXT}Please wait while setting the project ID...${RESET_FORMAT}"
gcloud config set project $DEVSHELL_PROJECT_ID
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID set to: $DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo

# Create Firestore Database
echo "${YELLOW_TEXT}Creating Firestore database in location nam5...${RESET_FORMAT}"
gcloud firestore databases create --location=nam5
echo "${GREEN_TEXT}${BOLD_TEXT}Firestore database created successfully!${RESET_FORMAT}"
echo

# Clone Repository
echo "${YELLOW_TEXT}Cloning the repository...${RESET_FORMAT}"
git clone https://github.com/rosera/pet-theory
echo "${GREEN_TEXT}${BOLD_TEXT}Repository cloned successfully!${RESET_FORMAT}"
echo

# Navigate to Directory
echo "${YELLOW_TEXT}Navigating to the lab directory...${RESET_FORMAT}"
cd pet-theory/lab01
echo "${GREEN_TEXT}${BOLD_TEXT}Successfully navigated to: $(pwd)${RESET_FORMAT}"
echo

# Install Firestore Package
echo "${YELLOW_TEXT}Installing @google-cloud/firestore package...${RESET_FORMAT}"
npm install @google-cloud/firestore
echo "${GREEN_TEXT}${BOLD_TEXT}@google-cloud/firestore package installed successfully!${RESET_FORMAT}"
echo

# Install Logging Package
echo "${YELLOW_TEXT}Installing @google-cloud/logging package...${RESET_FORMAT}"
npm install @google-cloud/logging
echo "${GREEN_TEXT}${BOLD_TEXT}@google-cloud/logging package installed successfully!${RESET_FORMAT}"
echo

# Download importTestData.js
echo "${YELLOW_TEXT}Downloading importTestData.js...${RESET_FORMAT}"
curl https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Importing%20Data%20to%20a%20Firestore%20Database/importTestData.js > importTestData.js
echo "${GREEN_TEXT}${BOLD_TEXT}importTestData.js downloaded successfully!${RESET_FORMAT}"
echo

# Install Faker
echo "${YELLOW_TEXT}Installing faker@5.5.3 package...${RESET_FORMAT}"
npm install faker@5.5.3
echo "${GREEN_TEXT}${BOLD_TEXT}faker@5.5.3 package installed successfully!${RESET_FORMAT}"
echo

# Download createTestData.js
echo "${YELLOW_TEXT}Downloading createTestData.js...${RESET_FORMAT}"
curl https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Importing%20Data%20to%20a%20Firestore%20Database/createTestData.js > createTestData.js
echo "${GREEN_TEXT}${BOLD_TEXT}createTestData.js downloaded successfully!${RESET_FORMAT}"
echo

# Create 1000 Test Records
echo "${YELLOW_TEXT}Creating 1000 test data records...${RESET_FORMAT}"
node createTestData 1000
echo "${GREEN_TEXT}${BOLD_TEXT}1000 test data records created successfully!${RESET_FORMAT}"
echo

# Import 1000 Records
echo "${YELLOW_TEXT}Importing 1000 test data records to Firestore...${RESET_FORMAT}"
node importTestData customers_1000.csv
echo "${GREEN_TEXT}${BOLD_TEXT}1000 test data records imported successfully!${RESET_FORMAT}"
echo

# Install csv-parse
echo "${YELLOW_TEXT}Installing csv-parse package...${RESET_FORMAT}"
npm install csv-parse
echo "${GREEN_TEXT}${BOLD_TEXT}csv-parse package installed successfully!${RESET_FORMAT}"
echo

# Create 20000 Test Records
echo "${YELLOW_TEXT}Creating 20000 test data records...${RESET_FORMAT}"
node createTestData 20000
echo "${GREEN_TEXT}${BOLD_TEXT}20000 test data records created successfully!${RESET_FORMAT}"
echo

# Import 20000 Records
echo "${YELLOW_TEXT}Importing 20000 test data records to Firestore...${RESET_FORMAT}"
node importTestData customers_20000.csv
echo "${GREEN_TEXT}${BOLD_TEXT}20000 test data records imported successfully!${RESET_FORMAT}"
echo

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
