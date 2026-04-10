# Fix: Enable public client flows on DeltaCrown-PnP app
# Required for Device Login and Interactive auth from CLI

$ErrorActionPreference = "Stop"
$DCETenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
$appId = "6d8820fe-7a7b-4226-bc3b-2c53add3c207"

Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId $DCETenantId -NoWelcome

$ctx = Get-MgContext
Write-Host "Connected: $($ctx.TenantId)" -ForegroundColor Green

# Get app by appId
$app = Get-MgApplication -Filter "appId eq '$appId'" -ErrorAction Stop
Write-Host "App: $($app.DisplayName) ($($app.AppId))" -ForegroundColor Cyan
Write-Host "Current IsFallbackPublicClient: $($app.IsFallbackPublicClient)"

# Enable public client flows
Update-MgApplication -ApplicationId $app.Id -IsFallbackPublicClient:$true -ErrorAction Stop

# Also add the native client redirect URIs needed for device code flow
$currentRedirects = $app.PublicClient.RedirectUris
$newRedirects = @(
    "http://localhost"
    "https://login.microsoftonline.com/common/oauth2/nativeclient"
    "urn:ietf:wg:oauth:2.0:oob"
)
# Merge
$allRedirects = ($currentRedirects + $newRedirects) | Select-Object -Unique
Update-MgApplication -ApplicationId $app.Id -PublicClient @{ RedirectUris = $allRedirects }

# Verify
$updated = Get-MgApplication -Filter "appId eq '$appId'"
Write-Host ""
Write-Host "Updated IsFallbackPublicClient: $($updated.IsFallbackPublicClient)" -ForegroundColor Green
Write-Host "Public client redirects: $($updated.PublicClient.RedirectUris -join ', ')" -ForegroundColor Green

Disconnect-MgGraph -ErrorAction SilentlyContinue
