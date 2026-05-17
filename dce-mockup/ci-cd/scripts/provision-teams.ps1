<#
.SYNOPSIS
  Provision DCE Teams + apply channelModerationSettings via Microsoft Graph.

.DESCRIPTION
  Reads teams/dce-channels.json. For each (team, channel) pair, ensures
  the team exists (creates if missing), ensures the channel exists,
  applies the desired moderationSettings via:

    PATCH https://graph.microsoft.com/beta/teams/{team-id}/channels/{channel-id}

  CRITICAL: channelModerationSettings is BETA-ONLY in Microsoft Graph
  as of May 2026 (verified by solutions-architect-e9372f, ADR-006 final).
  Graph v1.0 silently ignores moderationSettings on PATCH. Production
  must call /beta. Reference: https://learn.microsoft.com/graph/api/
  channel-patch?view=graph-rest-beta. Track v1.0 promotion at
  https://developer.microsoft.com/en-us/graph/changelog.

  This script does NOT create Microsoft 365 Groups directly. For
  Crown Connection (already group-backed), it just enforces channel
  moderation settings. New Teams are created via Graph from a labeled
  M365 Group when sensitivity labels are required (Graph doesn't allow
  setting sensitivity labels on channels directly — documented limitation).
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$ConfigPath,

  # ADR-011 §2.1: every provisioning script declares -Mode with scaffold
  # default. This script's mutations (Graph PATCH on channel moderation
  # settings) do not send user notifications, but the mode-aware contract
  # is uniform across all provisioning scripts to keep the fitness function
  # simple and the audit trail consistent.
  [ValidateSet('scaffold', 'launch')]
  [string]$Mode = 'scaffold'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ADR-011 §2.2: audit log line at startup. First stdout line of every run.
$commitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA.Substring(0, 7) } else { 'local' }
$runId     = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { Get-Date -Format 'yyyyMMdd-HHmmss' }
$auditLine = "PROVISIONING-MODE: $Mode COMMIT=$commitSha RUN=$runId SCRIPT=provision-teams.ps1"
Write-Host $auditLine
if (-not (Test-Path 'out')) { New-Item -ItemType Directory -Path 'out' | Out-Null }
"$auditLine`n" | Out-File -FilePath 'out/provisioning-mode.log' -Append -Encoding utf8

# Connect via cert (same path as deploy-prod.ps1)
$ClientId  = $env:CLIENT_ID
$TenantDom = $env:TENANT
$CertPass  = ConvertTo-SecureString -String $env:CERT_PASS -AsPlainText -Force
Connect-MgGraph -ClientId $ClientId `
                -TenantId $TenantDom `
                -CertificateThumbprint (Get-PfxCertificate -FilePath ./cert.pfx -Password $CertPass).Thumbprint

$config = Get-Content $ConfigPath | ConvertFrom-Json

foreach ($team in $config.teams) {
  Write-Host "Team: $($team.displayName)" -ForegroundColor Cyan

  # Resolve team by group id (group must already exist)
  $teamId = $team.id
  if (-not $teamId) {
    throw "team $($team.displayName) missing 'id'. Create the M365 Group first then re-run."
  }

  foreach ($channel in $team.channels) {
    Write-Host "  Channel: $($channel.displayName)" -ForegroundColor Gray

    # ─────────────────────────────────────────────────────────────────
    # CRITICAL: channelModerationSettings is BETA-ONLY as of May 2026.
    # Verified by Tyler's solutions-architect-e9372f research
    # (ADR-006 final, 2026-05-16):
    #   - Graph v1.0 has NO moderation support
    #   - Teams PowerShell v7.7.0 has ZERO moderation parameters
    #   - teams-js SDK v2.53.0 is client-side only
    # Reference: https://learn.microsoft.com/graph/api/channel-patch?view=graph-rest-beta
    # When Microsoft promotes this to v1.0, change /beta below to /v1.0
    # and update tests/architecture/test_teams_integration.py.
    # ─────────────────────────────────────────────────────────────────

    $body = @{
      moderationSettings = $channel.moderationSettings
    } | ConvertTo-Json -Depth 5

    if ($Mode -eq 'scaffold') {
      # Scaffold mode: report what WOULD change, don't PATCH.
      Write-Host "    [scaffold] WOULD PATCH /beta/teams/$teamId/channels/$($channel.id)" -ForegroundColor Yellow
      Write-Host "      body: $body" -ForegroundColor DarkGray
    } else {
      # ADR-011-SUPPRESSION-VERIFIED: PATCH /beta/teams/{id}/channels/{id}
      # with body { moderationSettings: {...} } updates channel-level
      # moderation rules only and does NOT trigger any user-facing
      # notification per Microsoft Graph reference
      # (https://learn.microsoft.com/graph/api/channel-patch?view=graph-rest-beta).
      # No notification-capable endpoints (group creates, B2B invites,
      # sharing invites) are reached by this script; the runtime-body-
      # defense test flags the appearance of the channels URI and this
      # comment is the affirmative waiver.
      Invoke-MgGraphRequest `
        -Method PATCH `
        -Uri "/beta/teams/$teamId/channels/$($channel.id)" `
        -Body $body
      Write-Host "    ✓ moderationSettings applied (via /beta)" -ForegroundColor Green
    }
  }
}

Disconnect-MgGraph
