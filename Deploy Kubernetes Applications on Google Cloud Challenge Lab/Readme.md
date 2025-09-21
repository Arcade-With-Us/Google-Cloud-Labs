<h1 align="center">
✨  Deploy Kubernetes Applications on Google Cloud Challenge Lab || GSP318  ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/10457?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are intended <em>solely for educational purposes</em> to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—<em>not</em> to circumvent it.
</blockquote>

---

## ⚙️ <ins>Lab Environment Setup</ins>

> ✅ **NOTE:** *Watch Full Video to get Full Scores on Check My Progress.*

**🌐Launch Cloud Shell:**
Start your Google CloudShell session by [clicking here](https://console.cloud.google.com/home/dashboard?project=&pli=1&cloudshell=true).

## 💻 **Execute in Cloud Shell**  
```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Introduction%20to%20Cloud%20Dataproc%20Hadoop%20and%20Spark%20on%20Google%20Cloud/GSP123.sh

sudo chmod +x GSP123.sh

./GSP123.sh
```
### If you don't get score from the script then you can do manually from below:
### For Task No. 1:
#### Run the following commands in **Cloud Shell**:
1. Load the validation script (already provided in your instructions):
```bash
source <(gsutil cat gs://spls/gsp318/script.sh) 
```
2. Copy the app source code:
```cpp
gsutil cp gs://spls/gsp318/valkyrie-app.tgz .
tar -xzf valkyrie-app.tgz
cd valkyrie-app
```
3. Create the Dockerfile inside the valkyrie-app directory:
```cpp
nano Dockerfile
```
4. Paste this:
```cpp
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
```
5. Press [**Ctrl X--> Y--> Enter**] to Save and exit.
6. Build the Docker image (Change the required name and version):
```cpp
docker build -t Image_Name:Tag_Name .
```
7. Verify the image exists:
```cpp
docker images
```
8. You should see:
```cpp
REPOSITORY      TAG       IMAGE ID       CREATED          SIZE
valkyrie-app    v0.0.3    <some_id>      <a few seconds>  ...
```

### For Task No. 1:
#### Run the following commands in **Cloud Shell**:
1. Get cluster credentials
```cpp
gcloud container clusters get-credentials valkyrie-dev --zone us-central1-f
```
2. Update the deployment.yaml, Navigate to the Kubernetes manifests folder:
```cpp
cd ~/valkyrie-app/k8s
```
3. Open deployment.yaml:
```cpp
nano deployment.yaml
```
4. Find the image field (it probably has a placeholder like IMAGE_PLACEHOLDER/IMAGE_HERE
```cpp
⚠️ Format must be exact → LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE:TAG
```
[Change Location as your region, Projrct-Id as your given lab project id, Repository, Imaage, Tag]
5. Replace it with your Artifact Registry image path, Save and exit.
```cpp
Example: [us-central1-docker.pkg.dev/qwiklabs-gcp-04-34becb816a10/valkyrie-docker/valkyrie-app:v0.0.3]
```
6. Apply the manifests:
```cpp
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```
7. Verify deployment & service
```cpp
kubectl get pods
```
8. Check service:
```cpp
kubectl get svc
```
9. You’ll see something like:
```cpp
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
valkyrie-dev    LoadBalancer   10.12.34.56    34.123.45.67    80:30563/TCP   1m
```
####Now hit “Check my progress” on the lab page.
####If the deployment is applied with the correct image path, you’ll get the ✅.

---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

<div align="center" style="padding: 5px;">
  <h3>📱 Join the Arcade With Us Community</h3>
  
  <a href="https://chat.whatsapp.com/KN3NvYNTJvU5xMCVTORJtS">
    <img src="https://img.shields.io/badge/Join_WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Join WhatsApp">
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
