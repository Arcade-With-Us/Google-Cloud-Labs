<h1 align="center">
✨ Build a Serverless Web App with Firebase || GSP643 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/8391?parent=catalog" target="_blank" rel="noopener noreferrer">
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

## 🚀 **Steps to Perform**

### Step 1: Access Firebase Console
👉 Go to the [Firebase Console](https://console.firebase.google.com/).
### THEN FOLLOW INSTRUCTIONS FROM VIDEO

### Step 2: Register Your App
- **App Name:** `Pet Theory`

#### Follow these Steps:

1. Click on the Build dropdown button in the left-hand navigation panel.
2. Select Authentication tile and then click on Get Started:
3. Click on Sign-in method tab and then, click on the Google item.
4. Click the enable toggle in the top right corner and for the Support email for project select your lab account from the drop down list.
5. Your page should now resemble the following:
![Demo](https://cdn.qwiklabs.com/wzLcWPT%2BlNf6jxJtjkmE3OdSlCGqrjrvGoBqDXHNCTc%3D)
6. Once you have verified the above, click on the Save button.
7. Click the Settings tab
8. Under the Domains heading, click the Authorized domains menu item
9. Your page should now resemble the following:
![Demo](https://cdn.qwiklabs.com/7Ifu%2B9cIFk3UDNQ%2BWgo5YEI75AQXi4WsfDYUGYDFgxQ%3D)
10. Click the Add domain button and add your given domain
11. Click the Add button

### Now Set up rules:

1. Click on the Build dropdown button in the left-hand navigation panel.
2. Select Firestore Database tile and then click on Create database:
3. Accept the default settings and click Next
4. Click Create to provision Cloud Firestore
5. Click the Rules tab
6. Update the rules as follows:
```cpp
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
  match /customers/{email} {
    allow read, write: if request.auth.token.email == email;
    }
  match /customers/{email}/{document=**} {
    allow read, write: if request.auth.token.email == email;
    }
  }
}
```

### Step 3: Run in Terminal: [Open](https://ide-service-rs5smkw3ba-ue.a.run.app) 

```bash
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Build%20a%20Serverless%20Web%20App%20with%20Firebase/GSP643.sh
sed -i 's/\r$//' GSP643.sh
source GSP643.sh
```

### Now follow the steps:

1. We need the following products:
  * Firestore
  * Hosting
2. Use the arrow keys and the spacebar to select Firestore and Hosting. Ensure your shell matches the following and then hit Enter:
```cpp
? Which Firebase CLI features do you want to set up for this folder? Press Space to select features, then Enter to confirm your choices.
 ◯ Realtime Database: Configure a security rules file for Realtime Database and (optionally) provision default insta
 ◉ Firestore: Configure security rules and indexes files for Firestore
 ◯ Functions: Configure a Cloud Functions directory and its files
❯◉ Hosting: Configure files for Firebase Hosting and (optionally) set up GitHub Action deploys
 ◯ Hosting: Set up GitHub Action deploys
 ◯ Storage: Configure a security rules file for Cloud Storage
```
### ▶️ **NOW FOLLOW STEPS IN THE VIDEO**

#### Customer name: ```John``` 
#### Customer phone: ```98473757454```
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
