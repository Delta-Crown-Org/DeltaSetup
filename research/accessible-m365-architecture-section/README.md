# Accessible GitHub README / GitHub Pages Section for Microsoft Entra and Microsoft 365 Architecture

**Research date:** 2026-04-30  
**Agent:** web-puppy-675cf8  
**Project context:** DeltaSetup is a documentation-first Microsoft 365 / SharePoint / Teams / Entra architecture repository with GitHub Pages-style HTML, executive presentation assets, and existing WCAG 2.2 accessibility research.

## Executive summary

Use a **text-first architecture summary** in the README and GitHub Pages, supported by optional diagrams that never carry the only meaning. The safest pattern is:

1. Start with a plain-language architecture narrative: purpose, users, tenants/sites, access model, data flows, and operational ownership.
2. Use semantic Markdown headings, lists, and tables that render well on GitHub and degrade cleanly in source view.
3. Include one high-level diagram only if it has an adjacent text equivalent and/or an accessible long description.
4. Avoid hotlinking Microsoft assets. If Microsoft icons are needed, use only downloaded official architecture-icon packages under Microsoft’s permitted uses for architectural diagrams, training materials, or documentation; keep product names near icons and do not crop, distort, rotate, or use icons as your own branding.
5. Prefer a Microsoft-aligned but brand-safe visual treatment: neutral backgrounds, high contrast, simple cards, line connectors, and textual service labels such as “Microsoft Entra ID,” “SharePoint hub site,” and “Teams shared channel,” not copied logos as decorative badges.
6. Test with automated tools, but require manual review for heading structure, alt/long descriptions, keyboard behavior, reading order, contrast in diagrams, trademark context, and stakeholder comprehension.

## Current tool versions checked

`npm view` results on 2026-04-30:

| Tool | Current npm version | Best use |
|---|---:|---|
| axe-core | 4.11.4 | Rule engine for page-level automated accessibility checks; strong for HTML semantics, names, ARIA, contrast in detectable text. |
| Pa11y | 9.1.1 | CLI/page checks useful in CI for GitHub Pages output. |
| Lighthouse | 13.1.0 | Broad page quality audit; accessibility category is useful but not sufficient for WCAG conformance. |

## Recommended section structure

```markdown
## Microsoft 365 architecture at a glance

### What this architecture does
Brief stakeholder summary in 3-5 bullets.

### Core components
| Layer | Microsoft service | Role in this environment | Owner |
|---|---|---|---|
| Identity | Microsoft Entra ID | Authentication, groups, Conditional Access | IT/security |
| Collaboration | SharePoint Online | Hub/spoke resource sites and document libraries | Operations |
| Communications | Microsoft Teams | Team/channel collaboration mapped to sites | Department leads |

### Access model
- Internal staff authenticate with Microsoft Entra ID.
- Franchise/partner access uses approved guest or cross-tenant collaboration patterns.
- Access is reviewed through documented owner and security review cadence.

### Data and collaboration flow
1. Users sign in through Microsoft Entra ID.
2. Group membership and policies determine access.
3. SharePoint sites host governed documents.
4. Teams channels provide collaboration surfaces tied to business workflows.

### Diagram
See the accessible diagram and text alternative below.
```

## GitHub README and Pages accessibility defaults

- Use one `#` page title and nested `##` / `###` headings; avoid skipped heading levels.
- Keep paragraphs short and front-loaded with conclusions.
- Use descriptive links: “Read ADR-004 cross-tenant access decision” rather than “click here.”
- Use Markdown tables only for simple comparisons; avoid complex merged-cell layouts. For mobile GitHub rendering, keep columns few and labels concise.
- Give every informative image meaningful alt text and a nearby long description. Decorative SVGs/images should be avoided in README; on Pages, mark decorative images with empty alt text only when truly decorative.
- Do not rely on Mermaid, colors, icons, or arrows alone. Add a text “Flow summary” list immediately before or after any diagram.
- If using GitHub Pages HTML, use semantic landmarks (`<header>`, `<main>`, `<nav>`, `<section>`, `<footer>`), visible focus states, sufficient contrast, and responsive layout.

## Safe Microsoft-aligned visual treatment

- Prefer **labels + simple shapes** over Microsoft logos.
- Use official product names accurately and less prominently than Delta Crown / project branding.
- If using icons, store them locally from official Microsoft architecture icon downloads, track the source/terms, and use only for architecture diagrams, training, or documentation.
- Do not hotlink Microsoft icon/logo URLs; it creates availability, privacy, and license-control risks.
- Do not use Microsoft product icons as page hero art, favicons, badges, navigation brand marks, or marketing decoration.
- Add a trademark notice when Microsoft names are used prominently: “Microsoft, Microsoft 365, Microsoft Entra, SharePoint, and Teams are trademarks of the Microsoft group of companies.”

## Stakeholder communication pattern

For executive and operations readers, use a layered story:

1. **Outcome:** what business capability the architecture enables.
2. **Trust boundary:** who can access what and under which controls.
3. **Operating model:** who owns groups, sites, channels, reviews, and exceptions.
4. **Change path:** current state, target state, next implementation step.
5. **Risks and decisions:** top unresolved risks, ADR links, and approval asks.

## Automated vs manual testing gaps

Automated tools can catch many markup issues, but W3C/WAI explicitly warns that tools cannot check all accessibility aspects and human judgment is required. For this use case, manual review is mandatory for:

- Whether alt text or a long description actually communicates the architecture.
- Whether the diagram reading order matches the visual/logical flow.
- Whether color, icon choice, and arrows are understandable without sight or without color perception.
- Whether headings create a usable outline for GitHub’s generated document outline.
- Whether stakeholder readers can understand the access model and decision points.
- Whether Microsoft brand assets are used under permitted terms and do not imply endorsement.

## Primary recommendation

Create a README section and matching GitHub Pages section from the same Markdown source where practical. Make the Markdown source the accessible baseline; make the Pages view a progressive enhancement with better spacing and responsive cards, not a separate source of truth.
