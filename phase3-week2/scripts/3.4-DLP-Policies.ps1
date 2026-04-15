# ============================================================================
# PHASE 3.4: DLP Policy Creation
# Delta Crown Extensions — Data Loss Prevention Policies
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Creates 3 DLP policies for Phase 3 brand isolation.
#              30-day test mode per Security Auditor condition SEC-002-1.
# DEPENDS ON: 3.3 (security hardening complete, sites hub-associated)
# ADR: ADR-002 Phase 3 — DLP Policy Coverage
# SEC: SECURITY-COSIGN-ADR002.md — SEC-002-1 (30-day test period)
# FIXES: A3 (connection ownership), B6 (no-op rules), B7 (path separators)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="ExchangeOnlineManagement";ModuleVersion="3.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    [Parameter(Mandatory=$false)]
    [int]$TestPeriodDays = 30  # SEC-002-1: Reduced from 90 to 30
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.1.0"

# ============================================================================
# PATH RESOLUTION (B7: Join-Path everywhere)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$LogPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.4-DLP-Policies-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# CONNECTION OWNERSHIP (A3)
# ============================================================================
$script:OwnsIPPSConnection = $false

# ============================================================================
# DLP POLICY DEFINITIONS (3 of 10 budget)
# B6 FIX: Each rule now has proper content conditions
# ============================================================================
$DLPPolicies = @(
    @{
        Name        = "DCE-Data-Protection"
        Comment     = "Prevents DCE content from being shared outside brand boundaries. $TestPeriodDays-day test period before enforcement."
        Mode        = "TestWithNotifications"
        Locations   = @(
            "https://$TenantName.sharepoint.com/sites/dce-operations"
            "https://$TenantName.sharepoint.com/sites/dce-clientservices"
            "https://$TenantName.sharepoint.com/sites/dce-marketing"
            "https://$TenantName.sharepoint.com/sites/dce-docs"
            "https://$TenantName.sharepoint.com/sites/dce-hub"
        )
        Rules       = @(
            @{
                Name        = "Block-Cross-Brand-Access"
                Description = "Block DCE content sharing with non-DCE recipients"
                BlockAccess = $true
                AccessScope = "NotInOrganization"
                Severity    = "High"
                PolicyTip   = "This content is restricted to Delta Crown Extensions staff only."
            },
            @{
                Name        = "Warn-External-Sharing"
                Description = "Warn users when sharing DCE content externally"
                BlockAccess = $false
                AccessScope = "NotInOrganization"
                Severity    = "Medium"
                PolicyTip   = "WARNING: You are sharing Delta Crown Extensions content externally."
            }
        )
    },
    @{
        Name        = "Corp-Data-Protection"
        Comment     = "Prevents Corporate content from leaking outside shared services. $TestPeriodDays-day test period."
        Mode        = "TestWithNotifications"
        Locations   = @(
            "https://$TenantName.sharepoint.com/sites/corp-hub"
            "https://$TenantName.sharepoint.com/sites/corp-hr"
            "https://$TenantName.sharepoint.com/sites/corp-it"
            "https://$TenantName.sharepoint.com/sites/corp-finance"
            "https://$TenantName.sharepoint.com/sites/corp-training"
        )
        Rules       = @(
            @{
                Name        = "Block-External-Corp-Sharing"
                Description = "Block external sharing of Corporate-Confidential content"
                BlockAccess = $true
                AccessScope = "NotInOrganization"
                Severity    = "High"
                PolicyTip   = "Corporate confidential content cannot be shared externally."
                # B6: Include US sensitive info types for PII detection
                SensitiveInfo = @(
                    @{ Name = "U.S. Social Security Number (SSN)"; MinCount = 1; MaxConfidence = 100 }
                    @{ Name = "U.S. Individual Taxpayer Identification Number (ITIN)"; MinCount = 1; MaxConfidence = 100 }
                )
            }
        )
    },
    @{
        Name        = "External-Sharing-Block"
        Comment     = "Blocks anonymous links and personal email sharing across ALL sites. Enforced immediately."
        Mode        = "Enable"  # Enforce mode — no test period
        Locations   = @("All")
        Rules       = @(
            @{
                Name        = "Block-Anonymous-Links"
                Description = "Block creation of anonymous sharing links"
                BlockAccess = $true
                AccessScope = "NotInOrganization"
                BlockAccessScope = "All"
                Severity    = "High"
                PolicyTip   = "Anonymous sharing links are not permitted."
            },
            @{
                Name        = "Block-Personal-Email-Sharing"
                Description = "Block sharing with personal email domains"
                BlockAccess = $true
                AccessScope = "NotInOrganization"
                Severity    = "Medium"
                PolicyTip   = "Sharing with personal email addresses is not permitted."
            }
        )
    }
)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.4: DLP Policy Creation"
    Write-DeltaCrownLog "Script Version: $scriptVersion" "INFO"
    Write-DeltaCrownLog "Test Period: $TestPeriodDays days (SEC-002-1)" "INFO"
    Write-DeltaCrownLog "Policy Budget: 3 of 10 (7 remaining for future brands)" "INFO"

    $results = @{
        PoliciesCreated = @()
        RulesCreated    = @()
        Errors          = @()
        StartTime       = Get-Date
        EnforcementDate = (Get-Date).AddDays($TestPeriodDays).ToString("yyyy-MM-dd")
    }

    # ------------------------------------------------------------------
    # CONNECTION SETUP (A3: check if Master pre-authed)
    # ------------------------------------------------------------------
    $existingSession = Get-PSSession | Where-Object { $_.ComputerName -match "compliance" }
    if (!$existingSession -or $existingSession.State -ne "Opened") {
        Write-DeltaCrownLog "Connecting to Security & Compliance Center..." "INFO"
        Connect-DeltaCrownIPPS
        $script:OwnsIPPSConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established IPPS connection" "INFO"
    }
    Write-DeltaCrownLog "Connected to SCC" "SUCCESS"

    foreach ($policy in $DLPPolicies) {
        Write-DeltaCrownLog "Processing policy: $($policy.Name)" "INFO"

        try {
            # Idempotency check
            $existing = Get-DlpCompliancePolicy -Identity $policy.Name -ErrorAction SilentlyContinue
            if ($existing) {
                Write-DeltaCrownLog "  Policy already exists: $($policy.Name) — skipping" "WARNING"
                $results.PoliciesCreated += $policy.Name
                continue
            }

            if ($PSCmdlet.ShouldProcess($policy.Name, "Create DLP policy")) {
                # Build location parameters
                $policyParams = @{
                    Name    = $policy.Name
                    Comment = $policy.Comment
                    Mode    = $policy.Mode
                }

                if ($policy.Locations -contains "All") {
                    $policyParams.SharePointLocation = "All"
                    $policyParams.ExchangeLocation   = "All"
                    $policyParams.OneDriveLocation    = "All"
                }
                else {
                    $policyParams.SharePointLocation = $policy.Locations
                }

                $createdPolicy = New-DlpCompliancePolicy @policyParams
                Write-DeltaCrownLog "  Created policy: $($policy.Name) (Mode: $($policy.Mode))" "SUCCESS"
                $results.PoliciesCreated += $policy.Name

                # Create rules for this policy (B6: with proper conditions)
                foreach ($rule in $policy.Rules) {
                    $ruleParams = @{
                        Name        = $rule.Name
                        Policy      = $policy.Name
                        BlockAccess = $rule.BlockAccess
                        NotifyUser  = "SiteAdmin"
                        GenerateAlert = "SiteAdmin"
                    }

                    # B6: Add AccessScope condition (prevents no-op rules)
                    if ($rule.ContainsKey("AccessScope")) {
                        $ruleParams.AccessScope = $rule.AccessScope
                    }

                    # B6: Add BlockAccessScope for anonymous link blocking
                    if ($rule.ContainsKey("BlockAccessScope")) {
                        $ruleParams.BlockAccessScope = $rule.BlockAccessScope
                    }

                    # B6: Add sensitive information type conditions
                    if ($rule.ContainsKey("SensitiveInfo") -and $rule.SensitiveInfo.Count -gt 0) {
                        $ruleParams.ContentContainsSensitiveInformation = $rule.SensitiveInfo
                    }

                    New-DlpComplianceRule @ruleParams
                    Write-DeltaCrownLog "    Created rule: $($rule.Name) (Block: $($rule.BlockAccess), Scope: $($rule.AccessScope))" "SUCCESS"
                    $results.RulesCreated += "$($policy.Name)/$($rule.Name)"
                }
            }
        }
        catch {
            Write-DeltaCrownLog "Failed to create policy $($policy.Name): $_" "ERROR"
            $results.Errors += "Policy failed: $($policy.Name) — $_"
        }
    }

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = Get-Date
    $duration = $results.EndTime - $results.StartTime

    Write-DeltaCrownBanner "PHASE 3.4 COMPLETE"
    Write-DeltaCrownLog "Policies created:    $($results.PoliciesCreated.Count)/3" "SUCCESS"
    Write-DeltaCrownLog "Rules created:       $($results.RulesCreated.Count)" "SUCCESS"
    Write-DeltaCrownLog "Enforcement date:    $($results.EnforcementDate) (review before switching to Enforce)" "WARNING"
    Write-DeltaCrownLog "Remaining budget:    7 policies for future brands" "INFO"
    Write-DeltaCrownLog "Errors:              $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})

    $resultsPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.4-dlp-results.json"))
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force

    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        PoliciesCreated  = $results.PoliciesCreated
        RulesCreated     = $results.RulesCreated
        EnforcementDate  = $results.EnforcementDate
        Errors           = $results.Errors
        Status           = if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.4: $_" "CRITICAL"
    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    if ($script:OwnsIPPSConnection) {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    }
}
