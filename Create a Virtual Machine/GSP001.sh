# Set region and zone
gcloud config set compute/region us-east4
gcloud config set compute/zone us-east4-a
export REGION=us-east4
export ZONE=us-east4-a

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create gcelab instance with NGINX and HTTP firewall
gcloud compute instances create gcelab \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --tags=http-server \
  --metadata=startup-script='#!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx' \
  --scopes=https://www.googleapis.com/auth/cloud-platform

# Create firewall rule to allow HTTP traffic (if not already exists)
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server \
  --description="Allow HTTP traffic" \
  --quiet || echo "Firewall rule already exists or skipped."

# Create second instance using gcloud
gcloud compute instances create gcelab2 \
  --machine-type=e2-medium \
  --zone=$ZONE \
  --image-family=debian-11 \
  --image-project=debian-cloud

# Print External IP for gcelab
echo -e "\nAccess your NGINX site at: http://$(gcloud compute instances describe gcelab --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
