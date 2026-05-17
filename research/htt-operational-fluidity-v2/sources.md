# Sources and Credibility Assessment

## Tier 1 — Primary / standards / official documentation

### Reveal.js Auto-Animate documentation
- **URL:** https://revealjs.com/auto-animate/
- **Authority:** Official Reveal.js documentation.
- **Currency:** Documentation page for Reveal.js 4.0+ auto-animate; accessed 2026-05-17.
- **Key findings:** Adjacent `<section data-auto-animate>` slides animate matching elements. Reveal.js matches text by content/node type and media by `src`; `data-id` can force matching. Settings include `data-auto-animate-easing`, `data-auto-animate-duration`, `data-auto-animate-unmatched`, `data-auto-animate-id`, and `data-auto-animate-restart`.
- **Credibility:** Tier 1. Primary source for implementation.
- **Bias:** Vendor/project documentation; appropriate for API behavior.

### W3C WCAG 2.2 Recommendation
- **URL:** https://www.w3.org/TR/WCAG22/
- **Authority:** W3C Recommendation, Accessibility Guidelines Working Group.
- **Currency:** W3C Recommendation republished 2024-12-12; accessed 2026-05-17.
- **Key findings:** WCAG 2.2 includes AA requirements relevant to decks: 1.4.3 Contrast Minimum, 1.4.11 Non-text Contrast, 1.4.12 Text Spacing, 2.1.1 Keyboard, 2.2.2 Pause/Stop/Hide, 2.3.1 Three Flashes, 2.4.7 Focus Visible, 2.4.11 Focus Not Obscured, 2.5.7 Dragging Movements, 2.5.8 Target Size Minimum.
- **Credibility:** Tier 1. Normative accessibility standard.
- **Bias:** None material.

### W3C WAI — Making Events Accessible checklist
- **URL:** https://www.w3.org/WAI/teach-advocate/accessible-presentations/
- **Authority:** W3C Web Accessibility Initiative.
- **Currency:** Updated 2022-08-31; accessed 2026-05-17.
- **Key findings:** Presentations should limit text per slide, make text and important visuals large enough from the back of the room, use easy-to-read fonts, maintain sufficient contrast, consider whether motion improves understanding, avoid distracting/seizure-inducing motion, describe relevant visual information, and provide accessible materials.
- **Credibility:** Tier 1. Official accessibility education guidance.
- **Bias:** Accessibility advocacy; appropriate for inclusive event/deck design.

### MDN — `backdrop-filter`
- **URL:** https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter
- **Authority:** MDN Web Docs.
- **Currency:** Page last modified 2026-04-20; notes Baseline 2024 availability; accessed 2026-05-17.
- **Key findings:** `backdrop-filter` applies effects such as blur/color shifting to pixels behind an element; the element/background must be transparent or partially transparent. Backdrop roots can affect how blur is applied. Baseline support is newly available across latest browser versions since September 2024.
- **Credibility:** Tier 1/2. Authoritative web platform reference with compatibility data.
- **Bias:** None material.

### MDN — `font-kerning`
- **URL:** https://developer.mozilla.org/en-US/docs/Web/CSS/font-kerning
- **Authority:** MDN Web Docs.
- **Currency:** Page last modified 2026-04-20; accessed 2026-05-17.
- **Key findings:** `font-kerning` controls use of kerning information in a font; kerning makes character spacing more uniform and pleasant to read by reducing whitespace in certain character combinations. Widely available since January 2020.
- **Credibility:** Tier 1/2. Authoritative CSS reference.
- **Bias:** None material.

### MDN — CSS Grid layout
- **URL:** https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout
- **Authority:** MDN Web Docs.
- **Currency:** Page last modified 2026-01-20; accessed 2026-05-17.
- **Key findings:** CSS Grid excels at dividing a page into major regions and defining size, position, and layering relationships; it supports columns, rows, gaps, alignment, and overlapping/layered placements.
- **Credibility:** Tier 1/2. Authoritative CSS reference.
- **Bias:** None material.

## Tier 2 — Established UX/design publication

### Nielsen Norman Group — Aesthetic-Usability Effect
- **URL:** https://www.nngroup.com/articles/aesthetic-usability-effect/
- **Authority:** Established UX research organization; article by Kate Moran.
- **Currency:** 2024-02-03; accessed 2026-05-17.
- **Key findings:** Attractive interfaces are perceived as more usable and professional, and users tolerate minor usability issues more when visual design creates a positive emotional response. The effect has limits: aesthetics cannot compensate for major usability/content problems.
- **Credibility:** Tier 2. Research-backed UX guidance.
- **Bias:** Commercial UX consulting/training, but evidence-based and widely recognized.

### Material Design 3 — Motion physics system
- **URL:** https://m3.material.io/styles/motion/overview
- **Authority:** Google Material Design official guidance.
- **Currency:** May 2025 page content; accessed 2026-05-17.
- **Key findings:** Current motion guidance differentiates expressive vs standard schemes; spatial movement can use expressive motion, but effects like opacity/color should avoid overshoot. Most motion should use consistent schemes/tokens; faster motion suits small elements, slower motion suits full-screen transitions.
- **Credibility:** Tier 2. Vendor design-system guidance; useful as pattern reference, not normative web requirement.
- **Bias:** Google ecosystem orientation.

## Cross-source validation

- Reveal.js confirms how to implement auto-animate; Material validates using motion as a consistent tokenized system; WCAG/WAI constrain the motion so it remains accessible.
- MDN validates CSS feasibility for glassmorphism (`backdrop-filter`) and typography tightening (`font-kerning`/letter spacing); WCAG validates contrast and fallback requirements.
- NN/g validates the business value of premium aesthetics, while warning not to let surface polish hide comprehension or usability defects.