<#
.SYNOPSIS
    Bulk-adds active HTT Brands users to the SG-DCE-Sync-Users security group.
.DESCRIPTION
    Connects to the HTT Brands tenant, finds the sync security group, and adds
    all active member-type users (or a specified subset) to it.
.EXAMPLE
    .\helpers\Add-SyncGroupMembers.ps1                    # Add ALL active users
    .\helpers\Add-SyncGroupMembers.ps1 -TestOnly          # Add only test users (Tyler + Jenna)
    .\helpers\Add-SyncGroupMembers.ps1 -WhatIf            # Preview without changes
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph

param(
    [switch]$TestOnly,
    [switch]$WhatIf
)

$configPath = Join-Path $PSScriptRoot "..\..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$sourceTenant = $config.tenants.source
$syncConfig = $config.syncConfig

Write-Host "`n=== Add Users to $($syncConfig.securityGroupName) ===" -ForegroundColor Cyan
Write-Host "Connecting to $($sourceTenant.name)..." -ForegroundColor Yellow
try {
    Connect-MgGraph -TenantId $sourceTenant.tenantId -Scopes "Group.ReadWrite.All", "User.Read.All" -NoWelcome -ErrorAction Stop
} catch {
    Write-Host "[FAIL] Graph connection failed: $_" -ForegroundColor Red
    exit 1
}

try {
    # Find the sync group
    $group = Get-MgGroup -Filter "displayName eq '$($syncConfig.securityGroupName)'" -ErrorAction SilentlyContinue
    if (-not $group) {
        Write-Host "[FAIL] Security group '$($syncConfig.securityGroupName)' not found." -ForegroundColor Red
        Write-Host "Run 03-Configure-CrossTenantSync.ps1 first." -ForegroundColor Gray
        exit 1
    }
    Write-Host "[OK] Found group: $($group.DisplayName) (ID: $($group.Id))" -ForegroundColor Green

    # Get current members
    $currentMembers = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
    $currentMemberIds = @($currentMembers | ForEach-Object { $_.Id })
    Write-Host "Current members: $($currentMemberIds.Count)" -ForegroundColor Gray

    # Get users to add
    if ($TestOnly) {
        Write-Host "`n[TEST MODE] Adding only test users..." -ForegroundColor Yellow
        # Load from the user export if it exists, otherwise query directly
        $users = @()
        $testUPNs = @(
            "tyler.granlund@httbrands.com",
            "t.granlund@httbrands.com",
            "tgranlund@httbrands.com",
            "jenna.bowden@httbrands.com",
            "j.bowden@httbrands.com",
            "jbowden@httbrands.com"
        )
        foreach ($upn in $testUPNs) {
            $u = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            if ($u) { $users += $u }
        }
        if ($users.Count -eq 0) {
            Write-Host "[WARN] No test users found with expected UPNs." -ForegroundColor Yellow
            Write-Host "Listing all active users so you can identify the correct UPNs:" -ForegroundColor Gray
            Get-MgUser -Filter "accountEnabled eq true and userType eq 'Member'" `
                -Property DisplayName, UserPrincipalName -All |
                Select-Object DisplayName, UserPrincipalName | Format-Table -AutoSize
            exit 0
        }
    } else {
        Write-Host "`n[FULL MODE] Adding all active member-type users..." -ForegroundColor Yellow
        $users = Get-MgUser -Filter "accountEnabled eq true and userType eq 'Member'" `
            -Property Id, DisplayName, UserPrincipalName -All
    }

    Write-Host "Users to process: $($users.Count)" -ForegroundColor Gray

    $added = 0
    $skipped = 0
    foreach ($user in $users) {
        if ($currentMemberIds -contains $user.Id) {
            Write-Host "  [SKIP] $($user.DisplayName) ($($user.UserPrincipalName)) — already a member" -ForegroundColor Cyan
            $skipped++
            continue
        }

        if (-not $WhatIf) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction Stop
                Write-Host "  [OK] $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Green
                $added++
            } catch {
                Write-Host "  [ERROR] $($user.DisplayName): $_" -ForegroundColor Red
            }
        } else {
            Write-Host "  [WHATIF] Would add $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Magenta
            $added++
        }
    }

    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Added: $added | Skipped (already member): $skipped | Total in group: $($currentMemberIds.Count + $added)" -ForegroundColor $(if ($added -gt 0) { "Green" } else { "Gray" })
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}

Write-Host ""
