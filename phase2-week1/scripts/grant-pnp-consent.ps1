# ============================================================================
# Grant admin consent for DeltaCrown-PnP-Provisioning app
# Usage: pwsh ./grant-pnp-consent.ps1
# ============================================================================

$ErrorActionPreference = "Stop"
$DCETenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
$appId = "6d8820fe-7a7b-4226-bc3b-2c53add3c207"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Grant Admin Consent for PnP App" -ForegroundColor Cyan
Write-Host "  App: $appId" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Connect
Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "Application.ReadWrite.All","DelegatedPermissionGrant.ReadWrite.All","AppRoleAssignment.ReadWrite.All" `
    -TenantId $DCETenantId -NoWelcome

$ctx = Get-MgContext
if (!$ctx -or $ctx.TenantId -ne $DCETenantId) {
    Write-Host "ERROR: Not connected to deltacrown tenant." -ForegroundColor Red
    exit 1
}
Write-Host "Connected: $($ctx.TenantId)" -ForegroundColor Green
Write-Host ""

# Get service principal for our app
Write-Host "=== Getting Service Principal ===" -ForegroundColor Cyan
$sp = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
if (-not $sp) {
    Write-Host "Creating service principal..."
    $sp = New-MgServicePrincipal -AppId $appId -ErrorAction Stop
}
Write-Host "  SP ID: $($sp.Id)"
Write-Host "  Name:  $($sp.DisplayName)"
Write-Host ""

# Get resource service principals
Write-Host "=== Getting Resource SPs ===" -ForegroundColor Cyan
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction Stop
Write-Host "  Graph SP:      $($graphSp.Id)"

$spoSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0ff1-ce00-000000000000'" -ErrorAction Stop
Write-Host "  SharePoint SP: $($spoSp.Id)"
Write-Host ""

# Check existing grants
$existingGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue
Write-Host "Existing grants: $(($existingGrants | Measure-Object).Count)"
Write-Host ""

# Grant Graph permissions
Write-Host "=== Granting Consent ===" -ForegroundColor Cyan

$graphScope = "Sites.FullControl.All Group.ReadWrite.All User.Read.All Directory.ReadWrite.All"
$existingGraph = $existingGrants | Where-Object { $_.ResourceId -eq $graphSp.Id }
if ($existingGraph) {
    Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $existingGraph.Id -Scope $graphScope
    Write-Host "  Updated Graph grant: $graphScope" -ForegroundColor Green
} else {
    New-MgOauth2PermissionGrant -BodyParameter @{
        ClientId    = $sp.Id
        ConsentType = "AllPrincipals"
        ResourceId  = $graphSp.Id
        Scope       = $graphScope
    } -ErrorAction Stop | Out-Null
    Write-Host "  Created Graph grant: $graphScope" -ForegroundColor Green
}

$spoScope = "Sites.FullControl.All AllSites.FullControl"
$existingSpo = $existingGrants | Where-Object { $_.ResourceId -eq $spoSp.Id }
if ($existingSpo) {
    Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $existingSpo.Id -Scope $spoScope
    Write-Host "  Updated SPO grant: $spoScope" -ForegroundColor Green
} else {
    New-MgOauth2PermissionGrant -BodyParameter @{
        ClientId    = $sp.Id
        ConsentType = "AllPrincipals"
        ResourceId  = $spoSp.Id
        Scope       = $spoScope
    } -ErrorAction Stop | Out-Null
    Write-Host "  Created SPO grant: $spoScope" -ForegroundColor Green
}

# Verify
Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
$allGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id
foreach ($g in $allGrants) {
    $resource = Get-MgServicePrincipal -ServicePrincipalId $g.ResourceId -Property "displayName" -ErrorAction SilentlyContinue
    Write-Host "  OK $($resource.DisplayName): $($g.Scope)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Admin Consent Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Test PnP connection:" -ForegroundColor Yellow
Write-Host "  Connect-PnPOnline -Url 'https://deltacrown-admin.sharepoint.com' -Interactive -ClientId '$appId'" -ForegroundColor Cyan

Disconnect-MgGraph -ErrorAction SilentlyContinue
