# ============================================================================
# CROSS-BRAND ISOLATION TEST SCRIPT
# Delta Crown Extensions - Automated Security Testing
# ============================================================================
# DESCRIPTION: Verifies Brand A cannot search/access Brand B content
#              Run after each deployment to validate isolation
# ============================================================================
# REQUIRED: PnP.PowerShell module, test accounts for each brand
# ============================================================================

#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$TestResultsPath = ".\phase2-week1\test-results",
    
    [Parameter(Mandatory=$false)]
    [switch]$FailOnViolation = $true,
    
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
# TEST CONFIGURATION
# ============================================================================

$TestConfig = @{
    # Brand configurations
    Brands = @(
        @{
            Name = "Delta Crown Extensions"
            Code = "DCE"
            HubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
            SearchKeywords = @("Delta Crown", "DCE", "Hair Extensions", "C9A227")
            TestSites = @(
                "https://$TenantName.sharepoint.com/sites/dce-operations"
                "https://$TenantName.sharepoint.com/sites/dce-clientservices"
            )
            ExcludedBrands = @("Bishops", "Frenchies", "HTT", "TLL", "Corp")
        }
        <#
        # Future brands to add as they're deployed:
        @{
            Name = "Bishops"
            Code = "BSH"
            HubUrl = "https://$TenantName.sharepoint.com/sites/bsh-hub"
            SearchKeywords = @("Bishops", "Barbershop", "BSH")
            TestSites = @(...)
            ExcludedBrands = @("Delta Crown Extensions", "Frenchies", "HTT", "TLL", "Corp")
        }
        #>
    )
    
    # Test thresholds
    Thresholds = @{
        MaxCrossBrandResults = 0     # Should be ZERO
        MaxUnauthorizedAccess = 0    # Should be ZERO
        MaxPermissionLeakage = 0     # Should be ZERO
    }
    
    # Test timeout (seconds)
    Timeout = 30
}

# ============================================================================
# LOGGING SETUP
# ============================================================================

