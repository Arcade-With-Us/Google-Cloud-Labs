export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

if [[ -z "$REGION" ]]; then
    echo -e "${BOLD_TEXT}${YELLOW_TEXT}⚠️  Default region not found! Please enter your region:${RESET_FORMAT}"
    read -p "$(echo -e "${BOLD_TEXT}${CYAN_TEXT}Region:${RESET_FORMAT} ")" REGION
    export REGION
fi

echo -e "${BOLD_TEXT}${GREEN_TEXT}✔ Using region: ${REGION}${RESET_FORMAT}"


echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 1: Authenticating with gcloud...          ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud auth list
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Authentication completed successfully.              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 2: Creating 'test' directory...             ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
mkdir test && cd test
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  'test' directory created successfully.            ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 3: Creating 'Dockerfile'...                ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
cat > Dockerfile <<EOF
# Use an official Node runtime as the parent image
FROM node:lts

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Make the container's port 80 available to the outside world
EXPOSE 80

# Run app.js using node when the container launches
CMD ["node", "app.js"]
EOF
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  'Dockerfile' created successfully.               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 4: Creating 'app.js'...                   ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
cat > app.js << EOF
const http = require("http");

const hostname = "0.0.0.0";
const port = 80;

const server = http.createServer((req, res) => {
    res.statusCode = 200;
    res.setHeader("Content-Type", "text/plain");
    res.end("Welcome to Cloud\n");
});

server.listen(port, hostname, () => {
    console.log("Server running at http://%s:%s/", hostname, port);
});

process.on("SIGINT", function () {
    console.log("Caught interrupt signal and will exit");
    process.exit();
});
EOF
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  'app.js' created successfully.                    ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 5: Building the Docker image...            ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
docker build -t node-app:0.2 .
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Docker image built successfully (node-app:0.2).  ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 6: Running the Docker container...         ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
docker run -p 8080:80 --name my-app-2 -d node-app:0.2
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Docker container running (my-app-2, port 8080).  ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 7: Listing running containers...           ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
docker ps
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  List of running containers shown above.           ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 8: Creating Artifact Registry...           ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud artifacts repositories create my-repository \
    --repository-format=docker \
    --location=$REGION \
    --description="Subscribe to arcadecrew"
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Artifact Registry 'my-repository' created ($REGION).  ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 9: Configuring Docker auth...               ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Docker authentication configured.                 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 10: Building Docker image for Registry...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}  Please wait until docker build complete.         ${RESET_FORMAT}"
# Fetch project ID dynamically
DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}  GCP Project ID detected: $DEVSHELL_PROJECT_ID        ${RESET_FORMAT}"
echo
docker build -t $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2 .
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Docker image built for Artifact Registry.       ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 11: Pushing to Artifact Registry...         ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Docker image pushed to Artifact Registry.        ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 12: Cleaning up Docker...                  ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
docker stop $(docker ps -q)
docker rm $(docker ps -aq)
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Stopped and removed all running containers.      ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
docker rmi $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2
docker rmi node:lts
docker rmi -f $(docker images -aq) # remove remaining images
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Removed all specified and extra Docker images.   ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 13: Listing all docker images...           ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
docker images
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Current available images shown above.            ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}┌────────────────────────────────────────────────┐${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 14: Running from Artifact Registry...       ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}└────────────────────────────────────────────────┘${RESET_FORMAT}"
docker run -p 4000:80 -d $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Docker image running (port 4000).                ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${RED_TEXT}${BOLD_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi
