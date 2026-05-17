# ADR-011 — Notification suppression by default across all provisioning surfaces

**Status:** Proposed (2026-05-16)
**Author:** `solutions-architect` agent research, persisted by `code-puppy-1bc20e`
**Co-sign required:** Security Auditor (STRIDE table) — routed to `release-gate-arbiter` since no `security-auditor` agent is present in this swarm; Pack Leader (rollout coordination); Experience Architect (launch-day comms UX)
**Supersedes:** none
**Superseded by:** none
**Companion document:** [`../NOTIFICATION-SUPPRESSION-PLAYBOOK.md`](../NOTIFICATION-SUPPRESSION-PLAYBOOK.md)

---

## Context

On 2026-05-12 through 2026-05-15, three commits on `Delta-Crown-Org/DeltaSetup` executed provisioning scripts that sent welcome / sharing / access-granted emails to approximately **5 initial owners + up to 52 HTT corporate users** without explicit operator consent. Tyler discovered the issue when he received one personally in his HTT mailbox at `tyler.granlund@httbrands.com`.

The triggering commits and scripts:

| Commit | Date | Script | Failure mode |
|---|---|---|---|
| `834f516` | 2026-05-12 | `tools/provision-crown-connection.sh` | `POST /groups` with `members@odata.bind` and **no `resourceBehaviorOptions: WelcomeEmailDisabled`**. Welcome mail fires for every member on group creation. |
| `1cad240` | 2026-05-14 | `tools/expand-crown-connection-htt-corp.py` | `PATCH /groups/{id}` `members@odata.bind` against the already-hot group. Guest userType forces autosubscribe regardless of group settings (Microsoft Learn-documented behavior). |
| `a6dd3f5` | 2026-05-15 | Same script, re-run for full HTT-corp coverage | Same failure mode, additional users in blast radius. |

The provisioning code worked as designed. The defect was **architectural**: the scripts treated end-user notification as a default side-effect of provisioning rather than as an explicit, separate, audited step.

Microsoft 365's provisioning surface has 30+ documented APIs/cmdlets across SharePoint, Teams, Entra, and Exchange. Per the research summarized in `NOTIFICATION-SUPPRESSION-PLAYBOOK.md` §3, the notification-suppression defaults are wildly inconsistent:

- **Default-sends** (high risk): M365 Group member-add (Exchange welcome path), `Add-PnPFile*SharingInvite -SendInvitation`, Teams team/channel member-add (activity feed; not suppressible at all), legacy `SP.Web.ShareObject sendEmail`.
- **Default-suppresses** (safe): Graph `POST /invitations` (`sendInvitationMessage: false`), Graph `POST /drives/.../invite` (`sendInvitation: false`), `Set-PnPWebPermission` (no email surface), `Add-PnPHubSiteAssociation` (no email surface), cross-tenant sync (silent by design).
- **PnP documentation defect**: `Add-PnPFileSharingInvite -SendInvitation` parameter prose is inverted relative to the parameter name and underlying Graph contract.
- **Microsoft product gap**: The Teams in-product activity-feed notification on member add is NOT suppressible via any documented API surface.
- **Behavioral trap**: Guest users are *always* autosubscribed to M365 Group conversations regardless of `autoSubscribeNewMembers:$false` — verified verbatim in Microsoft Learn.

Without a uniform default-off policy, every new provisioning script becomes an opportunity to repeat the incident.

---

## Decision

**Every provisioning action that could generate a user-facing notification MUST be suppressed by default. Notifications are an explicit, separate, audited step.** This is the *scaffold-quietly, launch-loudly* pattern.

Concrete invariants enforced by this ADR:

1. **Mode signaling.** Every provisioning script accepts `-Mode {scaffold|launch}` (PowerShell) or `--mode {scaffold,launch}` (Python/Bash), default `scaffold`. Scaffold mode forbids all notification opt-ins. Launch mode requires a separate file (filename matches `*launch*.{ps1,py,sh}`), a `# DCE-LAUNCH-MODE: APPROVED` marker, and a GitHub Environment with required reviewers.
2. **Forbidden opt-ins in scaffold mode** (statically enforced by `tests/architecture/test_notification_suppression.py`):
   - `-SendInvitation` on any `Add-PnP*SharingInvite` cmdlet
   - `-SendEmail` on `Add-PnPGroupMember`
   - Graph body `"sendInvitation": true`, `"sendEmail": true`
   - `sendInvitationMessage = $true` or `"sendInvitationMessage": True`
   - `-UnifiedGroupWelcomeMessageEnabled:$true` (re-enabling welcomes is launch-mode only)
   - `Set-PnPListItem -UpdateType UpdateOverwriteVersion` (footgun; use `SystemUpdate`)
