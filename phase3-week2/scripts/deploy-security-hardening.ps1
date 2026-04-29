# ============================================================================
# Security Hardening — Break Inheritance + Permission Matrix + Disable Sharing
# Run manually: pwsh -File ./deploy-security-hardening.ps1
# Requires: PnP.PowerShell (interactive browser auth)
# ============================================================================
param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Sites and their permission matrix
$PermissionMatrix = @{
    "dce-hub" = @(
        @{ Group = "AllStaff"; Role = "Read" }
        @{ Group = "Managers"; Role = "Full Control" }
    )
    "dce-clientservices" = @(
        @{ Group = "AllStaff"; Role = "Contribute" }
        @{ Group = "Managers"; Role = "Full Control" }
    )
    "dce-marketing" = @(
        @{ Group = "AllStaff"; Role = "Read" }
        @{ Group = "Managers"; Role = "Full Control" }
        @{ Group = "Marketing"; Role = "Edit" }
    )
    "dce-docs" = @(
        @{ Group = "AllStaff"; Role = "Read" }
        @{ Group = "Managers"; Role = "Full Control" }
    )
}

$ForbiddenGroups = @(
    "Everyone"
    "Everyone except external users"
    "All Users"
    "NT AUTHORITY\Authenticated Users"
)

$TenantName = "deltacrown"
$TenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
$PnpConfigPath = Join-Path $PSScriptRoot "..\..\phase2-week1\modules\pnp-app-config.json"
if (-not (Test-Path $PnpConfigPath)) {
    throw "PnP app config not found: $PnpConfigPath"
}
$PnpClientId = (Get-Content $PnpConfigPath -Raw | ConvertFrom-Json).PnPClientId
if (-not $PnpClientId) {
    throw "PnPClientId missing from $PnpConfigPath"
}
$pnpConnection = $null

try {
    Write-Host "=== Delta Crown Security Hardening ===" -ForegroundColor Cyan
    Write-Host ""

    foreach ($siteName in $PermissionMatrix.Keys) {
        $siteUrl = "https://$TenantName.sharepoint.com/sites/$siteName"
        Write-Host "━━━ $siteName ━━━" -ForegroundColor Yellow

        # Connect to this site
        $pnpConnection = Connect-PnPOnline -Url $siteUrl -DeviceLogin -ClientId $PnpClientId -Tenant $TenantId -ReturnConnection
        Write-Host "  Connected"

        # 1. Break inheritance
        $web = Get-PnPWeb -Includes HasUniqueRoleAssignments -Connection $pnpConnection
        if ($web.HasUniqueRoleAssignments) {
            Write-Host "  ⏭️  Already has unique permissions"
        } else {
            if (-not $WhatIf) {
                Set-PnPWeb -BreakInheritance -Connection $pnpConnection
                Write-Host "  ✅ Broke permission inheritance"
            } else {
                Write-Host "  [WhatIf] Would break inheritance"
            }
        }

        # 2. Remove forbidden groups
        foreach ($forbidden in $ForbiddenGroups) {
            try {
                $grp = Get-PnPGroup -Identity $forbidden -Connection $pnpConnection -ErrorAction SilentlyContinue
                if ($grp) {
                    if (-not $WhatIf) {
                        Remove-PnPGroup -Identity $forbidden -Force -Connection $pnpConnection -ErrorAction SilentlyContinue
                        Write-Host "  ✅ Removed: $forbidden"
                    } else {
                        Write-Host "  [WhatIf] Would remove: $forbidden"
                    }
                }
            } catch {
                # Expected — group doesn't exist
            }
        }

        # 3. Apply permission matrix
        $perms = $PermissionMatrix[$siteName]
        foreach ($perm in $perms) {
            try {
                if (-not $WhatIf) {
                    Set-PnPGroupPermissions -Identity $perm.Group -AddRole $perm.Role -Connection $pnpConnection -ErrorAction SilentlyContinue
                    Write-Host "  ✅ $($perm.Group) → $($perm.Role)"
                } else {
                    Write-Host "  [WhatIf] $($perm.Group) → $($perm.Role)"
                }
            } catch {
                Write-Host "  ⚠️  $($perm.Group): $($_.Exception.Message)"
            }
        }

        # 4. Disable external sharing (site level)
        try {
            if (-not $WhatIf) {
                Set-PnPSite -Sharing Disabled -Connection $pnpConnection -ErrorAction SilentlyContinue
                Write-Host "  ✅ External sharing disabled"
            } else {
                Write-Host "  [WhatIf] Would disable sharing"
            }
        } catch {
            Write-Host "  ⚠️  Sharing: $($_.Exception.Message)"
        }

        Write-Host ""
    }

    # Also handle corp sites (sharing only — no custom perms)
    $corpSites = @("corp-hub","corp-hr","corp-it","corp-finance","corp-training")
    foreach ($siteName in $corpSites) {
        $siteUrl = "https://$TenantName.sharepoint.com/sites/$siteName"
        Write-Host "━━━ $siteName (sharing only) ━━━" -ForegroundColor Yellow
        try {
            $conn = Connect-PnPOnline -Url $siteUrl -DeviceLogin -ClientId $PnpClientId -Tenant $TenantId -ReturnConnection
            if (-not $WhatIf) {
                Set-PnPSite -Sharing Disabled -Connection $conn -ErrorAction SilentlyContinue
                Write-Host "  ✅ External sharing disabled"
            } else {
                Write-Host "  [WhatIf] Would disable sharing"
            }
        } catch {
            Write-Host "  ⚠️  $($_.Exception.Message)"
        }
        Write-Host ""
    }

    Write-Host "🏁 Security hardening complete!" -ForegroundColor Green

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
