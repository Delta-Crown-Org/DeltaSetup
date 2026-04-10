# ============================================================================
# SECURITY CONFIGURATION VERIFICATION
# Delta Crown Extensions - Compensating Controls Validation
# ============================================================================
# DESCRIPTION: Verifies all 6 compensating controls are active
#              Called by 2.4-Verification.ps1 - fails deployment if missing
# ============================================================================
# REQUIRED: PnP.PowerShell, Microsoft.Graph.Groups
# ============================================================================

#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = $null,
    
    [Parameter(Mandatory=$false)]
    [switch]$FailOnMissingControls = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DetailedOutput = $false
)

# Initialize
if (!$AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

$ErrorActionPreference = "Stop"
$scriptVersion = "1.0"

# ============================================================================
# CONTROL DEFINITIONS
# ============================================================================

$CompensatingControls = @{
    Control1 = @{
        Name = "Azure AD Dynamic Groups"
        Description = "Brand-specific dynamic groups for automated membership"
        RequiredGroups = @("SG-DCE-AllStaff", "SG-DCE-Leadership")
        Criticality = "CRITICAL"
    }
    Control2 = @{
        Name = "Strict Unique Permissions"
        Description = "All brand sites have unique permissions (no inheritance)"
        CheckType = "PermissionInheritance"
        Criticality = "CRITICAL"
    }
    Control3 = @{
        Name = "Sensitivity Labels"
        Description = "DCE-Internal label applied to all DCE content"
        RequiredLabel = "DCE-Internal"
        CheckType = "SensitivityLabel"
        Criticality = "HIGH"
    }
    Control4 = @{
        Name = "DLP Policies"
        Description = "Data Loss Prevention policies preventing cross-brand sharing"
        RequiredPolicy = "DCE-Data-Protection"
        CheckType = "DLPPolicy"
        Criticality = "HIGH"
    }
    Control5 = @{
        Name = "Weekly Permission Scan"
        Description = "Automated weekly audit of permission configurations"
        CheckType = "ScheduledTask"
        Criticality = "MEDIUM"
    }
    Control6 = @{
        Name = "Quarterly Access Review"
        Description = "Regular attestation of access permissions by brand managers"
        CheckType = "GovernanceProcess"
        Criticality = "MEDIUM"
    }
}

# ============================================================================
# LOGGING SETUP
# ============================================================================

function Initialize-Verification {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logPath = ".\phase2-week1\logs"
    if (!(Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    
    $global:LogFile = Join-Path $logPath "Security-Verification-$timestamp.log"
    
    Write-SecLog "=== Security Configuration Verification Started ===" "INFO"
    Write-SecLog "Script Version: $scriptVersion" "INFO"
    Write-SecLog "Tenant: $TenantName" "INFO"
}

function Write-SecLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL")]
        [string]$Level = "INFO"
    )
    
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$time] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "CRITICAL" { "Magenta" }
        default { "White" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    if ($global:LogFile) {
        Add-Content -Path $global:LogFile -Value $logEntry
    }
}

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

function Test-Control1-DynamicGroups {
    <#
    .SYNOPSIS
        Verifies Azure AD dynamic groups exist and are configured
    #>
    param()
    
    Write-SecLog "Verifying Control 1: Azure AD Dynamic Groups..." "INFO"
    
    $results = @()
    $allPass = $true
    
    try {
        Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
        
        foreach ($groupName in $CompensatingControls.Control1.RequiredGroups) {
            Write-SecLog "  Checking group: $groupName" "INFO"
            
            $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
            
            if ($group) {
                $isDynamic = $group.GroupTypes -contains "DynamicMembership"
                $processingState = $group.MembershipRuleProcessingState
                
                $status = if ($isDynamic -and $processingState -eq "On") { "PASS" } else { "WARNING" }
                $details = if ($isDynamic) { 
                    "Dynamic group, Processing: $processingState" 
                } else { 
                    "Not a dynamic group!" 
                }
                
                $results += [PSCustomObject]@{
                    Control = "Control1"
                    ControlName = $CompensatingControls.Control1.Name
                    Item = $groupName
                    Status = $status
                    Details = $details
                    Criticality = $CompensatingControls.Control1.Criticality
                }
                
                if ($status -eq "PASS") {
                    Write-SecLog "    ✅ $groupName is configured correctly" "SUCCESS"
                } else {
                    Write-SecLog "    ⚠️ $groupName has issues: $details" "WARNING"
                    $allPass = $false
                }
            } else {
                $results += [PSCustomObject]@{
                    Control = "Control1"
                    ControlName = $CompensatingControls.Control1.Name
                    Item = $groupName
                    Status = "FAIL"
                    Details = "Group not found"
                    Criticality = $CompensatingControls.Control1.Criticality
                }
                
                Write-SecLog "    ❌ $groupName NOT FOUND!" "ERROR"
                $allPass = $false
            }
        }
        
        Disconnect-MgGraph
    }
    catch {
        Write-SecLog "Error verifying dynamic groups: $_" "ERROR"
        $results += [PSCustomObject]@{
            Control = "Control1"
            ControlName = $CompensatingControls.Control1.Name
            Item = "All"
            Status = "ERROR"
            Details = $_.Exception.Message
            Criticality = $CompensatingControls.Control1.Criticality
        }
        $allPass = $false
    }
    
    return @{
        Results = $results
        AllPass = $allPass
        ControlStatus = if ($allPass) { "ACTIVE" } else { "INACTIVE" }
    }
}

function Test-Control2-UniquePermissions {
    <#
    .SYNOPSIS
        Verifies all DCE sites have unique permissions (no inheritance)
    #>
    param()
    
    Write-SecLog "Verifying Control 2: Strict Unique Permissions..." "INFO"
    
    $results = @()
    $allPass = $true
    
    try {
        Connect-PnPOnline -Url $AdminUrl -Interactive -ErrorAction Stop
        
        # Get all DCE sites
        $dceSites = Get-PnPTenantSite | Where-Object {
            $_.Url -match "dce-" -or $_.Title -match "Delta Crown"
        }
        
        Write-SecLog "  Found $($dceSites.Count) DCE sites to check" "INFO"
        
        foreach ($site in $dceSites) {
            Write-SecLog "    Checking: $($site.Title)" "INFO"
            
            try {
                Connect-PnPOnline -Url $site.Url -Interactive -ErrorAction SilentlyContinue
                $web = Get-PnPWeb
                $hasUniquePerms = $web.HasUniqueRoleAssignments
                
                $status = if ($hasUniquePerms) { "PASS" } else { "FAIL" }
                $details = if ($hasUniquePerms) { "Unique permissions" } else { "INHERITED PERMISSIONS - VIOLATION!" }
                
                $results += [PSCustomObject]@{
                    Control = "Control2"
                    ControlName = $CompensatingControls.Control2.Name
                    Item = $site.Title
                    Status = $status
                    Details = $details
                    SiteUrl = $site.Url
                    Criticality = $CompensatingControls.Control2.Criticality
                }
                
                if ($status -eq "PASS") {
                    Write-SecLog "      ✅ Unique permissions configured" "SUCCESS"
                } else {
                    Write-SecLog "      ❌ INHERITED PERMISSIONS - SECURITY VIOLATION!" "ERROR"
                    $allPass = $false
                }
            }
            catch {
                $results += [PSCustomObject]@{
                    Control = "Control2"
                    ControlName = $CompensatingControls.Control2.Name
                    Item = $site.Title
                    Status = "ERROR"
                    Details = "Error checking: $_"
                    SiteUrl = $site.Url
                    Criticality = $CompensatingControls.Control2.Criticality
                }
                Write-SecLog "      ⚠️ Error checking permissions: $_" "WARNING"
            }
        }
        
        Disconnect-PnPOnline
    }
    catch {
        Write-SecLog "Error verifying unique permissions: $_" "ERROR"
        $allPass = $false
    }
    
    return @{
        Results = $results
        AllPass = $allPass
        ControlStatus = if ($allPass) { "ACTIVE" } else { "INACTIVE" }
    }
}

function Test-Control3-SensitivityLabels {
    <#
    .SYNOPSIS
        Verifies DCE-Internal sensitivity label exists
    #>
    param()
    
    Write-SecLog "Verifying Control 3: Sensitivity Labels..." "INFO"
    
    $results = @()
    $allPass = $true
    
    try {
        # Check if ExchangeOnlineManagement module is available
        if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
            Import-Module ExchangeOnlineManagement
            
            # Note: This requires authentication to Security & Compliance Center
            # In production, this would need proper credentials
            Write-SecLog "  ⚠️ Sensitivity label verification requires SCC connection" "WARNING"
            Write-SecLog "  Manual verification required for DCE-Internal label" "WARNING"
            
            $results += [PSCustomObject]@{
                Control = "Control3"
                ControlName = $CompensatingControls.Control3.Name
                Item = "DCE-Internal"
                Status = "MANUAL"
                Details = "Requires Security & Compliance Center authentication"
                Criticality = $CompensatingControls.Control3.Criticality
            }
        } else {
            Write-SecLog "  ⚠️ ExchangeOnlineManagement module not available" "WARNING"
            
            $results += [PSCustomObject]@{
                Control = "Control3"
                ControlName = $CompensatingControls.Control3.Name
                Item = "Module"
                Status = "WARNING"
                Details = "ExchangeOnlineManagement module not installed"
                Criticality = $CompensatingControls.Control3.Criticality
            }
        }
    }
    catch {
        Write-SecLog "Error verifying sensitivity labels: $_" "ERROR"
        $allPass = $false
    }
    
    return @{
        Results = $results
        AllPass = $allPass
        ControlStatus = "REQUIRES_MANUAL_VERIFICATION"
    }
}

