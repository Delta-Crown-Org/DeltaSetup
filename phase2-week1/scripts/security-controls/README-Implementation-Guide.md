# Delta Crown Extensions - Compensating Controls Implementation Guide
## Security Controls for Business Premium (No Information Barriers)

---

## Executive Summary

**Document Owner**: Security Auditor (security-auditor-b724ae)  
**Target Audience**: code-puppy (Implementation Team)  
**Status**: READY FOR IMPLEMENTATION  
**Risk Level**: HIGH (requires all controls for brand isolation)

### Purpose
This guide provides detailed implementation specifications for all 6 compensating controls required to achieve brand isolation in the absence of Microsoft Information Barriers (Business Premium limitation).

### Document Structure
```
security-controls/
├── README-Implementation-Guide.md          (This file - Master Guide)
├── 1-Sensitivity-Labels-Specification.md   (Control #3)
├── 2-DLP-Policies-Specification.md         (Control #4)
├── Weekly-Permission-Audit.ps1             (Control #5)
├── Test-CrossBrandIsolation.ps1            (Validation)
└── Security-Configuration-Verification.ps1 (Integration with 2.4-Verification.ps1)
```

---

## The 6 Compensating Controls

| Control | Name | Criticality | Implementation Status | File |
|---------|------|-------------|----------------------|------|
| #1 | Azure AD Dynamic Groups | **CRITICAL** | ✅ Complete | 2.3-AzureAD-DynamicGroups.ps1 |
| #2 | Strict Unique Permissions | **CRITICAL** | ✅ Complete | 2.1-CorpHub-Provisioning.ps1 |
| #3 | Sensitivity Labels | HIGH | 📋 Specification Ready | 1-Sensitivity-Labels-Specification.md |
| #4 | DLP Policies | HIGH | 📋 Specification Ready | 2-DLP-Policies-Specification.md |
| #5 | Weekly Permission Scan | MEDIUM | ✅ Script Ready | Weekly-Permission-Audit.ps1 |
| #6 | Quarterly Access Review | MEDIUM | 📋 Process Defined | Documented |

**Legend**: ✅ Complete | 📋 Specification Ready | ⏳ Pending

---

## Implementation Phases

### Phase 1: Critical Controls (MUST HAVE for Go-Live)

**Timeline**: Complete before DCE Hub deployment

#### Control #1: Azure AD Dynamic Groups
- **File**: `phase2-week1/scripts/2.3-AzureAD-DynamicGroups.ps1`
- **Purpose**: Automated brand membership via Azure AD attributes
- **Groups to Create**:
  - `AllStaff` (Department contains "Delta Crown")
  - `Managers` (Company contains "Delta Crown" AND management titles)
- **Prerequisites**: User attributes populated in Azure AD
- **Execution**: `./2.3-AzureAD-DynamicGroups.ps1 -WhatIf` (test first)

#### Control #2: Strict Unique Permissions
- **File**: `phase2-week1/scripts/2.1-CorpHub-Provisioning.ps1` and `2.2-DCEHub-Provisioning.ps1`
- **Purpose**: Every brand site must have unique permissions (no inheritance)
- **Verification**: Check `HasUniqueRoleAssignments` property on each site
- **Auto-Check**: Included in Security-Configuration-Verification.ps1

**CRITICAL**: If these two controls fail, **STOP DEPLOYMENT IMMEDIATELY**

---

### Phase 2: Data Protection Controls (Week 2-3)

#### Control #3: Sensitivity Labels (DCE-Internal)

**Quick Reference**:
```powershell
# Connect to Security & Compliance Center
Connect-IPPSSession -UserPrincipalName admin@deltacrown.com

# Create label
New-Label -Name "DCE-Internal" -DisplayName "Delta Crown - Internal" `
    -EncryptionEnabled $true `
    -EncryptionAssignUsers "AllStaff", "Managers" `
    -HeaderText "Delta Crown Extensions — INTERNAL USE ONLY"
```

**Detailed Spec**: See `1-Sensitivity-Labels-Specification.md`

**Key Settings**:
- **Label Name**: DCE-Internal
- **Encryption**: User-defined (assigned to DCE groups)
- **Offline Access**: 30 days
- **Auto-Apply**: Based on site URL containing "dce"
- **Content Marking**: Header + Footer with brand colors

**Verification**:
```powershell
Get-Label | Where-Object { $_.Name -eq "DCE-Internal" }
```

#### Control #4: DLP Policies (DCE-Data-Protection)

**Quick Reference**:
```powershell
# Create DLP Policy
New-DlpCompliancePolicy -Name "DCE-Data-Protection" `
    -SharePointLocation "https://deltacrown.sharepoint.com/sites/dce-*" `
    -Mode TestWithNotifications

