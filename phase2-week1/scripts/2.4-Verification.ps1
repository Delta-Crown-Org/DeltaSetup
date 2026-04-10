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
$ModulesPath = Join-Path $ProjectRoot "phase2-week1" "modules"

Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# ============================================================================
# LOGGING SETUP
# ============================================================================
# R2.4A: No hard-coded paths
$LogPath = Join-Path $ProjectRoot "phase2-week1" "logs"
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
# CONNECTION OWNERSHIP (R2.3A)
# ============================================================================
$script:OwnsPnPConnection = $false
$script:OwnsGraphConnection = $false

function Initialize-VerificationConnections {
    # Check if SharePoint connection already exists (from Master orchestrator)
    try {
        $ctx = Get-PnPContext -ErrorAction Stop
        Write-Log "Using pre-established SharePoint connection" "INFO"
    }
    catch {
        Write-Log "Establishing SharePoint connection..." "INFO"
        Connect-DeltaCrownSharePoint -Url $AdminUrl -Environment $Environment
        $script:OwnsPnPConnection = $true
    }
    
    # Check if Graph connection already exists
    try {
        $graphCtx = Get-MgContext -ErrorAction Stop
        if ($graphCtx) {
            Write-Log "Using pre-established Graph connection" "INFO"
        } else { throw "No Graph context" }
    }
    catch {
        Write-Log "Establishing Graph connection..." "INFO"
        Connect-DeltaCrownGraph -RequiredScopes @("Group.Read.All") -Environment $Environment
        $script:OwnsGraphConnection = $true
    }
}

# ============================================================================
# VERIFICATION FUNCTIONS (R2.3A: Remove connect churn)
# ============================================================================

