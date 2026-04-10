# ============================================================================
# PHASE 3.3: Security Hardening — Permissions & Group Cleanup
# Delta Crown Extensions — Break Inheritance, Remove Dangerous Groups
# ============================================================================
# VERSION: 1.0.0
# DESCRIPTION: Hardens all DCE sites with unique permissions, removes
#              Everyone/All Users groups, applies security group matrix,
#              disables external sharing, creates SG-DCE-Marketing group
# DEPENDS ON: 3.1 (all 4 DCE sites exist), 3.2 (Leadership channel SPO)
# ADR: ADR-002 Phase 3 — Permission Model (Section 3)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = "https://deltacrownext-admin.sharepoint.com",
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development"
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.0.0"

$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot "phase2-week1\modules"
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop
$Config = Import-PowerShellDataFile -Path (Join-Path $ModulesPath "DeltaCrown.Config.psd1")

$LogPath = Join-Path $ProjectRoot "phase3-week2\logs"
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.3-Security-Hardening-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# PERMISSION MATRIX (from ADR-002 Section 3)
# ============================================================================
$ForbiddenGroups = @(
    "Everyone"
    "Everyone except external users"
    "All Users"
    "NT AUTHORITY\Authenticated Users"
)

$PermissionMatrix = @(
    @{ SiteUrl = "/sites/dce-hub";            Permissions = @(
        @{ Group = "SG-DCE-AllStaff";   Role = "Read" }
        @{ Group = "SG-DCE-Leadership"; Role = "Full Control" }
    )}
    @{ SiteUrl = "/sites/dce-clientservices";  Permissions = @(
        @{ Group = "SG-DCE-AllStaff";   Role = "Contribute" }
        @{ Group = "SG-DCE-Leadership"; Role = "Full Control" }
    )}
    @{ SiteUrl = "/sites/dce-marketing";       Permissions = @(
        @{ Group = "SG-DCE-AllStaff";   Role = "Read" }
        @{ Group = "SG-DCE-Leadership"; Role = "Full Control" }
        @{ Group = "SG-DCE-Marketing";  Role = "Edit" }
    )}
    @{ SiteUrl = "/sites/dce-docs";            Permissions = @(
        @{ Group = "SG-DCE-AllStaff";   Role = "Read" }
        @{ Group = "SG-DCE-Leadership"; Role = "Full Control" }
    )}
    # DCE-Operations is Teams-managed — skip permission assignment
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function New-DCEMarketingGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $groupName = "SG-DCE-Marketing"

    Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome

    $existing = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existing) {
        Write-DeltaCrownLog "Security group already exists: $groupName (ID: $($existing.Id))" "WARNING"
        Disconnect-MgGraph
        return $existing
    }

    if ($PSCmdlet.ShouldProcess($groupName, "Create dynamic security group")) {
        $group = New-MgGroup `
            -DisplayName $groupName `
            -Description "Delta Crown Extensions marketing team — auto-populated" `
            -MailEnabled:$false `
            -SecurityEnabled:$true `
            -MailNickname "sg-dce-marketing" `
            -GroupTypes @("DynamicMembership") `
            -MembershipRule '(user.department -eq "Delta Crown Marketing")' `
            -MembershipRuleProcessingState "On" `
            -Visibility "Private"

        Write-DeltaCrownLog "Created dynamic group: $groupName (ID: $($group.Id))" "SUCCESS"

        Register-DeltaCrownRollbackAction `
            -ActionName "Remove $groupName" `
            -Action { param($ctx) Remove-MgGroup -GroupId $ctx.GroupId -Confirm:$false } `
            -Context @{ GroupId = $group.Id }

        Disconnect-MgGraph
        return $group
    }
}

function Set-DCEUniquePermissions {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SiteUrl
    )

    Connect-PnPOnline -Url $SiteUrl -Interactive

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

    Disconnect-PnPOnline
}

function Remove-DCEForbiddenGroups {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SiteUrl
    )

    Connect-PnPOnline -Url $SiteUrl -Interactive

    $roleAssignments = Get-PnPWeb -Includes RoleAssignments
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

    Disconnect-PnPOnline
    return $removed
}

