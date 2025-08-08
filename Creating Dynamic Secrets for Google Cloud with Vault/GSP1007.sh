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
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
}

# Function to pause and wait for user input
pause_for_user() {
    echo -e "\n${YELLOW}Press ENTER to continue...${NC}"
    read -r
}

# =============================================================================
# TASK 1: INSTALL VAULT
# =============================================================================
print_task "1. Install Vault"

print_step "Step 1.1: Add HashiCorp GPG Key"
print_status "Adding the HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
print_success "HashiCorp GPG key added successfully!"

print_step "Step 1.2: Add HashiCorp Repository"
print_status "Adding the official HashiCorp Linux repository..."
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
print_success "HashiCorp repository added successfully!"

print_step "Step 1.3: Update and Install Vault"
print_status "Updating package list..."
sudo apt-get update

print_status "Installing Vault..."
sudo apt-get install vault -y
print_success "Vault installation completed!"

print_step "Step 1.4: Verify Installation"
print_status "Verifying Vault installation..."
vault --version
print_success "Vault installation verified!"

echo -e "\n${GREEN}✓ TASK 1 COMPLETED: Vault has been successfully installed!${NC}"

# =============================================================================
# TASK 2: DEPLOY VAULT
# =============================================================================
print_task "2. Deploy Vault"

print_step "Step 2.1: Create Vault Configuration"
print_status "Creating Vault configuration file (config.hcl)..."

