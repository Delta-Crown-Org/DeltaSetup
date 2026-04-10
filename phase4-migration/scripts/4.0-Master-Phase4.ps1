# ============================================================================
# 4.0-Master-Phase4.ps1
# Master Orchestrator for Phase 4: Migration & User Onboarding
# ============================================================================
# PURPOSE: Execute Phase 4 scripts in correct order:
#          1. Verify Phase 2+3 are deployed (pre-check)
#          2. Audit existing users (4.1)
#          3. Onboard users with correct properties (4.2)
#          4. Migrate documents from HTTHQ (4.3)
#          5. Verify migration completeness (4.4)
# ============================================================================
# USAGE:
#   # Full Phase 4 run:
#   ./4.0-Master-Phase4.ps1 -UserMappingFile "../config/dce-user-mapping.csv" `
#       -FileMappingFile "../config/dce-file-mapping.csv"
#
#   # Dry run:
#   ./4.0-Master-Phase4.ps1 -UserMappingFile "../config/dce-user-mapping.csv" `
#       -FileMappingFile "../config/dce-file-mapping.csv" -WhatIf
#
#   # Run only user onboarding:
#   ./4.0-Master-Phase4.ps1 -Phase Users -UserMappingFile "../config/dce-user-mapping.csv"
#
#   # Run only document migration:
#   ./4.0-Master-Phase4.ps1 -Phase Documents -FileMappingFile "../config/dce-file-mapping.csv"
# ============================================================================

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet("All", "Audit", "Users", "Documents", "Verify")]
    [string]$Phase = "All",

    [Parameter()]
    [string]$UserMappingFile,

    [Parameter()]
    [string]$FileMappingFile,

    [Parameter()]
    [string]$TenantName = "deltacrown",

    [Parameter()]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter()]
    [switch]$SkipPreCheck,

    [Parameter()]
    [switch]$SkipGroupVerification,

    [Parameter()]
    [switch]$VerifyAfterCopy
)

# ============================================================================
# MODULE IMPORTS
# ============================================================================

