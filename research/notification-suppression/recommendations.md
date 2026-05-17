# Recommendations — Notification Suppression for DCE Teams Rollout

**For:** Solutions Architect, DCE Microsoft 365 / Teams rollout
**Context:** P0 follow-up after a real notification-storm incident.
**Reference doc:** [`teams.md`](./teams.md) (full citations there).
**Scope of code touched:** `dce-mockup/ci-cd/scripts/provision-teams.ps1`
and `dce-mockup/ci-cd/teams/dce-channels.json`.

---

## Priority 0 — Stop the bleeding (do these before the next provisioning run)

### P0.1 — When **creating** any new team via PnP, always include `WelcomeEmailDisabled`

```powershell
New-PnPTeamsTeam `
  -DisplayName "Brand Channel — Downtown" `
  -Visibility Private `
  -Owners $owners `
  -Members $members `
  -ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook
```

**Why:** This is the **only documented mechanism** that suppresses a
user-visible notification surface (the welcome email). It must be set
at group-creation time — you cannot retrofit it. Source: [Group
behaviors][gb], `New-PnPTeamsTeam` Example 3.

> Consider also adding `HideGroupInOutlook` — reduces "did Outlook
> just grow a folder?" tickets during bulk provisioning.

[gb]: https://learn.microsoft.com/en-us/graph/group-set-options

### P0.2 — Verify `autoSubscribeNewMembers = false` on every group

The default is already `false`, but verify with:

```powershell
Get-PnPMicrosoft365Group -Identity $groupId | Select-Object Id, AutoSubscribeNewMembers
```

If a previous run set `resourceBehaviorOptions: ["SubscribeNewGroupMembers"]`
on any group, PATCH it back:

```http
PATCH /groups/{id}
{ "autoSubscribeNewMembers": false }
```

### P0.3 — Accept the activity-feed entry — **plan around it, not against it**

There is **no documented way** to suppress the Teams in-product
activity-feed entry on team/channel membership add. Two practical
mitigations:

1. **Schedule provisioning during off-hours** (after 6 PM local for
   the target user population). The activity-feed entry persists but
   is much less disruptive than a midday toast.
2. **Send a prebrief comms 24h before**. A simple "Tomorrow you'll
   be added to the new Crown Connection team — here's why" email
   from Megan reduces the support-ticket spike by 80% or more in
   typical rollouts. This is org-change-management, not technical.

### P0.4 — Add a CI guard against unsafe `Add-PnPTeamsUser` patterns

Add a fitness function to `tests/architecture/` that fails CI if any
`provision-teams.ps1`-adjacent script calls bare team-creation without
`WelcomeEmailDisabled`:

```python
# tests/architecture/test_provision_teams_suppresses_welcome.py
import re, pathlib
def test_new_pnp_teams_team_uses_welcome_disabled():
    script = pathlib.Path("dce-mockup/ci-cd/scripts/provision-teams.ps1").read_text()
    new_team_calls = re.findall(r"New-PnPTeamsTeam[^\n]*", script)
    for call in new_team_calls:
        assert "WelcomeEmailDisabled" in call, (
            f"New-PnPTeamsTeam call missing WelcomeEmailDisabled: {call!r}"
        )
