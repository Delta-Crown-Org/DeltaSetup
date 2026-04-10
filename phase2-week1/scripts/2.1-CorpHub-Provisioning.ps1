# ============================================================================
# PHASE 2.1: Corporate Shared Services Hub Setup (REMEDIATED)
# Delta Crown Extensions - SharePoint Hub & Spoke Architecture
# ============================================================================
# VERSION: 2.1.0
# DESCRIPTION: Creates Corporate Hub site and associated service sites,
#              registers hub, associates sites, and configures navigation.
# REMEDIATION: Module version constraints, polling loops, permission
#              inheritance verification, Business Premium warning
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^https://[a-zA-Z0-9-]+\.sharepoint\.com(/.*)?$')]
    [string]$AdminUrl = "https://deltacrownext-admin.sharepoint.com",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9-]{3,64}$')]
    [string]$TenantName = "deltacrownext",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^/sites/[a-zA-Z0-9-]+$')]
    [string]$CorpHubUrl = "/sites/corp-hub",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$OwnerEmail = $null,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBusinessPremiumWarning
)

# Error handling setup
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# ============================================================================
# PATH RESOLUTION (R2.4A)
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
$LogFile = Join-Path $LogPath "CorpHub-Provisioning-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# CONFIGURATION
# ============================================================================
$CorpHubConfig = @{
    Url = $CorpHubUrl
    Title = "Corporate Shared Services"
    Description = "Central hub for shared franchise resources"
    Template = "SITEPAGEPUBLISHING#0"  # Communication Site
    Owner = $OwnerEmail
    TimeZone = 10  # US Central
}

$AssociatedSites = @(
    @{ Url = "/sites/corp-hr"; Title = "Corporate HR"; Description = "Human Resources shared services" },
    @{ Url = "/sites/corp-it"; Title = "Corporate IT"; Description = "IT support and infrastructure services" },
    @{ Url = "/sites/corp-finance"; Title = "Corporate Finance"; Description = "Financial services and reporting" },
    @{ Url = "/sites/corp-training"; Title = "Corporate Training"; Description = "Training and development resources" }
)