$modulesPath = Join-Path $PSScriptRoot "..\..\phase2-week1\modules"
Import-Module (Join-Path $modulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$scriptsPath = $PSScriptRoot

# ============================================================================
# PRE-CHECK: Verify Phase 2+3 are deployed
# ============================================================================

if (-not $SkipPreCheck) {
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
    Write-DeltaCrownLog "  PRE-CHECK: Verifying Phase 2+3 Deployment" "STAGE"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"

    try {
        Import-Module (Join-Path $modulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
        $authConfig = Import-DeltaCrownAuthConfig -Environment $Environment
        $adminUrl = "https://${TenantName}-admin.sharepoint.com"
        Connect-DeltaCrownSharePoint -Url $adminUrl -AuthConfig $authConfig

        # Check Corp Hub exists
        $corpHub = Get-PnPTenantSite -Url "https://${TenantName}.sharepoint.com/sites/corp-hub" -ErrorAction SilentlyContinue
        if (-not $corpHub) {
            Write-DeltaCrownLog "❌ Corp Hub not found — Phase 2 not deployed" "CRITICAL"
            Write-DeltaCrownLog "   Run Phase 2 first: phase2-week1/scripts/2.0-Master-Provisioning.ps1" "INFO"
            exit 2
        }
        Write-DeltaCrownLog "  ✅ Corp Hub exists" "SUCCESS"

        # Check DCE Hub exists
        $dceHub = Get-PnPTenantSite -Url "https://${TenantName}.sharepoint.com/sites/dce-hub" -ErrorAction SilentlyContinue
        if (-not $dceHub) {
            Write-DeltaCrownLog "❌ DCE Hub not found — Phase 2 not deployed" "CRITICAL"
            exit 2
        }
        Write-DeltaCrownLog "  ✅ DCE Hub exists" "SUCCESS"

        # Check at least one DCE site exists (Phase 3)
        $dceOps = Get-PnPTenantSite -Url "https://${TenantName}.sharepoint.com/sites/dce-operations" -ErrorAction SilentlyContinue
        if (-not $dceOps) {
            Write-DeltaCrownLog "❌ DCE-Operations not found — Phase 3 not deployed" "CRITICAL"
            Write-DeltaCrownLog "   Run Phase 3 first: phase3-week2/scripts/3.0-Master-Phase3.ps1" "INFO"
            exit 2
        }
        Write-DeltaCrownLog "  ✅ DCE-Operations exists" "SUCCESS"

        Write-DeltaCrownLog "  ✅ Pre-check passed — Phase 2+3 are deployed" "SUCCESS"
    }
    catch {
        Write-DeltaCrownLog "Pre-check failed: $_" "ERROR" -Exception $_.Exception
        Write-DeltaCrownLog "Use -SkipPreCheck to bypass (not recommended)" "WARNING"
        exit 2
    }
}

# ============================================================================
# PHASE 4 EXECUTION
# ============================================================================

$startTime = Get-Date
$stepResults = @{}

Write-DeltaCrownLog "" "INFO"
Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
Write-DeltaCrownLog "  PHASE 4: MIGRATION & USER ONBOARDING" "STAGE"
Write-DeltaCrownLog "  Tenant: $TenantName | Environment: $Environment" "STAGE"
Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"

# Step 4.1: User Audit
if ($Phase -in @("All", "Audit")) {
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "STEP 4.1: User Property Audit" "STAGE"
    Write-DeltaCrownLog "─────────────────────────────────" "INFO"

    $auditArgs = @{
        TenantName  = $TenantName
        Environment = $Environment
        ExportCsv   = $true
    }

    try {
        & (Join-Path $scriptsPath "4.1-User-Property-Audit.ps1") @auditArgs
        $stepResults["4.1-Audit"] = "Success"
        Write-DeltaCrownLog "Step 4.1 completed" "SUCCESS"
    }
    catch {
        $stepResults["4.1-Audit"] = "Failed: $_"
        Write-DeltaCrownLog "Step 4.1 failed: $_" "ERROR" -Exception $_.Exception
        if ($Phase -eq "Audit") { exit 1 }
    }
}

# Step 4.2: User Onboarding
if ($Phase -in @("All", "Users")) {
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "STEP 4.2: User Onboarding" "STAGE"
    Write-DeltaCrownLog "─────────────────────────────────" "INFO"

    if (-not $UserMappingFile) {
        $defaultMapping = Join-Path $PSScriptRoot "..\config\dce-user-mapping.csv"
        if (Test-Path $defaultMapping) {
            $UserMappingFile = $defaultMapping
            Write-DeltaCrownLog "Using default mapping: $UserMappingFile" "INFO"
        }
        else {
            Write-DeltaCrownLog "No user mapping file provided. Skipping step 4.2." "WARNING"
            Write-DeltaCrownLog "Create config/dce-user-mapping.csv or use -UserMappingFile" "INFO"
            $stepResults["4.2-Onboarding"] = "Skipped"
        }
    }

    if ($UserMappingFile) {
        $onboardArgs = @{
            MappingFile    = $UserMappingFile
            TenantName     = $TenantName
            Environment    = $Environment
        }
        if ($SkipGroupVerification) { $onboardArgs["SkipGroupVerification"] = $true }
        if ($WhatIfPreference) { $onboardArgs["WhatIf"] = $true }

        try {
            & (Join-Path $scriptsPath "4.2-User-Onboarding.ps1") @onboardArgs
            $stepResults["4.2-Onboarding"] = "Success"
            Write-DeltaCrownLog "Step 4.2 completed" "SUCCESS"
        }
        catch {
            $stepResults["4.2-Onboarding"] = "Failed: $_"
            Write-DeltaCrownLog "Step 4.2 failed: $_" "ERROR" -Exception $_.Exception
        }
    }
}

# Step 4.3: Document Migration
if ($Phase -in @("All", "Documents")) {
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "STEP 4.3: Document Migration" "STAGE"
    Write-DeltaCrownLog "─────────────────────────────────" "INFO"

    if (-not $FileMappingFile) {
        $defaultMapping = Join-Path $PSScriptRoot "..\config\dce-file-mapping.csv"
        if (Test-Path $defaultMapping) {
            $FileMappingFile = $defaultMapping
            Write-DeltaCrownLog "Using default mapping: $FileMappingFile" "INFO"
        }
        else {
            Write-DeltaCrownLog "No file mapping provided. Skipping step 4.3." "WARNING"
            Write-DeltaCrownLog "Create config/dce-file-mapping.csv or use -FileMappingFile" "INFO"
            $stepResults["4.3-Migration"] = "Skipped"
        }
    }

    if ($FileMappingFile) {
        $migrationArgs = @{
            MappingFile     = $FileMappingFile
            Environment     = $Environment
        }
        if ($VerifyAfterCopy) { $migrationArgs["VerifyAfterCopy"] = $true }
        if ($WhatIfPreference) { $migrationArgs["WhatIf"] = $true }

        try {
            & (Join-Path $scriptsPath "4.3-Document-Migration.ps1") @migrationArgs
            $stepResults["4.3-Migration"] = "Success"
            Write-DeltaCrownLog "Step 4.3 completed" "SUCCESS"
        }
        catch {
            $stepResults["4.3-Migration"] = "Failed: $_"
            Write-DeltaCrownLog "Step 4.3 failed: $_" "ERROR" -Exception $_.Exception
        }
    }
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

$duration = (Get-Date) - $startTime

Write-DeltaCrownLog "" "INFO"
Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
Write-DeltaCrownLog "  PHASE 4 SUMMARY" "STAGE"
Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
Write-DeltaCrownLog "  Duration: $([math]::Round($duration.TotalMinutes, 1)) minutes" "INFO"

foreach ($step in $stepResults.GetEnumerator() | Sort-Object Key) {
    $icon = if ($step.Value -eq "Success") { "✅" } elseif ($step.Value -eq "Skipped") { "⏭️" } else { "❌" }
    $level = if ($step.Value -match "^Failed") { "ERROR" } else { "INFO" }
    Write-DeltaCrownLog "  $icon $($step.Key): $($step.Value)" $level
}

Write-DeltaCrownLog "" "INFO"
Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"

# Exit code
$failures = ($stepResults.Values | Where-Object { $_ -match "^Failed" }).Count
if ($failures -gt 0) { exit 1 }
exit 0
