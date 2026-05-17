# Multi-dimensional analysis

## Project context

Reviewed artifacts:

- `decks/htt-operational-fluidity/README.md`
- `decks/htt-operational-fluidity/index.html`
- `decks/htt-operational-fluidity/css/theme.css` / `css/fluidity.css` context from listing and excerpts

The deck is a 10-slide Reveal.js presentation for operators. It uses:

- A 1600×900 canvas.
- Warm HTT palette: cream, green/teal, gold.
- HTML sections with repeated `.rail` and `.footer` metadata.
- Logo pairings and brand cards.
- Relationship diagrams: pressure map, journey bar, layer stack, metric chain.
- Concise narrative intentionally avoiding architecture/platform detail.

## Security / accessibility risk

- The primary risk is not security; it is accessibility and reputational risk if executive materials are distributed as inaccessible HTML/PDF.
- WCAG 2.2 AA applies when the deck is web content or exported/distributed as digital material with accessibility expectations.
- Required checks:
  - Text contrast: 4.5:1 for normal text; 3:1 for large text.
  - Meaningful graphic contrast: 3:1 for diagram lines, icons, boundaries, arrows, and focus indicators.
  - No color-only meaning in brand cards, metric chains, status cues, or diagrams.
  - Semantic structure: each slide should have a real heading; diagrams need labels or concise text equivalents.
  - Keyboard and focus: Reveal controls and any custom navigation must remain keyboard-visible.
- PDF export should not be assumed accessible merely because HTML is accessible. If distributed, review reading order, document title, alt text, tags, and contrast in the exported PDF.

## Cost

- Low implementation cost: most improvements are CSS token/rule additions and review guidelines.
- Highest cost item is PDF accessibility if a fully compliant PDF handout is required; HTML-first distribution is cheaper and more adaptable.
- Avoid costly manual slide-by-slide fixes by creating reusable classes: `.slide-inner`, `.safe-content`, `.rail`, `.footer`, `.logo-lockup`, `.diagram`, `.meta`.

## Implementation complexity

- Low to medium.
- Low complexity:
  - Add safe-zone CSS variables.
  - Add metadata size/contrast tokens.
  - Add logo sizing tokens.
  - Add diagram connector classes.
- Medium complexity:
  - Verify accessible names/text equivalents for custom diagrams.
  - Test print-PDF collision and exported PDF readability.
  - Create a small visual-regression checklist across 1600×900, 1280×720, and print-PDF.

## Stability

- Reveal.js is stable for HTML decks, but print-PDF can surface layout differences. Any design-system rule should be tested in live and `?print-pdf` modes.
- CSS `clamp()` and modern layout features are stable in current Chromium-based PDF export paths; still verify.
- Remote font dependency can affect deck appearance if offline. Consider local fallback or font-display behavior for live briefings.

## Optimization / performance

- Large logo PNGs can slow first load and PDF export. Current logos include several large files; use optimized dimensions for deck display where possible.
- Use CSS effects sparingly on projected decks. Heavy gradients, masks, and animations can reduce legibility on conference-room displays.
- Prefer SVG or optimized transparent PNG for logos/diagram icons when available.

## Compatibility

- HTML/CSS deck works well for browser delivery and PDF export.
- Projection environments vary: warm low-contrast palettes can wash out. Use contrast-tested tokens with extra margin above WCAG thresholds.
- Avoid relying on very thin gold hairlines on dark gradients; anti-aliasing and projectors can make them disappear.

## Maintenance

- Codify deck rules in the deck README and CSS comments so later slide additions do not break density/safe zones.
- Maintain brand token provenance in README; add accessibility notes next to tokens.
- Add a checklist before any operator briefing export:
  1. Review slide count and timing.
  2. Run HTML accessibility audits where available.
  3. Manually inspect header/footer collisions.
  4. Inspect logos for optical balance.
  5. Inspect diagrams in grayscale/color-blind simulation or at least without relying on hue.
  6. Export PDF and verify every footer, logo, and diagram remains readable.

## Design-system implications by requested topic

### Warm brand style

Warmth should come from background tone, restrained gold accents, rounded cards, and humane copy — not from lowering contrast or adding decorative density. Use gold for emphasis and dividers only when it passes required contrast or is decorative.

### Slide density

For 10–12 minutes, assume ~60–75 seconds per content slide after open/close. Use one decision-level idea per slide. Avoid dense tables except the 3-row practice slide pattern already used.

### Footer/header collision avoidance

Fixed rails should reserve physical space. Components should use `min-height`/`max-height` and safe-area padding instead of absolute positioning into the same zones.

### Metadata legibility

Metadata is secondary, but still content. If it communicates slide number, audience, or framing, it must remain legible and pass contrast. Avoid tiny uppercase tracking that looks elegant on a retina screen but fails in a room.

### Logo sizing / optical balance

Logos differ by aspect ratio, fill density, and whitespace inside PNG bounds. Optical balance requires brand-specific max dimensions and sometimes visual cropping/transparent padding normalization.

### Relationship cues in diagrams

Use multiple cues: spatial grouping, connector line/arrow, label, numbering, and shape. Color can reinforce but not carry meaning alone. Meaningful connector lines require 3:1 non-text contrast unless equivalent text makes them decorative.

## WCAG 2.2 AA implications for slide decks

If the slide deck is HTML/CSS, it is web content. WCAG 2.2 AA implications include:

- **1.1.1 Non-text Content:** logos may have concise alt text or be decorative depending on context; diagrams need text alternatives or equivalent visible text.
- **1.3.1 Info and Relationships:** headings/lists/tables/diagram relationships should be semantic or explained in text.
- **1.4.1 Use of Color:** brand colors cannot be the only relationship/status cue.
- **1.4.3 Contrast Minimum:** 4.5:1 normal text; 3:1 large text.
- **1.4.11 Non-text Contrast:** meaningful diagram objects, icons, borders, and focus indicators need 3:1.
- **1.4.5 Images of Text:** avoid image-based text except logos; use real HTML text.
- **1.4.10 Reflow / responsive behavior:** if deck is distributed as web content, users should be able to zoom/adapt; fixed-canvas decks complicate this, so provide an accessible HTML notes/handout version if necessary.
- **2.1.1 Keyboard / 2.4.7 Focus Visible / 2.4.13 Focus Appearance:** navigation and controls must work and show focus.
- **2.2.x Timing / Pause controls:** animations should not block comprehension; avoid blinking/flashing.
- **2.3.1 Three Flashes:** avoid flashing content.
- **2.4.2 Page Titled:** deck document title is present; keep meaningful.
- **2.4.6 Headings and Labels:** slide headings should describe topic/purpose.
- **3.1.5 Reading Level (AAA, not AA):** not required for AA, but operator audience benefits from plain language.
- **Captions/transcripts:** required if audio/video media is added; live briefings should provide captions where needed.
