# ============================================================================
# Register DeltaCrown PnP App in Entra ID
# One-time setup — creates the app registration needed for PnP.PowerShell 3.x
# Usage: pwsh ./register-pnp-app.ps1
# ============================================================================

$ErrorActionPreference = "Stop"
$DCETenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Register DeltaCrown-PnP App" -ForegroundColor Cyan
Write-Host "  Tenant: $DCETenantId" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Connect to Graph
Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId $DCETenantId -NoWelcome

$ctx = Get-MgContext
if (!$ctx -or $ctx.TenantId -ne $DCETenantId) {
    Write-Host "ERROR: Not connected to deltacrown tenant." -ForegroundColor Red
    exit 1
}
Write-Host "Connected to Graph: $($ctx.TenantId)" -ForegroundColor Green

# Check if already exists
$existing = Get-MgApplication -Filter "displayName eq 'DeltaCrown-PnP-Provisioning'" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host ""
    Write-Host "App already exists!" -ForegroundColor Yellow
    Write-Host "  Display Name: $($existing.DisplayName)"
    Write-Host "  Client ID:    $($existing.AppId)"
    Write-Host ""
    Write-Host "Use this Client ID for PnP connections:" -ForegroundColor Green
    Write-Host "  Connect-PnPOnline -Url 'https://deltacrown-admin.sharepoint.com' -Interactive -ClientId '$($existing.AppId)'"
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    exit 0
}

Write-Host ""
Write-Host "Creating app registration..." -ForegroundColor Yellow

# SharePoint API permissions
$sharepointAccess = @{
    ResourceAppId = "00000003-0000-0ff1-ce00-000000000000"
    ResourceAccess = @(
        @{ Id = "56680e0d-d2a3-4ae1-80d8-3c4f2571571b"; Type = "Scope" }  # AllSites.FullControl
    )
}

# Microsoft Graph API permissions
$graphAccess = @{
    ResourceAppId = "00000003-0000-0000-c000-000000000000"
    ResourceAccess = @(
        @{ Id = "205e70e5-aba6-4c52-a976-6d2d46c48043"; Type = "Scope" }  # Sites.FullControl.All
        @{ Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; Type = "Scope" }  # User.Read
        @{ Id = "62a82d76-70ea-41e2-9197-370581804d09"; Type = "Scope" }  # Group.ReadWrite.All
    )
}

$app = New-MgApplication `
    -DisplayName "DeltaCrown-PnP-Provisioning" `
    -SignInAudience "AzureADMyOrg" `
    -PublicClient @{ RedirectUris = @("http://localhost") } `
    -RequiredResourceAccess @($sharepointAccess, $graphAccess) `
    -ErrorAction Stop

Write-Host ""
Write-Host "=== APP REGISTERED ===" -ForegroundColor Green
Write-Host "  Display Name: $($app.DisplayName)"
Write-Host "  Client ID:    $($app.AppId)"
Write-Host "  Object ID:    $($app.Id)"
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Grant admin consent in Azure Portal:" -ForegroundColor Yellow
Write-Host "     https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$($app.AppId)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Then connect PnP with:" -ForegroundColor Yellow
Write-Host "     Connect-PnPOnline -Url 'https://deltacrown-admin.sharepoint.com' -Interactive -ClientId '$($app.AppId)'" -ForegroundColor Cyan
Write-Host ""

# Save the client ID to a file for other scripts to use
$configUpdate = @{
    PnPClientId = $app.AppId
    TenantId = $DCETenantId
    RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}
$configPath = Join-Path $PSScriptRoot ".." "modules" "pnp-app-config.json"
$configUpdate | ConvertTo-Json | Out-File -FilePath $configPath -Force
Write-Host "Client ID saved to: $configPath" -ForegroundColor Green

Disconnect-MgGraph -ErrorAction SilentlyContinue
