# Multi-Dimensional Analysis

## Project context

DeltaSetup contains a public executive site (`index.html`, `operations.html`, `msp.html`), a presentation (`presentation/`), and a DCE SharePoint mockup (`dce-mockup/`). Current root `css/tokens.css` has refreshed DCE palette variables:

- `--dce-emerald: #03534D`
- `--dce-gold: #D8A562`
- `--dce-almost-black: #231F20`
- `--dce-ivory: #FAFAF7`

However, `presentation/css/styles.css` and parts of `dce-mockup/css/tokens.css` still reference older palette values (`#006B5E`, `#D4A84B`). The review should therefore include both **user-facing WCAG checks** and **design-system/token drift checks**.

## WCAG 2.2 AA manual review lens

### Responsive navigation and drawers

Relevant criteria/patterns:

- WCAG 2.2 **2.1.1 Keyboard**, **2.1.2 No Keyboard Trap**, **2.4.3 Focus Order**, **2.4.7 Focus Visible**, **2.4.11 Focus Not Obscured (Minimum)**, **3.2.3 Consistent Navigation**, **3.2.4 Consistent Identification**, **4.1.2 Name, Role, Value**.
- WAI APG modal-dialog guidance if the drawer behaves modally.

Practical implications:

- Hamburger/drawer opener must be a `<button>` or equivalent with accessible name and correct `aria-expanded`/`aria-controls` if applicable.
- If the drawer covers the page, treat it like a modal: move focus inside on open, keep Tab/Shift+Tab inside, Escape closes, and return focus to opener.
- Do not set `aria-modal=true` unless outside content is actually inert and visually obscured.
- Sticky headers, top bars, and drawers must not fully hide the focused element at any responsive breakpoint.
- Confirm the serialized/focus order remains logical when nav changes from desktop links to mobile drawer.

### Focus visibility and appearance

Relevant criteria:

- AA: **2.4.7 Focus Visible**, **2.4.11 Focus Not Obscured (Minimum)**.
- AAA but useful quality target: **2.4.13 Focus Appearance** requires a visible focus indicator area at least as large as a 2 CSS px perimeter and 3:1 contrast between focused/unfocused pixels.

Practical implications:

- Existing root CSS uses `outline: 3px solid var(--gold); outline-offset: 3px;`. Gold on almost black is strong (7.36:1), but gold on white/ivory is only ~2.2:1. If the focus ring appears against light backgrounds, use a darker focus token (for example almost black/emerald outline, or two-layer outline) rather than raw gold alone.
- Test focus through hero CTAs, skip link, sidebars, nav/drawer, accordions/cards if interactive, and presentation controls.

### Target size

Relevant criteria:

- WCAG 2.2 AA **2.5.8 Target Size (Minimum)**: pointer targets at least 24×24 CSS px, with exceptions for spacing, equivalent controls, inline targets, user-agent controls, and essential presentation.
- WCAG AAA **2.5.5 Target Size (Enhanced)**: 44×44 CSS px target size, useful as a mobile quality target.

Practical implications:

- Icon-only menu/close buttons, small social/utility links, slide controls, and dense nav links are likely manual-check hotspots.
- Prefer 44×44 CSS px hit areas for primary mobile controls even when visual glyphs are smaller.
- Ensure adjacent small links do not create overlapping 24 CSS px target circles.

### Text and non-text contrast

Relevant criteria:

- **1.4.3 Contrast (Minimum)**: normal text 4.5:1; large text 3:1; logotypes exempt.
- **1.4.11 Non-text Contrast**: UI component/state indicators and essential graphics need 3:1 against adjacent colors.
- **1.4.1 Use of Color**: do not use color alone to convey state.

DCE palette implications:

- Emerald/white and emerald/ivory are excellent for text.
- Almost black/white and almost black/ivory are excellent for text.
- Gold/almost black is excellent for text and focus on dark.
- Gold/emerald is **4.04:1**: acceptable for large text, not normal text. Avoid small gold nav labels on emerald unless using a darker gold or larger/bolder typography that qualifies as large-scale text.
- Gold/white and gold/ivory fail both normal text and non-text contrast. Use gold decoratively or alongside a compliant label/border treatment.
- Emerald/almost black fails. Avoid emerald text/icons on almost-black surfaces.

### Responsive conformance

WCAG conformance applies to full pages, and WCAG states that full-page scope includes each automatically presented variation for different screen sizes. Therefore, the review should sample at minimum:

- Mobile width around 320–390 px.
- Tablet around 768–1024 px.
- Desktop around 1280–1440 px.
- 200% browser zoom and 400%/320 CSS px reflow where relevant.

## Design-system governance lens

Primary guidance:

- Design Tokens CG: tokens are name/value pairs with type, description, deprecation, references, groups; explicit type is important; groups should not be used to infer token purpose.
- USWDS: tokens constrain unlimited CSS choices into curated palettes and improve designer/developer communication; do not write raw token values directly in Sass rules.
- GOV.UK: use palette/functional color APIs; do not copy raw hex values; context-specific functional colors keep interactions predictable and easier to update.

Practical implications for DCE:

- Maintain one canonical DCE palette source and alias old variables to new tokens only where needed for compatibility.
- Introduce/confirm semantic tokens for roles, not colors: `--color-text-default`, `--color-text-inverse`, `--color-surface-page`, `--color-surface-hero`, `--color-accent-decorative`, `--color-focus-ring`, `--color-border-accent`, `--nav-link-color`, etc.
- Document forbidden combinations, especially gold on white/ivory and emerald on almost black.
- Add a review/lint step for raw hex leakage outside token definition files and SVG/image assets.
- Mark deprecated legacy tokens and provide replacements in comments or token documentation.

## Automated accessibility coverage limits

WAI guidance is explicit: evaluation tools help quickly identify potential issues, but cannot check all accessibility aspects automatically, require human judgment, and cannot determine accessibility on their own. Deque’s testing taxonomy similarly separates automated, semi-automated, and manual testing.

Practical implications:

- Keep the repo’s automated checks (`accessibility_static_audit.py`, `browser_smoke_audit.py`, `accessibility_axe_audit.py`) as quality gates.
- Add manual acceptance notes for nav drawer behavior, focus return, focus not obscured, visual reading order, actual target hit areas, text-on-image/overlay contrast, and keyboard operation.
- Treat automated pass as “no known machine-detectable blockers,” not as WCAG conformance.

## Multi-dimensional considerations

| Lens | Implication |
|---|---|
| Security | Avoid keyboard traps and inaccessible auth-like flows in internal M365 surfaces; do not compromise modal focus/inert behavior. Accessibility-related authentication is less central for static presentation, but internal links and embeds should remain keyboard accessible. |
| Cost | Manual WCAG review is cheaper when constrained by tokens. Fixing token roles prevents repeated per-page contrast patches. |
| Implementation complexity | Medium. Most improvements are CSS/token/docs and JS drawer focus management; no new framework required. |
| Stability | W3C WCAG 2.2 is stable Recommendation. Design Tokens spec is draft, so use vocabulary but avoid overfitting to draft-only syntax. |
| Optimization | Semantic tokens reduce CSS churn. Automated gates catch regressions; manual checklist catches interaction quality. |
| Compatibility | HTML/CSS/vanilla JS can meet guidance. Modal/drawer behavior must work across Chrome/Edge/Safari/Firefox and assistive tech patterns. |
| Maintenance | Token governance and deprecation notes are the main maintenance win. Keep presentation and mockup palettes synchronized with root tokens. |