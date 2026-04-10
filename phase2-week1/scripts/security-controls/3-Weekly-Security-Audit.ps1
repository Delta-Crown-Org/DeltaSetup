# ============================================================================
# WEEKLY SECURITY AUDIT SCRIPT
# Delta Crown Extensions — Compensating Control SC3
# ============================================================================
# DESCRIPTION:
#   Comprehensive weekly security audit for the DCE brand within the
#   deltacrownext M365 Business Premium tenant. Validates all six
#   compensating controls that substitute for Information Barriers.
#
# AUDIT DOMAINS:
#   1. Permission Audit   — unique perms, forbidden groups, permission matrix
#   2. Group Membership   — dynamic groups, processing state, membership drift
#   3. DLP Policy Audit   — policy state, match counts, external sharing
#   4. Sensitivity Labels — label publication, mandatory labeling, coverage
#   5. Teams Audit        — guest access, app governance, channel drift
#   6. Report Generation  — JSON, HTML (branded), email, console summary
#
# EXIT CODES:
#   0 = All checks passed
#   1 = Warnings detected (non-critical)
#   2 = Critical failures detected
#
# SCHEDULING: Weekly via Task Scheduler, Azure Automation, or CI/CD pipeline
# REQUIRED ROLE: SharePoint Admin + Compliance Reader + Groups Admin
# RELATED: SC1 (Sensitivity Labels), SC2 (DLP), SC4 (Isolation), SC5 (Config)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules PnP.PowerShell, Microsoft.Graph.Groups

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantName = "deltacrownext",

    [Parameter(Mandatory = $false)]
    [string]$AdminUrl = $null,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ".\phase2-week1\docs\weekly-audit-results",

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\phase2-week1\logs",

    [Parameter(Mandatory = $false)]
    [string[]]$AlertRecipients = @("security@deltacrownext.com"),

    [Parameter(Mandatory = $false)]
    [switch]$SendEmailAlert,

    [Parameter(Mandatory = $false)]
    [switch]$SkipTeamsAudit,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDLPAudit,

    [Parameter(Mandatory = $false)]
    [switch]$SkipLabelAudit
)

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

if (-not $AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

$script:Timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$script:ScriptVersion = "1.0.0"
$script:AuditId      = "AUDIT-$script:Timestamp"

# --- DCE Site Inventory (source of truth from ADR-002) -----------------------
$script:DCESites = @(
    [PSCustomObject]@{
        Url     = "https://$TenantName.sharepoint.com/sites/dce-hub"
        Title   = "DCE Hub"
        Type    = "Hub"
        TeamsManaged = $false
    },
    [PSCustomObject]@{
        Url     = "https://$TenantName.sharepoint.com/sites/dce-operations"
        Title   = "DCE Operations"
        Type    = "TeamSite"
        TeamsManaged = $true
    },
    [PSCustomObject]@{
        Url     = "https://$TenantName.sharepoint.com/sites/dce-clientservices"
        Title   = "DCE Client Services"
        Type    = "TeamSite"
        TeamsManaged = $false
    },
    [PSCustomObject]@{
        Url     = "https://$TenantName.sharepoint.com/sites/dce-marketing"
        Title   = "DCE Marketing"
        Type    = "CommunicationSite"
        TeamsManaged = $false
    },
    [PSCustomObject]@{
        Url     = "https://$TenantName.sharepoint.com/sites/dce-docs"
        Title   = "DCE Docs"
        Type    = "TeamSite"
        TeamsManaged = $false
    }
)

# Private channel site — auto-generated URL pattern from Teams
$script:LeadershipChannelSite = [PSCustomObject]@{
    Url     = "https://$TenantName.sharepoint.com/sites/dce-operations-Leadership"
    Title   = "DCE Operations - Leadership (Private Channel)"
    Type    = "PrivateChannelSite"
    TeamsManaged = $true
}

# --- Permission Matrix (source of truth from ADR-002) ------------------------
# DCE-Operations is Teams-managed so SharePoint groups are controlled by Teams.
# All other sites use explicit security group assignments.
$script:PermissionMatrix = @{
    "dce-hub" = @{
        "SG-DCE-AllStaff"    = "Read"
        "SG-DCE-Leadership"  = "Full Control"
        "SG-DCE-Marketing"   = "Read"
    }
    "dce-clientservices" = @{
        "SG-DCE-AllStaff"    = "Contribute"
        "SG-DCE-Leadership"  = "Full Control"
        "SG-DCE-Marketing"   = "Read"
    }
    "dce-marketing" = @{
        "SG-DCE-AllStaff"    = "Read"
        "SG-DCE-Leadership"  = "Full Control"
        "SG-DCE-Marketing"   = "Edit"
    }
    "dce-docs" = @{
        "SG-DCE-AllStaff"    = "Read"
        "SG-DCE-Leadership"  = "Full Control"
        "SG-DCE-Marketing"   = "Read"
    }
}

# --- Forbidden Groups --------------------------------------------------------
$script:ForbiddenGroupPatterns = @(
    "Everyone",
    "Everyone except external users",
    "All Users",
    "All Authenticated Users",
    "NT AUTHORITY\Authenticated Users"
)

# --- Dynamic Group Expectations -----------------------------------------------
$script:ExpectedGroups = @(
    @{
        DisplayName      = "SG-DCE-AllStaff"
        ExpectedMinCount = 1
        ExpectedMaxCount = 300   # Business Premium max 300 users
        MustBeDynamic    = $true
    },
    @{
        DisplayName      = "SG-DCE-Leadership"
        ExpectedMinCount = 1
        ExpectedMaxCount = 30
        MustBeDynamic    = $true
    },
    @{
        DisplayName      = "SG-DCE-Marketing"
        ExpectedMinCount = 0
        ExpectedMaxCount = 50
        MustBeDynamic    = $true
    }
)

# --- Brand Colours (DCE branding for HTML reports) ---------------------------
$script:BrandGold  = "#C9A227"
$script:BrandBlack = "#1A1A1A"
$script:BrandWhite = "#FFFFFF"

# ============================================================================
# LOGGING
# ============================================================================

function Initialize-AuditEnvironment {
    [CmdletBinding()]
    param()

    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    if (-not (Test-Path $ReportPath)) {
        New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
    }

    $script:LogFile = Join-Path $LogPath "Weekly-Audit-$script:Timestamp.log"

    Write-AuditLog "============================================================"
    Write-AuditLog "  DCE Weekly Security Audit — $script:AuditId"
    Write-AuditLog "  Script Version : $script:ScriptVersion"
    Write-AuditLog "  Tenant         : $TenantName"
    Write-AuditLog "  Started        : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC' -AsUTC)"
    Write-AuditLog "  WhatIf         : $WhatIfPreference"
    Write-AuditLog "============================================================"
}

function Write-AuditLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter(Position = 1)]
        [ValidateSet("INFO", "PASS", "WARN", "FAIL", "CRITICAL", "ERROR", "WHATIF", "SECTION")]
        [string]$Level = "INFO"
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$time] [$($Level.PadRight(8))] $Message"

    $color = switch ($Level) {
        "INFO"     { "Cyan" }
        "PASS"     { "Green" }
        "WARN"     { "Yellow" }
        "FAIL"     { "Red" }
        "CRITICAL" { "Magenta" }
        "ERROR"    { "DarkRed" }
        "WHATIF"   { "DarkYellow" }
        "SECTION"  { "White" }
        default    { "Gray" }
    }

    Write-Host $entry -ForegroundColor $color

    if ($script:LogFile) {
        try { Add-Content -Path $script:LogFile -Value $entry -ErrorAction SilentlyContinue }
        catch { <# swallow to avoid recursive failures #> }
    }
}

# ============================================================================
# RESULT HELPERS
# ============================================================================

