# ============================================================================
# PHASE 5.1: Exchange Online Setup — deltacrown.com Tenant
# Delta Crown Extensions — DDGs, Shared Mailboxes, Permissions & Auto-Replies
# ============================================================================
# VERSION: 1.0.0
# DESCRIPTION: Provisions Exchange Online resources in the deltacrown.com
#              tenant (separate M365 tenant from httbrands.com). Creates
#              Dynamic Distribution Groups mirroring Azure AD groups, shared
#              mailboxes with permissions, and auto-reply configurations.
#              Supports -VerifyOnly for Phase 0 pre-flight checks.
# DEPENDS ON: Azure AD groups (DCE-AllStaff, DCE-Managers, DCE-Stylists,
#             DCE-External) already exist. At least one licensed user for
#             Exchange activation.
# ADR: ADR-002 Phase 5 — Exchange Online Integration
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="ExchangeOnlineManagement";ModuleVersion="3.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Authentication";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$VerifyOnly,
    [string]$AdminUPN = "tyler.granlund-admin@httbrands.com",
    [string]$Organization = "deltacrown.com",
    [string]$TenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30",
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development"
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.0.0"

# ============================================================================
# PATH RESOLUTION (B7: Join-Path everywhere, no backslash literals)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")
$LogPath     = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
$DocsPath    = Join-Path $ProjectRoot (Join-Path "phase3-week2" "docs")
$ResultsFile = Join-Path $DocsPath "5.1-exchange-setup-results.json"

# ============================================================================
# MODULE IMPORTS (graceful fallback if modules unavailable)
# ============================================================================
$script:HasDeltaCrownModules = $false
try {
    Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
    $script:HasDeltaCrownModules = $true
} catch {
    Write-Warning "DeltaCrown modules not found at '$ModulesPath'. Using built-in logging fallback."
}

# ============================================================================
# LOGGING FALLBACK (when DeltaCrown modules aren't available)
# ============================================================================
if (-not $script:HasDeltaCrownModules) {
    function Write-DeltaCrownLog {
        param([Parameter(Mandatory, Position = 0)] [string]$Message, [Parameter(Position = 1)] [string]$Level = "INFO")
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $color = switch ($Level) {
            "DEBUG" { "DarkGray" } "INFO" { "Cyan" } "SUCCESS" { "Green" } "WARNING" { "Yellow" }
            "ERROR" { "Red" } "CRITICAL" { "Magenta" } "STAGE" { "Blue" } default { "White" }
        }
        Write-Host "[$ts] [$Level] $Message" -ForegroundColor $color
    }
    function Write-DeltaCrownBanner {
        param([Parameter(Mandatory)] [string]$Title)
        $sep = "=" * 80
        Write-Host "`n$sep`n  $Title`n$sep" -ForegroundColor Blue
    }
    function Export-DeltaCrownLogBuffer {
        param([Parameter(Mandatory)] [string]$Path)
        # No-op in fallback — logs already written to console
    }
}

