# Multi-dimensional analysis

## Security

- Do not publish tenant IDs, internal group names, privileged role assignments, Conditional Access policy details, private SharePoint URLs, or guest-user lists in public GitHub README/Pages.
- Show architecture at a control-pattern level: “External collaborators access approved resources through Microsoft Entra External ID / B2B controls” rather than exposing operational identifiers.
- GitHub Pages is static and public if the repo/site is public; GitHub notes visitor IP addresses are logged for security. Treat Pages content as public collateral unless access is explicitly controlled by plan/configuration.
- For diagrams, abstract sensitive data flows and include a “public-safe summary” review step before publishing.

## Cost

- Text-first Markdown is essentially free and maintainable.
- Automated accessibility testing can be low-cost with axe-core, Pa11y, and Lighthouse in local/CI workflows.
- Higher costs arise from manual accessibility review, screen reader testing, visual design refinement, and legal/brand review for Microsoft assets.
- Avoid custom image-heavy diagrams that require frequent designer updates; use simple Markdown tables/lists and generated diagrams when possible.

## Implementation complexity

Low-complexity baseline:

- README Markdown section with headings, tables, bullets, and links.
- Optional Mermaid diagram plus adjacent text equivalent.
- GitHub Pages section generated from or manually aligned with README content.

Moderate complexity:

- Responsive HTML cards and CSS for GitHub Pages.
- Local SVG architecture icons with license/source tracking.
- CI checks with Pa11y/Lighthouse against the built Pages output.

High complexity:

- Fully accessible custom SVG diagrams with keyboard focus, text alternatives, visible labels, and robust responsive behavior.

## Stability and maintenance

- GitHub Markdown features are stable, but Mermaid rendering support/version is GitHub-controlled. Keep diagrams simple and test rendered output.
- Microsoft branding and architecture icon sets update; include source dates and review quarterly.
- Tool versions change and can alter issue counts. axe-core release notes show fixes can increase/decrease findings, especially target-size and false-positive behavior.
- Maintain a single source of truth for architecture statements to avoid README/Pages drift.

## Optimization

- Prefer local lightweight SVG or CSS shapes over large raster diagrams.
- Avoid hotlinked assets: they are slower, brittle, privacy-leaky, and may violate terms or break if Microsoft changes URLs.
- Keep Pages CSS minimal and ensure no JavaScript is required to read architecture content.
- Use progressive enhancement: content is readable in Markdown source, GitHub render, and Pages HTML.

## Compatibility

- GitHub README supports a safe subset of HTML and GitHub Flavored Markdown; avoid relying on complex custom HTML in README.
- GitHub Pages allows normal static HTML/CSS/JS, enabling landmarks and richer layouts.
- Mermaid diagrams render on GitHub, but may not be accessible enough alone; include text alternatives.
- SVG icons should include accessible names only if informative; otherwise keep them decorative in Pages and avoid them in README unless necessary.

## Accessibility

### WCAG 2.2 AA-friendly patterns

- **Perceivable:** text alternatives for diagrams; no color-only encoding; adequate contrast; readable line length.
- **Operable:** keyboard-visible focus on Pages; skip links if a full page has navigation; no hover-only content.
- **Understandable:** plain-language architecture explanations, acronym expansion, predictable section order.
- **Robust:** semantic HTML landmarks/headings; avoid ARIA unless needed; validate output with automated tools and assistive technology smoke tests.

### Markdown-specific practices

- One top-level heading per document.
- No skipped heading levels.
- Tables only for genuinely tabular data; simple column headers.
- Link text describes destination/purpose.
- Images include meaningful alt text; complex diagrams include adjacent long descriptions.
- Alerts used sparingly for crucial risk/decision notes only.

### HTML/GitHub Pages practices

- Use `<main id="main">` and a skip link.
- Use `<section aria-labelledby="...">` for major architecture sections.
- Use lists for flows and cards for components; avoid div-only structures.
- Maintain visible focus states with at least 2 CSS pixels and sufficient contrast.
- Respect reduced motion; do not animate architecture flow as the only explanation.

## Trademark / visual treatment

Microsoft-aligned does not mean Microsoft-branded. A safe visual direction for this project:

- Delta Crown/project brand remains dominant.
- Microsoft names are used truthfully in text to identify services.
- Architecture icons, if used, are local copies from official Microsoft downloads and only inside architecture/training/documentation diagrams.
- Include product names near icons as Microsoft recommends.
- No Microsoft logos/product icons in hero blocks, nav, badges, favicons, or decorative marketing graphics.
- Include a trademark footnote in public-facing Pages/README when Microsoft marks are prominent.

## Stakeholder communication

Best architecture summaries answer stakeholder questions before component details:

- **What changes for the business?** Faster onboarding, clearer ownership, safer external collaboration.
- **Who can access what?** Map personas to resources and controls.
- **Where does work happen?** SharePoint hub/spoke sites, Teams channels, document libraries.
- **How is risk controlled?** Entra ID, Conditional Access, groups, reviews, sensitivity/DLP where relevant.
- **Who owns it?** Operations/security/content owners and review cadence.
- **What decision is needed?** Use an explicit “Decision needed” callout rather than burying asks in diagrams.

## Automated vs manual accessibility testing gaps

| Area | Automated coverage | Manual gap |
|---|---|---|
| Missing image alt text | Good | Whether alt text accurately explains architecture. |
| Color contrast of text | Good for detectable text | Contrast inside images/SVGs may be missed; color-only meaning needs human review. |
| Heading order | Partial/good | Whether the outline is meaningful to stakeholders. |
| Link names | Partial | Whether link purpose is clear in project context. |
| Keyboard access | Partial in Pages | Need actual tab-through review and focus visibility check. |
| Diagram accessibility | Weak/partial | Reading order, long description quality, cognitive load, and nonvisual comprehension require humans. |
| Trademark compliance | None | Requires brand/legal judgment. |
| Stakeholder comprehension | None | Requires review with target readers. |

## Recommended quality gates

1. Markdown review: `markdownlint` if available, plus manual heading/link/table review.
2. Pages smoke test: axe-core/Pa11y/Lighthouse against local static site.
3. Manual keyboard test: tab order, skip link, focus visibility.
4. Screen reader smoke test: VoiceOver/NVDA read headings, diagram alt/long description, and component table.
5. Brand review: ensure Microsoft assets are local, permitted, sourced, and not used as branding.
6. Security review: remove tenant-specific secrets/identifiers before publishing.