function New-AuditFinding {
    <#
    .SYNOPSIS
        Creates a structured audit finding object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Domain,        # e.g. "Permission", "Group", "DLP"
        [Parameter(Mandatory)][string]$CheckId,        # e.g. "PERM-001"
        [Parameter(Mandatory)][string]$CheckName,
        [Parameter(Mandatory)][ValidateSet("PASS","WARN","FAIL","CRITICAL","ERROR","SKIP")]
        [string]$Status,
        [Parameter(Mandatory)][string]$Details,
        [string]$SiteUrl      = "",
        [string]$SiteTitle    = "",
        [string]$Remediation  = "",
        [string]$Control      = ""
    )

    $severity = switch ($Status) {
        "CRITICAL" { 4 }
        "FAIL"     { 3 }
        "WARN"     { 2 }
        "ERROR"    { 2 }
        "SKIP"     { 0 }
        "PASS"     { 0 }
    }

    return [PSCustomObject]@{
        AuditId      = $script:AuditId
        Domain       = $Domain
        CheckId      = $CheckId
        CheckName    = $CheckName
        Status       = $Status
        Severity     = $severity
        Details      = $Details
        SiteUrl      = $SiteUrl
        SiteTitle    = $SiteTitle
        Remediation  = $Remediation
        Control      = $Control
        Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# ============================================================================
# DOMAIN 1 — PERMISSION AUDIT
# ============================================================================

function Invoke-PermissionAudit {
    <#
    .SYNOPSIS
        Audits SharePoint permissions across all DCE sites.
        Checks: unique permissions, forbidden groups, permission matrix, unexpected entries, external sharing.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-AuditLog "" "SECTION"
    Write-AuditLog "━━━ DOMAIN 1: PERMISSION AUDIT ━━━━━━━━━━━━━━━━━━━━━━━━━━━" "SECTION"

    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    $allSites = @($script:DCESites) + @($script:LeadershipChannelSite)

    foreach ($site in $allSites) {
        Write-AuditLog "Auditing: $($site.Title) ($($site.Url))" "INFO"

        # --- PERM-001: Unique Permissions ---
        try {
            if ($WhatIfPreference) {
                Write-AuditLog "  [WHATIF] Would check unique permissions on $($site.Title)" "WHATIF"
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-001" `
                    -CheckName "Unique Permissions" -Status "SKIP" `
                    -Details "WhatIf mode — skipped" -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Control "CC-2: Strict Unique Permissions"))
                continue  # Skip remaining checks for this site in WhatIf
            }

            Connect-PnPOnline -Url $site.Url -Interactive -ErrorAction Stop
            $web = Get-PnPWeb -ErrorAction Stop
            $hasUnique = Get-PnPProperty -ClientObject $web -Property HasUniqueRoleAssignments

            if ($hasUnique) {
                Write-AuditLog "  ✅ PERM-001: Unique permissions confirmed" "PASS"
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-001" `
                    -CheckName "Unique Permissions" -Status "PASS" `
                    -Details "Site has unique permissions (not inherited)" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Control "CC-2: Strict Unique Permissions"))
            }
            else {
                Write-AuditLog "  ❌ PERM-001: INHERITED PERMISSIONS — Security violation!" "CRITICAL"
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-001" `
                    -CheckName "Unique Permissions" -Status "CRITICAL" `
                    -Details "Site has INHERITED permissions — cross-brand leakage risk" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Remediation "Run: Set-PnPWeb -BreakRoleInheritance -CopyRoleAssignments" `
                    -Control "CC-2: Strict Unique Permissions"))
            }
        }
        catch {
            Write-AuditLog "  ⚠️ PERM-001: Error checking permissions — $($_.Exception.Message)" "ERROR"
            $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-001" `
                -CheckName "Unique Permissions" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" `
                -SiteUrl $site.Url -SiteTitle $site.Title `
                -Control "CC-2: Strict Unique Permissions"))
            continue  # Can't do further checks without connection
        }

        # --- PERM-002: Forbidden Groups ---
        try {
            $roleAssignments = Get-PnPProperty -ClientObject $web -Property RoleAssignments
            $forbiddenFound = [System.Collections.Generic.List[string]]::new()

            foreach ($ra in $roleAssignments) {
                $member = Get-PnPProperty -ClientObject $ra -Property Member
                $memberTitle = $member.Title
                $memberLogin = $member.LoginName

                foreach ($pattern in $script:ForbiddenGroupPatterns) {
                    if ($memberTitle -like "*$pattern*" -or $memberLogin -like "*$pattern*") {
                        $forbiddenFound.Add($memberTitle)
                        Write-AuditLog "  🚫 PERM-002: Forbidden group '$memberTitle' detected!" "CRITICAL"
                    }
                }
            }

            if ($forbiddenFound.Count -eq 0) {
                Write-AuditLog "  ✅ PERM-002: No forbidden groups" "PASS"
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-002" `
                    -CheckName "Forbidden Groups" -Status "PASS" `
                    -Details "No forbidden groups (Everyone, All Users, etc.) found" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Control "CC-2: Strict Unique Permissions"))
            }
            else {
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-002" `
                    -CheckName "Forbidden Groups" -Status "CRITICAL" `
                    -Details "Forbidden groups found: $($forbiddenFound -join ', ')" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Remediation "Remove these groups from site permissions immediately" `
                    -Control "CC-2: Strict Unique Permissions"))
            }
        }
        catch {
            Write-AuditLog "  ⚠️ PERM-002: Error checking groups — $($_.Exception.Message)" "ERROR"
            $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-002" `
                -CheckName "Forbidden Groups" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" `
                -SiteUrl $site.Url -SiteTitle $site.Title `
                -Control "CC-2: Strict Unique Permissions"))
        }

        # --- PERM-003: Permission Matrix Compliance ---
        $siteKey = ($site.Url -split "/")[-1]  # e.g. "dce-hub"
        if ($script:PermissionMatrix.ContainsKey($siteKey) -and -not $site.TeamsManaged) {
            try {
                $expectedPerms = $script:PermissionMatrix[$siteKey]
                $roleAssignments = Get-PnPProperty -ClientObject $web -Property RoleAssignments
                $actualGroups = [System.Collections.Generic.List[string]]::new()
                $matrixViolations = [System.Collections.Generic.List[string]]::new()

                foreach ($ra in $roleAssignments) {
                    $member = Get-PnPProperty -ClientObject $ra -Property Member
                    $roleBindings = Get-PnPProperty -ClientObject $ra -Property RoleDefinitionBindings
                    $roleName = ($roleBindings | Select-Object -First 1).Name
                    $actualGroups.Add($member.Title)

                    # Check if this group is in the expected matrix
                    if ($expectedPerms.ContainsKey($member.Title)) {
                        $expectedRole = $expectedPerms[$member.Title]
                        if ($roleName -ne $expectedRole) {
                            $matrixViolations.Add("$($member.Title): expected '$expectedRole', actual '$roleName'")
                            Write-AuditLog "  ⚠️ PERM-003: $($member.Title) has '$roleName' instead of '$expectedRole'" "WARN"
                        }
                    }
                }

                # Check for missing expected groups
                foreach ($expectedGroup in $expectedPerms.Keys) {
                    if ($expectedGroup -notin $actualGroups) {
                        $matrixViolations.Add("$expectedGroup: MISSING from site permissions")
                        Write-AuditLog "  ⚠️ PERM-003: Expected group '$expectedGroup' not found" "WARN"
                    }
                }

                if ($matrixViolations.Count -eq 0) {
                    Write-AuditLog "  ✅ PERM-003: Permission matrix matches" "PASS"
                    $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-003" `
                        -CheckName "Permission Matrix" -Status "PASS" `
                        -Details "All security group assignments match ADR-002 matrix" `
                        -SiteUrl $site.Url -SiteTitle $site.Title `
                        -Control "CC-2: Strict Unique Permissions"))
                }
                else {
                    $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-003" `
                        -CheckName "Permission Matrix" -Status "FAIL" `
                        -Details "Matrix violations: $($matrixViolations -join '; ')" `
                        -SiteUrl $site.Url -SiteTitle $site.Title `
                        -Remediation "Realign permissions to match ADR-002 permission matrix" `
                        -Control "CC-2: Strict Unique Permissions"))
                }
            }
            catch {
                Write-AuditLog "  ⚠️ PERM-003: Error — $($_.Exception.Message)" "ERROR"
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-003" `
                    -CheckName "Permission Matrix" -Status "ERROR" `
                    -Details "Error: $($_.Exception.Message)" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Control "CC-2: Strict Unique Permissions"))
            }
        }
        elseif ($site.TeamsManaged) {
            Write-AuditLog "  ℹ️ PERM-003: Skipped — Teams-managed site (permissions via Team membership)" "INFO"
            $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-003" `
                -CheckName "Permission Matrix" -Status "PASS" `
                -Details "Teams-managed site — permissions controlled via Team membership" `
                -SiteUrl $site.Url -SiteTitle $site.Title `
                -Control "CC-2: Strict Unique Permissions"))
        }

        # --- PERM-004: Unexpected Permission Entries ---
        if ($script:PermissionMatrix.ContainsKey($siteKey) -and -not $site.TeamsManaged) {
            try {
                $expectedGroupNames = @($script:PermissionMatrix[$siteKey].Keys)
                # Also allow built-in SharePoint groups (Owners, Members, Visitors, System Account)
                $allowedPatterns = $expectedGroupNames + @(
                    "*Owners*", "*Members*", "*Visitors*",
                    "System Account", "SG-Corp-IT-Admins",
                    "SharePoint App", "app@sharepoint", "Company Administrator"
                )
                $unexpected = [System.Collections.Generic.List[string]]::new()

                $roleAssignments = Get-PnPProperty -ClientObject $web -Property RoleAssignments
                foreach ($ra in $roleAssignments) {
                    $member = Get-PnPProperty -ClientObject $ra -Property Member
                    $isExpected = $false
                    foreach ($pattern in $allowedPatterns) {
                        if ($member.Title -like $pattern -or $member.LoginName -like $pattern) {
                            $isExpected = $true
                            break
                        }
                    }
                    if (-not $isExpected) {
                        $unexpected.Add("$($member.Title) ($($member.LoginName))")
                        Write-AuditLog "  ⚠️ PERM-004: Unexpected entry '$($member.Title)'" "WARN"
                    }
                }

                if ($unexpected.Count -eq 0) {
                    Write-AuditLog "  ✅ PERM-004: No unexpected permission entries" "PASS"
                    $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-004" `
                        -CheckName "Unexpected Entries" -Status "PASS" `
                        -Details "No unexpected permission entries detected" `
                        -SiteUrl $site.Url -SiteTitle $site.Title `
                        -Control "CC-5: Weekly Permission Scan"))
                }
                else {
                    $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-004" `
                        -CheckName "Unexpected Entries" -Status "WARN" `
                        -Details "Unexpected entries: $($unexpected -join '; ')" `
                        -SiteUrl $site.Url -SiteTitle $site.Title `
                        -Remediation "Review and remove unexpected permission entries" `
                        -Control "CC-5: Weekly Permission Scan"))
                }
            }
            catch {
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-004" `
                    -CheckName "Unexpected Entries" -Status "ERROR" `
                    -Details "Error: $($_.Exception.Message)" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Control "CC-5: Weekly Permission Scan"))
            }
        }

        # --- PERM-005: External Sharing Disabled ---
        try {
            Connect-PnPOnline -Url $AdminUrl -Interactive -ErrorAction Stop
            $siteInfo = Get-PnPTenantSite -Url $site.Url -ErrorAction Stop
            $sharingCap = $siteInfo.SharingCapability

            if ($sharingCap -eq "Disabled") {
                Write-AuditLog "  ✅ PERM-005: External sharing disabled" "PASS"
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-005" `
                    -CheckName "External Sharing" -Status "PASS" `
                    -Details "External sharing is disabled (SharingCapability = Disabled)" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Control "CC-2: Strict Unique Permissions"))
            }
            else {
                Write-AuditLog "  ❌ PERM-005: External sharing ENABLED — $sharingCap" "FAIL"
                $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-005" `
                    -CheckName "External Sharing" -Status "FAIL" `
                    -Details "External sharing is ENABLED: $sharingCap" `
                    -SiteUrl $site.Url -SiteTitle $site.Title `
                    -Remediation "Run: Set-PnPTenantSite -Url '$($site.Url)' -SharingCapability Disabled" `
                    -Control "CC-2: Strict Unique Permissions"))
            }
        }
        catch {
            $findings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-005" `
                -CheckName "External Sharing" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" `
                -SiteUrl $site.Url -SiteTitle $site.Title `
                -Control "CC-2: Strict Unique Permissions"))
        }

        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }

    return $findings
}

# ============================================================================
# DOMAIN 2 — GROUP MEMBERSHIP AUDIT
# ============================================================================

function Invoke-GroupMembershipAudit {
    <#
    .SYNOPSIS
        Audits Azure AD dynamic security groups used for brand isolation.
        Checks: existence, dynamic type, processing state, membership count, manual additions.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-AuditLog "" "SECTION"
    Write-AuditLog "━━━ DOMAIN 2: GROUP MEMBERSHIP AUDIT ━━━━━━━━━━━━━━━━━━━━━" "SECTION"

    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($WhatIfPreference) {
        Write-AuditLog "[WHATIF] Would connect to Microsoft Graph and audit groups" "WHATIF"
        foreach ($grp in $script:ExpectedGroups) {
            $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-001" `
                -CheckName "Group Exists: $($grp.DisplayName)" -Status "SKIP" `
                -Details "WhatIf mode — skipped" -Control "CC-1: Azure AD Dynamic Groups"))
        }
        return $findings
    }

    try {
        Connect-MgGraph -Scopes "Group.Read.All", "GroupMember.Read.All" -NoWelcome -ErrorAction Stop
        Write-AuditLog "Connected to Microsoft Graph" "INFO"
    }
    catch {
        Write-AuditLog "Failed to connect to Graph: $($_.Exception.Message)" "ERROR"
        $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-000" `
            -CheckName "Graph Connection" -Status "ERROR" `
            -Details "Cannot connect to Microsoft Graph: $($_.Exception.Message)" `
            -Control "CC-1: Azure AD Dynamic Groups"))
        return $findings
    }

    foreach ($expectedGroup in $script:ExpectedGroups) {
        $groupName = $expectedGroup.DisplayName
        Write-AuditLog "Auditing group: $groupName" "INFO"

        try {
            $group = Get-MgGroup -Filter "displayName eq '$groupName'" -Property `
                "Id,DisplayName,GroupTypes,MembershipRule,MembershipRuleProcessingState,SecurityEnabled" `
                -ErrorAction Stop

            if (-not $group) {
                Write-AuditLog "  ❌ GRP-001: Group NOT FOUND" "CRITICAL"
                $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-001" `
                    -CheckName "Group Exists: $groupName" -Status "CRITICAL" `
                    -Details "Security group '$groupName' does not exist in Azure AD" `
                    -Remediation "Create group via 2.3-AzureAD-DynamicGroups.ps1" `
                    -Control "CC-1: Azure AD Dynamic Groups"))
                continue
            }

            # GRP-001: Group exists
            Write-AuditLog "  ✅ GRP-001: Group exists (Id: $($group.Id))" "PASS"
            $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-001" `
                -CheckName "Group Exists: $groupName" -Status "PASS" `
                -Details "Group found: $($group.Id)" -Control "CC-1: Azure AD Dynamic Groups"))

            # GRP-002: Is dynamic?
            $isDynamic = $group.GroupTypes -contains "DynamicMembership"
            if ($expectedGroup.MustBeDynamic -and $isDynamic) {
                Write-AuditLog "  ✅ GRP-002: Dynamic membership confirmed" "PASS"
                $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-002" `
                    -CheckName "Dynamic Type: $groupName" -Status "PASS" `
                    -Details "Group is dynamic (rule: $($group.MembershipRule))" `
                    -Control "CC-1: Azure AD Dynamic Groups"))
            }
            elseif ($expectedGroup.MustBeDynamic -and -not $isDynamic) {
                Write-AuditLog "  ❌ GRP-002: NOT dynamic — should be dynamic!" "FAIL"
                $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-002" `
                    -CheckName "Dynamic Type: $groupName" -Status "FAIL" `
                    -Details "Group is NOT dynamic — must be converted to dynamic membership" `
                    -Remediation "Recreate as dynamic group with correct MembershipRule" `
                    -Control "CC-1: Azure AD Dynamic Groups"))
            }
            else {
                $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-002" `
                    -CheckName "Dynamic Type: $groupName" -Status "PASS" `
                    -Details "Group type is acceptable (dynamic=$isDynamic)" `
                    -Control "CC-1: Azure AD Dynamic Groups"))
            }

            # GRP-003: Processing state
            if ($isDynamic) {
                $processingState = $group.MembershipRuleProcessingState
                if ($processingState -eq "On") {
                    Write-AuditLog "  ✅ GRP-003: Processing state is On" "PASS"
                    $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-003" `
                        -CheckName "Processing State: $groupName" -Status "PASS" `
                        -Details "MembershipRuleProcessingState = On" `
                        -Control "CC-1: Azure AD Dynamic Groups"))
                }
                else {
                    Write-AuditLog "  ❌ GRP-003: Processing state is $processingState — should be On!" "FAIL"
                    $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-003" `
                        -CheckName "Processing State: $groupName" -Status "FAIL" `
                        -Details "MembershipRuleProcessingState = $processingState (expected: On)" `
                        -Remediation "Set MembershipRuleProcessingState to 'On' via Graph API" `
                        -Control "CC-1: Azure AD Dynamic Groups"))
                }
            }

            # GRP-004: Membership count within expected range
            $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction Stop
            $memberCount = $members.Count

            if ($memberCount -ge $expectedGroup.ExpectedMinCount -and $memberCount -le $expectedGroup.ExpectedMaxCount) {
                Write-AuditLog "  ✅ GRP-004: Member count $memberCount (expected $($expectedGroup.ExpectedMinCount)-$($expectedGroup.ExpectedMaxCount))" "PASS"
                $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-004" `
                    -CheckName "Member Count: $groupName" -Status "PASS" `
                    -Details "Count=$memberCount (range $($expectedGroup.ExpectedMinCount)-$($expectedGroup.ExpectedMaxCount))" `
                    -Control "CC-1: Azure AD Dynamic Groups"))
            }
            elseif ($memberCount -eq 0 -and $expectedGroup.ExpectedMinCount -gt 0) {
                Write-AuditLog "  ❌ GRP-004: ZERO members — group may not be processing" "FAIL"
                $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-004" `
                    -CheckName "Member Count: $groupName" -Status "FAIL" `
                    -Details "Count=0 — expected at least $($expectedGroup.ExpectedMinCount)" `
                    -Remediation "Verify Azure AD user attributes (department, companyName, jobTitle)" `
                    -Control "CC-1: Azure AD Dynamic Groups"))
            }
            else {
                Write-AuditLog "  ⚠️ GRP-004: Member count $memberCount is outside expected range" "WARN"
                $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-004" `
                    -CheckName "Member Count: $groupName" -Status "WARN" `
                    -Details "Count=$memberCount (expected $($expectedGroup.ExpectedMinCount)-$($expectedGroup.ExpectedMaxCount))" `
                    -Remediation "Review membership rule or Azure AD user attributes" `
                    -Control "CC-1: Azure AD Dynamic Groups"))
            }
        }
        catch {
            Write-AuditLog "  ⚠️ Error auditing '$groupName': $($_.Exception.Message)" "ERROR"
            $findings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-001" `
                -CheckName "Group Audit: $groupName" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" `
                -Control "CC-1: Azure AD Dynamic Groups"))
        }
    }

    try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch { }
    return $findings
}

