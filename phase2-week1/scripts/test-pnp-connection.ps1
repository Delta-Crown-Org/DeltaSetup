# Quick test: PnP SharePoint connection via Device Login
# Usage: pwsh ./test-pnp-connection.ps1

$ErrorActionPreference = "Stop"
$clientId = "6d8820fe-7a7b-4226-bc3b-2c53add3c207"
$adminUrl = "https://deltacrown-admin.sharepoint.com"

Write-Host ""
Write-Host "=== Testing PnP Connection ===" -ForegroundColor Cyan
Write-Host "Tyler: go to https://microsoft.com/devicelogin" -ForegroundColor Yellow
Write-Host "       and enter the code shown below." -ForegroundColor Yellow
Write-Host ""

try {
    Connect-PnPOnline -Url $adminUrl -DeviceLogin -ClientId $clientId -Tenant "ce62e17d-2feb-4e67-a115-8ea4af68da30" -ErrorAction Stop
    Write-Host ""
    Write-Host "Connected to SharePoint Admin!" -ForegroundColor Green
    Write-Host ""

    Write-Host "=== Existing Sites ===" -ForegroundColor Cyan
    $sites = Get-PnPTenantSite -ErrorAction Stop
    $sites | Select-Object Url, Title, Template, Status | Format-Table -AutoSize

    Write-Host "Total sites: $($sites.Count)" -ForegroundColor Green

    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
}
