# Evaluation Rubric — Puppy vs ChatGPT 5.5 Pro

This rubric exists to make the head-to-head comparable. Tyler will
score both models' outputs against this grid. The model with the
highest total wins; ties go to Tyler's gut.

The rubric is intentionally opinionated. Each criterion has a clear
operational definition so scoring isn't aesthetic.

---

## Scoring scale

For every criterion: **0 / 1 / 2 / 3** where:

- **0** = Missing or wrong.
- **1** = Present but with gaps that block execution.
- **2** = Solid; could ship with minor edits.
- **3** = Excellent; production-ready and demonstrably better than
  the prior art.

Each criterion has a weight. Weighted total / 300 = % score.

---

## Criteria

### 1. Reuse of existing assets (weight: 20%)

> Did the agent leverage the prior art, or rebuild it?

**Operational test:** Open the agent's output, search for references to:

- `Convention-Page-Build/spfx/` (HTT-side SPFx project)
- `bd-aj1-dce-audit/` (DCE worktree with mega brief)
- `sharepointagent/` (Python toolkit)
- `deltacrown.com/css/tokens.css` (THIS repo's tokens)
- `tools/connect-exo-cross-tenant.md` (cross-tenant EXO pattern)

**Score:**
- **0:** None of the above referenced; agent invented from scratch.
- **1:** 1-2 referenced, but agent still rebuilt 50%+ of what exists.
- **2:** 3-4 referenced and extended rather than replaced.
- **3:** All referenced; new code is purely additive (delta only) and
  the agent explicitly justified any deviation.

### 2. Faithfulness to DCE design tokens (weight: 15%)

> Are the agent's mockups / themes derived from `reference/dce-tokens.json`?

**Operational test:** Spot-check 10 random color/typography values in
the agent's output. Each must trace back to the canonical token file
(direct value or computed via a transform documented in
`03-design-system.md`).

**Score:**
- **0:** Hardcoded hex values everywhere; no token system.
- **1:** Some tokens used, many one-offs.
- **2:** ≥80% of values traceable to tokens.
- **3:** 100% traceable; agent generated the Fluent UI theme file
  programmatically from tokens via Style Dictionary.

### 3. Identity / audience model correctness (weight: 15%)

> Does the agent's audience-targeting model reflect the real M365
> group landscape?

**Operational test:** For each of the 6 roles in
`02-identity-audience.md` (Global Admin, Franchisor Leadership, DCE
Owner, DCE Manager, DCE Staff, HTT Corp), the agent's plan must
specify:

- Which existing or new M365 group represents the role.
- Whether sync into DCE happens automatically (via the dynamic gate)
  or requires manual provisioning.
- Which sites and which web parts are targeted to that role.

**Score:**
- **0:** Audience model ignored; treats SharePoint like a single
  global audience.
- **1:** Owners vs everyone-else distinction made; nothing more granular.
- **2:** ≥4 roles modeled correctly with group mappings.
- **3:** All 6 roles modeled, secondary attribute filters proposed
  where group mapping isn't sufficient, and the agent flagged at
  least one identity edge case that the spec missed.

### 4. CI/CD pipeline executability (weight: 15%)

> Could a fresh engineer take the agent's pipeline files and ship to
> the DCE tenant within an hour?

**Operational test:** Try it. Clone the agent's recommended repo
structure on a fresh machine. Run the documented setup. Push a
trivial change. Verify it lands in a dev site without manual
intervention. Time to first successful deploy is the metric.

**Score:**
- **0:** Pipeline is prose only; no runnable YAML.
- **1:** YAML present but requires undocumented manual steps.
- **2:** Runs end-to-end after secrets are populated. Documented
  setup ≤1 hour for a fresh engineer.
- **3:** Same as 2, plus the agent included a `scripts/bootstrap.sh`
  that automates app-registration + Graph permission grants.

### 5. Permission model + inheritance philosophy (weight: 10%)

> Does the agent default to inherited permissions and explicitly
> document when/why to break inheritance?

**Operational test:** Search the output for the word "inherit". The
agent must:

- State the inheritance philosophy ("inherit unless...") explicitly.
- Enumerate the SHORT list of cases where inheritance is broken.
- Specify how broken inheritance is audited / detected (avoiding
  the HTT-Headquarters cluster problem).

**Score:**
- **0:** Inheritance not addressed. Default behavior unspecified.
- **1:** Philosophy stated but no audit mechanism.
- **2:** Philosophy + audit mechanism + ≤3 explicit break exceptions
  enumerated.
- **3:** Same as 2, plus a programmatic check (PnP cmdlet sequence
  or Python script using `sharepointagent`) that detects unexpected
  breaks.

### 6. Accessibility — WCAG 2.2 AA minimum (weight: 10%)

> Does the implementation plan meet WCAG 2.2 AA with named AAA
> aspirations for text-heavy areas?

**Operational test:** Agent must specify:

- Color contrast verification approach (axe-core in CI).
- Focus appearance rules (the canonical 3px ring at 4.73:1 — see
  `DESIGN_SYSTEM_MEGA_BRIEF.md` §2 in the HTT repo).
- Target size compliance (44×44 minimum).
- Specific viewport breakpoints for responsive testing.

**Score:**
- **0:** No a11y planning.
- **1:** Mentioned but no concrete checks.
- **2:** axe-core + named contrast / focus / target-size rules.
- **3:** Same as 2, plus AAA aspiration zones explicitly marked +
  manual-checklist for "axe-incomplete" findings (the same pattern
  this repo uses — see `AGENTS.md`).

### 7. Mockup hi-fi → SPFx port-ability (weight: 10%)

> If the mockup is Tier B (HTML), can it be mechanically converted to
> SPFx without redesign?

**Operational test:** Identify each visual section in the mockup.
Each section must:

- Map 1:1 to a planned SPFx web part name in `06-tooling-pnp.md`.
- Use DCE tokens (no hardcoded hex except in token definitions).
- Be responsive (mobile, tablet, desktop layouts defined).

**Score:**
- **0:** No mockup, OR mockup uses arbitrary CSS unrelated to tokens.
- **1:** Mockup exists but each section requires redesign for SPFx.
- **2:** Mockup is structured by section with token-driven CSS.
- **3:** Same as 2, plus the agent provided a section-to-web-part
  conversion table.

### 8. Documentation quality — ADRs + runbooks (weight: 5%)

> Are the choices documented in a way that survives a re-org?

**Operational test:** Count the ADRs. Each must:

- Have a unique number.
- Document the decision, the alternatives considered, and the
  reasoning.
- Be revisable (status: proposed / accepted / superseded).

**Score:**
- **0:** No ADRs.
- **1:** 1-3 ADRs.
- **2:** 4-6 ADRs covering the major axes.
- **3:** ≥7 ADRs, plus at least one runbook with command-level
  detail (e.g., "Add a new franchise owner" with the exact PnP
  cmdlets).

---

## Bonus (uncapped — adds to weighted total)

- **+5%** if the agent identifies a real, specific defect in this
  spec pack and proposes a fix.
- **+5%** if the agent ships a working `make demo` or
  `npm run demo` command that bootstraps the mockup locally.
- **+5%** if the agent's Tier-A mockup ships to a real DCE dev site
  during the session (with screenshots).

## Penalties (subtracted from weighted total)

- **-10%** for each major scope-creep section (e.g., proposing a
  new identity provider, recommending migration off SharePoint).
- **-10%** for committed secrets or live tokens in the output repo.
- **-20%** for skipping the "reuse existing assets" review.

---

## Scoring template

| Criterion | Weight | Puppy | ChatGPT |
|---|---|---|---|
| 1. Reuse | 20% | _/3 | _/3 |
| 2. Token faithfulness | 15% | _/3 | _/3 |
| 3. Identity/audience | 15% | _/3 | _/3 |
| 4. CI/CD executability | 15% | _/3 | _/3 |
| 5. Permissions philosophy | 10% | _/3 | _/3 |
| 6. Accessibility | 10% | _/3 | _/3 |
| 7. Mockup port-ability | 10% | _/3 | _/3 |
| 8. Documentation | 5% | _/3 | _/3 |
| **Subtotal** | 100% | _% | _% |
| + Bonus | — | +__ | +__ |
| − Penalty | — | −__ | −__ |
| **TOTAL** | — | **__** | **__** |

The number above is the headline. Tyler reads RATIONALE.md from both
and confirms the score.
