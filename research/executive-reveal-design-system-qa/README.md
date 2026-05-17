# Executive Reveal.js Design-System QA Research

## Executive summary

For the HTT/DCE 16-slide executive intro deck, treat the DCE teal/gold system as the **presentation frame** and each proof brand as a **contained re-skin specimen**. The deck should feel premium and controlled, not like three brands were poured into one theme.

Top recommendations:

1. **Lock the deck to a 16:9 authored canvas** (`width: 1600`, `height: 900`, `margin: 0.04`, `center: false`) and use named slide-layout classes, not per-slide inline tweaks.
2. **Use theme-aware logo components** with SVG preferred and PNG fallback. Always select approved light/dark logo variants instead of recoloring third-party marks.
3. **Never rely on brand logo contrast exemptions for surrounding content.** Logos can remain canonical, but headings, captions, proof labels, UI chrome, and metric cards must pass WCAG contrast.
4. **Reserve DCE gold for dark teal surfaces.** Gold on white fails contrast (2.21:1), so on light slides use teal/near-black text and gold only as a decorative rule/accent.
5. **Structure proof slides consistently:** proof header, canonical logo lockup, brand-token swatch row, before/after or “brand shell” mockup, and 2–3 executive takeaways.
6. **Use stable text panels/scrims over imagery.** Background photos and gradients must not be the contrast source for executive copy.
7. **QA the deck as a design system:** visual regression screenshots, contrast-token checks, logo file existence/fallback checks, browser smoke across 16:9 and laptop viewport, and PDF export spot check.

## Implementation-ready CSS pattern

```css
:root {
  --deck-w: 1600px;
  --deck-h: 900px;
  --dce-teal-950: #0A1F1C;
  --dce-teal-700: #006B5E;
  --dce-gold-500: #D4A84B;
  --dce-gold-300: #E8C989;
  --paper: #FAFAF7;
  --ink: #10201d;
}

.reveal .slides section {
  box-sizing: border-box;
  padding: 64px 80px;
  color: var(--ink);
  background: var(--paper);
}

.slide--dark {
  background: radial-gradient(circle at 80% 10%, rgba(212,168,75,.12), transparent 36%), var(--dce-teal-950);
  color: #fff;
}

.slide--dark .eyebrow { color: var(--dce-gold-300); }
.slide--light .eyebrow { color: var(--dce-teal-700); } /* not gold on white */

.slide-grid-2 {
  display: grid;
  grid-template-columns: minmax(0, .95fr) minmax(0, 1.05fr);
  gap: 64px;
  align-items: center;
  min-height: 100%;
}

.logo-box {
  display: inline-grid;
  place-items: center;
  min-width: 280px;
  min-height: 112px;
  padding: 24px 32px;
  border-radius: 24px;
  background: var(--logo-bg, rgba(255,255,255,.08));
}

.logo-box img {
  max-width: min(360px, 100%);
  max-height: 96px;
  object-fit: contain;
  filter: drop-shadow(0 10px 24px rgba(0,0,0,.20));
}

.proof-slide {
  --brand-accent: var(--dce-gold-500);
  --brand-bg: var(--paper);
  --brand-ink: var(--ink);
  background: var(--brand-bg);
  color: var(--brand-ink);
}

.proof-card {
  border: 1px solid color-mix(in srgb, var(--brand-accent), transparent 72%);
  border-radius: 32px;
  padding: 36px;
  background: rgba(255,255,255,.82);
  box-shadow: 0 24px 80px rgba(10,31,28,.14);
}
```

## Suggested proof-slide CSS tokens

Use exact canonical values from the brand books where available. The observations below are directional from official public brand pages and should be replaced with approved token values.

```css
.proof--frenchies {
  --brand-bg: #f6ede5;
  --brand-ink: #202a44;
  --brand-accent: #b76550;
  --logo-bg: #fff8f0;
}

.proof--lash-lounge {
  --brand-bg: #f3eef2;
  --brand-ink: #563650;
  --brand-accent: #563650;
  --logo-bg: #ffffff;
}

.proof--bishops {
  --brand-bg: #ffffff;
  --brand-ink: #050505;
  --brand-accent: #f35b17;
  --logo-bg: #ffffff;
}
```

## Saved files

- `sources.md` — sources and credibility assessment
- `analysis.md` — multi-dimensional QA analysis
- `recommendations.md` — prioritized implementation recommendations
- `raw-findings/` — extracted findings and project context
