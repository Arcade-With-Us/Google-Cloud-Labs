<h1 align="center">
✨  Monitoring Multiple Projects with Cloud Monitoring || GSP090 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/621?parent=catalog" target="_blank" rel="noopener noreferrer">
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

## ⚙️ Lab Environment Setup:

**🌐Launch Cloud Shell:**
Start your Google CloudShell session by [clicking here](https://console.cloud.google.com/home/dashboard?project=&pli=1&cloudshell=true).

## 💻 **Execute in Cloud Shell** 

```
curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Monitoring%20Multiple%20Projects%20with%20Cloud%20Monitoring/GSP090.sh

sudo chmod +x GSP090.sh

./GSP090.sh
```

#### For creation of **`DemoGroup`** follow these steps:

1. In the left menu, click Groups, then click +Create group. Name your group **`DemoGroup`**.
2. In the first dropdown field (Type), **`Name`** is selected by default.
3. In the second dropdown (Operator), **`Contains`** is selected by default.
4. In the third field (Value), type in "**`instance`**"
5. Click Done, then click `Create`.

### Uptime check for your group:

1. In the left menu, click `Uptime checks`, then click `+Create uptime check`.
2. Create your uptime check with the following information:
3. `Protocol`: **`TCP`**
4. `Resource Type`: **`Instance`**
5. `Applies To`: **`Group`**, and then select **`DemoGroup`**.
6. `Port`: **`22`**
7. `Check frequency`: **`1 minute`**, then click `Continue`. Click `Continue` again.
8. Leave the slider `ON` state for Create an alert option in Alert & notification section, then click `Continue`.
9. For Title: enter **`DemoGroup uptime check`**.
10. Click `TEST` to verify that your uptime check can connect to the resource.
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
