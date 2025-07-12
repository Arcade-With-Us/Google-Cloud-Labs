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

# Fetch zone and region
ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_ID=$(gcloud config get-value project)


gcloud services enable artifactregistry.googleapis.com

gcloud config set project $PROJECT_ID

gcloud config set compute/region $REGION

gcloud artifacts repositories create my-python-repo \
    --repository-format=python \
    --location=$REGION \
    --description="Python package repository"


pip install keyrings.google-artifactregistry-auth

pip config set global.extra-index-url https://$REGION-python.pkg.dev/$PROJECT_ID/my-python-repo/simple

mkdir my-package
cd my-package


cat > setup.py <<EOF_END
from setuptools import setup, find_packages

setup(
    name='my_package',
    version='0.1.0',
    author='cls',
    author_email='$USER_EMAIL',
    packages=find_packages(exclude=['tests']),
    install_requires=[
        # List your dependencies here
    ],
    description='A sample Python package',
)
EOF_END

cat > my_module.py <<EOF_END
def hello_world():
    return 'Hello, world!'
EOF_END

pip install twine

python setup.py sdist bdist_wheel

python3 -m twine upload --repository-url https://$REGION-python.pkg.dev/$PROJECT_ID/my-python-repo/ dist/*

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