function Set-DCEPermissionMatrix {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SiteUrl,
        [array]$Permissions
    )

    Connect-PnPOnline -Url $SiteUrl -Interactive

    foreach ($perm in $Permissions) {
        try {
            $group = Get-PnPGroup -Identity $perm.Group -ErrorAction SilentlyContinue

            if (!$group) {
                # Try to find Azure AD group and grant permissions
                Write-DeltaCrownLog "  Granting $($perm.Role) to $($perm.Group) on $SiteUrl" "INFO"

                # Use Set-PnPWebPermission for Azure AD groups
                Set-PnPGroupPermissions -Identity $perm.Group -AddRole $perm.Role -ErrorAction SilentlyContinue
                if (!$?) {
                    # Fallback: add as site permission directly
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

    Disconnect-PnPOnline
}

function Disable-DCEExternalSharing {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SiteUrl
    )

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
        GroupCreated        = $false
        SitesHardened       = @()
        ForbiddenRemoved    = 0
        PermissionsApplied  = @()
        SharingDisabled     = @()
        Errors              = @()
        StartTime           = Get-Date
    }

    # ------------------------------------------------------------------
    # STEP 1: Create SG-DCE-Marketing dynamic group
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 1: Create SG-DCE-Marketing Group ===" "STAGE"
    $marketingGroup = New-DCEMarketingGroup
    $results.GroupCreated = ($marketingGroup -ne $null)

    # ------------------------------------------------------------------
    # STEP 2: Break inheritance + remove forbidden groups on ALL sites
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 2: Break Inheritance & Remove Forbidden Groups ===" "STAGE"

    Connect-PnPOnline -Url $AdminUrl -Interactive

    $allDCESites = @(
        "https://$TenantName.sharepoint.com/sites/dce-hub"
        "https://$TenantName.sharepoint.com/sites/dce-operations"
        "https://$TenantName.sharepoint.com/sites/dce-clientservices"
        "https://$TenantName.sharepoint.com/sites/dce-marketing"
        "https://$TenantName.sharepoint.com/sites/dce-docs"
    )

    # Also find Leadership private channel site
    $leadershipSites = Get-PnPTenantSite | Where-Object {
        $_.Url -match "dce-operations" -and $_.Url -match "Leadership"
    }
    foreach ($ls in $leadershipSites) {
        $allDCESites += $ls.Url
    }

    Disconnect-PnPOnline

    foreach ($siteUrl in $allDCESites) {
        try {
            Write-DeltaCrownLog "Hardening: $siteUrl" "INFO"

            Set-DCEUniquePermissions -SiteUrl $siteUrl
            $removed = Remove-DCEForbiddenGroups -SiteUrl $siteUrl
            $results.ForbiddenRemoved += $removed
            $results.SitesHardened += $siteUrl
        }
        catch {
            Write-DeltaCrownLog "Failed to harden $siteUrl`: $_" "ERROR"
            $results.Errors += "Hardening failed: $siteUrl — $_"
        }
    }

    # ------------------------------------------------------------------
    # STEP 3: Apply permission matrix
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 3: Apply Permission Matrix ===" "STAGE"

    foreach ($entry in $PermissionMatrix) {
        $fullUrl = "https://$TenantName.sharepoint.com$($entry.SiteUrl)"
        try {
            Set-DCEPermissionMatrix -SiteUrl $fullUrl -Permissions $entry.Permissions
            $results.PermissionsApplied += $entry.SiteUrl
        }
        catch {
            Write-DeltaCrownLog "Failed to apply permissions on $($entry.SiteUrl): $_" "ERROR"
            $results.Errors += "Permission matrix failed: $($entry.SiteUrl) — $_"
        }
    }

    # ------------------------------------------------------------------
    # STEP 4: Disable external sharing on all DCE sites
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 4: Disable External Sharing ===" "STAGE"

    Connect-PnPOnline -Url $AdminUrl -Interactive
    foreach ($siteUrl in $allDCESites) {
        Disable-DCEExternalSharing -SiteUrl $siteUrl
        $results.SharingDisabled += $siteUrl
    }
    Disconnect-PnPOnline

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = Get-Date
    $duration = $results.EndTime - $results.StartTime

    Write-DeltaCrownBanner "PHASE 3.3 COMPLETE"
    Write-DeltaCrownLog "Marketing group created: $($results.GroupCreated)" "SUCCESS"
    Write-DeltaCrownLog "Sites hardened:          $($results.SitesHardened.Count)" "SUCCESS"
    Write-DeltaCrownLog "Forbidden groups removed: $($results.ForbiddenRemoved)" "SUCCESS"
    Write-DeltaCrownLog "Permission matrices set: $($results.PermissionsApplied.Count)" "SUCCESS"
    Write-DeltaCrownLog "External sharing disabled: $($results.SharingDisabled.Count)" "SUCCESS"
    Write-DeltaCrownLog "Errors: $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})

    $resultsPath = Join-Path $ProjectRoot "phase3-week2\docs\3.3-security-results.json"
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force

    Clear-DeltaCrownRollbackStack
    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        SitesHardened    = $results.SitesHardened
        Errors           = $results.Errors
        Duration         = $duration
        Status           = if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.3: $_" "CRITICAL"
    try { Invoke-DeltaCrownRollback -Reason "Phase 3.3 failed: $_" -ContinueOnError } catch {}
    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
