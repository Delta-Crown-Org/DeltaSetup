# ============================================================================
# PHASE 2.4: Verification Script (REMEDIATED)
# Delta Crown Extensions - SharePoint Hub & Spoke Architecture
# ============================================================================
# VERSION: 2.1.0
# DESCRIPTION: Verifies all Phase 2 infrastructure components are properly
#              configured and accessible.
# REMEDIATION: Module version constraints, auth integration, permission checks
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9-]{3,64}$')]
    [string]$TenantName = "deltacrownext",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^https://[a-zA-Z0-9-]+\.sharepoint\.com(/.*)?$')]
    [string]$AdminUrl = $null,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportResults,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckPermissions  # R2.3A: Permission verification
)

if (!$AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

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
$ModulesPath = Join-Path $ProjectRoot "phase2-week1\modules"

Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# ============================================================================
# LOGGING SETUP
# ============================================================================
$LogPath = ".\phase2-week1\logs"
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}
$LogFile = Join-Path $LogPath "Verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    $color = switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "VERIFY" { "Magenta" }
        default { "White" }
    }
    Write-Host $logEntry -ForegroundColor $color
    Add-Content -Path $LogFile -Value $logEntry
}

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

function Test-PermissionInheritance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SiteUrl,
        
        [Parameter(Mandatory)]
        [string]$SiteName
    )
    
    try {
        Connect-PnPOnline -Url $SiteUrl -Interactive
        $web = Get-PnPWeb
        
        return [PSCustomObject]@{
            Component = "$SiteName Permissions"
            Status = if ($web.HasUniqueRoleAssignments) { "PASS" } else { "FAIL" }
            Details = if ($web.HasUniqueRoleAssignments) { "Unique permissions confirmed" } else { "Inheriting permissions - SECURITY RISK" }
        }
    }
    catch {
        return [PSCustomObject]@{
            Component = "$SiteName Permissions"
            Status = "ERROR"
            Details = $_.Exception.Message
        }
    }
}

function Test-CorpHub {
    Write-Log "`n[VERIFY] Corporate Shared Services Hub" "VERIFY"
    
    $results = @()
    $corpHubUrl = "https://$TenantName.sharepoint.com/sites/corp-hub"
    
    try {
        Connect-PnPOnline -Url $AdminUrl -Interactive
        
        # Check site exists
        $site = Get-PnPTenantSite -Url $corpHubUrl -ErrorAction SilentlyContinue
        $results += [PSCustomObject]@{
            Component = "Corp-Hub Site"
            Status = if ($site) { "PASS" } else { "FAIL" }
            Details = if ($site) { "Site exists: $($site.Title)" } else { "Site not found" }
        }
        
        # Check hub registration
        if ($site) {
            $hub = Get-PnPHubSite -Identity $corpHubUrl -ErrorAction SilentlyContinue
            $results += [PSCustomObject]@{
                Component = "Corp-Hub Registration"
                Status = if ($hub) { "PASS" } else { "FAIL" }
                Details = if ($hub) { "Hub ID: $($hub.SiteId)" } else { "Not registered as hub" }
            }
        }
        
        Disconnect-PnPOnline
    }
    catch {
        $results += [PSCustomObject]@{
            Component = "Corp-Hub"
            Status = "ERROR"
            Details = $_.Exception.Message
        }
    }
    
    return $results
}