3. **Required suppression at create time** (statically enforced where possible):
   - Every `New-PnPMicrosoft365Group` / `New-PnPTeamsTeam` includes `-ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook`.
   - Every Graph `POST /groups` body in repo scripts includes `"resourceBehaviorOptions": ["WelcomeEmailDisabled", "HideGroupInOutlook"]`.
   - Every `New-MgInvitation` includes `-SendInvitationMessage:$false` explicitly (defensive against SDK drift).
   - Every Graph `POST .../invite` body explicitly includes `"sendInvitation": false`.
4. **Tenant-wide post-hoc remediation.** A new `dce-mockup/ci-cd/scripts/remediate-group-welcome.ps1` runs idempotently as part of `bootstrap.sh` step 9 to disable `UnifiedGroupWelcomeMessageEnabled` on every existing M365 Group. This is required because `resourceBehaviorOptions` is creation-only — for groups already in the tenant, the Exchange-side switch is the only suppression.
5. **Fitness functions in CI.** `tests/architecture/test_notification_suppression.py` enforces all of the above at PR time. Runs in `pr-validation.yml` and again as a pre-deploy gate in `deploy-prod.yml`.
6. **Honest documentation of the Teams gap.** The Teams in-product activity-feed entry on member add cannot be suppressed via any documented Microsoft API. We accept the artifact and mitigate via off-hours provisioning + prebrief comms. We do NOT claim full suppression in user-facing documentation.

---

## Research basis (verified 2026-05-16)

Full citations and matrix in `NOTIFICATION-SUPPRESSION-PLAYBOOK.md`. All sources Tier 1 (Microsoft Learn / `pnp.github.io/powershell`). Key load-bearing quotes:

| Claim | Source |
|---|---|
| `resourceBehaviorOptions` is creation-only | <https://learn.microsoft.com/en-us/graph/group-set-options#configure-groups> |
| Guests are always autosubscribed to group conversations | <https://learn.microsoft.com/en-us/powershell/module/exchange/set-unifiedgroup?view=exchange-ps#-autosubscribenewmembers> |
| `sendInvitationMessage` defaults to `false` (v1.0 + beta) | <https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-1.0> |
| Cross-tenant sync sends no user-facing mail | <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview#when-is-the-consent-prompt-suppressed> |
| Teams `POST /teams/{id}/members` documents no suppression flag | <https://learn.microsoft.com/en-us/graph/api/team-post-members?view=graph-rest-1.0> |
| `Set-PnPListItem -UpdateType SystemUpdate` bypasses Power Automate flows; `UpdateOverwriteVersion` does NOT | <https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html> |
| `SharingInvitationCreated` UAL operation always implies mail was sent | <https://learn.microsoft.com/en-us/purview/audit-log-activities#sharing-and-access-request-activities> |
| `Get-MessageTrace` 10-day retention; `Start-HistoricalSearch` 90 days | <https://learn.microsoft.com/en-us/powershell/module/exchange/get-messagetrace?view=exchange-ps> |

---

## Alternatives considered

### A. Per-script discretion (status quo)

Each provisioning script author decides when to suppress. **Rejected** — this is precisely the model that produced the HTT-52 incident. Microsoft's defaults are too inconsistent to leave to memory.

### B. Tenant-level kill switch only (`Set-SPOTenant -DisableSharingForNonOwners`)

Disable tenant sharing capabilities globally; rely on tenant guardrails to prevent the mail surface. **Rejected** — over-broad. Tenant-level controls would block legitimate sharing during normal operation. Also doesn't address group welcomes, Teams activity feed, or B2B invitations, all of which have separate suppression paths.

### C. Pre-execution dry-run + human approval on every provisioning run

Force every script to print "I will create X group, Y member adds, Z shares" and wait for `y/n` confirmation. **Rejected for primary path** — works for ad-hoc Tyler-runs-it-himself scenarios but doesn't scale to CI/CD. **Adopted as the launch-mode pattern** (manual `workflow_dispatch` + GitHub Environment approval).

### D. Suppression-by-default with fitness functions (this ADR)

Static CI enforcement + tenant post-hoc remediation + separate launch-mode workflow. **Accepted.** This is the only option that:

