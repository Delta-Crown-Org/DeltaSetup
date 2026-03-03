<#
.SYNOPSIS
    Creates shared mailboxes in the DCE tenant from the provisioning CSV.
.DESCRIPTION
    Reads config/mailbox-provisioning.csv and creates shared mailboxes in Exchange Online
    for the Delta Crown Extensions tenant. Shared mailboxes are free (no license needed).
.EXAMPLE
    .\04-Create-SharedMailboxes.ps1
    .\04-Create-SharedMailboxes.ps1 -WhatIf
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
    Write-Host "Create it with columns: DisplayName, SharedMailboxEmail, SendAsUser, FullAccessUser" -ForegroundColor Gray
    exit 1
}

$mailboxes = Import-Csv $csvPath
if ($mailboxes.Count -eq 0) {
    Write-Host "[WARN] No entries in mailbox provisioning CSV" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n=== Create Shared Mailboxes — $($targetTenant.name) ===" -ForegroundColor Cyan
Write-Host "Mailboxes to process: $($mailboxes.Count)" -ForegroundColor Gray

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online ($($targetTenant.domain))..." -ForegroundColor Yellow
try {
    Connect-ExchangeOnline -Organization $targetTenant.domain -ShowBanner:$false -ErrorAction Stop
} catch {
    Write-Host "[FAIL] Exchange Online connection failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Connected" -ForegroundColor Green

$results = @()

try {
    foreach ($mb in $mailboxes) {
        Write-Host "`nProcessing: $($mb.DisplayName) ($($mb.SharedMailboxEmail))..." -ForegroundColor Yellow

        # Check if mailbox already exists
        $existing = $null
        try {
            $existing = Get-Mailbox -Identity $mb.SharedMailboxEmail -ErrorAction SilentlyContinue
        } catch {}

        if ($existing) {
            Write-Host "  [SKIP] Mailbox already exists" -ForegroundColor Cyan
            $results += [PSCustomObject]@{
                DisplayName = $mb.DisplayName
                Email       = $mb.SharedMailboxEmail
                Status      = "Already Exists"
            }
            continue
        }

        if (-not $WhatIf) {
            try {
                New-Mailbox -Shared -Name $mb.DisplayName -PrimarySmtpAddress $mb.SharedMailboxEmail -ErrorAction Stop
                Write-Host "  [OK] Created" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    DisplayName = $mb.DisplayName
                    Email       = $mb.SharedMailboxEmail
                    Status      = "Created"
                }
            } catch {
                Write-Host "  [ERROR] $_" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    DisplayName = $mb.DisplayName
                    Email       = $mb.SharedMailboxEmail
                    Status      = "ERROR: $_"
                }
            }
        } else {
            Write-Host "  [WHATIF] Would create shared mailbox" -ForegroundColor Magenta
            $results += [PSCustomObject]@{
                DisplayName = $mb.DisplayName
                Email       = $mb.SharedMailboxEmail
                Status      = "WhatIf"
            }
        }
    }

    # Results summary
    Write-Host "`n=== Results ===" -ForegroundColor Cyan
    $results | Format-Table -AutoSize
} finally {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
}

Write-Host "Next step: Run 05-Grant-SendAs-Permissions.ps1 to set up Send-As access" -ForegroundColor Gray
Write-Host ""
