# Project-Specific Recommendations

## Priority 1 — Add a deck-level token layer

Create a v2 CSS file scoped to the Reveal deck, not global site CSS.

```css
:root {
  --of-cream: #f7f2e8;
  --of-ink: #13231f;
  --of-green: #0f3a32;
  --of-gold: #c89b3c;
  --of-muted: #54615c;
  --of-safe-x: clamp(56px, 6vw, 104px);
  --of-safe-top: 72px;
  --of-safe-bottom: 64px;
  --of-radius-lg: 28px;
  --of-shadow-card: 0 24px 80px rgba(15,58,50,.14);
  --of-ease: cubic-bezier(.22,1,.36,1);
}
```

## Priority 2 — Use repeatable slide shells

```html
<section class="of-slide of-slide--editorial">
  <header class="of-rail">
    <p class="of-kicker">Operational Fluidity</p>
    <p class="of-step">02 / Brand operator view</p>
  </header>

  <div class="of-grid">
    <div class="of-copy span-5">
      <h2 class="of-title">Operators need one calm path.</h2>
      <p class="of-lede">The platform should turn brand complexity into a simple daily operating rhythm.</p>
    </div>
    <div class="of-panel span-7 glass-card">
      <!-- journey or cards -->
    </div>
  </div>
</section>
```

```css
.of-slide { padding: var(--of-safe-top) var(--of-safe-x) var(--of-safe-bottom); }
.of-rail {
  position: absolute;
  inset: 28px var(--of-safe-x) auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: color-mix(in srgb, var(--of-ink) 62%, transparent);
  font: 700 12px/1 system-ui;
  letter-spacing: .12em;
  text-transform: uppercase;
}
.of-grid {
  height: calc(900px - var(--of-safe-top) - var(--of-safe-bottom));
  display: grid;
  grid-template-columns: repeat(12, minmax(0, 1fr));
  gap: 32px;
  align-items: center;
}
.span-5 { grid-column: span 5; }
.span-7 { grid-column: span 7; }
```

## Priority 3 — Typography tightening rules

```css
.of-title {
  max-width: 11ch;
  margin: 0;
  font-family: var(--font-display, Georgia, serif);
  font-size: clamp(56px, 6.2vw, 94px);
  line-height: .93;
  letter-spacing: -.045em;
  font-kerning: normal;
  text-wrap: balance;
}
.of-lede {
  max-width: 48ch;
  margin-top: 24px;
  font: 450 clamp(22px, 2vw, 30px)/1.32 var(--font-sans, system-ui);
  letter-spacing: -.01em;
  color: var(--of-muted);
}
.of-microcopy {
  font-size: 14px;
  line-height: 1.45;
  letter-spacing: .01em;
}
```

**Do:** large titles with tight tracking.  
**Do not:** apply negative tracking to 14–18px labels/body copy.

## Priority 4 — Glass card system with fallbacks

```css
.glass-card {
  background: rgba(255,255,255,.82);
  border: 1px solid rgba(200,155,60,.28);
  border-radius: var(--of-radius-lg);
  box-shadow: var(--of-shadow-card), inset 0 1px 0 rgba(255,255,255,.72);
  padding: 32px;
}

@supports (backdrop-filter: blur(18px)) {
  .glass-card {
    background: color-mix(in srgb, #fff 74%, transparent);
    backdrop-filter: blur(18px) saturate(1.14);
    -webkit-backdrop-filter: blur(18px) saturate(1.14);
  }
}

.of-slide--dark .glass-card {
  background: rgba(15,58,50,.82);
  color: #fffaf0;
  border-color: rgba(242,193,93,.32);
}
```

**Accessibility gate:** test every text color used inside `.glass-card` against the effective card background, not the ideal token alone.

## Priority 5 — Define three auto-animate moments only

### Moment A: Metric expands into proof

```html
<section data-auto-animate data-auto-animate-id="metric-proof">
  <article class="metric-card" data-id="operator-time">
    <p class="metric">8 hrs</p>
    <p class="label">weekly admin drag</p>
  </article>
</section>

<section data-auto-animate data-auto-animate-id="metric-proof">
  <article class="metric-card metric-card--hero" data-id="operator-time">
    <p class="metric">8 hrs</p>
    <p class="label">weekly admin drag</p>
    <ul>
      <li>Searching across channels</li>
      <li>Duplicating intake</li>
      <li>Waiting for approvals</li>
    </ul>
  </article>
</section>
```

### Moment B: Journey resolves into operating rhythm

Use the same `data-id` on path nodes across slides (`intake`, `decision`, `handoff`, `proof`) and change from scattered positions to aligned flow.

### Moment C: Brand complexity becomes one platform

Keep brand cards in the same DOM order. Auto-animate from separate cards into a single grouped glass panel labeled “One operating rhythm.”

### Reveal config

```js
Reveal.initialize({
  hash: true,
  controls: true,
  progress: true,
  autoAnimateEasing: 'cubic-bezier(.22, 1, .36, 1)',
  autoAnimateDuration: 0.62,
  autoAnimateUnmatched: false
});
```

## Priority 6 — WCAG 2.2 AA checklist for the deck

- **Motion:** honor `prefers-reduced-motion`; no autoplaying motion over 5 seconds without pause/stop/hide; no flashing over 3 times/sec; avoid parallax and large unexpected movement.
- **Contrast:** 4.5:1 for normal text; 3:1 for large text; 3:1 for meaningful icons, graph lines, card boundaries, focus indicators, and controls.
- **Focus:** visible focus for all links/buttons; fixed rails/footers must not fully obscure focus; focus order follows the slide reading order.
- **Target size:** interactive targets at least 24×24 CSS px, with adequate spacing. Prefer 44×44 where touch use is possible.
- **Keyboard:** all navigation/controls usable without a mouse; no keyboard trap in embedded demos.
- **Semantics:** use real headings/lists; alt text or text equivalents for meaningful diagrams; decorative textures marked hidden.
- **Color:** do not rely on color alone for phase/status; include text labels, icons, line patterns, or grouping.
- **Readable presentation:** limit slide text, keep important visuals large, and provide accessible materials/notes if the deck is shared.

## Priority 7 — QA before executive review

1. Run browser smoke review at 1600×900, 1440×900, and PDF export.
2. Toggle reduced motion at OS/browser level and verify auto-animate becomes non-disorienting.
3. Keyboard through all controls; confirm focus is visible and unobscured.
4. Use a contrast checker on glass-card text over representative backgrounds.
5. Ask one reviewer to explain each slide after 5 seconds. If they cannot, reduce density before adding polish.