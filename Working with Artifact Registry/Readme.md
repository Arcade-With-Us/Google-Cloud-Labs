<h1 align="center">
✨ Working with Artifact Registry || GSP1076 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/52830?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

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
export ZONE=
```
```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Working%20with%20Artifact%20Registry/GSP1076-1.sh

sudo chmod +x GSP1076-1.sh

./GSP1076-1.sh
```

* *NOW FOLLOW VIDEO'S INSTRUCTIONS*

## Manual Steps

1. From the left menu, select **Cloud Code** and then expand the **COMPUTE ENGINE** option and click on **Select a Project** and choose the **project ID provided in the Lab Instruction**.

2. Also, expand the **KUBERNETES** option. You will be able to see the cluster loading.

3. Wait until you see the cluster listed under `KUBERNETES` as well as under `COMPUTE ENGINE`.

4. Click Navigation menu under the Cloud Shell Editor icon **View** > **Command Palette**... and type **Run on Kubernetes** and select **Cloud Code: Run on Kubernetes**.

5. Choose **`cloud-code-samples/java/java-hello-world/skaffold.yaml`** and then **dockerfile**.

6. If Prompted for a context, select Yes to use the current context.

7. In the prompt for the image registry select **Enter the address of an image repository** and put the address location you located below and press **Enter**.

**`"REGION"-docker.pkg.dev/"PROJECT_ID"/container-dev-repo`**

### Make sure to paste your code given in the lab manual.

8. Press Enter and let it be run for 4-5 minutes.

### Run again the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Working%20with%20Artifact%20Registry/GSP1076-2.sh

sudo chmod +x GSP1076-2.sh

./GSP1076-2.sh
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
