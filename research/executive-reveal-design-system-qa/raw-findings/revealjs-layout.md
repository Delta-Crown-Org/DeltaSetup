# Reveal.js layout findings

Source: https://revealjs.com/layout/ and https://revealjs.com/presentation-size/

- Reveal scales presentations uniformly from an authored “normal” size, preserving aspect ratio across displays.
- Config supports `width`, `height`, `margin`, `minScale`, `maxScale`; default width/height are 960x700.
- `center: false` disables automatic vertical centering, useful for fixed executive layouts.
- `data-background-*` attributes apply full-page slide backgrounds outside the slide content area; image backgrounds default to `cover`, with `data-background-size`, `position`, `repeat`, and opacity controls.
- `r-stack` layers elements; `r-fit-text` maximizes headline size without overflow; `r-stretch` gives one direct slide child remaining vertical space.

Implication: use a fixed 16:9 authoring canvas, low content density, named layout classes, and controlled background overlays rather than ad hoc inline positioning.
