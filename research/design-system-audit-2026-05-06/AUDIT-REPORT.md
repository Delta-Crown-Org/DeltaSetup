# DeltaSetup — Design System & WCAG 2.2 AA Audit

**Auditor:** experience-architect agent (session `experience-architect-session-d035f9`)
**Coordinated by:** code-puppy-13b0ad (Richard)
**Date:** 2026-05-06
**Standard:** WCAG 2.2 AA (March 2026 baseline)
**Scope:** `index.html` (1,655 lines), `operations.html` (343 lines), 8 stylesheets in `css/`
**Trigger:** Owner reported layout, spacing, breakpoint weirdness and contrast issues across the gh-pages site. Screenshot showed Project Progress section with phase cards squeezed to one-word-per-line columns at desktop width.

---

## Executive summary

1. **One structural root cause drives most layout pain.** Every `@media (max-width: …)` query in this codebase is **viewport-relative**, but `body.has-sidebar` removes 288 px from the content well. At a 1280–1408 px viewport (typical 13–15" laptop), content area is **only 992–1120 px** while desktop breakpoints (≥1100, ≥900, ≥800) all still fire. Phase cards, audit blueprint, exec-intro grid, and portfolio grid are all squeezed simultaneously. **This is the bug Tyler is seeing in the screenshot.**
2. **`grid--5` is not the only offender** — `.grid--2`, `.grid--3`, `.grid--4` all also use `repeat(N, 1fr)` with **no `minmax(0, 1fr)`**, which lets word-level overflow escape grid columns. `.grid--3` is even **defined twice in `styles.css`** (lines 245 + 770) with conflicting breakpoint sets.
3. **Two status-pill bugs are visible to users right now:** `status--success` is referenced 2× but doesn't exist (renders unstyled), and `status--done` is reused for a "Skipped" pill (renders green / "complete" semantics on a phase that was actively *not* done — a misleading state).
4. **WCAG 2.2 AA contrast fails in five locations** — `.status--pending` text, the muted hero subtitle (`rgba(255,255,255,0.35)`), `.sidebar__link-tag` muted variant, `.audit-owner-table caption`, and `.footer` text all sit between 2.0:1 and 3.1:1 on dark. Body-text minimum is 4.5:1.
5. **Eight stylesheets, ~3,500 lines, with no governance document.** Grid declarations live in 4 files; status pills in 2 files; breakpoints range across **eight different values** (500/540/620/640/700/720/760/768/800/900/1000/1020/1023/1100). High cascade risk; cannot be safely edited without a regression sweep.
6. **The 7 non-automatable WCAG 2.2 criteria are partly addressed** (skip link, `:focus-visible`, `prefers-reduced-motion`, `scroll-padding-top` for sidebar) but **focus indicator contrast on light surfaces fails 2.4.13**, and **target size on inline status pills with icons is borderline 24×24**.

---

## CRITICAL — ship-blockers (visible to users now)

### C1 · Phase Progress grid collapses content into vertical word-strips at desktop
**Evidence:** `index.html:1326` (`<div class="grid grid--5 stagger mb-48">`), `css/styles.css:762-764`
```css
.grid--5 { grid-template-columns: repeat(5, 1fr); }
@media (max-width: 1100px) { .grid--5 { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 700px)  { .grid--5 { grid-template-columns: 1fr; } }
```
Three problems compounding:
1. No `minmax(0, 1fr)` — children's intrinsic min-content (longest word) sets the column min-width, so cards refuse to shrink and content wraps awkwardly inside them.
2. The viewport breakpoint at 1100 px doesn't account for the 288 px sidebar — at viewport 1280 px the rule is *false* (sidebar pages are still 5-col) but the content well is only 992 px, so each column gets `(992 − 32×4) / 5 ≈ 173 px` after gaps.
3. There is no intermediate step between 5-col and 3-col, so the grid jumps from "too many columns" straight to "still too many columns."

**Proposed fix:**
```css
.grid--5 { grid-template-columns: repeat(5, minmax(0, 1fr)); }
@media (max-width: 1407px) { .grid--5 { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
@media (max-width: 1023px) { .grid--5 { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 640px)  { .grid--5 { grid-template-columns: 1fr; } }
```

### C2 · `.status--success` class is referenced but does not exist
**Evidence:** `index.html:1385` and `index.html:1455` use `<span class="status status--success">Complete</span>`. Defined in `css/styles.css:601-605` — only `--done`, `--active`, `--pending`, `--danger` exist. Both Phase 3 and Phase 5 pills render with no background and no color.

**Proposed fix:** Add canonical state classes:
```css
.status--success { background: rgba(46,125,50,0.18); color: #66BB6A; }
.status--skipped { background: rgba(120,144,156,0.16); color: #B0BEC5; }
.status--blocked { background: rgba(239,83,80,0.16); color: #EF5350; }
```

### C3 · Phase 4 "Skipped" pill uses `status--done` (green) — misleading semantics
**Evidence:** `index.html:1420` — `<span class="status status--done">Skipped</span>`. Card wrapper is also `phase-card phase-card--done`. Visually identical to a completed phase.

**Proposed fix:** Add `phase-card--skipped` modifier and use `status--skipped` from C2.

### C4 · Phase card titles all hard-coded to `#4CAF50` regardless of state
**Evidence:** `index.html:1330, 1357, 1384, 1419, 1454` — every Phase 1–5 title has inline `style="color: #4CAF50;"`, including Phase 4 (Skipped).

**Proposed fix:** Remove inline overrides; let card variant CSS scope the title color.

---

## HIGH — WCAG AA failures and breakpoint breakage

### H1 · Five color combinations fail WCAG 2.2 SC 1.4.3 (Contrast: Minimum)

| # | Token / Class | Effective text color | Bg | Ratio | Required | Result |
|---|---|---|---|---|---|---|
| 1 | `.status--pending` color `rgba(255,255,255,0.4)` | ≈ `#6C7977` | pill bg over deep teal ≈ `#182C29` | **3.05 : 1** | 4.5 : 1 | ❌ FAIL body |
| 2 | Hero post-status copy `rgba(255,255,255,0.35)` (`index.html:154`) | ≈ `#606D6B` | `#0A1F1C` | **3.03 : 1** | 4.5 : 1 | ❌ FAIL body |
| 3 | `--sidebar-text-muted: rgba(255,255,255,0.36)` on `.sidebar__link-tag` muted bg | ≈ `#626F6D` | `≈ #1B2F2C` | **3.04 : 1** | 4.5 : 1 | ❌ FAIL body |
| 4 | `.audit-owner-table caption` `rgba(255,255,255,0.46)` | ≈ `#7A8584` | `≈ #1F1F1F` | **3.91 : 1** | 4.5 : 1 | ❌ FAIL body |
| 5 | `.footer` color `rgba(255,255,255,0.25)` | ≈ `#454F4D` | `#050E0C` | **2.02 : 1** | 4.5 : 1 (3 : 1 large) | ❌ FAIL all |

**Borderline:** `.cascade__time` and `.exec-intro__card-headline` use `rgba(255,255,255,0.45)` ≈ 3.96:1 — fails AA body, passes only as ≥18 pt large text.

**Passes (recorded as evidence):**
- `#4CAF50` on `phase-card--done` bg ≈ 7.7 : 1 ✓
- `--gold-light` on `#101010` ≈ 12 : 1 ✓
- `--sidebar-text` (0.62) ≈ 7.06 : 1 ✓
- `.audit-hero__card p` (0.64) ≈ 6.88 : 1 ✓ (so the new MSP/CSP section is fine except the table caption)

**Proposed fixes (single-line bumps):**
```css
.status--pending { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.72); }
.footer { color: rgba(255,255,255,0.55); } /* was 0.25 */
--sidebar-text-muted: rgba(255, 255, 255, 0.58); /* was 0.36 */
.audit-owner-table caption { color: rgba(255,255,255,0.62); } /* was 0.46 */
```

### H2 · Focus indicator may fail SC 2.4.13 (Focus Appearance) on light surfaces
**Evidence:** `css/styles.css:69-72` — `*:focus-visible { outline: 3px solid var(--gold); }`. `--gold` is `#D4A84B` (luminance ≈ 0.42). Against `--surface` `#FAFAF7` (luminance ≈ 0.96) the outline-vs-adjacent contrast is **≈ 2.84 : 1**. SC 2.4.13 requires 3:1 minimum.

**Proposed fix:**
```css
*:focus-visible { outline: 3px solid var(--gold-dark); outline-offset: 3px; }
.section--dark *:focus-visible,
.section--teal *:focus-visible,
.section--danger *:focus-visible,
.sidebar *:focus-visible,
.hero *:focus-visible {
  outline-color: var(--gold-light);
}
```

### H3 · `.grid--2`, `.grid--3`, `.grid--4` all replicate the `grid--5` flaw
**Evidence:** `css/styles.css:244-256` — no `minmax(0, 1fr)` on any base grid; single jump from N-col → 1-col at 900 px is too coarse. **`grid--3` is redeclared at lines 770-779** with conflicting breakpoint set (1100/900/600).

**Proposed fix:** Consolidate base grids and add an intermediate step (1407px) plus delete the duplicate.

### H4 · Breakpoint values are inconsistent across files (eight different thresholds)

| Breakpoint | Where | Used for |
|---|---|---|
| 500 | `styles.css:443` | `.cascade__item` |
| 540 | `exec-vision.css:68` | `.exec-intro__grid` |
| 620 | `polish.css:181` | `.reality-digest`, `.role-lens__grid` |
| 640 | 3 files | audit panels, ops-scenes, op-system-strip |
| 700 | 5 places | flow, compare, grid--5, portfolio |
| 720 | `microsoft-platform.css:580` | `.msp-raci` thead |
| 760 | `whiteglove.css:241` | sequence |
| 768 | `styles.css:184/792` | nav, mobile toggle |
| 800 | 8 places | arch, migration, transform-compare, flowdir, sepconn |
| 900 | 3 places | base grids, exec-intro |
| 1000 | 2 files | audit, ops |
| 1020 | `polish.css:174` | reality-digest |
| 1023 | `sidebar.css:240` | **sidebar collapse** |
| 1100 | 3 places | grid--5, portfolio, op-system |

**Proposed canonical scale:** 640 / 1023 / 1407 (sm / md / lg). Bulk-rewrite all media queries to align.

### H5 · `.audit-blueprint` 5-column layout collapses too late on sidebar pages
**Evidence:** `css/microsoft-platform.css:152-161, 498-501`. Collapse at 1000 px misses the 1280 px sidebar squeeze. Move to 1023 px.

### H6 · `.exec-intro__grid`, `.role-lens__grid`, `.audit-next-steps__grid`, `.op-impact-grid`, `.op-future-track` (all 4-col) squeeze on sidebar viewports
At viewport 1280 px / content well 992 px each card gets ~208 px. Add a 3-col intermediate at 1407 px and align collapse to 1023 px across all five components.

### H7 · `.status` pills with embedded Material icon are borderline for SC 2.5.8 (Target Size)
27.8 px tall — clears 24×24 minimum, but icon-only span inside is 14×14. **Flag as future-proofing concern** if pills ever become interactive.

---

## MEDIUM — design system hygiene & token leakage

### M1 · Inline-style hex colors leaking past the token system
**Evidence:** `index.html` contains literal hex `#4CAF50` **27 times**. Other leaks: `#EF5350`, `var(--gold)` literally written into `style="color: var(--gold);"`, and `rgba(255,255,255,0.X)` with **eight different alpha values** scattered across 25+ inline styles.

**Proposed fix:** Extend token system:
```css
:root {
  --success:       #4CAF50;
  --success-soft:  rgba(46,125,50,0.12);
  --danger:        #EF5350;
  --danger-soft:   rgba(239,83,80,0.12);
  --warn:          #FB8C00;
  --warn-soft:     rgba(251,140,0,0.10);

  --text-on-dark:        rgba(255, 255, 255, 0.92);
  --text-on-dark-muted:  rgba(255, 255, 255, 0.70);
  --text-on-dark-subtle: rgba(255, 255, 255, 0.58);
}
```
Plus utility classes: `.text-success`, `.text-danger`, `.text-warn`, `.text-on-dark-muted`, `.text-on-dark-subtle`.

### M2 · Duplicate / conflicting CSS rules across the 8 stylesheets

| Selector | Defined in | Conflict |
|---|---|---|
| `.grid--3` | `styles.css:245` AND `styles.css:770-786` | Same file, two definitions, different breakpoints |
| `.status--*` | `styles.css:602-605` AND `presentation/css/styles.css:589-592` | Two separate copies — drift risk |
| `:root` | `styles.css:21-50` AND `sidebar.css:8-15` | Token block split across files |
| Mobile collapse @ 768/1023/640 | `styles.css:184`, `sidebar.css:240`, `microsoft-platform.css:514` | Three "small viewport" breakpoints firing in sequence |
| `.section--dark` p color | `styles.css:101` | Then overridden inline in 25+ places with different alphas — base rule almost never applies |

**Proposed fix:** Phase-2 file-structure refactor (`tokens.css` extracted, `components/` folder). Defer to post-launch; deduplicate `.grid--3` in the first pass since it directly affects C1/H3 rewrites.

### M3 · `whiteglove__chip` border contrast fails SC 1.4.11 (Non-text Contrast)
Border `rgba(212, 168, 75, 0.28)` against deep-teal hero bg ≈ 1.5:1. Needs 3:1.

### M4 · Sidebar tag font-size 0.6rem (≈9.6px uppercase) is below recommended for legibility
WCAG passes on contrast; flag for design review at next polish pass.

### M5 · Promote inline `style="color: rgba(255,255,255,0.X)"` to utility classes (introduced in M1)

---

## LOW — polish & future-proofing

- **L1** Explicit `prefers-reduced-motion` reset for `.status--active` pulse animation
- **L2** Skip-link target should be `<main id="main-content" tabindex="-1">`, not `#hero`
- **L3** `id="status"` section conflicts with `.status` pill component (readability/grep concern only)
- **L4** `chaos__folder--danger` etc. use raw status hex — same as M1
- **L5** `data-counter` ticker increments not announced to screen readers
- **L6** Material Symbols icons next to label text not `aria-hidden="true"` (60+ occurrences)

---

## Manual A11y Audit Checklist (the 7 non-automatable WCAG 2.2 criteria)

| # | Criterion | DeltaSetup-specific test |
|---|---|---|
| 1 | **2.4.11/2.4.12 Focus Not Obscured** | Tab through sidebar links; verify `scroll-padding-top: 72px` is honored on focus, not just scroll. |
| 2 | **2.4.13 Focus Appearance** | Tab onto a link inside `.exec-intro__card` — outline color must contrast ≥3:1 with both card and section bg. **Currently failing — see H2.** |
| 3 | **2.5.7 Dragging Movements** | No drag interactions. ✓ Auto-satisfied. |
| 4 | **2.5.8 Target Size (Minimum)** | Status pills 28 px ✓. Sidebar links 37 px ✓. Audit-panel inline anchor links — measure on staging. |
| 5 | **3.2.6 Consistent Help** | No help mechanism. Add or document deliberate absence. |
| 6 | **3.3.7 Redundant Entry** | No forms. ✓ Auto-satisfied. |
| 7 | **3.3.8/3.3.9 Accessible Authentication** | No auth. ✓ Auto-satisfied. |

---

## Recommended fix order (smallest-blast-radius first)

| # | Fix | Files touched | Risk | Effort |
|---|---|---|---|---|
| **1** | C2 + C3 + C4 — status-pill taxonomy + Phase 4 semantics | `css/styles.css` (+~10 lines), `index.html` (5 small edits) | Low | 20 min |
| **2** | C1 — `.grid--5` proper minmax + sidebar-aware breakpoints | `css/styles.css:761-764` | Low | 10 min |
| **3** | H3 — base grid utilities (`.grid--2/3/4`) gain `minmax(0, 1fr)` and consistent breakpoints; remove duplicate `.grid--3` | `css/styles.css:244-256` and 770-786 | Medium | 1 hr |
| **4** | H1 — five contrast-ratio bumps | `css/styles.css`, `css/sidebar.css`, `css/microsoft-platform.css` | Very low | 15 min |
| **5** | H2 — `:focus-visible` outline color split (light vs dark surface) | `css/styles.css:69-72` | Low | 15 min |
| **6** | H5 + H6 — audit-blueprint + 4-col grids gain sidebar-aware intermediate breakpoint | 4 CSS files | Medium | 45 min |
| **7** | M1 — extend token system with `--success`, `--danger`, `--text-on-dark-muted`, etc. | `css/styles.css:21-50` + utility classes | Very low | 20 min |
| **8** | M5 + sweep of inline `#4CAF50` and `rgba(255,255,255,0.X)` styles → utility classes | `index.html` (~50 inline-style replacements) | Medium | 1.5 hr |
| **9** | L5 + L6 — `aria-hidden` on decorative icons + ticker SR fix | `index.html` (bulk attribute add) | Low | 30 min |
| **10** | H4 — canonical breakpoint scale + bulk media-query alignment | All CSS files | High | 2 hr |
| **11** | M2 — file-structure refactor (`tokens.css` + `components/`) | All CSS files (rename + split) | Highest — defer to post-launch | 4 hr |

**Suggested first PR:** Steps 1 + 2 + 4 (the "fix what Tyler can see in the screenshot AND ship the readability bumps" PR). ~45 min of edit time, smallest possible diff, every change directly user-visible.

---

## Coordination notes

- **Solutions Architect:** No API contracts in scope (static site). No coordination needed.
- **Security Auditor:** No privacy-touching surfaces (no forms, no auth, no analytics inferred from HTML). GPC middleware is N/A — static GitHub Pages site, no server-side request handling.
- **Owner approval needed before step 10:** canonical breakpoint scale (640 / 1023 / 1407).
- **Owner approval needed before step 1:** status-pill taxonomy — `done`, `success`, `active`, `pending`, `skipped`, `blocked`, `danger`.

---

*Audit performed by experience-architect agent. No code changes were made during the audit. This document is the canonical reference for the design-system fix sequence — keep updated as fixes land.*
