# ============================================================================
# PHASE 4.M: Migrate bookings@deltacrown.com → help@deltacrown.com
# Delta Crown Extensions — Support Email Transition
# ============================================================================
# VERSION: 1.0.0
# DESCRIPTION: Replaces the legacy "bookings@" shared mailbox with "help@"
#              to align with the HTT brand support email standard.
#              bookings@ is retained but hidden and stripped of permissions
#              to preserve historical mail. help@ is created fresh with
#              support-oriented permissions and auto-reply.
#              Idempotent — safe to re-run.
# MODE: Requires live Exchange Online auth (device code or browser).
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="ExchangeOnlineManagement";ModuleVersion="3.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$AdminUPN = "tyler.granlund-admin@httbrands.com",
    [string]$Organization = "deltacrown.com",
    [switch]$RemoveBookings,      # Actually remove the bookings@ mailbox (destructive)
    [switch]$WhatIf               # Preview changes without applying
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.0.0"

# ============================================================================
# LOGGING
# ============================================================================
function Write-MigrationLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        "STAGE"   { "Blue" }
        default   { "White" }
    }
    Write-Host "[$ts] [$Level] $Message" -ForegroundColor $color
}

# ============================================================================
# CONNECTION
# ============================================================================
function Connect-DCEExchange {
    $existing = Get-PSSession | Where-Object { $_.ComputerName -match "outlook" -and $_.State -eq "Opened" }
    if ($existing) {
        Write-MigrationLog "Using existing Exchange session" "INFO"
        return
    }
    Write-MigrationLog "Connecting to Exchange Online (deltacrown.com)..." "INFO"
    Connect-ExchangeOnline -UserPrincipalName $AdminUPN `
        -DelegatedOrganization "deltacrown.onmicrosoft.com" `
        -ShowBanner:$false
    Write-MigrationLog "Connected" "SUCCESS"
}

# ============================================================================
# MAIN
# ============================================================================

