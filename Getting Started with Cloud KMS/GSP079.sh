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


export BUCKET_NAME="${DEVSHELL_PROJECT_ID}-kms_lab"

gsutil mb gs://${BUCKET_NAME}

# ==============================
# Task 2: Download Finance Dataset
# ==============================

echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading Finance Dataset...${RESET_FORMAT}"

gsutil cp gs://${DEVSHELL_PROJECT_ID}-kms-lab-data/finance-dept/inbox/1.txt .

echo "${BLUE_TEXT}Verifying File Content:${RESET_FORMAT}"
tail 1.txt
echo

# ==============================
# Task 3: Enable Cloud KMS API
# ==============================

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling Cloud KMS API...${RESET_FORMAT}"
gcloud services enable cloudkms.googleapis.com

# ==============================
# Task 4: Create KeyRing & CryptoKey
# ==============================

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating KeyRing and CryptoKey...${RESET_FORMAT}"

KEYRING_NAME=labkey
CRYPTOKEY_NAME=qwiklab

gcloud kms keyrings create $KEYRING_NAME --location global

gcloud kms keys create $CRYPTOKEY_NAME \
    --location global \
    --keyring $KEYRING_NAME \
    --purpose encryption

# ==============================
# Task 5: Encrypt Single File
# ==============================

echo "${YELLOW_TEXT}${BOLD_TEXT}Encrypting File 1.txt...${RESET_FORMAT}"

PLAINTEXT=$(cat 1.txt | base64 -w0)

curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
  -d "{\"plaintext\":\"$PLAINTEXT\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .ciphertext -r > 1.encrypted

echo "${GREEN_TEXT}Encrypted file saved as 1.encrypted${RESET_FORMAT}"

# Verify Decryption

echo "${BLUE_TEXT}Verifying Decryption:${RESET_FORMAT}"

curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:decrypt" \
  -d "{\"ciphertext\":\"$(cat 1.encrypted)\"}" \
  -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type:application/json" \
| jq .plaintext -r | base64 -d

# Upload encrypted file

echo "${YELLOW_TEXT}${BOLD_TEXT}Uploading encrypted file to bucket...${RESET_FORMAT}"
gsutil cp 1.encrypted gs://${BUCKET_NAME}

# ==============================
# Task 6: Configure IAM Permissions
# ==============================

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting IAM Permissions...${RESET_FORMAT}"

USER_EMAIL=$(gcloud auth list --limit=1 2>/dev/null | grep '@' | awk '{print $2}')

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.admin

gcloud kms keyrings add-iam-policy-binding $KEYRING_NAME \
    --location global \
    --member user:$USER_EMAIL \
    --role roles/cloudkms.cryptoKeyEncrypterDecrypter

# ==============================
# Task 7: Encrypt Multiple Files
# ==============================

echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading entire finance-dept directory...${RESET_FORMAT}"

gsutil -m cp -r gs://${DEVSHELL_PROJECT_ID}-kms-lab-data/finance-dept .

MYDIR=finance-dept
FILES=$(find $MYDIR -type f -not -name "*.encrypted")

echo "${YELLOW_TEXT}${BOLD_TEXT}Encrypting all finance files...${RESET_FORMAT}"

for file in $FILES; do
  PLAINTEXT=$(cat "$file" | base64 -w0)

  curl -s "https://cloudkms.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_NAME:encrypt" \
    -d "{\"plaintext\":\"$PLAINTEXT\"}" \
    -H "Authorization:Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type:application/json" \
  | jq .ciphertext -r > "$file.encrypted"
done

echo "${YELLOW_TEXT}${BOLD_TEXT}Uploading encrypted finance inbox files...${RESET_FORMAT}"

gsutil -m cp finance-dept/inbox/*.encrypted gs://${BUCKET_NAME}/finance-dept/inbox/

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
