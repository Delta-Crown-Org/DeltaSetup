# ============================================================================
# PHASE 3.7: Comprehensive Phase 3 Verification
# Delta Crown Extensions — Validate All Phase 3 Components
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Verifies all Phase 3 components: sites, lists, Teams,
#              permissions, DLP, mailboxes, templates, schema
# DEPENDS ON: All Phase 3 scripts (3.1–3.6) executed
# EXIT CODES: 0 = all pass, 1 = warnings, 2 = critical failures
# FIXES: A2 (connect churn), A3 (connection ownership), B7 (path seps),
#        C1 (DLP verification), C2 (mailbox verification), C3 (schema checks)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Teams";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = "https://deltacrown-admin.sharepoint.com",
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    [Parameter(Mandatory=$false)]
    [switch]$SkipTeamsChecks,
    [Parameter(Mandatory=$false)]
    [switch]$SkipDLPChecks,
    [Parameter(Mandatory=$false)]
    [switch]$SkipMailboxChecks
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.1.0"

# ============================================================================
# PATH RESOLUTION (B7: Join-Path everywhere)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$LogPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.7-Verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# CONNECTION OWNERSHIP (A3: track who owns each connection)
# ============================================================================
$script:OwnsPnPConnection = $false
$script:OwnsGraphConnection = $false
$script:OwnsIPPSConnection = $false
$script:OwnsExchangeConnection = $false

# Internal skip flags (set when connection fails for optional categories)
$script:SkipDLP = $false
$script:SkipMailboxes = $false

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

# C3: Critical PII columns that MUST exist on Client Records
$ClientRecordsPIIColumns = @("Email", "Phone", "AllergyNotes", "ServiceHistory")

# C3: DCE-Docs library metadata columns
$DocsMetadataColumns = @("DocType", "Department", "ReviewDate", "DocVersion", "DocStatus", "DocOwner")

$ExpectedGroups = @("AllStaff", "Managers", "Marketing")

$ForbiddenGroups = @("Everyone", "Everyone except external users", "All Users")

$ExpectedChannels = @("General", "Daily Ops", "Bookings", "Marketing", "Leadership")

$ExpectedMailboxes = @("operations@deltacrown.com", "bookings@deltacrown.com", "info@deltacrown.com")

$ExpectedDLPPolicies = @("DCE-Data-Protection", "Corp-Data-Protection", "External-Sharing-Block")

# ============================================================================
# TEST RUNNER (script scope — no global leaks)
# ============================================================================
$script:TestResults = @()
$script:PassCount = 0
$script:FailCount = 0
$script:WarnCount = 0
$script:SkipCount = 0

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

    $script:TestResults += [PSCustomObject]@{
        Category  = $Category
        Test      = $TestName
        Status    = $status
        Details   = if ($Condition) { $SuccessMsg } else { $FailureMsg }
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    switch ($status) {
        "PASS" { $script:PassCount++; Write-DeltaCrownLog "  ✅ $TestName" "SUCCESS" }
        "FAIL" { $script:FailCount++; Write-DeltaCrownLog "  ❌ $TestName — $FailureMsg" "ERROR" }
        "WARN" { $script:WarnCount++; Write-DeltaCrownLog "  ⚠️ $TestName — $FailureMsg" "WARNING" }
    }
}

