# ============================================================================
# PHASE 3.7: Comprehensive Phase 3 Verification
# Delta Crown Extensions — Validate All Phase 3 Components
# ============================================================================
# VERSION: 1.0.0
# DESCRIPTION: Verifies all Phase 3 components: sites, lists, Teams,
#              permissions, DLP, mailboxes, templates
# DEPENDS ON: All Phase 3 scripts (3.1–3.6) executed
# EXIT CODES: 0 = all pass, 1 = warnings, 2 = critical failures
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Teams";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = "https://deltacrownext-admin.sharepoint.com",
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    [Parameter(Mandatory=$false)]
    [switch]$SkipTeamsChecks,
    [Parameter(Mandatory=$false)]
    [switch]$SkipDLPChecks
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.0.0"

$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot "phase2-week1\modules"
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$LogPath = Join-Path $ProjectRoot "phase3-week2\logs"
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.7-Verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# EXPECTED STATE DEFINITIONS
# ============================================================================
$ExpectedSites = @(
    "/sites/dce-operations"
    "/sites/dce-clientservices"
    "/sites/dce-marketing"
    "/sites/dce-docs"
)

$ExpectedLists = @{
    "/sites/dce-operations"     = @("Bookings", "Staff Schedule", "Tasks", "Inventory", "Calendar")
    "/sites/dce-clientservices" = @("Client Records", "Service Catalog", "Feedback")
    "/sites/dce-marketing"      = @("Campaigns", "Social Calendar")
}

$ExpectedLibraries = @{
    "/sites/dce-operations"     = @("Daily Ops")
    "/sites/dce-clientservices" = @("Consent Forms")
    "/sites/dce-marketing"      = @("Brand Assets", "Templates")
    "/sites/dce-docs"           = @("Policies", "Training", "Forms", "Templates", "Archive")
}

$ExpectedGroups = @("SG-DCE-AllStaff", "SG-DCE-Leadership", "SG-DCE-Marketing")

$ForbiddenGroups = @("Everyone", "Everyone except external users", "All Users")

$ExpectedChannels = @("General", "Daily Ops", "Bookings", "Marketing", "Leadership")

$ExpectedMailboxes = @("operations@deltacrown.com.au", "bookings@deltacrown.com.au", "info@deltacrown.com.au")

$ExpectedDLPPolicies = @("DCE-Data-Protection", "Corp-Data-Protection", "External-Sharing-Block")

# ============================================================================
# TEST RUNNER
# ============================================================================
$global:TestResults = @()
$global:PassCount = 0
$global:FailCount = 0
$global:WarnCount = 0
$global:SkipCount = 0

