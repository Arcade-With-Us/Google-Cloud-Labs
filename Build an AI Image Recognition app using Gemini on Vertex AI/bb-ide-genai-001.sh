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

# Instruction for user to set the region
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read -r user_region
export REGION="$user_region"
echo "${GREEN_TEXT}${BOLD_TEXT}REGION set to: $REGION${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Retrieving Project ID...${RESET_FORMAT}"
ID="$(gcloud projects list --format='value(PROJECT_ID)')"
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID: $ID${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Creating genai.py file...${RESET_FORMAT}"
cat > genai.py <<EOF_END
import vertexai
from vertexai.generative_models import GenerativeModel, Part


def generate_text(project_id: str, location: str) -> str:
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    # Load the model
    multimodal_model = GenerativeModel("gemini-2.0-flash-001")
    # Query the model
    response = multimodal_model.generate_content(
        [
            # Add an example image
            Part.from_uri(
                "gs://generativeai-downloads/images/scones.jpg", mime_type="image/jpeg"
            ),
            # Add an example query
            "what is shown in this image?",
        ]
    )

    return response.text

# --------  Important: Variable declaration  --------

project_id = "$ID"
location = "$REGION"

#  --------   Call the Function  --------

response = generate_text(project_id, location)
print(response)

EOF_END
echo "${GREEN_TEXT}${BOLD_TEXT}genai.py file created successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Running the first instance of genai.py...${RESET_FORMAT}"
/usr/bin/python3 /home/student/genai.py
echo "${GREEN_TEXT}${BOLD_TEXT}First instance of genai.py completed!${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Sleeping for 30 seconds...${RESET_FORMAT}"
sleep 30
echo "${GREEN_TEXT}${BOLD_TEXT}Sleep time over.${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Running the second instance of genai.py...${RESET_FORMAT}"
/usr/bin/python3 /home/student/genai.py
echo "${GREEN_TEXT}${BOLD_TEXT}Second instance of genai.py completed!${RESET_FORMAT}"

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
