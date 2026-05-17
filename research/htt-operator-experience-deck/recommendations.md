# Project-Specific Recommendations

## Priority 1 — Shape the deck as an operator experience narrative

### Recommended storyline

Use this sentence as the deck’s controlling idea:

> “HTT can give every operator a clearer operating day by replacing scattered signals with a single, brand-aware rhythm for finding, deciding, and acting.”

### Slide title rules

Every visible slide title should be a complete assertion:

- Bad: “Current State”
- Better: “Operators lose momentum when context is scattered.”
- Bad: “SharePoint Hub”
- Better: “One operating start point reduces daily guesswork.”
- Bad: “Permissions”
- Better: “Brand-sensitive work stays visible to the right people.”

### Keep technical terms out of the main deck

Use operator language:

| Technical term | Operator-facing translation |
|---|---|
| SharePoint hub | Operating home base |
| Permissions model | Right people / right context |
| Migration | Moving current work into a cleaner operating rhythm |
| Dynamic groups | Role-aware access |
| Hub-and-spoke | HTT family backbone with brand-specific spaces |
| Information architecture | How operators find the right thing quickly |

## Priority 2 — Build a reusable Reveal.js slide system

### Base HTML pattern

```html
<section class="op-slide op-slide--impact" aria-labelledby="slide-03-title">
  <p class="op-kicker">Experience impact</p>
  <h2 id="slide-03-title">Fragmentation costs operators confidence before it costs minutes.</h2>

  <div class="op-evidence-grid" role="list" aria-label="Three ways fragmentation affects operators">
    <article class="op-impact-card" role="listitem">
      <h3>Lost time</h3>
      <p>Operators search across channels before acting.</p>
    </article>
    <article class="op-impact-card" role="listitem">
      <h3>Missed context</h3>
      <p>Updates arrive without a clear owner or next step.</p>
    </article>
    <article class="op-impact-card" role="listitem">
      <h3>Uneven execution</h3>
      <p>Brand standards depend on who knows where to look.</p>
    </article>
  </div>

  <aside class="notes">
    Speak to daily operator behavior: opening the day, routing questions, confirming brand guidance.
  </aside>
</section>
```

### Base CSS starter

```css
:root {
  --op-bg: var(--dce-ivory, #FAFAF7);
  --op-ink: var(--dce-almost-black, #231F20);
  --op-emerald: var(--dce-emerald, #03534D);
  --op-gold: var(--dce-gold, #D8A562);
  --op-muted: #465463;
  --op-card: #FFFFFF;
  --op-radius: 24px;
  --op-safe-x: clamp(56px, 7vw, 96px);
  --op-safe-y: clamp(44px, 6vh, 72px);
}

.reveal .slides section.op-slide {
  box-sizing: border-box;
  width: 100%;
  height: 100%;
  padding: var(--op-safe-y) var(--op-safe-x);
  display: grid;
  grid-template-rows: auto auto 1fr auto;
  gap: clamp(18px, 2.5vh, 32px);
  text-align: left;
  color: var(--op-ink);
  background: var(--op-bg);
}

.op-kicker {
  margin: 0;
  color: var(--op-emerald);
  font-size: 0.9rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.op-slide h2 {
  margin: 0;
  max-width: 12ch;
  font-family: var(--font-heading, Georgia, serif);
  font-size: clamp(2.4rem, 5vw, 5rem);
  line-height: 1.04;
  text-wrap: balance;
}

.op-evidence-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 24px;
  align-self: end;
}

.op-impact-card {
  padding: 28px;
  border: 1px solid color-mix(in srgb, var(--op-emerald) 18%, transparent);
  border-radius: var(--op-radius);
  background: var(--op-card);
}

.op-impact-card h3 {
  margin: 0 0 10px;
  font-size: clamp(1.35rem, 2vw, 2rem);
}

.op-impact-card p {
  margin: 0;
  color: var(--op-muted);
  font-size: clamp(1.05rem, 1.35vw, 1.35rem);
  line-height: 1.45;
}

@media (prefers-reduced-motion: reduce) {
  .reveal *, .reveal *::before, .reveal *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## Priority 3 — Use experience-map visuals carefully

### Recommended map design for slide 7

Do not show a full workshop-style journey map. Show a **presentation-grade slice**:

- 5 phases maximum.
- One operator quote or question per phase.
- One emotion/confidence line.
- 2–3 highlighted “moments that break momentum.”
- One future-state intervention below the highlighted moments.

Example phases:

1. Open day
2. Check updates
3. Route request
4. Confirm standard
5. Close loop

Use labels like “confidence dips here” instead of vague red zones.

## Priority 4 — Accessibility checklist for the deck

Before presenting or publishing:

- [ ] Each slide has a unique `h2` title and `aria-labelledby`.
- [ ] DOM reading order matches visual order.
- [ ] All meaningful images/SVGs have alt text or adjacent text descriptions.
- [ ] Decorative images use empty alt or are CSS backgrounds with no meaning.
- [ ] Text contrast meets WCAG AA; aim for AAA on body text where possible.
- [ ] Non-text graphics and focus indicators meet 3:1 contrast.
- [ ] Color is never the only signal for status, emotion, phase, or ownership.
- [ ] Keyboard navigation and focus visibility are tested.
- [ ] Motion is disabled under `prefers-reduced-motion`.
- [ ] Video/audio, if any, has captions and a transcript.
- [ ] Speaker verbally describes important visual changes and maps.
- [ ] A linear accessible handout is available.

## Priority 5 — Concrete visual guidance

### Use

- Premium whitespace.
- Large assertion titles.
- One photo or one diagram per slide.
- Operator quotes/questions as evidence.
- Before/after flows with clear labels.
- Gold as a thin rule, highlight, or key marker.
- Emerald for structural emphasis and section moments.

### Avoid

- Tiny UI screenshots.
- Multi-level architecture diagrams.
- Dense bullet lists.
- Overlaid body text on photography.
- Red/yellow/green without labels.
- Fast auto-advance or excessive fragments.
- Speaker notes that contain claims unsupported by the slide.

## Suggested final deliverables

1. `operator-experience-deck.html` — Reveal.js deck.
2. `operator-experience-deck.css` — slide system using DCE/HTT tokens.
3. `operator-experience-handout.html` — linear accessible leave-behind.
4. `operator-experience-deck.pdf` — export for stakeholders who require PDF, checked for readability.
5. `speaker-notes.md` — 12-minute talk track with visual descriptions.
