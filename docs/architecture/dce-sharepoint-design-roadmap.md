# DCE SharePoint Branding & Page-Build Roadmap

**Date:** 2026-05-15 (session: ~03:00 UTC)
**Status:** Strategic plan — ready for Tyler's decisions
**Tracking bd:** to be filed (see §8)

> This document synthesizes everything we learned tonight about the
> HTT/DCE SharePoint and design-system landscape. It maps what exists,
> what's missing, and the order of operations to build a beautiful,
> on-brand, sustainably-maintained DCE SharePoint experience.

---

## TL;DR

We do NOT need to start from scratch. There is a substantial amount of
existing work in `/Users/tygranlund/dev/01-htt-brands/` that we can
extend to DCE in a few weeks rather than months.

- **SPFx project scaffold:** ✅ exists at `Convention-Page-Build/spfx/`
- **Design system mega brief:** ✅ exists, WCAG-audited, covers HTT/Frenchies/Bishops/TLL
- **Logos for all 5 brands incl. DCE:** ✅ already collected
- **DCE design tokens:** ✅ extracted from `deltacrown.com` (`css/tokens.css`)
- **Per-brand audit worktrees:** ✅ already scaffolded for DCE/BCC/TLL/FN
- **Cross-tenant sync ↔ Crown Connection plumbing:** ✅ working as of tonight
- **Owner-site spec:** ⚠️ exists in `docs/naming-conventions/` but not yet applied to TLL/BCC/FN

The work to do is **integration + DCE-specific customization**, not invention.

---

## 1. What we accomplished tonight (May 15)

| # | Item | Result |
|---|---|---|
| 1 | Crown Connection launched | 57 members, 3 owners, fully populated |
| 2 | OwnerConnection alias added | DeltaSetup-yz2 CLOSED |
| 3 | Cross-tenant EXO pattern documented | `tools/connect-exo-cross-tenant.md` |
| 4 | Cross-tenant sync investigated | DeltaSetup-jch evidence locked in |
| 5 | `SG-DCE-Sync-Users` flipped STATIC → DYNAMIC | New HTT hires auto-flow forever |
| 6 | Jill Holderfield in DCE | resolved (via earlier B2B invite) |
| 7 | DCE asset inventory mapped | this document |

## 2. Existing assets (discovered tonight)

### 2.1 `Convention-Page-Build/` (HTT brands repo)

**Location:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/`

Production repo for HTT Brands Homecoming 2026 (live). Contains:

- `spfx/` — Full SharePoint Framework project with Fluent UI + PnP.js + Style Dictionary
- Tons of audit PowerShell:
  - `audit-sharepoint-sharing.ps1` — cross-site sharing audit
  - `audit-convention-groups.ps1` — M365 group audit
  - `audit-b2b-guests.ps1` — guest user audit
  - `audit-problem-users.ps1` — orphans / pending-acceptance / disabled
  - `fix-external-sharing.ps1` — remediations
  - `fix-static-groups.ps1` — group conversions (we just did this manually for SG-DCE-Sync-Users!)
- `research/` — twenty+ sub-directories of research on every SharePoint topic we care about (theming, mobile, CI/CD, design system, security architecture, PnP page building, notifications, etc.)

### 2.2 `Convention-Page-Build-wts/bd-aj1-dce-audit/` (DCE worktree)

**Location:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/`

This is a sibling worktree specifically for the **DCE audit**. Contains:

- `dce-audit-results.md` — cross-tenant trust verification (PASS as of 2026-04-07)
- `DESIGN_SYSTEM_MEGA_BRIEF.md` — **the bible**:
  - SPFx 1.22.2 / Node 22 / React 17 / TypeScript 5.3.3
  - Style Dictionary 5.3.3 token pipeline
  - Fluent UI Components
  - WCAG 2.2 AA audit of brand colors (HTT/Frenchies/Bishops/TLL — DCE missing, see §4)
  - Playwright multi-browser + axe-core + pa11y CI
  - Recommended project structure (extensions + webparts + tokens)
- `HTT-Brands-SharePoint-Architecture.md` — 5-tier model (native → SPFx)
- `logos/` — Bishops, DeltaCrown, Frenchies, HTT, TLL (PNG + SVG variants)
- `SECURITY_GROUP_AUDIT_REPORT.md`
- `spfx/` — second SPFx project rooted in DCE worktree
- `KAREN_CALL_AGENDA.md` — meeting context for Karen Meek (HTT content manager)

