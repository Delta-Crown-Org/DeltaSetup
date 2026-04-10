# ============================================================================
# PHASE 2 INFRASTRUCTURE TESTS
# Delta Crown Extensions - QA Automation
# ============================================================================
# DESCRIPTION: Automated tests for Phase 2 infrastructure components
#              - Hub site provisioning
#              - Hub registration
#              - Hub-to-hub association
#              - Navigation configuration
#              - Associated sites verification
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Pester";ModuleVersion="5.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\test-results",
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport
)

# Initialize
if (!$AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

$ErrorActionPreference = "Stop"
$testResults = @()
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# ============================================================================
# TESTING FRAMEWORK
# ============================================================================

function Write-TestLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet("INFO", "PASS", "FAIL", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] [$Level] $Message" -ForegroundColor $color
}

function New-TestResult {
    param(
        [string]$TestId,
        [string]$TestName,
        [string]$Status,
        [string]$Details,
        [hashtable]$Data = @{}
    )
    
    return [PSCustomObject]@{
        TestId = $TestId
        TestName = $TestName
        Status = $Status
        Details = $Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Data = $Data
    }
}

# ============================================================================
# TEST CASES
# ============================================================================

function Test-TC-INF-001 {
    <#
    .SYNOPSIS
        TC-INF-001: Corporate Hub Site Provisioning
    #>
    Write-TestLog "Running TC-INF-001: Corporate Hub Site Provisioning" "INFO"
    
    try {
        Connect-PnPOnline -Url $AdminUrl -Interactive
        
        $corpHubUrl = "https://$TenantName.sharepoint.com/sites/corp-hub"
        $corpHub = Get-PnPTenantSite -Url $corpHubUrl -ErrorAction SilentlyContinue
        
        if (!$corpHub) {
            return New-TestResult -TestId "TC-INF-001" -TestName "Corporate Hub Site Provisioning" `
                -Status "FAIL" -Details "Corporate Hub site not found at $corpHubUrl"
        }
        
        $checks = @{
            SiteExists = $true
            TitleCorrect = $corpHub.Title -eq "Corporate Shared Services"
            TemplateCorrect = $corpHub.Template -eq "SITEPAGEPUBLISHING#0"
            StatusActive = $corpHub.Status -eq "Active"
        }
        
        $allPassed = $checks.Values -notcontains $false
        $details = "Site: $($corpHub.Title), Template: $($corpHub.Template), Status: $($corpHub.Status)"
        
        if ($allPassed) {
            Write-TestLog "TC-INF-001: PASS - $details" "PASS"
            return New-TestResult -TestId "TC-INF-001" -TestName "Corporate Hub Site Provisioning" `
                -Status "PASS" -Details $details -Data $checks
        } else {
            $failedChecks = $checks.GetEnumerator() | Where-Object { !$_.Value } | Select-Object -ExpandProperty Key
            Write-TestLog "TC-INF-001: FAIL - Failed checks: $($failedChecks -join ', ')" "FAIL"
            return New-TestResult -TestId "TC-INF-001" -TestName "Corporate Hub Site Provisioning" `
                -Status "FAIL" -Details "Failed checks: $($failedChecks -join ', ')" -Data $checks
        }
    }
    catch {
        Write-TestLog "TC-INF-001: ERROR - $($_.Exception.Message)" "ERROR"
        return New-TestResult -TestId "TC-INF-001" -TestName "Corporate Hub Site Provisioning" `
            -Status "ERROR" -Details $_.Exception.Message
    }
}

function Test-TC-INF-002 {
    <#
    .SYNOPSIS
        TC-INF-002: DCE Hub Site Provisioning
    #>
    Write-TestLog "Running TC-INF-002: DCE Hub Site Provisioning" "INFO"
    
    try {
        $dceHubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
        $dceHub = Get-PnPTenantSite -Url $dceHubUrl -ErrorAction SilentlyContinue
        
        if (!$dceHub) {
            return New-TestResult -TestId "TC-INF-002" -TestName "DCE Hub Site Provisioning" `
                -Status "FAIL" -Details "DCE Hub site not found at $dceHubUrl"
        }
        
        $checks = @{
            SiteExists = $true
            TitleCorrect = $dceHub.Title -eq "Delta Crown Extensions Hub"
            TemplateCorrect = $dceHub.Template -eq "SITEPAGEPUBLISHING#0"
        }
        
        $allPassed = $checks.Values -notcontains $false
        $details = "Site: $($dceHub.Title), Template: $($dceHub.Template)"
        
        if ($allPassed) {
            Write-TestLog "TC-INF-002: PASS - $details" "PASS"
            return New-TestResult -TestId "TC-INF-002" -TestName "DCE Hub Site Provisioning" `
                -Status "PASS" -Details $details -Data $checks
        } else {
            $failedChecks = $checks.GetEnumerator() | Where-Object { !$_.Value } | Select-Object -ExpandProperty Key
            Write-TestLog "TC-INF-002: FAIL - Failed checks: $($failedChecks -join ', ')" "FAIL"
            return New-TestResult -TestId "TC-INF-002" -TestName "DCE Hub Site Provisioning" `
                -Status "FAIL" -Details "Failed checks: $($failedChecks -join ', ')" -Data $checks
        }
    }
    catch {
        Write-TestLog "TC-INF-002: ERROR - $($_.Exception.Message)" "ERROR"
        return New-TestResult -TestId "TC-INF-002" -TestName "DCE Hub Site Provisioning" `
            -Status "ERROR" -Details $_.Exception.Message
    }
}

function Test-TC-INF-003 {
    <#
    .SYNOPSIS
        TC-INF-003: Hub Registration Verification
    #>
    Write-TestLog "Running TC-INF-003: Hub Registration Verification" "INFO"
    
    try {
        $results = @()
        
        # Check Corp Hub registration
        $corpHub = Get-PnPHubSite -Identity "https://$TenantName.sharepoint.com/sites/corp-hub" -ErrorAction SilentlyContinue
        $corpHubCheck = [bool]$corpHub
        $results += "CorpHubRegistered=$corpHubCheck"
        
        # Check DCE Hub registration
        $dceHub = Get-PnPHubSite -Identity "https://$TenantName.sharepoint.com/sites/dce-hub" -ErrorAction SilentlyContinue
        $dceHubCheck = [bool]$dceHub
        $results += "DCEHubRegistered=$dceHubCheck"
        
        $allPassed = $corpHubCheck -and $dceHubCheck
        
        if ($allPassed) {
            Write-TestLog "TC-INF-003: PASS - Both hubs registered" "PASS"
            return New-TestResult -TestId "TC-INF-003" -TestName "Hub Registration Verification" `
                -Status "PASS" -Details "Corp Hub ID: $($corpHub.SiteId), DCE Hub ID: $($dceHub.SiteId)"
        } else {
            Write-TestLog "TC-INF-003: FAIL - Corp Hub: $corpHubCheck, DCE Hub: $dceHubCheck" "FAIL"
            return New-TestResult -TestId "TC-INF-003" -TestName "Hub Registration Verification" `
                -Status "FAIL" -Details ($results -join ", ")
        }
    }
    catch {
        Write-TestLog "TC-INF-003: ERROR - $($_.Exception.Message)" "ERROR"
        return New-TestResult -TestId "TC-INF-003" -TestName "Hub Registration Verification" `
            -Status "ERROR" -Details $_.Exception.Message
    }
}

function Test-TC-INF-004 {
    <#
    .SYNOPSIS
        TC-INF-004: Hub-to-Hub Association
    #>
    Write-TestLog "Running TC-INF-004: Hub-to-Hub Association" "INFO"
    
    try {
        Connect-PnPOnline -Url "https://$TenantName.sharepoint.com/sites/dce-hub" -Interactive
        
        $parentHub = Get-PnPHubSiteConnection -ErrorAction SilentlyContinue
        $hasAssociation = [bool]$parentHub
        
        if ($hasAssociation) {
            Write-TestLog "TC-INF-004: PASS - DCE Hub linked to parent" "PASS"
            return New-TestResult -TestId "TC-INF-004" -TestName "Hub-to-Hub Association" `
                -Status "PASS" -Details "DCE Hub linked to parent Hub ID: $($parentHub.Id)"
        } else {
            Write-TestLog "TC-INF-004: FAIL - No parent hub association found" "FAIL"
            return New-TestResult -TestId "TC-INF-004" -TestName "Hub-to-Hub Association" `
                -Status "FAIL" -Details "No parent hub association found"
        }
    }
    catch {
        Write-TestLog "TC-INF-004: ERROR - $($_.Exception.Message)" "ERROR"
        return New-TestResult -TestId "TC-INF-004" -TestName "Hub-to-Hub Association" `
            -Status "ERROR" -Details $_.Exception.Message
    }
}

function Test-TC-INF-005 {
    <#
    .SYNOPSIS
        TC-INF-005: Navigation Configuration
    #>
    Write-TestLog "Running TC-INF-005: Navigation Configuration" "INFO"
    
    try {
        $results = @()
        $hubs = @(
            @{ Url = "sites/corp-hub"; Name = "Corp Hub" },
            @{ Url = "sites/dce-hub"; Name = "DCE Hub" }
        )
        
        foreach ($hub in $hubs) {
            Connect-PnPOnline -Url "https://$TenantName.sharepoint.com/$($hub.Url)" -Interactive
            $navNodes = Get-PnPNavigationNode -Location HubNavigation -ErrorAction SilentlyContinue
            $nodeCount = if ($navNodes) { $navNodes.Count } else { 0 }
            $results += "$($hub.Name)=$nodeCount"
        }
        
        $allPassed = $results | ForEach-Object { ($_ -split "=")[1] -gt 0 }
        
        if ($allPassed) {
            Write-TestLog "TC-INF-005: PASS - Navigation configured: $($results -join ', ')" "PASS"
            return New-TestResult -TestId "TC-INF-005" -TestName "Navigation Configuration" `
                -Status "PASS" -Details ($results -join ", ")
        } else {
            Write-TestLog "TC-INF-005: WARNING - Some hubs have no navigation" "WARNING"
            return New-TestResult -TestId "TC-INF-005" -TestName "Navigation Configuration" `
                -Status "WARNING" -Details ($results -join ", ")
        }
    }
    catch {
        Write-TestLog "TC-INF-005: ERROR - $($_.Exception.Message)" "ERROR"
        return New-TestResult -TestId "TC-INF-005" -TestName "Navigation Configuration" `
            -Status "ERROR" -Details $_.Exception.Message
    }
}

function Test-TC-INF-006 {
    <#
    .SYNOPSIS
        TC-INF-006: Associated Sites Verification
    #>
    Write-TestLog "Running TC-INF-006: Associated Sites Verification" "INFO"
    
    try {
        $associatedSites = @(
            @{ Url = "sites/corp-hr"; Title = "Corporate HR" },
            @{ Url = "sites/corp-it"; Title = "Corporate IT" },
            @{ Url = "sites/corp-finance"; Title = "Corporate Finance" },
            @{ Url = "sites/corp-training"; Title = "Corporate Training" }
        )
        
        $results = @()
        $allPassed = $true
        
        foreach ($site in $associatedSites) {
            $siteUrl = "https://$TenantName.sharepoint.com/$($site.Url)"
            $tenantSite = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
            $exists = [bool]$tenantSite
            
            if ($exists) {
                Connect-PnPOnline -Url $siteUrl -Interactive
                $hubConnection = Get-PnPHubSiteConnection -ErrorAction SilentlyContinue
                $isAssociated = [bool]$hubConnection
                $results += "$($site.Title)=$exists/$isAssociated"
                
                if (!$isAssociated) { $allPassed = $false }
            } else {
                $results += "$($site.Title)=$exists/N/A"
                $allPassed = $false
            }
        }
        
        if ($allPassed) {
            Write-TestLog "TC-INF-006: PASS - All associated sites verified" "PASS"
            return New-TestResult -TestId "TC-INF-006" -TestName "Associated Sites Verification" `
                -Status "PASS" -Details ($results -join ", ")
        } else {
            Write-TestLog "TC-INF-006: FAIL - Some sites missing or not associated" "FAIL"
            return New-TestResult -TestId "TC-INF-006" -TestName "Associated Sites Verification" `
                -Status "FAIL" -Details ($results -join ", ")
        }
    }
    catch {
        Write-TestLog "TC-INF-006: ERROR - $($_.Exception.Message)" "ERROR"
        return New-TestResult -TestId "TC-INF-006" -TestName "Associated Sites Verification" `
            -Status "ERROR" -Details $_.Exception.Message
    }
}

# ============================================================================
# REPORTING
# ============================================================================

function Export-TestReport {
    param(
        [Parameter(Mandatory)]
        [array]$Results,
        
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    
    # Export JSON
    $jsonPath = Join-Path $Path "Infrastructure-Test-Results-$timestamp.json"
    $Results | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath
    Write-TestLog "Results exported to: $jsonPath" "INFO"
    
    # Export CSV
    $csvPath = Join-Path $Path "Infrastructure-Test-Results-$timestamp.csv"
    $Results | Select-Object TestId, TestName, Status, Details, Timestamp | 
        Export-Csv -Path $csvPath -NoTypeInformation
    Write-TestLog "CSV exported to: $csvPath" "INFO"
    
    # Generate HTML report
    $htmlPath = Join-Path $Path "Infrastructure-Test-Report-$timestamp.html"
    $html = Generate-HTMLReport -Results $Results
    $html | Out-File -FilePath $htmlPath
    Write-TestLog "HTML report: $htmlPath" "INFO"
}

function Generate-HTMLReport {
    param([array]$Results)
    
    $passCount = ($Results | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($Results | Where-Object { $_.Status -eq "FAIL" }).Count
    $errorCount = ($Results | Where-Object { $_.Status -eq "ERROR" }).Count
    $total = $Results.Count
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>DCE Infrastructure Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
        h1 { color: #1A1A1A; border-bottom: 3px solid #C9A227; }
        .summary { background: #f9f9f9; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 2em; font-weight: bold; }
        .pass { color: #5cb85c; }
        .fail { color: #d9534f; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #C9A227; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .status-pass { color: #5cb85c; font-weight: bold; }
        .status-fail { color: #d9534f; font-weight: bold; }
        .status-error { color: #f0ad4e; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏗️ DCE Infrastructure Test Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Tenant: $TenantName</p>
        
        <div class="summary">
            <h2>Summary</h2>
            <div class="metric">
                <div class="metric-value pass">$passCount</div>
                <div>Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value fail">$failCount</div>
                <div>Failed</div>
            </div>
            <div class="metric">
                <div class="metric-value">$errorCount</div>
                <div>Errors</div>
            </div>
            <div class="metric">
                <div class="metric-value">$total</div>
                <div>Total</div>
            </div>
            <div class="metric">
                <div class="metric-value">$([math]::Round(($passCount/$total)*100, 1))%</div>
                <div>Pass Rate</div>
            </div>
        </div>
        
        <h2>Test Results</h2>
        <table>
            <tr>
                <th>Test ID</th>
                <th>Test Name</th>
                <th>Status</th>
                <th>Details</th>
                <th>Timestamp</th>
            </tr>
"@
    
    foreach ($result in $Results) {
        $statusClass = switch ($result.Status) {
            "PASS" { "status-pass" }
            "FAIL" { "status-fail" }
            "ERROR" { "status-error" }
            default { "" }
        }
        
        $html += @"
            <tr>
                <td>$($result.TestId)</td>
                <td>$($result.TestName)</td>
                <td class="$statusClass">$($result.Status)</td>
                <td>$($result.Details)</td>
                <td>$($result.Timestamp)</td>
            </tr>
"@
    }
    
    $html += @"
        </table>
    </div>
</body>
</html>
"@
    
    return $html
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    Write-TestLog "=== DCE Phase 2 Infrastructure Tests ===" "INFO"
    Write-TestLog "Tenant: $TenantName" "INFO"
    Write-TestLog "Starting tests..." "INFO"
    
    # Execute all test cases
    $testResults = @()
    $testResults += Test-TC-INF-001
    $testResults += Test-TC-INF-002
    $testResults += Test-TC-INF-003
    $testResults += Test-TC-INF-004
    $testResults += Test-TC-INF-005
    $testResults += Test-TC-INF-006
    
    # Summary
    $passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
    $errorCount = ($testResults | Where-Object { $_.Status -eq "ERROR" }).Count
    
    Write-TestLog "" "INFO"
    Write-TestLog "=== TEST SUMMARY ===" "INFO"
    Write-TestLog "Total: $($testResults.Count)" "INFO"
    Write-TestLog "Passed: $passCount" "PASS"
    Write-TestLog "Failed: $failCount" $(if ($failCount -gt 0) { "FAIL" } else { "INFO" })
    Write-TestLog "Errors: $errorCount" $(if ($errorCount -gt 0) { "ERROR" } else { "INFO" })
    
    # Export results
    if ($GenerateReport) {
        Export-TestReport -Results $testResults -Path $OutputPath
    }
    
    # Final verdict
    if ($failCount -eq 0 -and $errorCount -eq 0) {
        Write-TestLog "✅ ALL INFRASTRUCTURE TESTS PASSED" "PASS"
        exit 0
    } else {
        Write-TestLog "⚠️ SOME TESTS FAILED" "FAIL"
        exit 1
    }
}

# Execute
Main
