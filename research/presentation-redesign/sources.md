# Sources — Credibility Assessment

## Source Hierarchy Applied

| Tier | Definition | Example |
|------|-----------|---------|
| **Tier 1** | Official specs, primary research, academic | W3C WCAG, WAI-ARIA APG |
| **Tier 2** | Established experts, vendor docs | Duarte, NN/g, MDN, McKinsey publications |
| **Tier 3** | Community-vetted, practitioner content | SpeakingSherpa, Untools, Awwwards |
| **Tier 4** | Personal blogs, unverified | — (none used) |

---

## Topic 1: Executive Presentation Narrative Arc

### Source 1.1 — Duarte: "7 Tips for Crafting a Storytelling Presentation"
- **URL:** https://www.duarte.com/blog/tips-for-crafting-a-storytelling-presentation/
- **Tier:** 2 (Established expert — Nancy Duarte is the foremost authority on presentation design)
- **Published:** March 15, 2024
- **Authority:** Duarte Inc. has designed presentations for Apple, Google, Al Gore. Nancy Duarte's "Resonate" is the foundational text. Their TED talk analyzing Steve Jobs and MLK speeches has 3M+ views.
- **Bias:** Commercial interest in selling workshops (Resonate®, VisualStory®, Slide:ology®), but core frameworks are well-established and independently validated.
- **Key content extracted:** Hero's Journey adaptation, Presentation Sparkline™ (what is / what could be contrast), S.T.A.R. Moments, audience-as-hero principle, "new bliss" closing technique.
- **Validation:** Cross-referenced with Duarte's TED talk analysis, which independently confirmed Jobs and MLK follow the Sparkline pattern.

### Source 1.2 — SpeakingSherpa: "McKinsey SCR Framework"
- **URL:** https://speakingsherpa.com/how-to-tell-a-business-story-using-the-mckinsey-situation-complication-resolution-scr-framework/
- **Tier:** 3 (Practitioner, but cites primary McKinsey sources)
- **Published:** November 18, 2017 (framework itself is timeless — originated 1960s)
- **Authority:** References actual McKinsey presentations (USPS, global steel, housing). Links to original McKinsey PDFs.
- **Bias:** Minimal — educational content with no product sales.
- **Key content extracted:** SCR component definitions, story element placement rules based on audience knowledge level, S-C-R vs R-S-C ordering, MECE principle, concrete examples with McKinsey case studies.
- **Validation:** Cross-referenced with Barbara Minto's Pyramid Principle (the foundational McKinsey methodology). SCR is the narrative wrapper for the Pyramid's top-down communication structure.

### Source 1.3 — Untools: "Minto Pyramid"
- **URL:** https://untools.co/minto-pyramid/
- **Tier:** 3 (Curated framework reference)
- **Published:** Undated (framework itself from Barbara Minto, 1967)
- **Authority:** Cites original source "The Minto Pyramid Principle" by Barbara Minto. Well-established framework used at McKinsey, BCG, Bain for 50+ years.
- **Bias:** None — nonprofit educational resource.
- **Key content extracted:** BLUF principle, three-tier structure (conclusion → key arguments → supporting detail), example application.
- **Validation:** Consistent with SCR framework — Pyramid Principle is the underlying logic; SCR is its narrative expression.

---

## Topic 2: Luxury Brand Digital Presentation Design

### Source 2.1 — Nielsen Norman Group: "Progressive Disclosure"
- **URL:** https://www.nngroup.com/articles/progressive-disclosure/
- **Tier:** 2 (Gold-standard UX research firm)
- **Published:** December 3, 2006 (updated; principle is foundational and current)
- **Authority:** Jakob Nielsen — co-founder of NN/g, pioneer of usability heuristics. The original article that defined progressive disclosure as a design pattern.
- **Bias:** None — independent research organization.
- **Key content extracted:** Core/secondary feature split, staged vs progressive disclosure, usability criteria (learnability, efficiency, error reduction), practical application guidelines.
- **Validation:** Principle is universally applied across Apple, Google, and luxury brand interfaces.

