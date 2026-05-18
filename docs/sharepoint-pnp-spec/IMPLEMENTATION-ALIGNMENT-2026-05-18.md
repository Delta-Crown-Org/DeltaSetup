# DCE SharePoint Hub/Spoke + SPFx CI/CD Alignment Check

**Date:** 2026-05-18  
**Owner:** Tyler Granlund  
**Prepared by:** code-puppy-73a4b6  
**Purpose:** reconcile the research/spec/mockup/bd database before building the real `Delta-Crown-Org/dce-sharepoint` implementation repo.

---

## Executive call

The repo has enough research and prototype material to start the real SharePoint implementation, but **not by blindly copying the current docs**. The implementation path is aligned at the architecture level, with three blocking spec defects that must be resolved before scaffolding the real SPFx/CI/CD repo.

Recommended sequence:

1. Clear ADR/security gates that unblock spec corrections.
2. Create `Delta-Crown-Org/dce-sharepoint` from the agreed scaffold.
3. Land token/theme foundations and Brand Center tests.
4. Build Hub home with PnP/OOTB first.
5. Add SPFx only when OOTB cannot deliver the required experience.

---

## Source stack we are aligning

| Layer | Source of truth / evidence | Current alignment |
|---|---|---|
| Strategic roadmap | `docs/architecture/dce-sharepoint-design-roadmap.md` | Aligned: Medium PnP-first, Heavy SPFx later if justified. |
| Sprint plan | `docs/sharepoint-pnp-spec/12-implementation-plan.md` | Mostly aligned; depends on repo creation + tenant prerequisites. |
| Tooling spec | `docs/sharepoint-pnp-spec/06-tooling-pnp.md` | Aligned to ADR-010 Fluent UI v8. |
| CI/CD spec | `docs/sharepoint-pnp-spec/07-ci-cd-pipeline.md` | Aligned to Heft-only SPFx build guidance. |
| Design system | `docs/sharepoint-pnp-spec/03-design-system.md` | Aligned to ADR-010; token model is otherwise strong. |
| ADRs | `docs/sharepoint-pnp-spec/decisions/` | ADR-006, ADR-009, and ADR-010 accepted. |
| Mockup | `dce-mockup/` | Strong prototype; not itself the production repo. |
| SPFx portability proof | `dce-mockup/spfx-skeleton/` | Aligned to Fluent UI v8 imports/theme provider. |
| Research deltas | `dce-mockup/RESEARCH-DELTAS.md` | Critical correction log; should be treated as blocking context. |
| External mega-guide | `docs/sharepoint-research/chatgpt-5.5-pro/htt-sharepoint-infrastructure-development-guide.md` | Useful background; some YAML examples still show gulp and must not override project-specific Heft decision. |
| bd database | `bd ready`, `bd show DeltaSetup-*` | Correctly captures the blocker chain. |

---

## What is aligned and ready

### 1. Architecture direction

The project direction is consistent:

- DCE Hub = operational hub for staff/audience-targeted content.
- Crown Connection = owner/franchisor communication surface.
- Hub/spoke model is the intended tenant pattern.
- PnP templates + GitHub Actions are the sprint-1 delivery mechanism.
- SPFx is a later/heavy tier unless OOTB SharePoint cannot satisfy the UX.

Supporting docs:

- `docs/architecture/dce-sharepoint-design-roadmap.md`
- `docs/sharepoint-pnp-spec/01-architecture.md`
- `docs/sharepoint-pnp-spec/12-implementation-plan.md`
- `docs/sharepoint-pnp-spec/decisions/005-defer-spfx-custom-webparts.md`

### 2. Repo placement

The intended implementation repo is:

```text
Delta-Crown-Org/dce-sharepoint
```

This is consistent across:

- `docs/sharepoint-pnp-spec/07-ci-cd-pipeline.md`
- `docs/sharepoint-pnp-spec/12-implementation-plan.md`
- `docs/sharepoint-pnp-spec/decisions/006-repo-placement.md`
- bd `DeltaSetup-emj`

