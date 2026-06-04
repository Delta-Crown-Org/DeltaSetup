#Requires -Version 7.0
#Requires -Modules @{ModuleName="Az";ModuleVersion="12.0.0"}
<#
.SYNOPSIS
  Register Entra ID app for Delta Crown Extensions Freshdesk SAML SSO.

.DESCRIPTION
  Creates a single-tenant Azure AD app registration with SAML configuration
  for Freshdesk SSO. Outputs the three values Freshdesk needs:
    - Login URL
    - Azure AD Identifier (Entity ID)
    - Certificate (Base64)

  Run AFTER creating the DCE product in Freshdesk and obtaining the
  ACS URL + Entity ID from Freshdesk Admin → Security → SSO.

.PARAMETER FreshdeskAcsUrl
  The Assertion Consumer Service URL from Freshdesk (e.g. https://deltacrown.freshdesk.com/login/saml)

.PARAMETER FreshdeskEntityId
  The Entity ID from Freshdesk (e.g. https://deltacrown.freshdesk.com)

.PARAMETER TenantId
  The DCE Entra tenant ID. Default: ce62e17d-2feb-4e67-a115-8ea4af68da30

.PARAMETER AppName
  The display name for the app registration. Default: Freshdesk-DCE-SSO

.PARAMETER SignOnUrl
  The user-facing sign-on URL. Default: https://help.deltacrown.com

.EXAMPLE
  .\Register-FreshdeskDCE-SSO.ps1 `
    -FreshdeskAcsUrl "https://deltacrown.freshdesk.com/login/saml" `
    -FreshdeskEntityId "https://deltacrown.freshdesk.com"

.NOTES
  Requires Azure CLI (`az`) authenticated to the DCE tenant.
  Run `az login --tenant ce62e17d-2feb-4e67-a115-8ea4af68da30` first if needed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$FreshdeskAcsUrl,

    [Parameter(Mandatory)]
    [string]$FreshdeskEntityId,

    [string]$TenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30",
    [string]$AppName = "Freshdesk-DCE-SSO",
    [string]$SignOnUrl = "https://help.deltacrown.com"
)

$ErrorActionPreference = "Stop"

# ── Validate Azure CLI auth ──────────────────────────────────────
Write-Host "[SSO] Checking Azure CLI authentication..." -ForegroundColor Cyan
$ctx = az account show --query "{tenant:id, user:name}" -o json 2>$null | ConvertFrom-Json
if (-not $ctx) {
    Write-Error "Not authenticated to Azure CLI. Run: az login --tenant $TenantId"
}
if ($ctx.tenant -ne $TenantId) {
    Write-Error "Authenticated to wrong tenant ($($ctx.tenant)). Run: az login --tenant $TenantId"
}
Write-Host "[SSO] Authenticated as $($ctx.user) in tenant $TenantId" -ForegroundColor Green

# ── Check for existing app ───────────────────────────────────────
Write-Host "[SSO] Checking for existing app '$AppName'..." -ForegroundColor Cyan
$existing = az ad app list --filter "displayName eq '$AppName'" --query "[0].appId" -o tsv 2>$null
if ($existing) {
    Write-Warning "App '$AppName' already exists (AppId: $existing). Use Update-FreshdeskDCE-SSO.ps1 to modify, or delete first."
    exit 1
}

# ── Create the app registration ──────────────────────────────────
Write-Host "[SSO] Creating app registration '$AppName'..." -ForegroundColor Cyan
$appJson = az ad app create `
    --display-name $AppName `
    --sign-in-audience AzureADMyOrg `
    --web-redirect-uris $FreshdeskAcsUrl `
    --enable-id-token-issuance true `
    --query "{appId:appId, objId:id}" -o json 2>$null | ConvertFrom-Json

if (-not $appJson) {
    Write-Error "Failed to create app registration. Check Azure CLI output above."
}

$appId = $appJson.appId
$objectId = $appJson.objId
Write-Host "[SSO] Created app: $appId" -ForegroundColor Green

# ── Add optional claims (email, givenName, surname) ───────────────
Write-Host "[SSO] Configuring optional claims..." -ForegroundColor Cyan
$optionalClaims = @{
    idToken = @(
        @{name="email"; source="user"; essential=$false}
        @{name="given_name"; source="user"; essential=$false}
        @{name="family_name"; source="user"; essential=$false}
    )
} | ConvertTo-Json -Depth 5 -Compress

# Use Graph API to patch optional claims
az rest --method PATCH `
    --uri "https://graph.microsoft.com/v1.0/applications/$objectId" `
    --headers "Content-Type=application/json" `
    --body "{`"optionalClaims`":$optionalClaims}" 2>$null | Out-Null

# ── Generate self-signed certificate for SAML signing ────────────
Write-Host "[SSO] Generating self-signed certificate..." -ForegroundColor Cyan
$certPath = [System.IO.Path]::GetTempFileName() + ".pfx"
$certPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid).Guid))

$cert = New-SelfSignedCertificate `
    -Subject "CN=Freshdesk-DCE-SAML" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeySpec KeyExchange `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(2) `
    -FriendlyName "Freshdesk DCE SAML Signing"

$thumbprint = $cert.Thumbprint
Export-PfxCertificate `
    -Cert "Cert:\CurrentUser\My\$thumbprint" `
    -FilePath $certPath `
    -Password (ConvertTo-SecureString $certPassword -AsPlainText -Force) | Out-Null

# Export public cert as Base64 (for Freshdesk upload)
$publicCert = [System.Convert]::ToBase64String($cert.RawData)

# Add certificate to app registration via Graph
$certPayload = @{
    keyCredentials = @(@{
        type = "AsymmetricX509Cert"
        usage = "Sign"
        key = $publicCert
        displayName = "Freshdesk SAML Signing"
    })
} | ConvertTo-Json -Depth 5 -Compress

az rest --method PATCH `
    --uri "https://graph.microsoft.com/v1.0/applications/$objectId" `
    --headers "Content-Type=application/json" `
    --body $certPayload 2>$null | Out-Null

Write-Host "[SSO] Certificate thumbprint: $thumbprint" -ForegroundColor Green

# ── Configure SAML-specific web properties ──────────────────────
Write-Host "[SSO] Configuring SAML web settings..." -ForegroundColor Cyan
$webSettings = @{
    web = @{
        redirectUris = @($FreshdeskAcsUrl)
        implicitGrantSettings = @{
            enableIdTokenIssuance = $true
        }
    }
} | ConvertTo-Json -Depth 5 -Compress

az rest --method PATCH `
    --uri "https://graph.microsoft.com/v1.0/applications/$objectId" `
    --headers "Content-Type=application/json" `
    --body $webSettings 2>$null | Out-Null

# ── Output the three values Freshdesk needs ──────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FRESHDESK SSO CONFIGURATION — PASTE THESE INTO FRESHDESK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. SAML SSO URL (Login URL):" -ForegroundColor Yellow
Write-Host "   https://login.microsoftonline.com/$TenantId/saml2"
Write-Host ""
Write-Host "2. IdP Entity ID (Azure AD Identifier):" -ForegroundColor Yellow
Write-Host "   https://sts.windows.net/$TenantId/"
Write-Host ""
Write-Host "3. Certificate (Base64) — SAVE THIS TO A .CER FILE:" -ForegroundColor Yellow
Write-Host "   Thumbprint: $thumbprint"
Write-Host "   Valid until: $($cert.NotAfter)"
Write-Host ""
Write-Host "---BEGIN CERTIFICATE---"
Write-Host $publicCert
Write-Host "---END CERTIFICATE---"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  ADDITIONAL SETTINGS FOR FRESHDESK"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   Name ID format: EmailAddress"
Write-Host "   Sign outgoing messages: Yes"
Write-Host "   Sign algorithm: SHA-256"
Write-Host "   Entity ID: $FreshdeskEntityId"
Write-Host "   ACS URL:   $FreshdeskAcsUrl"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── Save report ──────────────────────────────────────────────────
$report = [ordered]@{
    AppName              = $AppName
    AppId                = $appId
    ObjectId             = $objectId
    TenantId             = $TenantId
    FreshdeskAcsUrl      = $FreshdeskAcsUrl
    FreshdeskEntityId    = $FreshdeskEntityId
    SignOnUrl            = $SignOnUrl
    LoginUrl             = "https://login.microsoftonline.com/$TenantId/saml2"
    IdPEntityId          = "https://sts.windows.net/$TenantId/"
    CertificateThumbprint = $thumbprint
    CertificateValidUntil = $cert.NotAfter.ToString("s")
    CertificateBase64    = $publicCert
    CreatedAt            = (Get-Date).ToUniversalTime().ToString("s") + "Z"
}

$reportFile = "freshdesk-dce-sso-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile
Write-Host "[SSO] Report saved to $reportFile" -ForegroundColor Cyan

# Cleanup
Remove-Item $certPath -ErrorAction SilentlyContinue
Remove-Item "Cert:\CurrentUser\My\$thumbprint" -ErrorAction SilentlyContinue

Write-Host "[SSO] Done." -ForegroundColor Green
