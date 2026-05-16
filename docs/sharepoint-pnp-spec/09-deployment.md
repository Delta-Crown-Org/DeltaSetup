# 09 — Deployment

## What "deployment" means here

Three categories of changes that go through the pipeline:

| Category | Examples | Cadence |
|---|---|---|
| **Tokens** | Color change, font swap, type-scale tweak | Rare; high impact |
| **Templates** | New page section, web-part addition, navigation change | Weekly-ish |
| **Content** | Article publishing, owner-spotlight rotation, news posts | Daily — but NOT via this pipeline (Jenna/Karen do this in the SharePoint UI) |

The pipeline owns Tokens + Templates. Content is human-edited live in
SharePoint and not under version control. (We trust SharePoint's
built-in version history.)

## Pre-deploy setup (one-time, by Tyler)

### Step 1 — Register the Entra application

```powershell
Connect-MgGraph -TenantId ce62e17d-2feb-4e67-a115-8ea4af68da30 -Scopes Application.ReadWrite.All

$app = New-MgApplication -DisplayName "dce-sharepoint-deploy" `
                          -SignInAudience "AzureADMyOrg" `
                          -RequiredResourceAccess @(
    @{
      ResourceAppId = "00000003-0000-0000-c000-000000000000"   # Microsoft Graph
      ResourceAccess = @(
        @{ Id = "9492366f-7969-46a4-8d15-ed1a20078fff"; Type = "Role" }   # Sites.ReadWrite.All
        @{ Id = "df021288-bdef-4463-88db-98f22de89214"; Type = "Role" }   # User.Read.All
        @{ Id = "5b567255-7703-4780-807c-7be8301ae99b"; Type = "Role" }   # Group.Read.All
        @{ Id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"; Type = "Role" }   # Directory.Read.All
      )
    },
    @{
      ResourceAppId = "00000003-0000-0ff1-ce00-000000000000"   # SharePoint
      ResourceAccess = @(
        @{ Id = "678536fe-1083-478a-9c59-b99265e6b0d3"; Type = "Role" }   # Sites.FullControl.All
      )
    }
)

# Service principal
New-MgServicePrincipal -AppId $app.AppId

# Grant admin consent
Start-Process "https://login.microsoftonline.com/deltacrown.onmicrosoft.com/adminconsent?client_id=$($app.AppId)"
```

After admin consent, the app has the permissions it needs.

### Step 2 — Generate the deployment certificate

```bash
# Generate self-signed cert
openssl req -newkey rsa:2048 -nodes -keyout dce-deploy.key \
            -x509 -days 365 -out dce-deploy.cer \
            -subj "/CN=dce-sharepoint-deploy"

# Export to PFX with password
read -s -p "Cert password: " PFX_PASS
openssl pkcs12 -export -out dce-deploy.pfx \
               -inkey dce-deploy.key -in dce-deploy.cer \
               -passout pass:$PFX_PASS

# Base64-encode for GitHub Actions
base64 -i dce-deploy.pfx -o dce-deploy.pfx.b64

# (Linux: base64 dce-deploy.pfx > dce-deploy.pfx.b64)

echo "Public cert (upload to Entra app):"; cat dce-deploy.cer
echo ""
echo "GitHub secrets to set:"
echo "  DCE_DEPLOY_PFX           = $(cat dce-deploy.pfx.b64 | tr -d '\n')"
echo "  DCE_DEPLOY_PFX_PASSWORD  = $PFX_PASS"
echo "  DCE_DEPLOY_CLIENT_ID     = $($app.AppId)"
```

Upload `dce-deploy.cer` to the Entra app registration under
"Certificates & secrets". Delete the local `.cer`, `.key`, `.pfx`,
`.pfx.b64` files after secrets are stored.

### Step 3 — Configure GitHub repo secrets

In `Delta-Crown-Org/dce-sharepoint` → Settings → Secrets and variables
→ Actions:

| Secret | Value |
|---|---|
| `DCE_DEPLOY_CLIENT_ID` | `$($app.AppId)` from Step 1 |
| `DCE_DEPLOY_PFX` | base64-encoded PFX from Step 2 |
| `DCE_DEPLOY_PFX_PASSWORD` | the password you set in Step 2 |
| `DCE_TENANT_DOMAIN` | `deltacrown.onmicrosoft.com` |
| `DCE_DEV_SITE_URL` | `https://deltacrown.sharepoint.com/sites/dce-hub-dev` |
| `DCE_DEV_USER` | dev service-account UPN |
| `DCE_DEV_PASS` | dev service-account password |
| `TEAMS_DEPLOY_WEBHOOK` | Teams incoming webhook URL |

### Step 4 — Provision the dev site

```powershell
Connect-PnPOnline -Url https://deltacrown-admin.sharepoint.com -Interactive
New-PnPSite -Type CommunicationSite `
            -Title "DCE Hub (Dev)" `
            -Url https://deltacrown.sharepoint.com/sites/dce-hub-dev `
            -Owner tyler.granlund@deltacrown.com
```

Then apply the same initial template that will be used in prod.

### Step 5 — Provision Brand Center

```powershell
New-PnPSite -Type CommunicationSite `
            -Title "DCE Brand Center" `
            -Url https://deltacrown.sharepoint.com/sites/DCEBrandCenter `
            -Owner tyler.granlund@deltacrown.com
