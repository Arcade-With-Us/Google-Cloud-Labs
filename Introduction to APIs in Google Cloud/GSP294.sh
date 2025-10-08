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

#!/bin/bash


HEADER_COLOR=$'\033[38;5;54m'       # Deep purple
TITLE_COLOR=$'\033[38;5;93m'         # Bright purple
PROMPT_COLOR=$'\033[38;5;178m'       # Gold
ACTION_COLOR=$'\033[38;5;44m'        # Teal
SUCCESS_COLOR=$'\033[38;5;46m'       # Bright green
WARNING_COLOR=$'\033[38;5;196m'      # Bright red
LINK_COLOR=$'\033[38;5;27m'          # Blue
TEXT_COLOR=$'\033[38;5;255m'         # Bright white

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear


echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${TITLE_COLOR}${BOLD_TEXT}         🎓 ARCADE WITH US CLOUD TUTORIAL           ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}This lab demonstrates advanced Cloud Storage API operations${RESET_FORMAT}"
echo "${TEXT_COLOR}including bucket creation and file management in Google Cloud.${RESET_FORMAT}"
echo

# Function to display messages with formatting
print_message() {
    local color=$1
    local emoji=$2
    local message=$3
    echo -e "${color}${BOLD_TEXT}${emoji}  ${message}${RESET_FORMAT}"
}

# Function to display error messages
print_error() {
    local message=$1
    print_message "$WARNING_COLOR" "❌" "ERROR: ${message}"
}

