# 🚀 Azure AD Empty Groups Exporter  

This **PowerShell script**, authored by **Tycho Löke**, automates the process of identifying and exporting **empty groups** from **Microsoft Entra ID (Azure AD)** using the **Microsoft Graph API**.  

The results are saved to a **CSV file**, making it easy to analyze and clean up unused groups in your directory. Now includes support for identifying groups with **nested memberships** and distinguishing between **on-premises** and **cloud-only** groups.

---

## 📌 Features  
✅ **Automated Empty Group Retrieval** – Fetches all Azure AD groups and identifies those with **no members**.  
✅ **Excludes Nested Memberships** – Ensures groups that are members of other groups are excluded from the report.  
✅ **Detailed Group Classification** – Categorizes groups into types like **Microsoft 365**, **Security**, or **Distribution**.  
✅ **On-Premises vs. Cloud-Only Groups** – Classifies each group as either **On-Premises**, **Cloud-Only**, or **Unknown**.  
✅ **Real-Time Updates** – Displays progress as it processes each group.  
✅ **Customizable Export Path** – Save the report to a location of your choice.  
✅ **Error Handling** – Skips inaccessible groups and logs warnings without interrupting the script.  

---

## 🛠 Prerequisites  

Before running the script, ensure you meet the following requirements:  

- **Azure Active Directory (AAD)** – Your account must be linked to an Azure AD tenant.  
- **Admin Role** – Requires **Group.Read.All** or higher permissions in AAD.  
- **Microsoft Graph PowerShell Module** – Installed automatically by the script if missing.  
- **PowerShell Execution Policy** – Must allow script execution (`Set-ExecutionPolicy RemoteSigned`).  

---

## 🚀 How to Use  

### **1️⃣ Download the Script**  
Clone this repository or download the script file manually.  

```powershell
git clone https://github.com/TychoLoke/azure-ad-empty-groups-exporter.git
cd azure-ad-empty-groups-exporter
```

### **2️⃣ Run PowerShell as Administrator**  
- Open **PowerShell** with elevated permissions (`Run as Administrator`).  

### **3️⃣ Execute the Script**  
Run the script using:  

```powershell
.\Export-AzureAD-EmptyGroups.ps1 -OutputPath "C:\Temp\EmptyGroups.csv"
```

### **4️⃣ Authenticate with Microsoft Graph**  
- A **pop-up login window** will appear.
- Sign in with your **Global Admin** or **Group Administrator** credentials.

### **5️⃣ What Happens Next?**  
✅ The script **checks for required modules** and installs them if missing.  
✅ It **connects to Microsoft Graph** via pop-up login.  
✅ Retrieves **all Azure AD groups** and identifies empty groups (with no direct members or nested memberships).  
✅ **Classifies each group** by type and origin (On-Premises or Cloud-Only).  
✅ Saves the report to the specified file path (e.g., `C:\Temp\EmptyGroups.csv`).  

---

## 🔎 Notes  
- The script uses **`Microsoft.Graph.Groups`** instead of the full Microsoft Graph module to optimize performance.  
- It provides **progress updates** for long-running operations (e.g., processing thousands of groups).  
- The default export location can be customized using the `-OutputPath` parameter.  

---

## 🛠 Troubleshooting  

### ❌ Module Not Found?  
Ensure you have an internet connection and sufficient permissions to install the `Microsoft.Graph` module.  

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

### ❌ Script Fails to Authenticate?  
Verify your account has **Global Admin** or **Group Administrator** privileges.  

### ❌ Script Hangs or Freezes?  
If processing thousands of groups, allow the script time to complete. Progress is displayed in the PowerShell window.  

---

## 🤝 Contributing  

Want to improve this script? Contributions are welcome!  

**To contribute:**  
1. **Fork** the repository.  
2. **Create a feature branch** (`git checkout -b feature-name`).  
3. **Submit a Pull Request** with your changes.  

---

## 📜 License  

This project is licensed under the **MIT License** – feel free to use, modify, and distribute it.  

---

## 🔗 Author  

**Tycho Löke**  
GitHub: [TychoLoke](https://github.com/TychoLoke)

---

## 📋 Change Log  

### **v1.2.0** (February 2025)  
- **Added On-Premises vs. Cloud-Only Classification**:  
   - Groups are now classified as **On-Premises**, **Cloud-Only**, or **Unknown** based on the `OnPremisesSyncEnabled` property.  
   - This helps to distinguish between groups synced from on-premises environments and those created in the cloud.  

- **Improved Nested Membership Handling**:  
   - Groups that are members of other groups are excluded from the report.  

- **Enhanced Progress Updates and Logging**:  
   - Progress bar updated for better tracking during long executions.  

### **v1.1.0** (February 2025)  
- Added support for **nested memberships**:  
   - Groups that are members of other groups are now excluded from the empty groups report.  
   - Ensures that groups involved in nested relationships are not accidentally flagged for cleanup.  

### **v1.0.0** (February 2025)  
- Initial release of the script:  
   - Fetches all Azure AD groups.  
   - Identifies empty groups (no direct members).  
   - Categorizes groups by type (Microsoft 365, Security, Distribution, etc.).  
   - Exports results to a CSV file.  
