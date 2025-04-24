gcloud config set compute/region $REGION
gcloud config set project $DEVSHELL_PROJECT_ID

gcloud services enable appengine.googleapis.com


git clone https://github.com/GoogleCloudPlatform/golang-samples.git

cd golang-samples/appengine/go11x/helloworld

sudo apt-get install google-cloud-sdk-app-engine-go

gcloud app create --region=$REGION

gcloud app deploy --quiet 

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
