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

# Instruction 1: Display the project ID
echo "${YELLOW_TEXT}${BOLD_TEXT}Getting your Project ID...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Your Project ID is:${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${CYAN_TEXT}${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo

# Instruction 2: Creating connection
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a BigQuery connection named 'my-connection' in the 'US' location.${RESET_FORMAT}"
bq mk --connection --location=US --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE my-connection
echo "${GREEN_TEXT}${BOLD_TEXT}Connection 'my-connection' created successfully!${RESET_FORMAT}"
echo

# Instruction 3: Getting Service Account
echo "${YELLOW_TEXT}${BOLD_TEXT}Retrieving the service account associated with the connection.${RESET_FORMAT}"
SERVICE_ACCOUNT=$(bq show --format=json --connection $PROJECT_ID.US.my-connection | jq -r '.cloudResource.serviceAccountId')
echo "${YELLOW_TEXT}${BOLD_TEXT}Service Account ID:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$SERVICE_ACCOUNT${RESET_FORMAT}"
echo

# Instruction 4: Granting Permissions
echo "${MAGENTA_TEXT}${BOLD_TEXT}Granting the service account 'Storage Object Viewer' role to access data in your storage.${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/storage.objectViewer
echo "${GREEN_TEXT}${BOLD_TEXT}Service account has been granted the 'Storage Object Viewer' role.${RESET_FORMAT}"
echo

# Instruction 5: Creating Dataset
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a dataset named 'demo_dataset' in BigQuery.${RESET_FORMAT}"
bq mk demo_dataset
echo "${GREEN_TEXT}${BOLD_TEXT}Dataset 'demo_dataset' created successfully!${RESET_FORMAT}"
echo

# Instruction 6: Creating External Table Definition
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating an external table definition for a CSV file in your storage bucket.${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}The file is assumed to be located at 'gs://$PROJECT_ID/invoice.csv'.${RESET_FORMAT}"
bq mkdef \
--autodetect \
--connection_id=$PROJECT_ID.US.my-connection \
--source_format=CSV \
"gs://$PROJECT_ID/invoice.csv" > /tmp/tabledef.json
echo "${GREEN_TEXT}${BOLD_TEXT}External table definition created and saved to /tmp/tabledef.json${RESET_FORMAT}"
echo

# Instruction 7: Creating BigLake Table
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a BigLake table using the external table definition.${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This table will be named 'biglake_table' in the 'demo_dataset'.${RESET_FORMAT}"
bq mk --external_table_definition=/tmp/tabledef.json --project_id=$PROJECT_ID demo_dataset.biglake_table
echo "${GREEN_TEXT}${BOLD_TEXT}BigLake table 'biglake_table' created successfully!${RESET_FORMAT}"
echo

# Instruction 8: Creating External Table
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a regular external table using the same definition.${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}This table will be named 'external_table' in the 'demo_dataset'.${RESET_FORMAT}"
bq mk --external_table_definition=/tmp/tabledef.json --project_id=$PROJECT_ID demo_dataset.external_table
echo "${GREEN_TEXT}${BOLD_TEXT}External table 'external_table' created successfully!${RESET_FORMAT}"
echo

# Instruction 9: Getting Schema
echo "${YELLOW_TEXT}${BOLD_TEXT}Getting the schema of the external table and save it to a file.${RESET_FORMAT}"
bq show --schema --format=prettyjson  demo_dataset.external_table > /tmp/schema
echo "${GREEN_TEXT}${BOLD_TEXT}Schema saved to /tmp/schema${RESET_FORMAT}"
echo

# Instruction 10: Updating External Table
echo "${MAGENTA_TEXT}${BOLD_TEXT}Updating the external table with the schema we just retrieved.${RESET_FORMAT}"
bq update --external_table_definition=/tmp/tabledef.json --schema=/tmp/schema demo_dataset.external_table
echo "${GREEN_TEXT}${BOLD_TEXT}External table 'external_table' updated successfully!${RESET_FORMAT}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
ec
