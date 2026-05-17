# ADR-011 — Notification suppression by default across all provisioning surfaces

**Status:** Proposed (2026-05-16) — pending must-fold addenda from release-gate-arbiter STRIDE co-sign (this commit folds them; status may flip to Accepted once `tests/architecture/test_notification_suppression.py` is green in CI and the launch-mode workflow + access-digest workflow exist per Acceptance Criteria below).
**Author:** `solutions-architect` agent research, persisted by `code-puppy-1bc20e`
**Co-sign required:** Security Auditor (STRIDE table) — performed by `release-gate-arbiter-bc138a` as proxy on 2026-05-16; this swarm has no dedicated `security-auditor` agent. Full ASVS L2 / CIS-mapped audit remains an open dependency before any production launch-mode invocation (see signature block at end of STRIDE section). Plus: Pack Leader (rollout coordination); Experience Architect (launch-day comms UX).
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

> **Co-signed by `release-gate-arbiter-bc138a` on 2026-05-16 with 5 addenda folded below + 4 supplemental threats added.** Signature block at the end of this section. `security-auditor` agent is not present in this swarm; release-gate-arbiter acted as proxy. Full ASVS L2 / CIS-mapped human or dedicated-agent security review remains an open dependency before any production launch-mode invocation — tracked as bd `DeltaSetup-<security-auditor-engagement>`.

### Core STRIDE table (6 rows)