- Catches violations at PR time, before any tenant action.
- Distinguishes scaffold from launch with a single explicit signal.
- Survives operator forgetfulness, SDK default drift, and Microsoft's inconsistent defaults.
- Provides forensic audit trail (the `PROVISIONING-MODE:` log line) for every run.

---

## Consequences

**Good.**

- Future provisioning runs cannot repeat HTT-52 without a CI-gate violation.
- Launch-day comms are operator-curated, brand-controlled, and audited — better user experience than Microsoft's stock welcome mail anyway.
- The `PROVISIONING-MODE:` audit-log line gives the permission-audit workflow a hook to detect drift.
- Future agents inheriting this codebase have a single document (the playbook) describing every notification surface and its suppression mechanism.

**Bad.**

- One more parameter (`-Mode` / `--mode`) on every script — small learning curve.
- Two scripts (scaffold + launch) instead of one — more files to maintain.
- The Teams activity-feed gap remains unsuppressed. We accept this and mitigate operationally; we do not promise to solve it.
- `bootstrap.sh` now requires Exchange Online module + the post-hoc remediation step — adds 30–60 s to bootstrap time on first run.

**Neutral.**

- The PnP doc-defect on `Add-PnPFileSharingInvite -SendInvitation` should be reported upstream (separate `bd` issue), but our CI gate doesn't depend on Microsoft fixing it — the regex catches the switch regardless of what the prose says.
- ADR-009 (channel moderation BETA endpoint) gains a new open question: does `PATCH /beta/teams/.../channels/.../moderationSettings` fire a member-visible notification? Docs are silent. Empirical canary scheduled as part of ADR-011 rollout.

---

## STRIDE security analysis

> **⚠ Co-sign required.** Per the Solutions Architect protocol, the STRIDE table requires Security Auditor sign-off before status flips to Accepted. No `security-auditor` agent exists in this swarm; the closest authority is `release-gate-arbiter`. **Action:** route this ADR to Release Gate Arbiter for STRIDE adversarial review (tracked as bd `DeltaSetup-<adr011-cosign>`).

| Threat | Vector | Mitigation under ADR-011 | Residual risk |
|---|---|---|---|
| **Spoofing** | Attacker compromises `dce-sharepoint-deploy` cert and runs provisioning to seed silent backdoor accounts | App-only auth (ADR-007) + UAL records `ApplicationId` + `UserType=6` for every action; weekly permission-audit detects role-assignments not in `reference/permission-breaks.csv` | Low — actor identity is logged in two surfaces (UAL `ApplicationId` + Entra `initiatedBy.app.appId`) |
| **Tampering** | Operator edits provisioning script to bypass `-Mode scaffold` and sneak mail-sends past CI | Static fitness-function regex catches `-SendInvitation`, `sendInvitation:true`, `-SendEmail`, etc. at PR time. Launch scripts require `# DCE-LAUNCH-MODE: APPROVED` marker + GitHub Environment with required reviewers | Low — bypass requires concurrent PR-review collusion AND environment-approval collusion |
| **Repudiation** | Operator denies sending a notification ("I didn't send those emails!") | Every script writes `PROVISIONING-MODE: <mode> COMMIT=<sha> RUN=<id>` to `out/provisioning-mode.log`, uploaded as a CI artifact with 365-day retention. UAL records the `ApplicationId` + `ClientIP`. Message Trace records the SMTP envelope | Very low — three independent surfaces record the action; UAL is the system-of-record |
| **Information Disclosure** | Scaffold-mode provisioning accidentally emails a confidential resource URL to wrong recipient | Scaffold mode by definition does NOT email recipients. Launch-mode emails are operator-curated and go through Exchange DLP (existing tenant policy). Failure mode = no email sent, not wrong email sent | Very low — failure mode is silent, not loud |
| **Denial of Service** | Attacker triggers `launch` workflow to mass-mail every user in the tenant | `launch` workflow is `workflow_dispatch`-only and requires GitHub Environment approval. Each launch script emits a recipient manifest before sending; manifest must be human-reviewed in the approval flow. Exchange rate limits cap blast radius at ~30 msg/min/mailbox | Low — requires environment-approver collusion |
| **Elevation of Privilege** | Attacker uses suppressed-but-granted permissions to escalate access without users noticing | Permissions are granted regardless of mail suppression — this is *intended* behavior. The weekly permission-audit (`permission-audit.yml`, `05-permissions-model.md`) catches unexpected role assignments via the `permission-breaks.csv` allow-list. **Caveat:** suppression does not change the access-grant; it changes whether the user is *notified* of the grant. Users not being told they have access is itself an audit-surface concern | Medium — mitigated by weekly permission audit, but users not being notified means they cannot self-detect over-permissioning. Recommend a quarterly "your access" digest to all users as a separate compensating control |