# Ensure output directories exist
@($LogPath, $DocsPath) | ForEach-Object {
    if (!(Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}
$LogFile = Join-Path $LogPath "5.1-Exchange-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Connection ownership (A3: track who owns the connection, clean up in finally)
$script:OwnsExchangeConnection = $false
$script:OwnsGraphConnection    = $false

# ============================================================================
# RESOURCE DEFINITIONS
# ============================================================================

$DynamicDistributionGroups = @(
    @{
        Name            = "DCE All Staff"
        Alias           = "allstaff"
        Email           = "allstaff@$Organization"
        RecipientFilter = "((RecipientType -eq 'UserMailbox') -and (Company -eq 'Delta Crown Extensions'))"
    },
    @{
        Name            = "DCE Managers"
        Alias           = "managers"
        Email           = "managers@$Organization"
        RecipientFilter = "((RecipientType -eq 'UserMailbox') -and (Company -eq 'Delta Crown Extensions') -and (Title -like '*Manager*'))"
    },
    @{
        Name            = "DCE Stylists"
        Alias           = "stylists"
        Email           = "stylists@$Organization"
        RecipientFilter = "((RecipientType -eq 'UserMailbox') -and (Company -eq 'Delta Crown Extensions') -and (Title -like '*Stylist*'))"
    }
)

$SharedMailboxes = @(
    @{
        Name       = "DCE Operations"
        Email      = "operations@$Organization"
        SendAs     = "DCE-AllStaff"
        FullAccess = "DCE-Managers"
        AutoReply  = $null
    },
    @{
        Name       = "DCE Bookings"
        Email      = "bookings@$Organization"
        SendAs     = "DCE-AllStaff"
        FullAccess = "DCE-AllStaff"
        AutoReply  = "Thank you for contacting Delta Crown Extensions. We will confirm your booking within 24 hours."
    },
    @{
        Name       = "DCE Info"
        Email      = "info@$Organization"
        SendAs     = "DCE-AllStaff"
        FullAccess = "DCE-Managers"
        AutoReply  = "Thank you for contacting Delta Crown Extensions. We will respond within 48 hours."
    }
)

# ============================================================================
# HELPERS: Cross-Tenant Connections
# ============================================================================
function Connect-ExchangeCrossTenant {
    $existingSession = Get-PSSession | Where-Object { $_.ComputerName -match "outlook" }
    if ($existingSession -and $existingSession.State -eq "Opened") {
        Write-DeltaCrownLog "Using pre-established Exchange Online session" "INFO"; return
    }
    Write-DeltaCrownLog "Connecting to Exchange Online -> $Organization as $AdminUPN" "INFO"
    Connect-ExchangeOnline -UserPrincipalName $AdminUPN `
        -Organization $Organization -ShowBanner:$false
    $script:OwnsExchangeConnection = $true
    Write-DeltaCrownLog "Connected to Exchange Online ($Organization)" "SUCCESS"
}

function Connect-GraphCrossTenant {
    try {
        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        if ($ctx -and $ctx.TenantId -eq $TenantId) {
            Write-DeltaCrownLog "Using pre-established Graph session (tenant $TenantId)" "INFO"; return
        }
    } catch { <# No context - connect fresh #> }
    Write-DeltaCrownLog "Connecting to Microsoft Graph -> tenant $TenantId" "INFO"
    Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" `
        -TenantId $TenantId -NoWelcome
    $script:OwnsGraphConnection = $true
    Write-DeltaCrownLog "Connected to Microsoft Graph ($TenantId)" "SUCCESS"
}

# ============================================================================
# PHASE 0: VERIFY-ONLY — Pre-flight check
# ============================================================================
function Invoke-VerifyOnly {
    Write-DeltaCrownBanner "PHASE 0: Exchange Pre-Flight Verification"
    Write-DeltaCrownLog "Mode: VerifyOnly - read-only reconnaissance" "INFO"

    $report = [ordered]@{
        Timestamp          = (Get-Date).ToString("o")
        Mode               = "VerifyOnly"
        Organization       = $Organization
        TenantId           = $TenantId
        AdminUPN           = $AdminUPN
        ExchangeActive     = $false
        ExistingMailboxes  = @()
        ExistingDDGs       = @()
        ExistingDistGroups = @()
        AzureADGroups      = @()
        LicensedUsers      = @()
        Errors             = @()
    }

    # --- Exchange Online checks ---
    try {
        Connect-ExchangeCrossTenant

        Write-DeltaCrownLog "Running Get-OrganizationConfig..." "INFO"
        $orgConfig = Get-OrganizationConfig -ErrorAction Stop
        $report.ExchangeActive = $true
        Write-DeltaCrownLog "Exchange is ACTIVE - Org: $($orgConfig.DisplayName)" "SUCCESS"

        Write-DeltaCrownLog "Listing existing mailboxes..." "INFO"
        $mailboxes = Get-Mailbox -ResultSize Unlimited -ErrorAction SilentlyContinue
        if ($mailboxes) {
            $report.ExistingMailboxes = @($mailboxes | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails)
            Write-DeltaCrownLog "  Found $($mailboxes.Count) mailbox(es)" "INFO"
            foreach ($m in $mailboxes) {
                Write-DeltaCrownLog "    - $($m.DisplayName) <$($m.PrimarySmtpAddress)> [$($m.RecipientTypeDetails)]" "INFO"
            }
        } else {
            Write-DeltaCrownLog "  No mailboxes found" "WARNING"
        }

        Write-DeltaCrownLog "Listing existing distribution groups..." "INFO"
        $distGroups = Get-DistributionGroup -ResultSize Unlimited -ErrorAction SilentlyContinue
        if ($distGroups) {
            $report.ExistingDistGroups = @($distGroups | Select-Object DisplayName, PrimarySmtpAddress)
            Write-DeltaCrownLog "  Found $($distGroups.Count) distribution group(s)" "INFO"
        } else {
            Write-DeltaCrownLog "  No distribution groups found" "INFO"
        }

        Write-DeltaCrownLog "Listing existing dynamic distribution groups..." "INFO"
        $ddgs = Get-DynamicDistributionGroup -ResultSize Unlimited -ErrorAction SilentlyContinue
        if ($ddgs) {
            $report.ExistingDDGs = @($ddgs | Select-Object DisplayName, PrimarySmtpAddress, RecipientFilter)
            Write-DeltaCrownLog "  Found $($ddgs.Count) DDG(s)" "INFO"
        } else {
            Write-DeltaCrownLog "  No dynamic distribution groups found" "INFO"
        }
    }
    catch {
        $errMsg = "Exchange check failed: $($_.Exception.Message)"
        Write-DeltaCrownLog $errMsg "ERROR"
        $report.Errors += $errMsg
    }

    # --- Microsoft Graph checks ---
    try {
        Connect-GraphCrossTenant

        Write-DeltaCrownLog "Listing DCE-* Azure AD groups..." "INFO"
        $groups = Get-MgGroup -Filter "startsWith(displayName,'DCE-')" -All -ErrorAction Stop
        if ($groups) {
            $report.AzureADGroups = @($groups | Select-Object DisplayName, Id, MailEnabled, SecurityEnabled, GroupTypes)
            Write-DeltaCrownLog "  Found $($groups.Count) DCE-* group(s)" "INFO"
            foreach ($g in $groups) {
                $mailStatus = if ($g.MailEnabled) { "Mail-Enabled" } else { "Not Mail-Enabled" }
                Write-DeltaCrownLog "    - $($g.DisplayName) [$mailStatus] (Security=$($g.SecurityEnabled))" "INFO"
            }
        } else {
            Write-DeltaCrownLog "  No DCE-* groups found - this is unexpected!" "WARNING"
        }

        Write-DeltaCrownLog "Listing licensed users..." "INFO"
        $users = Get-MgUser -All -Property DisplayName, UserPrincipalName, AssignedLicenses -ErrorAction Stop
        $licensed = @($users | Where-Object { $_.AssignedLicenses.Count -gt 0 })
        if ($licensed) {
            $report.LicensedUsers = @($licensed | Select-Object DisplayName, UserPrincipalName)
            Write-DeltaCrownLog "  Found $($licensed.Count) licensed user(s)" "INFO"
            foreach ($u in $licensed) {
                Write-DeltaCrownLog "    - $($u.DisplayName) <$($u.UserPrincipalName)>" "INFO"
            }
        } else {
            Write-DeltaCrownLog "  No licensed users found - Exchange may not activate!" "WARNING"
        }
    }
    catch {
        $errMsg = "Graph check failed: $($_.Exception.Message)"
        Write-DeltaCrownLog $errMsg "ERROR"
        $report.Errors += $errMsg
    }

    # --- Status Report ---
    Write-DeltaCrownBanner "PRE-FLIGHT REPORT"
    Write-DeltaCrownLog "Exchange Active:     $($report.ExchangeActive)" $(if ($report.ExchangeActive) { "SUCCESS" } else { "WARNING" })
    Write-DeltaCrownLog "Mailboxes Found:     $($report.ExistingMailboxes.Count)" "INFO"
    Write-DeltaCrownLog "DDGs Found:          $($report.ExistingDDGs.Count)" "INFO"
    Write-DeltaCrownLog "Azure AD Groups:     $($report.AzureADGroups.Count)" $(if ($report.AzureADGroups.Count -ge 4) { "SUCCESS" } else { "WARNING" })
    Write-DeltaCrownLog "Licensed Users:      $($report.LicensedUsers.Count)" $(if ($report.LicensedUsers.Count -gt 0) { "SUCCESS" } else { "WARNING" })
    Write-DeltaCrownLog "Errors:              $($report.Errors.Count)" $(if ($report.Errors.Count -eq 0) { "SUCCESS" } else { "ERROR" })

    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsFile -Force
    Write-DeltaCrownLog "Report saved to $ResultsFile" "INFO"

    return $report
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
try {
    Write-DeltaCrownBanner "PHASE 5.1: Exchange Online Setup - $Organization"
    Write-DeltaCrownLog "Script Version: $scriptVersion | Environment: $Environment" "INFO"
    Write-DeltaCrownLog "Organization: $Organization | Tenant: $TenantId" "INFO"
    Write-DeltaCrownLog "Admin UPN: $AdminUPN | VerifyOnly: $VerifyOnly" "INFO"

    # ------------------------------------------------------------------
    # PHASE 0: VerifyOnly — run pre-flight and bail
    # ------------------------------------------------------------------
    if ($VerifyOnly) {
        $verifyResult = Invoke-VerifyOnly
        Export-DeltaCrownLogBuffer -Path $LogFile
        return $verifyResult
    }

    # ------------------------------------------------------------------
    # FULL EXECUTION MODE
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "Mode: Full Execution" "STAGE"

    $results = [ordered]@{
        Timestamp        = (Get-Date).ToString("o")
        Mode             = "FullExecution"
        ScriptVersion    = $scriptVersion
        Environment      = $Environment
        Organization     = $Organization
        TenantId         = $TenantId
        DDGsCreated      = @()
        MailboxesCreated = @()
        PermissionsSet   = @()
        AutoRepliesSet   = @()
        Errors           = @()
        StartTime        = (Get-Date).ToString("o")
    }

    # ==================================================================
    # STEP 1: Connect to Exchange Online
    # ==================================================================
    Write-DeltaCrownBanner "STEP 1: Connect to Exchange Online"
    Connect-ExchangeCrossTenant

    # ==================================================================
    # STEP 2: Connect to Microsoft Graph
    # ==================================================================
    Write-DeltaCrownBanner "STEP 2: Connect to Microsoft Graph"
    Connect-GraphCrossTenant

    # ==================================================================
    # STEP 3: Create Dynamic Distribution Groups
    # ==================================================================
    Write-DeltaCrownBanner "STEP 3: Create Dynamic Distribution Groups"

    foreach ($ddg in $DynamicDistributionGroups) {
        Write-DeltaCrownLog "Processing DDG: $($ddg.Name) ($($ddg.Email))" "INFO"
        try {
            $existing = Get-DynamicDistributionGroup -Identity $ddg.Email -ErrorAction SilentlyContinue
            if ($existing) {
                Write-DeltaCrownLog "  DDG already exists: $($ddg.Email) - skipping" "WARNING"
                $results.DDGsCreated += @{ Name = $ddg.Name; Email = $ddg.Email; Status = "AlreadyExists" }
                continue
            }
            if ($PSCmdlet.ShouldProcess($ddg.Email, "Create Dynamic Distribution Group")) {
                New-DynamicDistributionGroup `
                    -Name $ddg.Name `
                    -Alias $ddg.Alias `
                    -PrimarySmtpAddress $ddg.Email `
                    -RecipientFilter $ddg.RecipientFilter
                Write-DeltaCrownLog "  Created DDG: $($ddg.Email)" "SUCCESS"
                $results.DDGsCreated += @{
                    Name = $ddg.Name; Email = $ddg.Email
                    RecipientFilter = $ddg.RecipientFilter; Status = "Created"
                }
            }
        }
        catch {
            $errMsg = "Failed to create DDG $($ddg.Name): $($_.Exception.Message)"
            Write-DeltaCrownLog "  $errMsg" "ERROR"
            $results.Errors += $errMsg
        }
    }

    # ==================================================================
    # STEP 4: Create Shared Mailboxes with Permissions
    # ==================================================================
    Write-DeltaCrownBanner "STEP 4: Create Shared Mailboxes"

    foreach ($mbx in $SharedMailboxes) {
        Write-DeltaCrownLog "Processing mailbox: $($mbx.Name) ($($mbx.Email))" "INFO"
        try {
            # --- Create shared mailbox (idempotent) ---
            $existing = Get-Mailbox -Identity $mbx.Email -ErrorAction SilentlyContinue
            if ($existing) {
                Write-DeltaCrownLog "  Mailbox already exists: $($mbx.Email) - skipping creation" "WARNING"
            } else {
                if ($PSCmdlet.ShouldProcess($mbx.Email, "Create shared mailbox")) {
                    New-Mailbox -Shared -Name $mbx.Name -PrimarySmtpAddress $mbx.Email
                    Write-DeltaCrownLog "  Created mailbox: $($mbx.Email)" "SUCCESS"
                    Write-DeltaCrownLog "  Waiting 10s for provisioning..." "INFO"
                    Start-Sleep -Seconds 10
                }
            }
            $results.MailboxesCreated += @{
                Name = $mbx.Name; Email = $mbx.Email
                Status = if ($existing) { "AlreadyExists" } else { "Created" }
            }

            # --- Grant Send-As permission ---
            if ($PSCmdlet.ShouldProcess("$($mbx.SendAs) -> $($mbx.Email)", "Grant Send-As")) {
                try {
                    Add-RecipientPermission -Identity $mbx.Email `
                        -Trustee $mbx.SendAs -AccessRights SendAs `
                        -Confirm:$false -ErrorAction Stop
                    Write-DeltaCrownLog "  Send-As granted to: $($mbx.SendAs)" "SUCCESS"
                    $results.PermissionsSet += "$($mbx.Email):SendAs:$($mbx.SendAs)"
                }
                catch {
                    if ($_.Exception.Message -match "already exists|already present") {
                        Write-DeltaCrownLog "  Send-As already granted to $($mbx.SendAs)" "WARNING"
                    } else { throw }
                }
            }

            # --- Grant Full Access permission ---
            if ($PSCmdlet.ShouldProcess("$($mbx.FullAccess) -> $($mbx.Email)", "Grant Full Access")) {
                try {
                    Add-MailboxPermission -Identity $mbx.Email `
                        -User $mbx.FullAccess -AccessRights FullAccess `
                        -AutoMapping $true -ErrorAction Stop
                    Write-DeltaCrownLog "  Full Access granted to: $($mbx.FullAccess)" "SUCCESS"
                    $results.PermissionsSet += "$($mbx.Email):FullAccess:$($mbx.FullAccess)"
                }
                catch {
                    if ($_.Exception.Message -match "already exists|already present") {
                        Write-DeltaCrownLog "  Full Access already granted to $($mbx.FullAccess)" "WARNING"
                    } else { throw }
                }
            }
        }
        catch {
            $errMsg = "Failed to process mailbox $($mbx.Email): $($_.Exception.Message)"
            Write-DeltaCrownLog "  $errMsg" "ERROR"
            $results.Errors += $errMsg
        }
    }

    # ==================================================================
    # STEP 5: Configure Auto-Replies
    # ==================================================================
    Write-DeltaCrownBanner "STEP 5: Configure Auto-Replies"

    foreach ($mbx in $SharedMailboxes) {
        if (-not $mbx.AutoReply) {
            Write-DeltaCrownLog "  $($mbx.Name): No auto-reply configured (by design)" "INFO"
            continue
        }
        Write-DeltaCrownLog "Configuring auto-reply for $($mbx.Email)..." "INFO"
        try {
            if ($PSCmdlet.ShouldProcess($mbx.Email, "Set auto-reply")) {
                Set-MailboxAutoReplyConfiguration -Identity $mbx.Email `
                    -AutoReplyState Enabled -ExternalAudience All `
                    -InternalMessage $mbx.AutoReply -ExternalMessage $mbx.AutoReply
                Write-DeltaCrownLog "  Auto-reply set for $($mbx.Email)" "SUCCESS"
                $results.AutoRepliesSet += $mbx.Email
            }
        }
        catch {
            $errMsg = "Failed to set auto-reply for $($mbx.Email): $($_.Exception.Message)"
            Write-DeltaCrownLog "  $errMsg" "ERROR"
            $results.Errors += $errMsg
        }
    }

    # ==================================================================
    # STEP 6: Verification Sweep
    # ==================================================================
    Write-DeltaCrownBanner "STEP 6: Verification Sweep"

    Write-DeltaCrownLog "Verifying Dynamic Distribution Groups..." "STAGE"
    $allDDGs = Get-DynamicDistributionGroup -ResultSize Unlimited -ErrorAction SilentlyContinue
    if ($allDDGs) {
        foreach ($d in $allDDGs) {
            Write-DeltaCrownLog "  DDG: $($d.DisplayName) <$($d.PrimarySmtpAddress)>" "SUCCESS"
            Write-DeltaCrownLog "    Filter: $($d.RecipientFilter)" "INFO"
        }
    } else {
        Write-DeltaCrownLog "  No DDGs found - something may have gone wrong" "WARNING"
    }

    Write-DeltaCrownLog "Verifying Shared Mailboxes..." "STAGE"
    foreach ($mbx in $SharedMailboxes) {
        $box = Get-Mailbox -Identity $mbx.Email -ErrorAction SilentlyContinue
        if ($box) {
            Write-DeltaCrownLog "  Mailbox: $($box.DisplayName) <$($box.PrimarySmtpAddress)> [$($box.RecipientTypeDetails)]" "SUCCESS"

            $sendAsPerms = Get-RecipientPermission -Identity $mbx.Email -ErrorAction SilentlyContinue |
                Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" }
            foreach ($p in $sendAsPerms) {
                Write-DeltaCrownLog "    Send-As: $($p.Trustee)" "INFO"
            }

            $fullAccessPerms = Get-MailboxPermission -Identity $mbx.Email -ErrorAction SilentlyContinue |
                Where-Object { $_.User -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false }
            foreach ($p in $fullAccessPerms) {
                Write-DeltaCrownLog "    Full Access: $($p.User)" "INFO"
            }

            if ($mbx.AutoReply) {
                $arConfig = Get-MailboxAutoReplyConfiguration -Identity $mbx.Email -ErrorAction SilentlyContinue
                Write-DeltaCrownLog "    Auto-Reply: $($arConfig.AutoReplyState)" "INFO"
            }
        } else {
            Write-DeltaCrownLog "  Mailbox NOT FOUND: $($mbx.Email)" "ERROR"
        }
    }

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = (Get-Date).ToString("o")
    $startDt = [datetime]::Parse($results.StartTime)
    $duration = (Get-Date) - $startDt

    Write-DeltaCrownBanner "PHASE 5.1 COMPLETE"
    Write-DeltaCrownLog "DDGs created:       $($results.DDGsCreated.Count)/$($DynamicDistributionGroups.Count)" "SUCCESS"
    Write-DeltaCrownLog "Mailboxes created:  $($results.MailboxesCreated.Count)/$($SharedMailboxes.Count)" "SUCCESS"
    Write-DeltaCrownLog "Permissions set:    $($results.PermissionsSet.Count)" "SUCCESS"
    Write-DeltaCrownLog "Auto-replies set:   $($results.AutoRepliesSet.Count)" "SUCCESS"
    Write-DeltaCrownLog "Errors:             $($results.Errors.Count)" $(if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "ERROR" })
    Write-DeltaCrownLog "Duration:           $($duration.ToString('mm\:ss'))" "INFO"

    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsFile -Force
    Write-DeltaCrownLog "Results saved to $ResultsFile" "INFO"
    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        DDGsCreated      = $results.DDGsCreated
        MailboxesCreated = $results.MailboxesCreated
        PermissionsSet   = $results.PermissionsSet
        AutoRepliesSet   = $results.AutoRepliesSet
        Errors           = $results.Errors
        Duration         = $duration
        Status           = if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 5.1: $($_.Exception.Message)" "CRITICAL"
    Write-DeltaCrownLog "Stack: $($_.ScriptStackTrace)" "ERROR"
    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    if ($script:OwnsExchangeConnection) {
        Write-DeltaCrownLog "Disconnecting from Exchange Online (owned connection)..." "INFO"
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    }
    if ($script:OwnsGraphConnection) {
        Write-DeltaCrownLog "Disconnecting from Microsoft Graph (owned connection)..." "INFO"
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}
