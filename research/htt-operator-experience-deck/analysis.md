# Multi-Dimensional Analysis

## 1. Audience and narrative lens

### Operator reality
Franchise/brand operators are not evaluating architecture; they are evaluating whether the operating day becomes clearer, faster, and safer. The deck should answer:

- Where do I start my day?
- What do I no longer have to chase?
- What becomes more consistent across locations and brands?
- How does this protect brand standards without slowing me down?
- What is expected of me next?

### Experience-mapping implication
NN/g defines journey maps as visualizations of a person accomplishing a goal, built from actor, scenario, phases, actions/mindsets/emotions, and opportunities. For HTT, use an **operator experience map**, not a technical roadmap.

Recommended operator scenario:

> “A brand/location operator needs to open the day, find the right updates, answer a request, and keep brand execution consistent without hunting across channels.”

Journey phases suitable for the deck:

1. Start the day
2. Find the right context
3. Decide what matters
4. Act / route work
5. Close the loop
6. Learn / improve next time

## 2. Security lens

This deck should not expose tenant architecture, permission internals, group names, scripts, or operational vulnerabilities. Security should be framed as operator confidence:

- “The right people see the right operating context.”
- “Brand-sensitive material is easier to keep in its lane.”
- “Operators do not have to guess whether a source is current.”

Accessibility-related security/privacy considerations:

- Avoid live production screenshots with names, emails, request content, or permissions.
- If using screenshots, anonymize and enlarge only the relevant UI area.
- Provide an accessible handout without exposing sensitive implementation detail.

## 3. Cost lens

The deck’s cost story should emphasize reduced friction, not license tables:

- Lower operator time spent searching and confirming.
- Fewer repeated explanations from central teams.
- Faster onboarding to brand standards.
- Less rework from outdated or inconsistent guidance.

Avoid hidden-cost pitfalls:

- Overpromising automation that operators do not experience immediately.
- Showing polished mockups without naming the first proof point.
- Designing a deck so visually custom that future updates require specialist work.

## 4. Implementation complexity lens

### HTML/Reveal.js complexity
Reveal.js is suitable if treated as a controlled slide surface, not a miniature app.

Recommended settings:

```js
Reveal.initialize({
  width: 1280,
  height: 720,
  margin: 0.06,
  center: false,
  hash: true,
  slideNumber: 'c/t',
  transition: 'fade',
  backgroundTransition: 'fade'
});
```

Recommended slide skeleton:

```html
<section class="op-slide op-slide--journey" aria-labelledby="slide-07-title">
  <p class="op-kicker">Operator journey</p>
  <h2 id="slide-07-title">Momentum breaks at handoffs, not at tools.</h2>

  <figure class="journey-map" aria-describedby="slide-07-desc">
    <!-- semantic HTML/SVG map here -->
  </figure>

  <p id="slide-07-desc" class="visually-hidden">
    The journey shows the lowest-confidence moments during request routing and status follow-up.
    The proposed experience adds one start point and visible ownership to reduce uncertainty.
  </p>
</section>
```

Use native HTML/SVG with text equivalents instead of rasterized diagrams.

## 5. Stability lens

- Reveal.js official docs emphasize authored dimensions and uniform scaling. Build for predictable 16:9 and test at projector, laptop, and mobile widths.
- Keep custom CSS tokenized and portable. The project already has tokens for DCE emerald/gold/ivory and reduced-motion utilities.
- Avoid fragile slide layouts that depend on `r-fit-text` for critical content; use it only for intentional hero words.

## 6. Optimization/performance lens

A 10-slide operator deck should load instantly and feel calm.

Recommendations:

- Compress photography; use `srcset` if the deck is hosted publicly.
- Avoid autoplay video and background audio.
- Use SVG for maps/icons; use CSS for visual effects.
- Keep animations under 300ms and disable through `prefers-reduced-motion`.
- Do not use heavy chart libraries for static narrative evidence.

## 7. Compatibility lens

Accessibility and compatibility priorities:

- DOM order must match reading order.
- Use one `h1` deck title and one `h2` per slide.
- Ensure keyboard navigation works and focus indicators remain visible.
- Provide a scroll/print/handout mode or accessible HTML companion.
- Ensure text remains legible when exported to PDF or viewed in browser zoom.

Reveal-specific caution:

- Slide decks are two-dimensional by nature. WCAG 1.4.10 recognizes presentations/diagrams can require two-dimensional layout, but provide an alternative linear handout for adaptability.

## 8. Maintenance lens

Create a small slide component system instead of unique one-off slide art.

Recommended components:

- `.op-slide` base
- `.op-kicker`
- `.op-assertion`
- `.op-evidence-grid`
- `.op-impact-card`
- `.op-journey-map`
- `.op-emotion-line`
- `.op-decision-box`
- `.op-speaker-note` / `<aside class="notes">`

Avoid inline styles. Keep values in CSS custom properties so the deck can be updated for other HTT family brands.

## 9. Accessibility lens

### Required practices
From W3C WAI, WCAG 2.2, and Microsoft deck guidance:

- Provide materials ahead of time in accessible formats; HTML is preferred over inaccessible-only PDF.
- Start with an overview and end with a review/decision.
- Use consistent slide design to limit cognitive load.
- Limit text per slide; do not make users read and listen to dense text simultaneously.
- Make text and visuals large enough for the back of the room.
- Use readable fonts; avoid thin/fancy fonts for body copy.
- Ensure sufficient contrast: WCAG AA 4.5:1 for normal text and 3:1 for large text; AAA target 7:1 where feasible.
- Do not use color alone to convey status or meaning.
- Describe relevant visual information in the talk track.
- Add alt text/text equivalents for visuals.
- Give every slide a unique descriptive title.
- Test with keyboard and a screen reader.
- Caption any video/audio and provide transcript/notes.

### HTT/DCE specific accessibility guidance

- Playfair Display can remain for large hero assertions, but use a simpler sans serif or the existing Tenor Sans only at sufficiently large sizes and weights. Avoid small, light Tenor Sans on dark backgrounds.
- Gold is best as accent, divider, icon fill, or large display text; avoid gold body text on ivory and small muted text on emerald.
- Use labels with status colors: “Current friction,” “Future relief,” “Operator confidence,” not color-only dots.

## 10. Visual-system guidance

### Brand tone
Premium, calm, operational, human. The deck should feel like a franchise operator briefing, not a technology sales pitch.

### Palette usage
- **Emerald/deep teal:** authority, navigation, section backgrounds.
- **Ivory:** primary reading surface.
- **Gold:** emphasis, progress accents, key linework; keep sparse.
- **Almost black:** body text on light surfaces.
- **Soft neutrals:** secondary surfaces and map lanes.

### Typography
- Large assertion title: `clamp(2.2rem, 4.5vw, 4.8rem)`.
- Body/evidence: minimum equivalent of 18pt; in browser terms generally `1.25rem+` for projected slides.
- Avoid all caps beyond short labels with generous letter spacing.
- Use `text-wrap: balance` for headlines; do not justify text.

### Layout
- Leave 8–10% safe margins.
- Use one dominant visual per slide.
- Limit each slide to 2–3 content zones.
- Use cards only when they represent distinct operator outcomes.
- Favor sequence diagrams, journey lanes, and before/after comparisons over dashboards.

## 11. Pitfall analysis

| Pitfall | Why it hurts operators | Better approach |
|---|---|---|
| Architecture-first deck | Forces audience to translate system mechanics into day-to-day value | Start with operator scenario and friction |
| Dense screenshots | Unreadable from room; often inaccessible | Rebuild relevant UI concept as simplified HTML/SVG |
| Too many metrics | Suggests monitoring rather than relief | Tie each metric to operator confidence/speed |
| Decorative luxury styling | Can reduce contrast/readability | Use premium restraint: whitespace, strong type, one accent |
| Color-only journey emotions | Excludes colorblind users | Pair color with labels, icons, line shapes |
| Over-animation | Distracts and can trigger vestibular discomfort | Use subtle fades and reduced-motion support |
| No leave-behind | Viewers lose details after 12 minutes | Provide accessible one-page HTML/PDF handout |