cat > config.hcl <<EOF
storage "raft" {
  path    = "./vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true

disable_mlock = true
EOF

print_success "Configuration file created successfully!"

print_step "Step 2.2: Create Data Directory"
print_status "Creating ./vault/data directory for raft storage..."
mkdir -p ./vault/data
print_success "Data directory created!"

print_step "Step 2.3: Start Vault Server"
print_status "Starting Vault server in background..."
nohup vault server -config=config.hcl > vault_server.log 2>&1 &

print_status "Waiting for server to start (10 seconds)..."
sleep 10
print_success "Vault server started in background!"

print_warning "Note: Server logs are available in 'vault_server.log'"

print_step "Step 2.4: Set Environment Variables"
print_status "Setting VAULT_ADDR environment variable..."
export VAULT_ADDR='http://127.0.0.1:8200'
echo -e "${CYAN}VAULT_ADDR set to: ${WHITE}$VAULT_ADDR${NC}"

print_step "Step 2.5: Initialize Vault"
print_status "Initializing Vault (this creates unseal keys and root token)..."
vault operator init > vault_init_output.txt

print_success "Vault initialized! Keys and tokens saved to 'vault_init_output.txt'"

# Extract keys and token
KEY_1=$(grep 'Unseal Key 1:' vault_init_output.txt | awk '{print $NF}')
KEY_2=$(grep 'Unseal Key 2:' vault_init_output.txt | awk '{print $NF}')
KEY_3=$(grep 'Unseal Key 3:' vault_init_output.txt | awk '{print $NF}')
KEY_4=$(grep 'Unseal Key 4:' vault_init_output.txt | awk '{print $NF}')
KEY_5=$(grep 'Unseal Key 5:' vault_init_output.txt | awk '{print $NF}')
ROOT_TOKEN=$(grep 'Initial Root Token:' vault_init_output.txt | awk '{print $NF}')

echo -e "\n${YELLOW}IMPORTANT: Save these keys securely!${NC}"
echo -e "${CYAN}Unseal Keys and Root Token have been saved to 'vault_init_output.txt'${NC}"

print_step "Step 2.6: Unseal Vault"
print_status "Unsealing Vault with 3 keys (threshold requirement)..."

echo -e "${CYAN}Using Unseal Key 1...${NC}"
vault operator unseal $KEY_1

echo -e "${CYAN}Using Unseal Key 2...${NC}"
vault operator unseal $KEY_2

echo -e "${CYAN}Using Unseal Key 3...${NC}"
vault operator unseal $KEY_3

print_success "Vault unsealed successfully!"

print_step "Step 2.7: Authenticate with Root Token"
print_status "Logging in with root token..."
vault login $ROOT_TOKEN
print_success "Successfully authenticated as root user!"

echo -e "\n${GREEN}✓ TASK 2 COMPLETED: Vault is now deployed, initialized, and ready!${NC}"

# =============================================================================
# TASK 3: ENABLE GOOGLE CLOUD SECRETS ENGINE
# =============================================================================
print_task "3. Enable the Google Cloud secrets engine"

print_step "Step 3.1: Enable GCP Secrets Engine"
print_status "Enabling Google Cloud secrets engine..."
vault secrets enable gcp
print_success "GCP secrets engine enabled successfully!"

echo -e "\n${GREEN}✓ TASK 3 COMPLETED: Google Cloud secrets engine is now enabled!${NC}"

# =============================================================================
# TASK 4: CREATE DEFAULT CREDENTIALS
# =============================================================================
print_task "4. Create default credentials"

print_step "Step 4.1: Manual Service Account Key Creation Required"
print_warning "MANUAL STEPS REQUIRED:"
echo -e "${YELLOW}1. Go to Navigation menu > IAM & Admin > Service Accounts${NC}"
echo -e "${YELLOW}2. Click the dots next to 'Qwiklabs User Service Account' > 'Manage keys'${NC}"
echo -e "${YELLOW}3. Click 'Add Key' > 'Create new key'${NC}"
echo -e "${YELLOW}4. Leave type as 'JSON' and click 'Create'${NC}"
echo -e "${YELLOW}5. Save the downloaded key file${NC}"
echo -e "${YELLOW}6. Upload the key file to Cloud Shell using the Upload button${NC}"

pause_for_user

print_step "Step 4.2: List Available Files"
print_status "Listing files in home directory..."
cd ~
ls -la *.json 2>/dev/null || echo "No JSON files found yet"

print_warning "Make note of your service account key file name"
print_warning "It should look like: qwiklabs-gcp-XX-XXXXXXXXX-XXXXXXXXX.json"

echo -e "\n${CYAN}Please ensure your service account key file is uploaded before continuing.${NC}"
pause_for_user

echo -e "\n${GREEN}✓ TASK 4 COMPLETED: Service account key should be ready for use!${NC}"

# =============================================================================
# TASK 5: GENERATE CREDENTIALS USING VAULT
# =============================================================================
print_task "5. Generate credentials using Vault"

print_step "Step 5.1: Configure Vault with Service Account Credentials"
print_warning "You need to specify the path to your service account key file."

# Find JSON files
JSON_FILES=($(ls *.json 2>/dev/null))
if [ ${#JSON_FILES[@]} -eq 0 ]; then
    print_error "No JSON files found! Please upload your service account key file."
    echo -e "${YELLOW}Expected format: qwiklabs-gcp-XX-XXXXXXXXX-XXXXXXXXX.json${NC}"
    exit 1
elif [ ${#JSON_FILES[@]} -eq 1 ]; then
    CREDS_FILE=${JSON_FILES[0]}
    print_status "Found credentials file: $CREDS_FILE"
else
    print_warning "Multiple JSON files found:"
    for file in "${JSON_FILES[@]}"; do
        echo "  - $file"
    done
    CREDS_FILE=${JSON_FILES[0]}
    print_warning "Using first file: $CREDS_FILE"
fi

print_status "Configuring Vault with GCP credentials..."
vault write gcp/config \
    credentials=@$CREDS_FILE \
    ttl=3600 \
    max_ttl=86400

print_success "GCP configuration completed successfully!"

print_step "Step 5.2: Get Project ID"
export PROJECT_ID=$(gcloud config get-value project)
echo -e "${CYAN}Project ID: ${WHITE}$PROJECT_ID${NC}"

print_step "Step 5.3: Create Bindings Configuration"
print_status "Creating bindings.hcl file..."

cat > bindings.hcl <<EOF
resource "buckets/$PROJECT_ID" {
  roles = [
    "roles/storage.objectAdmin",
    "roles/storage.legacyBucketReader",
  ]
}
EOF

print_success "Bindings configuration created!"

print_step "Step 5.4: Configure OAuth2 Access Token Roleset"
print_status "Creating roleset for OAuth2 access tokens..."

vault write gcp/roleset/my-token-roleset \
    project="$PROJECT_ID" \
    secret_type="access_token" \
    token_scopes="https://www.googleapis.com/auth/cloud-platform" \
    bindings=@bindings.hcl

print_success "OAuth2 token roleset created successfully!"

print_step "Step 5.5: Test OAuth2 Token Generation"
print_status "Generating OAuth2 access token..."
vault read gcp/roleset/my-token-roleset/token > token_output.txt

# Extract token
OAUTH_TOKEN=$(grep 'token ' token_output.txt | grep -v 'token_ttl' | awk '{print $2}')

echo -e "${CYAN}Generated token (first 50 characters): ${WHITE}${OAUTH_TOKEN:0:50}...${NC}"

print_step "Step 5.6: Test API Call with Generated Token"
print_status "Testing bucket access with generated token..."

curl \
  "https://storage.googleapis.com/storage/v1/b/$PROJECT_ID" \
  --header "Authorization: Bearer $OAUTH_TOKEN" \
  --header "Accept: application/json" \
  --silent | head -5

print_status "Testing file download with generated token..."
curl -X GET \
  -H "Authorization: Bearer $OAUTH_TOKEN" \
  -o "sample.txt" \
  "https://storage.googleapis.com/storage/v1/b/$PROJECT_ID/o/sample.txt?alt=media" \
  --silent

if [ -f "sample.txt" ]; then
    print_status "Downloaded file contents:"
    echo -e "${WHITE}$(cat sample.txt)${NC}"
    print_success "File download successful!"
else
    print_warning "File download may have failed or file doesn't exist in bucket"
fi

print_step "Step 5.7: Configure Service Account Key Roleset"
print_status "Creating roleset for service account keys..."

vault write gcp/roleset/my-key-roleset \
    project="$PROJECT_ID" \
    secret_type="service_account_key" \
    bindings=@bindings.hcl

print_success "Service account key roleset created successfully!"

print_step "Step 5.8: Test Service Account Key Generation"
print_status "Generating service account key..."
vault read gcp/roleset/my-key-roleset/key > key_output.txt

print_success "Service account key generated successfully!"
echo -e "${CYAN}Key details saved to 'key_output.txt'${NC}"

echo -e "\n${GREEN}✓ TASK 5 COMPLETED: Credentials generation and testing successful!${NC}"

# =============================================================================
# TASK 6: CONFIGURE STATIC ACCOUNTS
# =============================================================================
print_task "6. Configure Static Accounts"

print_step "Step 6.1: Get Service Account Email"
print_status "Retrieving Qwiklabs User Service Account email..."
SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list --filter="displayName:'Qwiklabs User Service Account'" --format="value(email)")

if [ -z "$SERVICE_ACCOUNT_EMAIL" ]; then
    print_warning "Qwiklabs User Service Account not found, using project default..."
    SERVICE_ACCOUNT_EMAIL="$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com"
fi

echo -e "${CYAN}Service Account Email: ${WHITE}$SERVICE_ACCOUNT_EMAIL${NC}"

print_step "Step 6.2: Configure Static Account for OAuth2 Tokens"
print_status "Creating static account for OAuth2 access tokens..."

vault write gcp/static-account/my-token-account \
    service_account_email="$SERVICE_ACCOUNT_EMAIL" \
    secret_type="access_token" \
    token_scopes="https://www.googleapis.com/auth/cloud-platform" \
    bindings=@bindings.hcl

print_success "Static account for OAuth2 tokens configured successfully!"

print_step "Step 6.3: Configure Static Account for Service Account Keys"
print_status "Creating static account for service account keys..."

vault write gcp/static-account/my-key-account \
    service_account_email="$SERVICE_ACCOUNT_EMAIL" \
    secret_type="service_account_key" \
    bindings=@bindings.hcl

print_success "Static account for service account keys configured successfully!"

echo -e "\n${GREEN}✓ TASK 6 COMPLETED: Static accounts configuration successful!${NC}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
