# ============================================================================
# PHASE 3.4: DLP Policy Creation
# Delta Crown Extensions — Data Loss Prevention Policies
# ============================================================================
# VERSION: 1.0.0
# DESCRIPTION: Creates 3 DLP policies for Phase 3 brand isolation.
#              30-day test mode per Security Auditor condition SEC-002-1.
# DEPENDS ON: 3.3 (security hardening complete, sites hub-associated)
# ADR: ADR-002 Phase 3 — DLP Policy Coverage
# SEC: SECURITY-COSIGN-ADR002.md — SEC-002-1 (30-day test period)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="ExchangeOnlineManagement";ModuleVersion="3.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    [Parameter(Mandatory=$false)]
    [int]$TestPeriodDays = 30  # SEC-002-1: Reduced from 90 to 30
)

$ErrorActionPreference = "Stop"
$scriptVersion = "1.0.0"

$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot "phase2-week1\modules"
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$LogPath = Join-Path $ProjectRoot "phase3-week2\logs"
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.4-DLP-Policies-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# DLP POLICY DEFINITIONS (3 of 10 budget)
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
                Name = "Block-Cross-Brand-Access"
                Description = "Block DCE content sharing with non-DCE recipients"
                BlockAccess = $true
                Severity = "High"
                PolicyTip = "This content is restricted to Delta Crown Extensions staff only."
            },
            @{
                Name = "Warn-External-Sharing"
                Description = "Warn users when sharing DCE content externally"
                BlockAccess = $false
                Severity = "Medium"
                PolicyTip = "WARNING: You are sharing Delta Crown Extensions content externally."
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
                Name = "Block-External-Corp-Sharing"
                Description = "Block external sharing of Corporate-Confidential content"
                BlockAccess = $true
                Severity = "High"
                PolicyTip = "Corporate confidential content cannot be shared externally."
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
                Name = "Block-Anonymous-Links"
                Description = "Block creation of anonymous sharing links"
                BlockAccess = $true
                Severity = "High"
                PolicyTip = "Anonymous sharing links are not permitted."
            },
            @{
                Name = "Block-Personal-Email-Sharing"
                Description = "Block sharing with personal email domains"
                BlockAccess = $true
                Severity = "Medium"
                PolicyTip = "Sharing with personal email addresses is not permitted."
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

    # Connect to Security & Compliance Center
    Write-DeltaCrownLog "Connecting to Security & Compliance Center..." "INFO"
    Connect-IPPSSession -ShowBanner:$false
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

                # Create rules for this policy
                foreach ($rule in $policy.Rules) {
                    $ruleParams = @{
                        Name       = $rule.Name
                        Policy     = $policy.Name
                        BlockAccess = $rule.BlockAccess
                        NotifyUser  = "SiteAdmin"
                        GenerateAlert = "SiteAdmin"
                    }

                    New-DlpComplianceRule @ruleParams
                    Write-DeltaCrownLog "    Created rule: $($rule.Name) (Block: $($rule.BlockAccess))" "SUCCESS"
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

    $resultsPath = Join-Path $ProjectRoot "phase3-week2\docs\3.4-dlp-results.json"
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
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
}
