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


gcloud services disable dataflow.googleapis.com

gcloud services enable dataflow.googleapis.com

gsutil mb gs://$DEVSHELL_PROJECT_ID-bucket


cat <<EOF > Dockerfile
# Use the official Python 3.9 image as a base
FROM python:3.9

# Set environment variables for GCP project and region
ARG $DEVSHELL_PROJECT_ID
ARG $REGION

# Install Apache Beam with GCP extras
RUN pip install 'apache-beam[gcp]'==2.42.0

# Set up the GCP bucket path
ENV BUCKET=gs://\${DEVSHELL_PROJECT_ID}-bucket

# Copy the script into the container
COPY run_beam.sh /run_beam.sh

# Give execute permission to the script
RUN chmod +x /run_beam.sh

# Execute the script
CMD ["/run_beam.sh"]
EOF


cat <<EOF > run_beam.sh
#!/bin/bash

# Set necessary environment variables
export DEVSHELL_PROJECT_ID=\${DEVSHELL_PROJECT_ID}
export REGION=\${REGION}
export BUCKET=gs://\${DEVSHELL_PROJECT_ID}-bucket

# Run the local WordCount example to ensure installation
python -m apache_beam.examples.wordcount --output OUTPUT_FILE

# Run the WordCount example using the Dataflow runner
python -m apache_beam.examples.wordcount --project \$DEVSHELL_PROJECT_ID \
  --runner DataflowRunner \
  --staging_location \$BUCKET/staging \
  --temp_location \$BUCKET/temp \
  --output \$BUCKET/results/output \
  --region \$REGION
EOF


# Build the Docker image
docker build --build-arg DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID --build-arg REGION=$REGION -t beam-dataflow:latest .

# Run the Docker container
docker run -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID -e REGION=$REGION beam-dataflow:latest

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
