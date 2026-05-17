# DCE Brand Refresh UX/WCAG Review Research

**Purpose:** concise authoritative guidance for reviewing the DeltaSetup / Delta Crown Extensions internal brand-refresh website and presentation using the refreshed palette `#D8A562` royal gold, `#03534D` emerald, and `#231F20` almost black.

## Key findings

1. **Use WCAG 2.2 AA as the review baseline, with manual keyboard/responsive checks.** W3C recommends WCAG 2.2 for current applicability. WCAG 2.2 adds AA criteria especially relevant to this review: **2.4.11 Focus Not Obscured (Minimum)**, **2.5.7 Dragging Movements**, and **2.5.8 Target Size (Minimum)**. Responsive variants are in scope for conformance; WCAG notes that each automatically presented screen-size variation must conform.
2. **Automated accessibility scans are necessary but not sufficient.** WAI says tools cannot check all accessibility aspects, require human judgment, can produce false or misleading results, and cannot determine accessibility by themselves. WCAG-EM also expects expertise in WCAG, accessible design/development, assistive technologies, and disability user experience.
3. **The DCE palette is strong if roles are constrained.** Emerald or almost black with ivory/white passes normal-text AA easily. Royal gold is accessible as text on almost black, but **fails as normal text on emerald** and **fails as text on white/ivory**. Treat gold as accent, border, focus treatment, large display text only on emerald, or text on dark surfaces—not body copy on light surfaces.
4. **Design-system governance should require semantic tokens, not ad hoc hex.** The Design Tokens Community Group defines tokens as name/value pairs with type, description, references, deprecated flags, and groups. USWDS and GOV.UK both stress curated token palettes and functions/variables over copying raw hex values. For DCE, update token docs and lint/review for hex leakage outside token roots.
5. **Responsive nav/drawers must be tested like dialogs/menus, not visual-only components.** If a mobile drawer behaves modally, WAI APG expects focus to move inside, Tab/Shift+Tab to remain inside, Escape to close, focus to return to opener, and content outside to be inert/obscured. If it is not truly modal, do not mark it `aria-modal`.

## DCE palette contrast implications

| Pair | Contrast | Practical implication |
|---|---:|---|
| `#03534D` emerald on white | 8.94:1 | Passes AA/AAA normal text. Good primary text/link/action on light surfaces. |
| `#03534D` emerald on ivory `#FAFAF7` | 8.55:1 | Passes AA/AAA normal text. Good headings/buttons on site background. |
| `#231F20` almost black on white | 16.30:1 | Passes AA/AAA. Good primary body text. |
| `#231F20` almost black on ivory | 15.59:1 | Passes AA/AAA. Good primary body text. |
| `#D8A562` gold on `#231F20` | 7.36:1 | Passes AA/AAA normal text. Good on dark hero/drawer surfaces. |
| `#D8A562` gold on `#03534D` | 4.04:1 | Fails AA normal text (4.5), passes large text (3.0). Use for large headings/ornaments only, or darken gold for normal nav labels. |
| `#D8A562` gold on white | 2.22:1 | Fails text and non-text contrast. Decorative only on white unless paired with border/label alternatives. |
| `#D8A562` gold on ivory | 2.12:1 | Fails text and non-text contrast. Decorative only on ivory. |
| `#03534D` emerald on `#231F20` | 1.82:1 | Fails. Do not use emerald text/icons on almost black. |

## Most important manual review checks

- **Mobile nav/drawer:** opener is a real button with accessible name; `aria-expanded` state updates; focus enters drawer; Escape closes; Tab order does not reach obscured page content if modal; focus returns to opener; drawer is not hidden behind sticky headers; scroll-lock does not trap users.
- **Focus:** visible for all links/buttons; not fully obscured by sticky nav/overlays; focus ring has at least 3:1 contrast against adjacent colors where custom focus appearance is used.
- **Targets:** all pointer targets are at least 24×24 CSS px, or undersized inline/exception targets have sufficient spacing; aim for 44×44 CSS px for primary/mobile controls even though AA minimum is 24×24.
- **Text contrast:** audit every semantic state and responsive surface, especially gold text on light/emerald backgrounds, muted text, overlays, transparent text-on-image, and focus/hover states.
- **Token governance:** no new raw hex in component CSS/HTML; palette colors must map to semantic roles such as `--color-text-default`, `--color-surface-hero`, `--color-focus-ring`, `--color-accent-decorative`, etc.

## Files in this research packet

- [`sources.md`](sources.md) — source list with credibility assessments.
- [`analysis.md`](analysis.md) — multi-dimensional analysis for UX/accessibility/design-system review.
- [`recommendations.md`](recommendations.md) — prioritized DCE review checklist and action items.
- [`raw-findings/`](raw-findings/) — extracted/source-specific notes.