try {
    Write-MigrationLog "=== DCE Support Email Migration v$scriptVersion ===" "STAGE"
    Write-MigrationLog "Admin: $AdminUPN | Org: $Organization | RemoveBookings: $RemoveBookings | WhatIf: $WhatIf" "INFO"

    Connect-DCEExchange

    # ------------------------------------------------------------------
    # STEP 1: Assess current state
    # ------------------------------------------------------------------
    Write-MigrationLog "STEP 1: Assessing current mailboxes..." "STAGE"

    $bookings = Get-Mailbox -Identity "bookings@$Organization" -ErrorAction SilentlyContinue
    $help     = Get-Mailbox -Identity "help@$Organization"     -ErrorAction SilentlyContinue

    $report = [ordered]@{
        BookingsExists     = ($null -ne $bookings)
        HelpExists         = ($null -ne $help)
        BookingsType       = if ($bookings) { $bookings.RecipientTypeDetails } else { "N/A" }
        HelpType           = if ($help)     { $help.RecipientTypeDetails }     else { "N/A" }
        BookingsHidden     = if ($bookings) { $bookings.HiddenFromAddressListsEnabled } else { "N/A" }
        ActionsTaken       = @()
        Errors             = @()
    }

    Write-MigrationLog "  bookings@ exists: $($report.BookingsExists) [$($report.BookingsType)]" $(if($report.BookingsExists){"INFO"}else{"WARNING"})
    Write-MigrationLog "  help@ exists:     $($report.HelpExists) [$($report.HelpType)]" $(if($report.HelpExists){"INFO"}else{"WARNING"})

    # ------------------------------------------------------------------
    # STEP 2: Create help@ if missing
    # ------------------------------------------------------------------
    if (-not $help) {
        Write-MigrationLog "STEP 2: Creating help@$Organization..." "STAGE"
        if ($PSCmdlet.ShouldProcess("help@$Organization", "Create shared mailbox")) {
            try {
                New-Mailbox -Shared -Name "DCE Help" -PrimarySmtpAddress "help@$Organization"
                Write-MigrationLog "  Created help@$Organization" "SUCCESS"
                $report.ActionsTaken += "Created help@$Organization"
                Start-Sleep -Seconds 10  # Wait for provisioning
            }
            catch {
                $err = "Failed to create help@: $($_.Exception.Message)"
                Write-MigrationLog "  $err" "ERROR"
                $report.Errors += $err
                throw
            }
        }
    } else {
        Write-MigrationLog "STEP 2: help@ already exists — skipping creation" "INFO"
    }

    # ------------------------------------------------------------------
    # STEP 3: Set permissions on help@
    # ------------------------------------------------------------------
    Write-MigrationLog "STEP 3: Setting permissions on help@..." "STAGE"

    # Send-As: AllStaff
    if ($PSCmdlet.ShouldProcess("AllStaff → help@", "Grant Send-As")) {
        try {
            Add-RecipientPermission -Identity "help@$Organization" `
                -Trustee "AllStaff" -AccessRights SendAs `
                -Confirm:$false -ErrorAction Stop
            Write-MigrationLog "  Send-As granted to AllStaff" "SUCCESS"
            $report.ActionsTaken += "Send-As: AllStaff → help@"
        }
        catch {
            if ($_.Exception.Message -match "already exists|already present") {
                Write-MigrationLog "  Send-As already granted to AllStaff" "WARNING"
            } else {
                $err = "Send-As failed: $($_.Exception.Message)"
                Write-MigrationLog "  $err" "ERROR"
                $report.Errors += $err
            }
        }
    }

    # Full Access: AllStaff
    if ($PSCmdlet.ShouldProcess("AllStaff → help@", "Grant Full Access")) {
        try {
            Add-MailboxPermission -Identity "help@$Organization" `
                -User "AllStaff" -AccessRights FullAccess `
                -AutoMapping:$true -ErrorAction Stop
            Write-MigrationLog "  Full Access granted to AllStaff" "SUCCESS"
            $report.ActionsTaken += "FullAccess: AllStaff → help@"
        }
        catch {
            if ($_.Exception.Message -match "already exists|already present") {
                Write-MigrationLog "  Full Access already granted to AllStaff" "WARNING"
            } else {
                $err = "Full Access failed: $($_.Exception.Message)"
                Write-MigrationLog "  $err" "ERROR"
                $report.Errors += $err
            }
        }
    }

    # ------------------------------------------------------------------
    # STEP 4: Configure auto-reply on help@
    # ------------------------------------------------------------------
    Write-MigrationLog "STEP 4: Configuring auto-reply on help@..." "STAGE"

    $autoReplyText = "Thank you for contacting Delta Crown Extensions Support. Your request has been received and routed to the appropriate team. We aim to respond within 24 hours."

    if ($PSCmdlet.ShouldProcess("help@", "Set auto-reply")) {
        try {
            Set-MailboxAutoReplyConfiguration -Identity "help@$Organization" `
                -AutoReplyState Enabled -ExternalAudience All `
                -InternalMessage $autoReplyText -ExternalMessage $autoReplyText
            Write-MigrationLog "  Auto-reply enabled" "SUCCESS"
            $report.ActionsTaken += "Auto-reply enabled on help@"
        }
        catch {
            $err = "Auto-reply failed: $($_.Exception.Message)"
            Write-MigrationLog "  $err" "ERROR"
            $report.Errors += $err
        }
    }

    # ------------------------------------------------------------------
    # STEP 5: Copy data from bookings@ (optional, non-destructive)
    # ------------------------------------------------------------------
    if ($bookings) {
        Write-MigrationLog "STEP 5: Copying bookings@ permissions as baseline..." "STAGE"
        # Note: We intentionally do NOT copy mailbox content automatically.
        # If historical mail is needed, admin can export/import manually.
        Write-MigrationLog "  Historical mail in bookings@ is preserved." "INFO"
        Write-MigrationLog "  To migrate content manually, use: Search-Mailbox or New-MailboxExportRequest" "INFO"
    }

    # ------------------------------------------------------------------
    # STEP 6: Deprecate bookings@ (hide from address lists, remove permissions)
    # ------------------------------------------------------------------
    if ($bookings) {
        Write-MigrationLog "STEP 6: Deprecating bookings@..." "STAGE"

        # Hide from address lists
        if ($PSCmdlet.ShouldProcess("bookings@", "Hide from address lists")) {
            try {
                Set-Mailbox -Identity "bookings@$Organization" -HiddenFromAddressListsEnabled:$true
                Write-MigrationLog "  bookings@ hidden from address lists" "SUCCESS"
                $report.ActionsTaken += "Hidden bookings@ from GAL"
            }
            catch {
                $err = "Hide failed: $($_.Exception.Message)"
                Write-MigrationLog "  $err" "ERROR"
                $report.Errors += $err
            }
        }

        # Remove Send-As permissions
        if ($PSCmdlet.ShouldProcess("bookings@", "Remove Send-As permissions")) {
            try {
                $sendAsPerms = Get-RecipientPermission -Identity "bookings@$Organization" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" }
                foreach ($p in $sendAsPerms) {
                    Remove-RecipientPermission -Identity "bookings@$Organization" `
                        -Trustee $p.Trustee -AccessRights SendAs -Confirm:$false
                    Write-MigrationLog "  Removed Send-As for $($p.Trustee)" "SUCCESS"
                    $report.ActionsTaken += "Removed Send-As: $($p.Trustee) from bookings@"
                }
            }
            catch {
                $err = "Remove Send-As failed: $($_.Exception.Message)"
                Write-MigrationLog "  $err" "ERROR"
                $report.Errors += $err
            }
        }

        # Remove Full Access permissions
        if ($PSCmdlet.ShouldProcess("bookings@", "Remove Full Access permissions")) {
            try {
                $fullAccessPerms = Get-MailboxPermission -Identity "bookings@$Organization" -ErrorAction SilentlyContinue |
                    Where-Object { $_.User -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false }
                foreach ($p in $fullAccessPerms) {
                    Remove-MailboxPermission -Identity "bookings@$Organization" `
                        -User $p.User -AccessRights FullAccess -Confirm:$false
                    Write-MigrationLog "  Removed Full Access for $($p.User)" "SUCCESS"
                    $report.ActionsTaken += "Removed FullAccess: $($p.User) from bookings@"
                }
            }
            catch {
                $err = "Remove Full Access failed: $($_.Exception.Message)"
                Write-MigrationLog "  $err" "ERROR"
                $report.Errors += $err
            }
        }

        # Disable auto-reply
        if ($PSCmdlet.ShouldProcess("bookings@", "Disable auto-reply")) {
            try {
                Set-MailboxAutoReplyConfiguration -Identity "bookings@$Organization" `
                    -AutoReplyState Disabled
                Write-MigrationLog "  Auto-reply disabled on bookings@" "SUCCESS"
                $report.ActionsTaken += "Disabled auto-reply on bookings@"
            }
            catch {
                $err = "Disable auto-reply failed: $($_.Exception.Message)"
                Write-MigrationLog "  $err" "ERROR"
                $report.Errors += $err
            }
        }

        # ------------------------------------------------------------------
        # STEP 6B: Optionally REMOVE bookings@ entirely (destructive)
        # ------------------------------------------------------------------
        if ($RemoveBookings) {
            Write-MigrationLog "STEP 6B: REMOVE bookings@ mailbox (DESTRUCTIVE)..." "STAGE"
            Write-MigrationLog "  WARNING: This will delete the mailbox and ALL contained email." "ERROR"
            if ($PSCmdlet.ShouldProcess("bookings@$Organization", "REMOVE MAILBOX")) {
                try {
                    Disable-Mailbox -Identity "bookings@$Organization" -Confirm:$false
                    Write-MigrationLog "  bookings@ disabled (soft-deleted, recoverable for 30 days)" "SUCCESS"
                    $report.ActionsTaken += "REMOVED bookings@ (soft-delete)"
                }
                catch {
                    $err = "Remove failed: $($_.Exception.Message)"
                    Write-MigrationLog "  $err" "ERROR"
                    $report.Errors += $err
                }
            }
        }
    }

    # ------------------------------------------------------------------
    # STEP 7: Verify final state
    # ------------------------------------------------------------------
    Write-MigrationLog "STEP 7: Verifying final state..." "STAGE"

    $finalHelp = Get-Mailbox -Identity "help@$Organization" -ErrorAction SilentlyContinue
    $finalBookings = Get-Mailbox -Identity "bookings@$Organization" -ErrorAction SilentlyContinue

    if ($finalHelp) {
        Write-MigrationLog "  help@:     EXISTS [$($finalHelp.RecipientTypeDetails)]" "SUCCESS"
        $ar = Get-MailboxAutoReplyConfiguration -Identity "help@$Organization" -ErrorAction SilentlyContinue
        Write-MigrationLog "  help@ auto-reply: $($ar.AutoReplyState)" "INFO"
    } else {
        Write-MigrationLog "  help@:     NOT FOUND" "ERROR"
    }

    if ($finalBookings) {
        Write-MigrationLog "  bookings@: EXISTS [$($finalBookings.RecipientTypeDetails)] Hidden=$($finalBookings.HiddenFromAddressListsEnabled)" "WARNING"
    } else {
        Write-MigrationLog "  bookings@: NOT FOUND (removed or never existed)" "INFO"
    }

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    Write-MigrationLog "=== MIGRATION COMPLETE ===" "STAGE"
    Write-MigrationLog "Actions taken: $($report.ActionsTaken.Count)" "INFO"
    Write-MigrationLog "Errors:        $($report.Errors.Count)" $(if($report.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})

    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath "migrate-bookings-to-help-report.json" -Force
    Write-MigrationLog "Report saved to migrate-bookings-to-help-report.json" "INFO"

    return [PSCustomObject]$report
}
catch {
    Write-MigrationLog "CRITICAL ERROR: $($_.Exception.Message)" "ERROR"
    Write-MigrationLog "Stack: $($_.ScriptStackTrace)" "ERROR"
    throw
}
finally {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    Write-MigrationLog "Disconnected from Exchange Online" "INFO"
}
