# Jenna's DCE operator runbook (DRAFT — Phase 4 prep)

**Status:** Draft. Will migrate to `Delta-Crown-Org/dce-sharepoint/docs/operators/jenna-runbook.md` when the `dce-sharepoint` repo lands (gated on `DeltaSetup-emj` → `DeltaSetup-jn4`).
**Audience:** Jenna, after Tyler is no longer the only deploy operator.
**Prereq:** You have the `dce-deploy` GitHub repo write access, Microsoft 365 admin role in the DCE tenant, and the operator-cert thumbprint stored in 1Password.
**Reading time:** ~30 min cover-to-cover. **First-run mode:** read § 1 + § 2 + § 3 only; refer back to the rest as you hit each scenario.

> **🔴 Critical rule before you do ANYTHING:** Read ADR-011 (`docs/sharepoint-pnp-spec/decisions/011-notification-suppression-by-default.md`). Every script you run defaults to **scaffold mode** (no user notifications). This is on purpose. If you find yourself thinking "but I want to tell the users," that's a separate, audited workflow — never a side-effect of a deploy.

---

## 1. The five things you do

This is the whole job, ranked by frequency:

| # | Workflow | Frequency | Section |
|---|----------|-----------|---------|
| 1 | Triage a new **site request** (someone wants a new spoke site) | ~1/week initially, ~3/week post-launch | § 4 |
| 2 | Ship a **template change** to prod (someone edited a PnP template, page, or theme) | ~2-5/week | § 5 |
| 3 | **Roll back** a bad deploy | ~1/quarter (hopefully) | § 6 |
| 4 | **Permission-break review** when the weekly audit job reports drift | ~1/week | § 7 |
| 5 | **Audit triage** when the cron reports unexpected drift | rare; ~1/month | § 8 |

You do NOT directly:
- Create new M365 Groups by hand (the pipeline does it; you approve the PR)
- Click around in the SharePoint admin center (everything is PnP-templated)
- Send user notifications (those go through the `launch-notifications.yml` workflow with an explicit human approver — see § 9)

---

## 2. The mental model

DCE is a **hub-and-spoke** SharePoint setup with everything driven from one git repo:

```
GitHub (dce-sharepoint repo)
       │
       │ GitHub Actions (cert-based auth, ADR-007)
       ▼
SharePoint Online (deltacrown.sharepoint.com)
       │
       ├── /sites/dce-hub   (the hub — DCE-branded landing)
       ├── /sites/CrownConnection  (owners-only spoke)
       └── /sites/<future-spokes>  (provisioned via this runbook § 4)
```

Three "tiers" of change reach prod:

- **Light** — page text, web part config: edit in PR, auto-deploys.
- **Medium** — PnP template changes (new page, theme, audience targeting): edit in PR, auto-deploys after a fitness-function pass.
- **Heavy** — SPFx code changes (App Customizer, custom web parts): edit in PR, builds and version-bumps the `.sppkg`, deploys to app catalog, you approve the prod step.

You are mostly in the **Medium** lane.

---

## 3. Where everything is

| Thing | Location |
|---|---|
| Spec pack (the "why") | https://github.com/Delta-Crown-Org/DeltaSetup/tree/gh-pages/docs/sharepoint-pnp-spec |
| Deploy repo (the "what") | https://github.com/Delta-Crown-Org/dce-sharepoint (created in Phase 1) |
| Issue tracker (`bd`) | This repo, command-line. `bd ready` to see your queue. |
| CI runs | https://github.com/Delta-Crown-Org/dce-sharepoint/actions |
| Permission audit results | Each weekly run uploads `permission-audit.csv` as a workflow artifact, retained 365 days. |
| Tenant admin center | https://deltacrown-admin.sharepoint.com |
| Entra admin (rare) | https://entra.microsoft.com (use the tenant switcher → DCE) |

**One-Password / Bitwarden / 1Password vault:** `DCE Operator` collection. Contains: cert thumbprint, fallback admin credentials, support contact list. **Never paste these into a chat or commit.**

---

## 4. Workflow 1 — Triage a new site request

**Trigger:** A `bd ready` issue labeled `site-request` appears, created by the intake form (see § companion doc `site-request-intake-DRAFT.md`).

**Steps:**