```

Apply Brand Center template (uploads logos, sets default theme).

## Deploy script reference

`scripts/deploy-prod.ps1`:

```powershell
[CmdletBinding()]
param(
  [string]$CertPath = "./cert.pfx",
  [string]$Target = "prod"  # 'dev' or 'prod'
)

$ErrorActionPreference = "Stop"

$siteRoot = if ($Target -eq "dev") {
  "https://deltacrown.sharepoint.com/sites/dce-hub-dev"
} else {
  "https://deltacrown.sharepoint.com/sites/dce-hub"
}

Write-Host "Deploying to: $siteRoot"

# Connect
$securePass = ConvertTo-SecureString -String $env:CERT_PASS -AsPlainText -Force
Connect-PnPOnline -Url $siteRoot `
                  -ClientId $env:CLIENT_ID `
                  -Tenant $env:TENANT `
                  -CertificatePath $CertPath `
                  -CertificatePassword $securePass

# Backup current state
$timestamp = Get-Date -Format "yyyyMMddTHHmmssZ"
$backupDir = "backups/$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force
Get-PnPSiteTemplate -Out "$backupDir/snapshot.xml" -IncludeAllPages

# Apply templates in order
Get-ChildItem templates/hub -Filter "*.xml" | Sort-Object Name | ForEach-Object {
  Write-Host "Applying $($_.Name)..."
  Invoke-PnPSiteTemplate -Path $_.FullName
}

# Apply theme
$theme = Get-Content dist/sharepoint/theme.json | ConvertFrom-Json -AsHashtable
Add-PnPTenantTheme -Identity "DCE" -Palette $theme.palette -IsInverted $false -Overwrite
Set-PnPWebTheme -Theme "DCE"

# Disconnect
Disconnect-PnPOnline

Write-Host "Deploy complete. Backup at: $backupDir"
```

## Brand Center provisioning

Brand Center is configured separately because it's tenant-wide, not
site-specific.

```powershell
# Configure DCE theme tenant-wide
Connect-PnPOnline -Url https://deltacrown-admin.sharepoint.com `
                  -ClientId $env:CLIENT_ID -Tenant $env:TENANT `
                  -CertificatePath ./cert.pfx -CertificatePassword $securePass

$dceTheme = @{
  "themePrimary"   = "#006B5E"
  "themeLighterAlt" = "#f0f9f8"
  "themeLighter"   = "#c5e9e4"
  "themeLight"     = "#9dd8d0"
  "themeTertiary"  = "#5db7a9"
  "themeSecondary" = "#2a9286"
  "themeDarkAlt"   = "#006057"
  "themeDark"      = "#00524a"
  "themeDarker"    = "#003c36"
  "neutralLighterAlt" = "#fafaf7"
  # ... full palette ...
}

Add-PnPTenantTheme -Identity "DCE" -Palette $dceTheme -IsInverted $false -Overwrite
```

## Post-deploy verification

Every deploy ends with:

1. **Playwright smoke test** — `tests/playwright/smoke.spec.ts` against
   live URLs.
2. **Screenshot comparison** — visual regression baseline check.
3. **Audit log entry** — write to `/sites/dce-hub/Lists/DeployLog`
   with timestamp, commit SHA, status.
4. **Teams notification** — success / fail to deploy channel.

If any step fails: deploy is marked degraded; on-call engineer (Tyler
during v1) is paged via Teams.

## Maintenance / lifecycle

### Certificate rotation (annual)

Calendar reminder + GitHub Actions workflow that warns 30 days
before cert expiry. Procedure: generate new cert, upload to Entra app
(keep old as fallback for 7 days), update GitHub secret, redeploy.

### Permission audit (weekly cron)

Runs every Monday 06:00 UTC via `permission-audit.yml`. Outputs:

- `out/permission-audit-<timestamp>.csv` (snapshot of all unique role
  assignments).
- `out/drift-detected.txt` (only if drift vs. `reference/permission-breaks.csv`).

### Token regeneration

Anytime `tokens/**` changes, the pipeline:

1. Rebuilds tokens.
2. If prod deploy: re-applies the theme (`Add-PnPTenantTheme`).
3. SPFx components are NOT redeployed on token-only changes — they
   reference tokens at runtime via CSS variables.

## Disaster recovery

| Scenario | Recovery |
|---|---|
| Bad deploy corrupts page | Restore from `backups/<timestamp>/snapshot.xml` |
| Site deletion (accident) | SharePoint admin restore (93-day window) |
| Tenant compromise | Out of scope for this pipeline; tenant-level IR plan |
| Lost cert | Generate new, re-grant consent; old cert can be revoked |
| Lost client secret | n/a — we use cert auth only |

## Rollback procedure (concrete)

```powershell
# Identify the bad deploy commit
git log --oneline -20

# Check out the prior known-good commit
git checkout <good-sha>

# Apply just the templates from that commit
Connect-PnPOnline -Url https://deltacrown.sharepoint.com/sites/dce-hub `
                  -ClientId $env:CLIENT_ID -Tenant $env:TENANT `
                  -CertificatePath ./cert.pfx -CertificatePassword $securePass

Invoke-PnPSiteTemplate -Path templates/hub/<latest-known-good>.xml
```

If templates alone don't fully revert (e.g., a web part removal),
restore from the snapshot backup:

```powershell
Invoke-PnPSiteTemplate -Path backups/<timestamp>/snapshot.xml
```
