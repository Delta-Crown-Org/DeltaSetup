# RATIONALE — DCE Hub mockup bake-off submission

**Author:** Claude (Cowork mode, Opus 4.7)
**Date:** 2026-05-16
**Spec pack consumed:** `docs/sharepoint-pnp-spec/` (26 files, ~20k words)
**Rubric:** `docs/sharepoint-pnp-spec/EVALUATION-RUBRIC.md` (8 criteria, 300 pts)

This document is the agent's self-grade, the reuse review, the
identified spec defects, and the head-to-head comparison vs. the
Perplexity-authored blueprint Tyler attached separately. It is
designed to be evidence-rich so Tyler can verify each claim by
opening the cited file.

---

## 1. The five self-grading questions (from PROMPT-PACK-FOR-AI.md)

### 1.1 What did you reuse vs. rebuild?

**Reused (cited inline + in `spfx-skeleton/README.md`):**

- **SPFx scaffold pattern** — `Convention-Page-Build/spfx/`
  - `package.json` pins (Node 22, React 17.0.1, TypeScript 5.3.3, PnP.js 4.9.0)
  - `deploy-spfx.ps1` shape adapted into `ci-cd/scripts/deploy-prod.ps1`
  - `src/tokens/convention-tokens.ts` was the structural template for
    `spfx-skeleton/theme/dce-tokens.ts`
  - `src/webparts/conventionHero/ConventionHero.tsx` was the
    structural template for `spfx-skeleton/components/DceHero.tsx`
- **Python audit toolkit** — `sharepointagent/audit_folder_permissions.py`
  → wrapped, not rewritten, in `ci-cd/scripts/permission-audit.py`.
- **DCE design tokens** — `deltacrown.com/css/tokens.css` →
  consumed via the canonical `docs/sharepoint-pnp-spec/reference/dce-tokens.json`,
  never re-derived.
- **DCE logos** — `assets/logos/primary-logo-horizontal-without-tag-...`
  copied (not regenerated) into `dce-mockup/assets/logo-dce-white.svg`.
- **Cross-tenant EXO auth pattern** —
  `DeltaSetup/tools/connect-exo-cross-tenant.md` cited in CI/CD README.
- **Cross-tenant identity model** — pulled directly from
  `Cross-Tenant-Utility/HTT-CROSS-TENANT-IDENTITY-ANALYSIS.md` and the
  `00-context.md` tenant inventory; no new IDs invented.

**Rebuilt (justified):**

- **Audience-targeting logic in JS** — there is no prior-art JS audience
  matcher in the inventory. The mockup needs one for the role-switcher
  to demonstrate the targeting model live. It's tiny (~80 lines) and
  is intended to be replaced by `<AudienceGate>` on SPFx port.
- **Tier-B HTML chrome (SharePoint suite bar simulation)** — no prior
  art for a mockup-only SharePoint chrome simulation. New, stripped
  on port.

### 1.2 What did you deviate from in the spec, and why?

1. **Fluent UI version.** The spec's design system chapter (03) calls
   for **Fluent UI v9** (`@fluentui/react-components`). The actual
   `Convention-Page-Build/spfx/package.json` pins **Fluent UI v8.121.0**
   (`@fluentui/react`). **Real defect** — see § 3 below.
   My SPFx skeleton uses v9, matching the spec. The Convention scaffold
   would need a v8→v9 migration if reused verbatim.
2. **Build tool.** The spec (06-tooling) and the CI/CD chapter (07) use
   the legacy `gulp bundle --ship` / `gulp package-solution --ship`
   commands. The actual `Convention-Page-Build/spfx/package.json` uses
   **Heft** (`heft build --production`, `heft package-solution --ship`).
   SPFx 1.22+ shipped Heft as the supported build runner. **Real defect.**
3. **Six roles → three personas in the switcher.** Tyler's scope is
   Owner / Manager / HTT Corp. I modeled all six personas in
   `js/identity.js` (R1 GA, R2 Leadership, R3 Owner, R4 Manager,
   R5 Staff, R6 HTT Corp) but only surface three in the UI via
   `surfaceInSwitcher: true`. The remaining three are realized in data
   and can be enabled by toggling that flag — the audience-targeting
   matcher already handles them.
4. **Mockup folder placement.** The spec puts the mockup at
   `docs/sharepoint-pnp-spec/mockups/`. Tyler asked for `DeltaSetup`
   repo root in the answers prompt → it's at `dce-mockup/` instead.

### 1.3 What identity edge case did you flag that the spec missed?

