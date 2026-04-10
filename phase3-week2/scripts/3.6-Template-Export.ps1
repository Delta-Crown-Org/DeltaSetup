# ============================================================================
# PHASE 3.6: PnP Template Export
# Delta Crown Extensions — Capture Sites as Reusable Templates
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Exports all 4 DCE sites as PnP provisioning templates,
#              parameterizes brand values, generates companion scripts
# DEPENDS ON: ALL Phase 3 components deployed and verified
# ADR: ADR-002 Phase 3 — Template Capture Strategy
# FIXES: A3 (connection ownership), B7 (path separators)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = "https://deltacrownext-admin.sharepoint.com",
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = $null,
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development"
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.1.0"

# ============================================================================
# PATH RESOLUTION (B7: Join-Path everywhere)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$LogPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.6-Template-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

if (!$OutputPath) {
    $OutputPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "templates")
}
if (!(Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# ============================================================================
# CONNECTION OWNERSHIP (A3)
# ============================================================================
$script:OwnsPnPConnection = $false

# ============================================================================
# TEMPLATE DEFINITIONS
# ============================================================================
$TemplateSites = @(
    @{ Url = "/sites/dce-operations";     FileName = "DCE-Operations-Template.xml" }
    @{ Url = "/sites/dce-clientservices";  FileName = "DCE-ClientServices-Template.xml" }
    @{ Url = "/sites/dce-marketing";       FileName = "DCE-Marketing-Template.xml" }
    @{ Url = "/sites/dce-docs";            FileName = "DCE-Docs-Template.xml" }
)

$BrandParameters = @{
    "{BrandName}"       = "Delta Crown Extensions"
    "{BrandPrefix}"     = "DCE"
    "{BrandDomain}"     = "deltacrown.com.au"
    "{PrimaryColor}"    = "#C9A227"
    "{SecondaryColor}"  = "#1A1A1A"
    "{TenantName}"      = $TenantName
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.6: PnP Template Export"
    Write-DeltaCrownLog "Output: $OutputPath" "INFO"

    $results = @{
        TemplatesExported = @()
        Hashes            = @{}
        Errors            = @()
        StartTime         = Get-Date
    }

    # ------------------------------------------------------------------
    # CONNECTION SETUP (A3: check if Master pre-authed)
    # ------------------------------------------------------------------
    $existingCtx = Get-PnPContext -ErrorAction SilentlyContinue
    if (!$existingCtx) {
        Connect-DeltaCrownSharePoint -Url $AdminUrl
        $script:OwnsPnPConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established SharePoint connection" "INFO"
    }

    # ------------------------------------------------------------------
    # STEP 1: Export PnP templates from each site
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 1: Export Site Templates ===" "STAGE"

    foreach ($site in $TemplateSites) {
        $fullUrl = "https://$TenantName.sharepoint.com$($site.Url)"
        $outFile = Join-Path $OutputPath $site.FileName

        try {
            Write-DeltaCrownLog "Exporting: $($site.Url) → $($site.FileName)" "INFO"

            Connect-DeltaCrownSharePoint -Url $fullUrl

            if ($PSCmdlet.ShouldProcess($fullUrl, "Export PnP template")) {
                Get-PnPSiteTemplate -Out $outFile `
                    -Handlers Lists, Fields, ContentTypes, CustomActions, Navigation, Pages `
                    -IncludeAllPages `
                    -Force

                Write-DeltaCrownLog "  Exported: $($site.FileName)" "SUCCESS"
                $results.TemplatesExported += $site.FileName

                # Calculate SHA-256 hash
                $hash = (Get-FileHash -Path $outFile -Algorithm SHA256).Hash
                $results.Hashes[$site.FileName] = $hash
                Write-DeltaCrownLog "  SHA-256: $hash" "DEBUG"
            }
        }
        catch {
            Write-DeltaCrownLog "Failed to export $($site.Url): $_" "ERROR"
            $results.Errors += "Export failed: $($site.Url) — $_"
        }
    }

    # ------------------------------------------------------------------
    # STEP 2: Export DCE Hub theme
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 2: Export Hub Theme ===" "STAGE"

    try {
        Connect-DeltaCrownSharePoint -Url $AdminUrl
        $theme = Get-PnPTenantTheme -Name "Delta Crown Extensions Theme" -ErrorAction Stop

        $themeFile = Join-Path $OutputPath "DCE-Hub-Theme.json"
        $theme | ConvertTo-Json -Depth 5 | Out-File -FilePath $themeFile -Force
        $results.TemplatesExported += "DCE-Hub-Theme.json"

        $hash = (Get-FileHash -Path $themeFile -Algorithm SHA256).Hash
        $results.Hashes["DCE-Hub-Theme.json"] = $hash

        Write-DeltaCrownLog "Exported theme: DCE-Hub-Theme.json" "SUCCESS"
    }
    catch {
        Write-DeltaCrownLog "Failed to export theme: $_" "ERROR"
        $results.Errors += "Theme export failed: $_"
    }

    # ------------------------------------------------------------------
    # STEP 3: Save hash manifest
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 3: Save Hash Manifest ===" "STAGE"

    $hashFile = Join-Path $OutputPath "template-hashes.json"
    $hashManifest = @{
        GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        TenantName  = $TenantName
        ScriptVersion = $scriptVersion
        Hashes      = $results.Hashes
    }
    $hashManifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $hashFile -Force
    Write-DeltaCrownLog "Hash manifest saved: $hashFile" "SUCCESS"

    # ------------------------------------------------------------------
    # STEP 4: Generate brand-config.psd1 template
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 4: Generate Brand Config Template ===" "STAGE"

    $brandConfigContent = @"
# ============================================================================
# Brand Configuration Template
# Replace all {BrandXxx} placeholders with actual brand values
# ============================================================================
@{
    BrandName       = "{BrandName}"
    BrandPrefix     = "{BrandPrefix}"
    BrandDomain     = "{BrandDomain}"
    PrimaryColor    = "{PrimaryColor}"
    SecondaryColor  = "{SecondaryColor}"
    TenantName      = "{TenantName}"

    Sites = @{
        Operations     = "/sites/{BrandPrefix}-operations"
        ClientServices = "/sites/{BrandPrefix}-clientservices"
        Marketing      = "/sites/{BrandPrefix}-marketing"
        Docs           = "/sites/{BrandPrefix}-docs"
        Hub            = "/sites/{BrandPrefix}-hub"
    }

    Groups = @{
        AllStaff   = "SG-{BrandPrefix}-AllStaff"
        Leadership = "SG-{BrandPrefix}-Leadership"
        Marketing  = "SG-{BrandPrefix}-Marketing"
    }

    Mailboxes = @(
        @{ Name = "{BrandPrefix} Operations"; Email = "operations@{BrandDomain}" }
        @{ Name = "{BrandPrefix} Bookings";   Email = "bookings@{BrandDomain}" }
        @{ Name = "{BrandPrefix} Info";        Email = "info@{BrandDomain}" }
    )

    Team = @{
        DisplayName  = "{BrandName} Operations"
        MailNickname = "{BrandPrefix}-operations"
    }

    DLP = @{
        PolicyName = "{BrandPrefix}-Data-Protection"
        TestDays   = 30
    }
}
"@

    $brandConfigFile = Join-Path $OutputPath "brand-config.psd1"
    $brandConfigContent | Out-File -FilePath $brandConfigFile -Force
    Write-DeltaCrownLog "Brand config template saved: $brandConfigFile" "SUCCESS"

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = Get-Date
    $duration = $results.EndTime - $results.StartTime

    Write-DeltaCrownBanner "PHASE 3.6 COMPLETE"
    Write-DeltaCrownLog "Templates exported:  $($results.TemplatesExported.Count)" "SUCCESS"
    Write-DeltaCrownLog "Hash manifest:       $hashFile" "SUCCESS"
    Write-DeltaCrownLog "Brand config:        $brandConfigFile" "SUCCESS"
    Write-DeltaCrownLog "Errors:              $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})

    $resultsPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.6-template-results.json"))
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force

    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        TemplatesExported = $results.TemplatesExported
        Hashes            = $results.Hashes
        Errors            = $results.Errors
        Status            = if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.6: $_" "CRITICAL"
    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    if ($script:OwnsPnPConnection) {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }
}