| Threat | Vector | Mitigation under ADR-011 | Residual risk |
|---|---|---|---|
| **Spoofing** | Attacker compromises `dce-sharepoint-deploy` cert and runs provisioning to seed silent backdoor accounts | App-only auth (ADR-007) + UAL records `ApplicationId` + `UserType=6` for every action; weekly permission-audit detects role-assignments not in `reference/permission-breaks.csv`. **Addendum (cert lifecycle, required):** (a) private key resides in GitHub Actions OIDC-federated secret or Azure Key Vault HSM-backed secret, never in repo or local disk; (b) cert rotation cadence ≤ 90 days, tracked under a dedicated bd; (c) alert fires when `ApplicationId == dce-sharepoint-deploy` performs `/groups` or `/teams` writes outside business hours (08:00–20:00 CT, Mon–Fri) or outside the GitHub Actions IP range; (d) compromise playbook in `10-runbooks.md` includes immediate cert revocation + UAL replay over the rotation window | Low (conditional on cert-lifecycle addendum landing) — actor identity is logged in two surfaces (UAL `ApplicationId` + Entra `initiatedBy.app.appId`); compensating runtime detection raises the bar against the quiet-spoof advantage that scaffold-mode default creates |
| **Tampering** | Operator edits provisioning script to bypass `-Mode scaffold` and sneak mail-sends past CI | Static fitness-function regex catches `-SendInvitation`, `sendInvitation:true`, `-SendEmail`, etc. at PR time. Launch scripts require `# DCE-LAUNCH-MODE: APPROVED` marker + GitHub Environment with required reviewers. **Three control addenda (required for Low rating):** (1) **Glob coverage parity** — `PROVISIONING_GLOBS` in the fitness test extended to cover `.ps1/.py/.sh` × every reasonable directory (`tools/`, `scripts/`, `dce-mockup/ci-cd/scripts/`, `phase2-week1/`, `phase3-week2/`, `phase4-migration/`, `phase5/`) so a new directory can't ship without triggering the scan. **Landed in this commit.** (2) **Runtime-constructed body defense** — at least one test in Group 2 extended to require that scripts which `Invoke-RestMethod`/`requests` to `/groups`, `/invitations`, or `/invite` either emit the suppression literal in source OR carry a `# ADR-011-SUPPRESSION-VERIFIED: <reason>` waiver line that surfaces in PR review. Negative-lookahead regexes like `-SendInvitation\b(?!\s*:\s*\$false)` do not catch `-SendInvitation:$var` where `$var = $true` is set elsewhere. (3) **CODEOWNERS protection** — `.github/CODEOWNERS` lists `tests/architecture/`, ADR files, and `.github/workflows/` + `dce-mockup/ci-cd/workflows/` with two-reviewer required approval. **Landed in this commit.** | Low (with all three addenda); Medium if any one is omitted. With addenda, an insider bypass requires (i) compromising two CODEOWNERS reviewers simultaneously plus one launch-Environment approver, or (ii) finding a Microsoft API surface not enumerated in the playbook |
| **Repudiation** | Operator denies sending a notification ("I didn't send those emails!") | Every script writes `PROVISIONING-MODE: <mode> COMMIT=<sha> RUN=<id>` to `out/provisioning-mode.log`, uploaded as a CI artifact. UAL records the `ApplicationId` + `ClientIP`. Message Trace records the SMTP envelope. **Addendum (retention-pinning, required):** (a) GitHub Actions artifact retention has plan-tier caps (90d Team / 400d Enterprise); if 365+-day retention is required, mirror the artifact to S3/Blob with explicit lifecycle policy. The `retention-days:` value in workflow YAML is the source-of-record claim. (b) UAL retention citation is licensed-SKU-dependent: 180d on E3, 365d on E5. The playbook §8.1 must cite the actual DCE tenant SKU. (c) Message Trace beyond 10 days documented to use `Start-HistoricalSearch` (90-day window, async; already in playbook) | Very low (with retention pinning); Low without. Three-surface logging story is genuinely strong (UAL + Entra + Message Trace) |
| **Information Disclosure** | Scaffold-mode provisioning accidentally emails a confidential resource URL to wrong recipient | Scaffold mode by definition does NOT email recipients. Launch-mode emails are operator-curated and go through Exchange DLP (existing tenant policy). Failure mode = no email sent, not wrong email sent. **Scoped caveat:** ADR-011 addresses the email-channel disclosure vector only. Information Disclosure via the *granted permission itself* (an unintended share that is silently granted but never emailed is still a disclosure) is owned by ADR-004 (permissions philosophy) and the weekly permission-audit. Cross-reference noted | Very low for the email surface (scope of this ADR). Permission-grant disclosure tracked separately under ADR-004 |
| **Denial of Service** | Attacker triggers `launch` workflow to mass-mail every user in the tenant | `launch` workflow is `workflow_dispatch`-only and requires GitHub Environment approval. **Addendum (required):** the `launch` GitHub Environment is configured with **at least two distinct human reviewers**, with **author-of-launch-PR ≠ approver** enforced (matches the release-gate-arbiter waiver protocol §P0-9). The launch script itself enforces (a) **hard cap of N=500 recipients per invocation** with explicit chunking required above that, (b) Exchange-aware throttle of ≤ 30 msg/min/mailbox with backoff, (c) the recipient manifest is attached to the workflow run as a downloadable artifact and its **SHA-256 echoed in the approval prompt** so a tampered manifest between manifest-generation and send is detectable | Low (with addendum). Without the ≥2-reviewer enforcement, there is no collusion to require — a single compromised approver can send to the full tenant |
| **Elevation of Privilege** | Attacker uses suppressed-but-granted permissions to escalate access without users noticing | Permissions are granted regardless of mail suppression — this is *intended* behavior. The weekly permission-audit (`permission-audit.yml`, `05-permissions-model.md`) catches unexpected role assignments via the `permission-breaks.csv` allow-list. **Caveat:** suppression does not change the access-grant; it changes whether the user is *notified* of the grant. **Addendum (required as Acceptance Criterion):** the quarterly "your DCE access" digest is now a **blocking acceptance criterion**, NOT a follow-on. Maximum window during which a user holds unwanted access without notification is bounded at 90 days **by design**. If any resource in DCE holds PII/PHI/PCI, the digest cadence tightens to 30 days for those resources only | Medium (with digest as Acceptance Criterion). Without the digest in AC, this rating is aspirational and should be rated **High until the digest workflow ships** |

### Supplemental threats (4 rows, surfaced by adversarial review)

