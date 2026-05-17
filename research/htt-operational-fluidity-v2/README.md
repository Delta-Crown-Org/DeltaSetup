# HTT Operational Fluidity v2 — Premium Reveal.js Deck Patterns

**Date:** 2026-05-17  
**Research agent:** web-puppy-104933  
**Project context:** Executive/operator Reveal.js deck for brand operators, extending the existing HTT operational-fluidity research. The repo already uses HTML/CSS presentation systems with warm cream, deep green/teal, gold accents, logo rails, cards, journey diagrams, and Reveal.js-oriented accessibility concerns.

## Executive summary

The current premium web-deck pattern is **quiet luxury + disciplined product UI**: fewer objects, tighter type, a visible spacing rhythm, restrained translucent surfaces, and animation used to clarify a state change rather than entertain. For an executive deck, the most implementable upgrade is not more decoration; it is a tokenized CSS layer that makes every slide feel composed: consistent insets, type scale, optical tracking, card depth, and predictable Reveal.js auto-animate transitions.

## Fast prescriptions

1. **Tighten typography optically, not globally.** Use negative tracking only on large headlines; keep body copy at normal or slightly open tracking. Turn on kerning and contextual ligatures.
2. **Adopt a slide grid.** Reserve header/footer safe zones and place content on a 12-column or named-area grid. Use one rhythm scale (`8/12/16/24/32/48/64/96`) instead of ad hoc margins.
3. **Use “glass” as a hierarchy layer, not a theme.** Glass cards should be translucent, blurred, and backed by a solid fallback. Never place low-contrast body text directly on complex imagery or blur-only backgrounds.
4. **Use morphism sparingly.** Soft elevation and inset borders can make cards premium; avoid low-contrast neumorphic controls because they often fail non-text contrast and focus visibility.
5. **Auto-animate only semantic continuity.** Good moments: one metric card expands into evidence; a journey path resolves into three operating principles; a before/after stack aligns. Bad moments: unrelated objects sliding, bouncing, or reordering for flourish.
6. **WCAG 2.2 AA guardrails are non-negotiable.** Text contrast 4.5:1, large text 3:1, important graphics/UI states 3:1, visible focus, 24×24 minimum pointer targets, keyboard operation, no color-only meaning, reduced-motion support.

## Recommended CSS token starter

```css
:root {
  --slide-w: 1600px;
  --slide-h: 900px;
  --safe-x: clamp(56px, 6vw, 104px);
  --safe-top: 72px;
  --safe-bottom: 64px;

  --space-1: 8px;
  --space-2: 12px;
  --space-3: 16px;
  --space-4: 24px;
  --space-5: 32px;
  --space-6: 48px;
  --space-7: 64px;
  --space-8: 96px;

  --ink: #13231f;
  --muted: #54615c;
  --cream: #f7f2e8;
  --green: #0f3a32;
  --gold: #c89b3c;
  --glass-bg: color-mix(in srgb, #fff 72%, transparent);
  --glass-border: color-mix(in srgb, #fff 58%, #c89b3c 20%);

  --ease-premium: cubic-bezier(.22, 1, .36, 1);
  --duration-step: 520ms;
}

.reveal .slides section {
  padding: var(--safe-top) var(--safe-x) var(--safe-bottom);
  color: var(--ink);
  background: radial-gradient(circle at 15% 10%, rgba(200,155,60,.12), transparent 30%), var(--cream);
}

.slide-grid {
  min-height: calc(900px - var(--safe-top) - var(--safe-bottom));
  display: grid;
  grid-template-columns: repeat(12, minmax(0, 1fr));
  gap: var(--space-5);
  align-items: center;
}

.deck-kicker {
  font: 700 13px/1.1 var(--font-sans, system-ui);
  letter-spacing: .14em;
  text-transform: uppercase;
  color: var(--gold);
}

.deck-title {
  max-width: 11ch;
  font: 650 clamp(58px, 6.4vw, 96px)/.92 var(--font-display, Georgia, serif);
  letter-spacing: -.045em;
  font-kerning: normal;
  text-wrap: balance;
}

.deck-lede {
  max-width: 52ch;
  font: 450 clamp(22px, 2vw, 30px)/1.32 var(--font-sans, system-ui);
  letter-spacing: -.01em;
  color: var(--muted);
}

.glass-card {
  background: rgba(255,255,255,.78);
  border: 1px solid rgba(200,155,60,.24);
  box-shadow: 0 24px 80px rgba(15,58,50,.14), inset 0 1px 0 rgba(255,255,255,.75);
  border-radius: 28px;
  padding: var(--space-5);
}

@supports (backdrop-filter: blur(16px)) {
  .glass-card {
    background: var(--glass-bg);
    backdrop-filter: blur(18px) saturate(1.16);
    -webkit-backdrop-filter: blur(18px) saturate(1.16);
  }
}

.reveal :focus-visible {
  outline: 3px solid #f2c15d;
  outline-offset: 4px;
  border-radius: 10px;
}

.reveal a, .reveal button, .reveal [role="button"] {
  min-width: 24px;
  min-height: 24px;
}

@media (prefers-reduced-motion: reduce) {
  .reveal .slides section *,
  .reveal .slides section *::before,
  .reveal .slides section *::after {
    animation: none !important;
    transition-duration: .01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## Bottom line

Ship v2 as a **controlled premium system**: high-contrast cream/green/gold surfaces, large tight headlines, generous rhythm, translucent cards with fallback opacity, and three or four tasteful auto-animate moments that make the operating model easier to understand.