### 2.3 `sharepointagent/` (Python toolkit)

**Location:** `/Users/tygranlund/dev/01-htt-brands/sharepointagent/`

A Python codebase with SharePoint REST + Graph wrappers. Highlights:

- `audit_folder_permissions.py` — recursive permission audit
- `audit_recursive_deep.py` — full-site deep audit
- `analyze_tll_site.py` — TLL-specific analysis (precedent for the cross-brand work)
- `BRAND_INTEGRATION_GUIDE.md` — integration patterns
- `bishops_branded_page.json` — a fully-defined SharePoint page JSON (template precedent for what we'd do for DCE)
- `brand_color_palettes.json` — brand palette web part definition
- Cookie-based auth flow (different from the az-CLI approach we've been using tonight)

### 2.4 `deltacrown.com` (this repo — the public site)

**Location:** `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/`

The `gh-pages` branch IS the live `deltacrown.com` site. Already has:

- `css/tokens.css` — **DCE canonical design tokens** (see §3)
- `assets/logos/` — DCE primary horizontal logo (SVG + PNG, white + royal-gold)
- Production-quality components (`base.css`, `components.css`, `components-v2.css`)
- Accessibility audits already passing (the `tests/` directory has axe + a11y + smoke tests)
- Section-specific stylesheets (`exec-vision`, `ops-story`, `microsoft-platform`, `whiteglove`)

## 3. DCE design tokens — canonical (extracted from `tokens.css`)

```css
/* Brand — Teal family */
--teal:        #006B5E;   /* primary */
--teal-dark:   #004D44;
--teal-deeper: #0A1F1C;   /* hero / surface-dark backdrop */
--teal-light:  #4A9B8E;
--teal-on-dark:#5DB7A9;

/* Accent — Gold family */
--gold:        #D4A84B;
--gold-light:  #E8C989;
--gold-dark:   #6E4F0E;

/* Tertiary */
--sage:        #7A9B8A;

/* Surfaces */
--surface:       #FAFAF7;   /* base off-white */
--surface-dim:   #F0EDE8;
--surface-dark:  #0D2925;
--surface-card:  #FFFFFF;

/* Text */
--text:           #1A2A3A;
--text-secondary: #465463;
--text-muted:     #8A96A4;
--text-inverse:   #F5F5F3;

/* Fonts */
--font-heading: 'Playfair Display', Georgia, serif;
--font-body:    'Tenor Sans', -apple-system, BlinkMacSystemFont, sans-serif;

/* Spacing */
--section-pad: clamp(80px, 12vh, 140px);
--container:   1140px;
--gap:         clamp(16px, 3vw, 32px);
```

**Semantic state colors** (`--success`, `--danger`, `--warn`, `--neutral`) and a **canonical text-on-dark ramp** are also defined and WCAG-audited. The `tokens.css` comments cross-reference audit findings (`audit M1`, `audit H4`, `audit L5`) — this is a mature system.

> **Note for the mega-brief team:** DCE was the one brand missing from the
> mega-brief WCAG audit. The DCE primary (`#006B5E` teal) on white = **7.07:1**
> (AAA ✅). DCE gold (`#D4A84B`) on white = **2.31:1** (decorative only, like
> HTT warm gold). Gold-dark (`#6E4F0E`) on white = **8.27:1** (AAA ✅).

## 4. Current state of DCE SharePoint

| Site | URL | State |
|---|---|---|
| Root | `https://deltacrown.sharepoint.com` | "Communication site" (default tenant root, untouched) |
| DCE Hub | `https://deltacrown.sharepoint.com/sites/dce-hub` | Provisioned, empty (no pages, no lists yet) |
| Crown Connection | `https://deltacrown.sharepoint.com/sites/CrownConnection` | Provisioned tonight, 1 default Documents library, no custom content |

**Read:** the canvas is blank. Whatever we build is the first version
the team sees. That's both an opportunity and a slight pressure to get
the foundations right before content sprawl starts.

## 5. The plan — phased

### Phase 0 — Decisions (THIS WEEK, Tyler-only)

Before code, three product decisions:

1. **DCE Hub audience and purpose.** Earlier notes said it's the
   "operational hub for all DCE staff (owners, managers, lead
   extensionistas, etc.)." Crown Connection is owners+franchisor. Are
   those the only two? Or do we need separate sites for
   leadership/managers vs lead extensionistas vs day-of staff?

2. **CI/CD ambition level.** Three points on the spectrum:
   - **Light:** PnP PowerShell scripts that build pages from JSON
     templates, run manually. Lowest setup, highest agility, no real CI.
   - **Medium:** GitHub Actions runs PnP scripts on push to main,
     deploys to a dev → prod site flow. ~1 day setup.
   - **Heavy:** Full SPFx with Application Customizer + custom web
     parts, App Catalog deployment, full GitHub Actions CI with
     accessibility gates. ~2-3 weeks of focused work but gives you
     pixel-perfect control + permanent branding even non-admins
     can't break.

   The mega-brief already plans Medium-Heavy. I recommend starting
   **Medium**, layering Heavy only where Medium can't paint the
   picture.

3. **Hub-and-spoke architecture.** Does Crown Connection associate to
   DCE Hub as a child? Or stay standalone? The mega-brief's HTT
   architecture model is hub-and-spoke; DCE could mirror or diverge.
   My recommendation: **associate** so Crown Connection inherits the
   hub theme and global navigation when those exist.

### Phase 1 — Foundation (Week 1)

- [ ] Add DCE token file (`dce.json`) to the existing Style Dictionary
      pipeline in `Convention-Page-Build/spfx/src/tokens/brands/`.
      Source values from `deltacrown.com/css/tokens.css` (§3 above).
- [ ] Generate `dce-tokens.css` + Fluent UI theme JSON from Style
      Dictionary. Verify WCAG passing on DCE-specific combinations.
- [ ] Establish DCE Brand Center site (or section in existing site) in
      DCE tenant. Upload approved DCE logos (SVG + PNG, royal-gold +
      white variants).
- [ ] Apply DCE Fluent UI theme to DCE Hub and Crown Connection
      (via SharePoint Admin Center theme upload — no SPFx needed yet).

**Outcome:** Both DCE sites pick up DCE colors + logo in their default
chrome. No SPFx deploys yet.

### Phase 2 — DCE Hub home page (Week 2)

- [ ] Decide page architecture: hero + value props + quick links + news
      + people directory (Bishops/Frenchies/TLL pattern), or a more
      DCE-bespoke shape.
- [ ] Build the home page via PnP PowerShell or the in-browser editor.
      Either way, capture the result as a PnP template JSON for
      versioning.
- [ ] Populate quick-links: brand collateral, owner playbook (if
      exists), HR/IT helpdesk, training calendar.
- [ ] Tag content with audience targeting (owners vs staff vs all).

**Outcome:** DCE Hub looks and feels like a real brand homepage. Visual
parity with `deltacrown.com` patterns.

### Phase 3 — Crown Connection page build (Week 3)

- [ ] Mirror what Frenchies Studio Connection, Bishops Connect, and TLL
      Owners Group are doing (see §6 — pending audit).
- [ ] Sections: pinned announcements / owner spotlight, document hub
      (operational manuals), upcoming events, ask-the-franchisor form,
      owner-only resources.
- [ ] Same PnP template approach as DCE Hub.

**Outcome:** Crown Connection has a real homepage instead of the
default group team-site landing.

### Phase 4 — CI/CD (Weeks 3-4, runs parallel with Phase 3)

- [ ] Decide repo placement. Options:
  - In **this repo** (`DeltaSetup` gh-pages branch) — couples public
    site + intranet repo. Pro: one DCE source of truth. Con: gh-pages
    builds get noisier.
  - In **`Convention-Page-Build`** — keep with HTT/cross-brand work.
    Pro: leverages existing SPFx scaffolding. Con: DCE is its own org,
    might warrant its own repo eventually.
  - **New repo** `Delta-Crown-Org/dce-sharepoint`. Pro: clean
    separation. Con: yet another repo to maintain.

  My recommendation: **new repo** under `Delta-Crown-Org`, scaffolded
  from the existing `Convention-Page-Build/spfx/` directory.

- [ ] Workflow:
  - On push to `main`, run `style-dictionary build` → publish updated
    tokens
  - Run `pnp-powershell` apply against the DCE site (using app-only
    auth with a registered Entra app, secrets in GitHub repo secrets)
  - Optionally run Playwright + axe-core against the live site
- [ ] Quality gates: every push runs accessibility + screenshot
      regression before deploy. This mirrors what
      `deltacrown.com/tests/` already does (the three audit scripts in
      this repo's `AGENTS.md`).

**Outcome:** "Push to main → DCE Hub updates within minutes" pipeline
that anyone on Tyler's team can use without admin rights to SharePoint.

### Phase 5 — Cross-brand owner-site audit (Week 4-5)

**Currently blocked** on having authenticated admin access to Bishops,
Frenchies, and TLL tenants. We have HTT + DCE tokens; we'd need to
authenticate to those three for full audits. The work itself:

- [ ] For each of TLL Owners Group / Bishops Connect / Frenchies Studio
      Connection / HTT Brands Directory ("the cluster") / Crown
      Connection:
  - Page architecture (what sections, what web parts)
  - Document library structure
  - Permission model + inheritance breaks (the "is it a cluster?"
    diagnostic)
  - Branding (theme applied? logo? typography?)
  - Activity metrics (last-modified, # of visitors, # of contributors)
- [ ] Comparison matrix in markdown
- [ ] Recommendations: which patterns to copy, which to fix, which to
      avoid (HTT Brands Directory's mess)
- [ ] If HTT Brands Directory has the broken-inheritance + organisation
      problems Tyler described, file separate bds for the cleanup
      (likely owned by HTT/Karen, not DCE).

**Required input from Tyler:** Az login or app-registration credentials
in BCC, FMNC, TLL tenants. The work is gated on that.

### Phase 6 — Templated patterns for future brand launches (later)

If/when the org launches more brands, the goal is "spin up new brand
hub + connection site in a day, fully branded." That requires:

- Reusable PnP provisioning templates
- A "new-brand" runbook
- Per-brand token files plugged into Style Dictionary

Already conceptually mapped in the mega-brief; just needs execution.

## 6. Cross-brand site comparison (gap — Phase 5)

We have user-facing knowledge that the other brand owner sites exist
and "have styling and design" — but no captured inventory. Phase 5
above produces this.

Until then, what we can already see at the API level (with current
tokens):

| Site | URL | Tenant | Pages (queried) | Notes |
|---|---|---|---|---|
| DCE Hub | `/sites/dce-hub` | deltacrown | 0 (Graph) | Empty canvas |
| Crown Connection | `/sites/CrownConnection` | deltacrown | 0 (Graph) | Empty canvas, 1 default lib |
| HTT Brands Directory | `/` | httbrands | 0 (Graph) | The "cluster" — needs deeper audit |
| HTT Homecoming 2026 | `/sites/Homecoming2026` | httbrands | 0 (Graph) | Production live per its README; Graph scope blocking us from seeing actual page count |

The "0 pages" results are misleading — they're an auth artifact. The
Graph token we get from `az` doesn't include `Sites.Read.All`. To get
real page/list inventory we need either:

- App-registration with `Sites.Read.All` granted (production-grade),
- Or SharePoint REST direct via PnP PowerShell (we proved this works
  earlier tonight with `-DelegatedOrganization`).

This is a Phase-5 setup task, not a Phase-0 blocker.

## 7. CI/CD options matrix (deeper)

Pulled from the mega-brief + the `research/spfx-ci-cd` directory in the
HTT repo.

| Stack | Effort | Maintainability | Hard-coupling risk | When to choose |
|---|---|---|---|---|
| **Manual edits via SharePoint UI** | Zero | None — content drifts | Low | Never for production. Demo only. |
| **PnP PowerShell + JSON templates, run locally** | Low | Medium — runbook required | Low | Good for Phase-1/2 starter |
| **PnP PowerShell + GitHub Actions** | Medium | High | Low | **Sweet spot for DCE** |
| **SPFx + App Catalog + GitHub Actions** | High | Very high | Medium (requires admin App Catalog) | When custom web parts justify it |
| **Brand Center + custom themes (no code)** | Low-Medium | High | Very low | Always layer this in regardless |

**My recommendation:** **PnP PowerShell + GitHub Actions** (medium
column) for Phase 4. Add Brand Center setup in Phase 1. Defer SPFx
custom web parts until we hit a wall the medium stack can't solve.

## 8. Bds to file

- [ ] **DeltaSetup-?? (P1):** "Phase 1 — Add DCE tokens + Brand Center
      + theme to DCE tenant"
- [ ] **DeltaSetup-?? (P1):** "Phase 2 — DCE Hub home page build"
- [ ] **DeltaSetup-?? (P2):** "Phase 3 — Crown Connection home page build"
- [ ] **DeltaSetup-?? (P2):** "Phase 4 — CI/CD pipeline for DCE SharePoint
      (PnP + GitHub Actions)"
- [ ] **DeltaSetup-?? (P2):** "Phase 5 — Cross-brand owner-site audit
      (requires multi-tenant auth)"
- [ ] **DeltaSetup-?? (P3):** "HTT Brands Directory cleanup
      (permission-inheritance + organisation)" — likely OUT OF SCOPE
      for the DCE setup repo; raise on the HTT side instead.

The first one should reference this document.

## 9. Decisions on the table for Tyler

| # | Decision | Default if no answer | Impact if changed later |
|---|---|---|---|
| 1 | DCE Hub audience scope | All-staff hub like the mega-brief plans | Easy — just adjust audience targeting |
| 2 | CI/CD ambition (Light / Medium / Heavy) | Medium (PnP + Actions) | Light → Medium is easy; Medium → Heavy is significant rebuild |
| 3 | Hub-spoke association | Yes — Crown Connection associates to DCE Hub | Trivial to flip |
| 4 | Repo placement | New repo `Delta-Crown-Org/dce-sharepoint` | Easy to move later |
| 5 | Are there HTT users we deliberately don't want in DCE? | No (the dynamic group includes ALL enabled HTT users) | Add `-and (user.companyName -ne "X")` to membershipRule |

## 10. Things to investigate but NOT now (future sessions)

- **Multi-Tenant Organization with DCE**: would simplify all of this
  even further, eliminating B2B-style UPNs. Out of scope for the
  immediate work but worth a real evaluation in Q3.
- **The HTT-side TLL/FMNC sync apps**: same architecture, presumably
  same group-based gate. If we're flipping dynamic for DCE, we should
  consider doing the same for TLL+FMNC if their HR onboarding has
  similar drift. (Filed observation for HTT side.)
- **Karen Meek's content-edit workflow**: she does HTT Homecoming
  content edits directly in SharePoint. We want DCE to have the same
  "non-developer can edit copy without breaking branding" property.
  Architecturally that's the Application Customizer pattern from the
  mega-brief.

## 11. Security note (carried from the mega-brief)

The mega-brief flagged that `Convention-Page-Build/ACCESS_TOKEN.sh`
allegedly contained a live JWT with Global Admin privileges committed
to the repo. **This is from another agent's prior session and should be
verified.** If still present, it needs to be rotated and removed from
git history (filter-branch / BFG). Out of scope for THIS repo, but if
it's confirmed still live it's a CRITICAL finding for the
`Convention-Page-Build` repo.

---

## Closing

Crown Connection launch is COMPLETE for tonight. This doc is the bridge
between "we shipped a working group" and "we ship a beautiful branded
SharePoint experience that any team member can extend." Tyler's three
Phase-0 decisions unblock everything else.

## Companion: the AI agent reference pack

Added 2026-05-15 — a self-contained spec pack designed to be consumed
by an AI agent (Claude, ChatGPT 5.5 Pro, etc.) to build the
implementation against:

**`docs/sharepoint-pnp-spec/`** — 26 files:

- `PROMPT-PACK-FOR-AI.md` — the entry-point handoff doc.
- `EVALUATION-RUBRIC.md` — scoring grid for adversarial model
  comparison (Puppy vs ChatGPT bake-off).
- Numbered chapters 00-12 covering context, architecture, identity
  & audience, design system, content architecture, permissions,
  PnP tooling, CI/CD, quality gates, deployment, runbooks, and
  implementation plan.
- 7 ADRs documenting major decisions.
- `reference/dce-tokens.json` — canonical Style Dictionary token file
  derived from this repo's `css/tokens.css`.
- `reference/existing-assets-inventory.md` — annotated inventory of
  ALL prior art in `/Users/tygranlund/dev/01-htt-brands/` and this
  repo so the implementing agent doesn't re-invent.

The spec pack is structured so two competing AI models can produce
outputs scored on the same rubric. Tyler will run ChatGPT 5.5 Pro
against it in a parallel session and compare results.
