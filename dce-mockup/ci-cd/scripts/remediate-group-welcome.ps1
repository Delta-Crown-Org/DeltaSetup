# ============================================================================
# remediate-group-welcome.ps1
# ADR-011 — disable Unified Group welcome mail tenant-wide
# ============================================================================
# VERSION: 1.0.0 (initial; mockup — migrates to dce-sharepoint repo)
# AUTHOR:  code-puppy-1bc20e for DeltaSetup-17i; STRIDE co-sign by
#          release-gate-arbiter-bc138a (bootstrap Step 9 backup addendum)
# REF:     docs/sharepoint-pnp-spec/decisions/011-notification-suppression-by-default.md
#          docs/sharepoint-pnp-spec/NOTIFICATION-SUPPRESSION-PLAYBOOK.md §3.1
# ============================================================================
#
# What this does
#   Scans every Microsoft 365 Group in the DCE tenant and ensures
#   UnifiedGroupWelcomeMessageEnabled is $false on each. This is the
#   tenant-wide complement to the per-creation -ResourceBehaviorOptions
#   WelcomeEmailDisabled guard, defending against:
#     - Groups created by hand outside the pipeline (drift)
#     - Groups whose ResourceBehaviorOptions setting was reverted
#     - Future groups created before the per-creation guard fires
#
# Modes (ADR-011 invariant)
#   -Mode scaffold (DEFAULT): READ-ONLY. Enumerate groups, capture
#       pre-image to out/welcome-mail-preimage-<runid>.json, log what
#       WOULD change in -Mode launch. No mutations.
#   -Mode launch: Actually disable welcome mail on every group whose
#       current state has it enabled. Pre-image AND post-image written.
#       Companion script restore-group-welcome.ps1 can roll back any
#       group from the pre-image.
#
# Authentication
#   Uses the cert-based Exchange Online connection established by the
#   dce-sharepoint-deploy app reg (ADR-007). Requires Exchange.ManageAsApp
#   role assignment on the SP (NOT a Graph permission).
#
# Exit codes
#   0  scaffold mode complete OR launch mode succeeded with zero failures
#   1  toolchain / auth / connectivity failure
#   2  launch mode completed with at least one per-group failure
#      (preimage is intact; use restore-group-welcome.ps1 if needed)
# ============================================================================

#Requires -Version 7.2
#Requires -Modules @{ ModuleName='ExchangeOnlineManagement'; ModuleVersion='3.4.0' }

[CmdletBinding()]
param(
    # ADR-011 §2.1: every provisioning script declares -Mode with scaffold default.
    [ValidateSet('scaffold', 'launch')]
    [string]$Mode = 'scaffold',

    # Cert + app-reg parameters. Defaulted from env vars set by bootstrap.sh
    # step 8 output / GitHub Actions secrets. Override for local testing.
    [string]$AppId = $env:DCE_DEPLOY_CLIENT_ID,
    [string]$Organization = $env:DCE_TENANT_DOMAIN,
    [string]$CertificateThumbprint = $env:DCE_DEPLOY_CERT_THUMBPRINT,

    # Where to write the pre-image / post-image JSON. Defaults to a path
    # GitHub Actions can capture as an artifact.
    [string]$OutputDir = 'out',

    # A run identifier — defaults to GitHub Actions GITHUB_RUN_ID, falls
    # back to a timestamp for local invocations.
    [string]$RunId = $(if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { Get-Date -Format 'yyyyMMdd-HHmmss' })
)

$ErrorActionPreference = 'Stop'
$startedAt = Get-Date

# ----------------------------------------------------------------------------
# ADR-011 §2.2: audit log line at startup. This single line is the
# system-of-record claim ("we ran in mode X at commit Y in run Z") and
# must always be the first stdout line.
# ----------------------------------------------------------------------------
$commitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA.Substring(0, 7) } else { 'local' }
$auditLine = "PROVISIONING-MODE: $Mode COMMIT=$commitSha RUN=$RunId SCRIPT=remediate-group-welcome.ps1"
Write-Host $auditLine
"$auditLine`n" | Out-File -FilePath (Join-Path $OutputDir 'provisioning-mode.log') -Append -Encoding utf8

# ----------------------------------------------------------------------------
# Pre-flight checks
# ----------------------------------------------------------------------------
if (-not $AppId)                 { throw "AppId is required (set DCE_DEPLOY_CLIENT_ID env var)." }
if (-not $Organization)          { throw "Organization is required (set DCE_TENANT_DOMAIN env var)." }
if (-not $CertificateThumbprint) { throw "CertificateThumbprint is required (set DCE_DEPLOY_CERT_THUMBPRINT env var)." }

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

# ----------------------------------------------------------------------------
# Connect to Exchange Online with app-only cert auth (ADR-007)
# ----------------------------------------------------------------------------
Write-Host "Connecting to Exchange Online as app=$AppId, org=$Organization..."
Connect-ExchangeOnline `
    -AppId $AppId `
    -CertificateThumbprint $CertificateThumbprint `
    -Organization $Organization `
    -ShowBanner:$false | Out-Null

# ----------------------------------------------------------------------------
# Enumerate every Unified Group. Capture pre-image.
# ----------------------------------------------------------------------------
Write-Host "Enumerating Unified Groups (this is a tenant-wide scan)..."
$groups = Get-UnifiedGroup -ResultSize Unlimited |
    Select-Object Identity, DisplayName, PrimarySmtpAddress, WhenCreated, UnifiedGroupWelcomeMessageEnabled

Write-Host "  Found $($groups.Count) groups."

