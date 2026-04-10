# ============================================================================
# PHASE 2.2: Delta Crown Extensions Hub Setup (REMEDIATED)
# Delta Crown Extensions - SharePoint Hub & Spoke Architecture
# ============================================================================
# VERSION: 2.1.0
# DESCRIPTION: Creates DCE Hub with branding, registers hub, links to Corp-Hub
# BRANDING: Gold #C9A227, Black #1A1A1A (from brand guide)
# REMEDIATION: Module version constraints, auth integration, polling
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^https://[a-zA-Z0-9-]+\.sharepoint\.com(/.*)?$')]
    [string]$AdminUrl = "https://deltacrown-admin.sharepoint.com",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9-]{3,64}$')]
    [string]$TenantName = "deltacrown",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^/sites/[a-zA-Z0-9-]+$')]
    [string]$CorpHubUrl = "/sites/corp-hub",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^/sites/[a-zA-Z0-9-]+$')]
    [string]$DCEHubUrl = "/sites/dce-hub",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$OwnerEmail = $null,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBusinessPremiumWarning
)

# Error handling
$ErrorActionPreference = "Stop"

# ============================================================================
# PATH RESOLUTION
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

# ============================================================================
# MODULE IMPORT
# ============================================================================
$ModulesPath = Join-Path $ProjectRoot "phase2-week1" "modules"

Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# Load configuration
$ConfigPath = Join-Path $ModulesPath "DeltaCrown.Config.psd1"
$Config = Import-PowerShellDataFile -Path $ConfigPath

# ============================================================================
# LOGGING SETUP
# ============================================================================
$LogPath = Join-Path $ProjectRoot $Config.Logging.LogPath
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}
$LogFile = Join-Path $LogPath "DCEHub-Provisioning-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# BRANDING CONFIGURATION
# ============================================================================
$BrandColors = @{
    Gold = "#C9A227"      # Primary brand color
    Black = "#1A1A1A"     # Secondary/background
    White = "#FFFFFF"     # Text on dark
    GoldLight = "#D4B43F" # Hover states
    GoldDark = "#B08D1F"  # Active states
}

# ============================================================================
# SITE CONFIGURATION
# ============================================================================
$DCEHubConfig = @{
    Url = $DCEHubUrl
    Title = "Delta Crown Extensions Hub"
    Description = "Delta Crown Extensions operational hub"
    Template = "SITEPAGEPUBLISHING#0"
    Owner = $OwnerEmail
    TimeZone = 10
}

