# 🐶 Security Hardening — Tyler Must Run This

## Why Richard Can't Do It

SharePoint Online blocks:
1. **App-only tokens** — Tenant has `DisableCustomAppAuthentication = true`
2. **Guest admin REST calls** — Your SPO user profile doesn't exist yet
3. **PnP DeviceLogin** — Can't display device codes in non-interactive shell

## What You Need To Do (5 minutes)

### Step 1: Visit SPO Admin (creates your profile)
Open in browser: `https://deltacrown-admin.sharepoint.com`
Login as: `tyler.granlund-admin@httbrands.com`

### Step 2: Run the Security Script
```bash
cd ~/dev/DeltaSetup/phase3-week2/scripts
pwsh -NoProfile -File ./deploy-security-hardening.ps1
```

You'll see device code prompts for each site (9 total).
Enter each code at https://microsoft.com/devicelogin

### What The Script Does
1. **Breaks permission inheritance** on 4 DCE sites
2. **Removes "Everyone" groups** from all sites
3. **Applies permission matrix:**
   - AllStaff → Read (all DCE sites)
   - Managers → Full Control (all DCE sites)
   - Marketing → Edit (dce-marketing only)
4. **Disables external sharing** on all 9 sites

### Alternative: Enable App-Only Auth First
If you want Richard to handle it next session:
```powershell
Connect-SPOService -Url "https://deltacrown-admin.sharepoint.com"
Set-SPOTenant -DisableCustomAppAuthentication $false
```
Then Richard can use the temp app's `Sites.FullControl.All` grant.

## What Richard Already Did ✅
- All 4 security groups verified (AllStaff, Managers, Marketing, Stylists)
- No "Everyone" groups exist in Azure AD
- No forbidden groups in site permissions (Graph-level audit clean)
- 3 DLP policies deployed and active
- Teams workspace with 5 channels deployed
