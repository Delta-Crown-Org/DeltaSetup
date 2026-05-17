# Sources and Credibility Assessment

## Tier 1 — Primary / highest authority

1. **W3C — Web Content Accessibility Guidelines (WCAG) 2.2, W3C Recommendation 12 Dec 2024**  
   URL: https://www.w3.org/TR/WCAG22/  
   Credibility: **Tier 1.** Official normative W3C Recommendation. Current published WCAG 2.2 version observed as 12 Dec 2024.  
   Relevant guidance: WCAG 2.2 includes AA success criteria for text contrast (1.4.3), reflow (1.4.10), non-text contrast (1.4.11), text spacing (1.4.12), content on hover/focus (1.4.13), keyboard/no trap/focus order (2.1.1, 2.1.2, 2.4.3), focus visible/not obscured (2.4.7, 2.4.11), consistent navigation/identification (3.2.3, 3.2.4), name/role/value (4.1.2), and target size minimum (2.5.8). It also states responsive variations are included in full-page conformance.

2. **W3C WAI — Selecting Web Accessibility Evaluation Tools**  
   URL: https://www.w3.org/WAI/test-evaluate/tools/selecting/  
   Credibility: **Tier 1.** Official W3C/WAI educational guidance.  
   Relevant guidance: Tools can quickly identify potential accessibility issues and support automated/manual review, but “tools cannot check all accessibility aspects automatically,” “human judgement is required,” tools can produce false/misleading results, and tools “can not determine accessibility.”

3. **W3C WAI — WCAG-EM Overview: Website Accessibility Conformance Evaluation Methodology**  
   URL: https://www.w3.org/WAI/test-evaluate/conformance/wcag-em/  
   Credibility: **Tier 1.** Official W3C/WAI conformance-evaluation methodology overview.  
   Relevant guidance: Effective conformance evaluation requires expertise in accessibility standards, accessible web design/development, assistive technologies, and how people with disabilities use the Web. Process: define scope, explore assets, select representative sample, evaluate, report. Accessibility should be integrated throughout planning, design, and development.

4. **W3C WAI-ARIA Authoring Practices Guide — Dialog (Modal) Pattern**  
   URL: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/  
   Credibility: **Tier 1.** Official WAI ARIA Authoring Practices guidance for accessible interaction patterns.  
   Relevant guidance: Modal dialogs make outside content inert; Tab/Shift+Tab remain within dialog; Escape closes; focus moves inside on open and returns to invoker on close; `aria-modal=true` should be used only when code prevents outside interaction and styling obscures outside content. Useful for mobile nav drawers that behave as modal overlays.

5. **Design Tokens Community Group — Design Tokens Format Module 2025.10 draft**  
   URL: https://www.designtokens.org/TR/2025.10/format/  
   Credibility: **Tier 1/Tier 2 hybrid.** Primary standards-community draft, not a W3C Standard; status explicitly says preview draft and not authoritative for implementation. Still useful for current token-governance vocabulary.  
   Relevant guidance: Tokens are named values with optional/required metadata such as `$type`, `$description`, `$deprecated`, references/aliases, groups, and validation. Tools should not infer type from group names; token type should be explicit or inherited.

## Tier 2 — Established design-system guidance / recognized vendor expertise

6. **U.S. Web Design System (USWDS) — Design tokens**  
   URL: https://designsystem.digital.gov/design-tokens/  
   Credibility: **Tier 2.** Official U.S. government design-system documentation, stable operational guidance.  
   Relevant guidance: Design tokens are curated discrete palettes for color, spacing, typography, etc. They improve efficiency and designer/developer communication. USWDS notes not to include raw token values directly in Sass rules; instead use tokens through settings, functions, mixins, and utilities.

7. **GOV.UK Design System — Colour**  
   URL: https://design-system.service.gov.uk/styles/colour/  
   Credibility: **Tier 2.** Official UK government design-system documentation with WCAG-linked practices.  
   Relevant guidance: Always use the colour palette; ensure text and interactive elements meet WCAG 2.2 contrast minimum; assign functional colors using semantic functions; do not copy specific hex values such as brand color directly; use variables/functions so services inherit palette updates.

8. **Deque — Axe Platform / accessibility testing FAQ**  
   URL: https://www.deque.com/axe/  
   Credibility: **Tier 2.** Recognized accessibility tooling vendor; commercial bias present, but useful for vendor-stated tool boundaries. Cross-referenced with WAI.  
   Relevant guidance: Accessibility testing includes automated, semi-automated, and manual testing; manual testing uses assistive technology and expertise to identify complex barriers automation cannot detect. Axe-core is the rules engine underlying automated tests.

## Project-local sources

9. **DeltaSetup repo — `css/tokens.css`, `dce-mockup/css/tokens.css`, `presentation/css/styles.css`, `README.md`**  
   Credibility: **Project primary.** Current source files in the repo.  
   Relevant context: Current public/root tokens already define refreshed DCE colors `--dce-emerald: #03534D`, `--dce-gold: #D8A562`, and `--dce-almost-black: #231F20`; DCE mockup and presentation still contain older teal/gold values in some places, making brand-token governance a concrete review item.

## Notes on validation and bias

- W3C/WAI sources are the primary basis for WCAG requirements and automated-testing cautions.
- Design Tokens Community Group is a preview draft, so this report uses it for vocabulary/patterns, not as a hard compliance dependency.
- Deque is commercial and product-promotional; conclusions about automation limits are only used where corroborated by WAI/WCAG-EM.