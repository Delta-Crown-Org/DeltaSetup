# ============================================================================
# PHASE 2 SMOKE TESTS
# Delta Crown Extensions - Daily Validation
# ============================================================================
# DESCRIPTION: Quick smoke tests for daily validation of Phase 2
#              - Fast execution (< 5 minutes)
#              - Critical path only
#              - Automated report generation
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\test-results\smoke",
    
    [Parameter(Mandatory=$false)]
    [switch]$SendNotification
)

# Initialize
if (!$AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$script:StartTime = Get-Date

# ============================================================================
# SMOKE TEST FRAMEWORK
# ============================================================================

function Write-SmokeLog {
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
    $elapsed = "[{0:mm}:{0:ss}]" -f ((Get-Date) - $script:StartTime)
    Write-Host "[$time] $elapsed [$Level] $Message" -ForegroundColor $color
}

# ============================================================================
# SMOKE TEST CASES
# ============================================================================

$SmokeTests = @(
    @{
        Name = "Hub Sites Accessible"
        Test = {
            Connect-PnPOnline -Url "https://$TenantName.sharepoint.com/sites/corp-hub" -Interactive
            $corpWeb = Get-PnPWeb
            
            Connect-PnPOnline -Url "https://$TenantName.sharepoint.com/sites/dce-hub" -Interactive
            $dceWeb = Get-PnPWeb
            
            return ($corpWeb -and $dceWeb)
        }
        Critical = $true
    },
    @{
        Name = "Hub Sites Registered"
        Test = {
            $corpHub = Get-PnPHubSite -Identity "https://$TenantName.sharepoint.com/sites/corp-hub" -ErrorAction SilentlyContinue
            $dceHub = Get-PnPHubSite -Identity "https://$TenantName.sharepoint.com/sites/dce-hub" -ErrorAction SilentlyContinue
            return ($corpHub -and $dceHub)
        }
        Critical = $true
    },
    @{
        Name = "DCE Hub Linked to Corp Hub"
        Test = {
            Connect-PnPOnline -Url "https://$TenantName.sharepoint.com/sites/dce-hub" -Interactive
            $parent = Get-PnPHubSiteConnection -ErrorAction SilentlyContinue
            return [bool]$parent
        }
        Critical = $true
    },
    @{
        Name = "Associated Sites Accessible"
        Test = {
            $sites = @(
                "sites/corp-hr",
                "sites/corp-it"
            )
            
            foreach ($site in $sites) {
                $url = "https://$TenantName.sharepoint.com/$site"
                $tenantSite = Get-PnPTenantSite -Url $url -ErrorAction SilentlyContinue
                if (-not $tenantSite) { return $false }
            }
            return $true
        }
        Critical = $false
    },
    @{
        Name = "Navigation Nodes Present"
        Test = {
            Connect-PnPOnline -Url "https://$TenantName.sharepoint.com/sites/corp-hub" -Interactive
            $nav = Get-PnPNavigationNode -Location HubNavigation -ErrorAction SilentlyContinue
            return ($nav.Count -gt 0)
        }
        Critical = $false
    },
    @{
        Name = "Permission Inheritance Verified"
        Test = {
            $dceSites = Get-PnPTenantSite | Where-Object { $_.Url -match "dce-" } | Select-Object -First 2
            
            foreach ($site in $dceSites) {
                Connect-PnPOnline -Url $site.Url -Interactive
                $web = Get-PnPWeb
                if (-not $web.HasUniqueRoleAssignments) { return $false }
            }
            return $true
        }
        Critical = $true
    }
)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    Write-SmokeLog "=== DCE Phase 2 Smoke Tests ===" "INFO"
    Write-SmokeLog "Tenant: $TenantName" "INFO"
    
    $results = @()
    $criticalFailures = 0
    
    foreach ($test in $SmokeTests) {
        Write-SmokeLog "Running: $($test.Name)..." "INFO"
        
        try {
            $start = Get-Date
            $result = & $test.Test
            $duration = ((Get-Date) - $start).TotalSeconds
            
            if ($result) {
                Write-SmokeLog "PASS: $($test.Name) (${duration}s)" "PASS"
                $results += [PSCustomObject]@{
                    TestName = $test.Name
                    Status = "PASS"
                    Duration = $duration
                    Critical = $test.Critical
                    Error = $null
                }
            } else {
                Write-SmokeLog "FAIL: $($test.Name)" "FAIL"
                $results += [PSCustomObject]@{
                    TestName = $test.Name
                    Status = "FAIL"
                    Duration = $duration
                    Critical = $test.Critical
                    Error = "Test returned false"
                }
                if ($test.Critical) { $criticalFailures++ }
            }
        }
        catch {
            Write-SmokeLog "ERROR: $($test.Name) - $($_.Exception.Message)" "ERROR"
            $results += [PSCustomObject]@{
                TestName = $test.Name
                Status = "ERROR"
                Duration = 0
                Critical = $test.Critical
                Error = $_.Exception.Message
            }
            if ($test.Critical) { $criticalFailures++ }
        }
    }
    
    # Summary
    $total = $results.Count
    $passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
    $failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
    $errors = ($results | Where-Object { $_.Status -eq "ERROR" }).Count
    $totalDuration = ((Get-Date) - $script:StartTime).TotalSeconds
    
    Write-SmokeLog "" "INFO"
    Write-SmokeLog "=== SMOKE TEST SUMMARY ===" "INFO"
    Write-SmokeLog "Total: $total | Passed: $passed | Failed: $failed | Errors: $errors" "INFO"
    Write-SmokeLog "Duration: ${totalDuration}s" "INFO"
    
    if ($criticalFailures -gt 0) {
        Write-SmokeLog "CRITICAL FAILURES: $criticalFailures" "ERROR"
    }
    
    # Export results
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $csvPath = Join-Path $OutputPath "Smoke-Test-Results-$timestamp.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation
    Write-SmokeLog "Results: $csvPath" "INFO"
    
    # Final verdict
    if ($criticalFailures -eq 0 -and $failed -eq 0 -and $errors -eq 0) {
        Write-SmokeLog "✅ ALL SMOKE TESTS PASSED" "PASS"
        exit 0
    } else {
        Write-SmokeLog "⚠️ SMOKE TESTS FAILED" "FAIL"
        if ($criticalFailures -gt 0) {
            Write-SmokeLog "🔴 CRITICAL FAILURES - INVESTIGATE IMMEDIATELY" "ERROR"
        }
        exit 1
    }
}

# Execute
Main