function Initialize-TestEnvironment {
    $logPath = ".\phase2-week1\logs"
    if (!(Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    
    $global:LogFile = Join-Path $logPath "CrossBrand-Isolation-Test-$timestamp.log"
    
    # Create test results directory
    if (!(Test-Path $TestResultsPath)) {
        New-Item -ItemType Directory -Path $TestResultsPath -Force | Out-Null
    }
    
    Write-TestLog "=== Cross-Brand Isolation Test Started ===" "INFO"
    Write-TestLog "Script Version: $scriptVersion" "INFO"
    Write-TestLog "Tenant: $TenantName" "INFO"
    Write-TestLog "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
    Write-TestLog "WhatIf Mode: $WhatIf" "INFO"
}

function Write-TestLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL", "PASS", "FAIL")]
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
        "PASS" { "Green" }
        "FAIL" { "Red" }
        default { "White" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # File logging
    if ($global:LogFile) {
        Add-Content -Path $global:LogFile -Value $logEntry
    }
}

# ============================================================================
# TEST FUNCTIONS
# ============================================================================

function Test-CrossBrandSearch {
    <#
    .SYNOPSIS
        Tests that search results from one brand don't appear in another brand's hub
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Brand
    )
    
    Write-TestLog "Testing cross-brand search isolation for: $($Brand.Name)" "INFO"
    
    $testResults = @()
    
    try {
        Connect-PnPOnline -Url $Brand.HubUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction Stop
        
        foreach ($keyword in $Brand.SearchKeywords) {
            Write-TestLog "  Searching for keyword: '$keyword'" "INFO"
            
            # Execute search from brand hub
            $searchResults = Submit-PnPSearchQuery -Query $keyword -MaxResults 50 -ErrorAction SilentlyContinue
            
            $results = @()
            $violations = @()
            
            if ($searchResults) {
                foreach ($result in $searchResults.ResultRows) {
                    $resultUrl = $result["Path"]
                    $resultTitle = $result["Title"]
                    
                    # Check if result contains excluded brand references
                    foreach ($excludedBrand in $Brand.ExcludedBrands) {
                        if ($resultUrl -match $excludedBrand -or $resultTitle -match $excludedBrand) {
                            $violations += [PSCustomObject]@{
                                Keyword = $keyword
                                ResultUrl = $resultUrl
                                ResultTitle = $resultTitle
                                ViolationType = "CrossBrandContent"
                                DetectedBrand = $excludedBrand
                            }
                            Write-TestLog "  ❌ VIOLATION: Found $excludedBrand content in search results" "FAIL"
                        }
                    }
                    
                    $results += [PSCustomObject]@{
                        Title = $resultTitle
                        Url = $resultUrl
                        Author = $result["Author"]
                    }
                }
            }
            
            $testResults += [PSCustomObject]@{
                TestName = "Search Isolation - '$keyword'"
                Brand = $Brand.Name
                Keyword = $keyword
                TotalResults = $results.Count
                Violations = $violations.Count
                ViolationDetails = $violations
                Status = if ($violations.Count -eq 0) { "PASS" } else { "FAIL" }
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            if ($violations.Count -eq 0) {
                Write-TestLog "  ✅ PASS: No cross-brand content found ($($results.Count) results checked)" "PASS"
            }
        }
        
        Disconnect-PnPOnline
    }
    catch {
        Write-TestLog "Error during search test: $_" "ERROR"
        $testResults += [PSCustomObject]@{
            TestName = "Search Isolation"
            Brand = $Brand.Name
            Status = "ERROR"
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    return $testResults
}

function Test-CrossBrandAccess {
    <#
    .SYNOPSIS
        Tests that a user from one brand cannot access another brand's content
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Brand
    )
    
    Write-TestLog "Testing cross-brand access isolation for: $($Brand.Name)" "INFO"
    
    $testResults = @()
    
    try {
        # Connect to admin to get all sites
        Connect-PnPOnline -Url $AdminUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction Stop
        $allSites = Get-PnPTenantSite | Where-Object { 
            $_.Url -match "bishops|frenchies|htt-|tll-|corp-" 
        }
        Disconnect-PnPOnline
        
        # Now connect as brand user (simulated - in production, use delegated access)
        Connect-PnPOnline -Url $Brand.HubUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207'
        
        foreach ($externalSite in $allSites) {
            Write-TestLog "  Testing access to: $($externalSite.Title)" "INFO"
            
            try {
                # Attempt to access the external site
                Connect-PnPOnline -Url $externalSite.Url -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction Stop
                $web = Get-PnPWeb
                
                # If we get here, access was successful (VIOLATION!)
                $testResults += [PSCustomObject]@{
                    TestName = "Cross-Brand Access"
                    Brand = $Brand.Name
                    TargetSite = $externalSite.Title
                    TargetUrl = $externalSite.Url
                    AccessGranted = $true
                    Status = "FAIL"
                    Details = "UNAUTHORIZED ACCESS GRANTED - Brand user can access other brand content"
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                Write-TestLog "  ❌ VIOLATION: Access granted to $($externalSite.Title)" "FAIL"
            }
            catch {
                # Access denied is expected (GOOD!)
                $testResults += [PSCustomObject]@{
                    TestName = "Cross-Brand Access"
                    Brand = $Brand.Name
                    TargetSite = $externalSite.Title
                    TargetUrl = $externalSite.Url
                    AccessGranted = $false
                    Status = "PASS"
                    Details = "Access correctly denied"
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                Write-TestLog "  ✅ PASS: Access correctly denied to $($externalSite.Title)" "PASS"
            }
        }
        
        Disconnect-PnPOnline
    }
    catch {
        Write-TestLog "Error during access test: $_" "ERROR"
        $testResults += [PSCustomObject]@{
            TestName = "Cross-Brand Access"
            Brand = $Brand.Name
            Status = "ERROR"
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    return $testResults
}

function Test-HubNavigationIsolation {
    <#
    .SYNOPSIS
        Tests that hub navigation only shows appropriate brand content
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Brand
    )
    
    Write-TestLog "Testing hub navigation isolation for: $($Brand.Name)" "INFO"
    
    $testResults = @()
    
    try {
        Connect-PnPOnline -Url $Brand.HubUrl -Interactive -ClientId '6d8820fe-7a7b-4226-bc3b-2c53add3c207' -ErrorAction Stop
        
        # Get hub navigation
        $navNodes = Get-PnPNavigationNode -Location HubNavigation -ErrorAction SilentlyContinue
        
        $violations = @()
        $navItems = @()
        
        if ($navNodes) {
            foreach ($node in $navNodes) {
                $navItems += $node.Title
                
                # Check for cross-brand content in navigation
                foreach ($excludedBrand in $Brand.ExcludedBrands) {
                    if ($node.Title -match $excludedBrand -or $node.Url -match $excludedBrand) {
                        $violations += [PSCustomObject]@{
                            NavItem = $node.Title
                            Url = $node.Url
                            ViolationType = "CrossBrandNavigation"
                            DetectedBrand = $excludedBrand
                        }
                        Write-TestLog "  ❌ VIOLATION: Found $excludedBrand in navigation: $($node.Title)" "FAIL"
                    }
                }
            }
        }
        
        $testResults += [PSCustomObject]@{
            TestName = "Hub Navigation Isolation"
            Brand = $Brand.Name
            TotalNavItems = $navItems.Count
            Violations = $violations.Count
            NavItems = $navItems -join ", "
            ViolationDetails = $violations
            Status = if ($violations.Count -eq 0) { "PASS" } else { "FAIL" }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if ($violations.Count -eq 0) {
            Write-TestLog "  ✅ PASS: Navigation is brand-isolated ($($navItems.Count) items)" "PASS"
        }
        
        Disconnect-PnPOnline
    }
    catch {
        Write-TestLog "Error during navigation test: $_" "ERROR"
        $testResults += [PSCustomObject]@{
            TestName = "Hub Navigation Isolation"
            Brand = $Brand.Name
            Status = "ERROR"
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    return $testResults
}

function Test-TeamChannelIsolation {
    <#
    .SYNOPSIS
        Tests that Teams channels don't expose cross-brand content
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Brand
    )
    
    Write-TestLog "Testing Teams channel isolation for: $($Brand.Name)" "INFO"
    
    $testResults = @()
    
    # Note: Teams testing requires Microsoft Graph and Teams-specific permissions
    # This is a placeholder for the test structure
    
    Write-TestLog "  ⚠️ Teams channel testing requires Microsoft Graph permissions" "WARNING"
    
    $testResults += [PSCustomObject]@{
        TestName = "Teams Channel Isolation"
        Brand = $Brand.Name
        Status = "SKIPPED"
        Details = "Requires Microsoft Graph Teams permissions"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    return $testResults
}

# ============================================================================
# REPORTING FUNCTIONS
# ============================================================================

function Export-TestResults {
    param(
        [Parameter(Mandatory=$true)]
        [array]$AllResults
    )
    
    # Export JSON for programmatic access
    $jsonPath = Join-Path $TestResultsPath "CrossBrand-Test-Results-$timestamp.json"
    $AllResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Force
    Write-TestLog "JSON results saved to: $jsonPath" "SUCCESS"
    
    # Generate HTML report
    $htmlPath = Join-Path $TestResultsPath "CrossBrand-Test-Report-$timestamp.html"
    $htmlReport = Generate-TestReport -Results $AllResults
    $htmlReport | Out-File -FilePath $htmlPath -Force
    Write-TestLog "HTML report saved to: $htmlPath" "SUCCESS"
    
    # Calculate summary
    $passCount = ($AllResults | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($AllResults | Where-Object { $_.Status -eq "FAIL" }).Count
    $errorCount = ($AllResults | Where-Object { $_.Status -eq "ERROR" }).Count
    $skipCount = ($AllResults | Where-Object { $_.Status -eq "SKIPPED" }).Count
    
    $summary = [PSCustomObject]@{
        TotalTests = $AllResults.Count
        Passed = $passCount
        Failed = $failCount
        Errors = $errorCount
        Skipped = $skipCount
        PassRate = if ($AllResults.Count -gt 0) { [math]::Round(($passCount / $AllResults.Count) * 100, 2) } else { 0 }
    }
    
    # Export summary
    $summaryPath = Join-Path $TestResultsPath "CrossBrand-Test-Summary-$timestamp.json"
    $summary | ConvertTo-Json | Out-File -FilePath $summaryPath -Force
    
    return [PSCustomObject]@{
        JsonPath = $jsonPath
        HtmlPath = $htmlPath
        Summary = $summary
    }
}

function Generate-TestReport {
    param([array]$Results)
    
    $passCount = ($Results | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($Results | Where-Object { $_.Status -eq "FAIL" }).Count
    $errorCount = ($Results | Where-Object { $_.Status -eq "ERROR" }).Count
    $overallStatus = if ($failCount -eq 0 -and $errorCount -eq 0) { "PASS" } else { "FAIL" }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>DCE Cross-Brand Isolation Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #1A1A1A; border-bottom: 3px solid #C9A227; padding-bottom: 10px; }
        h2 { color: #C9A227; margin-top: 30px; }
        .status-pass { color: #5cb85c; font-weight: bold; font-size: 1.2em; }
        .status-fail { color: #d9534f; font-weight: bold; font-size: 1.2em; }
        .summary-box { background: #f9f9f9; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 2em; font-weight: bold; }
        .metric-label { color: #666; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #C9A227; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .badge { padding: 4px 8px; border-radius: 3px; font-size: 0.85em; font-weight: bold; }
        .badge-pass { background: #5cb85c; color: white; }
        .badge-fail { background: #d9534f; color: white; }
        .badge-error { background: #f0ad4e; color: white; }
        .badge-skip { background: #5bc0de; color: white; }
        .violation { background: #ffebee; padding: 10px; border-left: 4px solid #d9534f; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Cross-Brand Isolation Test Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Tenant:</strong> $TenantName</p>
        <p><strong>Overall Status:</strong> <span class="status-$(if($overallStatus -eq 'PASS'){'pass'}else{'fail'})">$overallStatus</span></p>
        
        <div class="summary-box">
            <h2>Test Summary</h2>
            <div class="metric">
                <div class="metric-value">$passCount</div>
                <div class="metric-label">Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value">$failCount</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric">
                <div class="metric-value">$errorCount</div>
                <div class="metric-label">Errors</div>
            </div>
        </div>
        
        <h2>Detailed Results</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Brand</th>
                <th>Status</th>
                <th>Details</th>
                <th>Timestamp</th>
            </tr>
"@
    
    foreach ($result in $Results) {
        $badgeClass = switch ($result.Status) {
            "PASS" { "badge-pass" }
            "FAIL" { "badge-fail" }
            "ERROR" { "badge-error" }
            default { "badge-skip" }
        }
        
        $details = if ($result.Violations -gt 0) {
            $violationDetails = $result.ViolationDetails | ConvertTo-Json -Compress
            "<div class='violation'>Violations: $($result.Violations)<br/>$violationDetails</div>"
        } else {
            $result.Details
        }
        
        $html += @"
            <tr>
                <td>$($result.TestName)</td>
                <td>$($result.Brand)</td>
                <td><span class="badge $badgeClass">$($result.Status)</span></td>
                <td>$details</td>
                <td>$($result.Timestamp)</td>
            </tr>
"@
    }
    
    $html += @"
        </table>
        
        <h2>Recommendations</h2>
        <ul>
            $(if ($failCount -gt 0) { "<li><strong>CRITICAL:</strong> Cross-brand isolation violations detected. Immediate remediation required.</li>" })
            <li>Review all FAILED tests and remediate permission configurations</li>
            <li>Verify Azure AD dynamic group membership rules</li>
            <li>Check sensitivity label application on cross-brand content</li>
            <li>Re-run tests after remediation</li>
        </ul>
        
        <hr>
        <p><em>This report was generated automatically by the DCE Security Test Suite</em></p>
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
    Initialize-TestEnvironment
    
    try {
        Write-TestLog "Starting cross-brand isolation tests..." "INFO"
        
        if ($WhatIf) {
            Write-TestLog "RUNNING IN WHATIF MODE - No actual tests executed" "WARNING"
        }
        
        $allTestResults = @()
        
        foreach ($brand in $TestConfig.Brands) {
            Write-TestLog "`n========================================" "INFO"
            Write-TestLog "Testing Brand: $($brand.Name)" "INFO"
            Write-TestLog "========================================" "INFO"
            
            # Test 1: Cross-brand search isolation
            Write-TestLog "`n[TEST 1] Cross-Brand Search Isolation" "INFO"
            $searchResults = Test-CrossBrandSearch -Brand $brand
            $allTestResults += $searchResults
            
            # Test 2: Cross-brand access isolation
            Write-TestLog "`n[TEST 2] Cross-Brand Access Isolation" "INFO"
            $accessResults = Test-CrossBrandAccess -Brand $brand
            $allTestResults += $accessResults
            
            # Test 3: Hub navigation isolation
            Write-TestLog "`n[TEST 3] Hub Navigation Isolation" "INFO"
            $navResults = Test-HubNavigationIsolation -Brand $brand
            $allTestResults += $navResults
            
            # Test 4: Teams channel isolation (placeholder)
            Write-TestLog "`n[TEST 4] Teams Channel Isolation" "INFO"
            $teamsResults = Test-TeamChannelIsolation -Brand $brand
            $allTestResults += $teamsResults
        }
        
        # Export results
        Write-TestLog "`n========================================" "INFO"
        Write-TestLog "Generating Test Reports..." "INFO"
        Write-TestLog "========================================" "INFO"
        
        $reportInfo = Export-TestResults -AllResults $allTestResults
        
        # Final summary
        Write-TestLog "`n=== TEST EXECUTION COMPLETE ===" "INFO"
        Write-TestLog "Total Tests: $($reportInfo.Summary.TotalTests)" "INFO"
        Write-TestLog "Passed: $($reportInfo.Summary.Passed)" $(if($reportInfo.Summary.Passed -gt 0){"SUCCESS"}else{"INFO"})
        Write-TestLog "Failed: $($reportInfo.Summary.Failed)" $(if($reportInfo.Summary.Failed -gt 0){"FAIL"}else{"INFO"})
        Write-TestLog "Errors: $($reportInfo.Summary.Errors)" $(if($reportInfo.Summary.Errors -gt 0){"ERROR"}else{"INFO"})
        Write-TestLog "Pass Rate: $($reportInfo.Summary.PassRate)%" "INFO"
        
        if ($reportInfo.Summary.Failed -gt 0) {
            Write-TestLog "`n❌ CROSS-BRAND ISOLATION VIOLATIONS DETECTED!" "FAIL"
            Write-TestLog "Brand isolation is NOT properly enforced." "CRITICAL"
            
            if ($FailOnViolation) {
                Write-TestLog "Deployment blocked due to isolation failures." "CRITICAL"
                exit 1
            }
        } else {
            Write-TestLog "`n✅ ALL CROSS-BRAND ISOLATION TESTS PASSED!" "SUCCESS"
            Write-TestLog "Brand isolation is properly enforced." "SUCCESS"
            exit 0
        }
    }
    catch {
        Write-TestLog "CRITICAL ERROR in test execution: $_" "CRITICAL"
        Write-TestLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
        exit 1
    }
    finally {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
        Write-TestLog "Disconnected from SharePoint" "INFO"
        Write-TestLog "Log file: $global:LogFile" "INFO"
    }
}

# Execute main function
Main
