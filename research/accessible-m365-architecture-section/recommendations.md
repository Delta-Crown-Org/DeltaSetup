# Project-specific recommendations

## Priority 1 — Build the README section as the accessible source of truth

Add a concise `## Microsoft 365 architecture at a glance` section using semantic Markdown:

- Purpose and business outcome.
- Core components table.
- Access model bullets.
- Data/collaboration flow as an ordered list.
- Links to relevant ADRs and runbooks.
- A diagram only after the text equivalent exists.

Use this pattern:

```markdown
## Microsoft 365 architecture at a glance

### Business outcome
- Centralize governed brand and operations resources.
- Keep identity, access, and collaboration controls understandable for nontechnical stakeholders.
- Provide a clear path from current state to target SharePoint/Teams operating model.

### Core services
| Layer | Service | Purpose | Primary owner |
|---|---|---|---|
| Identity | Microsoft Entra ID | Sign-in, groups, Conditional Access | IT/security |
| Content | SharePoint Online | Hub/spoke sites and libraries | Operations/content owners |
| Collaboration | Microsoft Teams | Team/channel workspaces | Department leads |

### Flow summary
1. Users authenticate through Microsoft Entra ID.
2. Group membership and access policies determine authorized resources.
3. SharePoint sites provide governed documents and brand resources.
4. Teams channels provide collaboration surfaces tied to operational workflows.
```

## Priority 2 — Use diagrams as supporting evidence, not primary content

- If using Mermaid, keep it simple and provide a “Flow summary” list adjacent to it.
- Do not encode risk or ownership only through color or icons.
- For any PNG/SVG diagram, include:
  - Short alt text: “High-level Microsoft 365 architecture for Delta Crown resource governance.”
  - Long description with nodes, relationships, and trust boundaries.
  - A plain text component table.

## Priority 3 — Use Microsoft visual assets conservatively

Recommended default: **no Microsoft product icons in the README hero/summary**. Use text labels and simple shapes.

If the team wants icons for a Pages diagram:

1. Download official Microsoft Entra/Microsoft 365/Azure architecture icon packages; do not hotlink.
2. Store under a tracked asset folder with `SOURCE.md` containing URL, download date, and terms summary.
3. Use icons only in diagrams/training/documentation.
4. Keep product names close to icons.
5. Do not crop, flip, rotate, distort, recolor beyond permitted use, or combine into a Delta Crown-branded mark.
6. Add trademark notice in README/Pages footer.

## Priority 4 — GitHub Pages implementation guidance

For a Pages section, use semantic HTML:

```html
<a class="skip-link" href="#main">Skip to main content</a>
<main id="main">
  <section aria-labelledby="architecture-heading">
    <h2 id="architecture-heading">Microsoft 365 architecture at a glance</h2>
    <p>Plain-language outcome summary...</p>

    <h3>Core services</h3>
    <ul class="architecture-cards">
      <li><strong>Microsoft Entra ID</strong>: authentication, groups, and policy enforcement.</li>
      <li><strong>SharePoint Online</strong>: governed hub/spoke document resources.</li>
      <li><strong>Microsoft Teams</strong>: collaboration spaces mapped to operations workflows.</li>
    </ul>
  </section>
</main>
```

CSS defaults:

- Use system fonts; avoid brand-font dependencies.
- Maintain 4.5:1 text contrast and 3:1 non-text UI contrast.
- Ensure visible focus styles.
- Keep cards responsive with single-column mobile layout.
- Avoid animation; if present, support `prefers-reduced-motion`.

## Priority 5 — Testing plan

Automated checks:

```bash
npm exec pa11y -- https://<site-url>/
npm exec lighthouse -- https://<site-url>/ --only-categories=accessibility
```

If writing Playwright/Puppeteer tests, use axe-core 4.11.4 directly or via a test integration. Pin versions in `package.json` if repeatable CI results matter.

Manual checks:

- Keyboard: tab through Pages section and verify focus is visible and logical.
- Screen reader: read heading outline and diagram alternative with VoiceOver or NVDA.
- Diagram: ask a reviewer to explain the architecture from text only; compare against intended meaning.
- Mobile: inspect README table/diagram on narrow viewport.
- Brand: verify Microsoft marks are textual, truthful, and not more prominent than the project brand.
- Security: verify no private URLs, tenant IDs, user names, or privileged controls are exposed.

## Priority 6 — Suggested public-safe wording

> This repository documents the target collaboration and identity architecture for Delta Crown resources in Microsoft 365. Microsoft Entra ID provides identity and access controls, SharePoint Online hosts governed resource sites and document libraries, and Microsoft Teams provides collaboration spaces aligned to business workflows. Access is managed through documented groups, ownership, and review processes.

Trademark footnote:

> Microsoft, Microsoft 365, Microsoft Entra, SharePoint, and Teams are trademarks of the Microsoft group of companies. This documentation is not endorsed by or affiliated with Microsoft.

## Do / don’t quick reference

| Do | Don’t |
|---|---|
| Use semantic headings and text-first summaries. | Put the architecture only in an image. |
| Use descriptive links to ADRs and runbooks. | Use “click here” or raw URLs as primary link text. |
| Store any permitted Microsoft icons locally with source notes. | Hotlink Microsoft logos/icons. |
| Use Microsoft product names truthfully in text. | Use Microsoft icons as page branding, favicons, badges, or hero decoration. |
| Pair diagrams with long descriptions and tables. | Rely on color, arrows, or icons alone. |
| Run axe/Pa11y/Lighthouse plus manual review. | Treat a passing automated score as WCAG 2.2 AA conformance. |