$DCEHubNavigation = @(
    @{ Title = "Home"; Url = $DCEHubUrl; IsHome = $true },
    @{ Title = "Operations"; Url = "$DCEHubUrl/SitePages/Operations.aspx"; IsHome = $false },
    @{ Title = "Client Services"; Url = "$DCEHubUrl/SitePages/Client-Services.aspx"; IsHome = $false },
    @{ Title = "Marketing"; Url = "$DCEHubUrl/SitePages/Marketing.aspx"; IsHome = $false },
    @{ Title = "Document Center"; Url = "$DCEHubUrl/SitePages/Document-Center.aspx"; IsHome = $false }
)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownLog "=== Starting Delta Crown Extensions Hub Provisioning ===" "STAGE"
    Write-DeltaCrownLog "Tenant: $TenantName"
    Write-DeltaCrownLog "Admin URL: $AdminUrl"
    
    # Business Premium Warning
    if (!$SkipBusinessPremiumWarning) {
        Show-DeltaCrownBusinessPremiumWarning -ForceAcknowledgment ($Environment -eq "Production")
    }
    
    # R2.4A: Require OwnerEmail as parameter (no interactive Read-Host)
    if (!$OwnerEmail) {
        throw "OwnerEmail parameter is required. Pass -OwnerEmail 'admin@example.com'"
    }
    $DCEHubConfig.Owner = $OwnerEmail
    
    $dceHubUrl = "https://$TenantName.sharepoint.com$($DCEHubConfig.Url)"
    $corpHubFullUrl = "https://$TenantName.sharepoint.com$CorpHubUrl"
    
    # ------------------------------------------------------------------------
    # STEP 1: Connect to SharePoint Admin (R2.1)
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "Connecting to SharePoint Admin Center..."
    Connect-DeltaCrownSharePoint -Url $AdminUrl -Environment $Environment
    Write-DeltaCrownLog "Connected successfully" "SUCCESS"
    
    # ------------------------------------------------------------------------
    # STEP 2: Create DCE-Hub Communication Site
    # ------------------------------------------------------------------------
    Write-Log "Creating DCE Hub Communication Site..."
    
    $existingSite = Get-PnPTenantSite -Url $dceHubUrl -ErrorAction SilentlyContinue
    if ($existingSite) {
        Write-Log "DCE Hub site already exists at $dceHubUrl" "WARNING"
    } else {
        New-PnPSite -Type CommunicationSite `
            -Title $DCEHubConfig.Title `
            -Url $dceHubUrl `
            -Description $DCEHubConfig.Description `
            -Owner $DCEHubConfig.Owner `
            -Lcid 1033 `
            -TimeZone $DCEHubConfig.TimeZone `
            -Wait
        
        Write-Log "Created DCE Hub: $dceHubUrl" "SUCCESS"
        # R2.4C: Poll for site readiness instead of fixed delay
        Wait-DeltaCrownSiteProvisioned -SiteUrl $dceHubUrl -TimeoutSeconds 120
    }
    
    # ------------------------------------------------------------------------
    # STEP 3: Apply DCE Branding
    # ------------------------------------------------------------------------
    Write-Log "Applying Delta Crown Extensions branding..."
    
    Connect-PnPOnline -Url $dceHubUrl -Interactive
    
    # Apply theme
    $themeName = "Delta Crown Extensions Theme"
    $themePalette = @{
        themePrimary = $BrandColors.Gold
        themeLighterAlt = "#FBF7EA"
        themeLighter = "#F2E8C4"
        themeLight = "#E8D798"
        themeTertiary = "#D4B44F"
        themeSecondary = "#C9A227"
        themeDarkAlt = "#B08D1F"
        themeDark = "#947719"
        themeDarker = "#6D5813"
        neutralLighterAlt = "#F8F8F8"
        neutralLighter = "#F4F4F4"
        neutralLight = "#EAEAEA"
        neutralQuaternaryAlt = "#DADADA"
        neutralQuaternary = "#D0D0D0"
        neutralTertiaryAlt = "#C8C8C8"
        neutralTertiary = "#A19F9D"
        neutralSecondary = "#605E5C"
        neutralSecondaryAlt = "#8A8886"
        neutralPrimaryAlt = "#3B3A39"
        neutralPrimary = $BrandColors.Black
        neutralDark = "#201F1E"
        black = "#1A1A1A"
        white = $BrandColors.White
        bodyBackground = $BrandColors.White
        bodyText = $BrandColors.Black
    }
    
    # Add theme to tenant
    Connect-PnPOnline -Url $AdminUrl -Interactive
    $existingTheme = Get-PnPTenantTheme -Name $themeName -ErrorAction SilentlyContinue
    if (!$existingTheme) {
        Add-PnPTenantTheme -Name $themeName -Palette $themePalette -IsInverted $false
        Write-Log "Added tenant theme: $themeName" "SUCCESS"
    } else {
        Write-Log "Theme $themeName already exists" "WARNING"
    }
    
    # Apply theme to DCE Hub
    Connect-PnPOnline -Url $dceHubUrl -Interactive
    Set-PnPWebTheme -Theme $themeName
    Write-Log "Applied theme to DCE Hub" "SUCCESS"
    
    # Set header styling
    Write-Log "Configuring site header..."
    Set-PnPWebHeader -HeaderLayout Standard -HeaderEmphasis Strong
    
    # ------------------------------------------------------------------------
    # STEP 4: Register DCE-Hub as Hub Site
    # ------------------------------------------------------------------------
    Write-Log "Registering DCE-Hub as Hub Site..."
    
    $existingHub = Get-PnPHubSite -Identity $dceHubUrl -ErrorAction SilentlyContinue
    if ($existingHub) {
        Write-Log "DCE-Hub is already registered as Hub Site" "WARNING"
        $dceHubId = $existingHub.SiteId
    } else {
        Register-PnPHubSite -Site $dceHubUrl
        $dceHubId = (Get-PnPSite -Includes Id).Id
        Write-Log "Registered DCE-Hub as Hub Site (ID: $dceHubId)" "SUCCESS"
    }
    
    # Export IDs
    # R2.4A: No hard-coded paths
    $dceHubIdPath = Join-Path $ProjectRoot "phase2-week1" "docs" "dce-hub-id.txt"
    $dceHubId | Out-File -FilePath $dceHubIdPath -Force
    $dceHubConfigPath = Join-Path $ProjectRoot "phase2-week1" "docs" "dce-hub-config.json"
    $dceConfig = @{
        DCEHubId = $dceHubId
        DCEHubUrl = $dceHubUrl
        CorpHubUrl = $corpHubFullUrl
        BrandingApplied = $true
        ExportedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    # R2.2B: Encrypted export for sensitive hub configuration
    Export-DeltaCrownSecureData -Data $dceConfig -Path "$dceHubConfigPath.enc" -AlsoExportPlaintext:($Environment -eq "Development")
    # Keep plaintext for backward compatibility
    $dceConfig | ConvertTo-Json | Out-File -FilePath $dceHubConfigPath -Force
    
    Write-Log "DCE Hub configuration saved" "SUCCESS"
    
    # ------------------------------------------------------------------------
    # STEP 5: Link DCE-Hub to Corp-Hub (Hub-to-Hub Association)
    # ------------------------------------------------------------------------
    Write-Log "Linking DCE-Hub to Corp-Hub..."
    
    Connect-PnPOnline -Url $AdminUrl -Interactive
    
    # Get Corp-Hub ID from previous step
    # R2.4A: No hard-coded paths
    $corpHubIdPath = Join-Path $ProjectRoot "phase2-week1" "docs" "corp-hub-id.txt"
    $corpHubId = Get-Content -Path $corpHubIdPath -ErrorAction SilentlyContinue
    if (!$corpHubId) {
        $corpHubId = (Get-PnPHubSite -Identity $corpHubFullUrl).SiteId
    }
    
    # Associate DCE-Hub as child of Corp-Hub
    # Note: In SharePoint, this creates a hub-to-hub relationship
    Connect-PnPOnline -Url $dceHubUrl -Interactive
    
    $currentConnection = Get-PnPHubSiteConnection -ErrorAction SilentlyContinue
    if ($currentConnection -and $currentConnection.Id -eq $corpHubId) {
        Write-Log "DCE-Hub is already linked to Corp-Hub" "WARNING"
    } else {
        Add-PnPHubSiteAssociation -Site $dceHubUrl -HubSite $corpHubFullUrl
        Write-Log "Linked DCE-Hub to Corp-Hub" "SUCCESS"
    }
    
    # ------------------------------------------------------------------------
    # STEP 6: Configure DCE Navigation Structure
    # ------------------------------------------------------------------------
    Write-Log "Configuring DCE Hub navigation..."
    
    Connect-PnPOnline -Url $dceHubUrl -Interactive
    
    # Note: Hub navigation inherits from parent, but we can add DCE-specific items
    foreach ($navItem in $DCEHubNavigation) {
        $nodeUrl = if ($navItem.IsHome) { $dceHubUrl } else { "https://$TenantName.sharepoint.com$($navItem.Url)" }
        
        try {
            Add-PnPNavigationNode -Location HubNavigation `
                -Title $navItem.Title `
                -Url $nodeUrl `
                -First
            Write-Log "Added navigation node: $($navItem.Title)" "SUCCESS"
        }
        catch {
            Write-Log "Navigation node may already exist: $_" "WARNING"
        }
    }
    
    # ------------------------------------------------------------------------
    # STEP 7: Create Initial Page Structure
    # ------------------------------------------------------------------------
    Write-Log "Creating initial page structure..."
    
    $pagesToCreate = @(
        "Operations",
        "Client-Services",
        "Marketing",
        "Document-Center"
    )
    
    foreach ($pageName in $pagesToCreate) {
        try {
            $page = Add-PnPPage -Name $pageName -Publish -ErrorAction SilentlyContinue
            Write-Log "Created page: $pageName" "SUCCESS"
        }
        catch {
            Write-Log "Page $pageName may already exist" "WARNING"
        }
    }
    
    # ------------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------------
    Write-Log "=== Delta Crown Extensions Hub Setup Complete ===" "SUCCESS"
    Write-Log "DCE Hub Site: $dceHubUrl"
    Write-Log "DCE Hub ID: $dceHubId"
    Write-Log "Linked to Corp-Hub: $corpHubFullUrl"
    Write-Log "Branding: Gold/Black theme applied"
    Write-Log "Log saved to: $LogFile"
    
    return [PSCustomObject]@{
        DCEHubUrl = $dceHubUrl
        DCEHubId = $dceHubId
        CorpHubUrl = $corpHubFullUrl
        CorpHubId = $corpHubId
        Owner = $DCEHubConfig.Owner
        Branding = $themeName
        Status = "SUCCESS"
        Timestamp = Get-Date
    }
}
catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR" -IncludeContext -Exception $_.Exception
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    throw
}
finally {
    Write-Log "Disconnecting from SharePoint..."
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