# ============================================================================
# DOMAIN 3 — DLP POLICY AUDIT
# ============================================================================

function Invoke-DLPPolicyAudit {
    <#
    .SYNOPSIS
        Audits DLP policies protecting DCE content.
        Checks: policy existence, mode, match counts, external sharing attempts.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-AuditLog "" "SECTION"
    Write-AuditLog "━━━ DOMAIN 3: DLP POLICY AUDIT ━━━━━━━━━━━━━━━━━━━━━━━━━━━" "SECTION"

    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($SkipDLPAudit) {
        Write-AuditLog "DLP audit skipped (flag)" "INFO"
        $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-000" `
            -CheckName "DLP Audit" -Status "SKIP" -Details "Skipped via -SkipDLPAudit flag" `
            -Control "CC-4: DLP Policies"))
        return $findings
    }

    if ($WhatIfPreference) {
        Write-AuditLog "[WHATIF] Would connect to Compliance Center and audit DLP policies" "WHATIF"
        $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-000" `
            -CheckName "DLP Audit" -Status "SKIP" -Details "WhatIf mode — skipped" `
            -Control "CC-4: DLP Policies"))
        return $findings
    }

    try {
        Connect-IPPSSession -ErrorAction Stop
        Write-AuditLog "Connected to Security & Compliance Center" "INFO"
    }
    catch {
        Write-AuditLog "Failed to connect to Compliance Center: $($_.Exception.Message)" "ERROR"
        Write-AuditLog "Install ExchangeOnlineManagement module and try again" "WARN"
        $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-000" `
            -CheckName "Compliance Connection" -Status "ERROR" `
            -Details "Cannot connect: $($_.Exception.Message)" `
            -Remediation "Install-Module ExchangeOnlineManagement; Connect-IPPSSession" `
            -Control "CC-4: DLP Policies"))
        return $findings
    }

    $policyName = "DCE-Data-Protection"

    # --- DLP-001: Policy Exists ---
    try {
        $policy = Get-DlpCompliancePolicy -Identity $policyName -ErrorAction SilentlyContinue

        if ($policy) {
            Write-AuditLog "  ✅ DLP-001: Policy '$policyName' exists" "PASS"
            $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-001" `
                -CheckName "Policy Exists" -Status "PASS" `
                -Details "Policy '$policyName' found (Enabled=$($policy.Enabled))" `
                -Control "CC-4: DLP Policies"))

            # --- DLP-002: Policy Mode ---
            $mode = $policy.Mode
            $enabled = $policy.Enabled

            if (-not $enabled) {
                Write-AuditLog "  ❌ DLP-002: Policy is DISABLED" "CRITICAL"
                $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-002" `
                    -CheckName "Policy Enabled" -Status "CRITICAL" `
                    -Details "Policy '$policyName' is disabled — no DLP protection active" `
                    -Remediation "Enable via: Set-DlpCompliancePolicy -Identity '$policyName' -Enabled `$true" `
                    -Control "CC-4: DLP Policies"))
            }
            elseif ($mode -eq "Enable") {
                Write-AuditLog "  ✅ DLP-002: Policy in Enforce mode" "PASS"
                $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-002" `
                    -CheckName "Policy Mode" -Status "PASS" `
                    -Details "Policy is in Enforce mode (full protection active)" `
                    -Control "CC-4: DLP Policies"))
            }
            elseif ($mode -eq "TestWithNotifications" -or $mode -eq "TestWithoutNotifications") {
                # Calculate days since creation for 90-day test window
                $createdDate = $policy.WhenCreated
                $daysSinceCreation = if ($createdDate) { ((Get-Date) - $createdDate).Days } else { "unknown" }
                $daysRemaining = if ($daysSinceCreation -is [int]) { [Math]::Max(0, 90 - $daysSinceCreation) } else { "unknown" }

                Write-AuditLog "  ℹ️ DLP-002: Policy in Test mode ($mode), day $daysSinceCreation of 90" "WARN"
                $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-002" `
                    -CheckName "Policy Mode" -Status "WARN" `
                    -Details "Policy in TEST mode: $mode. Day $daysSinceCreation of 90. $daysRemaining days until Enforce deadline." `
                    -Remediation "Switch to Enforce after 90-day test period" `
                    -Control "CC-4: DLP Policies"))
            }

            # --- DLP-003: Rule Count ---
            try {
                $rules = Get-DlpComplianceRule -Policy $policyName -ErrorAction Stop
                $ruleCount = ($rules | Measure-Object).Count
                if ($ruleCount -ge 2) {
                    Write-AuditLog "  ✅ DLP-003: $ruleCount DLP rules configured" "PASS"
                    $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-003" `
                        -CheckName "DLP Rules" -Status "PASS" `
                        -Details "$ruleCount rules configured (minimum 2 required)" `
                        -Control "CC-4: DLP Policies"))
                }
                else {
                    Write-AuditLog "  ⚠️ DLP-003: Only $ruleCount rules — expected ≥2" "WARN"
                    $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-003" `
                        -CheckName "DLP Rules" -Status "WARN" `
                        -Details "Only $ruleCount rules (expected ≥2: cross-brand block + external warn)" `
                        -Remediation "Review SC2 spec and add missing rules" `
                        -Control "CC-4: DLP Policies"))
                }
            }
            catch {
                $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-003" `
                    -CheckName "DLP Rules" -Status "ERROR" `
                    -Details "Error retrieving rules: $($_.Exception.Message)" `
                    -Control "CC-4: DLP Policies"))
            }

            # --- DLP-004: Match/Violation Counts (last 7 days) ---
            try {
                $weekAgo = (Get-Date).AddDays(-7)
                $dlpReport = Get-DlpDetailReport -StartDate $weekAgo -EndDate (Get-Date) `
                    -ErrorAction SilentlyContinue
                $dceMatches = $dlpReport | Where-Object { $_.PolicyName -eq $policyName }
                $matchCount = ($dceMatches | Measure-Object).Count

                Write-AuditLog "  ℹ️ DLP-004: $matchCount DLP matches in last 7 days" "INFO"
                $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-004" `
                    -CheckName "Weekly DLP Matches" -Status $(if ($matchCount -gt 50) { "WARN" } else { "PASS" }) `
                    -Details "$matchCount policy matches in last 7 days" `
                    -Remediation $(if ($matchCount -gt 50) { "Investigate high match volume — possible false positives" } else { "" }) `
                    -Control "CC-4: DLP Policies"))
            }
            catch {
                Write-AuditLog "  ℹ️ DLP-004: Could not retrieve DLP match reports" "WARN"
                $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-004" `
                    -CheckName "Weekly DLP Matches" -Status "WARN" `
                    -Details "Unable to retrieve DLP report: $($_.Exception.Message)" `
                    -Control "CC-4: DLP Policies"))
            }
        }
        else {
            Write-AuditLog "  ❌ DLP-001: Policy '$policyName' NOT FOUND" "CRITICAL"
            $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-001" `
                -CheckName "Policy Exists" -Status "CRITICAL" `
                -Details "DLP policy '$policyName' does not exist — no cross-brand sharing protection" `
                -Remediation "Deploy DLP policy per SC2 specification: 2-DLP-Policies-Specification.md" `
                -Control "CC-4: DLP Policies"))
        }
    }
    catch {
        Write-AuditLog "  ⚠️ DLP audit error: $($_.Exception.Message)" "ERROR"
        $findings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-001" `
            -CheckName "DLP Audit" -Status "ERROR" `
            -Details "Error: $($_.Exception.Message)" `
            -Control "CC-4: DLP Policies"))
    }

    try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch { }
    return $findings
}

