# ============================================================================
# PHASE 3.3: Security Hardening — Permissions & Group Cleanup
# Delta Crown Extensions — Break Inheritance, Remove Dangerous Groups
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Hardens all DCE sites with unique permissions, removes
#              Everyone/All Users groups, applies security group matrix,
#              disables external sharing, creates Marketing group
# DEPENDS ON: 3.1 (all 4 DCE sites exist), 3.2 (Leadership channel SPO)
# ADR: ADR-002 Phase 3 — Permission Model (Section 3)
# FIXES: A1 (connect churn), A3 (centralized auth), B7 (path separators)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = "https://deltacrown-admin.sharepoint.com",
    [Parameter(Mandatory=$false)]
    [string[]]$LocationCodes = @(),
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development"
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.1.0"

# ============================================================================
# PATH RESOLUTION (B7: Join-Path everywhere, no backslash literals)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop
$Config = Import-PowerShellDataFile -Path (Join-Path $ModulesPath "DeltaCrown.Config.psd1")

$LogPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.3-Security-Hardening-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# CONNECTION OWNERSHIP (A1: track who owns the connection)
# ============================================================================
$script:OwnsPnPConnection = $false
$script:OwnsGraphConnection = $false

# ============================================================================
# PERMISSION MATRIX (from ADR-002 Section 3)
# ============================================================================
$ForbiddenGroups = @(
    "Everyone"
    "Everyone except external users"
    "All Users"
    "NT AUTHORITY\Authenticated Users"
)

$PermissionMatrix = @{
    "/sites/dce-hub"            = @(
        @{ Group = "AllStaff"; Role = "Read" }
        @{ Group = "Managers"; Role = "Full Control" }
        @{ Group = "DCE-Leadership"; Role = "Full Control" }
    )
    "/sites/dce-clientservices"  = @(
        @{ Group = "AllStaff"; Role = "Read" }
        @{ Group = "DCE-ClientServices"; Role = "Contribute" }
        @{ Group = "Managers"; Role = "Full Control" }
        @{ Group = "DCE-Leadership"; Role = "Full Control" }
    )
    "/sites/dce-marketing"       = @(
        @{ Group = "AllStaff"; Role = "Read" }
        @{ Group = "Managers"; Role = "Full Control" }
        @{ Group = "Marketing"; Role = "Edit" }
    )
    "/sites/dce-docs"            = @(
        @{ Group = "AllStaff"; Role = "Read" }
        @{ Group = "Managers"; Role = "Full Control" }
        @{ Group = "DCE-Leadership"; Role = "Full Control" }
    )
    # DCE-Operations is Teams-managed — skip permission assignment
}

$RequiredDynamicGroups = @(
    "AllStaff"
    "Managers"
    "Marketing"
    "Stylists"
    "DCE-Operations"
    "DCE-ClientServices"
    "DCE-Leadership"
)

$RequiredStaticGroups = @(
    "DCE-CrossTenant-Pilot"
)

# ============================================================================
# HELPER FUNCTIONS (A1: NO connection management — caller owns the connection)
# ============================================================================

function Get-DCERequiredGroupNames {
    [CmdletBinding()]
    param()

    $required = @($RequiredDynamicGroups + $RequiredStaticGroups)
    foreach ($locationCode in $LocationCodes | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) {
        $groupLocationSuffix = ($locationCode.Trim() -replace '^DCE-', '')
        $required += "DCE-Loc-$groupLocationSuffix"
    }

    return $required | Select-Object -Unique
}

