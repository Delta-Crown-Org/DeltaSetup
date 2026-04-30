# Sources & Credibility

All sources accessed during research session (2025).

## Tier 1 — Primary / Normative

### W3C ARIA Authoring Practices Guide — Tabs Pattern
- **URL:** https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
- **Authority:** W3C Web Accessibility Initiative (canonical pattern library)
- **Currency:** Living document, actively maintained by APG Task Force
- **Used for:** Q2 — confirming `role="tab"` requires `aria-controls` → `tabpanel` (same-page panel switching)

### W3C WCAG 2.2 — Understanding SC 2.4.11 Focus Not Obscured (Minimum)
- **URL:** https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html
- **Authority:** W3C / Accessibility Guidelines Working Group (AGWG) — normative supporting document
- **Currency:** WCAG 2.2 became W3C Recommendation Oct 2023; Understanding docs receive ongoing errata
- **Used for:** Q3(b) — F110 failure mode, sufficient technique C43 (scroll-padding)

### W3C WCAG 2.2 — Understanding SC 2.3.3 Animation from Interactions
- **URL:** https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html
- **Authority:** W3C / AGWG
- **Used for:** Q3(a) — technique SCR40 (prefers-reduced-motion in JavaScript)

### W3C WCAG 2.2 — Understanding SC 2.5.8 Target Size (Minimum)
- **URL:** https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- **Authority:** W3C / AGWG
- **Used for:** Q3 quick-reference table — 24×24 CSS px requirement

### W3C ARIA APG — Landmark Regions
- **URL:** https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/
- **Authority:** W3C WAI
- **Used for:** Q3(c) — definitions of `complementary` (aside) vs `navigation` (nav) roles, "complementary should be top-level," nesting/labeling guidance

## Tier 2 — High-quality reference

### MDN Web Docs — `aria-current` attribute
- **URL:** https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-current
- **Authority:** Mozilla / Open Web Docs (industry-standard reference, sourced from ARIA spec)
- **Currency:** Page last modified Oct 29, 2025
- **Used for:** Q2 — explicit guidance that `aria-current` is for "current page within a set of pages" and must NOT substitute for `aria-selected` on tabs (and vice versa)

### Nielsen Norman Group — "Menu-Design Checklist: 17 UX Guidelines"
- **URL:** https://www.nngroup.com/articles/menu-design/
- **Author:** Page Laubheimer
- **Date:** June 7, 2024
- **Authority:** NN/g (most-cited applied UX research firm; Jakob Nielsen, Don Norman)
- **Used for:** Q1 — left rail = expected location for desktop local nav; show nav on large screens; clear/familiar wording; left-justify + front-load; current-location indication; avoid gimmicks

## Notes on coverage

- **GOV.UK Design System** styles index was inspected; the system does not publish a dedicated cross-page "view switcher" pattern. GOV.UK's broader content-design principle ("use plain language; use the words your users use") is referenced from their long-standing Service Manual guidance and is widely cited rather than from a single 2024–2026 page.
- No conflicting recent (2024–2026) sources were found contradicting the W3C / NN/g positions cited above. The "tabs vs nav links" boundary in particular has been stable in ARIA guidance since ARIA 1.1; ARIA 1.2 / 1.3 work has not relaxed it.
- DuckDuckGo and Google search were attempted for broader 2025–2026 sweep; both returned anti-bot pages in headless mode. Direct navigation to known authoritative URLs was used instead — appropriate for a targeted (not exploratory) research request.
