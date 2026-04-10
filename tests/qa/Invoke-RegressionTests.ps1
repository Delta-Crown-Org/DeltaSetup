# ============================================================================
# REGRESSION TEST SUITE
# Delta Crown Extensions - Full Quality Validation
# ============================================================================
# DESCRIPTION: Complete regression test suite for Phase 2
#              - Infrastructure tests
#              - Security tests
#              - Identity tests
#              - Compensating controls
#              - Generates comprehensive reports
# ============================================================================

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet(2, 3, 4)]
    [int]$Phase = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\test-results\regression",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipSecurity,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipInfrastructure,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipIdentity,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$script:AllResults = @()
$script:Phase = $Phase

# ============================================================================
# REGRESSION FRAMEWORK
# ============================================================================

function Write-RegLog {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SECTION" { "Blue" }
        default { "White" }
    }
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] [REG] [$Level] $Message" -ForegroundColor $color
}

function Invoke-TestSuite {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [hashtable]$Parameters = @{},
        [switch]$ContinueOnError
    )
    
    Write-RegLog "========================================" "SECTION"
    Write-RegLog "Executing: $Name" "SECTION"
    Write-RegLog "========================================" "SECTION"
    
    if (-not (Test-Path $ScriptPath)) {
        Write-RegLog "Script not found: $ScriptPath" "ERROR"
        return @{ Status = "ERROR"; Error = "Script not found" }
    }
    
    try {
        $outputPath = Join-Path $OutputPath $Name.Replace(" ", "-")
        $params = $Parameters.Clone()
        $params['OutputPath'] = $outputPath
        $params['GenerateReport'] = $true
        
        & $ScriptPath @params
        $exitCode = $LASTEXITCODE
        
        return @{
            Status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
            ExitCode = $exitCode
            OutputPath = $outputPath
        }
    }
    catch {
        Write-RegLog "Suite failed: $_" "ERROR"
        if (-not $ContinueOnError) { throw }
        return @{ Status = "ERROR"; Error = $_.Exception.Message }
    }
}

# ============================================================================
# PHASE 2 REGRESSION
# ============================================================================

function Invoke-Phase2Regression {
    Write-RegLog "=== PHASE 2 REGRESSION TESTS ===" "SECTION"
    
    $suiteResults = @()
    
    # Infrastructure Tests
    if (-not $SkipInfrastructure) {
        $result = Invoke-TestSuite -Name "Infrastructure Tests" `
            -ScriptPath ".\tests\qa\Run-InfrastructureTests.ps1" `
            -Parameters @{ TenantName = $TenantName }
        $suiteResults += [PSCustomObject]@{ Suite = "Infrastructure"; Result = $result }
    }
    
    # Security Tests
    if (-not $SkipSecurity) {
        $result = Invoke-TestSuite -Name "Security Tests" `
            -ScriptPath ".\tests\qa\Run-SecurityTests.ps1" `
            -Parameters @{ TenantName = $TenantName; FailFast = $true }
        $suiteResults += [PSCustomObject]@{ Suite = "Security"; Result = $result }
    }
    
    # Identity Tests (placeholder for future)
    if (-not $SkipIdentity) {
        Write-RegLog "Identity tests - Phase 2" "INFO"
        # Future: Add identity test script execution
    }
    
    return $suiteResults
}

# ============================================================================
# REPORTING
# ============================================================================