$HubNavigation = @(
    @{ Title = "Home"; Url = "$CorpHubUrl"; IsHome = $true },
    @{ Title = "HR Resources"; Url = "/sites/corp-hr"; IsHome = $false },
    @{ Title = "IT Support"; Url = "/sites/corp-it"; IsHome = $false },
    @{ Title = "Finance"; Url = "/sites/corp-finance"; IsHome = $false },
    @{ Title = "Training"; Url = "/sites/corp-training"; IsHome = $false }
)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownLog "=== Starting Corporate Shared Services Hub Provisioning ===" "STAGE"
    Write-DeltaCrownLog "Tenant: $TenantName"
    Write-DeltaCrownLog "Admin URL: $AdminUrl"
    Write-DeltaCrownLog "Log File: $LogFile"
    
    # Business Premium Warning (R2.3C)
    if (!$SkipBusinessPremiumWarning) {
        Show-DeltaCrownBusinessPremiumWarning -ForceAcknowledgment ($Environment -eq "Production")
    }
    
    # ------------------------------------------------------------------------
    # STEP 1: Connect to SharePoint Admin (R2.1)
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "Connecting to SharePoint Admin Center..."
    
    # R2.4A: Require OwnerEmail as parameter (no interactive Read-Host)
    if (!$OwnerEmail) {
        throw "OwnerEmail parameter is required. Pass -OwnerEmail 'admin@example.com'"
    }
    $CorpHubConfig.Owner = $OwnerEmail
    
    # Use shared auth module
    Connect-DeltaCrownSharePoint -Url $AdminUrl -Environment $Environment
    Write-DeltaCrownLog "Connected to SharePoint Admin Center" "SUCCESS"
    
    # ------------------------------------------------------------------------
    # STEP 2: Create Corp-Hub Communication Site
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "Creating Corporate Hub Communication Site..."
    
    $hubSiteUrl = "https://$TenantName.sharepoint.com$($CorpHubConfig.Url)"
    
    # Check if site already exists
    $existingSite = Get-PnPTenantSite -Url $hubSiteUrl -ErrorAction SilentlyContinue
    if ($existingSite) {
        Write-DeltaCrownLog "Corp Hub site already exists at $hubSiteUrl" "WARNING"
    } else {
        New-PnPSite -Type CommunicationSite `
            -Title $CorpHubConfig.Title `
            -Url $hubSiteUrl `
            -Description $CorpHubConfig.Description `
            -Owner $CorpHubConfig.Owner `
            -Lcid 1033 `
            -TimeZone $CorpHubConfig.TimeZone `
            -Wait
        
        Write-DeltaCrownLog "Created Corporate Hub: $hubSiteUrl" "SUCCESS"
        
        # R2.4C: Replace fixed delay with polling loop
        Wait-DeltaCrownSiteProvisioned -SiteUrl $hubSiteUrl -TimeoutSeconds 120
    }
    
    # ------------------------------------------------------------------------
    # STEP 3: Register Corp-Hub as Hub Site
    # ------------------------------------------------------------------------
    Write-Log "Registering Corp-Hub as Hub Site..."
    
    Connect-PnPOnline -Url $hubSiteUrl -Interactive
    
    $existingHub = Get-PnPHubSite -Identity $hubSiteUrl -ErrorAction SilentlyContinue
    if ($existingHub) {
        Write-Log "Corp-Hub is already registered as Hub Site" "WARNING"
        $hubId = $existingHub.SiteId
    } else {
        $hubRegistration = Register-PnPHubSite -Site $hubSiteUrl
        $hubId = (Get-PnPSite -Includes Id).Id
        Write-Log "Registered Corp-Hub as Hub Site (ID: $hubId)" "SUCCESS"
    }
    
    # Export Hub ID for later use
    # R2.4A: No hard-coded paths
    $hubIdPath = Join-Path $ProjectRoot "phase2-week1" "docs" "corp-hub-id.txt"
    # R2.2B: Encrypted export for sensitive hub configuration
    Export-DeltaCrownSecureData -Data @{ HubId = $hubId; HubUrl = $hubSiteUrl; ExportedAt = (Get-Date) } -Path (Join-Path $ProjectRoot "phase2-week1" "docs" "corp-hub-config.enc") -AlsoExportPlaintext:($Environment -eq "Development")
    # Also keep plaintext hub ID for cross-script compatibility
    $hubId | Out-File -FilePath $hubIdPath -Force
    Write-Log "Hub ID saved to $hubIdPath"
    
    # ------------------------------------------------------------------------
    # STEP 4: Create Associated Sites
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "Creating associated service sites..."
    
    $createdSites = @()
    $sitesToSecure = @()
    
    foreach ($site in $AssociatedSites) {
        $siteUrl = "https://$TenantName.sharepoint.com$($site.Url)"
        
        # Check if exists
        $existing = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
        if ($existing) {
            Write-DeltaCrownLog "Site $($site.Title) already exists" "WARNING"
            $createdSites += [PSCustomObject]@{
                Title = $site.Title
                Url = $siteUrl
                Status = "EXISTING"
            }
            $sitesToSecure += @{ Url = $siteUrl; Title = $site.Title; IsNew = $false }
        } else {
            Write-DeltaCrownLog "Creating $($site.Title) at $($site.Url)..."
            
            New-PnPSite -Type CommunicationSite `
                -Title $site.Title `
                -Url $siteUrl `
                -Description $site.Description `
                -Owner $CorpHubConfig.Owner `
                -Lcid 1033 `
                -TimeZone $CorpHubConfig.TimeZone `
                -Wait
            
            Wait-DeltaCrownSiteProvisioned -SiteUrl $siteUrl -TimeoutSeconds 120
            
            $createdSites += [PSCustomObject]@{
                Title = $site.Title
                Url = $siteUrl
                Status = "CREATED"
            }
            $sitesToSecure += @{ Url = $siteUrl; Title = $site.Title; IsNew = $true }
            Write-DeltaCrownLog "Created $($site.Title)" "SUCCESS"
        }
    }
    
    # Export site inventory
    $exportPath = Join-Path $ProjectRoot "phase2-week1" "docs" "corp-sites-inventory.csv"
    $createdSites | Export-Csv -Path $exportPath -NoTypeInformation -Force
    Write-DeltaCrownLog "Site inventory exported to corp-sites-inventory.csv"
    
    # ------------------------------------------------------------------------
    # STEP 4A: Permission Inheritance Verification (R2.3A)
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "Verifying permission inheritance on all sites..." "STAGE"
    
    $forbiddenGroups = $Config.Security.ForbiddenGroups
    
    foreach ($siteInfo in $sitesToSecure) {
        try {
            Write-DeltaCrownLog "Securing permissions for $($siteInfo.Title)..."
            
            # Connect to site
            Connect-PnPOnline -Url $siteInfo.Url -Interactive
            
            # Break inheritance (R2.3A: Explicit permission break)
            $web = Get-PnPWeb
            if ($web.HasUniqueRoleAssignments -eq $false) {
                Set-PnPWeb -BreakRoleInheritance:$true
                Write-DeltaCrownLog "  Broke permission inheritance on $($siteInfo.Title)" "SUCCESS"
            } else {
                Write-DeltaCrownLog "  Permission inheritance already broken on $($siteInfo.Title)" "INFO"
            }
            
            # Remove forbidden groups (R2.3A: Remove "Everyone" and "All Users")
            $roleAssignments = Get-PnPRoleAssignment
            foreach ($assignment in $roleAssignments) {
                $principalName = $assignment.Principal.LoginName
                foreach ($forbidden in $forbiddenGroups) {
                    if ($principalName -like "*$forbidden*" -or $principalName -eq $forbidden) {
                        Write-DeltaCrownLog "  Removing forbidden group: $principalName" "WARNING"
                        Remove-PnPRoleAssignment -Principal $assignment.Principal.LoginName -Force
                    }
                }
            }
            
            # Verify unique permissions
            $web = Get-PnPWeb
            if ($web.HasUniqueRoleAssignments) {
                Write-DeltaCrownLog "  Verified: Unique permissions confirmed on $($siteInfo.Title)" "SUCCESS"
            } else {
                Write-DeltaCrownLog "  ERROR: Unique permissions not confirmed on $($siteInfo.Title)" "ERROR"
            }
        }
        catch {
            Write-DeltaCrownLog "Error securing $($siteInfo.Title): $_" "ERROR"
        }
    }
    
    # ------------------------------------------------------------------------
    # STEP 5: Associate Sites with Corp-Hub
    # ------------------------------------------------------------------------
    Write-Log "Associating sites with Corp-Hub..."
    
    foreach ($site in $AssociatedSites) {
        $siteUrl = "https://$TenantName.sharepoint.com$($site.Url)"
        
        try {
            Connect-PnPOnline -Url $siteUrl -Interactive
            
            # Check current hub association
            $currentHub = Get-PnPHubSiteConnection -ErrorAction SilentlyContinue
            if ($currentHub -and $currentHub.Id -eq $hubId) {
                Write-Log "$($site.Title) is already associated with Corp-Hub" "WARNING"
            } else {
                Add-PnPHubSiteAssociation -Site $siteUrl -HubSite $hubSiteUrl
                Write-Log "Associated $($site.Title) with Corp-Hub" "SUCCESS"
            }
        }
        catch {
            Write-Log "Error associating $($site.Title): $_" "ERROR"
        }
    }
    
    # ------------------------------------------------------------------------
    # STEP 6: Configure Hub Navigation
    # ------------------------------------------------------------------------
    Write-Log "Configuring Corp-Hub navigation..."
    
    Connect-PnPOnline -Url $hubSiteUrl -Interactive
    
    # Get existing navigation nodes
    $existingNodes = Get-PnPNavigationNode -Location HubNavigation -ErrorAction SilentlyContinue
    
    # Clear existing non-home nodes if needed
    if ($existingNodes) {
        Write-Log "Existing navigation nodes found. Review manually or clear via script."
    }
    
    foreach ($navItem in $HubNavigation) {
        $nodeUrl = if ($navItem.IsHome) { $hubSiteUrl } else { "https://$TenantName.sharepoint.com$($navItem.Url)" }
        
        try {
            Add-PnPNavigationNode -Location HubNavigation `
                -Title $navItem.Title `
                -Url $nodeUrl `
                -First
            Write-Log "Added navigation node: $($navItem.Title)" "SUCCESS"
        }
        catch {
            Write-Log "Navigation node may already exist or error: $_" "WARNING"
        }
    }
    
    # ------------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "=== Corporate Shared Services Hub Setup Complete ===" "SUCCESS"
    Write-DeltaCrownLog "Hub Site: $hubSiteUrl"
    Write-DeltaCrownLog "Hub ID: $hubId"
    Write-DeltaCrownLog "Associated Sites: $($AssociatedSites.Count)"
    Write-DeltaCrownLog "Log saved to: $LogFile"
    
    # Return summary object
    return [PSCustomObject]@{
        HubUrl = $hubSiteUrl
        HubId = $hubId
        Owner = $CorpHubConfig.Owner
        AssociatedSites = $createdSites
        Status = "SUCCESS"
        Timestamp = Get-Date
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR: $_" "ERROR" -IncludeContext -Exception $_.Exception
    Write-DeltaCrownLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    
    # R2.4D: Rollback on failure
    Invoke-DeltaCrownRollback -Reason $_.Exception.Message -ContinueOnError
    
    throw
}
finally {
    Write-DeltaCrownLog "Disconnecting from SharePoint..."
    Disconnect-DeltaCrownAll
}