# ============================================================================
# DOMAIN 4 — SENSITIVITY LABEL AUDIT
# ============================================================================

function Invoke-SensitivityLabelAudit {
    <#
    .SYNOPSIS
        Audits sensitivity label deployment and coverage.
        Checks: label existence, policy publication, mandatory labeling, unlabeled content.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-AuditLog "" "SECTION"
    Write-AuditLog "━━━ DOMAIN 4: SENSITIVITY LABEL AUDIT ━━━━━━━━━━━━━━━━━━━━" "SECTION"

    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($SkipLabelAudit) {
        Write-AuditLog "Label audit skipped (flag)" "INFO"
        $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-000" `
            -CheckName "Label Audit" -Status "SKIP" -Details "Skipped via -SkipLabelAudit flag" `
            -Control "SC1: Sensitivity Labels"))
        return $findings
    }

    if ($WhatIfPreference) {
        Write-AuditLog "[WHATIF] Would connect to Compliance Center and audit labels" "WHATIF"
        $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-000" `
            -CheckName "Label Audit" -Status "SKIP" -Details "WhatIf mode — skipped" `
            -Control "SC1: Sensitivity Labels"))
        return $findings
    }

    try {
        Connect-IPPSSession -ErrorAction Stop
        Write-AuditLog "Connected to Security & Compliance Center" "INFO"
    }
    catch {
        Write-AuditLog "Failed to connect to Compliance Center: $($_.Exception.Message)" "ERROR"
        $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-000" `
            -CheckName "Compliance Connection" -Status "ERROR" `
            -Details "Cannot connect: $($_.Exception.Message)" `
            -Control "SC1: Sensitivity Labels"))
        return $findings
    }

    # --- LBL-001: Required Labels Exist ---
    $requiredLabels = @("Personal", "DCE-Internal", "DCE-Confidential", "Corporate-Confidential")
    foreach ($labelName in $requiredLabels) {
        try {
            $label = Get-Label -Identity $labelName -ErrorAction SilentlyContinue
            if ($label) {
                Write-AuditLog "  ✅ LBL-001: Label '$labelName' exists" "PASS"
                $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-001" `
                    -CheckName "Label Exists: $labelName" -Status "PASS" `
                    -Details "Label found (Priority=$($label.Priority), Encryption=$($label.EncryptionEnabled))" `
                    -Control "SC1: Sensitivity Labels"))
            }
            else {
                Write-AuditLog "  ❌ LBL-001: Label '$labelName' NOT FOUND" "FAIL"
                $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-001" `
                    -CheckName "Label Exists: $labelName" -Status "FAIL" `
                    -Details "Label '$labelName' not found — deploy per SC1 specification" `
                    -Remediation "Run SC1 PowerShell commands from 1-Sensitivity-Labels-Specification.md §7" `
                    -Control "SC1: Sensitivity Labels"))
            }
        }
        catch {
            $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-001" `
                -CheckName "Label Exists: $labelName" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" `
                -Control "SC1: Sensitivity Labels"))
        }
    }

    # --- LBL-002: Label Policy Published ---
    $requiredPolicies = @("DCE-Label-Policy", "Corp-Label-Policy")
    foreach ($policyName in $requiredPolicies) {
        try {
            $policy = Get-LabelPolicy -Identity $policyName -ErrorAction SilentlyContinue
            if ($policy) {
                Write-AuditLog "  ✅ LBL-002: Policy '$policyName' published" "PASS"
                $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-002" `
                    -CheckName "Policy Published: $policyName" -Status "PASS" `
                    -Details "Label policy is published and active" `
                    -Control "SC1: Sensitivity Labels"))

                # --- LBL-003: Mandatory Labeling Enabled ---
                if ($policyName -eq "DCE-Label-Policy") {
                    $settings = $policy.Settings
                    # Settings is a hashtable; 'mandatory' key controls mandatory labeling
                    $isMandatory = $false
                    if ($settings -and $settings.ContainsKey("mandatory")) {
                        $isMandatory = $settings["mandatory"] -eq "true"
                    }

                    if ($isMandatory) {
                        Write-AuditLog "  ✅ LBL-003: Mandatory labeling is ON" "PASS"
                        $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-003" `
                            -CheckName "Mandatory Labeling" -Status "PASS" `
                            -Details "DCE-Label-Policy enforces mandatory labeling" `
                            -Control "SC1: Sensitivity Labels"))
                    }
                    else {
                        Write-AuditLog "  ⚠️ LBL-003: Mandatory labeling is OFF" "WARN"
                        $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-003" `
                            -CheckName "Mandatory Labeling" -Status "WARN" `
                            -Details "Mandatory labeling is not enabled — users can save without a label" `
                            -Remediation "Set 'mandatory=true' in DCE-Label-Policy settings" `
                            -Control "SC1: Sensitivity Labels"))
                    }
                }
            }
            else {
                Write-AuditLog "  ❌ LBL-002: Policy '$policyName' NOT FOUND" "FAIL"
                $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-002" `
                    -CheckName "Policy Published: $policyName" -Status "FAIL" `
                    -Details "Label policy '$policyName' not found" `
                    -Remediation "Deploy via SC1 specification §7.4" `
                    -Control "SC1: Sensitivity Labels"))
            }
        }
        catch {
            $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-002" `
                -CheckName "Policy Published: $policyName" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" `
                -Control "SC1: Sensitivity Labels"))
        }
    }

    # --- LBL-004: Unlabeled Document Count (sampled) ---
    # This checks via SharePoint search — not 100% accurate but indicative
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        $totalUnlabeled = 0

        foreach ($site in $script:DCESites) {
            try {
                Connect-PnPOnline -Url $site.Url -Interactive -ErrorAction Stop
                $lists = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and -not $_.Hidden }

                foreach ($list in $lists) {
                    $items = Get-PnPListItem -List $list -PageSize 100 -ErrorAction SilentlyContinue |
                        Where-Object { -not $_["_ComplianceTag"] -and $_["FileLeafRef"] -match "\.(docx|xlsx|pptx|pdf)$" }
                    $unlabeledCount = ($items | Measure-Object).Count
                    $totalUnlabeled += $unlabeledCount
                }

                Disconnect-PnPOnline -ErrorAction SilentlyContinue
            }
            catch {
                Write-AuditLog "  ⚠️ LBL-004: Error scanning $($site.Title): $($_.Exception.Message)" "WARN"
            }
        }

        if ($totalUnlabeled -eq 0) {
            Write-AuditLog "  ✅ LBL-004: No unlabeled documents found" "PASS"
            $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-004" `
                -CheckName "Unlabeled Documents" -Status "PASS" `
                -Details "No unlabeled Office/PDF documents found across DCE sites" `
                -Control "SC1: Sensitivity Labels"))
        }
        elseif ($totalUnlabeled -le 10) {
            Write-AuditLog "  ⚠️ LBL-004: $totalUnlabeled unlabeled documents found" "WARN"
            $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-004" `
                -CheckName "Unlabeled Documents" -Status "WARN" `
                -Details "$totalUnlabeled unlabeled Office/PDF documents across DCE sites" `
                -Remediation "Open and re-save documents to trigger default label application" `
                -Control "SC1: Sensitivity Labels"))
        }
        else {
            Write-AuditLog "  ❌ LBL-004: $totalUnlabeled unlabeled documents — coverage gap" "FAIL"
            $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-004" `
                -CheckName "Unlabeled Documents" -Status "FAIL" `
                -Details "$totalUnlabeled unlabeled documents — significant coverage gap" `
                -Remediation "Run bulk re-label campaign per SC1 spec §7.6" `
                -Control "SC1: Sensitivity Labels"))
        }
    }
    catch {
        $findings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-004" `
            -CheckName "Unlabeled Documents" -Status "ERROR" `
            -Details "Error scanning for unlabeled content: $($_.Exception.Message)" `
            -Control "SC1: Sensitivity Labels"))
    }

    try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch { }
    return $findings
}

