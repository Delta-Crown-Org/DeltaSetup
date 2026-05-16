# 12 — Implementation Plan (Day-by-day, First Sprint)

This is the concrete sprint that takes us from "spec pack exists" to
"DCE Hub home page is live with DCE branding."

**Sprint duration:** 10 working days (2 weeks).
**Sprint owner:** Tyler.
**Implementing agent:** Whoever wins the Puppy-vs-ChatGPT bake-off.

---

## Day 0 — Pre-sprint (Tyler decides)

Before writing any code, Tyler answers the 5 open decisions from
`00-context.md`:

1. DCE Hub audience scope (all-staff vs sub-segmented).
2. Hub-spoke association (Crown Connection associates to Hub?).
3. Repo placement (recommend new `Delta-Crown-Org/dce-sharepoint`).
4. HTT users to exclude from DCE (recommend: none).
5. AAA aspirations (which surfaces need AAA, which AA is enough).

Recommend 30 min decision-stand-up with Kristin + Jenna present.
Output: a decisions log appended to `00-context.md`.

---

## Day 1 — Bootstrap the repo

**Goal:** New repo exists, scaffolded, first PR mergeable.

Tasks:
- [ ] Create `Delta-Crown-Org/dce-sharepoint` GitHub repo.
- [ ] `git init` local clone at `/Users/tygranlund/dev/04-other-orgs/dce-sharepoint/`.
- [ ] Copy `AGENTS.md` from this repo, adapt for the new repo.
- [ ] Copy `tokens.css` → seed `tokens/dce-tokens.json` (Style
      Dictionary format).
- [ ] Run `style-dictionary init` and configure the build (per `06-`).
- [ ] First PR: scaffold + initial `dce-tokens.json`. Merge.

**Acceptance:** Repo exists, README links to this spec pack,
`npm run build:tokens` produces `dist/css/dce-tokens.css`.

---

## Day 2 — App registration + cert + secrets

**Goal:** Deployment auth works end-to-end.

Tasks:
- [ ] Tyler runs the app-registration script from `09-deployment.md`.
- [ ] Generate cert, upload to Entra app, grant admin consent.
- [ ] Populate GitHub repo secrets.
- [ ] Smoke test: a minimal `Connect-PnPOnline` from a GitHub Action
      successfully connects to the dev site URL.

**Acceptance:** GitHub Actions can authenticate to DCE SharePoint as
the app identity.

---

## Day 3 — Provision dev environment

**Goal:** Dev SharePoint site collection exists.

Tasks:
- [ ] Provision `https://deltacrown.sharepoint.com/sites/dce-hub-dev`.
- [ ] Apply minimal initial template (just the site + default Documents
      library).
- [ ] Apply DCE Brand Center theme (generated from `dce-tokens.json`).
- [ ] Verify theme via browser screenshot.

**Acceptance:** Dev site loads with teal-and-gold theme applied.

---

## Day 4 — Build the home-page PnP template

**Goal:** Template produces the home page sections per `04-content-architecture.md`.

Tasks:
- [ ] Author `templates/hub/001-initial-provisioning.xml`.
- [ ] Include sections 1-7 from `04-content-architecture.md` § "Page:
      Home" (skipping admin-targeted sections for now).
- [ ] Each section uses placeholder web parts initially (Text + Image)
      that we'll later replace with branded variants.
- [ ] Apply to dev site, verify visually.

**Acceptance:** Dev site home page has 7 sections in order, each with
placeholder content. Layout matches the spec.

---

## Day 5 — DCE-branded styling

**Goal:** Sections look on-brand using the DCE token system.

Tasks:
- [ ] Style Dictionary generates `dist/sharepoint/theme.json`.
- [ ] Apply via `Add-PnPTenantTheme -Identity "DCE"`.
- [ ] Hero section uses `--surface-dark` background + `--text-on-dark`
      text + DCE white logo.
- [ ] Quick links use card style with `--color-brand-primary` accent.
- [ ] News web part uses Fluent UI theme.

**Acceptance:** Side-by-side comparison with `deltacrown.com`: the
SharePoint home page reads as the same brand.

---

## Day 6 — Audience targeting prototype

**Goal:** At least 2 audience-targeted web parts work end-to-end.

Tasks:
- [ ] Create the M365 groups from `02-identity-audience.md` (at minimum:
      `DCE-Franchise-Owners`, `DCE-Managers`, `DCE-AllStaff`,
      `DCE-Franchisor-Leadership`).
