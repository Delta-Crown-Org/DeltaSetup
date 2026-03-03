<#
.SYNOPSIS
    Exports all active HTT Brands users and optionally generates the mailbox provisioning CSV.
.DESCRIPTION
    Phase 1: Exports all active Member-type users from HTT Brands to a reference CSV.
    Phase 2: After cross-tenant sync completes, queries DCE for synced users and generates
    the mailbox-provisioning.csv with correct UPNs for Send-As/Full Access permissions.
.EXAMPLE
    .\helpers\Export-HTTUsers.ps1                    # Export HTT Brands user list only
    .\helpers\Export-HTTUsers.ps1 -GenerateMailboxCSV  # Generate mailbox CSV from synced users
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph

param(
    [switch]$GenerateMailboxCSV
)

$configPath = Join-Path $PSScriptRoot "..\..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$sourceTenant = $config.tenants.source
$targetTenant = $config.tenants.target

if (-not $GenerateMailboxCSV) {
    # ---- Phase 1: Export HTT Brands user list ----
    Write-Host "`n=== Export HTT Brands Active Users ===" -ForegroundColor Cyan
    Write-Host "Connecting to $($sourceTenant.name)..." -ForegroundColor Yellow
    try {
        Connect-MgGraph -TenantId $sourceTenant.tenantId -Scopes "User.Read.All" -NoWelcome -ErrorAction Stop
    } catch {
        Write-Host "[FAIL] Graph connection failed: $_" -ForegroundColor Red
        exit 1
    }

    try {
        $users = Get-MgUser -Filter "accountEnabled eq true and userType eq 'Member'" `
            -Property DisplayName, UserPrincipalName, Mail, GivenName, Surname, JobTitle, Department -All

        Write-Host "[OK] Found $($users.Count) active member-type users" -ForegroundColor Green

        $exportPath = Join-Path $PSScriptRoot "..\..\config\htt-users-export.csv"
        $users | Select-Object DisplayName, UserPrincipalName, Mail, GivenName, Surname, JobTitle, Department |
            Export-Csv -Path $exportPath -NoTypeInformation

        Write-Host "`nExported to: $exportPath" -ForegroundColor Cyan
        Write-Host "`nUsers:" -ForegroundColor Yellow
        $users | Select-Object DisplayName, UserPrincipalName | Format-Table -AutoSize

        Write-Host "Review this list. Remove any service accounts or admin-only accounts" -ForegroundColor Gray
        Write-Host "that should NOT be synced to DCE before proceeding with Phase 2." -ForegroundColor Gray
    } finally {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
} else {
    # ---- Phase 2: Generate mailbox CSV from synced users ----
    Write-Host "`n=== Generate Mailbox Provisioning CSV from Synced Users ===" -ForegroundColor Cyan
    Write-Host "Connecting to $($targetTenant.name) (DCE)..." -ForegroundColor Yellow
    try {
        Connect-MgGraph -TenantId $targetTenant.tenantId -Scopes "User.Read.All" -NoWelcome -ErrorAction Stop
    } catch {
        Write-Host "[FAIL] Graph connection failed: $_" -ForegroundColor Red
        exit 1
    }

    try {
        $syncedUsers = Get-MgUser -Filter "creationType eq 'Invitation' and userType eq 'Member'" `
            -Property DisplayName, UserPrincipalName, Mail, GivenName, Surname -All

        if ($syncedUsers.Count -eq 0) {
            Write-Host "[WARN] No synced member-type users found in DCE." -ForegroundColor Yellow
            Write-Host "Has cross-tenant sync been configured and run? Check Phase 2." -ForegroundColor Gray
            exit 0
        }

        Write-Host "[OK] Found $($syncedUsers.Count) synced users in DCE" -ForegroundColor Green
        Write-Host "`nSynced users and their UPN format:" -ForegroundColor Yellow
        $syncedUsers | Select-Object DisplayName, UserPrincipalName | Format-Table -AutoSize

        $csvRows = @()

        # Per-user shared mailboxes
        foreach ($user in $syncedUsers) {
            # Build the @deltacrown.com address from the user's name
            $nameParts = $user.DisplayName -split '\s+'
            if ($nameParts.Count -ge 2) {
                $firstName = $nameParts[0].ToLower() -replace '[^a-z]', ''
                $lastName = $nameParts[-1].ToLower() -replace '[^a-z]', ''
                $sharedEmail = "$firstName.$lastName@$($targetTenant.domain)"
            } else {
                $sharedEmail = "$($nameParts[0].ToLower())@$($targetTenant.domain)"
            }

            $csvRows += [PSCustomObject]@{
                DisplayName       = "$($user.DisplayName) - DCE"
                SharedMailboxEmail = $sharedEmail
                SendAsUser        = $user.UserPrincipalName
                FullAccessUser    = $user.UserPrincipalName
            }
        }

        # Preserve existing role mailboxes from current CSV
        $existingCsvPath = Join-Path $PSScriptRoot "..\..\config\mailbox-provisioning.csv"
        if (Test-Path $existingCsvPath) {
            $existingRows = Import-Csv $existingCsvPath
            foreach ($row in $existingRows) {
                # Skip rows that don't have a personal user email pattern
                if ($row.SharedMailboxEmail -and $row.SharedMailboxEmail -notmatch '^[a-z]+\.[a-z]+@') {
                    # This is a role mailbox (info@, support@, etc.)
                    # Keep it but don't overwrite user assignments if they exist
                    $csvRows += $row
                }
            }
        }

        # Write the CSV
        $outputPath = Join-Path $PSScriptRoot "..\..\config\mailbox-provisioning.csv"
        $csvRows | Export-Csv -Path $outputPath -NoTypeInformation

        Write-Host "`n=== Generated CSV ===" -ForegroundColor Cyan
        $csvRows | Format-Table -AutoSize

        Write-Host "Written to: $outputPath" -ForegroundColor Green
        Write-Host "`n[ACTION] Review the CSV and:" -ForegroundColor Yellow
        Write-Host "  1. Verify email addresses are correct (check for name edge cases)" -ForegroundColor Gray
        Write-Host "  2. Assign users to role mailboxes (info@, support@) in the SendAsUser/FullAccessUser columns" -ForegroundColor Gray
        Write-Host "  3. Then run: scripts/04-Create-SharedMailboxes.ps1 -WhatIf" -ForegroundColor Gray
    } finally {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}

Write-Host ""