# Add rules
New-DlpComplianceRule -Name "Block-Cross-Brand-Access" `
    -Policy "DCE-Data-Protection" `
    -BlockAccess $true `
    -ContentContainsSensitiveInformation @{ Labels = @("DCE-Internal") }
```

**Detailed Spec**: See `2-DLP-Policies-Specification.md`

**Key Configuration**:
- **Policy Name**: DCE-Data-Protection
- **Mode**: TestWithNotifications (90 days)
- **Rules**:
  1. Block cross-brand sharing
  2. Warn on external sharing
  3. Block external downloads
- **Scope**: DCE sites, Teams, Exchange

**90-Day Test Period**:
- Week 1-4: Monitor false positives
- Week 5-8: Tune rules based on feedback
- Week 9-12: Prepare for enforce mode
- Day 90: Switch to Enforce mode

---

### Phase 3: Monitoring Controls (Week 3-4)

#### Control #5: Weekly Permission Scan

**Script**: `Weekly-Permission-Audit.ps1`

**What It Does**:
1. Scans all DCE sites for permission violations
2. Checks for inherited permissions (should be NONE)
3. Checks for "Everyone"/"All Users" groups (should be NONE)
4. Checks for external sharing enabled (should be NONE)
5. Generates HTML + CSV reports
6. Sends email alerts on critical findings

**Scheduling Options**:

**Option A: Windows Task Scheduler** (On-premises server)
```powershell
# Run as administrator
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File 'C:\Scripts\Weekly-Permission-Audit.ps1'"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "02:00"
Register-ScheduledTask -TaskName "DCE-Weekly-Permission-Audit" `
    -Action $action -Trigger $trigger -User "DOMAIN\ServiceAccount"
```

**Option B: Azure Automation** (Cloud)
1. Create Azure Automation account
2. Import PnP.PowerShell module
3. Upload script as runbook
4. Schedule weekly execution

**Manual Execution**:
```powershell
.\Weekly-Permission-Audit.ps1 -WhatIf          # Preview
.\Weekly-Permission-Audit.ps1                  # Run audit
.\Weekly-Permission-Audit.ps1 -AutoRemediate   # Auto-fix issues
```

**Auto-Remediation Capabilities**:
- `-AutoRemediate` flag enables automatic fixes for:
  - Inherited permissions (breaks inheritance)
  - External sharing (disables sharing)
- **NOTE**: Dangerous groups require manual review

#### Control #6: Quarterly Access Review

**Process Overview**:

| Step | Action | Owner | Timeline |
|------|--------|-------|----------|
| 1 | Generate access report | IT Security | Week 1 of quarter |
| 2 | Distribute to brand managers | Compliance | Week 1 |
| 3 | Managers review and attest | Brand Managers | Week 2-3 |
| 4 | Collect attestations | Compliance | Week 4 |
| 5 | Remediate exceptions | IT Security | Week 5-6 |
| 6 | Archive documentation | Compliance | Week 6 |

**Access Review Template**:
```
DELTA CROWN EXTENSIONS - QUARTERLY ACCESS REVIEW

Review Period: [Q1/Q2/Q3/Q4] [Year]
Brand: Delta Crown Extensions
Reviewer: [Brand Manager Name]
Date: [Review Date]

Site: DCE-Operations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
□ All members still require access
□ No external users have access
□ No inappropriate permission levels
□ Comments: ________________

Attestation:
I confirm that I have reviewed all access permissions for DCE sites
and attest that access is appropriate for business requirements.

Signature: _________________ Date: _______
```

---

## Testing & Validation

### Test Script: Cross-Brand Isolation

**File**: `Test-CrossBrandIsolation.ps1`

**When to Run**:
- ✅ After initial DCE Hub deployment
- ✅ After each new brand deployment
- ✅ After permission changes
- ✅ Monthly as regression test

**What It Tests**:
1. **Search Isolation**: Brand A search doesn't return Brand B content
2. **Access Isolation**: Brand A users can't access Brand B sites
3. **Navigation Isolation**: Hub navigation is brand-scoped
4. **Teams Isolation**: Channel content doesn't leak across brands

**Execution**:
```powershell
# Run all tests
.\Test-CrossBrandIsolation.ps1

# Run without failing deployment on violations
.\Test-CrossBrandIsolation.ps1 -FailOnViolation:$false

