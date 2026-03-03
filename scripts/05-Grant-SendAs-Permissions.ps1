<#
.SYNOPSIS
    Grants Send-As and Full Access permissions on shared mailboxes.
.DESCRIPTION
    Reads config/mailbox-provisioning.csv and grants Send-As and Full Access (with AutoMapping)
    permissions to specified users on each shared mailbox in the DCE tenant.
.EXAMPLE
    .\05-Grant-SendAs-Permissions.ps1
    .\05-Grant-SendAs-Permissions.ps1 -WhatIf
#>

#Requires -Version 7.0

param(
    [switch]$WhatIf
)

# Load config
$configPath = Join-Path $PSScriptRoot "..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$targetTenant = $config.tenants.target

$csvPath = Join-Path $PSScriptRoot "..\config\mailbox-provisioning.csv"
if (-not (Test-Path $csvPath)) {
    Write-Host "[ERROR] Mailbox provisioning CSV not found: $csvPath" -ForegroundColor Red
    exit 1
}

$mailboxes = Import-Csv $csvPath
if ($mailboxes.Count -eq 0) {
    Write-Host "[WARN] No entries in mailbox provisioning CSV" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n=== Grant Send-As & Full Access Permissions — $($targetTenant.name) ===" -ForegroundColor Cyan

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online ($($targetTenant.domain))..." -ForegroundColor Yellow
Connect-ExchangeOnline -Organization $targetTenant.domain -ShowBanner:$false
Write-Host "[OK] Connected" -ForegroundColor Green

$results = @()

foreach ($mb in $mailboxes) {
    Write-Host "`nMailbox: $($mb.SharedMailboxEmail)" -ForegroundColor Cyan

    # Verify mailbox exists
    $existing = $null
    try {
        $existing = Get-Mailbox -Identity $mb.SharedMailboxEmail -ErrorAction SilentlyContinue
    } catch {}

    if (-not $existing) {
        Write-Host "  [SKIP] Mailbox does not exist — run 04-Create-SharedMailboxes.ps1 first" -ForegroundColor Red
        continue
    }

    # Process Send-As users (semicolon-delimited)
    if ($mb.SendAsUser -and $mb.SendAsUser.Trim() -ne "") {
        $sendAsUsers = $mb.SendAsUser -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

        foreach ($user in $sendAsUsers) {
            Write-Host "  Granting Send-As to: $user" -ForegroundColor Yellow
            if (-not $WhatIf) {
                try {
                    Add-RecipientPermission $mb.SharedMailboxEmail -AccessRights SendAs -Trustee $user -Confirm:$false
                    Write-Host "  [OK] Send-As granted" -ForegroundColor Green
                    $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "SendAs"; Status = "Granted" }
                } catch {
                    if ($_.Exception.Message -like "*already exists*") {
                        Write-Host "  [SKIP] Send-As already granted" -ForegroundColor Cyan
                        $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "SendAs"; Status = "Already Exists" }
                    } else {
                        Write-Host "  [ERROR] $_" -ForegroundColor Red
                        $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "SendAs"; Status = "ERROR" }
                    }
                }
            } else {
                Write-Host "  [WHATIF] Would grant Send-As" -ForegroundColor Magenta
                $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "SendAs"; Status = "WhatIf" }
            }
        }
    }

    # Process Full Access users (semicolon-delimited)
    if ($mb.FullAccessUser -and $mb.FullAccessUser.Trim() -ne "") {
        $fullAccessUsers = $mb.FullAccessUser -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

        foreach ($user in $fullAccessUsers) {
            Write-Host "  Granting Full Access (AutoMapping) to: $user" -ForegroundColor Yellow
            if (-not $WhatIf) {
                try {
                    Add-MailboxPermission $mb.SharedMailboxEmail -User $user -AccessRights FullAccess -AutoMapping $true -Confirm:$false
                    Write-Host "  [OK] Full Access granted" -ForegroundColor Green
                    $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "FullAccess"; Status = "Granted" }
                } catch {
                    if ($_.Exception.Message -like "*already has*") {
                        Write-Host "  [SKIP] Full Access already granted" -ForegroundColor Cyan
                        $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "FullAccess"; Status = "Already Exists" }
                    } else {
                        Write-Host "  [ERROR] $_" -ForegroundColor Red
                        $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "FullAccess"; Status = "ERROR" }
                    }
                }
            } else {
                Write-Host "  [WHATIF] Would grant Full Access" -ForegroundColor Magenta
                $results += [PSCustomObject]@{ Mailbox = $mb.SharedMailboxEmail; User = $user; Permission = "FullAccess"; Status = "WhatIf" }
            }
        }
    }
}

# Results summary
Write-Host "`n=== Permission Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Next step: Run 06-Create-Groups.ps1 to create M365 Groups" -ForegroundColor Gray
Write-Host ""