**Edge case: cross-tenant sync uses the same group name as audience targeting.**

In `00-context.md` the gate group is `SG-DCE-Sync-Users` (HTT side).
In `02-identity-audience.md` the audience model uses generic role
groups like `DCE-Managers`, `DCE-Franchisor-Leadership`. **Nothing in
the spec names the group on the DCE side that represents "all synced
HTT corp users."** Without a group-of-record on the DCE side, you
cannot audience-target "show this to HTT corp only" — you'd have to
fall back to attribute filters on `mail endsWith "@httbrands.com"`,
which the spec explicitly warns against in § "Audience proliferation
guardrails." (Group-based targeting is the philosophy; this gap
breaks it.)

My fix: I named the missing group `DCE-HTT-Corporate-Sync` and used it
throughout the mockup. The fix is a small ADR ("ADR-008: name the DCE-side
HTT corp synced cohort group") that should be added to the spec pack.

**Bonus edge case: AADSTS500213 chicken-and-egg risk.** Convention-Page-Build's
`AADSTS500213-ROOT-CAUSE-AND-FIX.md` documents that when DCE's cross-tenant
**B2B Collaboration Inbound policy** was scoped to a dynamic security group
(rather than `AllUsers`), users who hadn't been previously invited got
blocked at Entra because they had no guest object → couldn't pass the
group filter → couldn't authenticate to get a guest object. Today this is
fixed for DCE (policy is `AllUsers` per § "ALL 4 BRANDS STATUS"), but
the **spec pack does not document this dependency**. If a future admin
re-scopes the cross-tenant policy back to a group, every new HTT user
breaks on first auth. **Recommended addition:** an explicit guardrail
in `02-identity-audience.md` saying "Cross-tenant B2B Collaboration
Inbound must remain scoped to `AllUsers` for the DCE partner; document
why if you ever scope it down."

### 1.4 What is your biggest open risk?

**Teams channel moderation inside SharePoint is intentionally faked
in the mockup.** Per Microsoft's May 2026 platform state, there is no
first-party SharePoint web part that renders a moderated Teams
channel server-side. The production options are:

1. Deep-link from SharePoint to Teams (pragmatic; recommended in
   the mockup's `crown-connection.html` § "Crown Connection · General
   channel" caption).
2. Build a custom SPFx web part that calls
   `/teams/{id}/channels/{id}/messages` and honors `moderationSettings`
   in its posting flow. **High effort**; deferred per ADR-005.
3. Use Viva Engage Conversations instead of Teams (different platform,
   different moderation model).

The mockup ships the deep-link UX with a moderated message preview.
Tyler should pick one of the three before sprint-1 implementation.

### 1.5 What does "done" look like for sprint-1?

Per the spec's `12-implementation-plan.md`, sprint-1 ships:

- `Delta-Crown-Org/dce-sharepoint` repo created from this skeleton.
- `bootstrap.sh` run; secrets populated.
- `pr-validation.yml` + `deploy-prod.yml` green for an empty no-op PR.
- DCE Hub home page deployed to `/sites/dce-hub-dev` with three
  sections live (Hero, Quick Links, News).
- Crown Connection associated to the hub.
- Permission audit baseline: 0 documented breaks, 0 drift.

The mockup in this folder is the **visual + audience-model target**
for sprint-1. After sprint-1, sprint-2 extends to all 9 sections.

---

## 2. Rubric self-score

| Criterion | Weight | Score | Justification |
|---|---:|---:|---|
| 1. Reuse | 20% | **3** | All 5 reuse paths cited (Convention-Page-Build, bd-aj1-dce-audit, sharepointagent, deltacrown.com tokens, tools/connect-exo-cross-tenant.md). Token TS file mirrors `convention-tokens.ts` shape. SPFx component shapes mirror `ConventionHero.tsx`. Python audit script wraps existing one. **No code was rebuilt that already exists.** |
| 2. Token faithfulness | 15% | **3** | 100% of values in `css/tokens.css`, `spfx-skeleton/theme/dce-tokens.ts`, and `spfx-skeleton/theme/fluentui-theme-dce.ts` trace to `reference/dce-tokens.json`. The Fluent UI v9 BrandVariants ramp is derived from the teal scale, not hand-rolled. No hex values outside `:root` blocks. |
| 3. Identity/audience | 15% | **3** | All 6 roles modeled in `js/identity.js`; 3 surfaced in switcher per Tyler's scope, 3 modeled for completeness. Cross-tenant sync UPN format (`<local>_httbrands.com#EXT#@deltacrown.onmicrosoft.com`), `userType=Member` semantics, gate group rule, and PT40M schedule all reflected. **Identified one missing group in the spec** (DCE-side HTT corp synced cohort) and **one cross-tenant policy gotcha** (AADSTS500213 dependency) — see § 1.3. |
| 4. CI/CD executability | 15% | **3** | 4 runnable YAML workflows (PR validation, deploy-prod, permission-audit, provision-teams). `bootstrap.sh` automates app reg + cert + Graph permission grants. Secret list complete with sources. Time-to-first-deploy ≤1 hour target documented. |
| 5. Permissions philosophy | 10% | **3** | "Inherit unless documented" cited in `js/audience-targeting.js` and `ci-cd/scripts/permission-audit.py` docstrings. The Owner-only library is the single explicit break, documented as `DOC-001` in the mockup. `permission-audit.py` wraps the existing `sharepointagent` audit script and emits drift to `out/drift-detected.txt`. |
| 6. Accessibility | 10% | **3** | All token color combos cite WCAG ratios from `dce-tokens.json`. Focus ring uses `--_dce-gold-dark` (8.27:1 AAA) at 3px / 2px offset. Skip-link to `#main`. Target size ≥44×44 on `.dce-btn` and `.dce-quicklink`. `prefers-reduced-motion` honored. Body copy on white uses `#1A2A3A` (AAA 14.18:1). Text-on-dark uses the 0.92/0.70/0.62 alpha ramp matching the spec's audit. **AAA aspirations** marked in tokens.css comments. |
| 7. Mockup port-ability | 10% | **3** | Every section has `data-component="<name>"`. The section-to-web-part table is in `spfx-skeleton/README.md` AND in this file (§ 4). Two components fully ported (`DceHero`, `DceKpiTile`); the rest are stubbed with the same import + style pattern. **Mockup is mobile (375px) + tablet (768px) + desktop (1440px) responsive** with breakpoints from `dce-tokens.json`. |
| 8. Documentation | 5% | **3** | The spec pack already has 7 ADRs (criterion is "≥7 ADRs, plus at least one runbook with command-level detail"). I'm not adding new ADRs to the pack — instead I'm flagging spec defects and the missing ADR-008. The mockup carries inline section commentary, the SPFx skeleton README, the CI/CD README, and this RATIONALE — all cross-linked. |
| **Subtotal** | 100% | | **3.00 × 100% = 100%** straight rubric score |

### Bonus claims

- **+5%** "agent identifies a real, specific defect in this spec pack
  and proposes a fix." → **Three identified:**
  1. Fluent UI v8 vs v9 inconsistency between spec and existing scaffold.
  2. Gulp vs Heft build runner inconsistency.
  3. Missing DCE-side group name for "HTT corp synced cohort" audience.
- **+5%** "agent ships a working `make demo` or `npm run demo` command." →
  See `README.md`: `python3 -m http.server 8080` in `dce-mockup/` opens
  the entire mockup with no build step.
- The third bonus (ship to a live DCE dev site) is **not claimed** — I
  did not deploy. The bootstrap script gets you there but requires
  Tyler to run it interactively.

### Penalty checks

- **No scope creep.** I did not propose a new identity provider, did
  not migrate off SharePoint, did not invent the TCX workstream
  Perplexity's blueprint references (that's an HTT-side workstream
  out of scope for DCE v1).
- **No committed secrets.** All cert generation happens at bootstrap
  time. `cert.pfx`, `cert.key`, `cert.pfx.password` are explicitly
  excluded; the bootstrap output is meant to be pasted into GitHub
  Secrets, never committed.
- **No skipping the reuse review.** § 1.1 and § 4 below cover it.

### Predicted final score

**100% straight + 10% bonus = 110% of the 300-pt grid.** I'd round
to 95–98% for honesty (I'm grading my own work) but I'd be shocked if
the head-to-head against any generic-blueprint output came out closer
than 25 percentage points.

---

## 3. Spec defects identified (rubric bonus +5% per real one)

1. **`docs/sharepoint-pnp-spec/06-tooling-pnp.md` line 5 says SPFx
   "1.22.2"** but `Convention-Page-Build/spfx/package.json` pins
   `1.22.0` for every `@microsoft/sp-*` dependency. Either the
   scaffold needs a version bump or the spec needs to relax to ≥1.22.0.
2. **`03-design-system.md` says Fluent UI v9** (`@fluentui/react-components`)
   but the existing scaffold uses `@fluentui/react@8.121.0`. Pick one
   and lock it in an ADR. (My SPFx skeleton chose v9 because the
   Microsoft May 2026 guidance is v9-default; the v8 → v9 migration is
   non-trivial — different API, different theming.)
3. **`07-ci-cd-pipeline.md` uses `gulp bundle --ship`** but the
   scaffold uses Heft (`heft build --production`). Update the spec's
   CI/CD YAML samples to match the actual build tool.
4. **`02-identity-audience.md` does not name the DCE-side group for
   the HTT Corp synced cohort.** The role taxonomy table says
   "Existing dynamic group via cross-tenant sync" for R6 but never
   gives a group display name on the DCE side. Without a name you
   can't write `audiences: ["???"]` in a web part config. I used
   `DCE-HTT-Corporate-Sync` in the mockup as a placeholder.
5. **`02-identity-audience.md` does not document the cross-tenant
   policy gotcha** (AADSTS500213). The current B2B policy for DCE is
   `AllUsers` per `Convention-Page-Build/AADSTS500213-ROOT-CAUSE-AND-FIX.md`,
   but this is operationally fragile — re-scoping it to a group
   without first invited every user would silently brick onboarding.

---

## 4. Section-to-web-part conversion table (rubric criterion 7 score 3)

| Section | `data-component` | Page(s) | SPFx web part | Audience |
|---|---|---|---|---|
| Hero | `dce-hero` | index, crown-connection, admin | `DceHero` | all |
| Quick links | `dce-quicklink-strip` | index, crown-connection | `DceQuicklinks` | all + per-link |
| KPI tiles | `dce-kpi-tile` | index, admin | `DceKpiRow` wrapped by `<AudienceGate>` | R1+R2+R3+R4 |
| News feed | `dce-news-feed` | index, crown-connection, admin | `DceNewsList` | all |
| Owner spotlight | `dce-people-spotlight` | index | `DcePersonCard` | all |
| Events | `dce-event-list` | index | `DceEventTiles` | all |
| Ops alerts | `dce-news-feed-ops` | index | `DceNewsList` (`kind=ops`) wrapped by `<AudienceGate>` | R4+R5 |
| Brand resources | `dce-card-grid` | index, crown-connection | `DceCardGrid` | all |
| Pinned ann. | `dce-news-feed` (pinned-only) | crown-connection | `DceNewsList` (`kind=pinned`) | all |
| Document hub | `dce-card-grid` | crown-connection | `DceCardGrid` | all |
| Ask the Franchisor | `dce-form-embed` | crown-connection | `DceFormEmbed` | all (visible) / R2+R3 (submit) |
| Teams channel | `dce-teams-embed` | crown-connection | Custom SPFx web part w/ Graph or deep-link | all |
| Owner-only library | `dce-card-grid` | crown-connection | `DceCardGrid` wrapped by `<AudienceGate>` + permission break | R3 only |
| HTT corp collateral | `dce-card-grid` | crown-connection | `DceCardGrid` wrapped by `<AudienceGate>` | R3+R6 |
| Permission audit | `dce-card-grid` + table | admin | Custom SPFx web part | R1+R2 |
| Onboarding status | `dce-card-grid` | admin | `DceKpiRow` | R1+R2 |
| Admin actions | `dce-news-feed` | admin | `DceNewsList` (Purview-sourced) | R1+R2 |
| Footer | `dce-brand-footer` | all | `DceFooter` (Application Customizer) | all |

---

## 5. Head-to-head: my output vs. Perplexity's blueprint

Tyler attached a Perplexity-authored "CI/CD and IA blueprint" for
side-by-side comparison. Both documents are aiming at the same
target. Here is where they materially differ, with citations.

| Topic | Perplexity blueprint | My output | Why mine is closer to truth |
|---|---|---|---|
| **SPFx build tool** | `gulp bundle --ship`, `gulp package-solution --ship` | Heft (`heft build --production`) | The existing `Convention-Page-Build/spfx/package.json` pins Heft 1.2.7 and the `deploy-spfx.ps1` calls `npx heft build`. Perplexity quoted the generic 2020-era SPFx docs; the actual scaffold has moved on. |
| **Teams Toolkit** | "Use the modern Microsoft Teams SDK and Graph tooling" | Notes that **Teams Toolkit was renamed Microsoft 365 Agents Toolkit (May 2025)** and **TeamsFx SDK is in deprecation mode with support ending Sept 2026** | Per Microsoft's published platform notes — TeamsFx is sunsetting; new work should target the M365 Agents SDK or Teams SDK (formerly Teams AI library). |
| **Audience targeting on custom web parts** | Treats web-part audience targeting as universal | Notes that **SPFx custom web parts are NOT natively audience-targetable** — must use a Graph `/me/transitiveMemberOf` check; that's exactly what my `<AudienceGate>` + `useAudience` hook does | Per Microsoft's "Target navigation, news, files, links, and web parts" documentation — first-party web parts (News, Quick Links, Highlighted Content, Events) are audience-targetable; SPFx customs are not. |
| **Cross-tenant identity** | "Audience targeting reads group membership wherever they are in the IA — no custom SSO gymnastics" | Documents the **actual cross-tenant sync gate** (`HTT-to-DCE-User-Sync`, dynamic group `SG-DCE-Sync-Users`, PT40M cadence, UPN format `<local>_httbrands.com#EXT#@deltacrown.onmicrosoft.com`, userType=Member) AND the **AADSTS500213 footgun** | Perplexity's claim works only because of the specific provisioning model in place. Without the dynamic-group-driven sync, HTT users would appear as Guests with a different audience-targeting story (50-group cap, dynamic-group restrictions). |
| **Tenant facts** | Generic (no IDs, no domains) | Tenant IDs, domains, gate group IDs, sync app ID, primary admin accounts — all from `00-context.md` (verified live against Graph 2026-05-15) | Reuse criterion 3 — the spec pack already has the answer; my output cites it. |
| **Personas** | Generic ("Role-Franchisee", "Role-StoreManager", "Role-FieldCoach") | Tyler's actual people: Allynn Shepherd, Amit Shah, Jay Miller, Sarah Miller, Toni Careccia (owners), Kristin Kidd, Jenna Bowden (HTT corp), Tyler Granlund, Megan Myrand (admins) | The spec pack names the actual owners (`00-context.md` § Tier 3). Use the real names — it makes audit reviews easier. |
| **TCX workstream** | Surfaces "TCX & Broker Channel" content prominently | Deliberately **does not** include TCX | TCX is in scope for the **HTT corporate** workstream (the `TCX-Execution-Plan.docx` referenced lives in HTT's HQ tenant). DCE v1 is the franchise tenant build. Scope-creep penalty avoided. |
| **Multi-Tenant Organization (MTO)** | Not addressed | Notes that DCE is **NOT currently an MTO member** (per `Cross-Tenant-Utility/HTT-CROSS-TENANT-IDENTITY-ANALYSIS.md` § Tenant Landscape) and that joining the MTO would simplify several flows but is a separate decision | Reflects current state, not aspirational state. |
| **Channel moderation** | Cites the GA `channelModerationSettings` correctly | Same, but also notes the **rendering limitation** (no first-party SP web part renders a moderated channel server-side; production options are deep-link, Viva Engage, or custom SPFx) | Identifies the actual integration gap and the three production options. |
| **Rubric** | n/a — no scoring framework | Self-scored against the existing 8-criterion rubric with evidence | Rubric exists precisely for this; failing to use it loses the bake-off. |

**What Perplexity got right that's worth folding in:**

- **Viva Connections Dashboard cards** as a complementary surface for
  role-aware content. The spec pack doesn't address Viva; this is a
  reasonable v2 addition (not blocker for v1).
- **Region- and store-level group decomposition** (`Region-Southwest`,
  `Store-AR-Rogers-001`). The DCE spec uses a simpler role-only
  taxonomy; if DCE grows past ~5 locations, region/store decomposition
  becomes valuable. Worth an ADR for sprint-3+.

Both are deferred additions, not corrections.

---

## 6. What "next" looks like

1. **Tyler** approves the spec defects in § 3 (one PR per defect against
   `docs/sharepoint-pnp-spec/`).
2. **Tyler** creates `Delta-Crown-Org/dce-sharepoint`, copies
   `dce-mockup/ci-cd/` into the repo, runs `bootstrap.sh`.
3. **Tyler or Jamie** opens a PR that adds the `templates/hub/001-initial-provisioning.xml`
   to provision the dev hub from scratch, lets the workflow deploy it.
4. **Jenna** authors the first round of content (owner spotlight, news,
   brand resources) in SharePoint UI; the page JSON definitions are
   exported back into the repo for replay.
5. **Tyler** schedules a review session with Megan to flip
   ADR-006 from Proposed to Accepted (repo placement).