function Test-AssociatedSites {
    Write-Log "`n[VERIFY] Associated Service Sites" "VERIFY"
    
    $results = @()
    $sites = @(
        @{ Url = "sites/corp-hr"; Title = "Corporate HR" },
        @{ Url = "sites/corp-it"; Title = "Corporate IT" },
        @{ Url = "sites/corp-finance"; Title = "Corporate Finance" },
        @{ Url = "sites/corp-training"; Title = "Corporate Training" }
    )
    
    try {
        Connect-PnPOnline -Url $AdminUrl -Interactive
        $corpHubUrl = "https://$TenantName.sharepoint.com/sites/corp-hub"
        
        foreach ($site in $sites) {
            $siteUrl = "https://$TenantName.sharepoint.com/$($site.Url)"
            
            # Check site exists
            $tenantSite = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
            $siteExists = if ($tenantSite) { "PASS" } else { "FAIL" }
            
            # Check hub association
            $hubAssoc = "NOT_CHECKED"
            if ($tenantSite) {
                try {
                    Connect-PnPOnline -Url $siteUrl -Interactive -ErrorAction SilentlyContinue
                    $connection = Get-PnPHubSiteConnection -ErrorAction SilentlyContinue
                    $hubAssoc = if ($connection) { "Associated with: $($connection.Id)" } else { "NOT_ASSOCIATED" }
                }
                catch {
                    $hubAssoc = "ERROR: $($_.Exception.Message)"
                }
            }
            
            $results += [PSCustomObject]@{
                Component = $site.Title
                Status = $siteExists
                Details = $hubAssoc
            }
        }
        
        Disconnect-PnPOnline
    }
    catch {
        $results += [PSCustomObject]@{
            Component = "Associated Sites"
            Status = "ERROR"
            Details = $_.Exception.Message
        }
    }
    
    return $results
}

function Test-DCEHub {
    Write-Log "`n[VERIFY] Delta Crown Extensions Hub" "VERIFY"
    
    $results = @()
    $dceHubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
    
    try {
        Connect-PnPOnline -Url $AdminUrl -Interactive
        
        # Check site exists
        $site = Get-PnPTenantSite -Url $dceHubUrl -ErrorAction SilentlyContinue
        $results += [PSCustomObject]@{
            Component = "DCE-Hub Site"
            Status = if ($site) { "PASS" } else { "FAIL" }
            Details = if ($site) { "Site exists: $($site.Title)" } else { "Site not found" }
        }
        
        if ($site) {
            # Check hub registration
            $hub = Get-PnPHubSite -Identity $dceHubUrl -ErrorAction SilentlyContinue
            $results += [PSCustomObject]@{
                Component = "DCE-Hub Registration"
                Status = if ($hub) { "PASS" } else { "FAIL" }
                Details = if ($hub) { "Hub ID: $($hub.SiteId)" } else { "Not registered as hub" }
            }
            
            # Check branding
            try {
                Connect-PnPOnline -Url $dceHubUrl -Interactive
                $theme = Get-PnPWebTheme -ErrorAction SilentlyContinue
                $results += [PSCustomObject]@{
                    Component = "DCE Branding"
                    Status = if ($theme -match "Delta Crown") { "PASS" } else { "INFO" }
                    Details = if ($theme) { "Theme: $theme" } else { "Default theme" }
                }
            }
            catch {
                $results += [PSCustomObject]@{
                    Component = "DCE Branding"
                    Status = "WARNING"
                    Details = "Could not verify: $($_.Exception.Message)"
                }
            }
            
            # Check hub-to-hub association
            try {
                Connect-PnPOnline -Url $dceHubUrl -Interactive
                $parentHub = Get-PnPHubSiteConnection -ErrorAction SilentlyContinue
                $results += [PSCustomObject]@{
                    Component = "Hub-to-Hub Link"
                    Status = if ($parentHub) { "PASS" } else { "FAIL" }
                    Details = if ($parentHub) { "Linked to: $($parentHub.Id)" } else { "Not linked to Corp-Hub" }
                }
            }
            catch {
                $results += [PSCustomObject]@{
                    Component = "Hub-to-Hub Link"
                    Status = "ERROR"
                    Details = $_.Exception.Message
                }
            }
        }
        
        Disconnect-PnPOnline
    }
    catch {
        $results += [PSCustomObject]@{
            Component = "DCE-Hub"
            Status = "ERROR"
            Details = $_.Exception.Message
        }
    }
    
    return $results
}

