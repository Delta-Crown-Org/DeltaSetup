<#
.SYNOPSIS
    Creates the sync security group and outputs cross-tenant sync configuration instructions.
.DESCRIPTION
    Creates SG-DCE-Sync-Users in HTT Brands tenant and provides portal instructions
    for creating the cross-tenant sync provisioning configuration.
.EXAMPLE
    .\03-Configure-CrossTenantSync.ps1
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph

param(
    [switch]$WhatIf
)

# Load config
$configPath = Join-Path $PSScriptRoot "..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$sourceTenant = $config.tenants.source
$targetTenant = $config.tenants.target
$syncConfig = $config.syncConfig

Write-Host "`n=== Cross-Tenant Sync Configuration ===" -ForegroundColor Cyan

# Connect to HTT Brands (source) tenant
Write-Host "Connecting to $($sourceTenant.name)..." -ForegroundColor Yellow
try {
    Connect-MgGraph -TenantId $sourceTenant.tenantId -Scopes "Group.ReadWrite.All", "User.Read.All" -NoWelcome -ErrorAction Stop
} catch {
    Write-Host "[FAIL] Graph connection failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Connected to $($sourceTenant.name)" -ForegroundColor Green

try {
    # Check if sync group already exists
    $existingGroup = Get-MgGroup -Filter "displayName eq '$($syncConfig.securityGroupName)'" -ErrorAction SilentlyContinue

    if ($existingGroup) {
        Write-Host "[INFO] Security group '$($syncConfig.securityGroupName)' already exists (ID: $($existingGroup.Id))" -ForegroundColor Cyan
        $groupId = $existingGroup.Id
    } else {
        Write-Host "Creating security group '$($syncConfig.securityGroupName)'..." -ForegroundColor Yellow
        if (-not $WhatIf) {
            try {
                $groupParams = @{
                    DisplayName     = $syncConfig.securityGroupName
                    Description     = "Users synchronized to the Delta Crown Extensions tenant via cross-tenant sync"
                    MailEnabled     = $false
                    SecurityEnabled = $true
                    MailNickname    = "sg-dce-sync-users"
                }
                $newGroup = New-MgGroup -BodyParameter $groupParams -ErrorAction Stop
                $groupId = $newGroup.Id
                Write-Host "[OK] Security group created (ID: $groupId)" -ForegroundColor Green
            } catch {
                Write-Host "[FAIL] Failed to create security group: $_" -ForegroundColor Red
                throw
            }
        } else {
            Write-Host "[WHATIF] Would create security group '$($syncConfig.securityGroupName)'" -ForegroundColor Magenta
            $groupId = "<pending>"
        }
    }

    # Show current members
    if ($groupId -and $groupId -ne "<pending>") {
        $members = Get-MgGroupMember -GroupId $groupId -ErrorAction SilentlyContinue
        if ($members) {
            Write-Host "`nCurrent members of $($syncConfig.securityGroupName):" -ForegroundColor Cyan
            foreach ($member in $members) {
                $user = Get-MgUser -UserId $member.Id -Property DisplayName, UserPrincipalName
                Write-Host "  - $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Gray
            }
        } else {
            Write-Host "`n[WARN] Group has no members yet. Add users before starting sync." -ForegroundColor Yellow
        }
    }
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}

# Output manual portal instructions
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  MANUAL STEPS REQUIRED IN ENTRA PORTAL" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host @"

The cross-tenant sync provisioning configuration must be created in the Entra portal.

1. Go to: https://entra.microsoft.com
2. Switch to: $($sourceTenant.name) ($($sourceTenant.domain))
3. Navigate: Identity > External Identities > Cross-tenant synchronization > Configurations
4. Click: + New configuration
5. Name: $($syncConfig.configurationName)
6. Provisioning:
   - Mode: Automatic
   - Authorize with DCE tenant admin ($($targetTenant.domain))
   - Test Connection
7. Users and groups:
   - Add group: $($syncConfig.securityGroupName) (ID: $groupId)
   - Scope: Sync only assigned users and groups
8. Attribute Mappings:
   - CRITICAL: Set userType to Constant "Member" (NOT Guest)
   - See config/sync-attribute-mappings.json for full mapping reference
9. Start provisioning
10. Monitor provisioning logs for 20-40 minutes

"@ -ForegroundColor White

Write-Host "Attribute mapping reference: config\sync-attribute-mappings.json" -ForegroundColor Gray
Write-Host ""
