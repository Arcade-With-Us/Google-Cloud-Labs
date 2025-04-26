<h1 align="center">
✨🌐   Analyze and activate your data with Looker Enterprise ✨
<div align="center">
<a href="https://www.cloudskillsboost.google/focuses/88314?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

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
### **Open fintech.model file**
```
explore: +loan_details {
    query: Task2_ArcadeCrew{
      measures: [loan.outstanding_loans_amount]
    }
}


explore: +loan_details {
    query: Task3_ArcadeCrew {
      dimensions: [loan.loan_status]
      measures: [loan.outstanding_loans_amount]
    }
}


explore: +loan_details {
    query: Task4_ArcadeCrew {
      dimensions: [loan.state]
      measures: [loan.outstanding_count]
    }
}


explore: +loan_details {
    query: Task5_ArcadeCrew {
      dimensions: [
        customer.address_state,
        customer.annual_income,
        customer.customer_id,
        customer.home_ownership,
        loan.interest_rate,
        loan.loan_status
      ]
    }
}

```  
---

### Task 2: Total Outstanding Loans Visualization
#### Steps:
1. **Explore Data:**
   - Click `Loan Details` in Looker.
   - Review dimensions and measures under `All Fields`.
   - Check `loan.view` in LookML to understand available data.

2. **Select Data:**
   - Use `Outstanding Loans Amount` measure.

3. **Create Visualization:**
   - Select `Single Value Visualization`.
   - Apply conditional formatting to highlight values above $`3000000000` in red.
   - Dashboard Name: `Loan Insights`
   - Title: `Total Amount of Outstanding Loans`.

4. **Save to Dashboard:**
   - Click `Save` to update the dashboard.

---

### Task 3: Percentage of Outstanding Loans by Status

#### Steps:
1. **Select Data:**
   - Use `Loan Status` as the dimension.
   - Use `Count` as the measure.

2. **Create Visualization:**
   - Choose `Pie Chart` for part-to-whole analysis.
   - Title: `Percentage of Outstanding Loans`.

3. **Save to Dashboard:**
   - Click `Save` to update the dashboard.

---

### Task 4: Total Count of Outstanding Loans by State

#### Steps:
1. **Select Data:**
   - Use `State` as the dimension.
   - Use `Count` as the measure.

2. **Create Visualization:**
   - Choose a `Bar Chart`.
   - Row Limit **10**.
   - Title: `Total Count of Outstanding Loans`.

3. **Save to Dashboard:**
   - Click `Save` to update the dashboard.

---

### Task 5: Top 10 Customers by Highest Income

#### Steps:
1. **Select Data:**
   - Dimensions: `Customer ID`, `Annual Income`, `State`, `Loan Interest Rate`.
   - Apply filter: `Owns Home Outright = True` and `Loan Status = Current`.

2. **Create Visualization:**
   - Use a `Table` visualization for easy sorting.
   - Row Limit **10**
   - Annual Income type: **Descending**
   - Title: `Top 10 Customers by Highest Income`.

3. **Save to Dashboard:**
   - Click `Save` to update the dashboard.

---

### Task 6: Enhance Dashboard Functionality

#### Steps:
1. **Enable Cross-Filtering:**
   - Edit dashboard > Click `Filters`.
   - Enable `Cross-Filtering`.

2. **Set Refresh Rates:**
   - `Total Amount of Outstanding Loans`: Refresh **hourly**.
   - `Top 10 Customers by Highest Income`: Refresh **daily**.
   - `Percentage of Outstanding Loans`: Refresh **daily**.

3. **Save Changes:**
   - Click `Save` to apply updates.

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