1. `bd show <issue-id>` — read the request.
2. Check the requested name against `docs/sharepoint-pnp-spec/02-identity-audience.md` § "Group naming convention." If the name doesn't conform: reply on the bd with a corrected name, status → `in_progress` while you wait.
3. Check the requested audience against the role taxonomy (same chapter). If it's a new audience NOT in the taxonomy: this is an ADR-level question. Escalate to Tyler with `bd assign <id> tyler.granlund`.
4. If the request is straightforward (existing role, conforming name):
   - Branch off `main` in `dce-sharepoint`: `git checkout -b spoke/<short-name>`.
   - Run `./scripts/scaffold-spoke.sh <short-name> "<DisplayName>" "<short description>"`. This emits a PnP template + permission stub + audience config under `spokes/<short-name>/`.
   - **VERIFY** the generated `spokes/<short-name>/template.xml` contains `<ResourceBehaviorOptions>WelcomeEmailDisabled,HideGroupInOutlook</ResourceBehaviorOptions>` (ADR-011 invariant — the fitness function will catch you if you don't, but eyes-on-target is cheap insurance).
   - Open a PR with title `feat(spoke): scaffold <short-name>` and link the bd issue.
5. Once CI is green, merge. The `deploy-prod.yml` workflow runs and provisions the spoke **in scaffold mode** — no users get notified.
6. Update the bd: status → `closed`, `--reason "Provisioned at <url>; launch-mode notification pending Comms sign-off"`. Tell Tyler the spoke is up.

**Failure modes:**

- **PnP template apply fails partway** → workflow logs show which step. Most commonly: a duplicate `mailNickname`. Pick a new short-name and re-run. The partially-created group can be soft-deleted from Entra recycle bin if it's reachable: see `docs/sharepoint-pnp-spec/12-implementation-plan.md` § Rollback matrix row "M365 Group / Team creation."
- **Audience targeting doesn't fire** → check that the audience group exists in Entra AND that `02-identity-audience.md` lists it in the role taxonomy. If both, file a bd on the audience targeting; it's not your debug.

**Escalation:** anything that isn't on this list = ping Tyler.

---

## 5. Workflow 2 — Ship a template change to prod

**Trigger:** A contributor (could be Tyler, could be a future SPFx dev) opens a PR with changes under `templates/`, `pages/`, or `themes/`.

**Steps:**

1. Review the PR. Check that:
   - The change references a spec-pack chapter or bd in the PR body.
   - Fitness-function tests are green: `tests/architecture/`, especially `test_notification_suppression.py`.
   - The change doesn't reintroduce any pattern from the ADR-011 forbidden list (the fitness function catches this; but eyes-on is cheap).
2. If the PR is `light` or `medium` tier (no SPFx code), approve. Merge.
3. The `deploy-prod.yml` workflow runs automatically on merge. **Watch the run** in GitHub Actions for ~5 min.
4. If green: pop a comment on the bd that's linked from the PR, status → `closed`.
5. If red: read the failed step. Most failures are one of:
   - **PnP apply timeout** → re-run the workflow. ~80% of these are transient throttling.
   - **Fitness-function failure** → the PR shouldn't have been merged. Revert the merge commit (`git revert -m 1 <sha>`), re-open the PR with the fix.
   - **Cert auth failure** → see `docs/sharepoint-pnp-spec/10-runbooks.md` Runbook 8.

**Failure modes:**

- **Production site shows stale content after deploy succeeded** → CDN cache. Wait 5 min, hard-refresh, then check. If still stale: see § 6 (rollback).
- **Workflow appears to succeed but no change is visible** → check the workflow artifact `provisioning-mode.log`. If it says `PROVISIONING-MODE: scaffold` you're good. If it logged `Skipped: no diff` that means the PnP engine determined the change was a no-op; that's a content/config problem in the PR.

**Escalation:** any failure not on the above list = ping Tyler.

---

## 6. Workflow 3 — Roll back a bad deploy

**Trigger:** You (or a user) notice that something Bad shipped — wrong content, broken layout, missing audience, etc.

**Steps:**

1. **Do not panic.** Rollback is fast (~10 min, see `docs/sharepoint-pnp-spec/12-implementation-plan.md` § Rollback matrix).
2. Find the last-known-good commit:
   ```bash
   git log --oneline main | head -20
   ```
   Identify the commit BEFORE the bad one.
3. Trigger the rollback workflow manually:
   - GitHub Actions → `deploy-prod.yml` → "Run workflow" → input the known-good SHA.
4. Watch the run. It will re-apply the PnP template from that SHA. ~10 min.
5. Verify on the affected site. Hard-refresh.
6. File a `bd` for the root cause analysis. Include the bad SHA, the rollback SHA, what broke, and what the spec-pack defense should be (a new fitness function, an ADR addendum, a runbook addition).

**Failure modes:**

- **Rollback fails too** → you have two bad versions. Pick a third commit further back. If the failure is at the PnP engine level (cert, throttling): see § 5 failure modes.
- **Rollback ships but problem persists** → the issue isn't in the template. Check whether it's a permission grant (see § 7) or an SPFx version mismatch (escalate to Tyler).

**Always file a bd after a rollback.** This is the adaptation pillar — every rollback teaches us something the spec should encode.

---

## 7. Workflow 4 — Permission-break review

**Trigger:** Monday morning. The weekly `permission-audit.yml` cron emits a workflow artifact `permission-audit.csv`. If the file differs from `reference/permission-breaks.csv` (the allow-list), the workflow flags it.

**Steps:**

1. Open the workflow run (you'll get an email; if not, https://github.com/Delta-Crown-Org/dce-sharepoint/actions and find the latest `permission-audit` run).
2. Download `permission-audit.csv`. Compare to `reference/permission-breaks.csv`.
3. For each unexpected break:
   - **Was it intentional?** → add it to `reference/permission-breaks.csv`, PR, merge. Drift acknowledged.
   - **Was it NOT intentional?** → this is drift. Remove via the procedure in `docs/sharepoint-pnp-spec/10-runbooks.md` Runbook 5.
4. Verify the next weekly audit run is clean.

**Failure modes:**

- **You can't tell if a break was intentional** → ping Tyler with the row from the CSV. Don't guess; permission decisions belong in writing.

---

## 8. Workflow 5 — Audit triage (cron-reported drift)

**Trigger:** Less common — a different cron job (e.g., `notification-suppression-audit.yml`, which runs ADR-011 fitness functions weekly) reports drift outside the permission scope.

**Steps:**

1. Read the workflow log.
2. The drift is usually one of: a new script was added without the `-Mode` parameter; an existing script had `WelcomeEmailDisabled` removed in a careless edit; a new M365 Group was created in the tenant outside the pipeline.
3. For pipeline-side drift (the first two): revert the offending commit, re-PR with the fix.
4. For tenant-side drift (a group created out-of-band): identify who created it (`Get-MgGroup -GroupId <id> | Select CreatedDateTime, Creator`). Either bring it into the spec by adding the templated equivalent, or have the creator delete it.

**Escalation:** anything that looks like a security event (unexpected admin role assignment, unknown app registration, foreign IP in the sign-in logs) = ping Tyler **and** open a P0 bd labeled `security,incident`.

---

## 9. Notifications (ADR-011 — read this twice)

**You will NEVER manually send a notification to users.** Even if a PM asks. Even if Tyler asks.

Notifications go through ONE path only:

1. PM curates the email body in a `bd` issue (`launch-notification-request`).
2. PM approves the recipient cohort in the bd.
3. You trigger the `launch-notifications.yml` GitHub Actions workflow with the cohort name as input.
4. The workflow puts the request in a queue that requires a **second human approver** (the GitHub "launch" environment gate).
5. That approver (NOT you, unless you and the PM swap roles) clicks Approve in GitHub.
6. The workflow sends. Recipient manifest is uploaded as a 7-year-retention artifact.

If anyone bypasses this — pings users in Teams about a new feature, emails them out-of-band, etc. — that's a separate conversation. Your job is to refuse to bypass the workflow.

---

## 10. The handoff checkpoint

You are "fully handed off" when you have:

- [ ] Triaged 3 site requests start-to-finish unaided
- [ ] Shipped 5 template-change PRs start-to-finish unaided
- [ ] Executed at least one rollback (deliberate, on a test site) unaided
- [ ] Reviewed at least 2 weekly permission audits and either acknowledged or remediated drift
- [ ] Sent (with the second-approver flow) at least one launch-mode notification

Until then, Tyler observes every workflow. After, Tyler is on-call only for escalations.

---

## Open questions (resolve before Phase 4 closes)

1. Where does the `bd` triage queue live for Jenna? Same DeltaSetup repo, or split?
2. What's the on-call escalation path when Tyler is unavailable? Megan as backup?
3. Does Jenna get her own deploy cert (separate from the `dce-deploy` app cert) for audit-trail differentiation, or share Tyler's? See ADR-007.
4. Phase 4 timing relative to a3d (MTO decision) — if MTO joins, some Workflow 4 behaviors change because synced users are Members not Guests.

These are tracked in the `bd` issue this runbook closes (`DeltaSetup-x11`) until Phase 4 resolves them.