# ADR-011 STRIDE supplemental threat: bootstrap Step 9 tenant-wide write
# without backup. Always write the pre-image, regardless of mode.
$preImagePath = Join-Path $OutputDir "welcome-mail-preimage-$RunId.json"
$preImage = $groups | ForEach-Object {
    [pscustomobject]@{
        Identity                          = $_.Identity
        DisplayName                       = $_.DisplayName
        PrimarySmtpAddress                = $_.PrimarySmtpAddress.ToString()
        WhenCreated                       = $_.WhenCreated.ToString('o')
        UnifiedGroupWelcomeMessageEnabled = [bool]$_.UnifiedGroupWelcomeMessageEnabled
        CapturedAt                        = $startedAt.ToString('o')
        RunId                             = $RunId
        CommitSha                         = $commitSha
    }
}
$preImage | ConvertTo-Json -Depth 4 | Out-File -FilePath $preImagePath -Encoding utf8
Write-Host "  Pre-image written: $preImagePath"

# Slice to "groups that currently have welcome enabled" — the candidates
# for remediation.
$candidates = $preImage | Where-Object { $_.UnifiedGroupWelcomeMessageEnabled }
Write-Host "  Candidates for remediation (welcome=enabled): $($candidates.Count) / $($groups.Count)"

# ----------------------------------------------------------------------------
# Scaffold mode: report and exit. NO mutations.
# ----------------------------------------------------------------------------
if ($Mode -eq 'scaffold') {
    Write-Host ""
    Write-Host "SCAFFOLD MODE — no changes applied."
    Write-Host "Would disable welcome mail on $($candidates.Count) groups in -Mode launch."
    if ($candidates.Count -gt 0) {
        $sample = $candidates | Select-Object -First 5 | Format-Table DisplayName, PrimarySmtpAddress -AutoSize | Out-String
        Write-Host "  Sample (first 5):"
        Write-Host $sample
    }
    Write-Host ""
    Write-Host "To remediate: re-run with -Mode launch. Pre-image at $preImagePath."
    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    exit 0
}

# ----------------------------------------------------------------------------
# Launch mode: actually disable welcome mail on each candidate.
# ----------------------------------------------------------------------------
Write-Host ""
Write-Host "LAUNCH MODE — applying remediation to $($candidates.Count) groups."

$failures = @()
$successes = @()
$i = 0
foreach ($g in $candidates) {
    $i++
    Write-Host ("  [$i/$($candidates.Count)] $($g.DisplayName) <$($g.PrimarySmtpAddress)>") -NoNewline
    try {
        # NOTE: -RequireSenderAuthenticationEnabled is intentionally NOT touched.
        # This script's job is welcome-mail suppression only; other Exchange-side
        # settings are owned by ADR-004 (permissions) and ADR-011 STRIDE row
        # Information Disclosure §scoped caveat.
        Set-UnifiedGroup -Identity $g.Identity -UnifiedGroupWelcomeMessageEnabled:$false -ErrorAction Stop
        $successes += $g.Identity
        Write-Host " ✓" -ForegroundColor Green
    }
    catch {
        $failures += [pscustomobject]@{
            Identity = $g.Identity
            DisplayName = $g.DisplayName
            Error = $_.Exception.Message
        }
        Write-Host " ✗" -ForegroundColor Red
        Write-Host "      $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ----------------------------------------------------------------------------
# Post-image: re-enumerate to verify state and capture for audit.
# ----------------------------------------------------------------------------
Write-Host ""
Write-Host "Re-enumerating to capture post-image..."
$postImage = Get-UnifiedGroup -ResultSize Unlimited |
    Select-Object @{N='Identity';E={$_.Identity}},
                  @{N='DisplayName';E={$_.DisplayName}},
                  @{N='PrimarySmtpAddress';E={$_.PrimarySmtpAddress.ToString()}},
                  @{N='UnifiedGroupWelcomeMessageEnabled';E={[bool]$_.UnifiedGroupWelcomeMessageEnabled}}

$stillEnabled = $postImage | Where-Object { $_.UnifiedGroupWelcomeMessageEnabled }

$postImagePath = Join-Path $OutputDir "welcome-mail-postimage-$RunId.json"
@{
    StartedAt = $startedAt.ToString('o')
    CompletedAt = (Get-Date).ToString('o')
    RunId = $RunId
    CommitSha = $commitSha
    Mode = $Mode
    GroupsTotal = $postImage.Count
    SuccessCount = $successes.Count
    FailureCount = $failures.Count
    StillEnabledAfterRun = $stillEnabled.Count
    Failures = $failures
    PreImagePath = $preImagePath
} | ConvertTo-Json -Depth 4 | Out-File -FilePath $postImagePath -Encoding utf8
Write-Host "  Post-image written: $postImagePath"

# ----------------------------------------------------------------------------
# Summary + exit
# ----------------------------------------------------------------------------
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "  Total groups scanned: $($postImage.Count)"
Write-Host "  Remediated (success): $($successes.Count)"
Write-Host "  Failed:               $($failures.Count)"
Write-Host "  Still enabled:        $($stillEnabled.Count)  (acceptance: must be 0)"
Write-Host ""
Write-Host "Pre-image:  $preImagePath"
Write-Host "Post-image: $postImagePath"
Write-Host ""

if ($failures.Count -gt 0) {
    Write-Host "EXIT 2 — at least one group failed remediation. Pre-image intact." -ForegroundColor Yellow
    Write-Host "Use restore-group-welcome.ps1 to roll back if needed." -ForegroundColor Yellow
    exit 2
}

if ($stillEnabled.Count -gt 0) {
    Write-Host "EXIT 2 — race condition: $($stillEnabled.Count) groups still have welcome enabled." -ForegroundColor Yellow
    Write-Host "Likely a group was created between pre-image and post-image. Re-run to converge." -ForegroundColor Yellow
    exit 2
}

Write-Host "EXIT 0 — all groups remediated successfully." -ForegroundColor Green
exit 0
