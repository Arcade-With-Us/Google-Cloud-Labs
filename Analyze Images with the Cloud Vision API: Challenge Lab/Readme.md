<h1 align="center">
✨ Analyze Images with the Cloud Vision API: Challenge Lab || ARC122 ✨
<div align="center">
<a href="https://www.cloudskillsboost.google/focuses/64748?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

## 🔑 Solution [here]()

---

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are intended <em>solely for educational purposes</em> to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—<em>not</em> to circumvent it.
</blockquote>

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏

---

## ⚙️ <ins>Lab Environment Setup</ins>

> ✅ **NOTE:** *Watch Full Video to get Full Scores on Check My Progress.*

**🌐Launch Cloud Shell:**
Start your Google CloudShell session by [clicking here](https://console.cloud.google.com/home/dashboard?project=&pli=1&cloudshell=true).

## 💻 **Execute in Cloud Shell**  
```
export API_KEY=[CLOUD VISION API KEY]
```
```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Analyze%20Images%20with%20the%20Cloud%20Vision%20API%3A%20Challenge%20Lab/ARC122.sh

sudo chmod +x ARC122.sh

./ARC122.sh
```
#### If you get any error, in a new Cloud Shell tab run this
```py
echo "${MAGENTA}${BOLD}🔧 STEP 0: Enabling Required Services...${RESET}"
gcloud services enable cloudapis.googleapis.com || {
    echo "${RED}${BOLD}❌ Error: Failed to enable Cloud APIs${RESET}"
    exit 1
}
gcloud services enable vision.googleapis.com || {
    echo "${RED}${BOLD}❌ Error: Failed to enable Vision API${RESET}"
    exit 1
}
echo "${GREEN}${BOLD}✔ Success: Services enabled${RESET}"
echo ""

# ======================
#  API KEY CREATION WITH VISION API RESTRICTION
# ======================
echo "${MAGENTA}${BOLD}🔑 STEP 1: Creating API Key restricted to Vision API...${RESET}"

# Check if key already exists
EXISTING_KEY=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=vision-lab-key")

if [ -n "$EXISTING_KEY" ]; then
    echo "${YELLOW}${BOLD}⚠️ API key already exists. Deleting old key...${RESET}"
    gcloud alpha services api-keys delete $EXISTING_KEY --quiet || {
        echo "${RED}${BOLD}❌ Error: Failed to delete existing key${RESET}"
        exit 1
    }
    # Wait a moment for deletion to propagate
    sleep 5
fi

# Create new API key with Vision API restriction
gcloud alpha services api-keys create \
    --display-name="vision-lab-key" \
    --api-target="service=vision.googleapis.com" \
    --quiet || {
    echo "${RED}${BOLD}❌ Error: Failed to create API key${RESET}"
    exit 1
}

# Get the key name and value
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=vision-lab-key")
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
export PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN}${BOLD}✔ Success: API Key created and restricted to Vision API only${RESET}"
echo "${WHITE}Key Name: ${YELLOW}$KEY_NAME${RESET}"
echo "${WHITE}Key Value: ${YELLOW}$API_KEY${RESET}"
echo "${WHITE}Project ID: ${YELLOW}$PROJECT_ID${RESET}"
echo ""

# ======================
#  CREATE BUCKET AND UPLOAD IMAGE
# ======================
echo "${MAGENTA}${BOLD}📦 STEP 2: Setting up Cloud Storage...${RESET}"

# Check if bucket exists, create if not
if ! gsutil ls gs://$PROJECT_ID-bucket &>/dev/null; then
    echo "${WHITE}Creating bucket...${RESET}"
    gsutil mb gs://$PROJECT_ID-bucket || {
        echo "${RED}${BOLD}❌ Error: Failed to create bucket${RESET}"
        exit 1
    }
fi

# Check if image exists in bucket, if not download it
if ! gsutil ls gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg &>/dev/null; then
    echo "${WHITE}Image not found in bucket. Please ensure you have uploaded the image.${RESET}"
    echo "${YELLOW}To upload image, use: gsutil cp /path/to/image.jpg gs://$PROJECT_ID-bucket/${RESET}"
    echo "${YELLOW}Or download sample image:${RESET}"
    echo "${YELLOW}wget -O sample.jpg https://storage.googleapis.com/cloud-samples-data/vision/using_curl/shanghai.jpg${RESET}"
    echo "${YELLOW}gsutil cp sample.jpg gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg${RESET}"
    exit 1
fi

# Set image permissions
echo "${WHITE}Setting image to public readable...${RESET}"
gsutil acl ch -u allUsers:R gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg || {
    echo "${RED}${BOLD}❌ Error: Failed to set image permissions${RESET}"
    exit 1
}
echo "${GREEN}${BOLD}✔ Success: Image made publicly readable${RESET}"
echo ""

# ======================
#  TEXT DETECTION
# ======================
echo "${MAGENTA}${BOLD}📝 STEP 3: Performing TEXT_DETECTION...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
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

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o text-response.json

# Check if response contains error
if grep -q "error" text-response.json; then
    echo "${RED}${BOLD}❌ Error: Text detection failed${RESET}"
    cat text-response.json | jq '.'
    exit 1
fi

gsutil cp text-response.json gs://$PROJECT_ID-bucket/ || {
    echo "${RED}${BOLD}❌ Error: Failed to upload text response${RESET}"
    exit 1
}

echo "${GREEN}${BOLD}✔ Success: Text detection completed${RESET}"
echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/text-response.json${RESET}"
echo ""

# ======================
#  LANDMARK DETECTION
# ======================
echo "${MAGENTA}${BOLD}🏛️ STEP 4: Performing LANDMARK_DETECTION...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "LANDMARK_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o landmark-response.json

# Check if response contains error
if grep -q "error" landmark-response.json; then
    echo "${RED}${BOLD}❌ Error: Landmark detection failed${RESET}"
    cat landmark-response.json | jq '.'
    exit 1
fi

gsutil cp landmark-response.json gs://$PROJECT_ID-bucket/ || {
    echo "${RED}${BOLD}❌ Error: Failed to upload landmark response${RESET}"
    exit 1
}

echo "${GREEN}${BOLD}✔ Success: Landmark detection completed${RESET}"
echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/landmark-response.json${RESET}"
echo ""

# ======================
#  LABEL DETECTION (BONUS)
# ======================
echo "${MAGENTA}${BOLD}🏷️ STEP 5: Performing LABEL_DETECTION (Bonus)...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "LABEL_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o label-response.json

if grep -q "error" label-response.json; then
    echo "${RED}${BOLD}❌ Error: Label detection failed${RESET}"
else
    gsutil cp label-response.json gs://$PROJECT_ID-bucket/ || {
        echo "${RED}${BOLD}❌ Error: Failed to upload label response${RESET}"
        exit 1
    }
    echo "${GREEN}${BOLD}✔ Success: Label detection completed${RESET}"
    echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/label-response.json${RESET}"
fi
echo ""

# ======================
#  DISPLAY RESULTS
# ======================
echo "${MAGENTA}${BOLD}📊 STEP 6: Displaying Results...${RESET}"

# Display text detection results
if [ -f "text-response.json" ]; then
    echo "${CYAN}${BOLD}📝 Text Detection Results:${RESET}"
    cat text-response.json | jq '.responses[].textAnnotations[0].description' 2>/dev/null || echo "No text found"
    echo ""
fi

# Display landmark detection results
if [ -f "landmark-response.json" ]; then
    echo "${CYAN}${BOLD}🏛️ Landmark Detection Results:${RESET}"
    cat landmark-response.json | jq '.responses[].landmarkAnnotations[].description' 2>/dev/null || echo "No landmarks found"
    echo ""
fi

# Display label detection results
if [ -f "label-response.json" ]; then
    echo "${CYAN}${BOLD}🏷️ Label Detection Results:${RESET}"
    cat label-response.json | jq '.responses[].labelAnnotations[].description' 2>/dev/null || echo "No labels found"
    echo ""
fi

#Instructions before uploading landmark response
echo "${CYAN_TEXT} ${BOLD_TEXT}Uploading landmark-response.json to your bucket...${RESET_FORMAT}"

gsutil cp landmark-response.json gs://$PROJECT_ID-bucket
```
---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

Your hard work and determination paid off! 💻
You've successfully completed the lab. **Way to go!** 🚀


<div align="center" style="padding: 5px;">
  <h3>📱 Join the Arcade With Us Community</h3>
  
  <a href="https://chat.whatsapp.com/KN3NvYNTJvU5xMCVTORJtS">
    <img src="https://img.shields.io/badge/Join_WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Join WhatsApp 👥">
  </a>
  &nbsp;
  <a href="https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l">
    <img src="https://img.shields.io/badge/Subscribe-Arcade%20With%20Us-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>
  &nbsp;
  <a href="https://www.linkedin.com/in/tripti-gupta-a28a6832b/">
    <img src="https://img.shields.io/badge/LINKEDIN-Tripti%20Gupta-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
</a>


</div>

---

<div align="center">
  <p style="font-size: 12px; color: #586069;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 12px; color: #586069;">
    <em>Last updated: April 2025</em>
  </p>
</div>
