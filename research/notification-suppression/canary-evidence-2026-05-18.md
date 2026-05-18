# ADR-011 empirical canaries — evidence log (2026-05-18)

**bd:** `DeltaSetup-j3c`  
**Operator:** `code-puppy-73a4b6` with Tyler approval for any tenant mutation  
**Tenant under test:** Delta Crown / `deltacrown.onmicrosoft.com`  
**Status:** Deferred by Tyler after read-only tenant reconnaissance. No canary users were created and no tenant mutations were performed.

This file is the system-of-record evidence log for the initial ADR-011 empirical
canaries. The goal is not to prove Microsoft documentation by vibes; the goal is
to capture enough timestamps, identities, and observation surfaces that a future
reviewer can reproduce the conclusion or spot where the test was inconclusive.

On 2026-05-18 Tyler chose to put the canary-user execution on the back burner
while deciding whether cross-tenant sync and Teams moderation are required right
out of the gate. This is acceptable as long as tenant-wide xtsync expansion and
Teams channel-moderation rollout remain gated until the canaries are completed.

---

## Guardrails

1. No production cohort changes during this canary.
2. Use canary-only users, groups, and Teams.
3. Record UTC timestamps before and after each mutation.
4. Check both mail and Teams activity surfaces.
5. Do not treat "I did not notice a popup" as evidence. Use monitored mailbox,
   message trace, screenshots, or Graph/Teams UI observations.
6. Any intentionally noisy control run must use a canary mailbox only.

---

## Read-only reconnaissance completed

Timestamp: `2026-05-18T15:27Z` approximate, from local delegated Graph token.

### DCE tenant

Graph `GET /organization` confirmed:

- Tenant ID: `ce62e17d-2feb-4e67-a115-8ea4af68da30`
- Display name: `Delta Crown Extensions`
- Domains: `deltacrown.onmicrosoft.com`, `deltacrown.com`

### Unified Group suppression posture from Graph

Graph `GET /groups?$select=id,displayName,mail,groupTypes,resourceBehaviorOptions`
showed these relevant Unified Groups:

| Group | Mail | ID | `resourceBehaviorOptions` finding |
|---|---|---|---|
| `DCE-HTT-Corporate-Sync` | `DCEHTTCorporateSync@deltacrown.com` | `ebbd0644-edd3-441f-9857-88864c24dc5f` | Contains `WelcomeEmailDisabled`. |
| `Delta Crown Extensions` | `DeltaCrownExtensions@deltacrown.com` | `dca7a24a-00ed-49c0-be67-80a9c163492c` | Contains `HideGroupInOutlook`, `SubscribeMembersToCalendarEventsDisabled`, `WelcomeEmailDisabled`. |
| `Delta Crown Extensions` | `DeltaCrownExtensions379@deltacrown.com` | `1af8cb12-e2b4-4608-80e0-e4f60d2a2557` | Contains `HideGroupInOutlook`, `SubscribeMembersToCalendarEventsDisabled`, `WelcomeEmailDisabled`. |
| `Delta Crown Operations` | `dce-operations-team@deltacrown.com` | `03255d50-a52d-4b1f-a0f6-37379cc13a35` | Empty; pre-ADR-011 style posture. Do not use as canary target without explicit approval. |
| `Crown Connection` | `CrownConnection@deltacrown.com` | `11e4f2da-c468-4b81-9a18-46d883099a62` | Empty; pre-ADR-011 style posture. Do not use as canary target without explicit approval. |

### DCE-HTT-Corporate-Sync dynamic group

Graph `GET /groups/ebbd0644-edd3-441f-9857-88864c24dc5f` confirmed:

- `groupTypes`: `DynamicMembership`, `Unified`
- `membershipRule`: `(user.userType -eq "Member") and (user.mail -match ".*@httbrands\\.com$")`
- `membershipRuleProcessingState`: `On`
- `resourceBehaviorOptions`: `WelcomeEmailDisabled`
- Existing members are HTT-mail users represented in DCE as `userType = Member`.

Graph searches for `xtsync-canary*` found no existing DCE user. The initial
canary still requires creation/sync of a fresh HTT canary mailbox.

### Teams read-context blocker

Graph `GET /teams/{team-id}/channels` against the visible Team-backed groups
failed with:

```text
Forbidden: Failed to get license information for the user. Ensure user has a
valid Office365 license assigned to them.
```

This matches the separate Teams read-context blocker tracked by `DeltaSetup-4ay`.
The channel-moderation canary cannot be observed from the current local delegated
context until a licensed DCE/Teams-capable observer account is available or an
app-only Graph path with the needed Teams scopes is used.

---

## Deferral decision

Tyler asked to skip the canary user execution for now because the team needs to
confirm whether the capability is needed immediately. Therefore:

- No `xtsync-canary-1@httbrands.com` user was created.
- No canary mailbox license was assigned.
- No cross-tenant sync trigger was executed.
- No M365 Group member-add positive-control was executed.
- No Teams moderation PATCH was executed.

The canaries remain required before either of these actions is rolled out beyond
safe canary scope:

1. HTT → DCE cross-tenant sync expansion or production dependency.
2. Teams channel moderation changes via Graph beta against production Teams.

Until then, this work should be treated as a deferred rollout gate rather than a
current brand-tenant setup blocker.

---

## Canary A — cross-tenant sync silence

### Purpose

Validate, in the actual DCE/HTT configuration, that cross-tenant sync does not
send user-facing mail and that M365 Group welcome suppression prevents downstream
welcome mail when the synced user is added to a group.

### Preconditions

