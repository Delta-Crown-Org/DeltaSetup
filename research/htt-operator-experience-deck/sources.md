# Sources and Credibility Assessment

## Tier 1 — Primary / standards / official documentation

### Reveal.js official documentation — Layout and Presentation Size
- URLs: https://revealjs.com/layout/ and https://revealjs.com/presentation-size/
- Authority: Official Reveal.js documentation.
- Currency: Current online docs checked 2026-05-17.
- Relevant findings: Reveal.js preserves a configured “normal” presentation size and scales uniformly; default sizing examples use width/height/margin/minScale/maxScale; layout helpers include `r-stack`, `r-fit-text`, `r-stretch`, and `r-frame`.
- Bias: Vendor/project documentation; accurately documents framework behavior, not presentation strategy.
- Use in recommendations: Use predictable 16:9 sizing, `center: false` for consistent layout, and helpers sparingly.
- Reliability: **Tier 1** for Reveal.js implementation behavior.

### W3C WAI — Making Events Accessible Checklist
- URL: https://www.w3.org/WAI/teach-advocate/accessible-presentations/
- Authority: W3C Web Accessibility Initiative.
- Currency: Page states updated 31 August 2022; still aligned with WCAG principles and event accessibility practice.
- Relevant findings: Provide accessible material ahead of time; HTML is adaptable; start with overview and end with review; use consistent slide design to limit cognitive load; limit text; make text and visuals big enough; use readable fonts and sufficient contrast; describe relevant visual information; avoid unnecessary motion/flashing; speak clearly and use simple language.
- Bias: Accessibility advocacy; intentionally inclusive.
- Reliability: **Tier 1**.

### W3C WAI — WCAG 2.2 Quick Reference
- URL: https://www.w3.org/WAI/WCAG22/quickref/
- Authority: W3C/WAI official WCAG reference.
- Currency: Tool status updated 22 Sep 2025.
- Relevant findings: Text contrast minimum 4.5:1, large text 3:1; enhanced contrast 7:1; color cannot be the only information channel; non-text contrast 3:1; keyboard access; focus visible; focus not obscured; headings/labels; meaningful sequence; target size; reduced animation via `prefers-reduced-motion` is a technique for animation from interactions.
- Bias: Standards reference.
- Reliability: **Tier 1**.

### Microsoft Support — Make PowerPoint presentations accessible
- URL: https://support.microsoft.com/en-US/accessibility/powerpoint/make-your-powerpoint-presentations-accessible-to-people-with-disabilities
- Authority: Official Microsoft documentation.
- Currency: Current support page checked 2026-05-17; applies to current Microsoft 365 and recent Office versions.
- Relevant findings: Accessible decks need slide titles, intended reading order, alt text, meaningful links, sufficient contrast, font size 18pt or larger, sans serif fonts, whitespace, captions, avoidance of tables where possible, and screen-reader testing.
- Bias: Microsoft product guidance, but practices generalize to decks and HTML equivalents.
- Reliability: **Tier 1** for accessibility practices in slide-deck contexts.

## Tier 2 — Established expert/industry research

### Nielsen Norman Group — Journey Mapping 101
- URL: https://www.nngroup.com/articles/journey-mapping-101/
- Authority: Recognized UX research and consulting organization; author Sarah Gibbons.
- Currency: Published 2018-12-09; concepts are stable and widely adopted.
- Relevant findings: A journey map visualizes the process a person goes through to accomplish a goal. Core components: actor, scenario/expectations, journey phases, actions/mindsets/emotions, opportunities. Journey maps create aligned mental models and communicate concise, memorable shared vision.
- Bias: NN/g sells training/consulting, but the article is a free educational resource and consistent with service-design practice.
- Reliability: **Tier 2**.

### Assertion-Evidence approach — Michael Alley / Penn State Leonhard Center
- URL: https://www.assertion-evidence.com/
- Authority: Michael Alley and Penn State Leonhard Center; supported by NSF grant information on site.
- Currency: Site is older but the method is supported by research and remains relevant.
- Relevant findings: PowerPoint defaults of phrase headline + bullet list create noise; assertion-evidence uses succinct message headlines supported by visual evidence instead of bullet lists.
- Bias: Advocates a specific presentation method; most applicable to technical/scientific presentations but transferable to executive/operator decks.
- Reliability: **Tier 2** for presentation design methodology.

## Project-context sources

### Local project files
- `presentation/index.html` and `presentation/css/styles.css`: Existing DCE presentation/site patterns, current redirect, brand typography and visual style.
- `css/tokens.css`: Current DCE brand tokens: emerald `#03534D`, gold `#D8A562`, almost black `#231F20`, ivory `#FAFAF7`, motion and accessibility utilities.
- `docs/operators/README.md`: Operator-facing documentation principles: no assumed context, full paths, failure modes, named escalation.
- Prior research packages: `research/executive-presentation-ux/`, `research/presentation-narrative/`, `research/franchise-portal-ux/` used as contextual continuity, not as primary external evidence.

## Validation notes

Findings were cross-referenced across standards (W3C/WCAG), official product/framework docs (Reveal.js and Microsoft), and UX/presentation experts (NN/g and assertion-evidence). Where commercial/expert sources recommend narrative structure, accessibility recommendations were anchored back to W3C and Microsoft official guidance.