| Threat | Vector | Mitigation under ADR-011 | Residual risk |
|---|---|---|---|
| **Supply-chain Tampering on PnP / Graph SDK** | Malicious or regressed PnP.PowerShell or Microsoft.Graph module silently ignores `WelcomeEmailDisabled` or `sendInvitationMessage:false`; mail fires; fitness test passes because source text is correct | Pin module versions: `PnP.PowerShell` and `Microsoft.Graph` declared in `#Requires` / `requirements.txt`. Verify module signatures against PowerShell Gallery published thumbprints in `bootstrap.sh` Step 9. Quarterly empirical end-to-end canary (xtsync invitation + Message Trace check) proves suppression still works at runtime — bd `DeltaSetup-j3c` covers the initial canary; this addendum makes it recurring | Low (with quarterly canary). Without it, behavioral drift could be invisible for up to one Microsoft release cycle |
| **TOCTOU on launch marker / local override** | Operator runs a `*launch*.ps1` script locally with prod cert and credentials, bypassing `workflow_dispatch` and Environment approval | The launch script asserts the presence of a CI-only signed env var (e.g., `LAUNCH_APPROVAL_JWT` issued by the workflow with a 15-minute TTL) and refuses to execute without it. Local dry-run mode is a separate `-Mode preview` that cannot send. The cert used for launch-mode runs must NOT be installed on operator workstations | Low (with JWT gate). Without it, the GitHub Environment approval is bypassable by anyone with cert + script access |
| **Bootstrap Step 9 tenant-wide write without backup** | `remediate-group-welcome.ps1` modifies `UnifiedGroupWelcomeMessageEnabled` on every M365 Group; no pre-image captured; a botched run plus an angry group owner = unrecoverable | The remediation script writes the pre-image state of every modified group to `out/welcome-mail-preimage-<runid>.json` as a CI artifact, and a companion `restore-group-welcome.ps1` exists with documented rollback for any group whose owner objects. Tracked under bd `DeltaSetup-17i` | Very low (with pre-image + restore). Without, an operator dispute has no rollback path |
| **Notification-as-detection-channel** | Removing the user-facing email surface removes a (cheap, accidental) canary that detected the original HTT-52 incident. Quarterly digest restores it for the *access* class; nothing restores it for *future unforeseen* misconfiguration classes | Any new provisioning capability added under ADR-011 must include an explicit "detection-channel of last resort" section in its design doc — what surface (alert, dashboard tile, weekly digest, sample-canary mailbox) would catch the next HTT-52-class incident before it goes wide? Documented as a hard requirement in this ADR's Migration plan section | Medium — this is a permanent architectural trade. Mitigated, not eliminated, by the quarterly digest and the per-capability detection-channel requirement |

**Compensating controls (status as of this commit):**

1. **Quarterly "your DCE access" digest mail** — promoted from follow-on to **blocking Acceptance Criterion** per the EoP addendum. Tracked as bd `DeltaSetup-6rc`.
2. **Quarterly empirical canary** — promoted from one-time to recurring per the Supply-chain Tampering supplemental threat. Tracked as bd `DeltaSetup-j3c` (initial) + a recurring follow-on bd to be filed.
3. **Annual review of Microsoft Learn URLs** cited in the playbook — Microsoft revs the docs quarterly and we need to catch behavioral changes.
4. **`security-auditor` agent / human security review engagement** — open dependency. release-gate-arbiter co-signed STRIDE as proxy; this is sufficient for ADR-acceptance but not for production launch-mode invocation against real users.

### STRIDE co-sign signature (release-gate-arbiter, 2026-05-16)

> **STRIDE co-sign:** `release-gate-arbiter-bc138a` on 2026-05-16, scope = full table (6 core rows + 4 supplemental threats), with **5 addenda folded above** (Spoofing × 1, Tampering × 3, Repudiation × 1, DoS × 1, EoP × 1) and **4 supplemental threats added** (supply-chain Tampering, TOCTOU on launch marker, bootstrap Step 9 backup, notification-as-detection-channel). Acting as Security Auditor proxy; this swarm has no dedicated `security-auditor` agent and a full ASVS L2 review remains an open dependency before any production launch-mode invocation that actually sends mail to real HTT users. Per the ADR-011 acceptance criteria below, status may flip Proposed → Accepted once (a) `tests/architecture/test_notification_suppression.py` is green in CI (verified passing locally, 124/124 architecture tests including 7/7 ADR-011, 0.20s), (b) the quarterly access-digest workflow is added to Acceptance Criteria (**done in this commit**), and (c) the launch-notifications.yml workflow + CODEOWNERS + cert-lifecycle controls land (tracked under bd `DeltaSetup-17i`).

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