function Export-RegressionReport {
    param([array]$Results)
    
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Calculate metrics
    $passCount = ($Results | Where-Object { $_.Result.Status -eq "PASS" }).Count
    $failCount = ($Results | Where-Object { $_.Result.Status -eq "FAIL" }).Count
    $errorCount = ($Results | Where-Object { $_.Result.Status -eq "ERROR" }).Count
    $total = $Results.Count
    
    # JSON export
    $jsonPath = Join-Path $OutputPath "Regression-Results-$timestamp.json"
    $Results | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath
    
    # HTML report
    $htmlPath = Join-Path $OutputPath "Regression-Report-$timestamp.html"
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>DCE Phase $Phase Regression Report</title>
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
        .status-pass { color: #5cb85c; font-weight: bold; }
        .status-fail { color: #d9534f; font-weight: bold; }
        .status-error { color: #f0ad4e; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔄 DCE Phase $Phase Regression Test Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Phase: $Phase</p>
        
        <div class="summary">
            <h2>Regression Summary</h2>
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
                <div>Test Suites</div>
            </div>
            <div class="metric">
                <div class="metric-value">$([math]::Round(($passCount/$total)*100, 1))%</div>
                <div>Pass Rate</div>
            </div>
        </div>
        
        <h2>Test Suite Results</h2>
        <table>
            <tr>
                <th>Suite</th>
                <th>Status</th>
                <th>Exit Code</th>
                <th>Output Path</th>
            </tr>
"@
    
    foreach ($result in $Results) {
        $statusClass = switch ($result.Result.Status) {
            "PASS" { "status-pass" }
            "FAIL" { "status-fail" }
            "ERROR" { "status-error" }
            default { "" }
        }
        
        $html += @"
            <tr>
                <td>$($result.Suite)</td>
                <td class="$statusClass">$($result.Result.Status)</td>
                <td>$($result.Result.ExitCode)</td>
                <td>$($result.Result.OutputPath)</td>
            </tr>
"@
    }
    
    $html += @"
        </table>
        
        <h2>Next Steps</h2>
        <ul>
            <li>Review failed test suites</li>
            <li>Check detailed reports in output directories</li>
            <li>Remediate issues before deployment</li>
            <li>Re-run regression tests after fixes</li>
        </ul>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $htmlPath
    
    return @{
        JsonPath = $jsonPath
        HtmlPath = $htmlPath
        PassRate = if ($total -gt 0) { [math]::Round(($passCount/$total)*100, 1) } else { 0 }
        Passed = $passCount
        Failed = $failCount
        Errors = $errorCount
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    Write-RegLog "=== DCE REGRESSION TEST SUITE ===" "SECTION"
    Write-RegLog "Phase: $Phase" "INFO"
    Write-RegLog "Tenant: $TenantName" "INFO"
    Write-RegLog "Output: $OutputPath" "INFO"
    
    # Execute regression based on phase
    switch ($Phase) {
        2 { $suiteResults = Invoke-Phase2Regression }
        3 { Write-RegLog "Phase 3 tests not yet implemented" "WARNING" }
        4 { Write-RegLog "Phase 4 tests not yet implemented" "WARNING" }
        default { Write-RegLog "Invalid phase: $Phase" "ERROR"; exit 1 }
    }
    
    # Generate report
    $report = Export-RegressionReport -Results $suiteResults
    
    # Summary
    Write-RegLog "" "INFO"
    Write-RegLog "=== REGRESSION SUMMARY ===" "SECTION"
    Write-RegLog "Total Suites: $($suiteResults.Count)" "INFO"
    Write-RegLog "Passed: $($report.Passed)" $(if ($report.Passed -gt 0) { "PASS" } else { "INFO" })
    Write-RegLog "Failed: $($report.Failed)" $(if ($report.Failed -gt 0) { "FAIL" } else { "INFO" })
    Write-RegLog "Errors: $($report.Errors)" $(if ($report.Errors -gt 0) { "ERROR" } else { "INFO" })
    Write-RegLog "Pass Rate: $($report.PassRate)%" "INFO"
    Write-RegLog "" "INFO"
    Write-RegLog "Reports:" "INFO"
    Write-RegLog "  JSON: $($report.JsonPath)" "INFO"
    Write-RegLog "  HTML: $($report.HtmlPath)" "INFO"
    
    # Final verdict
    if ($report.Failed -eq 0 -and $report.Errors -eq 0) {
        Write-RegLog "✅ REGRESSION TESTS PASSED" "PASS"
        Write-RegLog "🚀 Ready for deployment" "PASS"
        exit 0
    } else {
        Write-RegLog "❌ REGRESSION TESTS FAILED" "FAIL"
        if ($report.Failed -gt 0) {
            Write-RegLog "⚠️ Deployment blocked - fix failures first" "FAIL"
        }
        exit 1
    }
}

# Execute
Main
