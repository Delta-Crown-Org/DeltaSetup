<#
.SYNOPSIS
    Creates Microsoft 365 Groups in the DCE tenant.
.DESCRIPTION
    Reads group definitions from config/tenant-config.json and creates M365 Groups
    in the Delta Crown Extensions tenant. Each group gets a SharePoint site and shared mailbox.
.EXAMPLE
    .\06-Create-Groups.ps1
    .\06-Create-Groups.ps1 -WhatIf
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph

param(
    [switch]$WhatIf
)

# Load config
$configPath = Join-Path $PSScriptRoot "..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$targetTenant = $config.tenants.target
$groups = $config.groups

Write-Host "`n=== Create Microsoft 365 Groups — $($targetTenant.name) ===" -ForegroundColor Cyan
Write-Host "Groups to process: $($groups.Count)" -ForegroundColor Gray

# Connect to Graph
Write-Host "Connecting to Microsoft Graph ($($targetTenant.domain))..." -ForegroundColor Yellow
Connect-MgGraph -TenantId $targetTenant.tenantId -Scopes "Group.ReadWrite.All" -NoWelcome
Write-Host "[OK] Connected" -ForegroundColor Green

$results = @()

foreach ($grp in $groups) {
    $email = "$($grp.mailNickname)@$($targetTenant.domain)"
    Write-Host "`nProcessing: $($grp.displayName) ($email)..." -ForegroundColor Yellow

    # Check if group already exists
    $existing = Get-MgGroup -Filter "mailNickname eq '$($grp.mailNickname)'" -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "  [SKIP] Group already exists (ID: $($existing.Id))" -ForegroundColor Cyan
        $results += [PSCustomObject]@{
            DisplayName  = $grp.displayName
            Email        = $email
            Status       = "Already Exists"
            GroupId      = $existing.Id
        }
        continue
    }

    if (-not $WhatIf) {
        try {
            $groupParams = @{
                DisplayName     = $grp.displayName
                Description     = $grp.description
                MailEnabled     = $true
                MailNickname    = $grp.mailNickname
                SecurityEnabled = $false
                GroupTypes      = @("Unified")
                Visibility      = "Private"
            }
            $newGroup = New-MgGroup -BodyParameter $groupParams
            Write-Host "  [OK] Created (ID: $($newGroup.Id))" -ForegroundColor Green
            $results += [PSCustomObject]@{
                DisplayName  = $grp.displayName
                Email        = $email
                Status       = "Created"
                GroupId      = $newGroup.Id
            }
        } catch {
            Write-Host "  [ERROR] $_" -ForegroundColor Red
            $results += [PSCustomObject]@{
                DisplayName  = $grp.displayName
                Email        = $email
                Status       = "ERROR: $_"
                GroupId      = ""
            }
        }
    } else {
        Write-Host "  [WHATIF] Would create M365 Group" -ForegroundColor Magenta
        $results += [PSCustomObject]@{
            DisplayName  = $grp.displayName
            Email        = $email
            Status       = "WhatIf"
            GroupId      = ""
        }
    }
}

# Results summary
Write-Host "`n=== Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Disconnect-MgGraph -ErrorAction SilentlyContinue
Write-Host "Each M365 Group auto-creates: SharePoint site, shared mailbox, Planner plan." -ForegroundColor Gray
Write-Host "Teams-enable them in the Teams client: Create team > From existing M365 group." -ForegroundColor Gray
Write-Host "`nNext step: Run 07-Validate-DNS-Records.ps1" -ForegroundColor Gray
Write-Host ""