function Test-CorpHub {
    Write-Log "`n[VERIFY] Corporate Shared Services Hub" "VERIFY"
    
    $results = @()
    $corpHubUrl = "https://$TenantName.sharepoint.com/sites/corp-hub"
    
    try {
        # Use existing admin connection
        $site = Get-PnPTenantSite -Url $corpHubUrl -ErrorAction SilentlyContinue
        $results += [PSCustomObject]@{
            Component = "Corp-Hub Site"
            Status = if ($site) { "PASS" } else { "FAIL" }
            Details = if ($site) { "Site exists: $($site.Title)" } else { "Site not found" }
        }
        
        if ($site) {
            $hub = Get-PnPHubSite -Identity $corpHubUrl -ErrorAction SilentlyContinue
            $results += [PSCustomObject]@{
                Component = "Corp-Hub Registration"
                Status = if ($hub) { "PASS" } else { "FAIL" }
                Details = if ($hub) { "Hub ID: $($hub.SiteId)" } else { "Not registered as hub" }
            }
        }
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
    
    $corpHubUrl = "https://$TenantName.sharepoint.com/sites/corp-hub"
    
    foreach ($site in $sites) {
        $siteUrl = "https://$TenantName.sharepoint.com/$($site.Url)"
        
        try {
            # Use admin connection (no separate Connect-PnPOnline)
            $tenantSite = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
            $siteExists = if ($tenantSite) { "PASS" } else { "FAIL" }
            
            $hubAssoc = "NOT_CHECKED"
            if ($tenantSite -and $tenantSite.HubSiteId) {
                $hubAssoc = "Hub Site ID: $($tenantSite.HubSiteId)"
            }
            
            $results += [PSCustomObject]@{
                Component = $site.Title
                Status = $siteExists
                Details = $hubAssoc
            }
        }
        catch {
            $results += [PSCustomObject]@{
                Component = $site.Title
                Status = "ERROR"
                Details = $_.Exception.Message
            }
        }
    }
    
    return $results
}

function Test-DCEHub {
    Write-Log "`n[VERIFY] Delta Crown Extensions Hub" "VERIFY"
    
    $results = @()
    $dceHubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
    
    try {
        # Use admin connection
        $site = Get-PnPTenantSite -Url $dceHubUrl -ErrorAction SilentlyContinue
        $results += [PSCustomObject]@{
            Component = "DCE-Hub Site"
            Status = if ($site) { "PASS" } else { "FAIL" }
            Details = if ($site) { "Site exists: $($site.Title)" } else { "Site not found" }
        }
        
        if ($site) {
            $hub = Get-PnPHubSite -Identity $dceHubUrl -ErrorAction SilentlyContinue
            $results += [PSCustomObject]@{
                Component = "DCE-Hub Registration"
                Status = if ($hub) { "PASS" } else { "FAIL" }
                Details = if ($hub) { "Hub ID: $($hub.SiteId)" } else { "Not registered as hub" }
            }
            
            # Check hub association via tenant site properties
            if ($site.HubSiteId -and $site.HubSiteId -ne [Guid]::Empty) {
                $results += [PSCustomObject]@{
                    Component = "Hub-to-Hub Link"
                    Status = "PASS"
                    Details = "Linked to parent hub: $($site.HubSiteId)"
                }
            } else {
                $results += [PSCustomObject]@{
                    Component = "Hub-to-Hub Link"
                    Status = "FAIL"
                    Details = "Not linked to Corp-Hub"
                }
            }
        }
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
        # Use existing Graph connection (no separate Connect-MgGraph)
        foreach ($groupName in $groups) {
            $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
            
            if ($group) {
                $isDynamic = $group.GroupTypes -contains "DynamicMembership"
                $processingState = $group.MembershipRuleProcessingState
                
                $memberCount = "N/A"
                try {
                    $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
                    $memberCount = if ($members) { $members.Count } else { 0 }
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
            # Connect to the specific site to read hub navigation
            Connect-PnPOnline -Url $hubUrl -Interactive
            
            $navNodes = Get-PnPNavigationNode -Location HubNavigation -ErrorAction SilentlyContinue
            $navCount = if ($navNodes) { $navNodes.Count } else { 0 }
            
            $results += [PSCustomObject]@{
                Component = "$($hub.Name) Navigation"
                Status = if ($navCount -gt 0) { "PASS" } else { "WARNING" }
                Details = "Nodes: $navCount"
            }
            
            # Return to admin connection
            Connect-PnPOnline -Url $AdminUrl -Interactive
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

# R2.3A: Permission verification (this function existed but wasn't called!)
function Test-AllPermissions {
    Write-Log "`n[VERIFY] Permission Inheritance (R2.3A)" "VERIFY"
    
    $results = @()
    $sitesToCheck = @(
        "https://$TenantName.sharepoint.com/sites/corp-hub",
        "https://$TenantName.sharepoint.com/sites/corp-hr",
        "https://$TenantName.sharepoint.com/sites/corp-it",
        "https://$TenantName.sharepoint.com/sites/corp-finance",
        "https://$TenantName.sharepoint.com/sites/corp-training",
        "https://$TenantName.sharepoint.com/sites/dce-hub"
    )
    
    $forbiddenGroups = @("Everyone", "Everyone except external users", "All Users")
    
    foreach ($siteUrl in $sitesToCheck) {
        $siteName = ($siteUrl -split '/')[-1]
        
        try {
            Connect-PnPOnline -Url $siteUrl -Interactive
            $web = Get-PnPWeb -Includes HasUniqueRoleAssignments
            
            $results += [PSCustomObject]@{
                Component = "$siteName Unique Permissions"
                Status = if ($web.HasUniqueRoleAssignments) { "PASS" } else { "FAIL" }
                Details = if ($web.HasUniqueRoleAssignments) { "Unique permissions confirmed" } else { "INHERITING - SECURITY RISK" }
            }
            
            # Check for forbidden groups
            $roleAssignments = Get-PnPRoleAssignment -ErrorAction SilentlyContinue
            foreach ($forbidden in $forbiddenGroups) {
                $found = $roleAssignments | Where-Object { $_.Principal.LoginName -like "*$forbidden*" }
                if ($found) {
                    $results += [PSCustomObject]@{
                        Component = "$siteName Forbidden Group"
                        Status = "FAIL"
                        Details = "Found forbidden group: $forbidden"
                    }
                }
            }
        }
        catch {
            $results += [PSCustomObject]@{
                Component = "$siteName Permissions"
                Status = "ERROR"
                Details = $_.Exception.Message
            }
        }
    }
    
    # Return to admin connection
    try { Connect-PnPOnline -Url $AdminUrl -Interactive } catch { }
    
    return $results
}

# R2.3A: Discrepancy reporting
function Export-DiscrepancyReport {
    param([array]$Results)
    
    $discrepancies = $Results | Where-Object { $_.Status -in @("FAIL", "ERROR", "WARNING") }
    
    if ($discrepancies.Count -gt 0) {
        Write-Log "`n=== DISCREPANCY REPORT (R2.3A) ===" "WARNING"
        Write-Log "Found $($discrepancies.Count) issues requiring attention:" "WARNING"
        
        foreach ($d in $discrepancies) {
            $icon = switch ($d.Status) { "FAIL" { "X" } "ERROR" { "!!" } "WARNING" { "?" } }
            Write-Log "  $icon [$($d.Status)] $($d.Component): $($d.Details)" $d.Status
        }
        
        # Export to JSON
        $reportPath = Join-Path $ProjectRoot "phase2-week1" "docs" "discrepancy-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $discrepancies | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Force
        Write-Log "Discrepancy report saved to: $reportPath" "INFO"
    } else {
        Write-Log "`nNo discrepancies found - all checks passed!" "SUCCESS"
    }
}

# ============================================================================
# MAIN EXECUTION (R2.3A: Consolidated connections)
# ============================================================================

try {
    Write-Log "=== Phase 2 Verification ===" "VERIFY"
    Write-Log "Tenant: $TenantName"
    Write-Log "Admin URL: $AdminUrl"
    
    # Initialize connections once
    Initialize-VerificationConnections
    
    $allResults = @()
    
    # Run all verification tests
    $allResults += Test-CorpHub
    $allResults += Test-AssociatedSites
    $allResults += Test-DCEHub
    $allResults += Test-AzureADGroups
    $allResults += Test-Navigation
    
    # R2.3A: Permission verification (now actually called!)
    if ($CheckPermissions) {
        $allResults += Test-AllPermissions
    }
    
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
    
    # R2.3A: Discrepancy report
    Export-DiscrepancyReport -Results $allResults
    
    # Export if requested
    if ($ExportResults) {
        $exportPath = Join-Path $ProjectRoot "phase2-week1" "docs" "verification-results.csv"
        $allResults | Export-Csv -Path $exportPath -NoTypeInformation -Force
        Write-Log "Results exported to: $exportPath" "SUCCESS"
    }
    
    # Final verdict
    if ($failCount -eq 0 -and $errorCount -eq 0) {
        Write-Log "All verifications passed!" "SUCCESS"
        exit 0
    } elseif ($failCount -eq 0) {
        Write-Log "Verifications passed with warnings." "WARNING"
        exit 1
    } else {
        Write-Log "Some verifications failed. Review and remediate." "ERROR"
        exit 2
    }
    
    Write-Log "Log saved to: $LogFile"
    
    return $allResults
}
catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR" -IncludeContext -Exception $_.Exception
    throw
}
finally {
    # Only disconnect what we own
    if ($script:OwnsPnPConnection) {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }
    if ($script:OwnsGraphConnection) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}
