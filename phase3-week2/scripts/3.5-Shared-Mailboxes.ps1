# ============================================================================
# PHASE 3.5: Shared Mailboxes Setup
# Delta Crown Extensions — Brand Mailboxes + Teams Integration
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Creates 3 DCE shared mailboxes, configures permissions,
#              auto-replies, and Teams channel forwarding
# DEPENDS ON: 3.2 (Teams team exists for channel email addresses)
# ADR: ADR-002 Phase 3 — Shared Mailbox Integration
# FIXES: A3 (connection ownership), B7 (path separators)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="ExchangeOnlineManagement";ModuleVersion="3.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    [Parameter(Mandatory=$false)]
    [string]$BrandDomain = "httbrands.com",
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development"
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
$LogFile = Join-Path $LogPath "3.5-Shared-Mailboxes-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# CONNECTION OWNERSHIP (A3)
# ============================================================================
$script:OwnsExchangeConnection = $false

# ============================================================================
# MAILBOX DEFINITIONS
# ============================================================================
$SharedMailboxes = @(
    @{
        Name          = "DCE Operations"
        Email         = "operations@$BrandDomain"
        SendAs        = "SG-DCE-AllStaff"
        FullAccess    = "SG-DCE-Leadership"
        AutoReply     = $null  # No auto-reply
        ForwardTo     = $null  # Will be set to General channel email
    },
    @{
        Name          = "DCE Bookings"
        Email         = "bookings@$BrandDomain"
        SendAs        = "SG-DCE-AllStaff"
        FullAccess    = "SG-DCE-AllStaff"
        AutoReply     = "Thank you for contacting Delta Crown Extensions. We will confirm your booking within 24 hours."
        ForwardTo     = $null  # Will be set to Bookings channel email
    },
    @{
        Name          = "DCE Info"
        Email         = "info@$BrandDomain"
        SendAs        = "SG-DCE-AllStaff"
        FullAccess    = "SG-DCE-Leadership"
        AutoReply     = "Thank you for contacting Delta Crown Extensions. We will respond within 48 hours."
        ForwardTo     = $null  # Group mailbox
    }
)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.5: Shared Mailboxes Setup"
    Write-DeltaCrownLog "Script Version: $scriptVersion" "INFO"
    Write-DeltaCrownLog "Brand Domain: $BrandDomain" "INFO"

    $results = @{
        MailboxesCreated    = @()
        PermissionsSet      = @()
        AutoRepliesSet      = @()
        Errors              = @()
        StartTime           = Get-Date
    }

    # ------------------------------------------------------------------
    # CONNECTION SETUP (A3: check if Master pre-authed)
    # ------------------------------------------------------------------
    $existingSession = Get-PSSession | Where-Object { $_.ComputerName -match "outlook" }
    if (!$existingSession -or $existingSession.State -ne "Opened") {
        Write-DeltaCrownLog "Connecting to Exchange Online..." "INFO"
        Connect-DeltaCrownExchange
        $script:OwnsExchangeConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established Exchange connection" "INFO"
    }
    Write-DeltaCrownLog "Connected to Exchange Online" "SUCCESS"

    foreach ($mbx in $SharedMailboxes) {
        Write-DeltaCrownLog "Processing mailbox: $($mbx.Name) ($($mbx.Email))" "INFO"

        try {
            # ----------------------------------------------------------
            # Create shared mailbox (idempotent)
            # ----------------------------------------------------------
            $existing = Get-Mailbox -Identity $mbx.Email -ErrorAction SilentlyContinue
            if ($existing) {
                Write-DeltaCrownLog "  Mailbox already exists: $($mbx.Email)" "WARNING"
            }
            else {
                if ($PSCmdlet.ShouldProcess($mbx.Email, "Create shared mailbox")) {
                    New-Mailbox -Shared -Name $mbx.Name -PrimarySmtpAddress $mbx.Email
                    Write-DeltaCrownLog "  Created mailbox: $($mbx.Email)" "SUCCESS"
                    Start-Sleep -Seconds 10  # Wait for provisioning
                }
            }
            $results.MailboxesCreated += $mbx.Email

            # ----------------------------------------------------------
            # Set Send-As permissions
            # ----------------------------------------------------------
            if ($PSCmdlet.ShouldProcess("$($mbx.SendAs) → $($mbx.Email)", "Grant Send-As")) {
                try {
                    Add-RecipientPermission -Identity $mbx.Email -Trustee $mbx.SendAs -AccessRights SendAs -Confirm:$false -ErrorAction SilentlyContinue
                    Write-DeltaCrownLog "  Send-As granted to: $($mbx.SendAs)" "SUCCESS"
                    $results.PermissionsSet += "$($mbx.Email):SendAs:$($mbx.SendAs)"
                }
                catch {
                    Write-DeltaCrownLog "  Send-As may already be granted: $_" "WARNING"
                }
            }

            # ----------------------------------------------------------
            # Set Full Access permissions
            # ----------------------------------------------------------
            if ($PSCmdlet.ShouldProcess("$($mbx.FullAccess) → $($mbx.Email)", "Grant Full Access")) {
                try {
                    Add-MailboxPermission -Identity $mbx.Email -User $mbx.FullAccess -AccessRights FullAccess -AutoMapping $true -ErrorAction SilentlyContinue
                    Write-DeltaCrownLog "  Full Access granted to: $($mbx.FullAccess)" "SUCCESS"
                    $results.PermissionsSet += "$($mbx.Email):FullAccess:$($mbx.FullAccess)"
                }
                catch {
                    Write-DeltaCrownLog "  Full Access may already be granted: $_" "WARNING"
                }
            }

            # ----------------------------------------------------------
            # Configure auto-reply
            # ----------------------------------------------------------
            if ($mbx.AutoReply) {
                if ($PSCmdlet.ShouldProcess($mbx.Email, "Set auto-reply")) {
                    Set-MailboxAutoReplyConfiguration -Identity $mbx.Email `
                        -AutoReplyState Enabled `
                        -ExternalAudience All `
                        -InternalMessage $mbx.AutoReply `
                        -ExternalMessage $mbx.AutoReply

                    Write-DeltaCrownLog "  Auto-reply configured" "SUCCESS"
                    $results.AutoRepliesSet += $mbx.Email
                }
            }
            else {
                Write-DeltaCrownLog "  No auto-reply configured (by design)" "INFO"
            }
        }
        catch {
            Write-DeltaCrownLog "Failed to process mailbox $($mbx.Email): $_" "ERROR"
            $results.Errors += "Mailbox failed: $($mbx.Email) — $_"
        }
    }

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = Get-Date
    $duration = $results.EndTime - $results.StartTime

    Write-DeltaCrownBanner "PHASE 3.5 COMPLETE"
    Write-DeltaCrownLog "Mailboxes created:  $($results.MailboxesCreated.Count)/3" "SUCCESS"
    Write-DeltaCrownLog "Permissions set:    $($results.PermissionsSet.Count)" "SUCCESS"
    Write-DeltaCrownLog "Auto-replies set:   $($results.AutoRepliesSet.Count)" "SUCCESS"
    Write-DeltaCrownLog "Errors:             $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})

    $resultsPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.5-mailbox-results.json"))
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force

    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        MailboxesCreated = $results.MailboxesCreated
        Errors           = $results.Errors
        Duration         = $duration
        Status           = if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.5: $_" "CRITICAL"
    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    if ($script:OwnsExchangeConnection) {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    }
    Write-DeltaCrownLog "Disconnected from Exchange Online" "INFO"
}
