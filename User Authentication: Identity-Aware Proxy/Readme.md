<h1 align="center">
✨ User Authentication: Identity-Aware Proxy || GSP499 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/5562?parent=catalog" target="_blank" rel="noopener noreferrer">
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
export REGION=
```
```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/User%20Authentication%3A%20Identity-Aware%20Proxy/GSP499.sh

sudo chmod +x GSP499.sh

./GSP499.sh
```
* Go to `OAuth consent screen` from [here](https://console.cloud.google.com/apis/credentials/consent?)
    * Click Get Started.
    * For App name, enter `IAP Example`.
    * Click **User support email**, and then click the **student email** and then click **Next**.
    * For **Audience**, select **Internal**, and then click **Next**.
    * On the left panel of the lab instructions, copy the **Username**.
    * For Contact information, paste the copied **username**.
    * Click **Next**.
    * Click Checkbox to agree the User Data Policy and click Continue and then click **Create**.

* Go to `Identity-Aware Proxy` from [here](https://console.cloud.google.com/security/iap?)
    * Return to the **Identity-Aware Proxy** page and refresh it.
    * You should now see a list of resources you can protect.
    * Click the toggle button in the **IAP column** in the App Engine app row to turn **IAP** on.
    * The domain will be protected by **IAP**. Click **Turn On**.
    * Click **Add Principal**.
    * Enter your **Student email address**.
    * Then, pick the `Cloud IAP` > **`IAP-Secured Web App User role`** to assign to that address.
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
