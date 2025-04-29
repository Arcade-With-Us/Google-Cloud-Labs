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

LAB_MODEL="gemini-2.0-flash-001"

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read -r REGION
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Region set to:${RESET_FORMAT} ${CYAN_TEXT}$REGION${RESET_FORMAT}"

export REGION
ID="$(gcloud projects list --format='value(PROJECT_ID)')"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} ${CYAN_TEXT}$ID${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Using Model:${RESET_FORMAT} ${CYAN_TEXT}${LAB_MODEL}${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Generating SendChatwithoutStream.py...${RESET_FORMAT}"


cat > SendChatwithoutStream.py <<EOF
from google import genai
from google.genai.types import HttpOptions, ModelContent, Part, UserContent

import logging
from google.cloud import logging as gcp_logging

# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

client = genai.Client(
    vertexai=True,
    project='${ID}',
    location='${REGION}',
    http_options=HttpOptions(api_version="v1")
)
chat = client.chats.create(
    model="${LAB_MODEL}",
    history=[
        UserContent(parts=[Part(text="Hello")]),
        ModelContent(
            parts=[Part(text="Great to meet you. What would you like to know?")],
        ),
    ],
)
response = chat.send_message("What are all the colors in a rainbow?")
logging.info(f'Received response 1: {response.text}') # Added logging
print(response.text)

response = chat.send_message("Why does it appear when it rains?")
logging.info(f'Received response 2: {response.text}') # Added logging
print(response.text)
EOF

echo "${GREEN_TEXT}${BOLD_TEXT}Executing SendChatwithoutStream.py...${RESET_FORMAT}"
/usr/bin/python3 /home/student/SendChatwithoutStream.py
sleep 5

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Generating SendChatwithStream.py...${RESET_FORMAT}"

cat > SendChatwithStream.py <<EOF
from google import genai
from google.genai.types import HttpOptions

import logging
from google.cloud import logging as gcp_logging

# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

client = genai.Client(
    vertexai=True,
    project='${ID}',
    location='${REGION}',
    http_options=HttpOptions(api_version="v1")
)
chat = client.chats.create(model="${LAB_MODEL}")
response_text = ""

logging.info("Sending streaming prompt...") # Added logging
print("Streaming response:") # Added for clarity
for chunk in chat.send_message_stream("What are all the colors in a rainbow?"):
    print(chunk.text, end="")
    response_text += chunk.text
print() # Add a newline after streaming output
logging.info(f"Received full streaming response: {response_text}") # Added logging

EOF

echo "${GREEN_TEXT}${BOLD_TEXT}Executing SendChatwithStream.py...${RESET_FORMAT}"
/usr/bin/python3 /home/student/SendChatwithStream.py
# small delay
sleep 5

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
