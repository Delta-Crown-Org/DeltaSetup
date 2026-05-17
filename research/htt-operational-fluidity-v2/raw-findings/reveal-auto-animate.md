# Raw findings — Reveal.js Auto-Animate

Source: https://revealjs.com/auto-animate/  
Accessed: 2026-05-17

## Extracted findings

- Add `data-auto-animate` to two adjacent slide `<section>` elements and Reveal.js automatically animates matching elements between them.
- Reveal.js can animate changes in position, font-size, line-height, color, background-color, padding, and margin; movement uses CSS transforms internally for smoothness.
- Auto-animate can move elements into new positions as content is added, removed, or rearranged.
- Matching behavior:
  - Text matches when text content and node type are identical.
  - Images/videos/iframes match by `src`.
  - DOM order is considered.
  - `data-id` can explicitly match elements and is prioritized above automatic matching.
- Per-slide/per-element attributes include:
  - `data-auto-animate-easing`
  - `data-auto-animate-unmatched`
  - `data-auto-animate-duration`
  - `data-auto-animate-delay`
  - `data-auto-animate-id`
  - `data-auto-animate-restart`
- Deck-level configuration can set:

```js
Reveal.initialize({
  autoAnimateEasing: 'ease-out',
  autoAnimateDuration: 0.8,
  autoAnimateUnmatched: false,
});
```

## Deck implications

Use auto-animate for deliberate continuity only. Add stable `data-id` values to metrics, cards, nodes, and diagram elements that should morph. Use `data-auto-animate-restart` between unrelated sequences so Reveal does not accidentally infer continuity.