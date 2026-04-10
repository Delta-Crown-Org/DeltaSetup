# 🧪 QA Test Plan: Delta Crown Extensions SharePoint Hub & Spoke
## Multi-Brand Franchise Implementation

**Document Version:** 1.0.0  
**Last Updated:** 2025-01-21  
**Owner:** QA Expert (qa-expert-931613)  
**Status:** DRAFT — Under Review

---

## 📋 Executive Summary

This QA Test Plan establishes comprehensive quality assurance coverage for the Delta Crown Extensions SharePoint Hub & Spoke implementation across three phases:

| Phase | Focus | Timeline | Risk Level |
|-------|-------|----------|------------|
| **Phase 2** | Infrastructure + Identity | Current | 🔴 HIGH |
| **Phase 3** | Collaboration + SharePoint | Upcoming | 🟠 MEDIUM |
| **Phase 4** | Governance + Go-Live | Future | 🟠 MEDIUM |

**Quality Gates:** All phases require >95% test pass rate, zero critical defects, and full security control validation before proceeding.

---

## 🎯 Test Strategy Overview

### Test Pyramid Distribution

```
                    /\
                   /  \
                  / E2E \      10% - User journey validation
                 /________\        (Hub navigation, cross-brand isolation)
                /          \
               / Integration \  20% - Hub association, Teams integration,
              /______________\      Graph API workflows
             /                \
            /   Unit Tests      \  70% - PowerShell validation, config verification
           /____________________\     (Permission checks, site properties)
```

### Test Categories

| Category | Coverage Target | Automation |
|----------|----------------|------------|
| **Infrastructure** | 100% | ✅ Full |
| **Security** | 100% | ✅ Full |
| **Identity** | 95% | ✅ Full |
| **Authentication** | 100% | ✅ Full |
| **SharePoint Sites** | 90% | ⚠️ Semi-Auto |
| **Teams Integration** | 85% | ⚠️ Semi-Auto |
| **Performance** | 80% | 🔶 Manual |
| **Governance** | 100% | ✅ Full |

---

## 📊 Phase 2: Infrastructure + Identity (IN PROGRESS)

### 2.1 Infrastructure Tests

#### TC-INF-001: Corporate Hub Site Provisioning

| Field | Value |
|-------|-------|
| **Test ID** | TC-INF-001 |
| **Priority** | P0 - Critical |
| **Component** | Corporate Hub |
| **Type** | Automated |

**Objective:** Verify Corporate Shared Services Hub exists and is properly configured.

**Preconditions:**
- PnP.PowerShell module installed (v2.0.0+)
- Admin credentials available
- Tenant: deltacrownext

**Test Steps:**
```powershell
# Step 1: Connect to SharePoint Admin
Connect-PnPOnline -Url "https://deltacrownext-admin.sharepoint.com" -Interactive

# Step 2: Verify Corp Hub exists
$corpHub = Get-PnPTenantSite -Url "https://deltacrownext.sharepoint.com/sites/corp-hub"

# Step 3: Verify properties
$corpHub.Title | Should -Be "Corporate Shared Services"
$corpHub.Template | Should -Be "SITEPAGEPUBLISHING#0"
$corpHub.Status | Should -Be "Active"
```

