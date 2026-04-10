# Phase 2: Week 1 Rollout Checklist
## Delta Crown Extensions Infrastructure Deployment

> **Status:** Ready for Deployment  
> **Date:** ___________  
> **Executed By:** ___________

---

## Pre-Deployment

- [ ] PowerShell 5.1+ or 7.x installed
- [ ] PnP PowerShell module installed
- [ ] Microsoft Graph modules installed
- [ ] SharePoint Admin credentials confirmed
- [ ] Azure AD Admin credentials confirmed
- [ ] Tenant name verified: `deltacrownext`
- [ ] Admin email identified
- [ ] Change window scheduled
- [ ] Rollback plan documented

---

## Task 2.1: Corporate Shared Services Hub

**Script:** `scripts/2.1-CorpHub-Provisioning.ps1`

### Creation Status
- [ ] Corp-Hub site created (`/sites/corp-hub`)
- [ ] Corp-Hub registered as Hub Site
- [ ] Corp-HR site created (`/sites/corp-hr`)
- [ ] Corp-IT site created (`/sites/corp-it`)
- [ ] Corp-Finance site created (`/sites/corp-finance`)
- [ ] Corp-Training site created (`/sites/corp-training`)

### Association Status
- [ ] Corp-HR associated with Corp-Hub
- [ ] Corp-IT associated with Corp-Hub
- [ ] Corp-Finance associated with Corp-Hub
- [ ] Corp-Training associated with Corp-Hub

### Navigation Status
- [ ] Home link configured
- [ ] HR Resources link configured
- [ ] IT Support link configured
- [ ] Finance link configured
- [ ] Training link configured

**Execution Time:** _____  
**Log File:** `logs/CorpHub-Provisioning-*.log`

---

## Task 2.2: Delta Crown Extensions Hub

**Script:** `scripts/2.2-DCEHub-Provisioning.ps1`

### Creation Status
- [ ] DCE-Hub site created (`/sites/dce-hub`)
- [ ] DCE-Hub registered as Hub Site

### Branding Status
- [ ] Gold (#C9A227) theme applied
- [ ] Black (#1A1A1A) secondary color set
- [ ] Theme name: "Delta Crown Extensions Theme"
- [ ] Header styling configured

### Linkage Status
- [ ] DCE-Hub linked to Corp-Hub (hub-to-hub)

### Navigation Status
- [ ] Home link configured
- [ ] Operations link configured
- [ ] Client Services link configured
- [ ] Marketing link configured
- [ ] Document Center link configured

### Page Structure
- [ ] Operations.aspx created
- [ ] Client-Services.aspx created
- [ ] Marketing.aspx created
- [ ] Document-Center.aspx created

**Execution Time:** _____  
**Log File:** `logs/DCEHub-Provisioning-*.log`

---

## Task 2.3: Azure AD Dynamic Groups

**Script:** `scripts/2.3-AzureAD-DynamicGroups.ps1`

### Group Creation
- [ ] SG-DCE-AllStaff group created
- [ ] SG-DCE-Leadership group created

### Membership Rules
- [ ] SG-DCE-AllStaff rule validated
- [ ] SG-DCE-Leadership rule validated

### Processing Status
- [ ] SG-DCE-AllStaff membership processing enabled
- [ ] SG-DCE-Leadership membership processing enabled

### Documentation
- [ ] Group configuration exported to JSON
- [ ] Usage guide generated

**Execution Time:** _____  
**Log File:** `logs/AzureAD-Groups-*.log`

---

## Verification

**Script:** `scripts/2.4-Verification.ps1`

### Site Verification
- [ ] All 6 sites accessible via browser
- [ ] Corp-Hub responds correctly
- [ ] DCE-Hub responds correctly
- [ ] All associated sites respond

### Hub Verification
- [ ] Corp-Hub shows as Hub in Admin Center
- [ ] DCE-Hub shows as Hub in Admin Center
- [ ] Hub associations visible
- [ ] Hub-to-hub link confirmed

### Navigation Verification
- [ ] Corp-Hub navigation displays correctly
- [ ] DCE-Hub navigation displays correctly
- [ ] All navigation links functional

### Group Verification
- [ ] Groups visible in Azure AD
- [ ] Membership rules processing
- [ ] Sample members populated (may take time)

### Results
- [ ] Verification results exported to CSV
- [ ] All PASS status (or documented exceptions)

**Execution Time:** _____  
**Log File:** `logs/Verification-*.log`

---

## Post-Deployment

### Documentation
- [ ] URL-and-ID-Inventory.md updated with actual IDs
- [ ] Site ownership documented
- [ ] Hub IDs recorded
- [ ] Group Object IDs recorded

### Security
- [ ] Site permissions reviewed
- [ ] No "Everyone" or "All Users" permissions found
- [ ] External sharing settings verified (disabled)
- [ ] Sensitivity labels applied to Finance site

### Handoff
- [ ] Results shared with stakeholders
- [ ] Log files archived
- [ ] Next phase (2.4) scheduled
- [ ] Knowledge transfer completed

---

## Rollback Plan

If issues encountered:

1. **Document** the issue in logs
2. **Preserve** log files for analysis
3. **Do NOT** delete sites immediately
4. **Contact** Microsoft Support if tenant-level issues
5. **Retry** specific task with `-Force` flag if appropriate
6. **Escalate** if critical business impact

### Emergency Contacts
- SharePoint Admin: ___________
- Azure AD Admin: ___________
- Microsoft Support: ___________

---

## Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Executed By** | | | |
| **Verified By** | | | |
| **Approved By** | | | |

---

## Notes

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```