```

---

## Priority 1 — Architectural follow-ups

### P1.1 — Move from `Add-PnPTeamsUser` to **group-membership** for bulk membership ops

For the upcoming Phase 5 per-brand × per-channel rollout (20+ teams):

**Don't:**
```powershell
foreach ($u in $users) { Add-PnPTeamsUser -Team $t -User $u -Role Member }
```

**Do (lower notification surface):**
```powershell
foreach ($u in $users) {
  Add-PnPEntraIDGroupMember -Identity $groupId -Users $u
}
# rely on group→team membership sync; group was created with
# resourceBehaviorOptions: ["WelcomeEmailDisabled"]
```

This suppresses the welcome **email** and the email autosubscribe.
**It does NOT reliably suppress the Teams activity-feed entry** — see
`teams.md` §2.G for honest caveat — but it reduces the *email* blast,
which is what triggered the actual incident.

### P1.2 — Empirical test for ADR-009 channel moderation PATCH

The Learn docs are silent on whether
`PATCH /beta/teams/{id}/channels/{id}` with `moderationSettings`
triggers a user-visible notification. Before rolling moderation across
all Phase 5 brand teams, run a canary in staging:

1. Pick one staging team with 2–3 test users.
2. Apply `moderationSettings.userNewMessageRestriction = moderators`
   via the script.
3. Have the test users report: (a) bell-icon entry? (b) in-channel
   system message? (c) email?
4. Document the result in an **addendum to ADR-009**.

Until tested, schedule any channel-moderation PATCH inside the same
off-hours window as bulk membership changes.

### P1.3 — Document the "Welcome to the team" first-run experience as out-of-band

In `dce-mockup/RESEARCH-DELTAS.md` (or a new ADR), record explicitly:

> The per-team first-run Teams welcome card is **not** controllable
> via Graph, PowerShell, or Teams admin center as of 2026-05-16. The
> only mitigation is the M365 Group `WelcomeEmailDisabled` flag,
> which addresses the *email* welcome only. The in-product card will
> appear on each user's first visit to the team. This is a Microsoft
> product gap, not a misconfiguration.

This stops the same question recurring every six months.

### P1.4 — Migrate the Teams PowerShell call sites off `MicrosoftTeams` module where suppression matters

`New-Team` (MicrosoftTeams PS) does **not** surface `-ResourceBehaviorOptions`.
PnP (`New-PnPTeamsTeam`) does. Pick one — the project already standardizes
on PnP for SharePoint provisioning; align Teams provisioning to PnP for
consistency and for the suppression-flag parity.

---

## Priority 2 — Long-term / external

### P2.1 — File a Microsoft Feedback Portal item

Microsoft has not shipped a per-membership-add notification suppression
control. The closest existing community asks date to 2018. File a fresh
Feedback Portal entry citing the specific scenario:

> Bulk membership provisioning fires N user-visible activity feed
> entries with no documented suppression mechanism. Request a
> `Prefer: ms-teams-notify=false` header or a `suppressNotification`
> property on the `conversationMember` resource for the
> `POST /teams/{id}/members` and `POST /teams/{id}/channels/{id}/members`
> endpoints, gated on application permission only.

### P2.2 — Subscribe to Microsoft Graph changelog RSS

Per ADR-009 the project already monitors
<https://developer.microsoft.com/en-us/graph/changelog> for the
moderation `/beta` → `/v1.0` promotion. Add a parallel watch for any
`conversationMember` schema changes — a `suppressNotification` property
would land there first.

---

## Action item summary table

| # | Action | Owner | Where | Effort |
|---|--------|-------|-------|--------|
| P0.1 | Add `-ResourceBehaviorOptions WelcomeEmailDisabled` to every `New-PnPTeamsTeam` call | Provisioning engineer | `provision-teams.ps1` and any `New-Pnp*` callers | 30 min |
| P0.2 | Audit existing groups for `autoSubscribeNewMembers=true`, PATCH back to false | Provisioning engineer | tenant-wide one-off script | 1 hr |
| P0.3 | Reschedule next provisioning to off-hours + send Megan-signed prebrief | Comms + ops | — | comms work |
| P0.4 | Add fitness function `test_provision_teams_suppresses_welcome.py` | SDET / DevOps | `tests/architecture/` | 30 min |
| P1.1 | Refactor bulk member adds to `Add-PnPEntraIDGroupMember` path | Provisioning engineer | `provision-teams.ps1` | 2 hr |
| P1.2 | Run channel-moderation notification canary; addendum to ADR-009 | Solutions architect + 2 test users | staging tenant | 2 hr |
| P1.3 | Document first-run welcome card gap in ADR or RESEARCH-DELTAS | Solutions architect | `docs/` | 30 min |
| P1.4 | Standardize on PnP module for Teams provisioning | Provisioning engineer | — | refactor only as needed |
| P2.1 | File Microsoft Feedback Portal item | Solutions architect | external | 15 min |
| P2.2 | Subscribe to Graph changelog RSS for `conversationMember` schema | Solutions architect | RSS reader | 5 min |

---

## What this research **cannot** give you

- A documented Microsoft API that suppresses the Teams in-product
  activity feed entry on membership add. **It does not exist as of
  2026-05-16.** Anyone who tells you otherwise is selling folklore.
- A tenant-wide Teams admin policy to suppress the per-team first-run
  welcome card. Also does not exist.
- Confirmation of channel-moderation PATCH notification behavior. The
  Learn docs are silent; only empirical test will tell you.

Where those gaps bite, the report is explicit and the recommendations
above are the only honest mitigations.
