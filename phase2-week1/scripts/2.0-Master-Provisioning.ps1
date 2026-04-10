# ============================================================================
# PHASE 2.0: Master Orchestration Script (REMEDIATED)
# Delta Crown Extensions - SharePoint Hub & Spoke Architecture
# ============================================================================
# VERSION: 2.1.0
# DESCRIPTION: Orchestrates all Phase 2.1-2.3 tasks with dependency management,
#              rollback capabilities, and production-ready authentication.
# REMEDIATION: Certificate-based auth, module version constraints,
#              rollback mechanisms, enhanced logging
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Identity.DirectoryManagement";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9-]{3,64}$')]
    [string]$TenantName = "deltacrown",
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^https://[a-zA-Z0-9-]+\.sharepoint\.com(/.*)?$')]
    [string]$AdminUrl = $null,
    
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$OwnerEmail = $null,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "2.1", "2.2", "2.3")]
    [string]$ExecuteTasks = "All",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipVerification,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBusinessPremiumWarning
)

# Auto-calculate admin URL if not provided
if (!$AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

# Error handling
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# ============================================================================
# PATH RESOLUTION (R2.4A: Fix Hard-coded Paths)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

# ============================================================================
# MODULE IMPORT
# ============================================================================
$ModulesPath = Join-Path $ProjectRoot "phase2-week1" "modules"

# Import shared modules
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# Load centralized configuration
$ConfigPath = Join-Path $ModulesPath "DeltaCrown.Config.psd1"
$Config = Import-PowerShellDataFile -Path $ConfigPath

# ============================================================================
# INITIALIZATION
# ============================================================================
$LogPath = Join-Path $ProjectRoot $Config.Logging.LogPath
$ScriptsPath = Join-Path $ProjectRoot $Config.Paths.Scripts
$DocsPath = Join-Path $ProjectRoot $Config.Paths.Docs

foreach ($path in @($LogPath, $ScriptsPath, $DocsPath)) {
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

$LogFile = Join-Path $LogPath "Master-Provisioning-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ResultsFile = Join-Path $DocsPath "provisioning-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# Initialize logging
Write-DeltaCrownLog "Delta Crown Extensions - Phase 2 Master Provisioning" "STAGE"
Write-DeltaCrownLog "Version: 2.1.0 (REMEDIATED)" "INFO"
Write-DeltaCrownLog "Environment: $Environment" "INFO"
Write-DeltaCrownLog "Log File: $LogFile" "INFO"

# ============================================================================
# BUSINESS PREMIUM WARNING (R2.3C)
# ============================================================================
if (!$SkipBusinessPremiumWarning) {
    Show-DeltaCrownBusinessPremiumWarning -ForceAcknowledgment ($Environment -eq "Production")
}

# ============================================================================
# AUTHENTICATION SETUP (R2.1)
# ============================================================================
$AuthConfig = Import-DeltaCrownAuthConfig -Environment $Environment

# ============================================================================
# PREREQUISITE CHECKS (R2.2A)
# ============================================================================
$prereqResults = Test-DeltaCrownPrerequisites -RequiredModules $Config.RequiredModules
Write-DeltaCrownLog "Prerequisite Check Results:" "STAGE"
$prereqResults.Results | ForEach-Object { 
    $level = if ($_.Status -eq "PASS") { "SUCCESS" } else { "WARNING" }
    Write-DeltaCrownLog "  $($_.Module): $($_.Status) (Required: $($_.RequiredVersion), Current: $($_.CurrentVersion))" $level
}

if (!$prereqResults.AllPassed -and !$Force) {
    throw "Prerequisite checks failed. Install missing modules or use -Force to continue."
}

# Auto-calculate admin URL if not provided
if (!$AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

# ============================================================================
# ROLLBACK REGISTRATION HELPER (R2.4D)
# ============================================================================
function Register-SiteCleanup {
    param([string]$SiteUrl)
    
    Register-DeltaCrownRollbackAction -ActionName "Delete Site: $SiteUrl" -Action {
        param($ctx)
        try {
            Connect-PnPOnline -Url $ctx.AdminUrl -Interactive
            Remove-PnPTenantSite -Url $ctx.SiteUrl -Force -SkipRecycleBin -ErrorAction SilentlyContinue
            Write-DeltaCrownLog "Rollback: Deleted site $($ctx.SiteUrl)" "INFO"
        }
        catch {
            Write-DeltaCrownLog "Rollback: Failed to delete site $($ctx.SiteUrl): $_" "WARNING"
        }
    } -Context @{ SiteUrl = $SiteUrl; AdminUrl = $AdminUrl }
}

function Register-GroupCleanup {
    param([string]$GroupId)
    
    Register-DeltaCrownRollbackAction -ActionName "Delete Group: $GroupId" -Action {
        param($ctx)
        try {
            Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome
            Remove-MgGroup -GroupId $ctx.GroupId -ErrorAction SilentlyContinue
            Write-DeltaCrownLog "Rollback: Deleted group $($ctx.GroupId)" "INFO"
        }
        catch {
            Write-DeltaCrownLog "Rollback: Failed to delete group $($ctx.GroupId): $_" "WARNING"
        }
    } -Context @{ GroupId = $GroupId }
}

# ============================================================================
# TASK 2.1: CORPORATE HUB
# ============================================================================
function Invoke-Task21 {
    param([string]$Owner)
    
    Write-DeltaCrownBanner "TASK 2.1: Corporate Shared Services Hub Setup"
    
    $scriptPath = Join-Path $ScriptsPath "2.1-CorpHub-Provisioning.ps1"
    
    if (!(Test-Path $scriptPath)) {
        throw "Task 2.1 script not found: $scriptPath"
    }
    
    $params = @{
        TenantName = $TenantName
        AdminUrl = $AdminUrl
        OwnerEmail = $Owner
        Environment = $Environment
    }
    
    if ($WhatIf) {
        Write-DeltaCrownLog "WHATIF: Would execute 2.1-CorpHub-Provisioning.ps1" "WARNING"
        return @{ Task = "2.1"; Status = "WHATIF"; Output = $null }
    }
    
    try {
        # Use splatting to pass parameters
        $output = & $scriptPath @params
        Write-DeltaCrownLog "Task 2.1 completed successfully" "SUCCESS"
        
        # Register rollback if sites were created
        if ($output.AssociatedSites) {
            foreach ($site in $output.AssociatedSites) {
                if ($site.Status -eq "CREATED") {
                    Register-SiteCleanup -SiteUrl $site.Url
                }
            }
        }
        
        return @{ Task = "2.1"; Status = "SUCCESS"; Output = $output }
    }
    catch {
        Write-DeltaCrownLog "Task 2.1 failed: $_" "ERROR"
        return @{ Task = "2.1"; Status = "FAILED"; Error = $_.Exception.Message }
    }
}

# ============================================================================
# TASK 2.2: DCE HUB
# ============================================================================
function Invoke-Task22 {
    param([string]$Owner)
    
    Write-DeltaCrownBanner "TASK 2.2: Delta Crown Extensions Hub Setup"
    
    $scriptPath = Join-Path $ScriptsPath "2.2-DCEHub-Provisioning.ps1"
    
    if (!(Test-Path $scriptPath)) {
        throw "Task 2.2 script not found: $scriptPath"
    }
    
    $params = @{
        TenantName = $TenantName
        AdminUrl = $AdminUrl
        OwnerEmail = $Owner
        Environment = $Environment
    }
    
    if ($WhatIf) {
        Write-DeltaCrownLog "WHATIF: Would execute 2.2-DCEHub-Provisioning.ps1" "WARNING"
        return @{ Task = "2.2"; Status = "WHATIF"; Output = $null }
    }
    
    try {
        $output = & $scriptPath @params
        Write-DeltaCrownLog "Task 2.2 completed successfully" "SUCCESS"
        
        # Register rollback
        if ($output.DCEHubUrl) {
            Register-SiteCleanup -SiteUrl $output.DCEHubUrl
        }
        
        return @{ Task = "2.2"; Status = "SUCCESS"; Output = $output }
    }
    catch {
        Write-DeltaCrownLog "Task 2.2 failed: $_" "ERROR"
        return @{ Task = "2.2"; Status = "FAILED"; Error = $_.Exception.Message }
    }
}

# ============================================================================
# TASK 2.3: AZURE AD GROUPS
# ============================================================================
function Invoke-Task23 {
    Write-DeltaCrownBanner "TASK 2.3: Azure AD Dynamic Groups Setup"
    
    $scriptPath = Join-Path $ScriptsPath "2.3-AzureAD-DynamicGroups.ps1"
    
    if (!(Test-Path $scriptPath)) {
        throw "Task 2.3 script not found: $scriptPath"
    }
    
    $params = @{
        Environment = $Environment
    }
    if ($WhatIf) { $params['WhatIf'] = $true }
    
    try {
        $output = & $scriptPath @params
        Write-DeltaCrownLog "Task 2.3 completed successfully" "SUCCESS"
        
        # Register rollback for created groups
        if ($output.GroupsCreated) {
            foreach ($group in $output.GroupsCreated) {
                Register-GroupCleanup -GroupId $group.Id
            }
        }
        
        return @{ Task = "2.3"; Status = "SUCCESS"; Output = $output }
    }
    catch {
        Write-DeltaCrownLog "Task 2.3 failed: $_" "ERROR"
        return @{ Task = "2.3"; Status = "FAILED"; Error = $_.Exception.Message }
    }
}

# ============================================================================
# VERIFICATION
# ============================================================================
function Invoke-Verification {
    Write-DeltaCrownBanner "VERIFICATION PHASE"
    
    $verifyScript = Join-Path $ScriptsPath "2.4-Verification.ps1"
    
    if (Test-Path $verifyScript) {
        try {
            & $verifyScript -TenantName $TenantName -AdminUrl $AdminUrl -Environment $Environment
            Write-DeltaCrownLog "Verification completed" "SUCCESS"
        }
        catch {
            Write-DeltaCrownLog "Verification failed: $_" "ERROR"
        }
    } else {
        Write-DeltaCrownLog "Verification script not found, skipping..." "WARNING"
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 2: WEEK 1 - INFRASTRUCTURE + IDENTITY"
    Write-DeltaCrownLog "Tenant: $TenantName"
    Write-DeltaCrownLog "Admin URL: $AdminUrl"
    Write-DeltaCrownLog "Execute Tasks: $ExecuteTasks"
    Write-DeltaCrownLog "WhatIf Mode: $WhatIf"
    
    # ------------------------------------------------------------------------
    # STEP 1: Get Owner Email (R2.4B: Input Validation)
    # ------------------------------------------------------------------------
    # R2.4A: Require OwnerEmail as parameter (no interactive Read-Host)
    if (!$OwnerEmail) {
        throw "OwnerEmail parameter is required. Pass -OwnerEmail 'admin@example.com'"
    }
    Write-DeltaCrownLog "Site Owner: $OwnerEmail"
    
    # ------------------------------------------------------------------------
    # STEP 3: Execute Tasks
    # ------------------------------------------------------------------------
    $results = @()
    
    if ($ExecuteTasks -in @("All", "2.1")) {
        $result21 = Invoke-Task21 -Owner $OwnerEmail
        $results += $result21
        
        # Stop if 2.1 fails (2.2 depends on it)
        if ($result21.Status -eq "FAILED" -and !$Force) {
            throw "Task 2.1 failed. Phase 2 aborted. Use -Force to continue."
        }
    }
    
    if ($ExecuteTasks -in @("All", "2.2")) {
        $result22 = Invoke-Task22 -Owner $OwnerEmail
        $results += $result22
    }
    
    if ($ExecuteTasks -in @("All", "2.3")) {
        $result23 = Invoke-Task23
        $results += $result23
    }
    
    # ------------------------------------------------------------------------
    # STEP 4: Verification
    # ------------------------------------------------------------------------
    if (!$SkipVerification -and !$WhatIf) {
        Invoke-Verification
    }
    
    # ------------------------------------------------------------------------
    # STEP 5: Export Results (R2.2B: Secure Exports)
    # ------------------------------------------------------------------------
    $finalResults = [PSCustomObject]@{
        Tenant = $TenantName
        AdminUrl = $AdminUrl
        Owner = $OwnerEmail
        Timestamp = Get-Date
        Environment = $Environment
        Tasks = $results
        Prerequisites = $prereqResults.Results
        WhatIf = $WhatIf
    }
    
    # Export to JSON (not encrypted for results, but in production consider encrypting)
    $finalResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsFile -Force
    Write-DeltaCrownLog "Results exported to: $ResultsFile" "SUCCESS"
    
    # Clear rollback stack on success
    Clear-DeltaCrownRollbackStack
    
    # ------------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------------
    Write-DeltaCrownBanner "PHASE 2 COMPLETE"
    
    $successCount = ($results | Where-Object { $_.Status -eq "SUCCESS" }).Count
    $failCount = ($results | Where-Object { $_.Status -eq "FAILED" }).Count
    
    Write-DeltaCrownLog "Tasks Succeeded: $successCount"
    Write-DeltaCrownLog "Tasks Failed: $failCount"
    Write-DeltaCrownLog "Total Tasks: $($results.Count)"
    
    if ($failCount -eq 0) {
        Write-DeltaCrownLog "🎉 All tasks completed successfully!" "SUCCESS"
    } else {
        Write-DeltaCrownLog "⚠ Some tasks failed. Review logs and results." "WARNING"
    }
    
    Write-DeltaCrownLog "Log saved to: $LogFile"
    Write-DeltaCrownLog "Results saved to: $ResultsFile"
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR: $_" "ERROR" -IncludeContext -Exception $_.Exception
    
    # R2.4D: Rollback on failure
    if (!$WhatIf) {
        Write-DeltaCrownLog "Initiating rollback due to failure..." "WARNING"
        Invoke-DeltaCrownRollback -Reason $_.Exception.Message -ContinueOnError
    }
    
    throw
}
finally {
    Write-DeltaCrownLog "Cleaning up connections..."
    Disconnect-DeltaCrownAll
}
