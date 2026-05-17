# Raw findings — CSS typography, layout, and glass implementation

Sources:
- MDN `backdrop-filter`: https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter
- MDN `font-kerning`: https://developer.mozilla.org/en-US/docs/Web/CSS/font-kerning
- MDN CSS Grid layout: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout

Accessed: 2026-05-17

## `backdrop-filter`

- Applies graphical effects such as blur or color shifting to the area behind an element.
- To see the effect, the element or its background needs to be transparent or partially transparent.
- Baseline 2024: works across latest devices/browser versions since September 2024, but may not work on older devices/browsers.
- Backdrop roots can affect blur behavior; parent properties such as opacity, filters, masks, `backdrop-filter`, mix-blend-mode, or `will-change` can bound what is blurred.

## `font-kerning`

- Controls whether kerning information stored in a font is used.
- Well-kerned fonts make character spacing more uniform and pleasant by reducing whitespace between certain combinations.
- Widely available across browsers since January 2020.

## CSS Grid

- CSS Grid divides a page into major regions and defines relationships in terms of size, position, and layering.
- Grid enables columns, rows, gaps, alignment, and layered/overlapping placements.
- Useful for slide systems where text, diagrams, rails, and cards need consistent alignment.

## Deck implications

- Use `font-kerning: normal` and careful `letter-spacing` for large deck titles.
- Use CSS Grid for the main slide composition rather than ad hoc absolute positioning.
- Use glass cards only with fallback solid/semi-solid backgrounds and contrast checks; beware of parent backdrop roots and PDF/export differences.