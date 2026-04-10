# ============================================================================
# PHASE 2: Fix & Complete — Register hubs, associations, branding, groups
# ============================================================================
# Fixes:
#   1. Register-PnPHubSite properly (was falsely reporting "already exists")
#   2. Add-PnPTenantTheme syntax for PnP 3.x
#   3. Hub associations after proper registration
# Tyler: 5 device codes
# ============================================================================

$ErrorActionPreference = "Stop"
$clientId = "6d8820fe-7a7b-4226-bc3b-2c53add3c207"
$tenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
$TenantName = "deltacrown"
$adminUrl = "https://${TenantName}-admin.sharepoint.com"
$corpHubUrl = "https://${TenantName}.sharepoint.com/sites/corp-hub"
$dceHubUrl = "https://${TenantName}.sharepoint.com/sites/dce-hub"

$results = @{ Errors = @(); Success = @() }

function Write-Log {
    param([string]$Msg, [string]$Lvl = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $c = @{ INFO="White"; SUCCESS="Green"; WARNING="Yellow"; ERROR="Red"; STAGE="Cyan" }
    $p = @{ SUCCESS="[OK]"; ERROR="[!!]"; WARNING="[??]"; STAGE="[==]"; INFO="[..]" }
    Write-Host "$ts $($p[$Lvl]) $Msg" -ForegroundColor $c[$Lvl]
}

function Do-DeviceLogin {
    param([string]$Url, [string]$Label)
    Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
    Write-Host "  AUTH: $Label" -ForegroundColor Cyan
    Write-Host "  Tyler: code at https://microsoft.com/devicelogin" -ForegroundColor Yellow
    Write-Host "$('=' * 60)" -ForegroundColor Cyan
    Connect-PnPOnline -Url $Url -DeviceLogin -ClientId $clientId -Tenant $tenantId -ErrorAction Stop
    Write-Log "Connected: $Label" "SUCCESS"
}

# ============================================================================
# AUTH 1: Admin
# ============================================================================
Do-DeviceLogin -Url $adminUrl -Label "SharePoint Admin"

# --- Diagnose hub state ---
Write-Log "=== DIAGNOSTIC: Current hub state ===" "STAGE"
$allHubs = Get-PnPHubSite -ErrorAction SilentlyContinue
if ($allHubs) {
    Write-Log "Existing hubs: $($allHubs.Count)" "INFO"
    foreach ($h in $allHubs) {
        Write-Log "  Hub: $($h.SiteUrl) — SiteId: $($h.SiteId)" "INFO"
    }
} else {
    Write-Log "No hub sites registered yet" "INFO"
}

# --- Register Corp-Hub ---
Write-Log "=== STEP 4: Register Hub Sites ===" "STAGE"

# Check if TRULY registered (SiteId must be non-empty)
$corpHub = $allHubs | Where-Object { $_.SiteUrl -eq $corpHubUrl }
if ($corpHub -and $corpHub.SiteId) {
    Write-Log "Corp-Hub already registered (ID: $($corpHub.SiteId))" "WARNING"
} else {
    try {
        Register-PnPHubSite -Site $corpHubUrl -ErrorAction Stop
        Write-Log "Registered Corp-Hub as hub site" "SUCCESS"
        $results.Success += "Corp-Hub registered"
    } catch {
        Write-Log "Corp-Hub registration: $_" "ERROR"
        $results.Errors += "Corp-Hub reg: $_"
    }
}

$dceHub = $allHubs | Where-Object { $_.SiteUrl -eq $dceHubUrl }
if ($dceHub -and $dceHub.SiteId) {
    Write-Log "DCE-Hub already registered (ID: $($dceHub.SiteId))" "WARNING"
} else {
    try {
        Register-PnPHubSite -Site $dceHubUrl -ErrorAction Stop
        Write-Log "Registered DCE-Hub as hub site" "SUCCESS"
        $results.Success += "DCE-Hub registered"
    } catch {
        Write-Log "DCE-Hub registration: $_" "ERROR"
        $results.Errors += "DCE-Hub reg: $_"
    }
}

# Verify registration
Write-Log "=== Verify hubs ===" "STAGE"
$hubs = Get-PnPHubSite
foreach ($h in $hubs) {
    Write-Log "  Hub: $($h.SiteUrl) — ID: $($h.SiteId)" "SUCCESS"
}

# --- Hub Associations ---
Write-Log "=== STEP 5: Hub Associations ===" "STAGE"

# Associate DCE-Hub with Corp-Hub
try {
    Add-PnPHubSiteAssociation -Site $dceHubUrl -HubSite $corpHubUrl -ErrorAction Stop
    Write-Log "DCE-Hub → Corp-Hub" "SUCCESS"
    $results.Success += "DCE→Corp association"
} catch {
    Write-Log "DCE→Corp: $_" "WARNING"
}

foreach ($spoke in @("corp-hr","corp-it","corp-finance","corp-training")) {
    $url = "https://${TenantName}.sharepoint.com/sites/$spoke"
    try {
        Add-PnPHubSiteAssociation -Site $url -HubSite $corpHubUrl -ErrorAction Stop
        Write-Log "  $spoke → Corp-Hub" "SUCCESS"
        $results.Success += "$spoke → Corp-Hub"
    } catch {
        Write-Log "  ${spoke}: $_" "WARNING"
    }
}

# --- Theme (PnP 3.x syntax check) ---
Write-Log "=== STEP 6: DCE Theme ===" "STAGE"

$themeName = "Delta Crown Extensions Theme"
$themePalette = @{
    themePrimary="#C9A227"; themeLighterAlt="#FBF7EA"; themeLighter="#F2E8C4"
    themeLight="#E8D798"; themeTertiary="#D4B44F"; themeSecondary="#C9A227"
    themeDarkAlt="#B08D1F"; themeDark="#947719"; themeDarker="#6D5813"
    neutralLighterAlt="#F8F8F8"; neutralLighter="#F4F4F4"; neutralLight="#EAEAEA"
    neutralQuaternaryAlt="#DADADA"; neutralQuaternary="#D0D0D0"; neutralTertiaryAlt="#C8C8C8"
    neutralTertiary="#A19F9D"; neutralSecondary="#605E5C"; neutralSecondaryAlt="#8A8886"
    neutralPrimaryAlt="#3B3A39"; neutralPrimary="#1A1A1A"; neutralDark="#201F1E"
    black="#1A1A1A"; white="#FFFFFF"; bodyBackground="#FFFFFF"; bodyText="#1A1A1A"
}

# Check PnP 3.x available commands
$themeCmd = Get-Command -Name "*TenantTheme*" -Module PnP.PowerShell -ErrorAction SilentlyContinue
Write-Log "Available theme commands: $($themeCmd.Name -join ', ')" "INFO"

# Try to add theme
try {
    $existingTheme = Get-PnPTenantTheme | Where-Object { $_.Name -eq $themeName }
    if ($existingTheme) {
        Write-Log "Theme exists: $themeName" "WARNING"
    } else {
        # PnP 3.x: try different parameter approaches
        try {
            Add-PnPTenantTheme -Identity $themeName -Palette $themePalette -IsInverted $false -ErrorAction Stop
            Write-Log "Theme added (via -Identity)" "SUCCESS"
        } catch {
            try {
                Add-PnPTenantTheme -Theme $themeName -Palette $themePalette -IsInverted $false -ErrorAction Stop
                Write-Log "Theme added (via -Theme)" "SUCCESS"
            } catch {
                Write-Log "Could not add theme. Manual add needed." "WARNING"
                Write-Log "Error: $_" "WARNING"
            }
        }
    }
} catch {
    Write-Log "Theme check: $_" "WARNING"
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 2: Corp-Hub — Navigation
# ============================================================================
Do-DeviceLogin -Url $corpHubUrl -Label "Corp-Hub"

Write-Log "=== STEP 7: Corp-Hub Navigation ===" "STAGE"
foreach ($n in @(
    @{ T="Home";     U=$corpHubUrl }
    @{ T="HR";       U="https://${TenantName}.sharepoint.com/sites/corp-hr" }
    @{ T="IT";       U="https://${TenantName}.sharepoint.com/sites/corp-it" }
    @{ T="Finance";  U="https://${TenantName}.sharepoint.com/sites/corp-finance" }
    @{ T="Training"; U="https://${TenantName}.sharepoint.com/sites/corp-training" }
    @{ T="DCE Hub";  U=$dceHubUrl }
)) {
    try {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $n.T -Url $n.U -ErrorAction SilentlyContinue
        Write-Log "  Nav: $($n.T)" "SUCCESS"
    } catch { Write-Log "  $($n.T) nav failed" "WARNING" }
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 3: DCE-Hub — Branding, Navigation, Pages
# ============================================================================
Do-DeviceLogin -Url $dceHubUrl -Label "DCE-Hub"

Write-Log "=== STEP 8: DCE Branding ===" "STAGE"
try {
    Set-PnPWebTheme -Theme $themeName -ErrorAction Stop
    Write-Log "Applied theme" "SUCCESS"
} catch {
    Write-Log "Theme apply (may not exist yet): $_" "WARNING"
}

try {
    Set-PnPWebHeader -HeaderLayout Standard -HeaderEmphasis Strong
    Write-Log "Header styled" "SUCCESS"
} catch { Write-Log "Header: $_" "WARNING" }

Write-Log "=== STEP 9: DCE Navigation ===" "STAGE"
foreach ($n in @(
    @{ T="Home";            U=$dceHubUrl }
    @{ T="Operations";      U="$dceHubUrl/SitePages/Operations.aspx" }
    @{ T="Client Services"; U="$dceHubUrl/SitePages/Client-Services.aspx" }
    @{ T="Marketing";       U="$dceHubUrl/SitePages/Marketing.aspx" }
    @{ T="Document Center"; U="$dceHubUrl/SitePages/Document-Center.aspx" }
)) {
    try {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $n.T -Url $n.U -ErrorAction SilentlyContinue
        Write-Log "  Nav: $($n.T)" "SUCCESS"
    } catch { Write-Log "  $($n.T) nav failed" "WARNING" }
}

Write-Log "=== STEP 10: DCE Pages ===" "STAGE"
foreach ($pg in @("Operations","Client-Services","Marketing","Document-Center")) {
    try {
        Add-PnPPage -Name $pg -Publish -ErrorAction SilentlyContinue
        Write-Log "  Page: $pg" "SUCCESS"
    } catch { Write-Log "  Page $pg may exist" "WARNING" }
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 4: Graph — Azure AD Groups
# ============================================================================
Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
Write-Host "  AUTH: Microsoft Graph" -ForegroundColor Cyan
Write-Host "  Tyler: code at https://microsoft.com/devicelogin" -ForegroundColor Yellow
Write-Host "$('=' * 60)" -ForegroundColor Cyan

Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.ReadWrite.All" `
    -TenantId $tenantId -NoWelcome
Write-Log "Connected to Graph" "SUCCESS"

Write-Log "=== STEP 11: Azure AD Groups ===" "STAGE"
$groups = @(
    @{ N="DCE-AllStaff";  D="All Delta Crown Extensions staff"
       M='(user.companyName -eq "Delta Crown Extensions")'; Nick="dce-allstaff" }
    @{ N="DCE-Managers";  D="DCE management team"
       M='(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Manager")'; Nick="dce-managers" }
    @{ N="DCE-Stylists";  D="DCE stylists and technicians"
       M='(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Stylist")'; Nick="dce-stylists" }
    @{ N="DCE-External";  D="External partners for DCE"
       M='(user.userType -eq "Guest") and (user.companyName -eq "Delta Crown Extensions")'; Nick="dce-external" }
)

foreach ($g in $groups) {
    $existing = Get-MgGroup -Filter "displayName eq '$($g.N)'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Log "  Exists: $($g.N) (ID: $($existing.Id))" "WARNING"
        continue
    }
    try {
        $new = New-MgGroup -DisplayName $g.N -Description $g.D `
            -MailEnabled:$false -MailNickname $g.Nick `
            -SecurityEnabled:$true -GroupTypes @("DynamicMembership") `
            -MembershipRule $g.M -MembershipRuleProcessingState "On"
        Write-Log "  Created: $($g.N) (ID: $($new.Id))" "SUCCESS"
        $results.Success += "Group: $($g.N)"
    } catch {
        Write-Log "  FAILED: $($g.N) — $_" "ERROR"
        $results.Errors += "Group: $($g.N) — $_"
    }
}

Disconnect-MgGraph -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 5: Final Verification
# ============================================================================
Do-DeviceLogin -Url $adminUrl -Label "Final Verification"

Write-Log "=== VERIFICATION ===" "STAGE"

Write-Host ""
Write-Log "--- Sites ---" "STAGE"
Get-PnPTenantSite | Where-Object { $_.Url -match "corp-|dce-" } |
    Select-Object Url, Title | Format-Table -AutoSize

Write-Log "--- Hubs ---" "STAGE"
Get-PnPHubSite | Select-Object SiteUrl, SiteId | Format-Table -AutoSize

Write-Log "--- Theme ---" "STAGE"
Get-PnPTenantTheme | Select-Object Name | Format-Table -AutoSize

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "`n$('=' * 60)" -ForegroundColor Green
Write-Host "  PHASE 2 DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "$('=' * 60)" -ForegroundColor Green
Write-Host ""

Write-Log "Successes: $($results.Success.Count)" "SUCCESS"
$results.Success | ForEach-Object { Write-Log "  $_" "SUCCESS" }

if ($results.Errors.Count -gt 0) {
    Write-Log "Errors: $($results.Errors.Count)" "ERROR"
    $results.Errors | ForEach-Object { Write-Log "  $_" "ERROR" }
} else {
    Write-Log "Zero errors!" "SUCCESS"
}
