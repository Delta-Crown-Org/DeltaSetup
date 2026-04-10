# ⚡ Quick Start Card

## Run Everything (5 Commands)

```powershell
# 1. Navigate to folder
cd phase2-week1

# 2. Install modules (first time only)
Install-Module PnP.PowerShell, Microsoft.Graph.Groups -Force

# 3. Run master script
.\scripts\2.0-Master-Provisioning.ps1 `
    -TenantName "deltacrown" `
    -OwnerEmail "admin@deltacrown.com"

# 4. Verify
.\scripts\2.4-Verification.ps1 -ExportResults

# 5. Check results
Get-Content .\docs\URL-and-ID-Inventory.md
```

---

## Created Resources

| Resource | URL |
|----------|-----|
| Corp Hub | `https://deltacrown.sharepoint.com/sites/corp-hub` |
| Corp HR | `https://deltacrown.sharepoint.com/sites/corp-hr` |
| Corp IT | `https://deltacrown.sharepoint.com/sites/corp-it` |
| Corp Finance | `https://deltacrown.sharepoint.com/sites/corp-finance` |
| Corp Training | `https://deltacrown.sharepoint.com/sites/corp-training` |
| DCE Hub | `https://deltacrown.sharepoint.com/sites/dce-hub` |

---

## Dynamic Groups

| Group | Rule |
|-------|------|
| SG-DCE-AllStaff | Department contains "Delta Crown" OR Company contains "Delta Crown Extensions" |
| SG-DCE-Leadership | Company contains "Delta Crown" AND Title contains Manager/Director/VP |

---

## What If Something Goes Wrong?

```powershell
# Preview changes without applying
.\scripts\2.0-Master-Provisioning.ps1 -WhatIf

# Run only one task
.\scripts\2.0-Master-Provisioning.ps1 -ExecuteTasks "2.1"

# Force continue on errors
.\scripts\2.0-Master-Provisioning.ps1 -Force
```

---

## Check Logs

```powershell
# Latest log
Get-ChildItem .\logs\* | Sort LastWriteTime -Descending | Select -First 1

# All results
Get-Content .\docs\provisioning-results.json | ConvertFrom-Json
```