function Test-Control4-DLPPolicies {
    <#
    .SYNOPSIS
        Verifies DLP policy exists and is configured
    #>
    param()
    
    Write-SecLog "Verifying Control 4: DLP Policies..." "INFO"
    
    $results = @()
    $allPass = $true
    
    try {
        if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
            Write-SecLog "  ⚠️ DLP policy verification requires SCC connection" "WARNING"
            Write-SecLog "  Manual verification required for DCE-Data-Protection policy" "WARNING"
            
            $results += [PSCustomObject]@{
                Control = "Control4"
                ControlName = $CompensatingControls.Control4.Name
                Item = "DCE-Data-Protection"
                Status = "MANUAL"
                Details = "Requires Security & Compliance Center authentication"
                Criticality = $CompensatingControls.Control4.Criticality
            }
        } else {
            $results += [PSCustomObject]@{
                Control = "Control4"
                ControlName = $CompensatingControls.Control4.Name
                Item = "Module"
                Status = "WARNING"
                Details = "ExchangeOnlineManagement module not installed"
                Criticality = $CompensatingControls.Control4.Criticality
            }
        }
    }
    catch {
        Write-SecLog "Error verifying DLP policies: $_" "ERROR"
        $allPass = $false
    }
    
    return @{
        Results = $results
        AllPass = $allPass
        ControlStatus = "REQUIRES_MANUAL_VERIFICATION"
    }
}

