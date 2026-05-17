# Multi-dimensional analysis

## Security / legal / brand protection

- Use only canonical brand book assets and registered logo files supplied/approved for Frenchies, The Lash Lounge, and Bishops.
- Do not recolor, stretch, crop, outline, or apply effects that materially alter third-party marks. Prefer approved light/dark variants.
- Keep local asset paths explicit and versioned; avoid hotlinking logos from public sites.
- Add alt text for meaningful logos; if a logo appears next to visible brand name text and adds no information, use `alt=""` to avoid redundancy.

## Cost

- Low implementation cost: CSS tokens + reusable proof-slide component avoid bespoke slide-by-slide production.
- Moderate QA cost: contrast and screenshot checks should be automated where possible; visual review still needed for brand compliance.
- Avoid expensive rework by locking slide dimensions and logo clear-space rules before final copy/art direction.

## Implementation complexity

- Reveal.js supports required layouts directly: fixed authoring size, background attributes, helper classes, and CSS-driven slide sections.
- Biggest complexity is asset QA: ensuring SVG/PNG fallbacks, correct variant selection on dark/light surfaces, and no broken logo paths in PDF/export.
- Use CSS custom properties per brand (`--brand-bg`, `--brand-ink`, `--brand-accent`, `--logo-bg`) instead of duplicating layout CSS.

## Stability

- Reveal.js layout APIs are stable and official.
- WCAG contrast rules are mature and suitable for executive decks even when slides are not traditional apps.
- MDN-documented `<picture>` fallback and CSS filters are widely available; keep plain `<img src>` fallback present.

## Optimization

- Prefer SVG logos for sharp scaling; use optimized transparent PNG fallback for brand marks where SVG is unavailable/unsupported by the export flow.
- Define `width` and `height` on images/logos to reduce layout shift and maintain stable screenshot comparisons.
- Use local assets and avoid large hero images where a masked/cropped proof mockup is sufficient.
- Use `filter: drop-shadow()` sparingly for transparent logos; avoid heavy blur effects in PDF export.

## Compatibility

- Test Chromium browser presentation and PDF export. If a PDF export renderer fails on `color-mix()`, provide fallback colors before advanced functions.
- Use `<picture>` with an `<img>` fallback; do not depend solely on SVG if the downstream PDF workflow may rasterize unpredictably.
- For Reveal.js backgrounds, use `data-background-color` or CSS backgrounds for core slide surfaces; reserve image backgrounds for decorative proof mockups.

## Maintenance

- Centralize all deck tokens in one CSS file: DCE base tokens, layout tokens, proof-brand tokens.
- Add an asset manifest table mapping each logo to its light/dark/background-safe usage.
- Create a manual brand QA checklist: clear space, minimum size, background pairing, no recolor, registered mark visible where required.
- Keep proof-slide structure identical across Frenchies / Lash Lounge / Bishops so new HTT brands can be added as token-only re-skins.

## Accessibility / contrast analysis

- DCE gold works well on dark teal (`7.75:1`) and can be used for text labels on dark slides.
- DCE gold fails on white (`2.21:1`), and darker gold still fails (`2.86:1`); do not use gold as text on light backgrounds.
- Use DCE teal on light paper for body text (`6.15:1`), and near-black for executive body copy where possible.
- Logos are exempt from contrast requirements as logotypes, but not the surrounding proof-slide explanatory copy.
- For brand-heavy slides, if a logo color lacks contrast on the slide surface, place it in an approved logo tile/background rather than changing the logo.

## Proof-slide structure analysis

Recommended composition for each proof slide:

1. **Top rail:** small DCE/HTT system marker + slide number; restrained, consistent.
2. **Proof header:** “Brand re-skin proof: [Brand]” + one executive claim.
3. **Logo tile:** canonical mark in approved variant, with clear space and fixed max dimensions.
4. **Brand token row:** 3–5 approved swatches with labels; labels must meet contrast.
5. **Mock shell:** one framed UI/portal/deck component re-skinned to the brand, not a full product mockup.
6. **Takeaway cards:** 2–3 bullets focused on governance, repeatability, and speed.
7. **Footer note:** “Brand assets shown from approved/canonical source files” if appropriate.

This structure demonstrates repeatability without implying unapproved brand modifications.
