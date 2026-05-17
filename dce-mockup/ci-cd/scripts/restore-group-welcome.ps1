# ============================================================================
# restore-group-welcome.ps1
# ADR-011 — companion rollback for remediate-group-welcome.ps1
# ============================================================================
# VERSION: 1.0.0
# AUTHOR:  code-puppy-1bc20e for DeltaSetup-17i; STRIDE co-sign by
#          release-gate-arbiter-bc138a (bootstrap Step 9 backup addendum)
# REF:     docs/sharepoint-pnp-spec/decisions/011-notification-suppression-by-default.md
# ============================================================================
#
# What this does
#   Given a pre-image JSON file written by remediate-group-welcome.ps1,
#   restore the UnifiedGroupWelcomeMessageEnabled state for one group,
#   a list of groups, or every group in the file.
#
# Why this exists
#   STRIDE supplemental threat #3 (bootstrap Step 9 tenant-wide write
#   without backup). The remediate script writes pre-image; this script
#   honors it. Without this companion, an operator dispute has no
#   rollback path.
#
# Modes (ADR-011 invariant — even rollback obeys mode discipline)
#   -Mode scaffold (DEFAULT): show what WOULD be restored. No mutations.
#   -Mode launch:             actually restore.
#
# Typical invocation
#   # Roll back all groups from a specific run
#   ./restore-group-welcome.ps1 -PreImagePath out/welcome-mail-preimage-12345.json -Mode launch
#
#   # Roll back ONE group only (preferred — surgical)
#   ./restore-group-welcome.ps1 -PreImagePath out/welcome-mail-preimage-12345.json \
#       -Identity "Crown Connection" -Mode launch
# ============================================================================

#Requires -Version 7.2
#Requires -Modules @{ ModuleName='ExchangeOnlineManagement'; ModuleVersion='3.4.0' }

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$PreImagePath,

    # Optional: restore only this group (by Identity / DisplayName / SMTP).
    # If omitted, restore EVERY group in the pre-image. Surgical mode is
    # safer — prefer naming the specific group whenever possible.
    [string]$Identity,

    [ValidateSet('scaffold', 'launch')]
    [string]$Mode = 'scaffold',

    [string]$AppId = $env:DCE_DEPLOY_CLIENT_ID,
    [string]$Organization = $env:DCE_TENANT_DOMAIN,
    [string]$CertificateThumbprint = $env:DCE_DEPLOY_CERT_THUMBPRINT,

    [string]$OutputDir = 'out',
    [string]$RunId = $(if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { Get-Date -Format 'yyyyMMdd-HHmmss' })
)

$ErrorActionPreference = 'Stop'

# ADR-011 §2.2 audit log
$commitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA.Substring(0, 7) } else { 'local' }
$auditLine = "PROVISIONING-MODE: $Mode COMMIT=$commitSha RUN=$RunId SCRIPT=restore-group-welcome.ps1 PRE_IMAGE=$PreImagePath"
Write-Host $auditLine
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
"$auditLine`n" | Out-File -FilePath (Join-Path $OutputDir 'provisioning-mode.log') -Append -Encoding utf8

# Pre-flight
if (-not (Test-Path $PreImagePath)) { throw "Pre-image not found: $PreImagePath" }
if (-not $AppId)                    { throw "AppId is required (set DCE_DEPLOY_CLIENT_ID env var)." }
if (-not $Organization)             { throw "Organization is required (set DCE_TENANT_DOMAIN env var)." }
if (-not $CertificateThumbprint)    { throw "CertificateThumbprint is required." }

# Load pre-image
$preImage = Get-Content $PreImagePath -Raw | ConvertFrom-Json
Write-Host "Pre-image loaded: $($preImage.Count) groups from run $($preImage[0].RunId), captured $($preImage[0].CapturedAt)"

# Filter to candidates
$candidates = if ($Identity) {
    $preImage | Where-Object {
        $_.Identity -eq $Identity -or
        $_.DisplayName -eq $Identity -or
        $_.PrimarySmtpAddress -eq $Identity
    }
} else {
    # Restore EVERY group's pre-image state (re-enabling welcome mail
    # where it was enabled, leaving alone groups that were already
    # disabled in the pre-image).
    $preImage | Where-Object { $_.UnifiedGroupWelcomeMessageEnabled }
}

if ($candidates.Count -eq 0) {
    Write-Host "No matching candidates in pre-image. Nothing to restore."
    if ($Identity) { Write-Host "  (Filter: -Identity '$Identity' matched 0 entries)" }
    exit 0
}

Write-Host "Candidates to restore: $($candidates.Count)"
$candidates | Format-Table DisplayName, PrimarySmtpAddress, UnifiedGroupWelcomeMessageEnabled -AutoSize | Out-String | Write-Host

if ($Mode -eq 'scaffold') {
    Write-Host "SCAFFOLD MODE — no changes applied. Re-run with -Mode launch to restore."
    exit 0
}

# Launch mode: actually restore
Connect-ExchangeOnline -AppId $AppId -CertificateThumbprint $CertificateThumbprint `
    -Organization $Organization -ShowBanner:$false | Out-Null

$failures = @()
$successes = @()
$i = 0
foreach ($g in $candidates) {
    $i++
    Write-Host ("  [$i/$($candidates.Count)] Restore $($g.DisplayName) → welcome=$($g.UnifiedGroupWelcomeMessageEnabled)") -NoNewline
    try {
        Set-UnifiedGroup -Identity $g.Identity `
            -UnifiedGroupWelcomeMessageEnabled:([bool]$g.UnifiedGroupWelcomeMessageEnabled) `
            -ErrorAction Stop
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

# Restore-image record
$restoreLogPath = Join-Path $OutputDir "welcome-mail-restore-$RunId.json"
@{
    PreImagePath = $PreImagePath
    RestoredAt = (Get-Date).ToString('o')
    RunId = $RunId
    CommitSha = $commitSha
    IdentityFilter = $Identity
    Successes = $successes
    Failures = $failures
} | ConvertTo-Json -Depth 4 | Out-File -FilePath $restoreLogPath -Encoding utf8

Disconnect-ExchangeOnline -Confirm:$false | Out-Null

Write-Host ""
Write-Host "Restored: $($successes.Count); Failed: $($failures.Count); Log: $restoreLogPath"
exit $(if ($failures.Count -gt 0) { 2 } else { 0 })