# Preview what would be tested
.\Test-CrossBrandIsolation.ps1 -WhatIf
```

**Exit Codes**:
- `0`: All tests passed ✅
- `1`: Cross-brand isolation violations detected ❌

### Integration with 2.4-Verification.ps1

**Security Verification Script**: `Security-Configuration-Verification.ps1`

This script is designed to be called from `2.4-Verification.ps1` to validate all compensating controls before marking deployment as complete.

**Integration Code** (add to 2.4-Verification.ps1):
```powershell
# At the end of 2.4-Verification.ps1, before final success message

# Import and run security verification
$securityModule = Join-Path $PSScriptRoot "security-controls\Security-Configuration-Verification.ps1"
if (Test-Path $securityModule) {
    Import-Module $securityModule -Force
    
    Write-Log "Running security control verification..." "VERIFY"
    $securityPassed = Invoke-SecurityVerification
    
    if (-not $securityPassed) {
        Write-Log "CRITICAL: Security compensating controls are not fully active!" "ERROR"
        Write-Log "Deployment verification FAILED due to missing security controls." "ERROR"
        exit 1
    }
    
    $allResults += [PSCustomObject]@{
        Component = "Security Controls"
        Status = "PASS"
        Details = "All compensating controls verified"
    }
} else {
    Write-Log "Security verification module not found - skipping" "WARNING"
}
```

---

## Quick Reference: PowerShell Commands

### Control #1: Dynamic Groups
```powershell
# View groups
Get-MgGroup | Where-Object { $_.DisplayName -like "SG-DCE*" }

# Check group members
Get-MgGroupMember -GroupId (Get-MgGroup -Filter "displayName eq 'AllStaff'").Id

# View membership rule
Get-MgGroup -Filter "displayName eq 'AllStaff'" | Select-Object MembershipRule
```

### Control #2: Unique Permissions
```powershell
# Check site permissions
Connect-PnPOnline -Url "https://deltacrown.sharepoint.com/sites/dce-hub" -Interactive
$web = Get-PnPWeb
$web.HasUniqueRoleAssignments  # Should be $true

# List role assignments
Get-PnPProperty -ClientObject $web -Property RoleAssignments
```

### Control #3: Sensitivity Labels
```powershell
# Connect to Compliance Center
Connect-IPPSSession -UserPrincipalName admin@deltacrown.com

# List labels
Get-Label | Where-Object { $_.Name -like "DCE*" }

# Check auto-label policies
Get-AutoSensitivityLabelPolicy | Where-Object { $_.Name -like "DCE*" }
```

### Control #4: DLP Policies
```powershell
# Connect to Compliance Center
Connect-IPPSSession -UserPrincipalName admin@deltacrown.com

# List policies
Get-DlpCompliancePolicy | Where-Object { $_.Name -like "DCE*" }

# View policy rules
Get-DlpComplianceRule -Policy "DCE-Data-Protection"

# Check matches
Get-DlpDetailReport -PolicyName "DCE-Data-Protection" -StartDate (Get-Date).AddDays(-7)
```

### Control #5: Weekly Scan
```powershell
# Run scan
.\Weekly-Permission-Audit.ps1

# Check reports
Get-ChildItem .\phase2-week1\reports\Permission-Audit-*.html | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

---

## Compliance Mapping

| Framework | Requirement | Control(s) | Evidence |
|-----------|-------------|------------|----------|
| **OWASP ASVS** | 7.1 - Content Classification | #3 | Label config export |
| **OWASP ASVS** | 7.2 - Encryption at Rest | #3 | Encryption settings |
| **OWASP ASVS** | 7.3 - Data Transmission | #4 | DLP policy config |
| **SOC 2 CC6.1** | Logical Access Controls | #1, #2 | Group membership, permission audit |
| **SOC 2 CC6.6** | Data Leakage Prevention | #4 | DLP policy matches |
| **SOC 2 CC7.2** | System Monitoring | #5 | Weekly audit reports |
| **ISO 27001 A.8.2.1** | Information Classification | #3 | Label documentation |
| **ISO 27001 A.9.1.2** | Access to Networks | #2, #4 | Permission reports |
| **ISO 27001 A.12.3.1** | Information Backup | #6 | Access review records |
| **GDPR Art. 32** | Security of Processing | #3, #4 | Encryption + DLP |

---

## Troubleshooting

### Issue: Dynamic Groups Not Populating
**Symptoms**: Groups show 0 members after creation

**Resolution**:
1. Check user attributes in Azure AD:
   ```powershell
   Get-MgUser -UserId "user@deltacrown.com" | Select-Object Department, CompanyName, JobTitle
   ```
