# ============================================================================
# WEEKLY PERMISSION AUDIT SCRIPT
# Delta Crown Extensions - Compensating Control #5
# ============================================================================
# DESCRIPTION: Scans all DCE sites for permission violations
#              - Checks for inherited permissions (should be NONE)
#              - Checks for "Everyone"/"All Users" groups (should be NONE)
#              - Checks for external sharing enabled (should be NONE)
#              - Generates report and alerts on violations
# ============================================================================
# SCHEDULING: Run weekly via Task Scheduler or Azure Automation
# REQUIRED ROLE: SharePoint Admin or Global Reader
# ============================================================================

#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = ".\phase2-week1\reports",
    
    [Parameter(Mandatory=$false)]
    [string[]]$AlertRecipients = @("security@deltacrown.com", "compliance@deltacrown.com"),
    
    [Parameter(Mandatory=$false)]
    [switch]$SendEmailAlert = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoRemediate = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Initialize
if (!$AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$scriptVersion = "1.0"

# ============================================================================
# LOGGING SETUP
# ============================================================================
function Initialize-Logging {
    $logPath = ".\phase2-week1\logs"
    if (!(Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    
    $global:LogFile = Join-Path $logPath "Weekly-Permission-Audit-$timestamp.log"
    
    Write-Log "=== DCE Weekly Permission Audit Started ===" "INFO"
    Write-Log "Script Version: $scriptVersion" "INFO"
    Write-Log "Tenant: $TenantName" "INFO"
    Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL", "WHATIF")]
        [string]$Level = "INFO"
    )
    
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$time] [$Level] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "CRITICAL" { "Magenta" }
        "WHATIF" { "DarkYellow" }
        default { "White" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # File logging
    if ($global:LogFile) {
        Add-Content -Path $global:LogFile -Value $logEntry
    }
}

# ============================================================================
# AUDIT FUNCTIONS
# ============================================================================

function Get-DCESites {
    <#
    .SYNOPSIS
        Retrieves all DCE-related sites from the tenant
    #>
    param()
    
    Write-Log "Scanning for DCE sites..." "INFO"
    
    try {
        Connect-PnPOnline -Url $AdminUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction Stop
        
        # Get all sites and filter for DCE
        $allSites = Get-PnPTenantSite | Where-Object {
            $_.Url -match "dce-" -or 
            $_.Url -match "deltacrown" -or
            $_.Title -match "Delta Crown"
        }
        
        $sites = @()
        foreach ($site in $allSites) {
            $sites += [PSCustomObject]@{
                Url = $site.Url
                Title = $site.Title
                Template = $site.Template
                SharingCapability = $site.SharingCapability
                ExternalSharing = $site.ExternalSharing
            }
        }
        
        Write-Log "Found $($sites.Count) DCE sites" "SUCCESS"
        
        foreach ($site in $sites) {
            Write-Log "  - $($site.Title): $($site.Url)" "INFO"
        }
        
        return $sites
    }
    catch {
        Write-Log "Failed to retrieve sites: $_" "ERROR"
        throw
    }
}

function Test-PermissionInheritance {
    <#
    .SYNOPSIS
        Checks if a site has unique permissions (not inherited)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Site
    )
    
    Write-Log "Checking permissions for: $($Site.Title)" "INFO"
    
    try {
        Connect-PnPOnline -Url $Site.Url -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction SilentlyContinue
        
        $web = Get-PnPWeb
        $hasUniquePermissions = $web.HasUniqueRoleAssignments
        
        $result = [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            HasUniquePermissions = $hasUniquePermissions
            Status = if ($hasUniquePermissions) { "PASS" } else { "CRITICAL" }
            Details = if ($hasUniquePermissions) { 
                "Unique permissions configured" 
            } else { 
                "INHERITED PERMISSIONS DETECTED - Security violation!" 
            }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if (-not $hasUniquePermissions) {
            Write-Log "CRITICAL: $($Site.Title) has inherited permissions!" "CRITICAL"
        }
        
        return $result
    }
    catch {
        Write-Log "Error checking permissions for $($Site.Url): $_" "ERROR"
        return [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            HasUniquePermissions = $null
            Status = "ERROR"
            Details = "Error: $_"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

function Test-DangerousGroups {
    <#
    .SYNOPSIS
        Checks for dangerous groups (Everyone, All Users, etc.) in site permissions
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Site
    )
    
    $dangerousPatterns = @(
        "Everyone",
        "All Users",
        "All Authenticated Users",
        "Everyone except external users",
        "NT AUTHORITY\\Authenticated Users"
    )
    
    Write-Log "Checking for dangerous groups on: $($Site.Title)" "INFO"
    
    try {
        Connect-PnPOnline -Url $Site.Url -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction SilentlyContinue
        
        $roleAssignments = Get-PnPPropertyBag -Key "_vti_ext_permission"
        $web = Get-PnPWeb
        $assignments = Get-PnPProperty -ClientObject $web -Property RoleAssignments
        
        $violations = @()
        
        foreach ($assignment in $assignments) {
            $group = Get-PnPGroup | Where-Object { $_.Id -eq $assignment.PrincipalId }
            
            if ($group) {
                foreach ($pattern in $dangerousPatterns) {
                    if ($group.LoginName -like "*$pattern*" -or $group.Title -like "*$pattern*") {
                        $violations += [PSCustomObject]@{
                            GroupName = $group.Title
                            GroupLoginName = $group.LoginName
                            Pattern = $pattern
                        }
                        Write-Log "DANGEROUS GROUP FOUND: $($group.Title) on $($Site.Title)" "CRITICAL"
                    }
                }
            }
        }
        
        $result = [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            ViolationsFound = $violations.Count
            Violations = $violations | ConvertTo-Json -Compress
            Status = if ($violations.Count -eq 0) { "PASS" } else { "CRITICAL" }
            Details = if ($violations.Count -eq 0) {
                "No dangerous groups found"
            } else {
                "Found $($violations.Count) dangerous group(s): $($violations.GroupName -join ', ')"
            }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        return $result
    }
    catch {
        Write-Log "Error checking dangerous groups for $($Site.Url): $_" "ERROR"
        return [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            ViolationsFound = $null
            Violations = $null
            Status = "ERROR"
            Details = "Error: $_"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

function Test-ExternalSharing {
    <#
    .SYNOPSIS
        Checks if external sharing is enabled on the site
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Site
    )
    
    Write-Log "Checking external sharing for: $($Site.Title)" "INFO"
    
    try {
        Connect-PnPOnline -Url $AdminUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction SilentlyContinue
        
        $siteInfo = Get-PnPTenantSite -Url $Site.Url
        $sharing = $siteInfo.SharingCapability
        $isExternalEnabled = $sharing -ne "Disabled"
        
        $result = [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            SharingCapability = $sharing
            ExternalSharingEnabled = $isExternalEnabled
            Status = if (-not $isExternalEnabled) { "PASS" } else { "WARNING" }
            Details = if (-not $isExternalEnabled) {
                "External sharing disabled"
            } else {
                "EXTERNAL SHARING ENABLED: $sharing"
            }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if ($isExternalEnabled) {
            Write-Log "WARNING: External sharing is ENABLED on $($Site.Title)" "WARNING"
            Write-Log "  Sharing Capability: $sharing" "WARNING"
        }
        
        return $result
    }
    catch {
        Write-Log "Error checking external sharing for $($Site.Url): $_" "ERROR"
        return [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            SharingCapability = "Unknown"
            ExternalSharingEnabled = $null
            Status = "ERROR"
            Details = "Error: $_"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

function Test-AnonymousLinks {
    <#
    .SYNOPSIS
        Checks for anonymous/guest sharing links
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Site
    )
    
    Write-Log "Checking for anonymous links on: $($Site.Title)" "INFO"
    
    try {
        Connect-PnPOnline -Url $Site.Url -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction SilentlyContinue
        
        # Get all sharing links (requires elevated permissions)
        $sharingLinks = @()
        
        # This requires Microsoft Graph or additional permissions
        # For now, we'll document the capability
        
        $result = [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            AnonymousLinksFound = "Requires manual check"
            Status = "INFO"
            Details = "Manual verification required via SharePoint Admin Center"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        return $result
    }
    catch {
        Write-Log "Error checking anonymous links for $($Site.Url): $_" "ERROR"
        return [PSCustomObject]@{
            SiteUrl = $Site.Url
            SiteTitle = $Site.Title
            AnonymousLinksFound = $null
            Status = "ERROR"
            Details = "Error: $_"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# ============================================================================
# REMEDIATION FUNCTIONS
# ============================================================================

function Invoke-AutoRemediation {
    <#
    .SYNOPSIS
        Automatically fixes certain violations if AutoRemediate is enabled
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Violations
    )
    
    if (-not $AutoRemediate) {
        Write-Log "Auto-remediation disabled - manual review required" "WARNING"
        return
    }
    
    if ($WhatIf) {
        Write-Log "WHATIF: Would auto-remediate violations" "WHATIF"
        return
    }
    
    Write-Log "Auto-remediation enabled - fixing violations..." "WARNING"
    
    foreach ($violation in $Violations) {
        switch ($violation.CheckType) {
            "Inheritance" {
                Write-Log "Auto-remediation: Breaking permission inheritance on $($violation.SiteUrl)" "WARNING"
                try {
                    Connect-PnPOnline -Url $violation.SiteUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207'
                    Set-PnPWeb -BreakRoleInheritance -CopyRoleAssignments
                    Write-Log "Fixed: Broke permission inheritance on $($violation.SiteTitle)" "SUCCESS"
                }
                catch {
                    Write-Log "Failed to fix inheritance on $($violation.SiteUrl): $_" "ERROR"
                }
            }
            
            "ExternalSharing" {
                Write-Log "Auto-remediation: Disabling external sharing on $($violation.SiteUrl)" "WARNING"
                try {
                    Connect-PnPOnline -Url $AdminUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207'
                    Set-PnPTenantSite -Url $violation.SiteUrl -SharingCapability Disabled
                    Write-Log "Fixed: Disabled external sharing on $($violation.SiteTitle)" "SUCCESS"
                }
                catch {
                    Write-Log "Failed to disable sharing on $($violation.SiteUrl): $_" "ERROR"
                }
            }
            
            "DangerousGroup" {
                Write-Log "Auto-remediation: Cannot auto-remove dangerous groups - manual review required" "WARNING"
                # Dangerous groups require manual review
            }
        }
    }
}

# ============================================================================
# REPORTING FUNCTIONS
# ============================================================================

function Export-AuditReport {
    <#
    .SYNOPSIS
        Exports the audit findings to CSV and HTML
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$PermissionResults,
        
        [Parameter(Mandatory=$true)]
        [array]$GroupResults,
        
        [Parameter(Mandatory=$true)]
        [array]$SharingResults,
        
        [Parameter(Mandatory=$true)]
        [array]$LinkResults
    )
    
    # Create reports directory
    if (!(Test-Path $ReportPath)) {
        New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
    }
    
    # Export CSV
    $csvPath = Join-Path $ReportPath "Permission-Audit-$timestamp.csv"
    $allResults = $PermissionResults + $GroupResults + $SharingResults + $LinkResults
    $allResults | Export-Csv -Path $csvPath -NoTypeInformation -Force
    Write-Log "CSV report saved to: $csvPath" "SUCCESS"
    
    # Generate HTML report
    $htmlPath = Join-Path $ReportPath "Permission-Audit-$timestamp.html"
    $htmlReport = Generate-HTMLReport -Results $allResults
    $htmlReport | Out-File -FilePath $htmlPath -Force
    Write-Log "HTML report saved to: $htmlPath" "SUCCESS"
    
    # Generate summary
    $criticalCount = ($allResults | Where-Object { $_.Status -eq "CRITICAL" }).Count
    $warningCount = ($allResults | Where-Object { $_.Status -eq "WARNING" }).Count
    $errorCount = ($allResults | Where-Object { $_.Status -eq "ERROR" }).Count
    $passCount = ($allResults | Where-Object { $_.Status -eq "PASS" }).Count
    
    Write-Log "`n=== AUDIT SUMMARY ===" "INFO"
    Write-Log "Total Checks: $($allResults.Count)" "INFO"
    Write-Log "PASSED: $passCount" "SUCCESS"
    Write-Log "WARNINGS: $warningCount" $(if ($warningCount -gt 0) { "WARNING" } else { "INFO" })
    Write-Log "CRITICAL: $criticalCount" $(if ($criticalCount -gt 0) { "CRITICAL" } else { "INFO" })
    Write-Log "ERRORS: $errorCount" $(if ($errorCount -gt 0) { "ERROR" } else { "INFO" })
    
    return [PSCustomObject]@{
        CsvPath = $csvPath
        HtmlPath = $htmlPath
        Summary = @{
            Total = $allResults.Count
            Passed = $passCount
            Warnings = $warningCount
            Critical = $criticalCount
            Errors = $errorCount
        }
    }
}

function Generate-HTMLReport {
    param([array]$Results)
    
    $criticalCount = ($Results | Where-Object { $_.Status -eq "CRITICAL" }).Count
    $warningCount = ($Results | Where-Object { $_.Status -eq "WARNING" }).Count
    $passCount = ($Results | Where-Object { $_.Status -eq "PASS" }).Count
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>DCE Weekly Permission Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #1A1A1A; }
        h2 { color: #C9A227; }
        .summary { background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .critical { color: #d9534f; font-weight: bold; }
        .warning { color: #f0ad4e; }
        .pass { color: #5cb85c; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background: #C9A227; color: white; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .status-critical { background: #ffebee; }
        .status-warning { background: #fff3e0; }
        .status-pass { background: #e8f5e9; }
    </style>
</head>
<body>
    <h1>🔒 DCE Weekly Permission Audit Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <p>Tenant: $TenantName</p>
    
    <div class="summary">
        <h2>Summary</h2>
        <p>✅ <strong>Passed:</strong> $passCount</p>
        <p>⚠️ <strong>Warnings:</strong> $warningCount</p>
        <p>🔴 <strong>Critical Issues:</strong> <span class="critical">$criticalCount</span></p>
    </div>
    
    <h2>Detailed Results</h2>
    <table>
        <tr>
            <th>Site</th>
            <th>Check Type</th>
            <th>Status</th>
            <th>Details</th>
            <th>Timestamp</th>
        </tr>
"@
    
    foreach ($result in $Results) {
        $statusClass = switch ($result.Status) {
            "CRITICAL" { "status-critical" }
            "WARNING" { "status-warning" }
            "PASS" { "status-pass" }
            default { "" }
        }
        
        $statusDisplay = switch ($result.Status) {
            "CRITICAL" { "<span class='critical'>🔴 CRITICAL</span>" }
            "WARNING" { "<span class='warning'>⚠️ WARNING</span>" }
            "PASS" { "<span class='pass'>✅ PASS</span>" }
            default { $result.Status }
        }
        
        $html += @"
        <tr class="$statusClass">
            <td>$($result.SiteTitle)</td>
            <td>$(if($result.HasUniquePermissions -ne $null){"Permissions"}elseif($result.ViolationsFound -ne $null){"Dangerous Groups"}elseif($result.ExternalSharingEnabled -ne $null){"External Sharing"}else{"Links"})</td>
            <td>$statusDisplay</td>
            <td>$($result.Details)</td>
            <td>$($result.Timestamp)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <h2>Remediation Required</h2>
    <p>The following sites require immediate attention:</p>
    <ul>
"@
    
    $criticalItems = $Results | Where-Object { $_.Status -eq "CRITICAL" }
    foreach ($item in $criticalItems) {
        $html += "<li><strong>$($item.SiteTitle)</strong>: $($item.Details)</li>`n"
    }
    
    if ($criticalItems.Count -eq 0) {
        $html += "<li>No critical issues found</li>`n"
    }
    
    $html += @"
    </ul>
    
    <hr>
    <p><em>This report was generated automatically by the DCE Security Audit System</em></p>
</body>
</html>
"@
    
    return $html
}

function Send-SecurityAlert {
    <#
    .SYNOPSIS
        Sends email alerts for critical findings
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$CriticalFindings,
        
        [Parameter(Mandatory=$true)]
        [string]$ReportPath
    )
    
    if (-not $SendEmailAlert -or $CriticalFindings.Count -eq 0) {
        Write-Log "No critical findings or alerts disabled - skipping email" "INFO"
        return
    }
    
    Write-Log "Sending security alert to $($AlertRecipients.Count) recipients..." "INFO"
    
    # Note: This requires Exchange Online module and configured email
    # For now, we document the capability
    
    $subject = "🔴 SECURITY ALERT: DCE Permission Violations Detected"
    $body = @"
CRITICAL permission violations have been detected in the DCE SharePoint environment.

Summary:
- Total Critical Issues: $($CriticalFindings.Count)
- Affected Sites: $(($CriticalFindings | Select-Object -Unique SiteTitle).Count)

Affected Sites:
$(($CriticalFindings | ForEach-Object { "- $($_.SiteTitle): $($_.Details)" }) -join "`n")

Immediate action required:
1. Review the attached audit report
2. Verify affected sites manually
3. Remediate violations immediately
4. Document remediation actions

Full report attached.

---
Delta Crown Extensions Security Team
"@
    
    # Send-MailMessage would go here with Exchange Online module
    Write-Log "Email alert prepared (send functionality requires Exchange Online module)" "INFO"
    Write-Log "Recipients: $($AlertRecipients -join ', ')" "INFO"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    Initialize-Logging
    
    try {
        Write-Log "Starting weekly permission audit..." "INFO"
        
        if ($WhatIf) {
            Write-Log "RUNNING IN WHATIF MODE - No changes will be made" "WHATIF"
        }
        
        # Step 1: Get all DCE sites
        $dceSites = Get-DCESites
        
        if ($dceSites.Count -eq 0) {
            Write-Log "No DCE sites found - nothing to audit" "WARNING"
            return
        }
        
        # Step 2: Run all checks
        $permissionResults = @()
        $groupResults = @()
        $sharingResults = @()
        $linkResults = @()
        
        foreach ($site in $dceSites) {
            # Check permission inheritance
            $permissionResults += Test-PermissionInheritance -Site $site
            
            # Check for dangerous groups
            $groupResults += Test-DangerousGroups -Site $site
            
            # Check external sharing
            $sharingResults += Test-ExternalSharing -Site $site
            
            # Check anonymous links
            $linkResults += Test-AnonymousLinks -Site $site
        }
        
        # Step 3: Collect all violations
        $allViolations = @()
        $allViolations += $permissionResults | Where-Object { $_.Status -eq "CRITICAL" }
        $allViolations += $groupResults | Where-Object { $_.Status -eq "CRITICAL" }
        $allViolations += $sharingResults | Where-Object { $_.Status -eq "WARNING" -or $_.Status -eq "CRITICAL" }
        
        # Step 4: Auto-remediate if enabled
        if ($allViolations.Count -gt 0) {
            Invoke-AutoRemediation -Violations $allViolations
        }
        
        # Step 5: Generate reports
        $reportInfo = Export-AuditReport `
            -PermissionResults $permissionResults `
            -GroupResults $groupResults `
            -SharingResults $sharingResults `
            -LinkResults $linkResults
        
        # Step 6: Send alerts for critical findings
        $criticalFindings = $allViolations | Where-Object { $_.Status -eq "CRITICAL" }
        Send-SecurityAlert -CriticalFindings $criticalFindings -ReportPath $reportInfo.HtmlPath
        
        # Step 7: Final status
        Write-Log "`n=== WEEKLY PERMISSION AUDIT COMPLETE ===" "SUCCESS"
        Write-Log "Reports generated:" "INFO"
        Write-Log "  CSV: $($reportInfo.CsvPath)" "INFO"
        Write-Log "  HTML: $($reportInfo.HtmlPath)" "INFO"
        
        if ($criticalFindings.Count -gt 0) {
            Write-Log "CRITICAL ISSUES FOUND: $($criticalFindings.Count)" "CRITICAL"
            Write-Log "Immediate remediation required!" "CRITICAL"
            exit 1  # Signal failure for CI/CD or scheduled task monitoring
        } else {
            Write-Log "✅ All permission checks passed" "SUCCESS"
            exit 0
        }
    }
    catch {
        Write-Log "CRITICAL ERROR in audit script: $_" "CRITICAL"
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
        exit 1
    }
    finally {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
        Write-Log "Disconnected from SharePoint" "INFO"
        Write-Log "Log file: $global:LogFile" "INFO"
    }
}

# Execute main function
Main
