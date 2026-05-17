# DCE SharePoint Hub-and-Spoke — 60-Day Execution Plan

**Date:** 2026-05-16
**Owner:** Tyler Granlund
**Planner:** planning-agent (delivered to Richard, code-puppy-1bc20e)
**Pack Leader:** Richard 🐶 (orchestrates agents + aligns bds against this plan)
**Scope:** Phases 0 → 4, ending ~2026-07-15
**Companion docs (don't re-read; link only):**
- Day-by-day sprint detail: [`12-implementation-plan.md`](./12-implementation-plan.md)
- Sprint-1 entry point: [`SPRINT-1-KICKOFF.md`](./SPRINT-1-KICKOFF.md)
- Decision log: [`decisions/`](./decisions/) (9 ADRs; 006/008/009 PROPOSED)
- Mockup + CI/CD seed: [`../../dce-mockup/`](../../dce-mockup/)
- Audit trail: [`../../ORACLE-AUDIT-2026-05-16.md`](../../ORACLE-AUDIT-2026-05-16.md)

---

## TL;DR

| Phase | North-Star Outcome | Duration | Lands |
|---|---|---|---|
| **0 — Unblock** | ADR-006 cosigned, Fluent v8/v9 locked, doc-debt cleared, corp-sync group propagating | Week 1 | 2026-05-22 |
| **1 — Foundation** | `dce-sharepoint` repo exists, CI green on empty PR, dev site provisioned with DCE theme | Weeks 2-3 | 2026-06-05 |
| **2 — DCE Hub MVP** | Hub home page live on dev with 7 sections + audience targeting working for 2 web parts | Weeks 4-5 | 2026-06-19 |
| **3 — Crown Connection + Prod** | Crown Connection re-themed in prod, hub association live, R3/R6 audience split working | Weeks 6-7 | 2026-07-03 |
| **4 — Operational handoff** | Permission audit cron green for 2 consecutive weeks, Jenna can run the system unaided | Weeks 8-9 | 2026-07-15 |

**Critical path (11 links, ~38 working days):**

> ADR-006 cosign → ADR-010 Fluent lock → repo creation → app-reg + cert → dev site provision → Style Dictionary build → hub home template → audience M365 groups → CI gates green → Crown Connection deploy → permission-audit baseline → Jenna handoff

**Confidence-pillar coverage:**
- **Security:** Phase 0 (cosign), Phase 1 (app-reg, cert, secrets), Phase 4 (audit cron)
- **Stability:** Phase 1 (CI gates), Phase 2 (template idempotency), Phase 4 (cron + runbooks)
- **Scalability:** Phase 2 (token system), Phase 3 (audience model = cross-brand pattern)
- **Adaptation:** Phase 0 (rollback matrix), Phase 3 (hub-spoke template reuse), Phase 4 (operator handoff)

---

## Priority pushback (bds re-graded before execution)

| Bd | Current | Recommended | Why |
|---|---|---|---|
| **DeltaSetup-303** (Heft alignment) | P2 | **P1** | Known spec defect. The moment anyone reads chapter 06 or 07 to start `emj`, they'll hit conflicting YAML. Cheap to fix now, expensive at sprint-1 day 4. |
| **DeltaSetup-au3** (corp-sync group) | P2 | **P1** | 24h Entra group propagation means "early" is "now." If we don't create it in week 1, audience targeting in Phase 2 day 6 slips. |
| **DeltaSetup-a6a** (AADSTS500213 guardrail) | P2 | **P2 — but bundle** | Priority is right, but treat it as a free win batched into the Phase 0 doc-debt PR with `bnf`. Same agent, same review cycle. |
| **DeltaSetup-4ay** (Teams read-context) | P2 | **P2 — promote to filler lane** | Correctly P2, but it's the ideal "do-now-while-waiting-on-cosign" work. Park it as the named back-burner for any human gate. |
| **DeltaSetup-7bm** (Fluent lock) | P1 | **P1 — but rename deliverable** | The bd says "lock + write ADR-010." It's not done until ADR-010 is `Status: Accepted`. Update bd description so success is unambiguous. |

Everything else is correctly graded.

---

## Phase 0 — Unblock (Week 1, 2026-05-18 → 2026-05-22)

**North star:** When this phase is done, every human-gated decision that blocks code generation has a resolution committed to the spec pack, and the agent fleet can run end-to-end without stopping for a human.

### Bds in this phase
1. **DeltaSetup-jn4** (P1) — Cosign ADR-006 final with Security Auditor. **Tyler + Security Auditor only.**
2. **DeltaSetup-7bm** (P1) — Fluent UI v8/v9 lock + ADR-010. Depends on `jn4`.
3. **DeltaSetup-303** (P1, upgraded) — Heft alignment in spec YAML. Depends on `jn4` (final tooling decision).
4. **DeltaSetup-bnf** (P1) — Rollback matrix appended to 12-implementation-plan.md.
5. **DeltaSetup-a6a** (P2) — AADSTS500213 guardrail paragraph in 02-identity-audience.md.
6. **DeltaSetup-au3** (P1, upgraded) — Create `DCE-HTT-Corporate-Sync` dynamic group.

### Parallel lanes
- **Lane A (human, serial):** `jn4` → `7bm` → `303` (cosign drives the tooling/version calls)
- **Lane B (agent, parallel from day 1):** `bnf` + `a6a` in one PR (doc-only, no blockers)
- **Lane C (Tyler in Entra portal, fire-and-forget):** `au3` — do this Monday morning so the 24h sync clock starts immediately

### Do-now-while-waiting lane
- **DeltaSetup-4ay** (Teams read-context blocker) — if cosign drags past Wednesday, agents start the Teams inventory work. It's audience-model-adjacent and unblocks Phase 3's audience tests.

### Human touchpoints (the bottlenecks)
- 🧑 **Security Auditor sign-off on ADR-006** — Tyler must schedule. Drop-dead Wed 5/20 or Phase 1 slips.
- 🧑 **Tyler in Entra portal** for `au3` — 15 min of clicking, but only Tyler has rights.
- 🧑 **Tyler accepts ADR-008** after group creation propagates.

### Phase exit gate
- [ ] ADR-006 `Status: Accepted` (not `Proposed`)
- [ ] ADR-010 exists, `Status: Accepted`, locks Fluent UI version
- [ ] ADR-008 `Status: Accepted`, group visible in Entra
- [ ] Chapter 07 + chapter 06 YAML samples reference Heft, not gulp
- [ ] 12-implementation-plan.md § "Rollback matrix" exists with per-day rollback
- [ ] 02-identity-audience.md mentions AADSTS500213 in the cross-tenant guardrails section

### Risk + rollback
- **Worst case:** Security Auditor pushes back on ADR-006, wants the SharePoint code inside this repo instead of `Delta-Crown-Org/dce-sharepoint`. **Rollback:** Cheap. Update `emj` description, treat `dce-mockup/ci-cd/` as the in-place seed, retarget CI workflows to the `gh-pages` branch carefully. Phase 1 starts 2 days later.

### Agent assignments
- `bnf` + `a6a` → **code-puppy** (doc edits)
- `303` → **code-puppy** after `jn4` clears
- `7bm` → **solutions-architect** drafts ADR-010, Tyler ratifies

---

## Phase 1 — Foundation (Weeks 2-3, 2026-05-25 → 2026-06-05)

**North star:** When this phase is done, `Delta-Crown-Org/dce-sharepoint` is a real repo with green CI on a trivial PR, an Entra app identity that can `Connect-PnPOnline`, and a dev site at `/sites/dce-hub-dev` rendering the DCE theme. Zero content yet — just the rails.

### Bds in this phase
1. **DeltaSetup-emj** (P1) — Create repo + seed from `dce-mockup/ci-cd/`. Depends on Phase 0 complete.
2. **DeltaSetup-ebk** (P1, partial) — Tokens + Brand Center + theme. Spans Phases 1 and 2; the "build + apply theme" piece lands here.
3. **DeltaSetup-7al** (P2, partial) — CI/CD pipeline (PR validation + deploy-dev). Full prod-deploy story lands in Phase 3.

### Parallel lanes
- **Lane A (Tyler + agent, serial):** `emj` repo creation → bootstrap.sh runs → secrets populated → first PR green
- **Lane B (agent, in parallel after Lane A day 2):** Style Dictionary build pipeline → `dce-tokens.css` and `dce-theme.json` artifacts
- **Lane C (agent, in parallel from day 1):** Adapt `dce-mockup/tests/` 12 fitness functions into the new repo's `tests/` so CI has something to validate from day 1

### Maps to `12-implementation-plan.md`
- Phase 1 = Days 1-3 + Day 5 of that document. Don't re-plan; just execute it.

### Human touchpoints
- 🧑 **Tyler creates the GitHub repo** (5 min) and the Entra app registration (Day 2 of the day-by-day plan). Both are non-delegable.
- 🧑 **Tyler approves the `prod` GitHub Environment** so deploys gate on his review.

### Do-now-while-waiting lane
- If Tyler is heads-down on the Entra app reg, agents continue `4ay` (Teams inventory) or start drafting `templates/hub/001-initial-provisioning.xml` against a local schema.

### Phase exit gate
- [ ] `Delta-Crown-Org/dce-sharepoint` exists, AGENTS.md committed, README links back to this spec pack
- [ ] `npm run build:tokens` produces `dist/css/dce-tokens.css` + `dist/sharepoint/theme.json`
- [ ] GitHub Action successfully runs `Connect-PnPOnline` against dev site (smoke job)
- [ ] `https://deltacrown.sharepoint.com/sites/dce-hub-dev` loads with teal/gold theme
- [ ] All 12 fitness tests (ported from `dce-mockup/tests/`) pass in CI
- [ ] Trivial PR (README edit) merges through `pr-validation.yml` green

### Risk + rollback
- **Worst case (high impact, low prob):** Brand Center API rejects the generated `theme.json`. **Rollback:** Per `12-implementation-plan.md` § Risks — fall back to Microsoft's reference palette, defer custom typography to SPFx Application Customizer in Phase 5+. Phase 2 still goes ahead with default Fluent typography.
- **Worst case (cert-auth):** Cert-based auth fails from GitHub Actions runners. **Rollback:** Document, then promote the OIDC federated identity item (new bd suggested below) to P1 mid-sprint.

### Agent assignments
- `emj` repo creation → **code-puppy** (file copy + adapt)
- `ebk` token build → **code-puppy**
- `7al` workflow seed → **code-puppy** → **solutions-architect** reviews secrets handling

---

## Phase 2 — DCE Hub MVP (Weeks 4-5, 2026-06-08 → 2026-06-19)

**North star:** When this phase is done, the dev hub home page renders 7 audience-aware sections that visually match `dce-mockup/index.html` and `deltacrown.com`, and at least 2 web parts hide/show correctly based on R1-R4 group membership.

### Bds in this phase
1. **DeltaSetup-8p5** (P1) — DCE Hub home page build. The headline deliverable.
2. **DeltaSetup-ebk** (P1, completion) — Brand Center applied + verified.
3. **DeltaSetup-7al** (P2, continuation) — CI quality gates (Playwright + pa11y-ci + axe) wired up.

### Parallel lanes
- **Lane A (serial):** Home-page template authoring (Day 4 of impl plan) → DCE-branded styling (Day 5) → audience targeting prototype (Day 6)
- **Lane B (parallel from week 4):** Quality gates wiring (Day 7) — independent of template work until they meet at the dev deploy
- **Lane C (parallel, agent-only):** Port the `audience-targeting.js` logic from `dce-mockup/js/` into the SPFx `useAudience` hook in `spfx-skeleton/`

### Human touchpoints
- 🧑 **Tyler creates the 4 M365 groups** (`DCE-Franchise-Owners`, `DCE-Managers`, `DCE-AllStaff`, `DCE-Franchisor-Leadership`) on Day 6 if not already auto-provisioned by `au3` infra. ~30 min in Entra.
- 🧑 **3 test users** for audience verification — Tyler picks them; Megan as backup global admin.

### Do-now-while-waiting lane
- Cross-brand owner-site inventory dry-run (precursor to `rod`) — read-only audit, no writes. Builds the inventory we'll need in sprint-3.

### Phase exit gate
- [ ] `/sites/dce-hub-dev` home page shows 7 sections in spec order
- [ ] Side-by-side with `deltacrown.com`: same brand identity (Tyler eyeball test)
- [ ] 2 audience-targeted web parts proven with 3 test users (R1, R3, R5 represented)
- [ ] `pr-validation.yml` runs Playwright + pa11y + axe — all green
- [ ] First "real" PR (template change) deploys to dev via `deploy-dev.yml` automatically
- [ ] Visual regression baseline captured for sprint-2 reference

### Risk + rollback
- **Worst case:** Audience targeting unreliable for cross-tenant Members. **Rollback:** Per ADR-006 / chapter 05 — fall back to permission breaks (Crown-Connection-style owner-only library) as the security backstop. Audience targeting downgrades from "permission enforcement" to "UX courtesy" — same as Microsoft's own posture.
- **Worst case (template):** PnP provisioning silently drops a section. **Rollback:** All section edits are idempotent template-apply; re-run with `-ClearNavigation` flag, restore prior template version from git.

### Agent assignments
- `8p5` template → **code-puppy**
- Styling → **code-puppy** → **experience-architect** for visual QA
- Audience tests → **qa-kitten** with real browser
- Quality-gate wiring → **code-puppy** → **solutions-architect** for the secrets review

---

## Phase 3 — Crown Connection + Prod (Weeks 6-7, 2026-06-22 → 2026-07-03)

**North star:** When this phase is done, Crown Connection in prod has the new branded home page, is associated to the DCE Hub, and HTT corporate users (R6) see only what they should see — verified with a real HTT test user, not a mock.

### Bds in this phase
1. **DeltaSetup-b59** (P2) — Crown Connection home page build.
2. **DeltaSetup-7al** (P2, completion) — Prod-deploy pipeline + environment approval gates.

### Parallel lanes
- **Lane A (serial, high-stakes):** Crown Connection template (Day 8 of impl plan) → coordinate-with-Kristin-and-Jenna comms → prod apply → smoke verify
- **Lane B (parallel):** Hub-spoke association wiring (one PnP cmdlet but needs verification against navigation, search, branding inheritance)
- **Lane C (parallel):** R3 vs R6 audience test matrix — needs real HTT corporate test user (cross-tenant invite already documented in `tools/`)

### Human touchpoints
- 🧑 **Tyler + Kristin + Jenna comms window** — Crown Connection is the live owner-facing site. Schedule a defined deploy window (weekday morning, low-traffic) and announce to franchise owners 48h ahead.
- 🧑 **Tyler approves the `prod` GitHub Environment** for each deploy.
- 🧑 **Jenna shadow-watches** the first prod deploy — start of the handoff curve.

### Do-now-while-waiting lane
- Start drafting Phase 4 deliverables: permission audit baselining, Jenna runbook outline.

### Phase exit gate
- [ ] Crown Connection home page live in prod with new theme
- [ ] Hub-spoke association confirmed: navigation inheritance + hub search scope working
- [ ] R3 (owner) test user sees owner-only tile; R6 (HTT corp) test user does not
- [ ] No regressions reported by Kristin or Jenna within 48h post-deploy
- [ ] Prod-deploy workflow has run end-to-end ≥2 times successfully

### Risk + rollback
- **Worst case:** Crown Connection home page breaks owner workflow during business hours. **Rollback:** PnP template-apply is non-destructive for existing content; revert is `Invoke-PnPSiteTemplate` with the prior version (committed in git). RTO < 30 min if Tyler is at a keyboard.
- **Worst case (hub association):** Hub theme overrides Crown Connection's brand inconsistently. **Rollback:** `Remove-PnPHubSiteAssociation`, re-theme manually. Documented in chapter 10.

### Agent assignments
- `b59` → **code-puppy**
- Prod-deploy gate → **solutions-architect** + **release-gate-arbiter** (this is the highest-blast-radius automation in the system)
- Audience tests → **qa-kitten** with real HTT user

---

## Phase 4 — Operational Handoff (Weeks 8-9, 2026-07-06 → 2026-07-15)

**North star:** When this phase is done, the permission audit cron has produced 2 consecutive weekly reports with zero unexpected drift, Jenna has executed at least one PR-to-prod deploy end-to-end without Tyler in the loop, and a runbook exists for every operational action.

### Bds in this phase
1. **Permission audit cron going live** — covered partly by `7al`, but the *baseline + first 2 green runs* is the actual milestone.
2. **Sprint review + handoff** — Day 10 of impl plan.
3. **NEW bds to be filed** (see § "New bds to create" below):
   - Jenna operator runbook
   - Observability / deploy-failure alerting
   - MTO membership decision doc

### Parallel lanes
- **Lane A (serial):** Permission audit Day-9 setup → first run + baseline → week-1 cron green → week-2 cron green
- **Lane B (parallel):** Jenna runbook authoring + dry-run with Jenna driving
- **Lane C (parallel):** Sprint-2 grooming — file all sprint-2 candidates as bds with clear acceptance criteria

### Human touchpoints
- 🧑 **Jenna's first solo deploy** — milestone moment. Tyler observes, doesn't intervene.
- 🧑 **Sprint review** — Tyler, Kristin, Jenna; recorded demo.

### Phase exit gate
- [ ] Permission audit CSV exists at `reference/permission-breaks-baseline.csv`
- [ ] 2 consecutive weekly cron runs report 0 unexpected drift
- [ ] Jenna runbook covers: site request intake, template change, deploy, rollback, permission-break review, audit triage
- [ ] Jenna has done one full PR-to-prod loop unaided (Tyler observed, didn't touch keyboard)
- [ ] Sprint-1 retrospective doc committed to spec pack
- [ ] All sprint-2 candidates from `SPRINT-1-KICKOFF.md` § 6 are filed as bds with acceptance criteria

### Risk + rollback
- **Worst case:** Audit cron reports drift but the cause is benign (e.g., Crown Connection owner-only library — known break). **Rollback:** That's why `reference/permission-breaks.csv` exists — the cron compares against the allowlist. Mitigation is documentation, not code.
- **Worst case (handoff):** Jenna's solo deploy fails. **Mitigation:** That's the whole point of the dry-run with Tyler present. Real failure mode would be Jenna deploying solo after Tyler signs off — runbook must have explicit rollback steps.

---

## 60-day calendar (week granularity)

| Week | Dates | Phase | Headline deliverable | Human gate |
|---|---|---|---|---|
| 1 | May 18-22 | 0 | ADR-006 cosigned, ADR-010 written, doc-debt PR merged, corp-sync group propagating | 🧑 Security Auditor session |
| 2 | May 25-29 | 1 | `dce-sharepoint` repo live, bootstrap.sh run, secrets populated | 🧑 Tyler: repo create + Entra app |
| 3 | Jun 1-5 | 1 | Dev site provisioned, DCE theme applied, fitness tests green in CI | 🧑 Tyler: `prod` env approval setup |
| 4 | Jun 8-12 | 2 | Hub home page template applied, 7 sections rendering | — |
| 5 | Jun 15-19 | 2 | Audience targeting working for 2 web parts, quality gates green | 🧑 Tyler: M365 groups + 3 test users |
| 6 | Jun 22-26 | 3 | Crown Connection template authored, hub-spoke association tested in dev | 🧑 Tyler + Kristin + Jenna comms |
| 7 | Jun 29-Jul 3 | 3 | Crown Connection live in prod, R3/R6 audience verified with real HTT user | 🧑 Defined prod deploy window |
| 8 | Jul 6-10 | 4 | Permission audit cron live, first weekly report green | 🧑 Jenna shadow session |
| 9 | Jul 13-17 | 4 | Sprint-1 retro, Jenna solo deploy proven, sprint-2 bds filed | 🧑 Sprint review meeting |

---

## New bds to create (Pack Leader files these)

Listed in priority order.

### P1 — file before Phase 1 starts
1. **ADR-010: Fluent UI version lock** — explicit deliverable from `7bm`. File as separate bd so success criterion is "ADR-010 `Status: Accepted`."
2. **Brand Center `theme.json` golden-image fitness test** — there's currently nothing in `dce-mockup/tests/` that proves the generated `theme.json` is a valid SharePoint theme. Add a snapshot test before Phase 1 day 5.

### P2 — file during Phase 1, execute in Phase 4
3. **Jenna operator runbook** — distinct from `docs/onboarding/`. Audience: Jenna, after Tyler is no longer the only deploy operator. Lives in the new `dce-sharepoint` repo, not this one.
4. **Observability: deploy-failure alerting + audit-drift alerting** — the cron from `7al` produces CSVs, but nothing pages anyone if a run fails. Need at minimum: GitHub Actions failure → Tyler email, audit-drift non-zero → Tyler+Jenna email.
5. **OIDC federated identity for deploy app** — sprint-2 candidate per `SPRINT-1-KICKOFF.md`. File as a bd so it doesn't get lost; execute when cert rotation pain becomes real (~3 months out).

### P2 — decision documents, file in Phase 0
6. **MTO membership evaluation for DCE tenant** — currently in `SPRINT-1-KICKOFF.md` § 5 as an open question with no owner. File as bd, owner Tyler, target decision by end of Phase 3 so it's resolved before cross-brand sprint-3 work.
7. **Site-request intake form / process** — Phase 4 surfaces this gap: when someone wants a new spoke, what's the path? Adaptation pillar.

### P3 — sprint-2+ placeholders
8. **Viva Connections Dashboard cards** — per ChatGPT 5.5 Pro guide § 10.3 and `SPRINT-1-KICKOFF.md` § 6.
9. **Region/store-level group decomposition** — per Perplexity blueprint. Touches audience model.
10. **Brand template parameterization for TLL / BCC / Frenchies / Bishops** — turns DCE pattern into reusable spoke template. The *real* deliverable behind `rod` and `69v`; those bds are the audit step, this is the productization step.

---

## What this plan deliberately does NOT do

- **Does not re-plan Sprint 1 day-by-day** — that lives in `12-implementation-plan.md`. This is the wrapper around it.
- **Does not touch the production marketing site** (`index.html`, `operations.html`, `msp.html`, `css/`, `js/`) — that has its own a11y gate triple and is out of scope.
- **Does not fold cross-brand work** (`rod`, `69v`) into the 60-day window — they're sprint-3+ after DCE proves the pattern. New bd #10 captures the future shape.
- **Does not include MTO joining as a precondition** — the architecture works without it. Decision can come from new bd #6.
- **Does not block on Kristin** — she's a stakeholder for Phase 3 comms, not a gate.

---

## Confidence pillar audit (reverse view)

| Pillar | Where it's served | Where the plan is weakest |
|---|---|---|
| **Security** | Phase 0 cosign, Phase 1 cert-auth, Phase 4 audit cron | OIDC federation (new bd #5) is sprint-2; we run on cert-auth for 60+ days |
| **Stability** | Phase 1 CI gates, Phase 2 idempotent templates, Phase 4 cron | No observability layer until new bd #4 lands |
| **Scalability** | Phase 1 token system, Phase 2 audience model | Cross-brand parameterization (new bd #10) deferred to sprint-3 |
| **Adaptation** | Phase 0 rollback matrix, Phase 4 Jenna handoff | Site-request intake (new bd #7) is a gap until Phase 4 |

The weakest pillar in the 60-day window is **adaptation** — specifically, the bus-factor on Tyler stays at 1 until Phase 4 ends. That's why new bds #3 (Jenna runbook) and #4 (observability) are the two most important "new bds." File both in week 1.
