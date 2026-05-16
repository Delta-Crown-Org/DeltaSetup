# Prompt Pack — DCE SharePoint Hub-and-Spoke Build

> **You are an AI agent (Claude, ChatGPT, or otherwise) being handed
> this pack to produce a working implementation plan and a functional
> visual mockup of the Delta Crown Extensions SharePoint hub-and-spoke.
> A competing agent has been given the same pack. Your work will be
> evaluated against theirs.**

---

## Mission

Produce **both** of the following:

1. **A working visual mockup** of the DCE SharePoint hub-and-spoke — at
   minimum the Hub home page and the Crown Connection home page. The
   mockup must be either:
   - **Tier A — Live:** PnP provisioning templates applied to the
     actual DCE tenant sites, OR
   - **Tier B — Hi-fi:** Static HTML/CSS that uses the actual DCE
     design tokens (`reference/dce-tokens.json`) and is structured so a
     mechanical port to SPFx is a 1:1 conversion (component-for-
     component, no design re-work).

   Tier A wins on the rubric (`EVALUATION-RUBRIC.md`). Tier B is
   acceptable.

2. **A complete implementation plan** that includes:
   - Repo layout (under `Delta-Crown-Org/` GitHub org by default).
   - PnP toolchain choices with exact versions (PnP.PowerShell module
     name + version, Style Dictionary version, Fluent UI version, etc.).
   - GitHub Actions workflow YAML — runnable, with the secrets your
     pipeline needs explicitly enumerated.
   - App registration spec: which Graph + SharePoint permissions, why,
     and the consent commands to grant them.
   - Quality-gate plan: Playwright + axe-core + visual regression with
     specific viewports and AAA-where-feasible accessibility targets.
   - Day-by-day execution plan for the first sprint (10 working days),
     mapped to the Phase 1-4 bds already filed (DeltaSetup-ebk, -8p5,
     -b59, -7al).

---

## Constraints (non-negotiable)

### Constraint A — Don't invent what already exists

The dev box already has:

- `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/spfx/` —
  full SPFx scaffold (Fluent UI + PnP.js + Style Dictionary). **Reuse
  it.**
- `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/` —
  DCE-specific worktree with `DESIGN_SYSTEM_MEGA_BRIEF.md`,
  `HTT-Brands-SharePoint-Architecture.md`, logos for all 5 brands, and
  WCAG audit data. **Reference it; don't redo the WCAG audit.**
- `/Users/tygranlund/dev/01-htt-brands/sharepointagent/` — Python
  toolkit for SharePoint REST audits and brand color extraction. **Use
  it for any auditing step.**
- `deltacrown.com` design tokens are already in this repo at
  `css/tokens.css`. They're WCAG-audited; the canonical token file is
  derived in `reference/dce-tokens.json`. **Use them. Do not redefine.**

If you find yourself writing a 5th SPFx scaffold or a new color
palette, stop and re-read this section.

### Constraint B — Tenancy and authentication facts

See `00-context.md`. Critical highlights:

- DCE tenant ID: `ce62e17d-2feb-4e67-a115-8ea4af68da30`.
- HTT tenant ID: `0c0e35dc-188a-4eb3-b8ba-61752154b407`.
- HTT→DCE cross-tenant sync is gated by the now-DYNAMIC group
  `SG-DCE-Sync-Users` (HTT side, id `6f5cc75e-b2ae-4ed2-992d-e56d4e3ef5f3`).
  Every enabled `@httbrands.com` user auto-syncs to DCE within 40 min.
- DCE Hub site: `https://deltacrown.sharepoint.com/sites/dce-hub`
  (provisioned, empty).
- Crown Connection: `https://deltacrown.sharepoint.com/sites/CrownConnection`
  (provisioned, 57 members, 3 owners — Tyler/Kristin/Jenna).
- For Exchange Online ops against DCE from an HTT admin account, use
  `Connect-ExchangeOnline -DelegatedOrganization deltacrown.onmicrosoft.com`
  (the `-Organization` flag is silently ignored — see
  `tools/connect-exo-cross-tenant.md` in the parent repo).

### Constraint C — Identity model is GROUP-DRIVEN

Audience targeting **must** use M365 group membership as the primary
mechanism, with optional secondary attribute filters (`department`,
`jobTitle`). Rationale and implementation in `02-identity-audience.md`.

This is non-negotiable because:

- HTT corp users sync into DCE as `userType: Member` with
  `companyName: 'HTT Brands'` (not an attribute the franchise owners
  have).
- Adding a new role / audience must be a "create a group, target a web
  part to it" operation, not a code change.

