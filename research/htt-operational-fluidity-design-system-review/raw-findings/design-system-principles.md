# Raw findings — Design-system principles relevant to operator briefing decks

## GOV.UK Design System — Colour

Source: https://design-system.service.gov.uk/styles/colour/
Credibility: Tier 2 — mature government design system.

Findings:

- Text and interactive elements must meet WCAG 2.2 SC 1.4.3 Contrast (Minimum) Level AA.
- Functional colors should be assigned by purpose/context, not copied ad hoc.
- Predictable functional color use supports consistency.

Deck implication:

- Treat warm HTT colors as tokens with roles: canvas, surface, text, accent, connector, metadata, focus.
- Do not use gold/cream/green combinations without contrast checks.

## GOV.UK Design System — Spacing

Source: https://design-system.service.gov.uk/styles/spacing/
Credibility: Tier 2.

Findings:

- Use a spacing scale; GOV.UK distinguishes responsive and static spacing scales.
- Applying consistent spacing helps predictable layout.

Deck implication:

- Create a deck spacing scale and protected header/footer safe zones.
- Avoid one-off absolute positioning that allows collision in print-PDF.

## IBM Design Language — Type basics

Source: https://www.ibm.com/design/language/typography/type-basics/
Credibility: Tier 2 — mature vendor design language; page showed last updated 23 Apr 2026.

Findings:

- Good typography includes consistency, hierarchy, and alignment.
- Flush-left alignment aids readability and organization.
- Appropriate leading matters; too open or too tight makes reading unpleasant.
- Avoid all caps for paragraphs; use sentence case.
- Control line lengths; short efficient line lengths are easier to read.
- Keep emphasis styles minimal; too many styles obscure importance.

Deck implication:

- Keep operator copy left-aligned, short, and hierarchically clear.
- Use uppercase/letterspaced metadata sparingly and at readable sizes.

## Material Design 2 — Data visualization

Source: https://m2.material.io/design/communication/data-visualization.html
Credibility: Tier 2 with currency caveat — page states Material 2 is no longer maintained.

Findings:

- Data visualization should be accurate, helpful, and scalable.
- Dashboards/layouts should prioritize the most important information with hierarchy, position, size, color, and visual weight.
- Presentation dashboards provide curated snapshots, few small charts/scorecards, and dynamic headlines explaining insights.
- Color can distinguish, quantify, highlight, or express meaning, but should be reinforced with other cues.
- Multiple colors can hinder focus.
- Use labels with icons; avoid icon-only communication for important information.
- Avoid rotated/vertical labels; use balanced label counts.

Deck implication:

- Relationship diagrams should explain one curated point, not become dashboards.
- Use labels near nodes/connectors; avoid legends where direct labels fit.
- Reinforce brand colors with brand names/logos/text, not hue alone.
