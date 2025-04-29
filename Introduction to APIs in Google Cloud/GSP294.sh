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
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo ""

# Function to display messages with formatting
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${BOLD_TEXT}${message}${RESET_FORMAT}"
}

# Function to display error messages
print_error() {
    local message=$1
    echo -e "${RED_TEXT}${BOLD_TEXT}ERROR: ${message}${RESET_FORMAT}"
}

# Function to display success messages
print_success() {
    local message=$1
    echo -e "${GREEN_TEXT}${BOLD_TEXT}SUCCESS: ${message}${RESET_FORMAT}"
}

# Function to handle errors and exit
handle_error() {
    local exit_code=$1
    local error_message=$2
    
    if [ $exit_code -ne 0 ]; then
        print_error "$error_message"
        exit $exit_code
    fi
}

# Function to check command existence
check_command() {
    local command=$1
    if ! command -v "$command" &> /dev/null; then
        print_error "$command could not be found. Please install it before continuing."
        exit 1
    fi
}

# Check for required commands
check_command "gcloud"
check_command "gsutil"
check_command "curl"
check_command "nano"

# Step 1: Set the region for the project
set_region() {
    print_message "$BLUE_TEXT" "TASK 1: Setting the compute region..."
    
    # Get region from user or use default
    read -p "Enter REGION: " REGION
    REGION=${REGION:-us-central1}
    
    gcloud config set compute/region $REGION
    handle_error $? "Failed to set compute region"
    
    print_success "Region set to: $REGION"
    echo
}

# Step 2: Creating JSON File
create_json_file() {
    print_message "$BLUE_TEXT" "TASK 2: Creating values.json file..."
    
    # Get Project ID
    PROJECT_ID=$(gcloud config get-value project)
    handle_error $? "Failed to get project ID"
    
    # Create the JSON file
    cat > values.json << EOL
{
  "name": "${PROJECT_ID}-bucket",
  "location": "us",
  "storageClass": "multi_regional"
}
EOL
    handle_error $? "Failed to create values.json file"
    
    print_success "values.json created successfully with Project ID: $PROJECT_ID"
    echo
    
    # Export project ID for later use
    export PROJECT_ID
}

# Step 3: Ensure API is enabled
enable_api() {
    print_message "$BLUE_TEXT" "TASK 3: Ensuring Cloud Storage API is enabled..."
    
    gcloud services enable storage-api.googleapis.com
    handle_error $? "Failed to enable Cloud Storage API"
    
    print_success "Cloud Storage API is enabled"
    echo
}

# Step 4: Manual OAuth token generation instructions
oauth_token_instructions() {
    print_message "$MAGENTA_TEXT" "TASK 4: OAuth Token Generation (MANUAL STEP)"
    echo
    print_message "$YELLOW_TEXT" "Please follow these steps to generate an OAuth token:"
    echo
    echo "${CYAN_TEXT}1. Open the OAuth 2.0 playground in a new tab: ${BOLD_TEXT}https://developers.google.com/oauthplayground/${RESET_FORMAT}"
    echo "${CYAN_TEXT}2. Scroll down and select ${BOLD_TEXT}Cloud Storage API V1${RESET_FORMAT}"
    echo "${CYAN_TEXT}3. Select the scope: ${BOLD_TEXT}https://www.googleapis.com/auth/devstorage.full_control${RESET_FORMAT}"
    echo "${CYAN_TEXT}4. Click ${BOLD_TEXT}Authorize APIs${RESET_FORMAT}"
    echo "${CYAN_TEXT}5. Sign in with your Google account and grant the requested permissions${RESET_FORMAT}"
    echo "${CYAN_TEXT}6. On Step 2, click ${BOLD_TEXT}Exchange authorization code for tokens${RESET_FORMAT}"
    echo "${CYAN_TEXT}7. Copy the ${BOLD_TEXT}Access token${RESET_FORMAT}"
    echo
    
    read -p "Paste your OAuth2 token here: " OAUTH2_TOKEN
    
    if [ -z "$OAUTH2_TOKEN" ]; then
        print_error "OAuth2 token is required to proceed"
        exit 1
    fi
    
    export OAUTH2_TOKEN
    print_success "OAuth2 token set"
    echo
}