### Constraint D — CI/CD ambition is MEDIUM by default

Per `11-decisions/002-ci-cd-tier.md`:

- **Medium** = PnP PowerShell templates + GitHub Actions = the default
  tier you should implement.
- **Light** = manual PnP runs. Not acceptable for production but OK
  for the first dev round-trip.
- **Heavy** = SPFx with App Catalog + custom web parts. Defer until
  Medium hits a wall.

If you propose Heavy, you must justify why Medium can't paint the
picture for the home pages.

### Constraint E — Repository layout

Recommended: a new GitHub repo `Delta-Crown-Org/dce-sharepoint` with
the structure spec'd in `07-ci-cd-pipeline.md`. Do NOT add a second
SPFx project to `DeltaSetup` (this repo is the public website).

You may scaffold the new repo locally at
`/Users/tygranlund/dev/04-other-orgs/dce-sharepoint/` and let Tyler push
when he reviews.

### Constraint F — Quality gates are GATES, not suggestions

Every PR that ships HTML/CSS/JS must pass:

- `pa11y-ci` or `axe-core` accessibility audit (WCAG 2.2 AA minimum,
  AAA where text-heavy)
- Playwright smoke test on 3 viewports (375 / 768 / 1440)
- Visual-regression diff (use Playwright snapshots or Percy)
- Token validation (style-dictionary build must succeed)

These mirror the gates already running on `deltacrown.com` (see this
repo's `AGENTS.md` for the public-page quality gates).

---

## Deliverables checklist (use this to self-grade)

```
[ ] reference/dce-tokens.json    (canonical DCE Style Dictionary tokens)
[ ] reference/fluentui-theme-dce.json (FluentUI theme generated from tokens)
[ ] reference/existing-assets-inventory.md (annotated, with prior-art links)
[ ] 00-context.md  — non-negotiable env facts
[ ] 01-architecture.md  — hub-spoke topology
[ ] 02-identity-audience.md  — roles + audience model
[ ] 03-design-system.md  — tokens + components + theme
[ ] 04-content-architecture.md  — page templates + IA
[ ] 05-permissions-model.md  — permission inheritance
[ ] 06-tooling-pnp.md  — PnP/SPFx versions + modules
[ ] 07-ci-cd-pipeline.md  — full pipeline spec + runnable YAML
[ ] 08-quality-gates.md  — testing strategy
[ ] 09-deployment.md  — app reg, secrets, runbook
[ ] 10-runbooks.md  — operational procedures
[ ] 11-decisions/  — ADRs for major choices
[ ] 12-implementation-plan.md  — day-by-day sprint plan
[ ] Mockup (Tier A or Tier B) of DCE Hub home page
[ ] Mockup (Tier A or Tier B) of Crown Connection home page
[ ] Implementation-plan.md cross-references each Phase bd
    (DeltaSetup-ebk, -8p5, -b59, -7al, -rod)
```

## Self-grading checklist for evaluation parity

After producing your output, answer in writing:

1. Which sections of this pack did you NOT use? Why not?
2. Which prior assets in `/Users/tygranlund/dev/01-htt-brands/` did
   you reuse? With paths.
3. Did you pick Medium CI/CD? If not, where in the rubric does your
   choice score better?
4. Which ADR would you flip if Tyler vetoed it, and what's the next
   best alternative?
5. What's the SHORTEST path from your output to a clickable demo on a
   real DCE site? Number the steps.

---

## How your work is evaluated

See `EVALUATION-RUBRIC.md` for the full grid. Top-level criteria:

| Dimension | Weight |
|---|---|
| Reuse of existing assets (no re-invention) | 20% |
| Faithfulness to DCE design tokens | 15% |
| Identity / audience model correctness | 15% |
| CI/CD pipeline executability | 15% |
| Permission model + inheritance philosophy | 10% |
| Accessibility (WCAG 2.2 AA minimum, AAA preferred) | 10% |
| Mockup hi-fi → SPFx port-ability | 10% |
| Documentation quality (ADRs, runbooks) | 5% |

The competing model's output will be scored on the same grid. Highest
total wins. Ties broken by Tyler's gut.

---

## Begin

When you have absorbed this pack and the chapters, produce:

1. Your output directory at
   `/Users/tygranlund/dev/04-other-orgs/dce-sharepoint/` (or your
   repo of choice — declare it).
2. A `RATIONALE.md` at the root that answers the 5 self-grading
   questions above.
3. The deliverables-checklist items.

Good luck. Don't be polite at the expense of being right. Disagree
with this pack where you can defend it. 🐶
