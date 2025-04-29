#!/bin/bash

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

echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction for Region Input
read -p "${BLUE_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
echo

# Displaying confirmation of user input
echo "${GREEN_TEXT}${BOLD_TEXT}You have entered the region: ${REGION}${RESET_FORMAT}"
echo

ID="$(gcloud projects list --format='value(PROJECT_ID)')"

cat > GenerateImage.py <<EOF_END
import argparse

import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(
  project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
  """Generate an image using a text prompt.
  Args:
    project_id: Google Cloud project ID, used to initialize Vertex AI.
    location: Google Cloud region, used to initialize Vertex AI.
    output_file: Local path to the output image file.
    prompt: The text prompt describing what you want to see."""

  vertexai.init(project=project_id, location=location)

  model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")

  images = model.generate_images(
    prompt=prompt,
    # Optional parameters
    number_of_images=1,
    seed=1,
    add_watermark=False,
  )

  images[0].save(location=output_file)

  return images

generate_image(
  project_id='$ID',
  location='$REGION',
  output_file='image.jpeg',
  prompt='Create an image of a cricket ground in the heart of Los Angeles',
)
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Generating an image... Please wait.${RESET_FORMAT}"
/usr/bin/python3 /home/student/GenerateImage.py
echo "${GREEN_TEXT}${BOLD_TEXT}Image generated successfully! Check 'image.jpeg' in your working directory.${RESET_FORMAT}"

ID="$(gcloud projects list --format='value(PROJECT_ID)')"

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

project_id = "$ID"
location = "$REGION"

response = generate_text(project_id, location)
print(response)
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Processing text with multimodal model first time... Please wait.${RESET_FORMAT}"
/usr/bin/python3 /home/student/genai.py
echo "${GREEN_TEXT}${BOLD_TEXT}Text process completed, see output above.${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting 30 seconds before running the process again...${RESET_FORMAT}"
sleep 30

echo "${YELLOW_TEXT}${BOLD_TEXT}Processing text with multimodal model second time... Please wait.${RESET_FORMAT}"
/usr/bin/python3 /home/student/genai.py
echo "${GREEN_TEXT}${BOLD_TEXT}Text process completed, see output above.${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
