# Sources and Credibility Assessment

## Tier 1 — Primary / official

1. **W3C Web Content Accessibility Guidelines (WCAG) 2.2, Recommendation 12 Dec 2024**  
   URL: https://www.w3.org/TR/WCAG22/  
   Credibility: Tier 1. Official standard. Current and normative for WCAG 2.2.  
   Used for: contrast minimums, non-text contrast, focus visible/not obscured, target size, reflow, headings/labels, name/role/value, consistent help.

2. **GitHub Docs — What is GitHub Pages?**  
   URL: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages  
   Credibility: Tier 1. Official platform documentation.  
   Used for: GitHub Pages as static hosting for HTML/CSS/JS directly from repository, optionally through build process; privacy note that visitor IPs are logged for security.

3. **WHATWG HTML Living Standard / MDN HTML and CSS docs**  
   Source type: official/living web platform references and widely maintained developer documentation.  
   Credibility: Tier 1/Tier 2.  
   Used for: native buttons/links, semantic sections/headings, reduced reliance on custom widgets, progressive enhancement.

## Tier 2 — Established UX / government design guidance

4. **Nielsen Norman Group — Information scent, scanning behavior, link/heading clarity, B2B content UX**  
   URL/source type: nngroup.com UX research articles and reports.  
   Credibility: Tier 2. Established UX research organization; practitioner summaries can be generalized but should be contextualized.  
   Used for: scannable IA, clear headings, information scent, audience task routing.

5. **GOV.UK Service Manual / Design System**  
   URL/source type: service-manual.service.gov.uk and design-system.service.gov.uk.  
   Credibility: Tier 2. Government digital-service standards; pragmatic accessibility/content guidance.  
   Used for: plain-language content, action-first task pages, accessible buttons/links, service-oriented IA.

6. **U.S. Web Design System (USWDS) / 18F content guidance**  
   URL/source type: designsystem.digital.gov, 18f.gsa.gov.  
   Credibility: Tier 2. Government-backed design system and content guidance.  
   Used for: design tokens, accessible components, contrast/focus/semantic patterns.

## Tier 2/3 — Conversion and B2B landing-page practitioner evidence

7. **CXL / Unbounce / HubSpot / Nielsen Norman B2B UX source types**  
   Credibility: Tier 2–3 depending on article. Commercially motivated but widely used; treat numeric benchmark claims cautiously.  
   Used for: landing-page best-practice consensus — audience-message match, clear CTA hierarchy, social proof/evidence placement, reduce friction.

8. **Baymard Institute UX research**  
   Credibility: Tier 2. Research-backed UX guidance; many findings are commerce-oriented but relevant to scannability, form/CTA clarity, and mobile behavior.  
   Used for: mobile/touch target and content clarity patterns.

## Internal project evidence

9. **DeltaSetup README and deployment/audit docs**  
   Source files: `README.md`, `DEPLOYMENT-STATUS.md`, `docs/delta-crown-*-inventory-summary.md`, ADRs.  
   Credibility: Tier 1 for project state when kept current; primary implementation evidence.  
   Used for: site narrative, real outcomes, known blockers.

10. **DeltaSetup design/WCAG audit (2026-05-06)**  
   Source: `research/design-system-audit-2026-05-06/AUDIT-REPORT.md`.  
   Credibility: Internal technical audit; high relevance, should be revalidated after implementation.  
   Used for: current breakpoint, contrast, focus, target-size, status semantics risks.

## Bias and validation notes

- WCAG and GitHub docs are primary sources and should drive hard requirements.
- Conversion blogs often publish persuasive “best practices” without transparent methodology; use them only where they align with established UX principles and project evidence.
- Avoid copying generic SaaS landing-page patterns that optimize demo requests over stakeholder comprehension. DeltaSetup’s conversion goal is likely approval/handoff/readiness, not anonymous lead capture.