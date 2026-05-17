# Project-specific recommendations

## Priority 0 — lock system rules before slide polishing

1. Configure Reveal.js for a fixed 16:9 executive canvas:

```js
Reveal.initialize({
  width: 1600,
  height: 900,
  margin: 0.04,
  minScale: 0.2,
  maxScale: 2.0,
  center: false,
  hash: true,
  transition: 'fade',
  backgroundTransition: 'fade'
});
```

2. Create one deck CSS file with sections:
   - DCE base tokens
   - layout primitives
   - typography primitives
   - logo/proof components
   - brand proof token overrides
   - print/PDF overrides

3. Ban inline styles for final deck slides except Reveal-specific data attributes.

## Priority 1 — logo rendering / fallback handling

Use this markup pattern for canonical logo assets:

```html
<picture class="brand-logo brand-logo--frenchies">
  <source srcset="assets/brands/frenchies/logo-dark.svg" type="image/svg+xml" media="(prefers-color-scheme: light)">
  <source srcset="assets/brands/frenchies/logo-light.svg" type="image/svg+xml" media="(prefers-color-scheme: dark)">
  <img
    src="assets/brands/frenchies/logo-dark.png"
    width="360"
    height="120"
    alt="Frenchies"
    loading="eager"
    decoding="async">
</picture>
```

CSS:

```css
.brand-logo {
  display: inline-grid;
  place-items: center;
  inline-size: min(380px, 100%);
  block-size: 128px;
}
.brand-logo > img,
.brand-logo img {
  max-inline-size: 100%;
  max-block-size: 100%;
  object-fit: contain;
}
.logo-box--dark img { filter: drop-shadow(0 8px 20px rgba(0,0,0,.28)); }
.logo-box--light img { filter: none; }
```

Rules:

- Prefer approved SVG; fall back to PNG.
- Keep a real `img src` fallback.
- Use explicit dimensions.
- Do not apply `mix-blend-mode`, `invert()`, `hue-rotate()`, or CSS recoloring to registered logos.
- If contrast is poor, change the approved logo tile/background, not the logo.

## Priority 2 — accessible contrast in brand-heavy slides

Token rules:

```css
/* Good */
.slide--dark .gold-text { color: #E8C989; } /* 10.73:1 on #0A1F1C */
.slide--light .primary-text { color: #0A1F1C; }
.slide--light .teal-text { color: #006B5E; } /* 6.15:1 on #FAFAF7 */

/* Avoid for text */
.slide--light .gold-text { color: #D4A84B; } /* 2.21:1 on white */
```

Design rules:

- Put copy on solid or semi-opaque panels; do not rely on photo brightness.
- Use 4.5:1 minimum for body text; target 7:1 for executive confidence and projector conditions.
- Use 3:1 minimum for meaningful icons, rules, chart lines, and focus indicators.
- Logo marks may remain canonical under WCAG exceptions, but captions/labels around them must pass.
- Avoid thin gold lines as the only separator on light backgrounds; add darker teal/ink label or thicker decorative band.

## Priority 3 — polished proof-slide structure

Recommended slide layout:

```html
<section class="proof-slide proof--bishops">
  <div class="proof-layout">
    <header class="proof-header">
      <p class="eyebrow">Brand re-skin proof</p>
      <h2>Bishops keeps its edge. The platform stays governed.</h2>
    </header>

    <aside class="logo-box">
      <!-- canonical logo picture/img here -->
    </aside>

    <div class="proof-card proof-card--mock">
      <!-- re-skinned shell / portal card / component sample -->
    </div>

    <ul class="takeaway-list">
      <li>Token swap, not custom rebuild.</li>
      <li>Approved logo/background pair preserved.</li>
      <li>Shared QA gates protect every brand.</li>
    </ul>
  </div>
</section>
```

Proof-specific art direction:

- **Frenchies:** cream/peach base, navy ink, terracotta CTA, warm editorial image crop, generous whitespace, soft corners.
- **The Lash Lounge:** plum/mauve palette, refined serif headline, circular or rounded beauty imagery, elegant spacing.
- **Bishops:** black/white/orange, bold headline, halftone or monochrome imagery, energetic CTA, sharper contrast.

## Priority 4 — QA checklist

Before final executive review:

- [ ] All 16 slides render at 1600×900 and laptop viewport without overflow.
- [ ] Every logo path resolves; SVG and PNG fallback exist.
- [ ] Brand marks are not recolored, stretched, cropped, or filtered beyond mild drop-shadow where allowed.
- [ ] Logo clear-space/min-size confirmed against brand book.
- [ ] Body text contrast >= 4.5:1; target >= 7:1 where practical.
- [ ] Large display text >= 3:1, preferably >= 4.5:1 for projector conditions.
- [ ] Meaningful icons/rules/chart lines >= 3:1.
- [ ] No explanatory text is embedded in images unless duplicated as selectable HTML text.
- [ ] PDF export checked for logo sharpness, missing backgrounds, and filter artifacts.
- [ ] Public-page quality gates run if deck changes touch `index.html`, `css/`, or `js/` in the public site.

## Optional automation ideas

- Add a simple asset manifest JSON:

```json
{
  "brands": {
    "frenchies": {
      "logoDarkSvg": "assets/brands/frenchies/logo-dark.svg",
      "logoDarkPng": "assets/brands/frenchies/logo-dark.png",
      "approvedBackgrounds": ["#fff8f0", "#f6ede5"]
    }
  }
}
```

- Write a preflight script that checks file existence, image dimensions, and forbidden CSS filters on `.brand-logo img`.
- Capture screenshots of all slides with Playwright/Chromium and compare against approved baselines before final PDF export.
