# Existing Assets Inventory

> Anything you would have built from scratch should be searched for here
> FIRST.

This document was compiled 2026-05-15 from a live scan of Tyler's dev
machine. Paths assume macOS (the agent's working environment).

---

## 1. SPFx scaffolds

### 1A. `Convention-Page-Build/spfx/` ★★★★★

**Path:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/spfx/`

**Status:** Production SPFx project for HTT Brands Homecoming 2026 (live).

**Contents (top level):**

- `config/` — SPFx build config
- `src/` — TypeScript + React 17 web parts and extensions
- `sharepoint/` — packaged `.sppkg` outputs
- `release/` — production builds
- `scripts/` — deploy automation
- `gulpfile.js` — build pipeline
- `webpack.config.js` — webpack override
- `package.json` — Node 22, React 17.0.1, TypeScript 5.3.3, Fluent UI v9, PnP.js
- `deploy-spfx.ps1` — PowerShell deploy script
- `tsconfig.json`

**Reuse for DCE:** Yes. Copy this scaffold structure into the new
`dce-sharepoint` repo. Strip HTT-specific tokens; keep the build pipeline.

### 1B. `Convention-Page-Build-wts/bd-aj1-dce-audit/spfx/` ★★★★☆

**Path:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/spfx/`

**Status:** A worktree-scoped SPFx project specifically for DCE audit.

**Reuse:** Reference for DCE-specific patterns. Some configs may already
have DCE token placeholders.

---

## 2. Design system documentation

### 2A. `DESIGN_SYSTEM_MEGA_BRIEF.md` ★★★★★

**Path:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/DESIGN_SYSTEM_MEGA_BRIEF.md`

**Compiled by:** Web-Puppy + Experience Architect + Solutions Architect
+ code-puppy-99d680, 2026-03-19.

**Sections:**

1. Platform Foundation (SPFx + Node)
2. Brand Color WCAG Audit (HTT, Frenchies, Bishops, TLL — NOT DCE; we fill in)
3. Typography & Fonts
4. Design Token Pipeline (Style Dictionary 3-tier)
5. Component Library & UI Building Blocks
6. Iconography (Phosphor Icons recommended)
7. JotForm Embed
8. Playwright Multi-Browser Testing
9. CI/CD + Accessibility Automation
10. Security Findings (Critical — see §11 below)
11. Full NPM Install Cheatsheet
12. File Map

**Reuse:** Treat as the canonical reference for all stack choices.

### 2B. `HTT-Brands-SharePoint-Architecture.md` ★★★★★

**Path:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/HTT-Brands-SharePoint-Architecture.md`

**Contents:** 5-tier architecture model (Native → Brand Center → PnP →
SPFx → Third-party). Phase 1-5 roadmap. Brand identity foundations.

**Reuse:** Tier 4 (SPFx) is informative; we're following that pattern.
The HTT-specific implementation is a precedent.

### 2C. `brand_color_palettes.json` ★★★★☆

**Path:** `/Users/tygranlund/dev/01-htt-brands/sharepointagent/brand_color_palettes.json`

**Contents:** Pre-built SharePoint web part JSON with brand color
palette content (HTT colors).

**Reuse:** Template precedent for how to define a colored content block
as a SharePoint web part JSON.

### 2D. `BRAND_INTEGRATION_GUIDE.md`

**Path:** `/Users/tygranlund/dev/01-htt-brands/sharepointagent/BRAND_INTEGRATION_GUIDE.md`

**Reuse:** Read for context on how brand integration was done HTT-side;
adapt patterns where applicable.

---

## 3. Audit + analysis tools

### 3A. `sharepointagent/` (Python toolkit) ★★★★☆

**Path:** `/Users/tygranlund/dev/01-htt-brands/sharepointagent/`

**Key files:**

- `audit_folder_permissions.py` — Recursive permission audit using
  SharePoint REST API. Outputs CSV.
- `audit_recursive_deep.py` — Full-site deep audit.
- `audit_recursive_deep_with_token.py` — Same, but with token-based
  auth (preferred for our use).
- `audit_folders_sp.py` — Folder-only audit.
- `analyze_tll_site.py` — TLL-specific analysis (precedent for the
  cross-brand audit we'll do in Phase 5).
- `add_users_to_site.py` — Bulk user-add to a SharePoint site.
- `bishops_branded_page.json` — A complete branded SharePoint page in
  JSON (template precedent for DCE pages).

**Auth model:** Cookie + access-token (not the cleanest; we wrap it).

**Reuse:** Critical for Phase 5 cross-brand audit + weekly permission
audit job in DCE. Don't re-implement these.

### 3B. PowerShell audit scripts

**Path:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/`

- `audit-b2b-guests.ps1`
- `audit-convention-groups.ps1`
- `audit-problem-users.ps1`
- `audit-sharepoint-sharing.ps1`
- `fix-external-sharing.ps1`
- `fix-static-groups.ps1` (we used the manual equivalent of this tonight!)
- `verify-all-fixes.ps1`

**Reuse:** Direct PowerShell patterns for graph + PnP operations. Many
are HTT-specific but the patterns translate.

---

## 4. Logos and brand assets

### 4A. Logos directory ★★★★★

**Path:** `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/logos/`

Contains brand-specific subdirectories:

```
logos/
├── Bishops/
│   ├── BB logo ORANGE.png
│   ├── BB logo WHITE.png
│   └── logo-bishops-cuts-color_white.svg
├── DeltaCrown/                                            ← OUR LOGOS
│   ├── primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_royal-gold.png
│   ├── primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_white.png
│   └── primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_white.svg
├── Frenchies/
│   ├── logo-frenchies-fmn_navy.png
│   ├── logo-frenchies-fmn_white.png
│   └── logo-frenchies-fmn_white.svg
├── HTT/
│   ├── Head To Toe logo_horizontal_Maroon.png
│   └── Head To Toe logo_horizontal_White.png
└── TLL/
    ├── Stacked_Logo_TLL_Amethyst.png
    ├── Stacked_Logo_TLL_White.png
    └── stacked-logo-tll_white (1).svg
```

**Reuse:** Use DeltaCrown logos directly. We have horizontal logo in
two color variants (royal-gold for light backgrounds, white for dark).
SVG is available; prefer over PNG.

---

## 5. DCE-side assets (this repo)

### 5A. `deltacrown.com/css/tokens.css` ★★★★★

**Path:** `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/css/tokens.css`

**Status:** Production. Source of truth.

**Contents:** Complete CSS custom properties for color, surface, text,
font, spacing, motion, state colors, breakpoints. Includes WCAG audit
references (audit M1, H4, L5).

**Reuse:** Converted to `reference/dce-tokens.json` for Style Dictionary
consumption. Do not duplicate.

### 5B. `deltacrown.com` component CSS ★★★★☆

**Path:** `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/css/`

Files: `base.css`, `components.css`, `components-v2.css`, plus section
stylesheets (`exec-vision.css`, `ops-story.css`, etc.).

**Reuse:** Read for component patterns. These power the production
public site and are battle-tested. Likely won't copy-paste into SPFx
verbatim but the patterns transfer.

### 5C. Audit scripts (this repo)

**Path:** `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/tests/`

- `accessibility_static_audit.py`
- `browser_smoke_audit.py`
- `accessibility_axe_audit.py`

**Reuse:** Pattern for accessibility gates. The new `dce-sharepoint`
repo's quality gates will mirror this approach.

### 5D. Tools (this repo)

**Path:** `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/tools/`

- `connect-exo-cross-tenant.md` — cross-tenant EXO pattern (discovered
  tonight). Critical for cross-tenant Exchange ops.
- `expand-crown-connection-htt-corp.py` — idempotent group membership
  expansion. Already running.
- `invite-htt-users-to-dce.py` — emergency B2B invite tool.
- `provision-crown-connection.sh` — Crown Connection provisioning script.

**Reuse:** Direct references. Some will move to the new repo.

---

## 6. Security findings flagged but not yet remediated

### `Convention-Page-Build/ACCESS_TOKEN.sh`

**Status:** Mega brief (2026-03-19) flagged this file as containing a
live JWT with Global Admin privileges committed to the repo.

**Action required:** Verify and rotate. **Not in scope for DCE work**
but a CRITICAL finding for the HTT-side repo. Should be filed on the
HTT side immediately.

---

## How to use this inventory

When you're about to scaffold something, search this file. If the
asset exists, **reuse or extend**. Do not rebuild.

The rubric `EVALUATION-RUBRIC.md` § 1 weights reuse at 20%. Skipping
this inventory is the fastest way to lose the bake-off.