**Expected Results:**
- ✅ Site exists with correct URL
- ✅ Title matches "Corporate Shared Services"
- ✅ Template is Communication Site (SITEPAGEPUBLISHING#0)
- ✅ Site status is Active

**Pass Criteria:** All assertions pass.

**Failure Action:** Block Phase 2 deployment.

---

#### TC-INF-002: DCE Hub Site Provisioning

| Field | Value |
|-------|-------|
| **Test ID** | TC-INF-002 |
| **Priority** | P0 - Critical |
| **Component** | DCE Hub |

**Objective:** Verify Delta Crown Extensions Hub exists with proper branding.

**Test Steps:**
```powershell
$dceHub = Get-PnPTenantSite -Url "https://deltacrownext.sharepoint.com/sites/dce-hub"
$dceHub.Title | Should -Be "Delta Crown Extensions Hub"
$dceHub.Template | Should -Be "SITEPAGEPUBLISHING#0"
```

**Expected Results:**
- ✅ Site exists
- ✅ Title matches "Delta Crown Extensions Hub"
- ✅ Communication site template applied

---

#### TC-INF-003: Hub Registration Verification

| Field | Value |
|-------|-------|
| **Test ID** | TC-INF-003 |
| **Priority** | P0 - Critical |

**Objective:** Verify both hubs are registered as Hub Sites.

**Test Steps:**
```powershell
# Check Corp Hub registration
$corpHub = Get-PnPHubSite -Identity "https://deltacrownext.sharepoint.com/sites/corp-hub"
$corpHub | Should -Not -Be $null

# Check DCE Hub registration
$dceHub = Get-PnPHubSite -Identity "https://deltacrownext.sharepoint.com/sites/dce-hub"
$dceHub | Should -Not -Be $null
```

**Expected Results:**
- ✅ Corp-Hub is registered as Hub Site
- ✅ DCE-Hub is registered as Hub Site
- ✅ Both have valid Hub Site IDs

---

#### TC-INF-004: Hub-to-Hub Association

| Field | Value |
|-------|-------|
| **Test ID** | TC-INF-004 |
| **Priority** | P0 - Critical |

**Objective:** Verify DCE Hub is linked to Corporate Hub.

**Test Steps:**
```powershell
Connect-PnPOnline -Url "https://deltacrownext.sharepoint.com/sites/dce-hub" -Interactive
$parentHub = Get-PnPHubSiteConnection
$parentHub | Should -Not -Be $null
```

**Expected Results:**
- ✅ DCE Hub has parent hub connection
- ✅ Connection points to Corp Hub

---

#### TC-INF-005: Navigation Configuration

| Field | Value |
|-------|-------|
| **Test ID** | TC-INF-005 |
| **Priority** | P1 - High |

**Objective:** Verify hub navigation nodes are configured.

**Test Steps:**
```powershell
Connect-PnPOnline -Url "https://deltacrownext.sharepoint.com/sites/corp-hub" -Interactive
$navNodes = Get-PnPNavigationNode -Location HubNavigation
$navNodes.Count | Should -BeGreaterThan 0
```

**Expected Results:**
- ✅ At least 3 navigation nodes present
- ✅ Nodes include: Home, HR Resources, IT Support, Finance, Training

---

#### TC-INF-006: Associated Sites Verification

| Field | Value |
|-------|-------|
| **Test ID** | TC-INF-006 |
| **Priority** | P1 - High |

**Objective:** Verify all associated sites exist and are linked to Corp Hub.

**Test Steps:**
```powershell
$associatedSites = @(
    "sites/corp-hr",
    "sites/corp-it",
    "sites/corp-finance",
    "sites/corp-training"
)

foreach ($site in $associatedSites) {
    $siteUrl = "https://deltacrownext.sharepoint.com/$site"
    $tenantSite = Get-PnPTenantSite -Url $siteUrl
    $tenantSite | Should -Not -Be $null
    
    # Check hub association
    Connect-PnPOnline -Url $siteUrl -Interactive
    $hubConnection = Get-PnPHubSiteConnection
    $hubConnection | Should -Not -Be $null
}
```

**Expected Results:**
- ✅ All 4 associated sites exist
- ✅ All sites are associated with Corp Hub

---

#### TC-INF-007: Site Provisioning Polling Validation

| Field | Value |
|-------|-------|
| **Test ID** | TC-INF-007 |
| **Priority** | P2 - Medium |

**Objective:** Verify site provisioning uses polling instead of fixed delays.

**Test Steps:**
```powershell
# Execute provisioning with -Verbose to verify polling
& "..\scripts\2.1-CorpHub-Provisioning.ps1" -Verbose 2>&1 | 
    Select-String -Pattern "Wait-DeltaCrownSiteProvisioned"
```

**Expected Results:**
- ✅ Polling function is called
- ✅ No arbitrary Start-Sleep delays >5 seconds

---

### 2.2 Identity Tests

#### TC-IDT-001: Azure AD Dynamic Groups Exist

| Field | Value |
|-------|-------|
| **Test ID** | TC-IDT-001 |
| **Priority** | P0 - Critical |

**Objective:** Verify required Azure AD dynamic groups are created.

**Test Steps:**
```powershell
Connect-MgGraph -Scopes "Group.Read.All"

$requiredGroups = @("SG-DCE-AllStaff", "SG-DCE-Leadership")
foreach ($groupName in $requiredGroups) {
    $group = Get-MgGroup -Filter "displayName eq '$groupName'"
    $group | Should -Not -Be $null
    $group.GroupTypes | Should -Contain "DynamicMembership"
}
```

**Expected Results:**
- ✅ SG-DCE-AllStaff exists and is dynamic
- ✅ SG-DCE-Leadership exists and is dynamic

---

#### TC-IDT-002: Dynamic Group Membership Rules

| Field | Value |
|-------|-------|
| **Test ID** | TC-IDT-002 |
| **Priority** | P0 - Critical |

**Objective:** Verify dynamic group membership rules are configured correctly.

**Test Steps:**
```powershell
$allStaff = Get-MgGroup -Filter "displayName eq 'SG-DCE-AllStaff'"
$allStaff.MembershipRule | Should -Match "department"
$allStaff.MembershipRuleProcessingState | Should -Be "On"
```

**Expected Results:**
- ✅ SG-DCE-AllStaff has membership rule based on department
- ✅ Processing state is "On"
- ✅ Rule matches "Delta Crown" department

---

#### TC-IDT-003: No Orphaned Groups

| Field | Value |
|-------|-------|
| **Test ID** | TC-IDT-003 |
| **Priority** | P1 - High |

**Objective:** Verify no groups exist without proper membership or purpose.

**Test Steps:**
```powershell
$dceGroups = Get-MgGroup -All | Where-Object { 
    $_.DisplayName -match "DCE|Delta Crown" 
}

foreach ($group in $dceGroups) {
    $members = Get-MgGroupMember -GroupId $group.Id
    # Groups should have members or be dynamic
    ($members.Count -gt 0 -or $group.GroupTypes -contains "DynamicMembership") | 
        Should -Be $true
}
```

**Expected Results:**
- ✅ All DCE-related groups have members or are dynamic
- ✅ No orphaned groups found

---

### 2.3 Security Tests

#### TC-SEC-001: Permission Inheritance Broken

| Field | Value |
|-------|-------|
| **Test ID** | TC-SEC-001 |
| **Priority** | P0 - Critical |
| **Security Control** | Compensating Control #2 |

**Objective:** Verify all brand sites have unique permissions (not inherited).

**Test Steps:**
```powershell
$dceSites = Get-PnPTenantSite | Where-Object { 
    $_.Url -match "dce-" -or $_.Title -match "Delta Crown" 
}

foreach ($site in $dceSites) {
    Connect-PnPOnline -Url $site.Url -Interactive
    $web = Get-PnPWeb
    $web.HasUniqueRoleAssignments | Should -Be $true
}
```

**Expected Results:**
- ✅ All DCE sites have HasUniqueRoleAssignments = $true

**Failure Action:** 🔴 CRITICAL - Block deployment.

---

#### TC-SEC-002: Dangerous Groups Removed

| Field | Value |
|-------|-------|
| **Test ID** | TC-SEC-002 |
| **Priority** | P0 - Critical |

**Objective:** Verify "Everyone" and "All Users" groups are removed.

**Test Steps:**
```powershell
$dangerousPatterns = @("Everyone", "All Users", "All Authenticated Users")

foreach ($site in $dceSites) {
    Connect-PnPOnline -Url $site.Url -Interactive
    $web = Get-PnPWeb
    $assignments = Get-PnPProperty -ClientObject $web -Property RoleAssignments
    
    foreach ($assignment in $assignments) {
        $principal = Get-PnPProperty -ClientObject $assignment -Property Member
        foreach ($pattern in $dangerousPatterns) {
            $principal.Title | Should -Not -Match $pattern
        }
    }
}
```

**Expected Results:**
- ✅ No dangerous groups found on any DCE site

---

#### TC-SEC-003: External Sharing Disabled

| Field | Value |
|-------|-------|
| **Test ID** | TC-SEC-003 |
| **Priority** | P0 - Critical |

**Objective:** Verify external sharing is disabled on all DCE sites.

**Test Steps:**
```powershell
foreach ($site in $dceSites) {
    $siteInfo = Get-PnPTenantSite -Url $site.Url
    $siteInfo.SharingCapability | Should -Be "Disabled"
}
```

**Expected Results:**
- ✅ SharingCapability = "Disabled" for all DCE sites

---

#### TC-SEC-004: Cross-Brand Isolation

| Field | Value |
|-------|-------|
| **Test ID** | TC-SEC-004 |
| **Priority** | P0 - Critical |
| **Security Control** | Compensating Control #6 |

**Objective:** Verify Brand A cannot access Brand B content.

**Test Steps:**
```powershell
# Execute isolation test script
& "..\scripts\security-controls\Test-CrossBrandIsolation.ps1"
```

**Expected Results:**
- ✅ Zero cross-brand search results
- ✅ Zero unauthorized access attempts succeed
- ✅ Zero permission leakage detected

**Pass Criteria:** All isolation tests pass with 0 violations.

---

#### TC-SEC-005: Sensitivity Labels Applied

| Field | Value |
|-------|-------|
| **Test ID** | TC-SEC-005 |
| **Priority** | P1 - High |
| **Security Control** | Compensating Control #3 |

**Objective:** Verify DCE-Internal sensitivity label exists and is configured.

**Test Steps:**
```powershell
# Connect to Compliance Center
Connect-IPPSSession -UserPrincipalName $AdminEmail

$label = Get-Label -Identity "DCE-Internal"
$label | Should -Not -Be $null
$label.EncryptionEnabled | Should -Be $true
```

**Expected Results:**
- ✅ DCE-Internal label exists
- ✅ Encryption is enabled
- ✅ Label auto-applies to DCE sites

---

#### TC-SEC-006: DLP Policies Active

| Field | Value |
|-------|-------|
| **Test ID** | TC-SEC-006 |
| **Priority** | P1 - High |
| **Security Control** | Compensating Control #4 |

**Objective:** Verify DLP policies are configured to prevent cross-brand sharing.

**Test Steps:**
```powershell
$dlpPolicy = Get-DlpCompliancePolicy -Identity "DCE-Data-Protection"
$dlpPolicy | Should -Not -Be $null
$dlpPolicy.Mode | Should -BeIn @("TestWithNotifications", "Enforce")
```

**Expected Results:**
- ✅ DCE-Data-Protection policy exists
- ✅ Policy mode is TestWithNotifications or Enforce

---

### 2.4 Authentication Tests

#### TC-AUTH-001: Service Principal Permissions

| Field | Value |
|-------|-------|
| **Test ID** | TC-AUTH-001 |
| **Priority** | P1 - High |

**Objective:** Verify service principal has correct Graph API permissions.

**Test Steps:**
```powershell
# Check app registration permissions
$app = Get-MgApplication -Filter "displayName eq 'Delta Crown Extensions PnP'"
$requiredPermissions = @(
    "Sites.Read.All",
    "Sites.Manage.All",
    "Group.Read.All",
    "User.Read.All"
)

foreach ($permission in $requiredPermissions) {
    $app.RequiredResourceAccess.ResourceAccess | 
        Where-Object { $_.Type -eq "Role" } |
        Should -Contain $permission
}
```

**Expected Results:**
- ✅ Service principal has required permissions
- ✅ No excessive permissions granted

---

#### TC-AUTH-002: Certificate-Based Authentication

| Field | Value |
|-------|-------|
| **Test ID** | TC-AUTH-002 |
| **Priority** | P1 - High |

**Objective:** Verify certificate-based authentication works.

**Test Steps:**
```powershell
# Import auth module and test cert auth
Import-Module "..\modules\DeltaCrown.Auth.psm1"

$authConfig = @{
    ClientId = $env:DCE_CLIENT_ID
    TenantId = $env:DCE_TENANT_ID
    CertificatePath = $env:DCE_CERT_PATH
    CertificatePassword = $env:DCE_CERT_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
}

# Attempt connection
Connect-DeltaCrownSharePoint -Url "https://deltacrownext-admin.sharepoint.com" `
    -AuthConfig $authConfig
```

**Expected Results:**
- ✅ Certificate-based authentication succeeds
- ✅ No interactive prompts required

---

#### TC-AUTH-003: Token Refresh

| Field | Value |
|-------|-------|
| **Test ID** | TC-AUTH-003 |
| **Priority** | P2 - Medium |

**Objective:** Verify token refresh works automatically.

**Test Steps:**
```powershell
# Connect and wait for token expiration simulation
Connect-PnPOnline -Url $siteUrl -ClientId $clientId `
    -Tenant $tenantId -CertificatePath $certPath

# Verify context is still valid after operations
Start-Sleep -Seconds 5
Get-PnPWeb | Should -Not -Be $null
```

**Expected Results:**
- ✅ Token refreshes automatically
- ✅ Operations continue without re-authentication

---

### 2.5 Compensating Controls Tests

#### TC-CTL-001: Weekly Audit Script

| Field | Value |
|-------|-------|
| **Test ID** | TC-CTL-001 |
| **Priority** | P1 - High |
| **Security Control** | Compensating Control #5 |

**Objective:** Verify weekly permission audit script runs successfully.

**Test Steps:**
```powershell
# Execute weekly audit
$auditResult = & "..\scripts\security-controls\Weekly-Permission-Audit.ps1" -WhatIf

# Verify report generation
Test-Path "..\reports\Permission-Audit-*.html" | Should -Be $true
```

**Expected Results:**
- ✅ Script executes without errors
- ✅ HTML report generated
- ✅ CSV data exported
- ✅ Critical violations identified

---

#### TC-CTL-002: Security Verification Integration

| Field | Value |
|-------|-------|
| **Test ID** | TC-CTL-002 |
| **Priority** | P0 - Critical |

**Objective:** Verify security verification blocks deployment on failures.

**Test Steps:**
```powershell
# Run verification with simulated failure
$verificationResult = & "..\scripts\security-controls\Security-Configuration-Verification.ps1" `
    -FailOnMissingControls

$verificationResult | Should -Be $true
```

**Expected Results:**
- ✅ All 6 compensating controls verified
- ✅ Script returns $true when controls pass
- ✅ Script returns $false (blocks deployment) when controls fail

---

## 📊 Phase 3: Collaboration + SharePoint (UPCOMING)

### 3.1 SharePoint Site Tests

#### TC-SPS-001: Site Creation from Template

| Field | Value |
|-------|-------|
| **Test ID** | TC-SPS-001 |
| **Priority** | P0 - Critical |

**Objective:** Verify sites can be created from PnP templates.

**Test Steps:**
```powershell
# Apply DCE template
Invoke-PnPTenantTemplate -Path "..\templates\DCEHub-Template.json"

# Verify site created
$site = Get-PnPTenantSite -Url "https://deltacrownext.sharepoint.com/sites/dce-test"
$site | Should -Not -Be $null
```

**Expected Results:**
- ✅ Site created from template
- ✅ Template ID matches expected
- ✅ Provisioning completes < 30 minutes

---

#### TC-SPS-002: Lists and Libraries Configuration

| Field | Value |
|-------|-------|
| **Test ID** | TC-SPS-002 |
| **Priority** | P1 - High |

**Test Steps:**
```powershell
Connect-PnPOnline -Url "https://deltacrownext.sharepoint.com/sites/dce-hub" -Interactive

$expectedLists = @("Announcements", "Policies and Procedures", "Resource Library")
foreach ($listName in $expectedLists) {
    $list = Get-PnPList -Identity $listName
    $list | Should -Not -Be $null
}
```

**Expected Results:**
- ✅ All expected lists exist
- ✅ Content types applied correctly
- ✅ Versioning enabled on document libraries

---

#### TC-SPS-003: Content Types Applied

| Field | Value |
|-------|-------|
| **Test ID** | TC-SPS-003 |
| **Priority** | P1 - High |

**Test Steps:**
```powershell
$contentTypes = Get-PnPContentType -List "Policies and Procedures"
$contentTypes | Where-Object { $_.Name -eq "Document" } | Should -Not -Be $null
```

**Expected Results:**
- ✅ Content types published from hub
- ✅ Inheritance works correctly

---

### 3.2 Teams Integration Tests

#### TC-TEA-001: Team Creation with Channels

| Field | Value |
|-------|-------|
| **Test ID** | TC-TEA-001 |
| **Priority** | P0 - Critical |

**Objective:** Verify Teams creation with correct channel structure.

**Test Steps:**
```powershell
Connect-MicrosoftTeams

$team = Get-Team -DisplayName "Delta Crown Operations"
$team | Should -Not -Be $null

$channels = Get-TeamChannel -GroupId $team.GroupId
$expectedChannels = @("General", "Daily Operations", "Client Bookings", "Marketing")

foreach ($channel in $expectedChannels) {
    $channels | Where-Object { $_.DisplayName -eq $channel } | Should -Not -Be $null
}
```

**Expected Results:**
- ✅ Team exists with correct name
- ✅ All expected channels present
- ✅ SharePoint site linked correctly

---

#### TC-TEA-002: SharePoint File Sync

| Field | Value |
|-------|-------|
| **Test ID** | TC-TEA-002 |
| **Priority** | P1 - High |

**Test Steps:**
```powershell
# Verify file sync between Teams and SharePoint
$channel = Get-TeamChannel -GroupId $team.GroupId | 
    Where-Object { $_.DisplayName -eq "General" }

$folder = Get-PnPFolder -Url "$($channel.FolderObjectUrl)"
$folder | Should -Not -Be $null
```

**Expected Results:**
- ✅ Files sync between Teams and SharePoint
- ✅ Folder structure matches

---

#### TC-TEA-003: Private Channel Isolation

| Field | Value |
|-------|-------|
| **Test ID** | TC-TEA-003 |
| **Priority** | P1 - High |

**Test Steps:**
```powershell
$privateChannel = Get-TeamChannel -GroupId $team.GroupId -MembershipType Private
$privateChannel | Should -Not -Be $null

# Verify separate SharePoint site
$privateSite = Get-PnPTenantSite -Url $privateChannel.SharePointSiteUrl
$privateSite | Should -Not -Be $null
```

**Expected Results:**
- ✅ Private channel creates separate SPO site
- ✅ Isolation maintained

---

#### TC-TEA-004: Guest Access Controlled

| Field | Value |
|-------|-------|
| **Test ID** | TC-TEA-004 |
| **Priority** | P0 - Critical |

**Test Steps:**
```powershell
$guestSettings = Get-TeamGuestSettings -GroupId $team.GroupId
$guestSettings.AllowCreateUpdateChannels | Should -Be $false
```

**Expected Results:**
- ✅ Guest access disabled or restricted
- ✅ Cannot create/update channels

---

### 3.3 Template Tests

#### TC-TPL-001: PnP Template Export

| Field | Value |
|-------|-------|
| **Test ID** | TC-TPL-001 |
| **Priority** | P1 - High |

**Objective:** Verify PnP template can be exported from existing site.

**Test Steps:**
```powershell
Get-PnPSiteTemplate -Out "..\templates\Exported-DCE-Template.xml" `
    -ConfigurationExportMode "All"

Test-Path "..\templates\Exported-DCE-Template.xml" | Should -Be $true
```

**Expected Results:**
- ✅ Template exports successfully
- ✅ File size > 10KB (indicates content captured)

---

#### TC-TPL-002: Template Reapplication

| Field | Value |
|-------|-------|
| **Test ID** | TC-TPL-002 |
| **Priority** | P1 - High |

**Objective:** Verify template can be reapplied to new site.

**Test Steps:**
```powershell
# Create test site
New-PnPSite -Type CommunicationSite -Title "Template Test" `
    -Url "https://deltacrownext.sharepoint.com/sites/template-test"

# Apply template
Invoke-PnPSiteTemplate -Path "..\templates\DCEHub-Template.json"

# Verify configuration applied
$nav = Get-PnPNavigationNode -Location HubNavigation
$nav.Count | Should -BeGreaterThan 0
```

**Expected Results:**
- ✅ Template applies without errors
- ✅ Navigation configured correctly
- ✅ Lists/libraries created

---

#### TC-TPL-003: Brand Parameterization

| Field | Value |
|-------|-------|
| **Test ID** | TC-TPL-003 |
| **Priority** | P2 - Medium |

**Objective:** Verify template supports brand-specific variables.

**Test Steps:**
```powershell
# Test with different brand parameters
$parameters = @{
    "BrandName" = "Bishops"
    "BrandCode" = "BSH"
    "PrimaryColor" = "#0066CC"
}

Invoke-PnPSiteTemplate -Path "..\templates\DCEHub-Template.json" `
    -Parameters $parameters
```

**Expected Results:**
- ✅ Template accepts parameters
- ✅ Values substituted correctly
- ✅ Bishops branding applied

---

## 📊 Phase 4: Governance + Go-Live (UPCOMING)

### 4.1 Governance Tests

#### TC-GOV-001: Access Review Process

| Field | Value |
|-------|-------|
| **Test ID** | TC-GOV-001 |
| **Priority** | P1 - High |

**Test Steps:**
```powershell
# Verify quarterly access review documented
Test-Path "..\docs\ACCESS-REVIEW-PROCESS.md" | Should -Be $true

# Check attestation records
$attestations = Get-ChildItem "..\docs\access-attestations" -Filter "*.csv"
$attestations.Count | Should -BeGreaterThan 0
```

---

#### TC-GOV-002: Backup and Recovery

| Field | Value |
|-------|-------|
| **Test ID** | TC-GOV-002 |
| **Priority** | P0 - Critical |

**Test Steps:**
```powershell
# Verify retention policy configured
$retention = Get-PnPRetentionLabel
$retention | Should -Not -Be $null
```

---

### 4.2 Performance Tests

#### TC-PERF-001: Hub Page Load Time

| Field | Value |
|-------|-------|
| **Test ID** | TC-PERF-001 |
| **Priority** | P1 - High |

**Test Steps:**
```powershell
# Measure page load time (requires browser automation)
# Target: < 3 seconds
```

**Pass Criteria:**
- ✅ Page loads < 3 seconds (p95)
- ✅ Time to First Byte < 500ms

---

#### TC-PERF-002: Search Response Time

| Field | Value |
|-------|-------|
| **Test ID** | TC-PERF-002 |
| **Priority** | P1 - High |

**Test Steps:**
```powershell
$start = Get-Date
$results = Submit-PnPSearchQuery -Query "test" -MaxResults 10
$end = Get-Date
($end - $start).TotalSeconds | Should -BeLessThan 2
```

**Pass Criteria:**
- ✅ Search completes < 2 seconds

---

## 🔄 Regression Test Suite

### Automated Regression Tests

| Test ID | Description | Frequency |
|---------|-------------|-----------|
| REG-001 | Full Phase 2 verification | Daily |
| REG-002 | Cross-brand isolation | Daily |
| REG-003 | Permission audit | Weekly |
| REG-004 | Security controls | Weekly |
| REG-005 | Site provisioning | Per deployment |

### Regression Execution

```powershell
# Execute full regression
& "..\scripts\qa\Invoke-RegressionTests.ps1" -Phase 2 -Verbose
```

---

## 📈 Quality Metrics

### Coverage Targets

| Metric | Target | Current |
|--------|--------|---------|
| Unit Test Coverage | >90% | 0% |
| Integration Coverage | >80% | 0% |
| E2E Coverage | >70% | 0% |
| Security Test Coverage | 100% | 0% |

### Defect Metrics

| Metric | Target | Threshold |
|--------|--------|-----------|
| Defect Density | <1/KLOC | <1 |
| Critical Defects (Prod) | 0 | 0 |
| MTTR (P0/P1) | <4 hours | 4h |

### Performance Thresholds

| Metric | Target |
|--------|--------|
| Site Provisioning | <30 minutes |
| Page Load (p95) | <3 seconds |
| Search Response | <2 seconds |
| Hub Sync | <5 minutes |

---

## 🚀 Test Execution

### Daily Execution (Phase 2)

```bash
# Run Phase 2 smoke tests
./tests/qa/Run-Phase2-SmokeTests.ps1

# Run security verification
./phase2-week1/scripts/security-controls/Security-Configuration-Verification.ps1
```

### Pre-Deployment Checklist

- [ ] All P0 tests pass
- [ ] Security controls verified
- [ ] Cross-brand isolation confirmed
- [ ] Performance benchmarks met
- [ ] Documentation updated
- [ ] Rollback plan tested

---

## 📝 Appendix: Test Scripts

### Script Inventory

| Script | Purpose | Location |
|--------|---------|----------|
| `Run-InfrastructureTests.ps1` | Phase 2 infrastructure validation | `tests/qa/` |
| `Run-SecurityTests.ps1` | Security control validation | `tests/qa/` |
| `Run-IdentityTests.ps1` | Azure AD group validation | `tests/qa/` |
| `Run-Phase2-SmokeTests.ps1` | Daily smoke tests | `tests/qa/` |
| `Invoke-RegressionTests.ps1` | Full regression suite | `tests/qa/` |
| `Test-CrossBrandIsolation.ps1` | Security isolation tests | `phase2-week1/scripts/security-controls/` |
| `Weekly-Permission-Audit.ps1` | Permission compliance | `phase2-week1/scripts/security-controls/` |
| `Security-Configuration-Verification.ps1` | Control verification | `phase2-week1/scripts/security-controls/` |

---

## ✅ Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Lead | QA Expert | _____________ | _______ |
| Security Auditor | | _____________ | _______ |
| Solutions Architect | | _____________ | _______ |
| Product Owner | | _____________ | _______ |

---

*This document is a living document. Updates should be tracked in version control.*

**Document Control:**
- Version: 1.0.0
- Author: QA Expert (qa-expert-931613)
- Reviewers: Security Auditor, Solutions Architect
- Approval: Pending