# Step 5: Create a bucket using the API
create_bucket() {
    print_message "$BLUE_TEXT" "TASK 5: Creating a Cloud Storage bucket using the API..."
    
    # Verify we have the required variables
    if [ -z "$PROJECT_ID" ] || [ -z "$OAUTH2_TOKEN" ]; then
        print_error "Missing required variables. Ensure PROJECT_ID and OAUTH2_TOKEN are set."
        exit 1
    fi
    
    # Make the API call
    print_message "$CYAN_TEXT" "Making API call to create bucket..."
    RESPONSE=$(curl -s -X POST --data-binary @values.json \
        -H "Authorization: Bearer $OAUTH2_TOKEN" \
        -H "Content-Type: application/json" \
        "https://www.googleapis.com/storage/v1/b?project=$PROJECT_ID")
    
    # Check for errors in the response
    if echo "$RESPONSE" | grep -q "error"; then
        print_error "Failed to create bucket. API returned an error:"
        echo "$RESPONSE"
        
        # Check for common errors
        if echo "$RESPONSE" | grep -q "Use of this bucket name is restricted" || echo "$RESPONSE" | grep -q "Sorry, that name is not available"; then
            print_message "$YELLOW_TEXT" "Bucket name conflict detected. Let's modify the bucket name..."
            
            # Update the bucket name with a random suffix
            RANDOM_SUFFIX=$(date +%s | cut -c 6-10)
            BUCKET_NAME="${PROJECT_ID}-bucket-${RANDOM_SUFFIX}"
            
            # Update the JSON file
            sed -i "s/\"name\": \".*\"/\"name\": \"$BUCKET_NAME\"/" values.json
            
            print_message "$CYAN_TEXT" "Retrying with new bucket name: $BUCKET_NAME"
            
            # Retry the API call
            RESPONSE=$(curl -s -X POST --data-binary @values.json \
                -H "Authorization: Bearer $OAUTH2_TOKEN" \
                -H "Content-Type: application/json" \
                "https://www.googleapis.com/storage/v1/b?project=$PROJECT_ID")
            
            if echo "$RESPONSE" | grep -q "error"; then
                print_error "Failed to create bucket with updated name. Please check the error and try again."
                echo "$RESPONSE"
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    # Extract bucket name from response
    BUCKET_NAME=$(echo "$RESPONSE" | grep -o '"name": *"[^"]*"' | cut -d'"' -f4)
    export BUCKET_NAME
    
    print_success "Bucket created successfully: $BUCKET_NAME"
    echo
}

# Step 6: Upload a file to the bucket
upload_file() {
    print_message "$BLUE_TEXT" "TASK 6: Uploading demo-image.png to bucket..."
    
    # Create a sample image file (using echo to create a base64-encoded PNG)
    print_message "$CYAN_TEXT" "Creating demo image file..."
    
    # Base64 string of a small PNG image (1x1 pixel)
    BASE64_IMG="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVQI12P4//8/AAX+Av7czFnnAAAAAElFTkSuQmCC"
    
    echo "$BASE64_IMG" | base64 -d > demo-image.png
    handle_error $? "Failed to create demo image file"
    
    # Get absolute path to the image file
    OBJECT=$(realpath demo-image.png)
    handle_error $? "Failed to get path to image file"
    
    # Verify we have the required variables
    if [ -z "$BUCKET_NAME" ] || [ -z "$OAUTH2_TOKEN" ] || [ -z "$OBJECT" ]; then
        print_error "Missing required variables. Ensure BUCKET_NAME, OAUTH2_TOKEN, and OBJECT are set."
        exit 1
    fi
    
    # Make the API call
    print_message "$CYAN_TEXT" "Making API call to upload file..."
    RESPONSE=$(curl -s -X POST --data-binary @$OBJECT \
        -H "Authorization: Bearer $OAUTH2_TOKEN" \
        -H "Content-Type: image/png" \
        "https://www.googleapis.com/upload/storage/v1/b/$BUCKET_NAME/o?uploadType=media&name=demo-image")
    
    # Check for errors in the response
    if echo "$RESPONSE" | grep -q "error"; then
        print_error "Failed to upload file. API returned an error:"
        echo "$RESPONSE"
        exit 1
    fi
    
    print_success "Image uploaded successfully to $BUCKET_NAME"
    echo
    
    # Verify the uploaded object exists
    gsutil ls "gs://$BUCKET_NAME/demo-image" &>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Verified that demo-image exists in bucket $BUCKET_NAME"
    else
        print_error "Cannot verify that demo-image was uploaded to bucket $BUCKET_NAME"
    fi
}

# Main execution starts here
main() {
    echo
    
    # Execute each function in sequence
    set_region
    create_json_file
    enable_api
    oauth_token_instructions  # Manual step
    create_bucket
    upload_file
}

# Run the main function
main

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