# Function to display success messages
print_success() {
    local message=$1
    print_message "$SUCCESS_COLOR" "✓" "${message}"
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
print_message "$ACTION_COLOR" "🔍" "Checking system requirements..."
check_command "gcloud"
check_command "gsutil"
check_command "curl"
check_command "nano"
print_success "All required commands are available"
echo

# Step 1: Set the region for the project
set_region() {
    print_message "$ACTION_COLOR" "🌍" "TASK 1: Setting the compute region..."
    
    # Get region from user or use default
    read -p "${PROMPT_COLOR}${BOLD_TEXT}Enter REGION [us-central1]: ${RESET_FORMAT}" REGION
    REGION=${REGION:-us-central1}
    
    gcloud config set compute/region $REGION
    handle_error $? "Failed to set compute region"
    
    print_success "Region set to: $REGION"
    echo
}

# Step 2: Creating JSON File
create_json_file() {
    print_message "$ACTION_COLOR" "📄" "TASK 2: Creating values.json configuration file..."
    
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
    
    print_success "Configuration file created with Project ID: $PROJECT_ID"
    echo
    
    # Export project ID for later use
    export PROJECT_ID
}

# Step 3: Ensure API is enabled
enable_api() {
    print_message "$ACTION_COLOR" "⚙️" "TASK 3: Enabling Cloud Storage API..."
    
    gcloud services enable storage-api.googleapis.com
    handle_error $? "Failed to enable Cloud Storage API"
    
    print_success "Cloud Storage API is now enabled"
    echo
}

# Step 4: Manual OAuth token generation instructions
oauth_token_instructions() {
    print_message "$ACTION_COLOR" "🔑" "TASK 4: OAuth Token Generation (Manual Step)"
    echo
    echo "${TEXT_COLOR}Please follow these steps to generate an OAuth token:${RESET_FORMAT}"
    echo
    echo "${PROMPT_COLOR}1. Open the OAuth 2.0 playground: ${LINK_COLOR}https://developers.google.com/oauthplayground/${RESET_FORMAT}"
    echo "${PROMPT_COLOR}2. Select ${BOLD_TEXT}Cloud Storage API V1${RESET_FORMAT}"
    echo "${PROMPT_COLOR}3. Choose the scope: ${BOLD_TEXT}https://www.googleapis.com/auth/devstorage.full_control${RESET_FORMAT}"
    echo "${PROMPT_COLOR}4. Click ${BOLD_TEXT}Authorize APIs${RESET_FORMAT} and sign in"
    echo "${PROMPT_COLOR}5. Exchange authorization code for tokens"
    echo "${PROMPT_COLOR}6. Copy the ${BOLD_TEXT}Access token${RESET_FORMAT}"
    echo
    
    read -p "${PROMPT_COLOR}${BOLD_TEXT}Please paste your OAuth2 token here: ${RESET_FORMAT}" OAUTH2_TOKEN
    
    if [ -z "$OAUTH2_TOKEN" ]; then
        print_error "OAuth2 token is required to proceed"
        exit 1
    fi
    
    export OAUTH2_TOKEN
    print_success "OAuth2 token successfully configured"
    echo
}

# Step 5: Create a bucket using the API
create_bucket() {
    print_message "$ACTION_COLOR" "🛠️" "TASK 5: Creating Cloud Storage bucket via API..."
    
    # Verify we have the required variables
    if [ -z "$PROJECT_ID" ] || [ -z "$OAUTH2_TOKEN" ]; then
        print_error "Missing required configuration. Ensure PROJECT_ID and OAUTH2_TOKEN are set."
        exit 1
    fi
    
    # Make the API call
    print_message "$TEXT_COLOR" "🔧" "Initiating bucket creation API call..."
    RESPONSE=$(curl -s -X POST --data-binary @values.json \
        -H "Authorization: Bearer $OAUTH2_TOKEN" \
        -H "Content-Type: application/json" \
        "https://www.googleapis.com/storage/v1/b?project=$PROJECT_ID")
    
    # Check for errors in the response
    if echo "$RESPONSE" | grep -q "error"; then
        print_error "Bucket creation failed. API response:"
        echo "$RESPONSE"
        
        # Handle bucket name conflicts
        if echo "$RESPONSE" | grep -q "bucket name is restricted"; then
            print_message "$PROMPT_COLOR" "🔄" "Detected bucket name conflict. Generating unique name..."
            
            # Update the bucket name with a random suffix
            RANDOM_SUFFIX=$(date +%s | cut -c 6-10)
            BUCKET_NAME="${PROJECT_ID}-bucket-${RANDOM_SUFFIX}"
            
            # Update the JSON file
            sed -i "s/\"name\": \".*\"/\"name\": \"$BUCKET_NAME\"/" values.json
            
            print_message "$TEXT_COLOR" "🔄" "Retrying with new bucket name: $BUCKET_NAME"
            
            # Retry the API call
            RESPONSE=$(curl -s -X POST --data-binary @values.json \
                -H "Authorization: Bearer $OAUTH2_TOKEN" \
                -H "Content-Type: application/json" \
                "https://www.googleapis.com/storage/v1/b?project=$PROJECT_ID")
            
            if echo "$RESPONSE" | grep -q "error"; then
                print_error "Failed with updated name. Please check the error and try again."
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
    
    print_success "Bucket successfully created: $BUCKET_NAME"
    echo
}

# Step 6: Upload a file to the bucket
upload_file() {
    print_message "$ACTION_COLOR" "📤" "TASK 6: Uploading sample file to bucket..."
    
    # Create a sample image file
    print_message "$TEXT_COLOR" "🖼️" "Generating sample image file..."
    
    # Base64 string of a small PNG image (1x1 pixel)
    BASE64_IMG="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVQI12P4//8/AAX+Av7czFnnAAAAAElFTkSuQmCC"
    
    echo "$BASE64_IMG" | base64 -d > demo-image.png
    handle_error $? "Failed to create sample image file"
    
    # Get absolute path to the image file
    OBJECT=$(realpath demo-image.png)
    handle_error $? "Failed to resolve file path"
    
    # Verify we have the required variables
    if [ -z "$BUCKET_NAME" ] || [ -z "$OAUTH2_TOKEN" ] || [ -z "$OBJECT" ]; then
        print_error "Missing required configuration. Ensure BUCKET_NAME, OAUTH2_TOKEN, and OBJECT are set."
        exit 1
    fi
    
    # Make the API call
    print_message "$TEXT_COLOR" "🔼" "Initiating file upload API call..."
    RESPONSE=$(curl -s -X POST --data-binary @$OBJECT \
        -H "Authorization: Bearer $OAUTH2_TOKEN" \
        -H "Content-Type: image/png" \
        "https://www.googleapis.com/upload/storage/v1/b/$BUCKET_NAME/o?uploadType=media&name=demo-image")
    
    # Check for errors in the response
    if echo "$RESPONSE" | grep -q "error"; then
        print_error "File upload failed. API response:"
        echo "$RESPONSE"
        exit 1
    fi
    
    print_success "File successfully uploaded to: gs://$BUCKET_NAME/demo-image"
    echo
    
    # Verify the uploaded object exists
    gsutil ls "gs://$BUCKET_NAME/demo-image" &>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Verification: File exists in bucket $BUCKET_NAME"
    else
        print_error "Warning: Cannot verify file existence in bucket $BUCKET_NAME"
    fi
}

# Main execution function
main() {
    echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━ LAB EXECUTION STARTED ━━━━━━━━━━━━┓${RESET_FORMAT}"
    echo
    
    # Execute each function in sequence
    set_region
    create_json_file
    enable_api
    oauth_token_instructions  # Manual step
    create_bucket
    upload_file
    
    echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
}

# Run the main function
main

echo
echo -e "${PROMPT_COLOR}${BOLD_TEXT}💡 Continue learning at: ${LINK_COLOR}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo "${PROMPT_COLOR}${BOLD_TEXT}   Don't forget to like and subscribe!${RESET_FORMAT}"
echo

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