Caveat: `decisions/006-repo-placement.md` says **Status: Proposed** even though the body says **Accepted**. Clean this during ADR gate cleanup.

### 3. Token and brand foundation

The token story is coherent:

- Public site `css/tokens.css` is the governed source.
- `docs/sharepoint-pnp-spec/reference/dce-tokens.json` is the Style Dictionary source projection.
- SharePoint theme output should be generated, not hand-authored.
- DCE gold is decorative-only on white; teal/dark teal are text-safe.

Supporting docs:

- `docs/sharepoint-pnp-spec/03-design-system.md`
- `docs/sharepoint-pnp-spec/reference/dce-tokens.json`
- `research/deltacrown-design-tokens/`
- `dce-mockup/css/tokens.css`

### 4. Notification suppression and provisioning safety

ADR-011 static enforcement is now much stronger:

- Active CI/CD scripts have mode signaling.
- Phase 2/3 historical scripts were retrofitted and removed from grace period.
- Fitness test currently passes:

```bash
pytest tests/architecture/test_notification_suppression.py -v
# 8 passed
```

Remaining grace-period scripts are historical `tools/` incident scripts, not the active SharePoint build path.

---

## Blocking alignment gaps

### Gap A — Fluent UI version lock is resolved

**bd:** `DeltaSetup-7bm`  
**Resolution:** ADR-010 accepted; SPFx custom components use Fluent UI v8
(`@fluentui/react` 8.121.0).

Implemented alignment:

- `03-design-system.md` describes a Fluent UI v8 `ITheme` token map.
- `06-tooling-pnp.md` pins `@fluentui/react` 8.121.0.
- `dce-mockup/spfx-skeleton/` imports `ThemeProvider`, `createTheme`, and
  `ITheme` from `@fluentui/react`.

A future migration to Fluent UI v9 requires a superseding ADR.

### Gap B — CI/CD samples need Heft alignment

**bd:** `DeltaSetup-303`  
**Blocked by:** `DeltaSetup-jn4`

Current contradiction:

- Some research/examples still use classic SPFx gulp commands:

```bash
npx gulp bundle --ship
npx gulp package-solution --ship
```

- Project-specific research says SPFx 1.22+ scaffold uses Heft:

```bash
npx heft build --production
npx heft package-solution --ship
```

Rule for implementation repo: **do not cargo-cult gulp snippets from research docs**. Use the Heft commands after ADR-006/ADR-010 cleanup lands.

### Gap C — Repo creation is blocked by governance/spec gates

**bd:** `DeltaSetup-emj`  
**Blocked by:** `DeltaSetup-jn4`

The implementation repo should not be created until the toolchain decision is stable. Otherwise we create a repo, immediately churn dependencies, and everyone gets to enjoy dependency archaeology. No thanks.

---

## bd pipeline alignment

### Immediate unblockers

| bd | Why it matters |
|---|---|
| `DeltaSetup-jn4` | Security Auditor cosign for ADR-006. Unblocks Fluent lock, Heft spec correction, and repo creation. |
| `DeltaSetup-7bm` | Writes ADR-010 and makes Fluent UI version consistent across docs/mockup/skeleton. |
| `DeltaSetup-303` | Replaces gulp-era CI guidance with Heft guidance. |
| `DeltaSetup-emj` | Creates/seeds the real `dce-sharepoint` implementation repo. |

### Foundation build chain

| bd | Implementation meaning |
|---|---|
| `DeltaSetup-ebk` | Phase 1: tokens + Brand Center + generated SharePoint theme. |
| `DeltaSetup-j6o` | Adds golden-image/schema fitness test for generated Brand Center `theme.json`. |
| `DeltaSetup-8p5` | Phase 2: DCE Hub home page build. |
| `DeltaSetup-b59` | Phase 3: Crown Connection home page build. |
| `DeltaSetup-7al` | Phase 4: CI/CD pipeline with PnP + GitHub Actions. |

