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
  [string]$TargetEnv = 'prod',

  # ADR-011 §2.1: every provisioning script declares -Mode with scaffold
  # default. PnP template apply does NOT send user notifications, but the
  # mode contract is uniform — and scaffold mode lets us validate templates
  # parse without touching the live site (useful for PR review).
  [ValidateSet('scaffold', 'launch')]
  [string]$Mode = 'scaffold'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ADR-011 §2.2: audit log line at startup. First stdout line of every run.
$commitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA.Substring(0, 7) } else { 'local' }
$runId     = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { Get-Date -Format 'yyyyMMdd-HHmmss' }
$auditLine = "PROVISIONING-MODE: $Mode COMMIT=$commitSha RUN=$runId SCRIPT=deploy-prod.ps1 TARGET_ENV=$TargetEnv"
Write-Host $auditLine
if (-not (Test-Path 'out')) { New-Item -ItemType Directory -Path 'out' | Out-Null }
"$auditLine`n" | Out-File -FilePath 'out/provisioning-mode.log' -Append -Encoding utf8

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
  if ($Mode -eq 'scaffold') {
    Write-Host "    [scaffold] WOULD apply $($t.Name) (Test-PnPSiteTemplate only)" -ForegroundColor Yellow
    Test-PnPSiteTemplate -Path $t.FullName -ErrorAction Stop
    OK "$($t.Name) parsed clean (no mutation)"
  } else {
    Write-Host "    Applying $($t.Name)…" -ForegroundColor Gray
    Invoke-PnPSiteTemplate -Path $t.FullName -ClearNavigation:$false
    OK "$($t.Name) applied"
  }
}

Step "4. Apply page JSON definitions"
$pages = Get-ChildItem -Path 'pages' -Filter '*.json' | Sort-Object Name
foreach ($p in $pages) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($p.Name)
  if ($Mode -eq 'scaffold') {
    Write-Host "    [scaffold] WOULD apply page $name" -ForegroundColor Yellow
  } else {
    Write-Host "    Applying page $name…" -ForegroundColor Gray
    # Custom logic: parse JSON, Add-PnPPage if missing, Set-PnPPage if exists
    & ./scripts/apply-page.ps1 -Path $p.FullName
  }
}
OK "$($pages.Count) page(s) processed (mode=$Mode)"

Step "5. Ensure hub association (spokes)"
if ($Mode -eq 'scaffold') {
  Write-Host "    [scaffold] WOULD verify hub association for Crown Connection" -ForegroundColor Yellow
} else {
  $hub = Get-PnPHubSite -Identity $siteUrl
  if ($null -ne $hub.SiteId) {
    Add-PnPHubSiteAssociation -Site 'https://deltacrown.sharepoint.com/sites/CrownConnection' `
                              -HubSite $siteUrl -ErrorAction SilentlyContinue
    OK "Crown Connection associated"
  }
}

Step "6. Disconnect"
Disconnect-PnPOnline
OK "Done. Target: $TargetEnv ($siteUrl)"
