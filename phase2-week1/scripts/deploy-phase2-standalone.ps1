# ============================================================================
# PHASE 2: Standalone Deployment — Hub & Spoke Foundation
# ============================================================================
# Deploys the full Phase 2 architecture with minimal auth events:
#   Auth 1: SharePoint Admin (device login) — create sites, hubs, theme
#   Auth 2: Corp-Hub site (device login) — navigation, hub config
#   Auth 3: DCE-Hub site (device login) — branding, navigation, pages
#   Auth 4: Microsoft Graph (device login) — Azure AD groups
#
# Tyler: you'll enter 4 device codes at https://microsoft.com/devicelogin
# ============================================================================

#Requires -Version 5.1

param(
    [string]$TenantName = "deltacrown",
    [string]$OwnerEmail = "tyler@deltacrown.com",
    [switch]$SkipGroups
)

$ErrorActionPreference = "Stop"
$clientId = "6d8820fe-7a7b-4226-bc3b-2c53add3c207"
$tenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
$adminUrl = "https://$TenantName-admin.sharepoint.com"

# Results tracker
$results = @{
    SitesCreated = @()
    HubsRegistered = @()
    HubAssociations = @()
    ThemeApplied = $false
    NavConfigured = @()
    PagesCreated = @()
    GroupsCreated = @()
    Errors = @()
    StartTime = Get-Date
}

function Write-Phase2Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colors = @{
        INFO = "White"; SUCCESS = "Green"; WARNING = "Yellow"
        ERROR = "Red"; STAGE = "Cyan"; CRITICAL = "Magenta"
    }
    $color = $colors[$Level]
    if (!$color) { $color = "White" }
    $prefix = switch ($Level) {
        "SUCCESS"  { "[OK]" }
        "ERROR"    { "[!!]" }
        "WARNING"  { "[??]" }
        "STAGE"    { "[==]" }
        "CRITICAL" { "[XX]" }
        default    { "[..]" }
    }
    Write-Host "$timestamp $prefix $Message" -ForegroundColor $color
}

function Connect-DeviceLogin {
    param([string]$Url, [string]$Label)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  AUTH: $Label" -ForegroundColor Cyan
    Write-Host "  Tyler: enter device code at https://microsoft.com/devicelogin" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    Connect-PnPOnline -Url $Url -DeviceLogin -ClientId $clientId -Tenant $tenantId -ErrorAction Stop
    Write-Phase2Log "Connected to $Label" "SUCCESS"
}

# ============================================================================
# AUTH 1: SharePoint Admin — All tenant-level operations
# ============================================================================
Connect-DeviceLogin -Url $adminUrl -Label "SharePoint Admin Center"

# --- Create Corp-Hub Communication Site ---
Write-Phase2Log "=== STEP 1: Create Corp-Hub ===" "STAGE"

$corpHubUrl = "https://$TenantName.sharepoint.com/sites/corp-hub"
$existing = Get-PnPTenantSite -Url $corpHubUrl -ErrorAction SilentlyContinue
if ($existing) {
    Write-Phase2Log "Corp-Hub already exists: $corpHubUrl" "WARNING"
} else {
    Write-Phase2Log "Creating Corp-Hub Communication Site..."
    New-PnPSite -Type CommunicationSite `
        -Title "Corporate Shared Services" `
        -Url $corpHubUrl `
        -Description "Central hub for shared franchise resources" `
        -Lcid 1033 -TimeZone 10 -Wait
    Write-Phase2Log "Created Corp-Hub: $corpHubUrl" "SUCCESS"
    $results.SitesCreated += "corp-hub"
    Start-Sleep -Seconds 10  # Let it provision
}

# --- Create Corp spoke sites ---
Write-Phase2Log "=== STEP 2: Create Corp Spoke Sites ===" "STAGE"

$corpSpokes = @(
    @{ Path = "corp-hr";       Title = "Corporate HR";       Desc = "Human Resources shared services" }
    @{ Path = "corp-it";       Title = "Corporate IT";       Desc = "IT support and infrastructure" }
    @{ Path = "corp-finance";  Title = "Corporate Finance";  Desc = "Financial services and reporting" }
    @{ Path = "corp-training"; Title = "Corporate Training"; Desc = "Training and development resources" }
)

