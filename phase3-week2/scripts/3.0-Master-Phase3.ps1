# ============================================================================
# PHASE 3.0: Master Orchestrator
# Delta Crown Extensions — Execute All Phase 3 Scripts in Dependency Order
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Validates Phase 2 prerequisite, pre-authenticates ALL services,
#              then executes Phase 3 scripts in dependency order (hands-free)
# ADR: ADR-002 Phase 3 SharePoint Sites + Teams Collaboration
# FIXES: A5 (pre-auth), B4 (AdminUrl pass-through), B5 (LASTEXITCODE),
#        B7 (path separators)
# ============================================================================

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = "https://deltacrownext-admin.sharepoint.com",

    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Sites", "Teams", "Security", "DLP", "Mailboxes", "Templates", "Verify")]
    [string]$Phase = "All",

    [Parameter(Mandatory=$false)]
    [switch]$SkipVerification,

    [Parameter(Mandatory=$false)]
    [switch]$SkipPreCheck,

    [Parameter(Mandatory=$false)]
    [string]$StartFrom = $null  # Resume from specific step: "3.2", "3.3", etc.
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.1.0"

# ============================================================================
# PATH RESOLUTION (B7: Join-Path everywhere, no backslash literals)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

# ============================================================================
# MODULE IMPORT (Auth + Common)
# ============================================================================
$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$LogPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.0-Master-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# EXECUTION PLAN (dependency order)
# ============================================================================
$ExecutionPlan = @(
    @{ Id = "3.1"; Script = "3.1-DCE-Sites-Provisioning.ps1"; Phase = "Sites";     Name = "Site Provisioning" }
    @{ Id = "3.2"; Script = "3.2-Teams-Provisioning.ps1";     Phase = "Teams";     Name = "Teams Workspace" }
    @{ Id = "3.3"; Script = "3.3-Security-Hardening.ps1";     Phase = "Security";  Name = "Security Hardening" }
    @{ Id = "3.4"; Script = "3.4-DLP-Policies.ps1";           Phase = "DLP";       Name = "DLP Policies" }
    @{ Id = "3.5"; Script = "3.5-Shared-Mailboxes.ps1";       Phase = "Mailboxes"; Name = "Shared Mailboxes" }
    @{ Id = "3.6"; Script = "3.6-Template-Export.ps1";         Phase = "Templates"; Name = "Template Export" }
    @{ Id = "3.7"; Script = "3.7-Phase3-Verification.ps1";    Phase = "Verify";    Name = "Verification" }
)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.0: Master Orchestrator"
    Write-DeltaCrownLog "Script Version: $scriptVersion" "INFO"
    Write-DeltaCrownLog "Phase: $Phase" "INFO"
    Write-DeltaCrownLog "Environment: $Environment" "INFO"
    Write-DeltaCrownLog "Tenant: $TenantName" "INFO"

    $masterResults = @{
        StartTime     = Get-Date
        StepsExecuted = @()
        StepsFailed   = @()
        StepsSkipped  = @()
    }

    # ------------------------------------------------------------------
    # PRE-CHECK: Verify Phase 2 is deployed (B5: try/catch, not LASTEXITCODE)
    # ------------------------------------------------------------------
    if (!$SkipPreCheck) {
        Write-DeltaCrownLog "=== Pre-Check: Verifying Phase 2 ===" "STAGE"

        $phase2VerifyScript = Join-Path $ProjectRoot (Join-Path "phase2-week1" (Join-Path "scripts" "2.7-Phase2-Verification.ps1"))
        if (Test-Path $phase2VerifyScript) {
            Write-DeltaCrownLog "Running Phase 2 verification..." "INFO"

            try {
                $phase2Result = & $phase2VerifyScript -TenantName $TenantName -AdminUrl $AdminUrl
                if ($phase2Result -and $phase2Result.Status -eq "PARTIAL") {
                    Write-DeltaCrownLog "Phase 2 has warnings — proceeding with caution" "WARNING"
                }
                else {
                    Write-DeltaCrownLog "Phase 2 verification passed" "SUCCESS"
                }
            }
            catch {
                throw "Phase 2 verification FAILED — Cannot proceed with Phase 3. Run Phase 2 first. Error: $_"
            }
        }
        else {
            Write-DeltaCrownLog "Phase 2 verification script not found — checking hub directly" "WARNING"

            Connect-DeltaCrownSharePoint -Url $AdminUrl

            $dceHub = Get-PnPTenantSite -Url "https://$TenantName.sharepoint.com/sites/dce-hub" -ErrorAction SilentlyContinue
            if (!$dceHub) {
                throw "DCE Hub site not found — Phase 2 must be deployed before Phase 3."
            }

            $isHub = Get-PnPHubSite -Identity "https://$TenantName.sharepoint.com/sites/dce-hub" -ErrorAction SilentlyContinue
            if (!$isHub) {
                throw "DCE Hub is not registered as a hub site — Phase 2 incomplete."
            }

            Write-DeltaCrownLog "DCE Hub verified: $($dceHub.Url)" "SUCCESS"
        }
    }
    else {
        Write-DeltaCrownLog "Skipping Phase 2 pre-check (SkipPreCheck flag)" "WARNING"
    }

    # ------------------------------------------------------------------
    # PRE-AUTHENTICATION (A5: connect all services ONCE upfront)
    # Tyler approves auth prompts here, then everything runs hands-free
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Pre-Authentication ===" "STAGE"
    Write-DeltaCrownLog "You will be prompted to authenticate to up to 4 services." "INFO"
    Write-DeltaCrownLog "After approving, the rest of the execution is hands-free." "INFO"

    $authConfig = Import-DeltaCrownAuthConfig -Environment $Environment

    # 1. SharePoint (PnP) — needed by 3.1, 3.3, 3.6, 3.7
    Write-DeltaCrownLog "Authenticating to SharePoint Online..." "INFO"
    Connect-DeltaCrownSharePoint -Url $AdminUrl -AuthConfig $authConfig
    Write-DeltaCrownLog "SharePoint: Connected ✓" "SUCCESS"

    # 2. Microsoft Graph — needed by 3.2, 3.3, 3.7
    $graphScopes = @(
        "Group.ReadWrite.All",
        "TeamSettings.ReadWrite.All",
        "Channel.Create",
        "TeamsTab.Create",
        "GroupMember.ReadWrite.All",
        "Team.ReadBasic.All",
        "Channel.ReadBasic.All"
    )
    Write-DeltaCrownLog "Authenticating to Microsoft Graph..." "INFO"
    Connect-DeltaCrownGraph -RequiredScopes $graphScopes -AuthConfig $authConfig
    Write-DeltaCrownLog "Graph: Connected ✓" "SUCCESS"

    # 3. Exchange Online — needed by 3.4 (IPPS), 3.5
    if ($Phase -in @("All", "Mailboxes", "DLP")) {
        Write-DeltaCrownLog "Authenticating to Exchange Online..." "INFO"
        Connect-DeltaCrownExchange -AuthConfig $authConfig
        Write-DeltaCrownLog "Exchange: Connected ✓" "SUCCESS"
    }

    # 4. Security & Compliance (IPPS) — needed by 3.4
    if ($Phase -in @("All", "DLP")) {
        Write-DeltaCrownLog "Authenticating to Security & Compliance..." "INFO"
        Connect-DeltaCrownIPPS -AuthConfig $authConfig
        Write-DeltaCrownLog "IPPS: Connected ✓" "SUCCESS"
    }

    Write-DeltaCrownLog "All services authenticated. Execution is now hands-free." "SUCCESS"

    # ------------------------------------------------------------------
    # DETERMINE WHICH STEPS TO RUN
    # ------------------------------------------------------------------
    $stepsToRun = $ExecutionPlan

    # Filter by Phase parameter
    if ($Phase -ne "All") {
        $stepsToRun = $ExecutionPlan | Where-Object { $_.Phase -eq $Phase }
    }

    # Filter by StartFrom parameter
    if ($StartFrom) {
        $startIndex = [array]::IndexOf(($ExecutionPlan | ForEach-Object { $_.Id }), $StartFrom)
        if ($startIndex -lt 0) {
            throw "Invalid StartFrom value: $StartFrom. Valid values: $($ExecutionPlan.Id -join ', ')"
        }
        $stepsToRun = $ExecutionPlan[$startIndex..($ExecutionPlan.Count - 1)]

        # Still filter by Phase if specified
        if ($Phase -ne "All") {
            $stepsToRun = $stepsToRun | Where-Object { $_.Phase -eq $Phase }
        }
    }

    # Skip verification if flag set
    if ($SkipVerification) {
        $stepsToRun = $stepsToRun | Where-Object { $_.Phase -ne "Verify" }
    }

    Write-DeltaCrownLog "Steps to execute: $($stepsToRun.Count)" "INFO"
    foreach ($step in $stepsToRun) {
        Write-DeltaCrownLog "  [$($step.Id)] $($step.Name)" "INFO"
    }

    # ------------------------------------------------------------------
    # EXECUTE EACH STEP (B4: pass AdminUrl to all scripts that accept it)
    # ------------------------------------------------------------------
    foreach ($step in $stepsToRun) {
        $scriptPath = Join-Path $ScriptRoot $step.Script

        if (!(Test-Path $scriptPath)) {
            Write-DeltaCrownLog "Script not found: $scriptPath — SKIPPING" "ERROR"
            $masterResults.StepsSkipped += $step.Id
            continue
        }

        Write-DeltaCrownLog "" "INFO"
        Write-DeltaCrownBanner "EXECUTING: [$($step.Id)] $($step.Name)"

        $stepStart = Get-Date

        try {
            $commonParams = @{
                TenantName  = $TenantName
                Environment = $Environment
            }

            # Pass AdminUrl to scripts that accept it (B4: comprehensive list)
            if ($step.Id -in @("3.1", "3.3", "3.6", "3.7")) {
                $commonParams.AdminUrl = $AdminUrl
            }

            # Pass BrandDomain to 3.5 (Shared Mailboxes)
            if ($step.Id -eq "3.5") {
                $commonParams.BrandDomain = "deltacrown.com.au"
            }

            # Propagate WhatIf
            if ($WhatIfPreference) {
                $commonParams.WhatIf = $true
            }

            $result = & $scriptPath @commonParams

            $stepDuration = (Get-Date) - $stepStart
            Write-DeltaCrownLog "[$($step.Id)] $($step.Name) — COMPLETED in $($stepDuration.TotalMinutes.ToString('F1'))m" "SUCCESS"

            $masterResults.StepsExecuted += @{
                Id       = $step.Id
                Name     = $step.Name
                Duration = $stepDuration.TotalSeconds
                Status   = if ($result.Status) { $result.Status } else { "COMPLETED" }
                Errors   = if ($result.Errors) { $result.Errors.Count } else { 0 }
            }

            # Check for PARTIAL status
            if ($result.Status -eq "PARTIAL") {
                Write-DeltaCrownLog "[$($step.Id)] completed with errors — review before continuing" "WARNING"
            }
        }
        catch {
            $stepDuration = (Get-Date) - $stepStart
            Write-DeltaCrownLog "[$($step.Id)] $($step.Name) — FAILED after $($stepDuration.TotalMinutes.ToString('F1'))m" "CRITICAL"
            Write-DeltaCrownLog "Error: $_" "ERROR"

            $masterResults.StepsFailed += @{
                Id       = $step.Id
                Name     = $step.Name
                Duration = $stepDuration.TotalSeconds
                Error    = $_.ToString()
            }

            # 3.1 is critical — sites must exist for everything else
            if ($step.Id -eq "3.1") {
                throw "Critical step $($step.Id) failed — cannot continue. Fix and retry."
            }

            Write-DeltaCrownLog "Non-critical failure — continuing with remaining steps" "WARNING"
        }
    }

    # ------------------------------------------------------------------
    # COMPLETION SUMMARY
    # ------------------------------------------------------------------
    $masterResults.EndTime = Get-Date
    $totalDuration = $masterResults.EndTime - $masterResults.StartTime

    Write-DeltaCrownBanner "PHASE 3 ORCHESTRATION COMPLETE"
    Write-DeltaCrownLog "Total Duration:    $($totalDuration.TotalMinutes.ToString('F1')) minutes" "INFO"
    Write-DeltaCrownLog "Steps Executed:    $($masterResults.StepsExecuted.Count)" "SUCCESS"
    Write-DeltaCrownLog "Steps Failed:      $($masterResults.StepsFailed.Count)" $(if($masterResults.StepsFailed.Count -gt 0){"ERROR"}else{"SUCCESS"})
    Write-DeltaCrownLog "Steps Skipped:     $($masterResults.StepsSkipped.Count)" $(if($masterResults.StepsSkipped.Count -gt 0){"WARNING"}else{"INFO"})

    foreach ($step in $masterResults.StepsExecuted) {
        Write-DeltaCrownLog "  [$($step.Id)] $($step.Name): $($step.Status) ($($step.Duration.ToString('F0'))s)" "INFO"
    }

    foreach ($step in $masterResults.StepsFailed) {
        Write-DeltaCrownLog "  [$($step.Id)] $($step.Name): FAILED — $($step.Error)" "ERROR"
    }

    # Save master results
    $resultsPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.0-master-results.json"))
    $masterResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force

    Export-DeltaCrownLogBuffer -Path $LogFile

    # Exit code
    if ($masterResults.StepsFailed.Count -gt 0) {
        exit 2
    }
    elseif ($masterResults.StepsSkipped.Count -gt 0) {
        exit 1
    }
    else {
        exit 0
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Master Orchestrator: $_" "CRITICAL"
    Write-DeltaCrownLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    Export-DeltaCrownLogBuffer -Path $LogFile
    exit 2
}
finally {
    Disconnect-DeltaCrownAll
    Write-DeltaCrownLog "All services disconnected" "INFO"
}