| Item | Required value / evidence | Status |
|---|---|---|
| HTT canary user | `xtsync-canary-1@httbrands...` monitored mailbox | Pending Tyler confirmation |
| DCE synced user object | Object ID captured after sync | Pending execution |
| DCE canary target group | Dedicated test M365 Group, not Crown Connection production | Pending selection/creation |
| Group creation suppression | `resourceBehaviorOptions` includes `WelcomeEmailDisabled` if newly created | Pending execution |
| Exchange group flag | `UnifiedGroupWelcomeMessageEnabled = False` before member-add | Pending execution |
| Observation window | Minimum 15 minutes after each mutation, unless message trace proves earlier | Pending execution |

### Execution checklist

#### A1. Baseline mailbox state

- [ ] Record canary mailbox inbox count / latest relevant message timestamp.
- [ ] Record Exchange message trace query window start.
- [ ] Save screenshot or message-trace export path.

Evidence:

```text
UTC start:
Mailbox observer:
Message trace command/export:
Baseline finding:
```

#### A2. Run or trigger cross-tenant sync

- [ ] Trigger sync for only the canary scope, or wait for the scoped sync cycle.
- [ ] Record DCE user object ID and userType.
- [ ] Wait observation window.
- [ ] Check canary mailbox for user-facing mail from Microsoft provisioning,
      SharePoint, Teams, Entra invitation, or M365 Groups.

Evidence:

```text
UTC mutation time:
DCE user object ID:
DCE userType:
Observation window:
Mailbox result:
Message trace result:
Conclusion: PASS / FAIL / INCONCLUSIVE
```

#### A3. Suppressed group-member add

- [ ] Confirm target group `UnifiedGroupWelcomeMessageEnabled = False`.
- [ ] Add the synced canary to the target group.
- [ ] Wait observation window.
- [ ] Check mailbox and message trace.

Evidence:

```text
UTC mutation time:
Target group identity:
Pre-add UnifiedGroupWelcomeMessageEnabled:
Add method/cmdlet/API:
Observation window:
Mailbox result:
Message trace result:
Conclusion: PASS / FAIL / INCONCLUSIVE
```

#### A4. Positive-control noisy run

This run proves the canary mailbox can receive the type of notification being
suppressed. It must target only the canary mailbox.

- [ ] Create or select a disposable canary group with welcome enabled.
- [ ] Add the canary user.
- [ ] Confirm welcome mail arrives, or document why the positive control failed.
- [ ] Disable welcome mail again and/or delete the disposable group.

Evidence:

```text
UTC mutation time:
Control group identity:
Pre-add UnifiedGroupWelcomeMessageEnabled:
Mailbox result:
Message trace result:
Cleanup completed:
Conclusion: PASS / FAIL / INCONCLUSIVE
```

### Canary A decision

```text
Result: Pending
Rationale:
Residual uncertainty:
Follow-up issue(s):
```

---

## Canary B — Teams channel moderation PATCH notification behavior

### Purpose

Validate whether `PATCH /beta/teams/{id}/channels/{id}` with
`moderationSettings` creates a member-visible Teams activity-feed item, toast,
channel post, or email in the DCE tenant.

### Preconditions

| Item | Required value / evidence | Status |
|---|---|---|
| Test Team | Dedicated canary Team with exactly scoped test members | Pending selection/creation |
| Canary member | Monitored test user, not production cohort | Pending Tyler confirmation |
| Observer account | Account that can inspect canary member Teams activity/feed | Pending Tyler confirmation |
| Channel | Prefer General channel in canary Team | Pending execution |
| Baseline moderation state | GET channel result captured before PATCH | Pending execution |
| Observation window | Minimum 15 minutes after PATCH | Pending execution |

### Execution checklist

#### B1. Baseline Teams state

- [ ] Record Team ID and Channel ID.
- [ ] Capture current `moderationSettings` via Graph GET.
- [ ] Capture canary member Teams activity feed baseline.
- [ ] Confirm no unread/channel-settings activity exists before test.

Evidence:

```text
UTC start:
Team ID:
Channel ID:
Canary member:
Baseline moderationSettings:
Baseline activity feed finding:
```

#### B2. PATCH moderationSettings

- [ ] PATCH only the canary channel.
- [ ] Record exact request body.
- [ ] Capture response status and post-PATCH GET result.
- [ ] Wait observation window.
- [ ] Check canary member Teams activity feed, channel list, General channel,
      desktop/web toast history if available, and mailbox.

Evidence:

```text
UTC mutation time:
PATCH URI:
PATCH body:
Response status:
Post-PATCH moderationSettings:
Observation window:
Teams activity result:
Channel post result:
Mailbox/message trace result:
Conclusion: PASS / FAIL / INCONCLUSIVE
```

#### B3. Revert moderationSettings

- [ ] Restore baseline moderation settings.
- [ ] Capture post-revert GET result.
- [ ] Check whether revert itself created activity.

Evidence:

```text
UTC revert time:
Revert body:
Post-revert moderationSettings:
Activity result after revert:
Conclusion: PASS / FAIL / INCONCLUSIVE
```

### Canary B decision

```text
Result: Pending
Rationale:
Residual uncertainty:
ADR-009 addendum text:
Follow-up issue(s):
```

---

## Required doc updates after execution

- [ ] Update `docs/sharepoint-pnp-spec/NOTIFICATION-SUPPRESSION-PLAYBOOK.md`
      §4.3 and §4.5 with empirical results.
- [ ] Update `docs/sharepoint-pnp-spec/decisions/011-notification-suppression-by-default.md`
      acceptance criteria / compensating-control status.
- [ ] Add ADR-009 addendum in
      `docs/sharepoint-pnp-spec/decisions/009-teams-moderation-beta-only.md`.
- [ ] Close `DeltaSetup-j3c` only after evidence and doc updates are committed.
