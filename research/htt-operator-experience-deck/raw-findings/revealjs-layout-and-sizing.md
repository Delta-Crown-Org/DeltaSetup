# Raw Findings — Reveal.js Layout and Sizing

Sources:
- https://revealjs.com/layout/
- https://revealjs.com/presentation-size/

Extracted findings:

- Reveal.js presentations have a configured “normal” size and scale uniformly to fit different displays/viewports while preserving aspect ratio and layout.
- Documented defaults include `width: 960`, `height: 700`, `margin: 0.04`, `minScale: 0.2`, and `maxScale: 2.0`.
- `center: false` disables automatic vertical centering and leaves slides fixed at the configured height.
- `embedded` changes whether Reveal assumes full viewport control.
- `disableLayout` can turn off built-in scaling/centering, but then responsive layout is author responsibility.
- Layout helpers:
  - `r-stack`: centers and overlays multiple elements, often with fragments.
  - `r-fit-text`: enlarges text to fit without overflowing; useful for intentionally large words, risky for consistent typography if overused.
  - `r-stretch`: stretches one direct child to fill remaining vertical space.
  - `r-frame`: frames content visually.

Deck implications:

- Use a predictable 16:9 configuration for projector/browser stability, e.g. 1280×720.
- Avoid authoring important content that only works because of automatic scale magic.
- Use `center: false` for consistent placement of title/evidence/takeaway zones.
- Use helper classes sparingly; build most layout with CSS Grid/Flex.
