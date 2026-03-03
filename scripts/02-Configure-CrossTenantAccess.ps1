<#
.SYNOPSIS
    Configures cross-tenant access policies for HTT Brands ↔ DCE synchronization.
.DESCRIPTION
    Sets up inbound access on DCE tenant and outbound access on HTT Brands tenant.
    Enables user sync, automatic redemption, and MFA trust.
.EXAMPLE
    .\02-Configure-CrossTenantAccess.ps1
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph

param(
    [switch]$WhatIf
)

# Load tenant config
$configPath = Join-Path $PSScriptRoot "..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$sourceTenant = $config.tenants.source
$targetTenant = $config.tenants.target

Write-Host "`n=== Cross-Tenant Access Configuration ===" -ForegroundColor Cyan
Write-Host "Source: $($sourceTenant.name) ($($sourceTenant.tenantId))" -ForegroundColor Gray
Write-Host "Target: $($targetTenant.name) ($($targetTenant.tenantId))" -ForegroundColor Gray

# ============================================================
# PART 1: Configure INBOUND access on DCE tenant (target)
# ============================================================
Write-Host "`n--- Part 1: DCE Tenant (Inbound Access) ---" -ForegroundColor Yellow
Write-Host "Connecting to DCE tenant..." -ForegroundColor Yellow
try {
    Connect-MgGraph -TenantId $targetTenant.tenantId -Scopes "Policy.ReadWrite.CrossTenantAccess" -NoWelcome -ErrorAction Stop
} catch {
    Write-Host "[FAIL] DCE Graph connection failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Connected to $($targetTenant.name)" -ForegroundColor Green

try {
    # Check if partner configuration already exists
    $existingPartner = $null
    try {
        $existingPartner = Get-MgPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $sourceTenant.tenantId -ErrorAction SilentlyContinue
    } catch {}

    if ($existingPartner) {
        Write-Host "[INFO] Partner configuration for $($sourceTenant.name) already exists in DCE" -ForegroundColor Cyan
    } else {
        Write-Host "Creating partner configuration for $($sourceTenant.name)..." -ForegroundColor Yellow
        if (-not $WhatIf) {
            try {
                $params = @{
                    TenantId = $sourceTenant.tenantId
                }
                New-MgPolicyCrossTenantAccessPolicyPartner -BodyParameter $params -ErrorAction Stop
                Write-Host "[OK] Partner configuration created" -ForegroundColor Green
            } catch {
                Write-Host "[FAIL] Failed to create partner configuration: $_" -ForegroundColor Red
                throw
            }
        } else {
            Write-Host "[WHATIF] Would create partner config for $($sourceTenant.tenantId)" -ForegroundColor Magenta
        }
    }

    # Enable inbound user sync
    Write-Host "Enabling inbound cross-tenant sync..." -ForegroundColor Yellow
    if (-not $WhatIf) {
        try {
            $syncParams = @{
                CrossTenantAccessPolicyConfigurationPartnerTenantId = $sourceTenant.tenantId
                IdentitySynchronization = @{
                    UserSyncInbound = @{
                        IsSyncAllowed = $true
                    }
                }
            }
            Update-MgPolicyCrossTenantAccessPolicyPartner @syncParams -ErrorAction Stop
            Write-Host "[OK] Inbound user sync enabled" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL] Failed to enable inbound user sync: $_" -ForegroundColor Red
            throw
        }
    } else {
        Write-Host "[WHATIF] Would enable inbound user sync" -ForegroundColor Magenta
    }

    # Enable automatic redemption (suppresses consent prompts)
    Write-Host "Enabling automatic redemption..." -ForegroundColor Yellow
    if (-not $WhatIf) {
        try {
            $redemptionParams = @{
                CrossTenantAccessPolicyConfigurationPartnerTenantId = $sourceTenant.tenantId
                InboundTrust = @{
                    IsAutoRedeemEnabled = $true
                    IsMfaAccepted = $true
                    IsCompliantDeviceAccepted = $true
                    IsHybridAzureADJoinedDeviceAccepted = $true
                }
            }
            Update-MgPolicyCrossTenantAccessPolicyPartner @redemptionParams -ErrorAction Stop
            Write-Host "[OK] Automatic redemption and MFA trust enabled" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL] Failed to enable automatic redemption: $_" -ForegroundColor Red
            throw
        }
    } else {
        Write-Host "[WHATIF] Would enable automatic redemption and MFA trust" -ForegroundColor Magenta
    }
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}

# ============================================================
# PART 2: Configure OUTBOUND access on HTT Brands tenant (source)
# ============================================================
Write-Host "`n--- Part 2: HTT Brands Tenant (Outbound Access) ---" -ForegroundColor Yellow
Write-Host "Connecting to HTT Brands tenant..." -ForegroundColor Yellow
try {
    Connect-MgGraph -TenantId $sourceTenant.tenantId -Scopes "Policy.ReadWrite.CrossTenantAccess" -NoWelcome -ErrorAction Stop
} catch {
    Write-Host "[FAIL] HTT Brands Graph connection failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Connected to $($sourceTenant.name)" -ForegroundColor Green

try {
    # Check if partner configuration already exists
    $existingPartner = $null
    try {
        $existingPartner = Get-MgPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $targetTenant.tenantId -ErrorAction SilentlyContinue
    } catch {}

    if ($existingPartner) {
        Write-Host "[INFO] Partner configuration for $($targetTenant.name) already exists in HTT Brands" -ForegroundColor Cyan
    } else {
        Write-Host "Creating partner configuration for $($targetTenant.name)..." -ForegroundColor Yellow
        if (-not $WhatIf) {
            try {
                $params = @{
                    TenantId = $targetTenant.tenantId
                }
                New-MgPolicyCrossTenantAccessPolicyPartner -BodyParameter $params -ErrorAction Stop
                Write-Host "[OK] Partner configuration created" -ForegroundColor Green
            } catch {
                Write-Host "[FAIL] Failed to create partner configuration: $_" -ForegroundColor Red
                throw
            }
        } else {
            Write-Host "[WHATIF] Would create partner config for $($targetTenant.tenantId)" -ForegroundColor Magenta
        }
    }

    # Enable automatic redemption outbound
    Write-Host "Enabling outbound automatic redemption..." -ForegroundColor Yellow
    if (-not $WhatIf) {
        try {
            $outboundParams = @{
                CrossTenantAccessPolicyConfigurationPartnerTenantId = $targetTenant.tenantId
                AutomaticUserConsentSettings = @{
                    OutboundAllowed = $true
                }
            }
            Update-MgPolicyCrossTenantAccessPolicyPartner @outboundParams -ErrorAction Stop
            Write-Host "[OK] Outbound automatic redemption enabled" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL] Failed to enable outbound automatic redemption: $_" -ForegroundColor Red
            throw
        }
    } else {
        Write-Host "[WHATIF] Would enable outbound automatic redemption" -ForegroundColor Magenta
    }
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}

Write-Host "`n=== Cross-Tenant Access Configuration Complete ===" -ForegroundColor Green
Write-Host "Next step: Run 03-Configure-CrossTenantSync.ps1 to create the sync group" -ForegroundColor Gray
Write-Host ""
