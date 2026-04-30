# Sources and credibility assessment

## Tier 1: official / primary sources

| Source | Authority | Currency observed | Key finding | Reliability notes |
|---|---|---|---|---|
| W3C WAI — WCAG 2 Overview (`https://www.w3.org/WAI/standards-guidelines/wcag/`) | Tier 1 official standards body | Page notes WCAG 2.2 published 2023-10-05 and updated 2024-12-12; page also references ISO/IEC 40500:2025 | WCAG 2.2 is latest encouraged version; organized by perceivable, operable, understandable, robust; content conforming to 2.2 also conforms to 2.1/2.0 except obsolete parsing nuance. | Highest authority for WCAG baseline. |
| W3C WAI — Selecting Web Accessibility Evaluation Tools (`https://www.w3.org/WAI/test-evaluate/tools/selecting/`) | Tier 1 official accessibility guidance | Current WAI guidance | Tools help identify potential issues but cannot determine accessibility alone; human judgment is required; tools can produce false/misleading results. | Highest authority for automated vs manual testing gap. |
| GitHub Docs — Basic writing and formatting syntax | Tier 1 official vendor docs | Current GitHub docs | GitHub supports headings, links, relative links, images with alt text, alerts, and document outline from headings; recommends relative links for repository images. | Primary for GitHub Markdown behavior. |
| GitHub Docs — Creating diagrams | Tier 1 official vendor docs | Current GitHub docs | GitHub Markdown supports Mermaid, GeoJSON, TopoJSON, and ASCII STL diagrams in Markdown files, issues, PRs, discussions, and wikis. | Primary for GitHub-rendered diagrams. |
| GitHub Docs — What is GitHub Pages? | Tier 1 official vendor docs | Current GitHub docs | GitHub Pages publishes static HTML/CSS/JS from a repository and logs visitor IP addresses for security. | Primary for Pages platform constraints and privacy note. |
| Microsoft Learn — Microsoft Entra architecture icons | Tier 1 official vendor docs | Last updated 2023-10-23 | Microsoft permits Entra icons in architectural diagrams, training materials, or documentation only; don’t crop/flip/rotate/distort; don’t use product icons to represent your own service or in marketing. | Primary for Entra icon terms; page showed access notice but content extracted. |
| Microsoft Learn — Microsoft 365 architecture templates and icons | Tier 1 official vendor docs | Last updated 2024-04-29; archived path | Microsoft permits M365 icons in architectural diagrams, training materials, or documentation; includes SVG icons and Visio templates/stencils. | Primary but archived; use cautiously and preserve terms/source. |
| Microsoft Learn — Azure architecture icons | Tier 1 official vendor docs | Last updated 2025-12-18 | Similar official icon do/don’t rules; product names near icons; use icons as they appear in Azure; no distortion or own-product representation. | Corroborates icon rules across Microsoft architecture icon sets. |
| Microsoft Legal — Trademark and Brand Guidelines | Tier 1 official legal guidance | Page footer copyright 2026 | Microsoft brand assets include logos, icons, designs, product names; many uses require a license; wordmarks may be used truthfully and less prominently; don’t imply endorsement; include trademark notice. | Primary legal/brand source; not a substitute for counsel. |
| Microsoft Learn — What is Microsoft Entra? | Tier 1 official product docs | Last updated 2026-04-09 | Microsoft Entra is identity and network access product family supporting Zero Trust; Entra ID is foundational IAM for Microsoft 365/Azure/Dynamics tenants. | Primary for accurate product terminology. |

## Tier 2: package registry / vendor release data

| Source | Authority | Currency observed | Key finding | Reliability notes |
|---|---|---|---|---|
| npm registry via `npm view axe-core version` | Tier 2 package registry | Checked 2026-04-30 | axe-core current npm version: 4.11.4 | Good for current version; cross-check with GitHub release page. |
| npm registry via `npm view pa11y version` | Tier 2 package registry | Checked 2026-04-30 | Pa11y current npm version: 9.1.1 | Good for current version. |
| npm registry via `npm view lighthouse version` | Tier 2 package registry | Checked 2026-04-30 | Lighthouse current npm version: 13.1.0 | Good for current npm package version. |
| GitHub releases — dequelabs/axe-core | Tier 2 vendor/source repository | Latest visible release 4.11.4 on 2026-04-28 | Confirms axe-core release recency and that patch releases can change false positives/target-size behavior. | Strong source for release notes; GitHub page had partial loading errors but release content visible. |

## Bias and validation notes

- Microsoft sources are authoritative for Microsoft terms and trademarks but have vendor interest; cross-reference accessibility guidance with W3C/WAI.
- GitHub Docs are authoritative for GitHub rendering but not a WCAG conformance guarantee.
- npm registry is accurate for package versions but does not assess tool quality.
- No source should be read as legal approval for Microsoft trademark/icon use; route ambiguous use through counsel or avoid icons.
