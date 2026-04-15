

## Security Hardening Status

### Graph API Audit Results (automated)
- ✅ All 4 security groups exist (AllStaff, Managers, Marketing, Stylists)
- ✅ No forbidden groups ("Everyone", "All Users") in Azure AD
- ✅ No forbidden groups in Graph-level site permissions
- ✅ 10 sites audited via Graph API

### Blocked By SharePoint
- ❌ SPO tenant has `DisableCustomAppAuthentication = true` → app tokens rejected
- ❌ Tyler's guest admin has no SPO user profile → delegated tokens rejected  
- ❌ PnP DeviceLogin needs interactive terminal → can't run from agent

### Tyler Must Run
```bash
# 1. Visit https://deltacrown-admin.sharepoint.com in browser first
# 2. Then:
cd ~/dev/DeltaSetup/phase3-week2/scripts
pwsh -NoProfile -File ./deploy-security-hardening.ps1
```

### Alternative: Enable App-Only (then Richard can do it)
```powershell
Connect-SPOService -Url "https://deltacrown-admin.sharepoint.com"
Set-SPOTenant -DisableCustomAppAuthentication $false
```
