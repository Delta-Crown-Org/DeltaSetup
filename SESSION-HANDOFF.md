

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

### 2026-04-29 Follow-up — Auth Blocker
- Richard/code-puppy-bf0453 patched `deploy-security-hardening.ps1` for PnP.PowerShell 3.x by loading `PnPClientId` from `phase2-week1/modules/pnp-app-config.json` and passing `-ClientId` + tenant ID to `Connect-PnPOnline -DeviceLogin`.
- Local syntax checks passed for hardening and migration scripts.
- Phase 3 Pester tests passed: 50/50.
- Live SPO security hardening was retried with Tyler present and completed successfully on 2026-04-29 for dce-docs, dce-clientservices, dce-marketing, dce-hub, corp-hub, corp-hr, corp-it, corp-finance, and corp-training.
- Phase 4 migration dry-run copied no files and is blocked on HTT Brands source tenant auth. Legacy/no-client DeviceLogin returned `invalid_client`; historical source client `5d0381fe-0e8a-4656-80f3-fd91839667f1` returned AADSTS700016 app not found/not consented in Head to Toe Brands; browser `-Interactive` timed out in the agent shell.
- Tracking issues: `DeltaSetup-117` for live hardening/migration execution and `DeltaSetup-118` for registering/consenting an HTT Brands PnP app/client ID. `DeltaSetup-118` blocks E2E testing (`DeltaSetup-agr`) and production launch (`DeltaSetup-e46`).
