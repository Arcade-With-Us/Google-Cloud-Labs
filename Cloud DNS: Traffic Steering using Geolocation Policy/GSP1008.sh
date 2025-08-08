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

print_task() {
    echo -e "\n${CYAN}▶ TASK: $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
}

# =============================================================================
# TASK 1: ENABLE APIS
# =============================================================================
print_task "1. Enable APIs"

print_step "Step 1.1: Enable Compute Engine API"
print_status "Enabling Compute Engine API..."
gcloud services enable compute.googleapis.com
print_success "Compute Engine API enabled successfully!"

print_step "Step 1.2: Enable Cloud DNS API"
print_status "Enabling Cloud DNS API..."
gcloud services enable dns.googleapis.com
print_success "Cloud DNS API enabled successfully!"

print_step "Step 1.3: Verify APIs are Enabled"
print_status "Verifying enabled APIs..."
gcloud services list | grep -E 'compute|dns'
print_success "APIs verification completed!"

echo -e "\n${GREEN}✓ TASK 1 COMPLETED: APIs enabled successfully!${NC}"

# =============================================================================
# TASK 2: CONFIGURE FIREWALL
# =============================================================================
print_task "2. Configure the Firewall"

print_step "Step 2.1: Create IAP SSH Firewall Rule"
print_status "Creating firewall rule for SSH access through IAP..."
gcloud compute firewall-rules create fw-default-iapproxy \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:22,icmp \
--source-ranges=35.235.240.0/20
print_success "IAP SSH firewall rule created successfully!"

print_step "Step 2.2: Create HTTP Traffic Firewall Rule"
print_status "Creating firewall rule for HTTP traffic..."
gcloud compute firewall-rules create allow-http-traffic \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:80 \
--source-ranges=0.0.0.0/0 \
--target-tags=http-server
print_success "HTTP traffic firewall rule created successfully!"

echo -e "\n${GREEN}✓ TASK 2 COMPLETED: Firewall configuration completed!${NC}"

# =============================================================================
# TASK 3: LAUNCH CLIENT VMS
# =============================================================================
print_task "3. Launch Client VMs"

print_step "Step 3.1: Launch Client in US Region"
print_status "Creating US client VM..."
gcloud compute instances create us-client-vm \
--machine-type e2-micro \
--zone us-central1-a
print_success "US client VM created successfully!"

print_step "Step 3.2: Launch Client in Europe Region"
print_status "Creating Europe client VM..."
gcloud compute instances create europe-client-vm \
--machine-type e2-micro \
--zone europe-west1-b
print_success "Europe client VM created successfully!"

print_step "Step 3.3: Launch Client in Asia Region"
print_status "Creating Asia client VM..."
gcloud compute instances create asia-client-vm \
--machine-type e2-micro \
--zone asia-east1-a
print_success "Asia client VM created successfully!"

echo -e "\n${GREEN}✓ TASK 3 COMPLETED: Client VMs launched successfully!${NC}"

# =============================================================================
# TASK 4: LAUNCH SERVER VMS
# =============================================================================
print_task "4. Launch Server VMs"

print_step "Step 4.1: Launch Web Server in US Region"
print_status "Creating US web server with Apache startup script..."
gcloud compute instances create us-web-vm \
--zone=us-central1-a \
--machine-type=e2-micro \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
 apt-get update
 apt-get install apache2 -y
 echo "Page served from: us-central1-a" | \
 tee /var/www/html/index.html
 systemctl restart apache2'
print_success "US web server created successfully!"

print_step "Step 4.2: Launch Web Server in Europe Region"
print_status "Creating Europe web server with Apache startup script..."
gcloud compute instances create europe-web-vm \
--zone=europe-west1-b \
--machine-type=e2-micro \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
 apt-get update
 apt-get install apache2 -y
 echo "Page served from: europe-west1-b" | \
 tee /var/www/html/index.html
 systemctl restart apache2'
print_success "Europe web server created successfully!"

echo -e "\n${GREEN}✓ TASK 4 COMPLETED: Server VMs launched successfully!${NC}"

# =============================================================================
# TASK 5: SETTING UP ENVIRONMENT VARIABLES
# =============================================================================
print_task "5. Setting up Environment Variables"

print_step "Step 5.1: Get US Web Server Internal IP"
print_status "Retrieving internal IP address for US web server..."
export US_WEB_IP=$(gcloud compute instances describe us-web-vm --zone=us-central1-a --format="value(networkInterfaces.networkIP)")
echo -e "${CYAN}US Web Server IP: ${WHITE}$US_WEB_IP${NC}"
print_success "US web server IP retrieved!"

print_step "Step 5.2: Get Europe Web Server Internal IP"
print_status "Retrieving internal IP address for Europe web server..."
export EUROPE_WEB_IP=$(gcloud compute instances describe europe-web-vm --zone=europe-west1-b --format="value(networkInterfaces.networkIP)")
echo -e "${CYAN}Europe Web Server IP: ${WHITE}$EUROPE_WEB_IP${NC}"
print_success "Europe web server IP retrieved!"

echo -e "\n${GREEN}✓ TASK 5 COMPLETED: Environment variables configured!${NC}"

# =============================================================================
# TASK 6: CREATE THE PRIVATE ZONE
# =============================================================================
print_task "6. Create the Private Zone"

print_step "Step 6.1: Create Cloud DNS Private Zone"
print_status "Creating Cloud DNS private zone for example.com..."
gcloud dns managed-zones create example \
--description=test \
--dns-name=example.com \
--networks=default \
--visibility=private
print_success "Private DNS zone created successfully!"

echo -e "\n${GREEN}✓ TASK 6 COMPLETED: Private zone created successfully!${NC}"

# =============================================================================
# TASK 7: CREATE CLOUD DNS ROUTING POLICY
# =============================================================================
print_task "7. Create Cloud DNS Routing Policy"

print_step "Step 7.1: Create Geolocation Routing Policy"
print_status "Creating geo.example.com record with geolocation routing policy..."
gcloud dns record-sets create geo.example.com \
--ttl=5 --type=A --zone=example \
--routing-policy-type=GEO \
--routing-policy-data="us-central1=$US_WEB_IP;europe-west1=$EUROPE_WEB_IP"
print_success "Geolocation routing policy created successfully!"

print_step "Step 7.2: Verify DNS Record Configuration"
print_status "Verifying DNS record configuration..."
gcloud dns record-sets list --zone=example
print_success "DNS record verification completed!"

echo -e "\n${GREEN}✓ TASK 7 COMPLETED: Cloud DNS routing policy configured successfully!${NC}"


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