All items below MUST be satisfied before status flips Proposed → Accepted. Items folded from the release-gate-arbiter STRIDE co-sign are tagged `[arbiter]`.

### Code + CI gates
- [x] `tests/architecture/test_notification_suppression.py` passes (7/7 fitness tests; 124/124 architecture suite; verified 2026-05-16, 0.20s)
- [x] `PROVISIONING_GLOBS` covers `.{ps1,py,sh}` × all plausible directory roots `[arbiter Tampering #1]`
- [x] `.github/CODEOWNERS` lists `tests/architecture/`, ADR files, workflow files with two-reviewer required approval `[arbiter Tampering #3]`
- [ ] Runtime-constructed body defense: fitness test extended to require explicit literal OR `# ADR-011-SUPPRESSION-VERIFIED:` waiver for any `Invoke-RestMethod`/`requests` POST to `/groups`, `/invitations`, `/invite` `[arbiter Tampering #2]`
- [ ] PnP / Graph module versions pinned (`#Requires` / `requirements.txt`) and signature-verified in `bootstrap.sh` Step 9 `[arbiter supply-chain]`

### Tenant-side rollout (bd `DeltaSetup-17i`)
- [ ] `bootstrap.sh` step 9 completes without warnings on a fresh DCE tenant
- [ ] `scripts/remediate-group-welcome.ps1 -Mode scaffold` reports 0 groups with welcomes enabled AND writes pre-image to `out/welcome-mail-preimage-<runid>.json` `[arbiter bootstrap-backup]`
- [ ] `scripts/restore-group-welcome.ps1` exists with documented per-group rollback `[arbiter bootstrap-backup]`
- [ ] `provisioning-mode.log` artifact is produced on every `provision-teams.yml` / `deploy-prod.yml` run; retention pinned to plan-tier-appropriate days with off-platform mirror if 365+ required `[arbiter Repudiation]`
- [ ] `launch-notifications.yml` exists, `workflow_dispatch`-only, gated by `launch` GitHub Environment configured with **≥2 distinct human reviewers** and author≠approver enforcement `[arbiter DoS]`
- [ ] Launch script enforces hard cap N=500 recipients, Exchange-throttle ≤30 msg/min/mailbox, SHA-256 of recipient manifest echoed in approval prompt `[arbiter DoS]`
- [ ] Launch script asserts CI-only signed `LAUNCH_APPROVAL_JWT` (15-min TTL); refuses local invocation `[arbiter TOCTOU]`
- [ ] Cert lifecycle controls in place: rotation ≤90d, OIDC-federated or HSM-backed key storage, out-of-hours / out-of-IP alerting `[arbiter Spoofing]`
- [ ] DCE tenant SKU cited in playbook §8.1 (drives UAL retention claim — 180d on E3, 365d on E5) `[arbiter Repudiation]`

### User-facing controls
- [ ] **Quarterly "your DCE access" digest workflow exists** (`launch` mode), has run at least once against the DCE tenant in dry-run, and recipient-coverage test confirms 100% of `User` objects with non-default group membership receive a digest entry. **Blocking AC — promoted from follow-on per `[arbiter EoP]`.** Tracked as bd `DeltaSetup-6rc`
- [ ] Empirical canaries executed: xtsync silence + channel moderation notification behavior (bd `DeltaSetup-j3c`)
- [ ] Recurring (quarterly) end-to-end canary scheduled (xtsync invitation + Message Trace check) — defends against PnP/Graph behavioral drift `[arbiter supply-chain]`

### Incident closure
- [ ] HTT-52 apology mail-merge sent and acknowledged (bd `DeltaSetup-377`); evidence retained 7 years
- [ ] Message Trace forensics complete before 2026-05-22 deadline (bd `DeltaSetup-377`)

### Governance
- [x] Release Gate Arbiter has co-signed the STRIDE table (signature in §STRIDE security analysis, 2026-05-16)
- [ ] Dedicated `security-auditor` agent or human Tier-1 security review engaged before first production launch-mode invocation against real users `[arbiter process gap]`
- [ ] Per-capability "detection-channel of last resort" requirement documented for any new provisioning surface added under ADR-011 `[arbiter detection-channel]`

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
