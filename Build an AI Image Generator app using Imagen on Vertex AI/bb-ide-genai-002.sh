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

# Instructions for Region
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION_INPUT
export REGION=$REGION_INPUT

if [ -z "$REGION" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error:${RESET_FORMAT} ${WHITE_TEXT}${BOLD_TEXT}REGION is not set. Please set the REGION before running the script.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Region set to: ${RESET_FORMAT}${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"

ID="$(gcloud projects list --format='value(PROJECT_ID)')"

echo "${YELLOW_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} ${WHITE_TEXT}${BOLD_TEXT}$ID${RESET_FORMAT}"

# Prompt for user to input a prompt
echo "${YELLOW_TEXT}Defining the prompt for the image generation.${RESET_FORMAT}"

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

echo "${MAGENTA_TEXT}${BOLD_TEXT}Running the image generation process...${RESET_FORMAT}"
/usr/bin/python3 /home/student/GenerateImage.py

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