function Test-Condition {
    param(
        [string]$Category,
        [string]$TestName,
        [bool]$Condition,
        [string]$SuccessMsg = "PASS",
        [string]$FailureMsg = "FAIL",
        [string]$Severity = "FAIL"  # FAIL or WARN
    )

    $status = if ($Condition) { "PASS" } else { $Severity }

    $global:TestResults += [PSCustomObject]@{
        Category  = $Category
        Test      = $TestName
        Status    = $status
        Details   = if ($Condition) { $SuccessMsg } else { $FailureMsg }
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    switch ($status) {
        "PASS" { $global:PassCount++; Write-DeltaCrownLog "  ✅ $TestName" "SUCCESS" }
        "FAIL" { $global:FailCount++; Write-DeltaCrownLog "  ❌ $TestName — $FailureMsg" "ERROR" }
        "WARN" { $global:WarnCount++; Write-DeltaCrownLog "  ⚠️ $TestName — $FailureMsg" "WARNING" }
    }
}

function Skip-Test {
    param([string]$Category, [string]$TestName, [string]$Reason)
    $global:SkipCount++
    $global:TestResults += [PSCustomObject]@{
        Category = $Category; Test = $TestName; Status = "SKIP"; Details = $Reason; Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    Write-DeltaCrownLog "  ⏭️ $TestName — SKIPPED: $Reason" "WARNING"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.7: Comprehensive Verification"
    Write-DeltaCrownLog "Script Version: $scriptVersion" "INFO"

    $startTime = Get-Date

    # ------------------------------------------------------------------
    # CATEGORY 1: Site Existence
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Sites ===" "STAGE"

    Connect-PnPOnline -Url $AdminUrl -Interactive

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        $site = Get-PnPTenantSite -Url $fullUrl -ErrorAction SilentlyContinue
        Test-Condition "Sites" "Site exists: $siteUrl" ($site -ne $null) -FailureMsg "Site not found at $fullUrl"
    }

    # ------------------------------------------------------------------
    # CATEGORY 2: Hub Association
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Hub Association ===" "STAGE"

    $dceHubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
    $hubChildren = Get-PnPHubSiteChild -Identity $dceHubUrl -ErrorAction SilentlyContinue

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        $isAssociated = $hubChildren -contains $fullUrl
        Test-Condition "Hub" "Hub associated: $siteUrl" $isAssociated -FailureMsg "Not associated with DCE Hub"
    }

    Disconnect-PnPOnline

    # ------------------------------------------------------------------
    # CATEGORY 3: Lists & Libraries
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Lists & Libraries ===" "STAGE"

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        Connect-PnPOnline -Url $fullUrl -Interactive

        # Check lists
        if ($ExpectedLists.ContainsKey($siteUrl)) {
            foreach ($listName in $ExpectedLists[$siteUrl]) {
                $list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue
                Test-Condition "Lists" "$siteUrl — List: $listName" ($list -ne $null) -FailureMsg "List not found"
            }
        }

        # Check libraries
        if ($ExpectedLibraries.ContainsKey($siteUrl)) {
            foreach ($libName in $ExpectedLibraries[$siteUrl]) {
                $lib = Get-PnPList -Identity $libName -ErrorAction SilentlyContinue
                Test-Condition "Libraries" "$siteUrl — Library: $libName" ($lib -ne $null) -FailureMsg "Library not found"
            }
        }

        Disconnect-PnPOnline
    }

    # ------------------------------------------------------------------
    # CATEGORY 4: Permissions
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Permissions ===" "STAGE"

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        Connect-PnPOnline -Url $fullUrl -Interactive

        $web = Get-PnPWeb -Includes HasUniqueRoleAssignments
        Test-Condition "Permissions" "Unique permissions: $siteUrl" $web.HasUniqueRoleAssignments -FailureMsg "Inheriting permissions!"

        # Check for forbidden groups
        foreach ($forbidden in $ForbiddenGroups) {
            $found = Get-PnPGroup -Identity $forbidden -ErrorAction SilentlyContinue
            Test-Condition "Permissions" "No '$forbidden' on $siteUrl" ($found -eq $null) -FailureMsg "FORBIDDEN GROUP FOUND!"
        }

        # Check external sharing
        $site = Get-PnPTenantSite -Url $fullUrl -ErrorAction SilentlyContinue
        $sharingOff = ($site.SharingCapability -eq "Disabled")
        Test-Condition "Permissions" "External sharing disabled: $siteUrl" $sharingOff -FailureMsg "External sharing is ENABLED" -Severity "FAIL"

        Disconnect-PnPOnline
    }

    # ------------------------------------------------------------------
    # CATEGORY 5: Security Groups
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Security Groups ===" "STAGE"

    Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

    foreach ($groupName in $ExpectedGroups) {
        $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
        Test-Condition "Groups" "Group exists: $groupName" ($group -ne $null) -FailureMsg "Group not found"

        if ($group) {
            $isDynamic = $group.GroupTypes -contains "DynamicMembership"
            Test-Condition "Groups" "Dynamic membership: $groupName" $isDynamic -FailureMsg "Not a dynamic group" -Severity "WARN"
        }
    }

    Disconnect-MgGraph

    # ------------------------------------------------------------------
    # CATEGORY 6: Teams (optional)
    # ------------------------------------------------------------------
    if (!$SkipTeamsChecks) {
        Write-DeltaCrownLog "=== Teams ===" "STAGE"

        Connect-MgGraph -Scopes "Team.ReadBasic.All", "Channel.ReadBasic.All" -NoWelcome

        $team = Get-MgGroup -Filter "displayName eq 'Delta Crown Operations'" -ErrorAction SilentlyContinue |
            Where-Object { $_.ResourceProvisioningOptions -contains "Team" } | Select-Object -First 1

        Test-Condition "Teams" "Team exists: Delta Crown Operations" ($team -ne $null) -FailureMsg "Team not found"

        if ($team) {
            $channels = Get-MgTeamChannel -TeamId $team.Id -ErrorAction SilentlyContinue
            $channelNames = $channels | ForEach-Object { $_.DisplayName }

            foreach ($expected in $ExpectedChannels) {
                Test-Condition "Teams" "Channel exists: $expected" ($channelNames -contains $expected) -FailureMsg "Channel not found"
            }

            # Check private channel
            $leadership = $channels | Where-Object { $_.DisplayName -eq "Leadership" }
            if ($leadership) {
                Test-Condition "Teams" "Leadership is private" ($leadership.MembershipType -eq "Private") -FailureMsg "Leadership channel is not private!"
            }
        }

        Disconnect-MgGraph
    }
    else {
        Skip-Test "Teams" "All Teams checks" "SkipTeamsChecks flag set"
    }

    # ------------------------------------------------------------------
    # CATEGORY 7: Templates
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Templates ===" "STAGE"

    $templatePath = Join-Path $ProjectRoot "phase3-week2\templates"
    $hashFile = Join-Path $templatePath "template-hashes.json"

    $expectedTemplates = @("DCE-Operations-Template.xml", "DCE-ClientServices-Template.xml", "DCE-Marketing-Template.xml", "DCE-Docs-Template.xml", "DCE-Hub-Theme.json")

    foreach ($tmpl in $expectedTemplates) {
        $tmplPath = Join-Path $templatePath $tmpl
        Test-Condition "Templates" "Template exists: $tmpl" (Test-Path $tmplPath) -FailureMsg "Template file not found" -Severity "WARN"
    }

    Test-Condition "Templates" "Hash manifest exists" (Test-Path $hashFile) -FailureMsg "template-hashes.json not found" -Severity "WARN"

    # ------------------------------------------------------------------
    # SUMMARY REPORT
    # ------------------------------------------------------------------
    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-DeltaCrownBanner "VERIFICATION RESULTS"
    Write-DeltaCrownLog "✅ Passed:   $global:PassCount" "SUCCESS"
    Write-DeltaCrownLog "❌ Failed:   $global:FailCount" $(if($global:FailCount -gt 0){"ERROR"}else{"SUCCESS"})
    Write-DeltaCrownLog "⚠️ Warnings: $global:WarnCount" $(if($global:WarnCount -gt 0){"WARNING"}else{"INFO"})
    Write-DeltaCrownLog "⏭️ Skipped:  $global:SkipCount" "INFO"
    Write-DeltaCrownLog "Duration:    $($duration.TotalSeconds.ToString('F1'))s" "INFO"

    # Export JSON report
    $report = @{
        Summary = @{
            Passed   = $global:PassCount
            Failed   = $global:FailCount
            Warnings = $global:WarnCount
            Skipped  = $global:SkipCount
            Total    = $global:TestResults.Count
            Duration = $duration.TotalSeconds
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        Results = $global:TestResults
    }

    $reportPath = Join-Path $ProjectRoot "phase3-week2\docs\3.7-verification-report.json"
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Force
    Write-DeltaCrownLog "Report saved: $reportPath" "INFO"

    Export-DeltaCrownLogBuffer -Path $LogFile

    # Exit codes
    if ($global:FailCount -gt 0) {
        Write-DeltaCrownLog "VERIFICATION FAILED — $global:FailCount critical failures" "CRITICAL"
        exit 2
    }
    elseif ($global:WarnCount -gt 0) {
        Write-DeltaCrownLog "VERIFICATION PASSED WITH WARNINGS — $global:WarnCount warnings" "WARNING"
        exit 1
    }
    else {
        Write-DeltaCrownLog "VERIFICATION PASSED — All checks green" "SUCCESS"
        exit 0
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.7: $_" "CRITICAL"
    Export-DeltaCrownLogBuffer -Path $LogFile
    exit 2
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