2. Verify membership rule syntax
3. Wait 5-30 minutes for initial sync
4. Check Azure AD > Groups > [Group] > Members for processing status

### Issue: Sensitivity Labels Not Applying
**Symptoms**: Documents don't have labels

**Resolution**:
1. Verify label is published to DCE sites
2. Check auto-label policy mode (Test vs Enforce)
3. Ensure content matches auto-label conditions
4. Review audit logs in Compliance Center

### Issue: DLP Policy Blocking Legitimate Sharing
**Symptoms**: Users can't share with authorized parties

**Resolution**:
1. Switch policy to TestWithoutNotifications temporarily
2. Review DLP matches in Compliance Center
3. Tune conditions to reduce false positives
4. Add exceptions as needed
5. Return to TestWithNotifications or Enforce

### Issue: Permission Scan Shows Inherited Permissions
**Symptoms**: Sites have inherited permissions (violation)

**Resolution**:
1. **Immediate**: Break inheritance on affected site:
   ```powershell
   Connect-PnPOnline -Url $siteUrl -Interactive
   Set-PnPWeb -BreakRoleInheritance -CopyRoleAssignments
   ```
2. **Root Cause**: Investigate how inheritance was re-enabled
3. **Prevention**: Add to weekly scan alerts

---

## Implementation Checklist

### Pre-Implementation
- [ ] Review all specification documents
- [ ] Verify Azure AD user attributes are populated
- [ ] Confirm Exchange Online module available for sensitivity labels/DLP
- [ ] Test connectivity to all M365 services
- [ ] Prepare rollback plan

### Control #1: Azure AD Dynamic Groups
- [ ] Run `2.3-AzureAD-DynamicGroups.ps1 -WhatIf`
- [ ] Review dynamic group membership rules
- [ ] Execute without WhatIf flag
- [ ] Verify groups appear in Azure AD
- [ ] Wait 30 minutes and verify member population
- [ ] Document group Object IDs

### Control #2: Unique Permissions
- [ ] Deploy Corporate Hub (2.1-CorpHub-Provisioning.ps1)
- [ ] Deploy DCE Hub (2.2-DCEHub-Provisioning.ps1)
- [ ] Run permission inheritance check
- [ ] Verify all DCE sites have unique permissions
- [ ] Document any exceptions

### Control #3: Sensitivity Labels
- [ ] Connect to Security & Compliance Center
- [ ] Create DCE-Internal label
- [ ] Configure encryption settings
- [ ] Set up auto-labeling rules
- [ ] Publish label to DCE sites
- [ ] Test label application on sample document
- [ ] Verify content marking appears

### Control #4: DLP Policies
- [ ] Create DCE-Data-Protection policy
- [ ] Add cross-brand sharing rule
- [ ] Add external sharing warning rule
- [ ] Set mode to TestWithNotifications
- [ ] Configure alert recipients
- [ ] Test policy with sample content
- [ ] Schedule 90-day review for Enforce mode

### Control #5: Weekly Scan
- [ ] Copy Weekly-Permission-Audit.ps1 to scripts directory
- [ ] Test script execution with -WhatIf
- [ ] Create scheduled task or Azure Automation runbook
- [ ] Configure email alert recipients
- [ ] Run initial scan and review results
- [ ] Document baseline findings

### Control #6: Quarterly Access Review
- [ ] Create ACCESS-REVIEW-PROCESS.md
- [ ] Design access review template
- [ ] Identify brand managers for attestation
- [ ] Set up access-attestations directory
- [ ] Schedule first quarterly review
- [ ] Document review cycle in calendar

### Post-Implementation
- [ ] Run `Test-CrossBrandIsolation.ps1`
- [ ] Verify all controls in Security-Configuration-Verification.ps1
- [ ] Generate compliance evidence package
- [ ] Schedule 90-day control effectiveness review
- [ ] Document lessons learned
- [ ] Update runbooks for future brand deployments

---

## Next Steps for code-puppy

1. **Review this guide** and ask questions on any unclear sections
2. **Start with Control #1 and #2** (Critical for go-live)
3. **Test each control** using -WhatIf before production execution
4. **Run Test-CrossBrandIsolation.ps1** after each control implementation
5. **Schedule weekly permission scan** before end of Week 2
6. **Set calendar reminder** for 90-day DLP policy mode switch

**Questions? Contact**: security-auditor-b724ae

---

**Document Version**: 1.0  
**Last Updated**: $(Get-Date -Format 'yyyy-MM-dd')  
**Review Cycle**: Quarterly or after each brand deployment
