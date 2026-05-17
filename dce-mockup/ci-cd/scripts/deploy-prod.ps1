<#
.SYNOPSIS
  DCE SharePoint — production deploy. Cert-based app-only auth.

.DESCRIPTION
  1. Connect-PnPOnline via cert (admin path, no interactive auth).
  2. Apply PnP templates in templates/ — numbered, idempotent, forward-only.
  3. Apply page JSON definitions in pages/ — re-applied each run.
  4. Associate Crown Connection (and any other spokes) to DCE Hub.

  Per 09-deployment.md and ADR-007. Templates are NEVER deleted by this
  script — drift-fix is a separate manual operation by Tyler.

.PARAMETER TargetEnv
  'dev' or 'prod'. Defaults to 'prod'.

.NOTES
  Reuse: pattern adapted from
  /Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/spfx/deploy-spfx.ps1
  (production-tested SPFx deploy script). DCE strips the SPFx-package
  upload step (no custom web parts in v1 per ADR-005) and adds the
  multi-template-apply loop.
#>

param(
  [ValidateSet('dev', 'prod')]
  [string]$TargetEnv = 'prod'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ClientId   = $env:CLIENT_ID
$TenantDom  = $env:TENANT
$CertPath   = "./cert.pfx"
$CertPass   = ConvertTo-SecureString -String $env:CERT_PASS -AsPlainText -Force

$siteUrl = if ($TargetEnv -eq 'prod') {
  'https://deltacrown.sharepoint.com/sites/dce-hub'
} else {
  'https://deltacrown.sharepoint.com/sites/dce-hub-dev'
}

function Step($msg) { Write-Host "`n── $msg ──" -ForegroundColor Cyan }
function OK($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }

Step "1. Connect to $siteUrl"
Connect-PnPOnline -Url $siteUrl `
                  -ClientId $ClientId `
                  -Tenant $TenantDom `
                  -CertificatePath $CertPath `
                  -CertificatePassword $CertPass
OK "Connected"

Step "2. Validate site state"
$site = Get-PnPSite
$web  = Get-PnPWeb
OK "Site ID: $($site.Id)"
OK "Web title: $($web.Title)"

Step "3. Apply numbered PnP templates (idempotent, forward-only)"
$templates = Get-ChildItem -Path 'templates/hub' -Filter '*.xml' | Sort-Object Name
foreach ($t in $templates) {
  Write-Host "    Applying $($t.Name)…" -ForegroundColor Gray
  Invoke-PnPSiteTemplate -Path $t.FullName -ClearNavigation:$false
  OK "$($t.Name) applied"
}

Step "4. Apply page JSON definitions"
$pages = Get-ChildItem -Path 'pages' -Filter '*.json' | Sort-Object Name
foreach ($p in $pages) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($p.Name)
  Write-Host "    Applying page $name…" -ForegroundColor Gray
  # Custom logic: parse JSON, Add-PnPPage if missing, Set-PnPPage if exists
  & ./scripts/apply-page.ps1 -Path $p.FullName
}
OK "$($pages.Count) page(s) applied"

Step "5. Ensure hub association (spokes)"
$hub = Get-PnPHubSite -Identity $siteUrl
if ($null -ne $hub.SiteId) {
  Add-PnPHubSiteAssociation -Site 'https://deltacrown.sharepoint.com/sites/CrownConnection' `
                            -HubSite $siteUrl -ErrorAction SilentlyContinue
  OK "Crown Connection associated"
}

Step "6. Disconnect"
Disconnect-PnPOnline
OK "Done. Target: $TargetEnv ($siteUrl)"
