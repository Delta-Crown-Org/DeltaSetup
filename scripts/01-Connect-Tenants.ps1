<#
.SYNOPSIS
    Connection helper functions for HTT Brands and DCE tenants.
.DESCRIPTION
    Dot-source this script to load Connect-HTTBrandsTenant and Connect-DCETenant functions.
    Reads tenant configuration from config/tenant-config.json.
.EXAMPLE
    . .\scripts\01-Connect-Tenants.ps1
    Connect-DCETenant
    Connect-HTTBrandsTenant
#>

#Requires -Version 7.0

# Load tenant config
$configPath = Join-Path $PSScriptRoot "..\config\tenant-config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "[ERROR] Config file not found: $configPath" -ForegroundColor Red
    return
}
$TenantConfig = Get-Content $configPath | ConvertFrom-Json

$GraphScopes = @(
    "User.Read.All",
    "Group.ReadWrite.All",
    "Policy.ReadWrite.CrossTenantAccess",
    "Directory.ReadWrite.All"
)

function Connect-HTTBrandsTenant {
    [CmdletBinding()]
    param(
        [switch]$GraphOnly,
        [switch]$ExchangeOnly
    )

    $tenant = $TenantConfig.tenants.source
    Write-Host "`n=== Connecting to: $($tenant.name) ($($tenant.domain)) ===" -ForegroundColor Cyan

    if (-not $ExchangeOnly) {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        Connect-MgGraph -TenantId $tenant.tenantId -Scopes $GraphScopes -NoWelcome
        $ctx = Get-MgContext
        Write-Host "[OK] Graph connected: $($ctx.Account) → $($ctx.TenantId)" -ForegroundColor Green
    }

    if (-not $GraphOnly) {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline -Organization $tenant.domain -ShowBanner:$false
        Write-Host "[OK] Exchange Online connected: $($tenant.domain)" -ForegroundColor Green
    }

    Write-Host ""
}

function Connect-DCETenant {
    [CmdletBinding()]
    param(
        [switch]$GraphOnly,
        [switch]$ExchangeOnly
    )

    $tenant = $TenantConfig.tenants.target
    Write-Host "`n=== Connecting to: $($tenant.name) ($($tenant.domain)) ===" -ForegroundColor Cyan

    if (-not $ExchangeOnly) {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        Connect-MgGraph -TenantId $tenant.tenantId -Scopes $GraphScopes -NoWelcome
        $ctx = Get-MgContext
        Write-Host "[OK] Graph connected: $($ctx.Account) → $($ctx.TenantId)" -ForegroundColor Green
    }

    if (-not $GraphOnly) {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline -Organization $tenant.domain -ShowBanner:$false
        Write-Host "[OK] Exchange Online connected: $($tenant.domain)" -ForegroundColor Green
    }

    Write-Host ""
}

function Disconnect-AllTenants {
    [CmdletBinding()]
    param()

    Write-Host "Disconnecting all sessions..." -ForegroundColor Yellow
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch {}
    try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    Write-Host "[OK] All sessions disconnected" -ForegroundColor Green
}

Write-Host "Tenant connection functions loaded." -ForegroundColor Green
Write-Host "  Connect-HTTBrandsTenant  — Connect to HTT Brands ($($TenantConfig.tenants.source.domain))" -ForegroundColor Gray
Write-Host "  Connect-DCETenant        — Connect to DCE ($($TenantConfig.tenants.target.domain))" -ForegroundColor Gray
Write-Host "  Disconnect-AllTenants    — Disconnect all sessions" -ForegroundColor Gray
Write-Host ""
