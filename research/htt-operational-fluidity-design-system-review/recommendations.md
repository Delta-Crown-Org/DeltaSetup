# Concise implementation recommendations

## 1. Add deck-level design tokens

```css
:root {
  --slide-w: 1600px;
  --slide-h: 900px;
  --safe-x: 96px;
  --safe-top: 78px;
  --safe-bottom: 74px;
  --rail-h: 34px;
  --footer-h: 30px;
  --content-gap: 32px;

  --meta-size: 14px;
  --meta-tracking: 0.16em; /* avoid excessive tracking under 14px */
  --diagram-line: 2px;
  --diagram-line-strong: 3px;

  --logo-lockup-h: 34px;
  --logo-feature-h: 54px;
}
```

## 2. Enforce protected header/footer zones

```css
.slide {
  position: relative;
  min-height: 100%;
}

.slide-content {
  position: relative;
  z-index: 1;
  padding: calc(var(--safe-top) + var(--rail-h)) var(--safe-x)
           calc(var(--safe-bottom) + var(--footer-h));
  min-height: 100%;
  box-sizing: border-box;
}

.rail,
.footer {
  position: absolute;
  left: var(--safe-x);
  right: var(--safe-x);
  z-index: 3;
}

.rail { top: 34px; min-height: var(--rail-h); }
.footer { bottom: 30px; min-height: var(--footer-h); }
```

**Rule:** diagrams/cards may be large, but they must live inside `.slide-content`; only rails/footers can occupy the protected zones.

## 3. Set density budgets by slide type

| Slide type | Max content |
|---|---|
| Title / close | 1 eyebrow, 1 headline, 1 lede, 1 logo lockup. |
| Statement | 1 headline, 1 lede, 1 visual metaphor. |
| Principle grid | 3 cards max. |
| Journey / chain | 5 steps max, each 1 label + 1 short phrase. |
| Practice table | 3 rows max, 3 columns max. |
| Brand grid | 4 cards max; each card 1 logo, 1 label, 1 promise, 1 micro-caption. |

If a slide exceeds the budget, split it or move detail to notes.

## 4. Make metadata readable without competing

```css
.rail,
.footer,
.meta {
  font-size: var(--meta-size);
  line-height: 1.35;
  letter-spacing: var(--meta-tracking);
  color: rgba(16, 35, 31, 0.78); /* on light */
}

.dark .rail,
.rail.dark,
.dark .footer,
.footer.dark {
  color: rgba(255, 250, 240, 0.78); /* verify 4.5:1 if text */
}
```

**Guidance:** if metadata is essential text, test it as normal text at 4.5:1. If decorative, hide from assistive tech and keep it visually subdued.

## 5. Balance logos optically

```css
.logo-pair,
.logo-lockup {
  display: inline-flex;
  align-items: center;
  gap: 18px;
}

.logo-pair img {
  display: block;
  max-height: var(--logo-lockup-h);
  max-width: 170px;
  object-fit: contain;
}

.logo-pair img[src*="htt"] { max-height: 30px; max-width: 150px; }
.logo-pair img[src*="dce"] { max-height: 32px; max-width: 160px; }
.brand-card img { max-height: 42px; max-width: 180px; object-fit: contain; }
```

**Review visually, not mathematically:** HTT white PNGs are visually dense; some sibling marks have more internal whitespace. Adjust per mark until the lockup feels equal in weight.

## 6. Strengthen relationship cues in diagrams

Use a pattern like:

```css
.diagram-node {
  border: 1.5px solid var(--diagram-border);
  border-radius: 18px;
}

.diagram-connector {
  stroke: var(--diagram-connector);
  stroke-width: var(--diagram-line-strong);
  stroke-linecap: round;
  marker-end: url(#arrow);
}

.diagram-label {
  font-size: 18px;
  line-height: 1.25;
}
```

Diagram rule set:

- Every relationship gets a **label or directional cue**.
- Use **position + connector + label**, not color alone.
- Use line styles for type: solid = current flow, dashed = feedback loop, dotted = optional/secondary.
- Keep relationship diagrams to **5 nodes or fewer** for this briefing format.
- If a connector is required to understand the diagram, it needs 3:1 contrast or an equivalent text explanation.

## 7. Preserve warm brand style safely

- Prefer warm cream surfaces and deep green text for operator readability.
- Use gold as accent, not body text, unless tested.
- Avoid low-opacity gold hairlines for essential diagram meaning.
- Let warmth come from language: “support,” “clarity,” “confidence,” “close the loop,” not just palette.

## 8. Accessibility QA checklist for this deck

Before briefing/export:

```bash
# If public-page files are touched, run repo gates per AGENTS.md.
python3 tests/accessibility_static_audit.py
python3 tests/browser_smoke_audit.py
python3 tests/accessibility_axe_audit.py
```

Manual deck-specific checks:

- [ ] At 1600×900, no card/diagram/logo intersects `.rail` or `.footer`.
- [ ] At 1280×720 or browser zoom, essential content remains visible or has an accessible fallback.
- [ ] In `?print-pdf`, slide numbers, footers, logos, and diagrams remain legible.
- [ ] All essential text meets 4.5:1 unless large text qualifies for 3:1.
- [ ] Meaningful diagram lines/icons/borders meet 3:1.
- [ ] No slide communicates status/brand grouping by color alone.
- [ ] Every slide has a meaningful heading.
- [ ] Logos have appropriate alt text when informative; decorative duplicates are hidden.
- [ ] Presenter script describes important visual diagrams instead of saying “as you can see.”
- [ ] If distributed as PDF, PDF accessibility is reviewed separately.

## 9. Suggested README addition for maintainers

```md
### Design-system guardrails

This deck is built for a 10–12 minute operator briefing. Keep each slide to one idea.
Do not place content in the protected rail/footer zones. Metadata must remain readable
in browser and print-PDF export. Diagram relationships must be conveyed by labels,
connectors, grouping, or shape — never color alone. Treat HTML as the accessible source;
PDF export requires separate review before distribution.
```
