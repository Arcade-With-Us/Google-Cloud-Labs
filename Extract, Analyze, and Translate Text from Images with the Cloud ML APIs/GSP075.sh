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


echo "${YELLOW_TEXT} ${BOLD_TEXT} Creating API Key... Please wait... ${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="arcadecrew" 

echo "${GREEN_TEXT} ${BOLD_TEXT} API Key created successfully! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Fetching API Key Name... ${RESET_FORMAT}"
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=arcadecrew")

echo "${GREEN_TEXT} ${BOLD_TEXT} API Key Name fetched: ${KEY_NAME} ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Fetching API Key String... ${RESET_FORMAT}"
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
echo "${GREEN_TEXT} ${BOLD_TEXT} API Key String fetched successfully! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Setting Project ID... ${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
echo "${GREEN_TEXT} ${BOLD_TEXT} Project ID set to: ${PROJECT_ID} ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Setting Project Number... ${RESET_FORMAT}"
export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="value(projectNumber)")
echo "${GREEN_TEXT} ${BOLD_TEXT} Project Number set to: ${PROJECT_NUMBER} ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Creating GCS Bucket... ${RESET_FORMAT}"
gcloud storage buckets create gs://$DEVSHELL_PROJECT_ID-bucket --project=$DEVSHELL_PROJECT_ID
echo "${GREEN_TEXT} ${BOLD_TEXT} GCS Bucket created successfully! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Setting IAM permissions for GCS Bucket... ${RESET_FORMAT}"
gsutil iam ch projectEditor:serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com:objectCreator gs://$DEVSHELL_PROJECT_ID-bucket
echo "${GREEN_TEXT} ${BOLD_TEXT} IAM permissions set successfully! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Downloading sample image... ${RESET_FORMAT}"
curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Extract%2C%20Analyze%2C%20and%20Translate%20Text%20from%20Images%20with%20the%20Cloud%20ML%20APIs/sign.jpg
echo "${GREEN_TEXT} ${BOLD_TEXT} Sample image downloaded! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Copying image to GCS Bucket... ${RESET_FORMAT}"
gsutil cp sign.jpg gs://$DEVSHELL_PROJECT_ID-bucket/sign.jpg
echo "${GREEN_TEXT} ${BOLD_TEXT} Image copied to GCS Bucket! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Setting public read access for the image... ${RESET_FORMAT}"
gsutil acl ch -u AllUsers:R gs://$DEVSHELL_PROJECT_ID-bucket/sign.jpg
echo "${GREEN_TEXT} ${BOLD_TEXT} Public read access set! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Creating OCR request file... ${RESET_FORMAT}"
touch ocr-request.json

tee ocr-request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$DEVSHELL_PROJECT_ID-bucket/sign.jpg"
          }
        },
        "features": [
          {
            "type": "TEXT_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF
echo "${GREEN_TEXT} ${BOLD_TEXT} OCR request file created! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Sending OCR request to Vision API... ${RESET_FORMAT}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @ocr-request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}
echo "${GREEN_TEXT} ${BOLD_TEXT} OCR request sent! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Sending OCR request to Vision API and saving response... ${RESET_FORMAT}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @ocr-request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o ocr-response.json
echo "${GREEN_TEXT} ${BOLD_TEXT} OCR response saved to ocr-response.json! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Creating translation request file... ${RESET_FORMAT}"
touch translation-request.json

tee translation-request.json <<EOF
{
  "q": "My Name is Abir_Dey",	
  "target": "en"
}
EOF
echo "${GREEN_TEXT} ${BOLD_TEXT} Translation request file created! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Extracting text from OCR response and updating translation request... ${RESET_FORMAT}"
STR=$(jq .responses[0].textAnnotations[0].description ocr-response.json) && STR="${STR//\"}" && sed -i "s|your_text_here|$STR|g" translation-request.json
echo "${GREEN_TEXT} ${BOLD_TEXT} Text extracted and translation request updated! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Sending translation request to Translation API... ${RESET_FORMAT}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @translation-request.json https://translation.googleapis.com/language/translate/v2?key=${API_KEY} -o translation-response.json
echo "${GREEN_TEXT} ${BOLD_TEXT} Translation request sent and response saved! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Displaying translation response... ${RESET_FORMAT}"
cat translation-response.json
echo "${GREEN_TEXT} ${BOLD_TEXT} Translation response displayed! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Creating Natural Language request file... ${RESET_FORMAT}"
touch nl-request.json

tee nl-request.json <<EOF
{
  "document":{
    "type":"PLAIN_TEXT",
    "content":"your_text_here"
  },
  "encodingType":"UTF8"
}
EOF
echo "${GREEN_TEXT} ${BOLD_TEXT} Natural Language request file created! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Extracting translated text and updating Natural Language request... ${RESET_FORMAT}"
STR=$(jq .data.translations[0].translatedText  translation-response.json) && STR="${STR//\"}" && sed -i "s|your_text_here|$STR|g" nl-request.json
echo "${GREEN_TEXT} ${BOLD_TEXT} Translated text extracted and Natural Language request updated! ${RESET_FORMAT}"

echo "${YELLOW_TEXT} ${BOLD_TEXT} Sending Natural Language request to Language API... ${RESET_FORMAT}"
curl "https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @nl-request.json
echo "${GREEN_TEXT} ${BOLD_TEXT} Natural Language request sent! ${RESET_FORMAT}"

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
