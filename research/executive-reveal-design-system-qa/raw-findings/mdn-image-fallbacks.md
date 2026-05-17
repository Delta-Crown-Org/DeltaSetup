# MDN image fallback findings

Sources: MDN `<picture>` and CSS `drop-shadow()`.

- `<picture>` contains zero or more `<source>` elements and one required `<img>` fallback.
- Browser selects first compatible matching source; if none match or picture unsupported, it uses the `img src`.
- Common use cases include alternative image formats, art direction, high-density assets, and light/dark theme swaps using `prefers-color-scheme` media queries.
- `object-fit` and `object-position` should be applied to the child `<img>`.
- `filter: drop-shadow()` follows the input image alpha mask, unlike `box-shadow` which shadows the rectangular element box.

Implication: logo components should prefer SVG where approved, fall back to PNG, include width/height to avoid layout shift, and select dark/light variants by slide theme. Shape-aware drop-shadow can improve edge separation without adding a visible box around transparent logos.