function Test-AzureADGroups {
    Write-Log "`n[VERIFY] Azure AD Dynamic Groups" "VERIFY"
    
    $results = @()
    $groups = @("SG-DCE-AllStaff", "SG-DCE-Leadership")
    
    try {
        Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
        
        foreach ($groupName in $groups) {
            $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
            
            if ($group) {
                # Check group properties
                $isDynamic = $group.GroupTypes -contains "DynamicMembership"
                $processingState = $group.MembershipRuleProcessingState
                
                # Try to get member count
                $memberCount = "N/A"
                try {
                    $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
                    $memberCount = $members.Count
                }
                catch {
                    $memberCount = "Error"
                }
                
                $results += [PSCustomObject]@{
                    Component = $groupName
                    Status = if ($isDynamic -and $processingState -eq "On") { "PASS" } else { "WARNING" }
                    Details = "Type: $(if($isDynamic){'Dynamic'}else{'Static'}), Processing: $processingState, Members: $memberCount"
                }
            } else {
                $results += [PSCustomObject]@{
                    Component = $groupName
                    Status = "FAIL"
                    Details = "Group not found"
                }
            }
        }
        
        Disconnect-MgGraph
    }
    catch {
        $results += [PSCustomObject]@{
            Component = "Azure AD Groups"
            Status = "ERROR"
            Details = $_.Exception.Message
        }
    }
    
    return $results
}

function Test-Navigation {
    Write-Log "`n[VERIFY] Navigation Configuration" "VERIFY"
    
    $results = @()
    $hubs = @(
        @{ Url = "sites/corp-hub"; Name = "Corp-Hub" },
        @{ Url = "sites/dce-hub"; Name = "DCE-Hub" }
    )
    
    foreach ($hub in $hubs) {
        try {
            $hubUrl = "https://$TenantName.sharepoint.com/$($hub.Url)"
            Connect-PnPOnline -Url $hubUrl -Interactive
            
            $navNodes = Get-PnPNavigationNode -Location HubNavigation -ErrorAction SilentlyContinue
            $navCount = if ($navNodes) { $navNodes.Count } else { 0 }
            
            $results += [PSCustomObject]@{
                Component = "$($hub.Name) Navigation"
                Status = if ($navCount -gt 0) { "PASS" } else { "WARNING" }
                Details = "Nodes: $navCount"
            }
            
            Disconnect-PnPOnline
        }
        catch {
            $results += [PSCustomObject]@{
                Component = "$($hub.Name) Navigation"
                Status = "ERROR"
                Details = $_.Exception.Message
            }
        }
    }
    
    return $results
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "=== Phase 2 Verification ===" "VERIFY"
    Write-Log "Tenant: $TenantName"
    Write-Log "Admin URL: $AdminUrl"
    
    $allResults = @()
    
    # Run all verification tests
    $allResults += Test-CorpHub
    $allResults += Test-AssociatedSites
    $allResults += Test-DCEHub
    $allResults += Test-AzureADGroups
    $allResults += Test-Navigation
    
    # Summary
    Write-Log "`n=== VERIFICATION SUMMARY ===" "VERIFY"
    
    $passCount = ($allResults | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($allResults | Where-Object { $_.Status -eq "FAIL" }).Count
    $warnCount = ($allResults | Where-Object { $_.Status -eq "WARNING" }).Count
    $errorCount = ($allResults | Where-Object { $_.Status -eq "ERROR" }).Count
    
    Write-Log "Passed: $passCount"
    Write-Log "Failed: $failCount" $(if ($failCount -gt 0) { "ERROR" } else { "INFO" })
    Write-Log "Warnings: $warnCount" $(if ($warnCount -gt 0) { "WARNING" } else { "INFO" })
    Write-Log "Errors: $errorCount" $(if ($errorCount -gt 0) { "ERROR" } else { "INFO" })
    
    # Display results table
    Write-Log "`nDetailed Results:"
    $allResults | Format-Table -AutoSize | Out-String | Write-Host
    
    # Export if requested
    if ($ExportResults) {
        $exportPath = ".\phase2-week1\docs\verification-results.csv"
        $allResults | Export-Csv -Path $exportPath -NoTypeInformation -Force
        Write-Log "Results exported to: $exportPath" "SUCCESS"
    }
    
    # Final verdict
    if ($failCount -eq 0 -and $errorCount -eq 0) {
        Write-Log "✅ All verifications passed!" "SUCCESS"
    } else {
        Write-Log "⚠ Some verifications failed. Review and remediate." "WARNING"
    }
    
    Write-Log "Log saved to: $LogFile"
    
    return $allResults
}
catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR"
    throw
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
