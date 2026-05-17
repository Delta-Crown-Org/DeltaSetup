# ADR-009 — Teams channel moderation runs against the Graph BETA endpoint

**Status:** Proposed (2026-05-16)
**Author:** Surfaced from solutions-architect-e9372f ADR-006 final + `dce-mockup/RESEARCH-DELTAS.md` § 1.1
**Supersedes:** none
**Superseded by:** none

---

## Context

The DCE design requires per-channel moderation on the Crown Connection
Team (and downstream brand teams in Phase 5+). Specifically:

- General channel: `userNewMessageRestriction = moderators` (only owners
  can start posts; everyone can reply).
- Operations / Ops-Daily: `userNewMessageRestriction = everyoneExceptGuests`.
- Leadership (private): `replyRestriction = authorAndModerators`,
  bots/connectors disabled.

The spec pack's `06-tooling-pnp.md` and `09-deployment.md` reference
Microsoft Graph PATCH on `/teams/{id}/channels/{id}` with
`moderationSettings` as the implementation path.

## Decision

The implementation calls **Graph BETA** specifically:

```
PATCH https://graph.microsoft.com/beta/teams/{team-id}/channels/{channel-id}
```

NOT v1.0.

## Research basis (verified 2026-05-16)

| Surface | Moderation support |
|---|---|
| Graph v1.0 `PATCH /teams/{id}/channels/{id}` | **Silently ignores** `moderationSettings` |
| Graph beta `PATCH /teams/{id}/channels/{id}` | Full support |
| Teams PowerShell v7.7.0 (April 2026) | **Zero** moderation parameters |
| `@microsoft/teams-js` SDK v2.53.0 | Client-side only; no moderation API |
| Teams admin center UI | Supported manually per channel |

Sources:
- https://learn.microsoft.com/graph/api/channel-patch?view=graph-rest-beta
- https://learn.microsoft.com/graph/api/resources/channelmoderationsettings
- solutions-architect-e9372f ADR-006 final, 2026-05-16

## Alternatives considered

### 1. Wait for v1.0 GA before automating

Rejected. The mockup demonstrates moderation as a first-class capability;
deferring it leaves the production rollout dependent on manual Teams
admin clicks per channel. The Heft / SPFx team's pattern (use beta with
a migration monitor) is the lesser evil.

### 2. Use Teams admin center UI only

Rejected. We have 5 channels in v1 and an expected 20+ in Phase 5
(per-brand × per-channel). Manual config is error-prone and unaudited.

### 3. Wrap a third-party tool

Rejected. The only mature wrapper of channelModerationSettings is the
PnP community CLI, which itself calls Graph beta. No layer added.

## Implementation

`ci-cd/scripts/provision-teams.ps1` calls `/beta`. `ci-cd/teams/dce-channels.json`
has a top-level `_meta._CRITICAL_BETA_ONLY_2026_05` key that documents
the constraint.

The fitness function `tests/architecture/test_audience_targeting.py`
class `TestTeamsModerationBetaOnly` enforces:

1. `provision-teams.ps1` contains `/beta/teams/`.
2. `provision-teams.ps1` does NOT contain a non-comment line with
   `PATCH /v1.0/teams/`.
3. `dce-channels.json _meta` documents the BETA-only constraint.

All three tests currently pass.

## Migration plan

When Microsoft promotes `moderationSettings` to Graph v1.0:

1. Monitor https://developer.microsoft.com/graph/changelog (recommended:
   subscribe to RSS).
2. When the promotion lands, update one line in
   `ci-cd/scripts/provision-teams.ps1` (`/beta/` → `/v1.0/`) and one
   line in the .SYNOPSIS comment.
3. Update this ADR's status to **Superseded by ADR-XXX** referencing the
   v1.0 cutover ADR.
4. Update fitness test `test_provision_teams_uses_beta_endpoint` to
   `test_provision_teams_uses_v1_endpoint` and invert the regex.

## Risk

Microsoft beta endpoints carry the documented disclaimer "APIs under the
/beta version in Microsoft Graph are subject to change." Realistic
failure modes:

- **Schema change.** `moderationSettings` adds a new required field. PATCH
  starts returning 400. Mitigation: the fitness test catches this in CI
  if the response is validated.
- **Endpoint deprecation.** Microsoft removes beta entirely before v1.0
  promotion. Mitigation: monitor the changelog; fall back to Teams admin
  center UI per channel as documented in `10-runbooks.md`.
- **Token scope change.** Beta endpoints may require additional scopes.
  Mitigation: app registration grants `ChannelSettings.ReadWrite.All`
  (application), which is the documented scope for both v1.0 and beta.

## Acceptance criteria

- All channels in `ci-cd/teams/dce-channels.json` have their
  `moderationSettings` applied by the workflow.
- A post-deploy verification call (`GET` the same channel, compare
  `moderationSettings`) returns the expected values.
- The post-deploy Teams notification states "moderation applied via
  /beta — pending v1.0 promotion monitor."
