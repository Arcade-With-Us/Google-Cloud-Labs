#!/bin/bash

echo
echo "===================================================="
echo "                creating VM Instance                "
echo "===================================================="
echo

# Prompt user for region and zone
read -p ">> Enter the region (e.g. us-central1): " REGION
read -p ">> Enter the zone (e.g. us-central1-a): " ZONE

# Set variables
VM_NAME="my-vm-1"
MACHINE_TYPE="e2-standard-2"
IMAGE_FAMILY="ubuntu-2004-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

# Optional: Set defaults for gcloud config if not already set
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Create the VM instance
gcloud compute instances create $VM_NAME \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --image-family=$IMAGE_FAMILY \
  --image-project=$IMAGE_PROJECT \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --boot-disk-device-name=$VM_NAME

echo "VM $VM_NAME creation initiated in region $REGION, zone $ZONE."
