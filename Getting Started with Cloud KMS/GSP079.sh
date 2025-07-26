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

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
BUCKET_NAME="${PROJECT_ID}-enron_corpus"
KEYRING_NAME="test"
CRYPTOKEY_NAME="qwiklab"
LOCATION="global"
USER_EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

# Function for error handling
die() {
    echo "Error: $1" >&2
    exit 1
}

# Task 1: Create Cloud Storage bucket
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Cloud Storage bucket:${RESET_FORMAT} $BUCKET_NAME"
gsutil mb gs://${BUCKET_NAME} || die "${RED_TEXT}${BOLD_TEXT}Failed to create bucket ${RESET_FORMAT}"

# Task 2: Review the data
echo "${BLUE_TEXT}${BOLD_TEXT}Downloading sample email file... ${RESET_FORMAT}"
gsutil cp gs://enron_emails/allen-p/inbox/1. . || die "${RED_TEXT}${BOLD_TEXT}Failed to download sample file ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Previewing file content: ${RESET_FORMAT}"
tail 1. || die "${RED_TEXT}${BOLD_TEXT}Failed to read file ${RESET_FORMAT}"

# Task 3: Enable Cloud KMS
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling Cloud KMS API... ${RESET_FORMAT}"
gcloud services enable cloudkms.googleapis.com || die "${RED_TEXT}${BOLD_TEXT}Failed to enable Cloud KMS ${RESET_FORMAT}"

# Task 4: Create Keyring and Cryptokey
echo "${BLUE_TEXT}${BOLD_TEXT}Creating KeyRing: ${RESET_FORMAT} $KEYRING_NAME"
gcloud kms keyrings create $KEYRING_NAME --location=$LOCATION || echo "${RED_TEXT}${BOLD_TEXT}KeyRing may already exist ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Creating CryptoKey: ${RESET_FORMAT} $CRYPTOKEY_NAME"
gcloud kms keys create $CRYPTOKEY_NAME --location=$LOCATION --keyring=$KEYRING_NAME --purpose=encryption || echo "${RED_TEXT}${BOLD_TEXT}CryptoKey may already exist ${RESET_FORMAT}"

# Task 5: Encrypt the email file
echo "${BLUE_TEXT}${BOLD_TEXT}Encrypting sample email file... ${RESET_FORMAT}"
PLAINTEXT=$(cat 1. | base64 -w0)
CIPHERTEXT=$(curl -s -X POST "https://cloudkms.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type: application/json" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" | jq -r .ciphertext) || die "${RED_TEXT}${BOLD_TEXT}Encryption failed${RESET_FORMAT}"
echo "$CIPHERTEXT" > 1.encrypted
echo "${BLUE_TEXT}${BOLD_TEXT}Uploading encrypted file to Cloud Storage${RESET_FORMAT}"
gsutil cp 1.encrypted gs://${BUCKET_NAME}/ || die "${RED_TEXT}${BOLD_TEXT}Failed to upload encrypted file${RESET_FORMAT}"

# Task 6: Configure IAM permissions
echo "${BLUE_TEXT}${BOLD_TEXT}Assigning IAM roles to user:${RESET_FORMAT} $USER_EMAIL"
gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME --location=$LOCATION --member=user:$USER_EMAIL --role=roles/cloudkms.admin || die "${RED_TEXT}${BOLD_TEXT}Failed to assign cloudkms.admin role${RESET_FORMAT}"
gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME --location=$LOCATION --member=user:$USER_EMAIL --role=roles/cloudkms.cryptoKeyEncrypterDecrypter || die "${RED_TEXT}${BOLD_TEXT}Failed to assign cloudkms.cryptoKeyEncrypterDecrypter role${RESET_FORMAT}"

# Task 7: Backup and encrypt all email files
echo "${BLUE_TEXT}${BOLD_TEXT}Backing up and encrypting all emails for user allen-p...${RESET_FORMAT}"
gsutil -m cp -r gs://enron_emails/allen-p . || die "${RED_TEXT}${BOLD_TEXT}Failed to copy email dataset${RESET_FORMAT}"
MYDIR="allen-p"
FILES=$(find $MYDIR -type f -not -name "*.encrypted")
for file in $FILES; do
    PLAINTEXT=$(cat $file | base64 -w0)
    CIPHERTEXT=$(curl -s -X POST "https://cloudkms.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
        -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
        -H "Content-Type: application/json" \
        -d "{\"plaintext\":\"$PLAINTEXT\"}" | jq -r .ciphertext)
    echo "$CIPHERTEXT" > "$file.encrypted"
done
echo "${BLUE_TEXT}${BOLD_TEXT}Uploading encrypted emails to Cloud Storage${RESET_FORMAT}"
gsutil -m cp $MYDIR/inbox/*.encrypted gs://${BUCKET_NAME}/$MYDIR/inbox || die "${RED_TEXT}${BOLD_TEXT}Failed to upload encrypted emails${RESET_FORMAT}"

echo
echo -e "\e[1;31mDeleting the script (arcadecrew.sh) for safety purposes...\e[0m"
rm -- "$0"
echo
echo
# Completion message
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