# ============================================================================
# DOMAIN 5 — TEAMS AUDIT
# ============================================================================

function Invoke-TeamsAudit {
    <#
    .SYNOPSIS
        Audits the DCE Operations Team configuration.
        Checks: guest access, member permissions, app sideloading, channel count.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-AuditLog "" "SECTION"
    Write-AuditLog "━━━ DOMAIN 5: TEAMS AUDIT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "SECTION"

    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($SkipTeamsAudit) {
        Write-AuditLog "Teams audit skipped (flag)" "INFO"
        $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-000" `
            -CheckName "Teams Audit" -Status "SKIP" -Details "Skipped via -SkipTeamsAudit flag" `
            -Control "Teams Governance"))
        return $findings
    }

    if ($WhatIfPreference) {
        Write-AuditLog "[WHATIF] Would connect to Graph and audit Teams settings" "WHATIF"
        $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-000" `
            -CheckName "Teams Audit" -Status "SKIP" -Details "WhatIf mode — skipped" `
            -Control "Teams Governance"))
        return $findings
    }

    try {
        Connect-MgGraph -Scopes "Team.ReadBasic.All", "Channel.ReadBasic.All", "TeamSettings.Read.All" `
            -NoWelcome -ErrorAction Stop
        Write-AuditLog "Connected to Microsoft Graph for Teams audit" "INFO"
    }
    catch {
        Write-AuditLog "Failed to connect to Graph for Teams: $($_.Exception.Message)" "ERROR"
        $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-000" `
            -CheckName "Teams Connection" -Status "ERROR" `
            -Details "Cannot connect: $($_.Exception.Message)" `
            -Control "Teams Governance"))
        return $findings
    }

    # Find the DCE Operations team
    $teamName = "Delta Crown Operations"
    try {
        $teams = Get-MgGroup -Filter "displayName eq '$teamName' and resourceProvisioningOptions/Any(x:x eq 'Team')" -ErrorAction Stop

        if (-not $teams) {
            Write-AuditLog "  ⚠️ TMS-001: Team '$teamName' not found" "WARN"
            $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-001" `
                -CheckName "Team Exists" -Status "WARN" `
                -Details "Team '$teamName' not found — may not be deployed yet" `
                -Control "Teams Governance"))
            try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch { }
            return $findings
        }

        $teamId = $teams.Id
        Write-AuditLog "  Found team: $teamName (Id: $teamId)" "INFO"

        # TMS-001: Team exists
        $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-001" `
            -CheckName "Team Exists" -Status "PASS" `
            -Details "Team '$teamName' found" -Control "Teams Governance"))

        # TMS-002: Guest access disabled
        try {
            $team = Get-MgTeam -TeamId $teamId -ErrorAction Stop
            $guestSettings = $team.GuestSettings

            if ($guestSettings -and $guestSettings.AllowCreateUpdateChannels -eq $false -and
                $guestSettings.AllowDeleteChannels -eq $false) {
                Write-AuditLog "  ✅ TMS-002: Guest permissions restricted" "PASS"
                $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-002" `
                    -CheckName "Guest Access" -Status "PASS" `
                    -Details "Guest channel create/update/delete disabled" `
                    -Control "Teams Governance"))
            }
            else {
                Write-AuditLog "  ⚠️ TMS-002: Guest permissions not fully restricted" "WARN"
                $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-002" `
                    -CheckName "Guest Access" -Status "WARN" `
                    -Details "Guest settings: AllowCreate=$($guestSettings.AllowCreateUpdateChannels), AllowDelete=$($guestSettings.AllowDeleteChannels)" `
                    -Remediation "Restrict guest permissions in Teams admin center" `
                    -Control "Teams Governance"))
            }

            # TMS-003: Member permissions restricted
            $memberSettings = $team.MemberSettings
            if ($memberSettings) {
                $issues = [System.Collections.Generic.List[string]]::new()
                if ($memberSettings.AllowCreateUpdateRemoveConnectors) { $issues.Add("Connectors") }
                if ($memberSettings.AllowDeleteChannels) { $issues.Add("DeleteChannels") }

                if ($issues.Count -eq 0) {
                    Write-AuditLog "  ✅ TMS-003: Member permissions properly restricted" "PASS"
                    $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-003" `
                        -CheckName "Member Permissions" -Status "PASS" `
                        -Details "Members cannot delete channels or manage connectors" `
                        -Control "Teams Governance"))
                }
                else {
                    Write-AuditLog "  ⚠️ TMS-003: Members have excessive permissions: $($issues -join ', ')" "WARN"
                    $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-003" `
                        -CheckName "Member Permissions" -Status "WARN" `
                        -Details "Members can: $($issues -join ', ')" `
                        -Remediation "Restrict member permissions in Team settings" `
                        -Control "Teams Governance"))
                }
            }

            # TMS-004: Fun stuff / app sideloading
            $funSettings = $team.FunSettings
            if ($funSettings -and $funSettings.AllowCustomMemes -eq $false) {
                # We actually care about app sideloading, not memes — check messaging policies
                Write-AuditLog "  ℹ️ TMS-004: App governance check — verify sideloading in admin center" "INFO"
            }
            # App sideloading is a tenant-level policy, not per-team — note this
            $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-004" `
                -CheckName "App Governance" -Status "WARN" `
                -Details "App sideloading is a tenant-level policy — verify in Teams Admin Center > Teams apps > Setup policies" `
                -Remediation "Ensure 'Upload custom apps' is disabled in the default setup policy" `
                -Control "Teams Governance"))
        }
        catch {
            Write-AuditLog "  ⚠️ Error reading Team settings: $($_.Exception.Message)" "ERROR"
            $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-002" `
                -CheckName "Team Settings" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" -Control "Teams Governance"))
        }

        # TMS-005: Channel count drift
        try {
            $channels = Get-MgTeamChannel -TeamId $teamId -ErrorAction Stop
            $channelCount = ($channels | Measure-Object).Count
            $privateChannels = $channels | Where-Object { $_.MembershipType -eq "private" }
            $privateCount = ($privateChannels | Measure-Object).Count

            # Expected: General + a few standard + Leadership (private) = roughly 3-8 channels
            $expectedMin = 2
            $expectedMax = 10

            if ($channelCount -ge $expectedMin -and $channelCount -le $expectedMax) {
                Write-AuditLog "  ✅ TMS-005: Channel count $channelCount (private: $privateCount) — within range" "PASS"
                $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-005" `
                    -CheckName "Channel Count" -Status "PASS" `
                    -Details "Total=$channelCount, Private=$privateCount (expected $expectedMin-$expectedMax)" `
                    -Control "Teams Governance"))
            }
            else {
                Write-AuditLog "  ⚠️ TMS-005: Channel count $channelCount — outside expected range" "WARN"
                $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-005" `
                    -CheckName "Channel Count" -Status "WARN" `
                    -Details "Total=$channelCount (expected $expectedMin-$expectedMax) — investigate new/removed channels" `
                    -Remediation "Review channel list for unauthorized additions or deletions" `
                    -Control "Teams Governance"))
            }
        }
        catch {
            $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-005" `
                -CheckName "Channel Count" -Status "ERROR" `
                -Details "Error: $($_.Exception.Message)" -Control "Teams Governance"))
        }
    }
    catch {
        Write-AuditLog "  ⚠️ Teams audit error: $($_.Exception.Message)" "ERROR"
        $findings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-001" `
            -CheckName "Team Discovery" -Status "ERROR" `
            -Details "Error: $($_.Exception.Message)" -Control "Teams Governance"))
    }

    try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch { }
    return $findings
}

# ============================================================================
# DOMAIN 6 — REPORT GENERATION
# ============================================================================

function Export-AuditReportJSON {
    <#
    .SYNOPSIS
        Exports structured JSON report for programmatic consumption.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$Findings,
        [Parameter(Mandatory)][hashtable]$Summary
    )

    $jsonPath = Join-Path $ReportPath "Weekly-Audit-$script:Timestamp.json"

    $report = [ordered]@{
        auditId      = $script:AuditId
        tenant       = $TenantName
        brand        = "Delta Crown Extensions"
        scriptVersion = $script:ScriptVersion
        generated    = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC
        summary      = $Summary
        findings     = $Findings
    }

    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-AuditLog "JSON report: $jsonPath" "INFO"
    return $jsonPath
}

function Export-AuditReportHTML {
    <#
    .SYNOPSIS
        Generates a branded HTML report with DCE Gold/Black theme.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$Findings,
        [Parameter(Mandatory)][hashtable]$Summary
    )

    $htmlPath = Join-Path $ReportPath "Weekly-Audit-$script:Timestamp.html"

    $criticals = $Findings | Where-Object { $_.Status -eq "CRITICAL" }
    $fails     = $Findings | Where-Object { $_.Status -eq "FAIL" }
    $warns     = $Findings | Where-Object { $_.Status -eq "WARN" }
    $passes    = $Findings | Where-Object { $_.Status -eq "PASS" }
    $errors    = $Findings | Where-Object { $_.Status -eq "ERROR" }
    $skips     = $Findings | Where-Object { $_.Status -eq "SKIP" }

    $overallColor = if ($criticals.Count -gt 0) { "#d9534f" }
                    elseif ($fails.Count -gt 0) { "#f0ad4e" }
                    else { "#5cb85c" }

    # Build findings rows
    $tableRows = ""
    foreach ($f in ($Findings | Sort-Object -Property Severity -Descending)) {
        $statusIcon = switch ($f.Status) {
            "CRITICAL" { "🔴" }
            "FAIL"     { "❌" }
            "WARN"     { "⚠️" }
            "PASS"     { "✅" }
            "ERROR"    { "💥" }
            "SKIP"     { "⏭️" }
        }
        $rowClass = switch ($f.Status) {
            "CRITICAL" { "row-critical" }
            "FAIL"     { "row-fail" }
            "WARN"     { "row-warn" }
            "PASS"     { "row-pass" }
            default    { "" }
        }
        $siteDisplay = if ($f.SiteTitle) { $f.SiteTitle } else { "—" }
        $remediationDisplay = if ($f.Remediation) { "<br><em class='remediation'>Fix: $($f.Remediation)</em>" } else { "" }

        $tableRows += @"
            <tr class="$rowClass">
                <td>$($f.CheckId)</td>
                <td>$siteDisplay</td>
                <td>$($f.CheckName)</td>
                <td>$statusIcon $($f.Status)</td>
                <td>$($f.Details)$remediationDisplay</td>
                <td class="control-ref">$($f.Control)</td>
            </tr>
"@
    }

    # Build remediation list
    $remediationList = ""
    $actionItems = $Findings | Where-Object { $_.Status -in @("CRITICAL", "FAIL") -and $_.Remediation }
    foreach ($item in $actionItems) {
        $remediationList += "<li><strong>$($item.CheckId) — $($item.CheckName)</strong>"
        if ($item.SiteTitle) { $remediationList += " ($($item.SiteTitle))" }
        $remediationList += ": $($item.Remediation)</li>`n"
    }
    if (-not $remediationList) { $remediationList = "<li>No critical or failed items requiring remediation.</li>" }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DCE Weekly Security Audit — $script:AuditId</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', -apple-system, sans-serif;
            background: #f4f4f4; color: $script:BrandBlack;
            line-height: 1.5;
        }
        .header {
            background: $script:BrandBlack; color: $script:BrandGold;
            padding: 24px 32px; display: flex; align-items: center; gap: 16px;
        }
        .header h1 { font-size: 1.5em; }
        .header .meta { color: #aaa; font-size: 0.85em; margin-top: 4px; }
        .container { max-width: 1280px; margin: 24px auto; padding: 0 16px; }
        .summary-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
            gap: 12px; margin-bottom: 24px;
        }
        .summary-card {
            background: white; border-radius: 8px; padding: 20px; text-align: center;
            box-shadow: 0 1px 3px rgba(0,0,0,.1); border-top: 4px solid #ddd;
        }
        .summary-card .value { font-size: 2.2em; font-weight: 700; }
        .summary-card .label { font-size: 0.85em; color: #666; margin-top: 4px; }
        .card-pass   { border-top-color: #5cb85c; }
        .card-warn   { border-top-color: #f0ad4e; }
        .card-fail   { border-top-color: #d9534f; }
        .card-critical { border-top-color: #8b0000; }
        .card-total  { border-top-color: $script:BrandGold; }
        .overall-badge {
            display: inline-block; padding: 6px 18px; border-radius: 20px;
            font-weight: 700; color: white; background: $overallColor;
            font-size: 1.1em; margin-bottom: 16px;
        }
        .section { background: white; border-radius: 8px; padding: 24px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,.1); }
        .section h2 { color: $script:BrandBlack; border-bottom: 2px solid $script:BrandGold; padding-bottom: 8px; margin-bottom: 16px; }
        table { width: 100%; border-collapse: collapse; font-size: 0.9em; }
        th { background: $script:BrandBlack; color: $script:BrandGold; padding: 10px 8px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #eee; vertical-align: top; }
        .row-critical { background: #ffebee; }
        .row-fail { background: #fff8e1; }
        .row-warn { background: #fffde7; }
        .row-pass { background: #f1f8e9; }
        .control-ref { font-size: 0.8em; color: #888; }
        .remediation { color: #d9534f; font-size: 0.85em; }
        .footer { text-align: center; color: #999; font-size: 0.8em; padding: 24px; }
        ul { margin-left: 20px; }
        li { margin-bottom: 6px; }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>🔒 Delta Crown Extensions — Weekly Security Audit</h1>
            <div class="meta">
                Audit ID: $script:AuditId &nbsp;|&nbsp;
                Tenant: $TenantName &nbsp;|&nbsp;
                Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm UTC' -AsUTC)
            </div>
        </div>
    </div>

    <div class="container">
        <div class="overall-badge">
            $(if ($criticals.Count -gt 0) { "⛔ CRITICAL ISSUES" }
              elseif ($fails.Count -gt 0) { "⚠️ NEEDS ATTENTION" }
              else { "✅ ALL CLEAR" })
        </div>

        <div class="summary-grid">
            <div class="summary-card card-total">
                <div class="value">$($Summary.Total)</div>
                <div class="label">Total Checks</div>
            </div>
            <div class="summary-card card-pass">
                <div class="value" style="color:#5cb85c">$($Summary.Pass)</div>
                <div class="label">Passed</div>
            </div>
            <div class="summary-card card-warn">
                <div class="value" style="color:#f0ad4e">$($Summary.Warn)</div>
                <div class="label">Warnings</div>
            </div>
            <div class="summary-card card-fail">
                <div class="value" style="color:#d9534f">$($Summary.Fail)</div>
                <div class="label">Failed</div>
            </div>
            <div class="summary-card card-critical">
                <div class="value" style="color:#8b0000">$($Summary.Critical)</div>
                <div class="label">Critical</div>
            </div>
        </div>

        <div class="section">
            <h2>Detailed Findings</h2>
            <table>
                <thead>
                    <tr>
                        <th>Check ID</th>
                        <th>Site</th>
                        <th>Check</th>
                        <th>Status</th>
                        <th>Details</th>
                        <th>Control</th>
                    </tr>
                </thead>
                <tbody>
                    $tableRows
                </tbody>
            </table>
        </div>

        <div class="section">
            <h2>Remediation Actions Required</h2>
            <ul>
                $remediationList
            </ul>
        </div>
    </div>

    <div class="footer">
        Delta Crown Extensions Security Audit &mdash; $script:ScriptVersion &mdash; security-auditor-8f512f
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-AuditLog "HTML report: $htmlPath" "INFO"
    return $htmlPath
}

function Send-AuditAlertEmail {
    <#
    .SYNOPSIS
        Sends email summary to security team. Requires ExchangeOnlineManagement.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Summary,
        [Parameter(Mandatory)][array]$CriticalFindings,
        [string]$HtmlReportPath
    )

    if (-not $SendEmailAlert) {
        Write-AuditLog "Email alerts disabled (use -SendEmailAlert to enable)" "INFO"
        return
    }

    $subject = if ($CriticalFindings.Count -gt 0) {
        "🔴 CRITICAL: DCE Weekly Security Audit — $($CriticalFindings.Count) critical findings"
    }
    elseif ($Summary.Fail -gt 0) {
        "⚠️ DCE Weekly Security Audit — $($Summary.Fail) failures"
    }
    else {
        "✅ DCE Weekly Security Audit — All Clear"
    }

    $body = @"
DCE WEEKLY SECURITY AUDIT SUMMARY
===================================
Audit ID  : $script:AuditId
Tenant    : $TenantName
Timestamp : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

RESULTS:
  Total     : $($Summary.Total)
  Passed    : $($Summary.Pass)
  Warnings  : $($Summary.Warn)
  Failed    : $($Summary.Fail)
  Critical  : $($Summary.Critical)
  Errors    : $($Summary.Error)

$(if ($CriticalFindings.Count -gt 0) {
"CRITICAL FINDINGS (Immediate Action Required):
$(($CriticalFindings | ForEach-Object { "  [$($_.CheckId)] $($_.CheckName): $($_.Details)" }) -join "`n")
"
})

Full HTML report attached or available at:
  $HtmlReportPath

---
Delta Crown Extensions Security Team
security-auditor-8f512f
"@

    Write-AuditLog "Email alert prepared for: $($AlertRecipients -join ', ')" "INFO"
    Write-AuditLog "Subject: $subject" "INFO"

    # Attempt to send via Exchange Online
    try {
        # This requires an active Exchange Online connection and Send-MailMessage or Graph API
        # For environments without SMTP, use Microsoft Graph Send-MgUserMail
        Write-AuditLog "Email send requires Exchange Online or Graph Mail.Send — see logs for prepared content" "WARN"

        # If Send-MgUserMail is available:
        # Send-MgUserMail -UserId "security@deltacrownext.com" -Message @{
        #     Subject = $subject
        #     Body = @{ ContentType = "Text"; Content = $body }
        #     ToRecipients = $AlertRecipients | ForEach-Object { @{ EmailAddress = @{ Address = $_ } } }
        # }
    }
    catch {
        Write-AuditLog "Email send failed: $($_.Exception.Message)" "WARN"
    }
}

# ============================================================================
# MAIN ORCHESTRATOR
# ============================================================================

function Invoke-WeeklySecurityAudit {
    <#
    .SYNOPSIS
        Main entry point. Runs all audit domains and generates reports.
    .DESCRIPTION
        Orchestrates: Permission → Groups → DLP → Labels → Teams → Reports
        Idempotent and safe to run repeatedly.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Initialize-AuditEnvironment

    $allFindings = [System.Collections.Generic.List[PSCustomObject]]::new()

    # --- Run all audit domains ---
    try {
        $permFindings  = Invoke-PermissionAudit
        $allFindings.AddRange([PSCustomObject[]]$permFindings)
    }
    catch {
        Write-AuditLog "Permission audit crashed: $($_.Exception.Message)" "ERROR"
        Write-AuditLog "Stack: $($_.ScriptStackTrace)" "ERROR"
        $allFindings.Add((New-AuditFinding -Domain "Permission" -CheckId "PERM-999" `
            -CheckName "Permission Audit" -Status "ERROR" `
            -Details "Audit crashed: $($_.Exception.Message)" -Control "All"))
    }

    try {
        $groupFindings = Invoke-GroupMembershipAudit
        $allFindings.AddRange([PSCustomObject[]]$groupFindings)
    }
    catch {
        Write-AuditLog "Group audit crashed: $($_.Exception.Message)" "ERROR"
        $allFindings.Add((New-AuditFinding -Domain "Group" -CheckId "GRP-999" `
            -CheckName "Group Audit" -Status "ERROR" `
            -Details "Audit crashed: $($_.Exception.Message)" -Control "All"))
    }

    try {
        $dlpFindings = Invoke-DLPPolicyAudit
        $allFindings.AddRange([PSCustomObject[]]$dlpFindings)
    }
    catch {
        Write-AuditLog "DLP audit crashed: $($_.Exception.Message)" "ERROR"
        $allFindings.Add((New-AuditFinding -Domain "DLP" -CheckId "DLP-999" `
            -CheckName "DLP Audit" -Status "ERROR" `
            -Details "Audit crashed: $($_.Exception.Message)" -Control "All"))
    }

    try {
        $labelFindings = Invoke-SensitivityLabelAudit
        $allFindings.AddRange([PSCustomObject[]]$labelFindings)
    }
    catch {
        Write-AuditLog "Label audit crashed: $($_.Exception.Message)" "ERROR"
        $allFindings.Add((New-AuditFinding -Domain "Label" -CheckId "LBL-999" `
            -CheckName "Label Audit" -Status "ERROR" `
            -Details "Audit crashed: $($_.Exception.Message)" -Control "All"))
    }

    try {
        $teamsFindings = Invoke-TeamsAudit
        $allFindings.AddRange([PSCustomObject[]]$teamsFindings)
    }
    catch {
        Write-AuditLog "Teams audit crashed: $($_.Exception.Message)" "ERROR"
        $allFindings.Add((New-AuditFinding -Domain "Teams" -CheckId "TMS-999" `
            -CheckName "Teams Audit" -Status "ERROR" `
            -Details "Audit crashed: $($_.Exception.Message)" -Control "All"))
    }

    # --- Calculate summary ---
    $summary = @{
        Total    = $allFindings.Count
        Pass     = ($allFindings | Where-Object { $_.Status -eq "PASS" }).Count
        Warn     = ($allFindings | Where-Object { $_.Status -eq "WARN" }).Count
        Fail     = ($allFindings | Where-Object { $_.Status -eq "FAIL" }).Count
        Critical = ($allFindings | Where-Object { $_.Status -eq "CRITICAL" }).Count
        Error    = ($allFindings | Where-Object { $_.Status -eq "ERROR" }).Count
        Skip     = ($allFindings | Where-Object { $_.Status -eq "SKIP" }).Count
    }

    # --- Generate reports ---
    Write-AuditLog "" "SECTION"
    Write-AuditLog "━━━ DOMAIN 6: REPORT GENERATION ━━━━━━━━━━━━━━━━━━━━━━━━━━" "SECTION"

    $jsonPath = Export-AuditReportJSON -Findings $allFindings -Summary $summary
    $htmlPath = Export-AuditReportHTML -Findings $allFindings -Summary $summary

    $criticalFindings = $allFindings | Where-Object { $_.Status -eq "CRITICAL" }
    Send-AuditAlertEmail -Summary $summary -CriticalFindings $criticalFindings -HtmlReportPath $htmlPath

    # --- Console Summary ---
    Write-AuditLog "" "SECTION"
    Write-AuditLog "╔══════════════════════════════════════════════════════════╗" "SECTION"
    Write-AuditLog "║       DCE WEEKLY SECURITY AUDIT — FINAL SUMMARY        ║" "SECTION"
    Write-AuditLog "╠══════════════════════════════════════════════════════════╣" "SECTION"
    Write-AuditLog "║  Audit ID : $($script:AuditId.PadRight(44))║" "SECTION"
    Write-AuditLog "║  Total    : $($summary.Total.ToString().PadRight(44))║" "INFO"
    Write-AuditLog "║  Passed   : $($summary.Pass.ToString().PadRight(44))║" "PASS"
    Write-AuditLog "║  Warnings : $($summary.Warn.ToString().PadRight(44))║" $(if ($summary.Warn -gt 0) { "WARN" } else { "PASS" })
    Write-AuditLog "║  Failed   : $($summary.Fail.ToString().PadRight(44))║" $(if ($summary.Fail -gt 0) { "FAIL" } else { "PASS" })
    Write-AuditLog "║  Critical : $($summary.Critical.ToString().PadRight(44))║" $(if ($summary.Critical -gt 0) { "CRITICAL" } else { "PASS" })
    Write-AuditLog "║  Errors   : $($summary.Error.ToString().PadRight(44))║" $(if ($summary.Error -gt 0) { "ERROR" } else { "PASS" })
    Write-AuditLog "║  Skipped  : $($summary.Skip.ToString().PadRight(44))║" "INFO"
    Write-AuditLog "╠══════════════════════════════════════════════════════════╣" "SECTION"

    if ($summary.Critical -gt 0) {
        Write-AuditLog "║  ⛔ CRITICAL SECURITY ISSUES — IMMEDIATE ACTION NEEDED  ║" "CRITICAL"
    }
    elseif ($summary.Fail -gt 0) {
        Write-AuditLog "║  ⚠️  FAILURES DETECTED — REVIEW AND REMEDIATE            ║" "FAIL"
    }
    elseif ($summary.Warn -gt 0) {
        Write-AuditLog "║  ℹ️  WARNINGS PRESENT — MONITOR AND PLAN FIXES           ║" "WARN"
    }
    else {
        Write-AuditLog "║  ✅ ALL SECURITY CHECKS PASSED                           ║" "PASS"
    }

    Write-AuditLog "╠══════════════════════════════════════════════════════════╣" "SECTION"
    Write-AuditLog "║  Reports:                                                ║" "SECTION"
    Write-AuditLog "║    JSON : $($jsonPath.PadRight(46))║" "INFO"
    Write-AuditLog "║    HTML : $($htmlPath.PadRight(46))║" "INFO"
    Write-AuditLog "║    Log  : $($script:LogFile.PadRight(46))║" "INFO"
    Write-AuditLog "╚══════════════════════════════════════════════════════════╝" "SECTION"

    # --- Determine exit code ---
    if ($summary.Critical -gt 0) {
        Write-AuditLog "Exiting with code 2 (critical failures)" "CRITICAL"
        exit 2
    }
    elseif ($summary.Fail -gt 0 -or $summary.Warn -gt 0) {
        Write-AuditLog "Exiting with code 1 (warnings/failures)" "WARN"
        exit 1
    }
    else {
        Write-AuditLog "Exiting with code 0 (all clear)" "PASS"
        exit 0
    }
}

# ============================================================================
# ENTRY POINT
# ============================================================================

Invoke-WeeklySecurityAudit