### Identity/audience prerequisites

| bd | Why it matters |
|---|---|
| `DeltaSetup-au3` | Creates `DCE-HTT-Corporate-Sync`, required for Crown Connection / R6 targeting. |
| `DeltaSetup-1b3` | Populates user metadata so dynamic groups resolve. Required for reliable audience targeting. |
| `DeltaSetup-4ay` | Teams inventory/read-context blocker; affects Teams-connected hub/spoke confidence. |

---

## Recommended build spine

### Phase 0 — alignment and governance

1. Complete `DeltaSetup-jn4`.
2. Complete `DeltaSetup-7bm` with ADR-010.
3. Complete `DeltaSetup-303`.
4. Update `decisions/006-repo-placement.md` status if Tyler confirms repo placement.

### Phase 1 — create implementation repo

1. Complete `DeltaSetup-emj`.
2. Seed repo with:
   - `AGENTS.md`
   - token build skeleton
   - PnP template directories
   - GitHub Actions stubs
   - ADR links back to this spec pack
   - copied/normalized `dce-mockup/ci-cd` scripts
3. Do **not** copy public-site pages into the repo as production source. The mockup is reference material, not the source of truth.

### Phase 2 — token/theme/Brand Center

1. Complete `DeltaSetup-ebk`.
2. Complete `DeltaSetup-j6o`.
3. Output artifacts:
   - `dist/css/dce-tokens.css`
   - `dist/sharepoint/theme.json`
   - `dist/fluent/fluentui-theme-dce.*` only after Fluent version lock is final

### Phase 3 — PnP/OOTB pages first

1. Build Hub home via PnP templates and OOTB parts.
2. Use audience targeting with Entra groups only.
3. Avoid permission breaks unless documented in `05-permissions-model.md`.
4. Snapshot/export after manual/editor adjustments to keep repo truth current.

### Phase 4 — CI/CD hardening

1. Add PR validation:
   - token build
   - PnP template syntax
   - ADR-011 notification suppression tests
   - Playwright smoke/a11y where feasible
2. Add dev deploy.
3. Add prod deploy behind GitHub Environment approval.
4. Add permission audit cron.
5. Add SPFx build workflow only when actual SPFx code enters the repo.

### Phase 5 — SPFx only if justified

SPFx enters when one of ADR-005 triggers happens:

- OOTB/Brand Center cannot deliver required hero/card/news fidelity.
- Multi-source news or real Graph-backed KPI tiles are required.
- Viva Connections/Adaptive Card Extensions become sprint scope.
- Global header/footer requires Application Customizer.

---

## Implementation guardrails

1. **Fluent UI work follows ADR-010: v8 only unless superseded.**
2. **No SPFx dependency copying outside the ADR-010 pins.**
3. **No gulp commands in production CI unless ADR explicitly reverses the Heft decision.**
4. **No notification-capable provisioning script without `-Mode scaffold|launch` and `PROVISIONING-MODE:` logging.**
5. **No direct-user audience targeting. Use groups only.**
6. **No SharePoint audience targeting as security. Visibility is not authorization.**
7. **No production page edits without exporting/syncing templates back to git.**
8. **No launch-mode notification path outside the `launch` GitHub Environment.**

---

## Bottom line

Everything is directionally aligned, but the next real work is not “build pages immediately.” It is:

```text
ADR-006 accepted
  → ADR-010 Fluent lock accepted
  → Heft CI doc correction complete
  → dce-sharepoint repo creation
  → token/theme foundation
  → DCE Hub home
  → Crown Connection home
  → CI/CD hardening
  → SPFx only where justified
```

That keeps the research, bd database, mockup, and implementation path pulling in the same direction instead of creating yet another beautiful-but-fragile SharePoint snow globe.