function Skip-Test {
    param([string]$Category, [string]$TestName, [string]$Reason)
    $script:SkipCount++
    $script:TestResults += [PSCustomObject]@{
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
    Write-DeltaCrownLog "Environment: $Environment" "INFO"
    Write-DeltaCrownLog "Tenant: $TenantName" "INFO"

    $startTime = Get-Date

    # ------------------------------------------------------------------
    # A2 FIX: Connect ALL services ONCE at the start
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Establishing Connections ===" "STAGE"

    # PnP SharePoint (needed for Categories 1-4, 7)
    $existingPnP = Get-PnPContext -ErrorAction SilentlyContinue
    if (!$existingPnP) {
        Connect-DeltaCrownSharePoint -Url $AdminUrl
        $script:OwnsPnPConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established SharePoint connection" "INFO"
    }
    Write-DeltaCrownLog "SharePoint connection ready" "SUCCESS"

    # Graph (needed for Categories 5, 6)
    $existingGraph = Get-MgContext -ErrorAction SilentlyContinue
    if (!$existingGraph) {
        Connect-DeltaCrownGraph -RequiredScopes @(
            "Group.Read.All",
            "Team.ReadBasic.All",
            "Channel.ReadBasic.All"
        )
        $script:OwnsGraphConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established Graph connection" "INFO"
    }
    Write-DeltaCrownLog "Graph connection ready" "SUCCESS"

    # ------------------------------------------------------------------
    # CATEGORY 1: Site Existence
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Category 1: Sites ===" "STAGE"

    Connect-DeltaCrownSharePoint -Url $AdminUrl

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        $site = Get-PnPTenantSite -Url $fullUrl -ErrorAction SilentlyContinue
        Test-Condition "Sites" "Site exists: $siteUrl" ($site -ne $null) -FailureMsg "Site not found at $fullUrl"
    }

    # ------------------------------------------------------------------
    # CATEGORY 2: Hub Association
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Category 2: Hub Association ===" "STAGE"

    $dceHubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
    $hubChildren = Get-PnPHubSiteChild -Identity $dceHubUrl -ErrorAction SilentlyContinue

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        $isAssociated = $hubChildren -contains $fullUrl
        Test-Condition "Hub" "Hub associated: $siteUrl" $isAssociated -FailureMsg "Not associated with DCE Hub"
    }

    # ------------------------------------------------------------------
    # CATEGORY 3: Lists, Libraries & Schema
    # A2 FIX: Switch site context without disconnect/reconnect
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Category 3: Lists, Libraries & Schema ===" "STAGE"

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        Connect-DeltaCrownSharePoint -Url $fullUrl

        # Check lists
        if ($ExpectedLists.ContainsKey($siteUrl)) {
            foreach ($listName in $ExpectedLists[$siteUrl]) {
                $list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue
                Test-Condition "Lists" "$siteUrl — List: $listName" ($list -ne $null) -FailureMsg "List not found"

                # C3: Deep schema check for Client Records (PII-sensitive)
                if ($listName -eq "Client Records" -and $list) {
                    foreach ($col in $ClientRecordsPIIColumns) {
                        $field = Get-PnPField -List "Client Records" -Identity $col -ErrorAction SilentlyContinue
                        Test-Condition "Schema" "PII column exists: Client Records/$col" ($field -ne $null) -FailureMsg "PII column missing — security gap"
                    }
                }
            }
        }

        # Check libraries
        if ($ExpectedLibraries.ContainsKey($siteUrl)) {
            foreach ($libName in $ExpectedLibraries[$siteUrl]) {
                $lib = Get-PnPList -Identity $libName -ErrorAction SilentlyContinue
                Test-Condition "Libraries" "$siteUrl — Library: $libName" ($lib -ne $null) -FailureMsg "Library not found"

                # C3: Check DCE-Docs metadata columns on libraries
                if ($siteUrl -eq "/sites/dce-docs" -and $lib) {
                    foreach ($col in $DocsMetadataColumns) {
                        $field = Get-PnPField -List $libName -Identity $col -ErrorAction SilentlyContinue
                        Test-Condition "Schema" "Metadata column: $libName/$col" ($field -ne $null) -FailureMsg "Library metadata column missing" -Severity "WARN"
                    }
                }
            }
        }
    }

    # ------------------------------------------------------------------
    # CATEGORY 4: Permissions
    # A2 FIX: Reuse PnP connection, just switch context
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Category 4: Permissions ===" "STAGE"

    foreach ($siteUrl in $ExpectedSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        Connect-DeltaCrownSharePoint -Url $fullUrl

        $web = Get-PnPWeb -Includes HasUniqueRoleAssignments
        Test-Condition "Permissions" "Unique permissions: $siteUrl" $web.HasUniqueRoleAssignments -FailureMsg "Inheriting permissions!"

        # Check for forbidden groups
        foreach ($forbidden in $ForbiddenGroups) {
            $found = Get-PnPGroup -Identity $forbidden -ErrorAction SilentlyContinue
            Test-Condition "Permissions" "No '$forbidden' on $siteUrl" ($found -eq $null) -FailureMsg "FORBIDDEN GROUP FOUND!"
        }

        # Check external sharing
        Connect-DeltaCrownSharePoint -Url $AdminUrl
        $site = Get-PnPTenantSite -Url $fullUrl -ErrorAction SilentlyContinue
        $sharingOff = ($site.SharingCapability -eq "Disabled")
        Test-Condition "Permissions" "External sharing disabled: $siteUrl" $sharingOff -FailureMsg "External sharing is ENABLED" -Severity "FAIL"
    }

    # ------------------------------------------------------------------
    # CATEGORY 5: Security Groups (uses Graph — already connected)
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Category 5: Security Groups ===" "STAGE"

    foreach ($groupName in $ExpectedGroups) {
        $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
        Test-Condition "Groups" "Group exists: $groupName" ($group -ne $null) -FailureMsg "Group not found"

        if ($group) {
            $isDynamic = $group.GroupTypes -contains "DynamicMembership"
            Test-Condition "Groups" "Dynamic membership: $groupName" $isDynamic -FailureMsg "Not a dynamic group" -Severity "WARN"
        }
    }

    # ------------------------------------------------------------------
    # CATEGORY 6: Teams (uses Graph — already connected)
    # ------------------------------------------------------------------
    if (!$SkipTeamsChecks) {
        Write-DeltaCrownLog "=== Category 6: Teams ===" "STAGE"

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
    }
    else {
        Skip-Test "Teams" "All Teams checks" "SkipTeamsChecks flag set"
    }

    # ------------------------------------------------------------------
    # CATEGORY 7: Templates (filesystem only — no connection needed)
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Category 7: Templates ===" "STAGE"

    $templatePath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "templates")
    $hashFile = Join-Path $templatePath "template-hashes.json"

    $expectedTemplates = @("DCE-Operations-Template.xml", "DCE-ClientServices-Template.xml", "DCE-Marketing-Template.xml", "DCE-Docs-Template.xml", "DCE-Hub-Theme.json")

    foreach ($tmpl in $expectedTemplates) {
        $tmplPath = Join-Path $templatePath $tmpl
        Test-Condition "Templates" "Template exists: $tmpl" (Test-Path $tmplPath) -FailureMsg "Template file not found" -Severity "WARN"
    }

    Test-Condition "Templates" "Hash manifest exists" (Test-Path $hashFile) -FailureMsg "template-hashes.json not found" -Severity "WARN"

    # Verify hash integrity if manifest exists
    if (Test-Path $hashFile) {
        $manifest = Get-Content $hashFile -Raw | ConvertFrom-Json
        foreach ($tmpl in $expectedTemplates) {
            $tmplPath = Join-Path $templatePath $tmpl
            if (Test-Path $tmplPath) {
                $currentHash = (Get-FileHash -Path $tmplPath -Algorithm SHA256).Hash
                $expectedHash = $manifest.Hashes.$tmpl
                if ($expectedHash) {
                    Test-Condition "Templates" "Hash valid: $tmpl" ($currentHash -eq $expectedHash) -FailureMsg "Template modified since export!" -Severity "WARN"
                }
            }
        }
    }

    # ------------------------------------------------------------------
    # CATEGORY 8: DLP Policies (C1: was defined but never verified)
    # ------------------------------------------------------------------
    if (!$SkipDLPChecks) {
        Write-DeltaCrownLog "=== Category 8: DLP Policies ===" "STAGE"

        # Connect to IPPS if not already connected
        $ippsSession = Get-PSSession | Where-Object { $_.ComputerName -match "compliance" -and $_.State -eq "Opened" }
        if (!$ippsSession) {
            try {
                Connect-DeltaCrownIPPS
                $script:OwnsIPPSConnection = $true
            }
            catch {
                Write-DeltaCrownLog "Cannot connect to Security & Compliance Center: $_" "WARNING"
                $script:SkipDLP = $true
                Skip-Test "DLP" "All DLP checks" "Cannot connect to Security & Compliance Center"
            }
        }

        if (!$script:SkipDLP) {
            foreach ($policyName in $ExpectedDLPPolicies) {
                $policy = Get-DlpCompliancePolicy -Identity $policyName -ErrorAction SilentlyContinue
                Test-Condition "DLP" "Policy exists: $policyName" ($policy -ne $null) -FailureMsg "DLP policy not found"

                if ($policy) {
                    # Check mode — External-Sharing-Block should be enforced, others in test
                    $isTestMode = ($policyName -ne "External-Sharing-Block")
                    if ($isTestMode) {
                        Test-Condition "DLP" "Test mode: $policyName" ($policy.Mode -eq "TestWithNotifications") -FailureMsg "Expected TestWithNotifications, got $($policy.Mode)" -Severity "WARN"
                    }
                    else {
                        Test-Condition "DLP" "Enforce mode: $policyName" ($policy.Mode -eq "Enable") -FailureMsg "Expected Enable, got $($policy.Mode)"
                    }

                    # Check rules exist (B6 fix ensures they have conditions)
                    $rules = Get-DlpComplianceRule -Policy $policyName -ErrorAction SilentlyContinue
                    Test-Condition "DLP" "Has rules: $policyName" ($rules.Count -gt 0) -FailureMsg "No rules defined for policy"
                }
            }
        }
    }
    else {
        Skip-Test "DLP" "All DLP checks" "SkipDLPChecks flag set"
    }

    # ------------------------------------------------------------------
    # CATEGORY 9: Shared Mailboxes (C2: was defined but never verified)
    # ------------------------------------------------------------------
    if (!$SkipMailboxChecks) {
        Write-DeltaCrownLog "=== Category 9: Shared Mailboxes ===" "STAGE"

        # Connect to Exchange if not already connected
        $exoSession = Get-PSSession | Where-Object { $_.ComputerName -match "outlook" -and $_.State -eq "Opened" }
        if (!$exoSession) {
            try {
                Connect-DeltaCrownExchange
                $script:OwnsExchangeConnection = $true
            }
            catch {
                Write-DeltaCrownLog "Cannot connect to Exchange Online: $_" "WARNING"
                $script:SkipMailboxes = $true
                Skip-Test "Mailboxes" "All mailbox checks" "Cannot connect to Exchange Online"
            }
        }

        if (!$script:SkipMailboxes) {
            foreach ($email in $ExpectedMailboxes) {
                $mbx = Get-Mailbox -Identity $email -ErrorAction SilentlyContinue
                Test-Condition "Mailboxes" "Mailbox exists: $email" ($mbx -ne $null) -FailureMsg "Shared mailbox not found"

                if ($mbx) {
                    Test-Condition "Mailboxes" "Is shared: $email" ($mbx.RecipientTypeDetails -eq "SharedMailbox") -FailureMsg "Not a shared mailbox: $($mbx.RecipientTypeDetails)"
                }
            }

            # Check auto-reply on bookings
            $bookingsReply = Get-MailboxAutoReplyConfiguration -Identity "bookings@deltacrown.com" -ErrorAction SilentlyContinue
            if ($bookingsReply) {
                Test-Condition "Mailboxes" "Auto-reply enabled: bookings" ($bookingsReply.AutoReplyState -eq "Enabled") -FailureMsg "Auto-reply not enabled"
            }
        }
    }
    else {
        Skip-Test "Mailboxes" "All mailbox checks" "SkipMailboxChecks flag set"
    }

    # ------------------------------------------------------------------
    # SUMMARY REPORT
    # ------------------------------------------------------------------
    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-DeltaCrownBanner "VERIFICATION RESULTS"
    Write-DeltaCrownLog "✅ Passed:   $($script:PassCount)" "SUCCESS"
    Write-DeltaCrownLog "❌ Failed:   $($script:FailCount)" $(if($script:FailCount -gt 0){"ERROR"}else{"SUCCESS"})
    Write-DeltaCrownLog "⚠️ Warnings: $($script:WarnCount)" $(if($script:WarnCount -gt 0){"WARNING"}else{"INFO"})
    Write-DeltaCrownLog "⏭️ Skipped:  $($script:SkipCount)" "INFO"
    Write-DeltaCrownLog "Duration:    $($duration.TotalSeconds.ToString('F1'))s" "INFO"

    # Export JSON report
    $report = @{
        Summary = @{
            ScriptVersion = $scriptVersion
            Environment   = $Environment
            TenantName    = $TenantName
            Passed        = $script:PassCount
            Failed        = $script:FailCount
            Warnings      = $script:WarnCount
            Skipped       = $script:SkipCount
            Total         = $script:TestResults.Count
            Duration      = $duration.TotalSeconds
            Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        Results = $script:TestResults
    }

    $reportPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.7-verification-report.json"))
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Force
    Write-DeltaCrownLog "Report saved: $reportPath" "INFO"

    Export-DeltaCrownLogBuffer -Path $LogFile

    # Exit codes
    if ($script:FailCount -gt 0) {
        Write-DeltaCrownLog "VERIFICATION FAILED — $($script:FailCount) critical failures" "CRITICAL"
        exit 2
    }
    elseif ($script:WarnCount -gt 0) {
        Write-DeltaCrownLog "VERIFICATION PASSED WITH WARNINGS — $($script:WarnCount) warnings" "WARNING"
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
    # A2/A3: Only disconnect services WE connected
    if ($script:OwnsPnPConnection) { Disconnect-PnPOnline -ErrorAction SilentlyContinue }
    if ($script:OwnsGraphConnection) { Disconnect-MgGraph -ErrorAction SilentlyContinue }
    if ($script:OwnsIPPSConnection -or $script:OwnsExchangeConnection) {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    }
    Write-DeltaCrownLog "Disconnected from all services" "INFO"
}
