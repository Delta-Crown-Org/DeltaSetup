# Phase 2: Week 1 — Infrastructure + Identity
## Delta Crown Extensions SharePoint Hub & Spoke Architecture

### 🎯 Overview
This package contains all scripts, templates, and documentation for deploying the foundational infrastructure of the Delta Crown Extensions franchise ecosystem.

### 📁 Package Structure
```
phase2-week1/
├── scripts/
│   ├── 2.0-Master-Provisioning.ps1      # Orchestrates all tasks
│   ├── 2.1-CorpHub-Provisioning.ps1     # Corporate Hub + 4 sites
│   ├── 2.2-DCEHub-Provisioning.ps1      # DCE Hub + branding
│   ├── 2.3-AzureAD-DynamicGroups.ps1    # Security groups
│   └── 2.4-Verification.ps1             # Post-deployment verification
├── templates/
│   ├── CorpHub-Template.json            # Corporate site template
│   └── DCEHub-Template.json             # DCE branded template
├── docs/
│   ├── URL-and-ID-Inventory.md          # Site inventory (update after run)
│   └── azure-ad-groups-usage-guide.md   # Auto-generated
└── logs/                                # Execution logs (auto-created)
```

### 🚀 Quick Start

#### Option 1: Run Everything (Recommended)
```powershell
# Run from the phase2-week1 directory
.\scripts\2.0-Master-Provisioning.ps1 -TenantName "deltacrown" -OwnerEmail "admin@deltacrown.com"
```

#### Option 2: Run Individual Tasks
```powershell
# Task 2.1: Corporate Hub
.\scripts\2.1-CorpHub-Provisioning.ps1 -OwnerEmail "admin@deltacrown.com"

# Task 2.2: DCE Hub (run after 2.1)
.\scripts\2.2-DCEHub-Provisioning.ps1 -OwnerEmail "admin@deltacrown.com"

# Task 2.3: Azure AD Groups
.\scripts\2.3-AzureAD-DynamicGroups.ps1
```

#### Option 3: WhatIf Mode (Preview Changes)
```powershell
.\scripts\2.0-Master-Provisioning.ps1 -WhatIf
```

### ✅ Prerequisites

1. **PowerShell Modules** (install if missing):
```powershell
Install-Module PnP.PowerShell -Force
Install-Module Microsoft.Graph.Groups -Force
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force
```

2. **Permissions Required**:
   - SharePoint Administrator
   - Global Administrator (for Azure AD groups)
   - Site Collection Administrator

3. **Authentication**:
   - Interactive login (browser popup)
   - MFA supported

### 🏗 What Gets Created

#### 2.1 Corporate Shared Services Hub
- ✅ `/sites/corp-hub` — Communication Site (Hub)
- ✅ `/sites/corp-hr` — Associated Site
- ✅ `/sites/corp-it` — Associated Site  
- ✅ `/sites/corp-finance` — Associated Site
- ✅ `/sites/corp-training` — Associated Site
- ✅ Hub Navigation configured

#### 2.2 Delta Crown Extensions Hub
- ✅ `/sites/dce-hub` — Communication Site (Hub)
- ✅ Gold (#C9A227) & Black (#1A1A1A) branding applied
- ✅ Linked to Corp-Hub (hub-to-hub)
- ✅ DCE-specific navigation
- ✅ Initial page structure

#### 2.3 Azure AD Dynamic Groups
- ✅ `SG-DCE-AllStaff` — All DCE employees
- ✅ `SG-DCE-Leadership` — Managers, Directors, VPs

### 🔒 Security Notes

⚠️ **CRITICAL**: Business Premium has NO Information Barriers!

- ✅ Use dynamic groups for permissions (never "Everyone")
- ✅ Review permissions quarterly
- ✅ Finance site uses sensitivity labels
- ✅ External sharing disabled by default

### 🧪 Verification

After deployment, verify with:
```powershell
.\scripts\2.4-Verification.ps1 -TenantName "deltacrown" -ExportResults
```

### 📊 Expected Timeline

| Task | Duration | Dependencies |
|------|----------|--------------|
| 2.1 Corp Hub | 5-10 min | None |
| 2.2 DCE Hub | 5-10 min | 2.1 complete |
| 2.3 Azure AD | 2-5 min | None |
| Verification | 2-3 min | All above |
| **Total** | **15-30 min** | — |

### 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Site already exists" | Use `-Force` flag or skip creation |
| "Access denied" | Ensure you're SharePoint Admin |
| "Module not found" | Run prerequisite install commands |
| "Graph connection failed" | Check MFA completion |
| Group shows 0 members | Verify user attributes (department, companyName, jobTitle) |

### 📚 Documentation

- Full inventory: `docs/URL-and-ID-Inventory.md`
- Group usage: `docs/azure-ad-groups-usage-guide.md` (auto-generated)
- Execution logs: `logs/*.log`

### 🔄 Next Steps

After Phase 2.1-2.3 complete:
1. ✅ Populate user attributes for dynamic groups
2. ✅ Validate group membership
3. ⏭️ Proceed to Phase 2.4: Content Types & Document Libraries

---

**Questions?** Check the logs or run verification script for detailed status.