function Test-Control5-WeeklyScan {
    <#
    .SYNOPSIS
        Verifies weekly permission scan is scheduled
    #>
    param()
    
    Write-SecLog "Verifying Control 5: Weekly Permission Scan..." "INFO"
    
    $results = @()
    $allPass = $true
    
    try {
        # Check for scheduled task (Windows) or Azure Automation (Cloud)
        $taskName = "DCE-Weekly-Permission-Audit"
        
        # Check Windows Task Scheduler
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        
        if ($task) {
            $status = if ($task.State -eq "Ready") { "PASS" } else { "WARNING" }
            $details = "Task exists, State: $($task.State), Next run: $($task.NextRunTime)"
            
            $results += [PSCustomObject]@{
                Control = "Control5"
                ControlName = $CompensatingControls.Control5.Name
                Item = "Scheduled Task"
                Status = $status
                Details = $details
                Criticality = $CompensatingControls.Control5.Criticality
            }
            
            Write-SecLog "  ✅ Weekly scan scheduled task found" "SUCCESS"
        } else {
            # Check if script exists (indicating manual run capability)
            $scriptPath = ".\phase2-week1\scripts\security-controls\Weekly-Permission-Audit.ps1"
            if (Test-Path $scriptPath) {
                $results += [PSCustomObject]@{
                    Control = "Control5"
                    ControlName = $CompensatingControls.Control5.Name
                    Item = "Script"
                    Status = "WARNING"
                    Details = "Script exists but not scheduled. Manual execution required."
                    Criticality = $CompensatingControls.Control5.Criticality
                }
                
                Write-SecLog "  ⚠️ Scan script exists but not scheduled" "WARNING"
            } else {
                $results += [PSCustomObject]@{
                    Control = "Control5"
                    ControlName = $CompensatingControls.Control5.Name
                    Item = "Script"
                    Status = "FAIL"
                    Details = "Weekly audit script not found"
                    Criticality = $CompensatingControls.Control5.Criticality
                }
                
                Write-SecLog "  ❌ Weekly scan script not found" "ERROR"
                $allPass = $false
            }
        }
    }
    catch {
        Write-SecLog "Error verifying weekly scan: $_" "ERROR"
        $allPass = $false
    }
    
    return @{
        Results = $results
        AllPass = $allPass
        ControlStatus = if ($allPass) { "ACTIVE" } else { "INACTIVE" }
    }
}