foreach ($spoke in $corpSpokes) {
    $spokeUrl = "https://$TenantName.sharepoint.com/sites/$($spoke.Path)"
    $exists = Get-PnPTenantSite -Url $spokeUrl -ErrorAction SilentlyContinue
    if ($exists) {
        Write-Phase2Log "  $($spoke.Title) already exists" "WARNING"
    } else {
        New-PnPSite -Type CommunicationSite `
            -Title $spoke.Title -Url $spokeUrl `
            -Description $spoke.Desc `
            -Lcid 1033 -TimeZone 10 -Wait
        Write-Phase2Log "  Created: $($spoke.Title)" "SUCCESS"
        $results.SitesCreated += $spoke.Path
        Start-Sleep -Seconds 5
    }
}

# --- Create DCE-Hub Communication Site ---
Write-Phase2Log "=== STEP 3: Create DCE-Hub ===" "STAGE"

$dceHubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
$existing = Get-PnPTenantSite -Url $dceHubUrl -ErrorAction SilentlyContinue
if ($existing) {
    Write-Phase2Log "DCE-Hub already exists: $dceHubUrl" "WARNING"
} else {
    New-PnPSite -Type CommunicationSite `
        -Title "Delta Crown Extensions Hub" `
        -Url $dceHubUrl `
        -Description "Delta Crown Extensions operational hub" `
        -Lcid 1033 -TimeZone 10 -Wait
    Write-Phase2Log "Created DCE-Hub: $dceHubUrl" "SUCCESS"
    $results.SitesCreated += "dce-hub"
    Start-Sleep -Seconds 10
}

# --- Register Hub Sites ---
Write-Phase2Log "=== STEP 4: Register Hub Sites ===" "STAGE"

foreach ($hub in @(
    @{ Url = $corpHubUrl; Name = "Corp-Hub" },
    @{ Url = $dceHubUrl;  Name = "DCE-Hub" }
)) {
    $existingHub = Get-PnPHubSite -Identity $hub.Url -ErrorAction SilentlyContinue
    if ($existingHub) {
        Write-Phase2Log "  $($hub.Name) already registered as hub" "WARNING"
    } else {
        try {
            Register-PnPHubSite -Site $hub.Url -ErrorAction Stop
            Write-Phase2Log "  Registered: $($hub.Name)" "SUCCESS"
            $results.HubsRegistered += $hub.Name
        }
        catch {
            Write-Phase2Log "  Failed to register $($hub.Name): $_" "ERROR"
            $results.Errors += "Hub registration: $($hub.Name) — $_"
        }
    }
}

# --- Associate DCE-Hub with Corp-Hub ---
Write-Phase2Log "=== STEP 5: Associate DCE-Hub → Corp-Hub ===" "STAGE"

try {
    Add-PnPHubSiteAssociation -Site $dceHubUrl -HubSite $corpHubUrl -ErrorAction Stop
    Write-Phase2Log "Associated DCE-Hub with Corp-Hub" "SUCCESS"
    $results.HubAssociations += "dce-hub → corp-hub"
}
catch {
    Write-Phase2Log "Association may already exist: $_" "WARNING"
}

# --- Associate Corp spokes with Corp-Hub ---
foreach ($spoke in $corpSpokes) {
    $spokeUrl = "https://$TenantName.sharepoint.com/sites/$($spoke.Path)"
    try {
        Add-PnPHubSiteAssociation -Site $spokeUrl -HubSite $corpHubUrl -ErrorAction Stop
        Write-Phase2Log "  Associated $($spoke.Title) → Corp-Hub" "SUCCESS"
        $results.HubAssociations += "$($spoke.Path) → corp-hub"
    }
    catch {
        Write-Phase2Log "  $($spoke.Title) association: $_" "WARNING"
    }
}

# --- Add DCE Theme to tenant ---
Write-Phase2Log "=== STEP 6: Register DCE Theme ===" "STAGE"

$themeName = "Delta Crown Extensions Theme"
$themePalette = @{
    themePrimary          = "#C9A227"
    themeLighterAlt       = "#FBF7EA"
    themeLighter          = "#F2E8C4"
    themeLight            = "#E8D798"
    themeTertiary         = "#D4B44F"
    themeSecondary        = "#C9A227"
    themeDarkAlt          = "#B08D1F"
    themeDark             = "#947719"
    themeDarker           = "#6D5813"
    neutralLighterAlt     = "#F8F8F8"
    neutralLighter        = "#F4F4F4"
    neutralLight          = "#EAEAEA"
    neutralQuaternaryAlt  = "#DADADA"
    neutralQuaternary     = "#D0D0D0"
    neutralTertiaryAlt    = "#C8C8C8"
    neutralTertiary       = "#A19F9D"
    neutralSecondary      = "#605E5C"
    neutralSecondaryAlt   = "#8A8886"
    neutralPrimaryAlt     = "#3B3A39"
    neutralPrimary        = "#1A1A1A"
    neutralDark           = "#201F1E"
    black                 = "#1A1A1A"
    white                 = "#FFFFFF"
    bodyBackground        = "#FFFFFF"
    bodyText              = "#1A1A1A"
}

$existingTheme = Get-PnPTenantTheme -Name $themeName -ErrorAction SilentlyContinue
if (!$existingTheme) {
    Add-PnPTenantTheme -Name $themeName -Palette $themePalette -IsInverted $false
    Write-Phase2Log "Registered theme: $themeName" "SUCCESS"
} else {
    Write-Phase2Log "Theme already exists: $themeName" "WARNING"
}

# Summarize admin session
Write-Phase2Log "Admin session complete. Sites: $($results.SitesCreated.Count), Hubs: $($results.HubsRegistered.Count)" "SUCCESS"
Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 2: Corp-Hub site — Navigation
# ============================================================================
Connect-DeviceLogin -Url $corpHubUrl -Label "Corp-Hub Site ($corpHubUrl)"

Write-Phase2Log "=== STEP 7: Configure Corp-Hub Navigation ===" "STAGE"

$corpNav = @(
    @{ Title = "Home";       Url = $corpHubUrl }
    @{ Title = "HR";         Url = "https://$TenantName.sharepoint.com/sites/corp-hr" }
    @{ Title = "IT Support"; Url = "https://$TenantName.sharepoint.com/sites/corp-it" }
    @{ Title = "Finance";    Url = "https://$TenantName.sharepoint.com/sites/corp-finance" }
    @{ Title = "Training";   Url = "https://$TenantName.sharepoint.com/sites/corp-training" }
    @{ Title = "DCE Hub";    Url = $dceHubUrl }
)

foreach ($nav in $corpNav) {
    try {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $nav.Title -Url $nav.Url -ErrorAction SilentlyContinue
        Write-Phase2Log "  Nav: $($nav.Title)" "SUCCESS"
        $results.NavConfigured += "corp-hub/$($nav.Title)"
    }
    catch {
        Write-Phase2Log "  Nav $($nav.Title): $_" "WARNING"
    }
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 3: DCE-Hub site — Branding, navigation, pages
# ============================================================================
Connect-DeviceLogin -Url $dceHubUrl -Label "DCE-Hub Site ($dceHubUrl)"

# Apply theme
Write-Phase2Log "=== STEP 8: Apply DCE Branding ===" "STAGE"
try {
    Set-PnPWebTheme -Theme $themeName
    Write-Phase2Log "Applied theme: $themeName" "SUCCESS"
    $results.ThemeApplied = $true
}
catch {
    Write-Phase2Log "Theme application failed: $_" "ERROR"
    $results.Errors += "Theme: $_"
}

# Header
try {
    Set-PnPWebHeader -HeaderLayout Standard -HeaderEmphasis Strong
    Write-Phase2Log "Set header styling" "SUCCESS"
}
catch {
    Write-Phase2Log "Header styling: $_" "WARNING"
}

# Navigation
Write-Phase2Log "=== STEP 9: Configure DCE-Hub Navigation ===" "STAGE"

$dceNav = @(
    @{ Title = "Home";            Url = $dceHubUrl }
    @{ Title = "Operations";      Url = "$dceHubUrl/SitePages/Operations.aspx" }
    @{ Title = "Client Services"; Url = "$dceHubUrl/SitePages/Client-Services.aspx" }
    @{ Title = "Marketing";       Url = "$dceHubUrl/SitePages/Marketing.aspx" }
    @{ Title = "Document Center"; Url = "$dceHubUrl/SitePages/Document-Center.aspx" }
)

foreach ($nav in $dceNav) {
    try {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $nav.Title -Url $nav.Url -ErrorAction SilentlyContinue
        Write-Phase2Log "  Nav: $($nav.Title)" "SUCCESS"
        $results.NavConfigured += "dce-hub/$($nav.Title)"
    }
    catch {
        Write-Phase2Log "  Nav $($nav.Title): $_" "WARNING"
    }
}

# Create placeholder pages
Write-Phase2Log "=== STEP 10: Create DCE Pages ===" "STAGE"

foreach ($page in @("Operations", "Client-Services", "Marketing", "Document-Center")) {
    try {
        Add-PnPPage -Name $page -Publish -ErrorAction SilentlyContinue
        Write-Phase2Log "  Page: $page" "SUCCESS"
        $results.PagesCreated += $page
    }
    catch {
        Write-Phase2Log "  Page $page may exist: $_" "WARNING"
    }
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 4: Microsoft Graph — Azure AD Dynamic Groups
# ============================================================================
if (!$SkipGroups) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  AUTH: Microsoft Graph (Azure AD Groups)" -ForegroundColor Cyan
    Write-Host "  Tyler: enter device code at https://microsoft.com/devicelogin" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""

    Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.ReadWrite.All" `
        -TenantId $tenantId -NoWelcome -ErrorAction Stop
    Write-Phase2Log "Connected to Microsoft Graph" "SUCCESS"

    Write-Phase2Log "=== STEP 11: Create Azure AD Groups ===" "STAGE"

    $adGroups = @(
        @{
            DisplayName = "DCE-AllStaff"
            Description = "All Delta Crown Extensions staff"
            MailNickname = "dce-allstaff"
            MembershipRule = '(user.companyName -eq "Delta Crown Extensions")'
        }
        @{
            DisplayName = "DCE-Managers"
            Description = "DCE management team"
            MailNickname = "dce-managers"
            MembershipRule = '(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Manager")'
        }
        @{
            DisplayName = "DCE-Stylists"
            Description = "DCE stylists and technicians"
            MailNickname = "dce-stylists"
            MembershipRule = '(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Stylist")'
        }
        @{
            DisplayName = "DCE-External"
            Description = "External partners and contractors for DCE"
            MailNickname = "dce-external"
            MembershipRule = '(user.userType -eq "Guest") and (user.companyName -eq "Delta Crown Extensions")'
        }
    )

    foreach ($group in $adGroups) {
        $existing = Get-MgGroup -Filter "displayName eq '$($group.DisplayName)'" -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Phase2Log "  Group exists: $($group.DisplayName)" "WARNING"
            continue
        }

        try {
            $newGroup = New-MgGroup -DisplayName $group.DisplayName `
                -Description $group.Description `
                -MailEnabled:$false `
                -MailNickname $group.MailNickname `
                -SecurityEnabled:$true `
                -GroupTypes @("DynamicMembership") `
                -MembershipRule $group.MembershipRule `
                -MembershipRuleProcessingState "On" `
                -ErrorAction Stop

            Write-Phase2Log "  Created group: $($group.DisplayName) (ID: $($newGroup.Id))" "SUCCESS"
            $results.GroupsCreated += $group.DisplayName
        }
        catch {
            Write-Phase2Log "  Failed: $($group.DisplayName) — $_" "ERROR"
            $results.Errors += "Group: $($group.DisplayName) — $_"
        }
    }

    Disconnect-MgGraph -ErrorAction SilentlyContinue
}

