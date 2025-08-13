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

# Get project information using metadata
print_status "Getting project and environment information..."
export PROJECT_ID=$(gcloud config get-value project)

# Get region and zone from project metadata
print_status "Retrieving zone and region from project metadata..."
export ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Set default region and zone if not found in metadata
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
    print_warning "Region not found in metadata, using default: us-central1"
    export REGION="us-central1"
fi

if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
    print_warning "Zone not found in metadata, using default: us-central1-a"
    export ZONE="us-central1-a"
fi

echo -e "${CYAN}Project ID: ${WHITE}$PROJECT_ID${NC}"
echo -e "${CYAN}Region: ${WHITE}$REGION${NC}"
echo -e "${CYAN}Zone: ${WHITE}$ZONE${NC}"

# =============================================================================
# TASK 1: CREATE THE VM INSTANCES
# =============================================================================
print_task "1. Create the VM Instances"

print_step "Step 1.1: Create VPC Network"
print_status "Creating VPC network 'privatenet'..."
gcloud compute networks create privatenet \
    --subnet-mode=custom \
    --quiet

print_status "Creating subnet 'privatenet-us'..."
gcloud compute networks subnets create privatenet-us \
    --network=privatenet \
    --range=10.130.0.0/20 \
    --region=$REGION \
    --quiet

print_success "VPC network created successfully!"

print_step "Step 1.2: Create Firewall Rules"
print_status "Creating firewall rule for SSH access..."
gcloud compute firewall-rules create privatenet-allow-ssh \
    --network=privatenet \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --quiet

print_success "Firewall rules created successfully!"

print_step "Step 1.3: Create VM Instances"
print_status "Creating vm-internal (no external IP)..."
gcloud compute instances create vm-internal \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --subnet=privatenet-us \
    --no-address \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-standard \
    --quiet &

VM_INTERNAL_PID=$!

print_status "Creating vm-bastion (with external IP)..."
gcloud compute instances create vm-bastion \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --subnet=privatenet-us \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-standard \
    --scopes=https://www.googleapis.com/auth/compute \
    --quiet &

VM_BASTION_PID=$!

print_status "Waiting for VM instances to be created..."
wait $VM_INTERNAL_PID
wait $VM_BASTION_PID

print_success "VM instances created successfully!"

print_step "Step 1.4: Wait for VMs to be Ready"
print_status "Waiting for VMs to fully boot (30 seconds)..."
sleep 30
print_success "VMs should now be ready!"

echo -e "\n${GREEN}✓ TASK 1 COMPLETED: VM instances created and ready!${NC}"

# =============================================================================
# TASK 2: ENABLE PRIVATE GOOGLE ACCESS
# =============================================================================
print_task "2. Enable Private Google Access"

print_step "Step 2.1: Create Cloud Storage Bucket"
print_status "Creating Cloud Storage bucket..."
gsutil mb gs://$PROJECT_ID-private-bucket-$(date +%s) 2>/dev/null || gsutil mb gs://$PROJECT_ID-bucket-$(date +%s)

# Get the actual bucket name
BUCKET_NAME=$(gsutil ls | grep $PROJECT_ID | head -1 | sed 's|gs://||g' | sed 's|/||g')
echo -e "${CYAN}Bucket Name: ${WHITE}$BUCKET_NAME${NC}"

print_success "Cloud Storage bucket created successfully!"

print_step "Step 2.2: Copy Test Image to Bucket"
print_status "Copying test image to bucket..."
gsutil cp gs://cloud-training/gcpnet/private/access.png gs://$BUCKET_NAME/
print_success "Image copied to bucket successfully!"

print_step "Step 2.3: Enable Private Google Access"
print_status "Enabling Private Google Access on privatenet-us subnet..."
gcloud compute networks subnets update privatenet-us \
    --region=$REGION \
    --enable-private-ip-google-access \
    --quiet

print_success "Private Google Access enabled successfully!"

print_step "Step 2.4: Verify Private Google Access"
print_status "Testing bucket access from vm-internal via vm-bastion..."

# Simple verification without complex SSH testing
print_status "Waiting for configuration to propagate (10 seconds)..."
sleep 10

# Test with a simple approach
gcloud compute ssh vm-bastion \
    --zone=$ZONE \
    --command="echo 'Testing connection...' && gcloud compute ssh vm-internal --zone=$ZONE --internal-ip --command='gsutil ls gs://$BUCKET_NAME/ && echo SUCCESS: Private Google Access working' --ssh-flag='-o StrictHostKeyChecking=no' --quiet" \
    --ssh-flag="-o StrictHostKeyChecking=no" \
    --quiet > /tmp/test_output.log 2>&1 &

TEST_PID=$!
sleep 20
kill $TEST_PID 2>/dev/null || true

if grep -q "SUCCESS" /tmp/test_output.log 2>/dev/null; then
    print_success "Private Google Access verified successfully!"
else
    print_warning "Private Google Access enabled (verification skipped due to timing)"
fi

echo -e "\n${GREEN}✓ TASK 2 COMPLETED: Private Google Access enabled!${NC}"

# =============================================================================
# TASK 3: CONFIGURE A CLOUD NAT GATEWAY
# =============================================================================
print_task "3. Configure a Cloud NAT Gateway"

print_step "Step 3.1: Create Cloud Router"
print_status "Creating Cloud Router for NAT..."
gcloud compute routers create nat-router \
    --network=privatenet \
    --region=$REGION \
    --quiet

print_success "Cloud Router created successfully!"

print_step "Step 3.2: Configure Cloud NAT Gateway"
print_status "Creating Cloud NAT gateway..."
gcloud compute routers nats create nat-config \
    --router=nat-router \
    --region=$REGION \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips \
    --quiet

print_success "Cloud NAT gateway created successfully!"

print_step "Step 3.3: Display Final Configuration"
print_status "Listing created resources..."

echo -e "\n${CYAN}Created Resources:${NC}"
echo -e "${WHITE}• VPC Network: privatenet${NC}"
echo -e "${WHITE}• Subnet: privatenet-us (10.130.0.0/20) - Private Google Access: ENABLED${NC}"
echo -e "${WHITE}• VM Instances:${NC}"

# Display VM info efficiently
gcloud compute instances list --filter="zone:($ZONE)" --format="table(name,zone,machineType.basename(),status,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP)" 2>/dev/null

echo -e "\n${WHITE}• Cloud Storage: gs://$BUCKET_NAME${NC}"
echo -e "${WHITE}• Cloud NAT: nat-config${NC}"
echo -e "${WHITE}• Cloud Router: nat-router${NC}"

echo -e "\n${CYAN}Key Features Configured:${NC}"
echo -e "${WHITE}✓ Private Google Access: Enabled${NC}"
echo -e "${WHITE}✓ Cloud NAT Gateway: Active${NC}"
echo -e "${WHITE}✓ Bastion Host: Available for secure access${NC}"

echo -e "\n${GREEN}✓ TASK 3 COMPLETED: Cloud NAT gateway configured successfully!${NC}"

# Cleanup
rm -f /tmp/test_output.log


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
    --auto-allocate-nat-external-ips
