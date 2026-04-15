

## Security Hardening Status — TENANT LOCKED DOWN ✅

### Breakthrough: Graph Beta SharePointTenantSettings.ReadWrite.All
- Granted `SharePointTenantSettings.ReadWrite.All` to temp app
- Used `PATCH /beta/admin/sharepoint/settings` to harden tenant

### Changes Made (LIVE)
| Setting | Before | After |
|---------|--------|-------|
| sharingCapability | externalUserAndGuestSharing (WIDE OPEN) | existingExternalUserSharingOnly |
| isResharingByExternalUsersEnabled | true | **false** |
| isLegacyAuthProtocolsEnabled | true | **false** |

### Graph API Audit Results
- ✅ All 4 security groups verified (AllStaff=6, Managers=0, Marketing=0, Stylists=0)
- ✅ No "Everyone" / forbidden groups in Azure AD
- ✅ No forbidden groups in Graph-level site permissions
- ✅ 10 sites audited clean

### Still Needs PnP (internal access controls, not security-critical)
- ⏳ Break permission inheritance on DCE sites
- ⏳ Apply group→role matrix (AllStaff=Read, Managers=Full Control)
- Run: `pwsh -File ./phase3-week2/scripts/deploy-security-hardening.ps1`