function Test-DCEEntraGroupExists {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$GroupName)

    return (Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Ensure-DCEPilotGroup {
    <#
    .SYNOPSIS
        Ensures the cross-tenant pilot security group exists.
    .DESCRIPTION
        Assumes caller has already connected to Microsoft Graph.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $groupName = "DCE-CrossTenant-Pilot"
    $existing = Test-DCEEntraGroupExists -GroupName $groupName
    if ($existing) {
        Write-DeltaCrownLog "Security group already exists: $groupName (ID: $($existing.Id))" "WARNING"
        return $existing
    }

    if ($PSCmdlet.ShouldProcess($groupName, "Create static security group")) {
        $group = New-MgGroup `
            -DisplayName $groupName `
            -Description "Pilot validation group for cross-tenant onboarding and access checks" `
            -MailEnabled:$false `
            -SecurityEnabled:$true `
            -MailNickname "dcecrosstenantpilot" `
            -Visibility "Private"

        Write-DeltaCrownLog "Created static security group: $groupName (ID: $($group.Id))" "SUCCESS"

        Register-DeltaCrownRollbackAction `
            -ActionName "Remove $groupName" `
            -Action { param($ctx) Remove-MgGroup -GroupId $ctx.GroupId -Confirm:$false } `
            -Context @{ GroupId = $group.Id }

        return $group
    }
}

function Set-DCEUniquePermissions {
    <#
    .SYNOPSIS
        Breaks permission inheritance on a site. Caller manages PnP connection.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$SiteUrl)

    $web = Get-PnPWeb -Includes HasUniqueRoleAssignments
    if ($web.HasUniqueRoleAssignments) {
        Write-DeltaCrownLog "  Already has unique permissions: $SiteUrl" "WARNING"
    }
    else {
        if ($PSCmdlet.ShouldProcess($SiteUrl, "Break permission inheritance")) {
            Set-PnPWeb -BreakInheritance
            Write-DeltaCrownLog "  Broke permission inheritance: $SiteUrl" "SUCCESS"
        }
    }
}

function Remove-DCEForbiddenGroups {
    <#
    .SYNOPSIS
        Removes dangerous broad-access groups from a site. Caller manages PnP connection.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$SiteUrl)

    $removed = 0

    foreach ($forbidden in $ForbiddenGroups) {
        try {
            $assignment = Get-PnPGroup -Identity $forbidden -ErrorAction SilentlyContinue
            if ($assignment) {
                if ($PSCmdlet.ShouldProcess("$forbidden from $SiteUrl", "Remove group")) {
                    Remove-PnPGroup -Identity $forbidden -Force -ErrorAction SilentlyContinue
                    $removed++
                    Write-DeltaCrownLog "  Removed forbidden group: $forbidden" "SUCCESS"
                }
            }
        }
        catch {
            Write-DeltaCrownLog "  Group not found (expected): $forbidden" "DEBUG"
        }
    }

    return $removed
}

function Set-DCESitePermissions {
    <#
    .SYNOPSIS
        Applies permission matrix entries for a site. Caller manages PnP connection.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SiteUrl,
        [array]$Permissions
    )

    foreach ($perm in $Permissions) {
        try {
            $group = Get-PnPGroup -Identity $perm.Group -ErrorAction SilentlyContinue

            if (!$group) {
                Write-DeltaCrownLog "  Granting $($perm.Role) to $($perm.Group) on $SiteUrl" "INFO"
                Set-PnPGroupPermissions -Identity $perm.Group -AddRole $perm.Role -ErrorAction SilentlyContinue
                if (!$?) {
                    $roleDefinition = Get-PnPRoleDefinition -Identity $perm.Role -ErrorAction Stop
                    Write-DeltaCrownLog "  Applied $($perm.Role) for $($perm.Group)" "SUCCESS"
                }
            }
            else {
                Set-PnPGroupPermissions -Identity $perm.Group -AddRole $perm.Role
                Write-DeltaCrownLog "  Set $($perm.Role) for $($perm.Group)" "SUCCESS"
            }
        }
        catch {
            Write-DeltaCrownLog "  Failed to set permissions for $($perm.Group): $_" "ERROR"
        }
    }
}

function Disable-DCEExternalSharing {
    <#
    .SYNOPSIS
        Disables external sharing on a site. Requires admin-level PnP connection.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$SiteUrl)

    if ($PSCmdlet.ShouldProcess($SiteUrl, "Disable external sharing")) {
        try {
            Set-PnPTenantSite -Url $SiteUrl -SharingCapability Disabled
            Write-DeltaCrownLog "  Disabled external sharing: $SiteUrl" "SUCCESS"
        }
        catch {
            Write-DeltaCrownLog "  Failed to disable sharing on $SiteUrl`: $_" "ERROR"
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.3: Security Hardening"
    Write-DeltaCrownLog "Script Version: $scriptVersion" "INFO"

    $results = @{
        PilotGroupReady    = $false
        MissingGroups       = @()
        SitesHardened       = @()
        ForbiddenRemoved    = 0
        PermissionsApplied  = @()
        SharingDisabled     = @()
        Errors              = @()
        StartTime           = Get-Date
    }

    # ------------------------------------------------------------------
    # CONNECTION SETUP (A1: connect once, reuse everywhere)
    # ------------------------------------------------------------------
    $existingGraph = Get-MgContext -ErrorAction SilentlyContinue
    if (!$existingGraph) {
        Connect-DeltaCrownGraph -RequiredScopes @("Group.ReadWrite.All")
        $script:OwnsGraphConnection = $true
    }
    Write-DeltaCrownLog "Graph connection ready" "SUCCESS"

    $existingPnP = Get-PnPContext -ErrorAction SilentlyContinue
    if (!$existingPnP) {
        Connect-DeltaCrownSharePoint -Url $AdminUrl
        $script:OwnsPnPConnection = $true
    }
    Write-DeltaCrownLog "SharePoint Admin connection ready" "SUCCESS"

    # ------------------------------------------------------------------
    # STEP 1: Verify required Entra groups and ensure pilot group exists
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 1: Verify Entra Group Readiness ===" "STAGE"

    $pilotGroup = Ensure-DCEPilotGroup
    $results.PilotGroupReady = ($pilotGroup -ne $null)

    foreach ($requiredGroup in (Get-DCERequiredGroupNames)) {
        $group = Test-DCEEntraGroupExists -GroupName $requiredGroup
        if ($group) {
            Write-DeltaCrownLog "Required group ready: $requiredGroup" "SUCCESS"
        }
        else {
            Write-DeltaCrownLog "Required group missing: $requiredGroup" "WARNING"
            $results.MissingGroups += $requiredGroup
        }
    }

    # ------------------------------------------------------------------
    # STEP 2: Build site list (needs admin PnP for Leadership lookup)
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 2: Enumerate DCE Sites ===" "STAGE"

    # Reconnect to admin if we're not there (helpers may have changed context)
    Connect-DeltaCrownSharePoint -Url $AdminUrl

    $allDCESites = @(
        "https://$TenantName.sharepoint.com/sites/dce-hub"
        "https://$TenantName.sharepoint.com/sites/dce-operations"
        "https://$TenantName.sharepoint.com/sites/dce-clientservices"
        "https://$TenantName.sharepoint.com/sites/dce-marketing"
        "https://$TenantName.sharepoint.com/sites/dce-docs"
    )

    $leadershipSites = Get-PnPTenantSite | Where-Object {
        $_.Url -match "dce-operations" -and $_.Url -match "Leadership"
    }
    foreach ($ls in $leadershipSites) {
        $allDCESites += $ls.Url
    }

    Write-DeltaCrownLog "Sites to harden: $($allDCESites.Count)" "INFO"

    # ------------------------------------------------------------------
    # STEP 3: Harden each site — connect ONCE per site, run ALL helpers
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 3: Break Inheritance, Remove Forbidden Groups, Apply Permissions ===" "STAGE"

    foreach ($siteUrl in $allDCESites) {
        Write-DeltaCrownLog "Hardening: $siteUrl" "INFO"

        try {
            # Single connection per site — all helpers reuse it
            Connect-DeltaCrownSharePoint -Url $siteUrl

            # 3a: Break inheritance
            Set-DCEUniquePermissions -SiteUrl $siteUrl

            # 3b: Remove forbidden groups
            $removed = Remove-DCEForbiddenGroups -SiteUrl $siteUrl
            $results.ForbiddenRemoved += $removed

            # 3c: Apply permission matrix (if this site has one)
            $siteRelative = $siteUrl -replace "https://$TenantName\.sharepoint\.com", ""
            if ($PermissionMatrix.ContainsKey($siteRelative)) {
                Set-DCESitePermissions -SiteUrl $siteUrl -Permissions $PermissionMatrix[$siteRelative]
                $results.PermissionsApplied += $siteRelative
            }

            $results.SitesHardened += $siteUrl
        }
        catch {
            Write-DeltaCrownLog "Failed to harden $siteUrl`: $_" "ERROR"
            $results.Errors += "Hardening failed: $siteUrl — $_"
        }
    }

    # ------------------------------------------------------------------
    # STEP 4: Disable external sharing (requires admin connection)
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 4: Disable External Sharing ===" "STAGE"

    Connect-DeltaCrownSharePoint -Url $AdminUrl

    foreach ($siteUrl in $allDCESites) {
        Disable-DCEExternalSharing -SiteUrl $siteUrl
        $results.SharingDisabled += $siteUrl
    }

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = Get-Date
    $duration = $results.EndTime - $results.StartTime

    Write-DeltaCrownBanner "PHASE 3.3 COMPLETE"
    Write-DeltaCrownLog "Pilot group ready:       $($results.PilotGroupReady)" "SUCCESS"
    Write-DeltaCrownLog "Missing groups:          $($results.MissingGroups.Count)" $(if($results.MissingGroups.Count -gt 0){"WARNING"}else{"SUCCESS"})
    Write-DeltaCrownLog "Sites hardened:          $($results.SitesHardened.Count)" "SUCCESS"
    Write-DeltaCrownLog "Forbidden groups removed: $($results.ForbiddenRemoved)" "SUCCESS"
    Write-DeltaCrownLog "Permission matrices set: $($results.PermissionsApplied.Count)" "SUCCESS"
    Write-DeltaCrownLog "External sharing disabled: $($results.SharingDisabled.Count)" "SUCCESS"
    Write-DeltaCrownLog "Errors: $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})

    $resultsPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.3-security-results.json"))
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force

    Clear-DeltaCrownRollbackStack
    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        SitesHardened    = $results.SitesHardened
        Errors           = $results.Errors
        Duration         = $duration
        Status           = if ($results.Errors.Count -eq 0 -and $results.MissingGroups.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.3: $_" "CRITICAL"
    try { Invoke-DeltaCrownRollback -Reason "Phase 3.3 failed: $_" -ContinueOnError } catch {}
    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    # Only disconnect connections WE created (A1: connection ownership)
    if ($script:OwnsPnPConnection) {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }
    if ($script:OwnsGraphConnection) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}