### Source 2.2 — MDN Web Docs: "CSS Scroll-Driven Animations"
- **URL:** https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations
- **Tier:** 1 (Official web platform documentation)
- **Published:** Last modified March 29, 2026
- **Authority:** MDN is maintained by Mozilla, Google, Microsoft, and Apple. The canonical reference for web APIs.
- **Bias:** None — vendor-neutral documentation.
- **Key content extracted:** `scroll-timeline`, `view-timeline`, `animation-range`, `scroll()` and `view()` functions. Specification status.
- **Validation:** Backed by W3C Scroll-driven Animations specification.

### Source 2.3 — Awwwards: Fashion Website Inspiration
- **URL:** https://www.awwwards.com/websites/fashion/
- **Tier:** 3 (Curated design gallery)
- **Published:** Continuously updated
- **Authority:** Industry-standard award site for web design excellence. Jury includes designers from Google, Apple, Spotify.
- **Bias:** Favors visually impressive sites; may not represent accessible or performant designs.
- **Key content extracted:** Pattern analysis of award-winning luxury fashion sites (Chanel, Gucci, Hermès, Prada digital experiences).

---

## Topic 3: WCAG 2.2 Accessibility for Slide Presentations

### Source 3.1 — W3C WAI: "How to Meet WCAG 2.2 (Quick Reference)"
- **URL:** https://www.w3.org/WAI/WCAG22/quickref/
- **Tier:** 1 (THE authoritative source — W3C is the standards body)
- **Published:** Updated September 22, 2025
- **Authority:** W3C Web Accessibility Initiative. The definitive, legally-referenced accessibility standard worldwide (ADA, Section 508, EN 301 549, EU Web Accessibility Directive).
- **Bias:** None — open standards body.
- **Key content extracted:** All WCAG 2.2 success criteria with techniques, including new 2.2 additions: 2.4.11 Focus Not Obscured, 2.4.12 Focus Not Obscured (Enhanced), 2.4.13 Focus Appearance, 2.5.7 Dragging Movements, 2.5.8 Target Size (Minimum), 3.2.6 Consistent Help, 3.3.7 Redundant Entry, 3.3.8 Accessible Authentication.
- **Validation:** This IS the validation source.

### Source 3.2 — W3C WAI-ARIA APG: "Carousel Pattern"
- **URL:** https://www.w3.org/WAI/ARIA/apg/patterns/carousel/
- **Tier:** 1 (Official ARIA Authoring Practices Guide)
- **Published:** Current (maintained by W3C ARIA WG)
- **Authority:** The definitive guide for implementing accessible carousels/slideshows using ARIA.
- **Bias:** None.
- **Key content extracted:** Three carousel styles (basic, tabbed, grouped), required roles/states/properties, keyboard interaction model, auto-rotation accessibility requirements, `aria-roledescription="slide"`, `aria-live` polite/off toggling.
- **Validation:** This IS the validation source for ARIA carousel patterns.

### Source 3.3 — MDN Web Docs: "prefers-reduced-motion"
- **URL:** https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
- **Tier:** 1 (Official web platform documentation)
- **Published:** Last modified January 8, 2026
- **Authority:** MDN — canonical web API reference.
- **Bias:** None.
- **Key content extracted:** `no-preference` and `reduce` values, cross-platform user preference settings, baseline browser support (since January 2020), implementation examples.
- **Validation:** References Media Queries Level 5 W3C specification.

---

## Sources NOT Used (and why)

| Source | Reason Excluded |
|--------|----------------|
| McKinsey.com direct | HTTP/2 protocol error — site blocked automated access |
| Google Search | CAPTCHA blocked |
| DuckDuckGo | CAPTCHA blocked |
| Brave Search | CAPTCHA blocked |
| LinkedIn Pulse | Article not found (404) |
| Random "top 10 presentation tips" blogs | Tier 4 — no original research or methodology |