**Compensating controls (filed as follow-on `bd` issues):**

1. Quarterly "your DCE access" digest mail to every active user — operator-curated, no Microsoft stock welcome, but ensures users learn of their access within 90 days even when scaffold mode hid the original grant.
2. Empirical canary on every notification-capable provisioning change (one-user pilot before cohort run).
3. Annual review of Microsoft Learn URLs cited in the playbook — Microsoft revs the docs quarterly and we need to catch behavioral changes.

---

## Fitness functions

`tests/architecture/test_notification_suppression.py` — four test groups:

1. **TestSuppressByDefault** — no provisioning file may contain the forbidden opt-in patterns in non-comment lines.
2. **TestSuppressionMechanismsPresent** — every group/team creation includes `WelcomeEmailDisabled`; every B2B invitation explicitly sets `sendInvitationMessage:$false`.
3. **TestModeSignal** — every provisioning script declares the `-Mode`/`--mode` parameter and logs `PROVISIONING-MODE:` at startup.
4. **TestLaunchScriptsAreSeparate** — files matching `**/*launch*.{ps1,py,sh}` carry the `# DCE-LAUNCH-MODE: APPROVED` marker.

See [`../../../tests/architecture/test_notification_suppression.py`](../../../tests/architecture/test_notification_suppression.py) for the full implementation. Wired into `pr-validation.yml` after schema validation and `deploy-prod.yml` as a pre-deploy gate. Runs in <1 s (pure static analysis).

---

## Implementation

1. **Today (P0):** Run the playbook §8.1 Message Trace forensic query. Hard deadline 2026-05-22. (Tyler-action; tracked as bd `DeltaSetup-<htt52-forensics>`.)
2. **Today (P0):** Land the playbook + ADR-011 + fitness functions. (This commit.)
3. **This week:** Apply the `bootstrap.sh` / workflow refactor and the `remediate-group-welcome.ps1` script. Run remediation against the DCE tenant. (Tracked as bd `DeltaSetup-<adr011-rollout>`.)
4. **Empirical canary (P1):** Single-user xtsync canary per playbook §4.3 step 5. Single-channel moderation canary per ADR-009 addendum.
5. **Apology comms:** Per playbook §8.5, send curated apology mail-merge to the ~52 affected HTT users from a recognizable sender. (Launch-mode workflow.)
6. **Acceptance:** Once Release Gate Arbiter signs the STRIDE section and the fitness functions are green in CI, flip status from Proposed → Accepted.

---

## Acceptance criteria

- [ ] `tests/architecture/test_notification_suppression.py` passes in CI on a fresh PR.
- [ ] `bootstrap.sh` step 9 completes without warnings on a fresh DCE tenant.
- [ ] `scripts/remediate-group-welcome.ps1 -Mode scaffold` reports 0 groups with welcomes enabled.
- [ ] `provisioning-mode.log` artifact is produced on every `provision-teams.yml` / `deploy-prod.yml` run.
- [ ] `launch-notifications.yml` requires a human approver before any run.
- [ ] Empirical canaries (xtsync + channel moderation) executed and documented.
- [ ] HTT-52 apology mail-merge sent and acknowledged.
- [ ] Release Gate Arbiter has co-signed the STRIDE table.

---

## Migration plan

When Microsoft ships a documented suppression for the Teams activity-feed entry (the one remaining gap):

1. Monitor <https://developer.microsoft.com/graph/changelog> for `conversationMember` schema changes.
2. When a `suppressNotification` (or equivalent) property lands on `POST /teams/{id}/members`, file a new ADR superseding the §4.5 "accept the artifact" position.
3. Update `provision-teams.ps1` to include the property by default.
4. Update fitness function group `TestSuppressionMechanismsPresent` to enforce it.

---

## References

- Playbook: [`../NOTIFICATION-SUPPRESSION-PLAYBOOK.md`](../NOTIFICATION-SUPPRESSION-PLAYBOOK.md)
- Related ADRs: ADR-007 (cert-based auth), ADR-008 (HTT-corp sync group name), ADR-009 (Teams moderation BETA)
- Source scripts (the HTT-52 culprits): `tools/provision-crown-connection.sh`, `tools/expand-crown-connection-htt-corp.py`
- Source scripts (the compliant pattern): `tools/invite-htt-users-to-dce.py` (already sets `sendInvitationMessage: False`)