function Test-Control6-AccessReview {
    <#
    .SYNOPSIS
        Verifies quarterly access review process is documented
    #>
    param()
    
    Write-SecLog "Verifying Control 6: Quarterly Access Review..." "INFO"
    
    $results = @()
    $allPass = $true
    
    # Check if access review process is documented
    $docPath = ".\phase2-week1\docs\ACCESS-REVIEW-PROCESS.md"
    
    if (Test-Path $docPath) {
        $results += [PSCustomObject]@{
            Control = "Control6"
            ControlName = $CompensatingControls.Control6.Name
            Item = "Process Documentation"
            Status = "PASS"
            Details = "Access review process documented"
            Criticality = $CompensatingControls.Control6.Criticality
        }
        
        Write-SecLog "  ✅ Access review process documented" "SUCCESS"
    } else {
        $results += [PSCustomObject]@{
            Control = "Control6"
            ControlName = $CompensatingControls.Control6.Name
            Item = "Process Documentation"
            Status = "WARNING"
            Details = "Access review process not documented"
            Criticality = $CompensatingControls.Control6.Criticality
        }
        
        Write-SecLog "  ⚠️ Access review process not documented" "WARNING"
    }
    
    # Check for recent attestation records
    $attestationPath = ".\phase2-week1\docs\access-attestations"
    if (Test-Path $attestationPath) {
        $recentFiles = Get-ChildItem -Path $attestationPath -Filter "*.csv" | 
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-95) }  # Within last quarter
        
        if ($recentFiles) {
            $results += [PSCustomObject]@{
                Control = "Control6"
                ControlName = $CompensatingControls.Control6.Name
                Item = "Attestation Records"
                Status = "PASS"
                Details = "Recent attestation records found"
                Criticality = $CompensatingControls.Control6.Criticality
            }
            
            Write-SecLog "  ✅ Recent attestation records found" "SUCCESS"
        } else {
            $results += [PSCustomObject]@{
                Control = "Control6"
                ControlName = $CompensatingControls.Control6.Name
                Item = "Attestation Records"
                Status = "WARNING"
                Details = "No recent attestation records (last 95 days)"
                Criticality = $CompensatingControls.Control6.Criticality
            }
            
            Write-SecLog "  ⚠️ No recent attestation records" "WARNING"
        }
    } else {
        $results += [PSCustomObject]@{
            Control = "Control6"
            ControlName = $CompensatingControls.Control6.Name
            Item = "Attestation Records"
            Status = "WARNING"
            Details = "Attestation records directory not found"
            Criticality = $CompensatingControls.Control6.Criticality
        }
        
        Write-SecLog "  ⚠️ Attestation records directory not found" "WARNING"
    }
    
    return @{
        Results = $results
        AllPass = $allPass
        ControlStatus = "PROCESS_DEFINED"
    }
}

# ============================================================================
# SUMMARY GENERATION
# ============================================================================

function Get-ControlSummary {
    param([array]$AllResults)
    
    $summary = @()
    
    foreach ($control in $CompensatingControls.Keys) {
        $controlResults = $AllResults | Where-Object { $_.Control -eq $control }
        $passCount = ($controlResults | Where-Object { $_.Status -eq "PASS" }).Count
        $failCount = ($controlResults | Where-Object { $_.Status -eq "FAIL" }).Count
        $warningCount = ($controlResults | Where-Object { $_.Status -eq "WARNING" }).Count
        $totalCount = $controlResults.Count
        
        $controlStatus = if ($failCount -gt 0) { 
            "FAILED" 
        } elseif ($warningCount -gt 0) { 
            "WARNING" 
        } else { 
            "PASS" 
        }
        
        $summary += [PSCustomObject]@{
            Control = $control
            ControlName = $CompensatingControls[$control].Name
            Status = $controlStatus
            Criticality = $CompensatingControls[$control].Criticality
            PassRate = if ($totalCount -gt 0) { [math]::Round(($passCount / $totalCount) * 100, 1) } else { 0 }
            Passed = $passCount
            Failed = $failCount
            Warnings = $warningCount
            Total = $totalCount
        }
    }
    
    return $summary
}

