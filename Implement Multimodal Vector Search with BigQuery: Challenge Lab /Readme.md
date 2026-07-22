<h1 align="center">
✨  Implement Multimodal Vector Search with BigQuery: Challenge Lab || GSP523 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/course_templates/1232/labs/550617"_blank" rel="noopener noreferrer">
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
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Implement%20Multimodal%20Vector%20Search%20with%20BigQuery%3A%20Challenge%20Lab%20/GSP523.sh

sudo chmod +x GSP523.sh

./GSP523.sh
```
### For the last TASK 4, If you don't get the full score, run this code in BIGQUERY
##### Make sure to change the variables value like (MODEL_NAME, PROJECT_ID, DATASET_NAME, EMBEDDINGS_FUNCTION)
```py
Create or replace table `[PROJECT_ID].[DATASET_NAME].[SEARCH_RESULTS_TABLE]` AS
select base.uri,
base.product_name,
base.content_type,
distance
 from
[VECTOR_SEARCH_FUNCTION](table [DATASET_NAME].[EMBEDDINGS_TABLE_NAME],'ml_generate_embedding_result',
(
SELECT ml_generate_embedding_result as embedding_col
FROM
 [EMBEDDINGS_FUNCTION]
 (
   MODEL `[DATASET_NAME].[MODEL_NAME]`,
   (select 'Men Sweaters' as content),
   STRUCT(TRUE AS flatten_json_output)
 )
),
  [STATEMENT_TO_SELECT_TOP_2_RESULTS],
  distance_type => 'COSINE'
);
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
    <em>Last updated: June 2025</em>
  </p>
</div>
