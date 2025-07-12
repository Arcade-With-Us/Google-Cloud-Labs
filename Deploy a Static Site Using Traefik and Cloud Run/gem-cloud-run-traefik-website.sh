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


gcloud auth list

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/region $REGION
gcloud config set project $PROJECT_ID

gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com

gcloud artifacts repositories create traefik-repo --repository-format=docker --location="$REGION" --description="Docker repository for static site images"

mkdir traefik-site && cd traefik-site && mkdir public

cat > public/index.html <<EOF
<html>
<head>
  <title>My Static Website</title>
</head>
<body>
  <p>Hello from my static website on Cloud Run!</p>
</body>
</html>
EOF

gcloud auth configure-docker "$REGION"-docker.pkg.dev

cat > traefik.yml <<EOF
entryPoints:
  web:
    address: ":8080"

providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true

log:
  level: INFO
EOF


cat > traefik.yml <<EOF
entryPoints:
  web:
    address: ":8080"

providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true

log:
  level: INFO
EOF


cat > dynamic.yml <<EOF
http:
  routers:
    static-files:
      rule: "PathPrefix(`/`)"
      entryPoints:
        - web
      service: static-service

  services:
    static-service:
      loadBalancer:
        servers:
          - url: "http://localhost:8000"
EOF




cat > Dockerfile <<EOF
FROM alpine:3.20

# Install traefik and caddy
RUN apk add --no-cache traefik caddy

# Copy configs and static files
COPY traefik.yml /etc/traefik/traefik.yml
COPY dynamic.yml /etc/traefik/dynamic.yml
COPY public/ /public/

# Cloud Run uses port 8080
EXPOSE 8080

# Run static server (on 8000) and Traefik (on 8080)
ENTRYPOINT [ "caddy" ]
CMD [ "file-server", "--listen", ":8000", "--root", "/public", "&", "traefik" ]
EOF




docker build -t "$REGION"-docker.pkg.dev/"$PROJECT_ID"/traefik-repo/traefik-static-site:latest .


docker push "$REGION"-docker.pkg.dev/"$PROJECT_ID"/traefik-repo/traefik-static-site:latest


gcloud run deploy traefik-static-site --region "$REGION" --image "$REGION"-docker.pkg.dev/"$PROJECT_ID"/traefik-repo/traefik-static-site:latest --platform managed --allow-unauthenticated --port 8000

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