# ============================================================================
# COMPLETION
# ============================================================================
$results.EndTime = Get-Date
$duration = $results.EndTime - $results.StartTime

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Green
Write-Host "  PHASE 2 DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Green
Write-Host ""

Write-Phase2Log "Sites created:      $($results.SitesCreated.Count)" "SUCCESS"
Write-Phase2Log "Hubs registered:    $($results.HubsRegistered.Count)" "SUCCESS"
Write-Phase2Log "Hub associations:   $($results.HubAssociations.Count)" "SUCCESS"
Write-Phase2Log "Theme applied:      $($results.ThemeApplied)" "SUCCESS"
Write-Phase2Log "Nav items:          $($results.NavConfigured.Count)" "SUCCESS"
Write-Phase2Log "Pages created:      $($results.PagesCreated.Count)" "SUCCESS"
Write-Phase2Log "Groups created:     $($results.GroupsCreated.Count)" "SUCCESS"
Write-Phase2Log "Errors:             $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})
Write-Phase2Log "Duration:           $($duration.TotalMinutes.ToString('F1')) min" "INFO"

if ($results.Errors.Count -gt 0) {
    Write-Host ""
    Write-Phase2Log "=== ERRORS ===" "ERROR"
    foreach ($err in $results.Errors) {
        Write-Phase2Log "  $err" "ERROR"
    }
}

# Save results
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)
$resultsPath = Join-Path $ProjectRoot "phase2-week1" "docs"
if (!(Test-Path $resultsPath)) { New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null }
$resultsFile = Join-Path $resultsPath "phase2-deploy-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsFile -Force
Write-Phase2Log "Results saved: $resultsFile" "INFO"

Write-Host ""
Write-Phase2Log "Next: Run phase3-week2/scripts/3.1-DCE-Sites-Provisioning.ps1" "INFO"