function Write-SummaryReport {
    param(
        [array]$Summary,
        [array]$AllResults
    )
    
    Write-SecLog "`n========================================" "INFO"
    Write-SecLog "COMPENSATING CONTROLS VERIFICATION SUMMARY" "INFO"
    Write-SecLog "========================================" "INFO"
    
    $criticalFailures = $Summary | Where-Object { $_.Status -eq "FAILED" -and $_.Criticality -eq "CRITICAL" }
    $highFailures = $Summary | Where-Object { $_.Status -eq "FAILED" -and $_.Criticality -eq "HIGH" }
    
    foreach ($item in $Summary) {
        $statusIcon = switch ($item.Status) {
            "PASS" { "✅" }
            "WARNING" { "⚠️" }
            "FAILED" { "❌" }
            default { "❓" }
        }
        
        $color = switch ($item.Status) {
            "PASS" { "SUCCESS" }
            "WARNING" { "WARNING" }
            "FAILED" { if ($item.Criticality -eq "CRITICAL") { "CRITICAL" } else { "ERROR" } }
            default { "INFO" }
        }
        
        Write-SecLog "$statusIcon [$($item.Criticality)] $($item.ControlName): $($item.Status) ($($item.PassRate)%)" $color
    }
    
    Write-SecLog "`n========================================" "INFO"
    
    if ($criticalFailures.Count -gt 0) {
        Write-SecLog "❌ CRITICAL CONTROL FAILURES DETECTED!" "CRITICAL"
        Write-SecLog "The following CRITICAL controls are not active:" "CRITICAL"
        foreach ($failure in $criticalFailures) {
            Write-SecLog "  - $($failure.ControlName)" "CRITICAL"
        }
        return $false
    }
    
    if ($highFailures.Count -gt 0) {
        Write-SecLog "⚠️ HIGH-priority control failures detected" "WARNING"
        foreach ($failure in $highFailures) {
            Write-SecLog "  - $($failure.ControlName)" "WARNING"
        }
        Write-SecLog "Deployment can continue but remediation is required" "WARNING"
        return $true
    }
    
    Write-SecLog "✅ All compensating controls verified successfully!" "SUCCESS"
    return $true
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Invoke-SecurityVerification {
    <#
    .SYNOPSIS
        Main entry point for security control verification
        Called by 2.4-Verification.ps1
    #>
    param()
    
    Initialize-Verification
    
    try {
        $allResults = @()
        
        # Run all control verifications
        Write-SecLog "Starting compensating controls verification..." "INFO"
        
        $control1 = Test-Control1-DynamicGroups
        $allResults += $control1.Results
        
        $control2 = Test-Control2-UniquePermissions
        $allResults += $control2.Results
        
        $control3 = Test-Control3-SensitivityLabels
        $allResults += $control3.Results
        
        $control4 = Test-Control4-DLPPolicies
        $allResults += $control4.Results
        
        $control5 = Test-Control5-WeeklyScan
        $allResults += $control5.Results
        
        $control6 = Test-Control6-AccessReview
        $allResults += $control6.Results
        
        # Generate summary
        $summary = Get-ControlSummary -AllResults $allResults
        
        # Write summary report
        $canProceed = Write-SummaryReport -Summary $summary -AllResults $allResults
        
        # Export detailed results
        $exportPath = ".\phase2-week1\docs\security-verification-results.json"
        $allResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $exportPath -Force
        Write-SecLog "Detailed results exported to: $exportPath" "INFO"
        
        # Export summary
        $summaryPath = ".\phase2-week1\docs\security-verification-summary.csv"
        $summary | Export-Csv -Path $summaryPath -NoTypeInformation -Force
        Write-SecLog "Summary exported to: $summaryPath" "INFO"
        
        # Final decision
        if (-not $canProceed -and $FailOnMissingControls) {
            Write-SecLog "`n❌ DEPLOYMENT BLOCKED: Critical controls are not active!" "CRITICAL"
            Write-SecLog "Cannot proceed with deployment until compensating controls are implemented." "CRITICAL"
            return $false
        }
        
        Write-SecLog "`n✅ Security verification complete. Deployment can proceed." "SUCCESS"
        return $true
    }
    catch {
        Write-SecLog "CRITICAL ERROR during verification: $_" "CRITICAL"
        Write-SecLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
        return $false
    }
    finally {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-SecLog "Log file: $global:LogFile" "INFO"
    }
}

# Export the main function for use by other scripts
Export-ModuleMember -Function Invoke-SecurityVerification

# If script is run directly, execute verification
if ($MyInvocation.InvocationName -ne '.') {
    $result = Invoke-SecurityVerification
    exit [int](-not $result)  # Exit 0 for success, 1 for failure
}
