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

echo "${RED_TEXT}${BOLD_TEXT}🔔 Step 1:${RESET_FORMAT} ${RED_TEXT}Let's enable the Firestore API for your project.${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}Enabling Firestore API...${RESET_FORMAT}"
gcloud services enable firestore.googleapis.com

echo "${GREEN_TEXT}${BOLD_TEXT}🗄️ Step 2:${RESET_FORMAT} ${GREEN_TEXT}Now, we will create a Firestore database in Datastore mode.${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Firestore Database in Datastore mode...${RESET_FORMAT}"
gcloud firestore databases create --location=nam5 --type=datastore-mode

echo "${YELLOW_TEXT}${BOLD_TEXT}🐍 Step 3:${RESET_FORMAT} ${YELLOW_TEXT}Next, a Python script will be generated to insert a sample task entity into Firestore.${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Python script to insert task into Firestore...${RESET_FORMAT}"
cat << 'EOF' > insert_task.py
from google.cloud import datastore
from datetime import datetime

# Initialize client
client = datastore.Client()

# Define the kind and create a task entity
kind = "Task"
task_key = client.key(kind)

task = datastore.Entity(key=task_key)
task.update({
  "description": "Learn Google Cloud Datastore",
  "created": datetime.utcnow(),
  "done": False
})

client.put(task)
print("Task entity added successfully.")
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}💡 Step 4:${RESET_FORMAT} ${BLUE_TEXT}Let's set up a Python virtual environment to keep dependencies isolated.${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Creating and activating Python virtual environment...${RESET_FORMAT}"
python3 -m venv env
source env/bin/activate

echo "${MAGENTA_TEXT}${BOLD_TEXT}📦 Step 5:${RESET_FORMAT} ${MAGENTA_TEXT}We will now install the required Python package for Google Cloud Datastore.${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Installing google-cloud-datastore package...${RESET_FORMAT}"
pip install google-cloud-datastore

echo "${CYAN_TEXT}${BOLD_TEXT}⚡ Step 6:${RESET_FORMAT} ${CYAN_TEXT}Time to run the Python script and insert your first task entity into Firestore!${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Running Python script to insert task...${RESET_FORMAT}"
python insert_task.py

echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