- [ ] Configure audience targeting on KPI tiles (R1/R2/R3/R4 only) and
      Operations alerts (R4/R5 only).
- [ ] Test with three test users in different groups.

**Acceptance:** Web parts hide/show correctly per group membership.

---

## Day 7 — Quality gates

**Goal:** Quality gates run in CI.

Tasks:
- [ ] Wire up `pr-validation.yml` workflow per `07-`.
- [ ] Wire up `deploy-prod.yml` and `deploy-dev.yml`.
- [ ] Configure Playwright smoke test against dev site.
- [ ] Configure pa11y-ci + axe-core.
- [ ] First green build.

**Acceptance:** A trivial PR (e.g., README update) passes all gates;
push to develop triggers dev deploy.

---

## Day 8 — Crown Connection home page

**Goal:** Crown Connection home page is branded and audience-targeted.

Tasks:
- [ ] Author `templates/crown-connection/001-home-page.xml`.
- [ ] All 10 sections from `04-content-architecture.md` § "Page: Home
      (Crown Connection)".
- [ ] Audience targeting: HTT collateral visible to R3+R6, owner-only
      tile visible to R3 only.
- [ ] Apply to Crown Connection (which is the real prod site — careful;
      coordinate with Kristin + Jenna).

**Acceptance:** Crown Connection home looks polished and shows
audience-appropriate content for 3 test users.

---

## Day 9 — Permission audit job

**Goal:** Weekly permission audit runs and stores results.

Tasks:
- [ ] Adapt `sharepointagent/audit_folder_permissions.py` for our tenant.
- [ ] Author `scripts/permission-audit.py` (Python; reuse the existing
      logic).
- [ ] Wire up `permission-audit.yml` cron.
- [ ] Author `reference/permission-breaks.csv` documenting the known
      break (Crown Connection owner-only library).
- [ ] First run; verify output.

**Acceptance:** Audit job runs, produces CSV, flags no drift.

---

## Day 10 — Sprint review + handoff

**Goal:** Functional demo + sprint retrospective.

Tasks:
- [ ] Demo to Tyler + Kristin + Jenna: dev site, prod Crown Connection
      with new home page, audience targeting in action.
- [ ] Document any sprint-1 deviations from the spec.
- [ ] File bds for any deferred work.
- [ ] Update `12-implementation-plan.md` with sprint-1 actuals + sprint-2 plan.

**Acceptance:** All stakeholders see and approve. Sprint-2 plan exists.

---

## Mapping to existing bds

| Bd | Maps to days |
|---|---|
| DeltaSetup-ebk (P1) — Phase 1: tokens + Brand Center + theme | Days 1-3, 5 |
| DeltaSetup-8p5 (P1) — Phase 2: DCE Hub home | Days 4-6 |
| DeltaSetup-b59 (P2) — Phase 3: Crown Connection home | Day 8 |
| DeltaSetup-7al (P2) — Phase 4: CI/CD | Days 2, 7 |
| DeltaSetup-rod (P2) — Phase 5: Cross-brand audit | NOT in sprint 1 — Phase 5 work |

## Sprint-2 preview

After sprint 1:

- People page + About page on Hub.
- Resources page on Hub.
- Crown Connection: Documents library structure + Events page.
- Cross-brand audit (Phase 5) once we have auth to TLL/BCC/FMNC.
- Application Customizer for global header/footer (start of "Heavy"
  CI/CD tier).

## Risks + mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Brand Center API doesn't accept custom fonts | Med | Med | Fallback to CSS @font-face injection via SPFx App Customizer (Sprint 2) |
| Audience targeting doesn't reliably hide content from cross-tenant Members | Low | High | Permission break as backup; test on Day 6 with HTT corp test user |
| GitHub Actions cannot reach SharePoint due to firewall | Low | High | Use az pipelines or self-hosted runner |
| Token system produces theme JSON SharePoint rejects | Med | Med | Validate against Microsoft's reference theme; minimal palette to start |
| Tyler unavailable mid-sprint | Med | Med | Megan as Global Admin backup; runbook 10 |

## Definition of Done (sprint 1)

- ✅ Dev site at `/sites/dce-hub-dev` loads with DCE theme.
- ✅ Prod site at `/sites/dce-hub` loads with DCE theme and home page.
- ✅ Crown Connection home page is branded and live.
- ✅ Audience targeting works for at least 2 web parts.
- ✅ CI gates run on every PR.
- ✅ Weekly permission audit job is scheduled.
- ✅ All sprint-1 PRs reference the spec pack chapters they implement.
- ✅ Sprint-1 demo recorded.
