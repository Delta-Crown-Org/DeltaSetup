# Multi-Dimensional Analysis

## 1. Typography tightening

### Pattern
Premium executive decks increasingly use **large, controlled display typography**: narrow line lengths, slight negative tracking, careful kerning, and high contrast between headline, lede, and metadata. The goal is editorial confidence, not decorative type.

### Implementable rules
- Apply `font-kerning: normal; text-rendering: optimizeLegibility;` on deck text.
- Use negative `letter-spacing` only for display sizes (`-.025em` to `-.055em`).
- Keep body text between `1.2–1.45` line-height; avoid compressed body copy.
- For eyebrow/kicker labels, use uppercase with moderate tracking (`.10em–.16em`), not extreme `.25em+` tracking that reduces readability.
- Limit titles to `8–12ch` where possible; use `text-wrap: balance` for headings.

### Accessibility cautions
- WCAG text spacing means content must not break when users override spacing to 1.5 line height, 2× paragraph spacing, `.12em` letter spacing, and `.16em` word spacing.
- Avoid thin serif text on glass or gradient backgrounds; anti-aliasing can make nominally passing contrast feel weak.
- Images of text should be avoided except logos.

## 2. Spacing/layout rhythm

### Pattern
Premium decks feel expensive because they are **quietly aligned**. Use a stable safe-area inset, a grid, and repeatable spacing tokens. Avoid one-off absolute positioning unless it serves a specific diagram.

### Implementable rules
- Reserve header/footer zones: e.g. `72px` top and `64px` bottom in a 1600×900 deck.
- Use a 12-column grid for mixed editorial/card slides; named grid areas for repeat slide templates.
- Use a spacing scale: `8, 12, 16, 24, 32, 48, 64, 96`.
- Apply density budgets: one headline + one lede + one diagram or 3–5 cards.
- Align diagrams to the same grid as text so connectors feel intentional.

### Accessibility cautions
- DOM reading order must match visual reading order; CSS Grid can visually rearrange items in ways that harm screen-reader/keyboard comprehension.
- Fixed overlays/footers must not obscure focused controls (WCAG 2.4.11 AA).
- Responsive/PDF export variants need separate review because WCAG conformance applies to full page variations.

## 3. Glassmorphism / morphism

### Pattern
The current high-end version of glassmorphism is **subtle frosted layering**: translucent off-white panels, thin warm borders, deep soft shadows, and blur over calm gradients or image washes. It should support hierarchy and brand warmth, not become a noisy effect.

### Implementable rules
- Always provide a solid/semi-solid fallback background before `@supports (backdrop-filter)`.
- Use blur around `14–22px`, saturation `1.08–1.18`, and opacity high enough for contrast (`rgba(255,255,255,.74–.88)` on light cards; `rgba(15,58,50,.70–.86)` on dark cards).
- Add a 1px border and inner highlight to define the card edge.
- Avoid blur-only separation; include border/shadow/solid tint.
- Use neumorphic/morphic inset treatments only for non-critical decorative containers, not buttons or controls.

### Accessibility cautions
- Validate actual foreground/background color pairs after blur and overlays; transparent designs can fail contrast depending on what sits behind them.
- Important card outlines, icons, connectors, and focus states need 3:1 non-text contrast.
- Do not rely on color alone for state; pair color with label, shape, icon, or line style.

## 4. Tasteful auto-animate moments

### Pattern
For executive decks, motion should create **semantic continuity**. Use auto-animate to show that one idea becomes the next: a metric expands into evidence, a journey collapses into principles, or a before/after map aligns around an operating model.

### Implementable rules
- Use `data-id` for every object that should morph predictably.
- Set deck-level defaults near `autoAnimateDuration: 0.55–0.8`, `autoAnimateEasing: 'cubic-bezier(.22, 1, .36, 1)'`, and `autoAnimateUnmatched: false`.
- Use `data-auto-animate-id` to isolate sequences; use `data-auto-animate-restart` between unrelated moments.
- Animate position, scale, opacity, and card expansion; avoid spinning, bouncing, flashing, parallax, or unrelated reordering.
- Keep each moment under ~800ms and avoid chained delays that make the presenter wait.

### Accessibility cautions
- Respect `prefers-reduced-motion`; provide near-instant transitions and no transform movement for reduced-motion users.
- Avoid motion that starts automatically and runs over 5 seconds without pause/stop/hide.
- Avoid flashing more than three times per second.
- Keyboard navigation should not trigger disorienting context changes without user request.

## 5. Security

Minimal direct security implications. Avoid loading remote fonts/scripts during executive presentations if offline reliability or privacy is important. Prefer vendored Reveal.js/assets or stable CDNs with integrity where feasible.

## 6. Cost

Low. All recommendations are CSS/HTML-level and compatible with static deployment. The only cost is design QA time: contrast checks, reduced-motion testing, keyboard review, and PDF/export review if distributed.

## 7. Implementation complexity

Low to medium. Typography, grid, and glass-card tokens are straightforward. Auto-animate requires careful slide pairing and `data-id` discipline; complexity rises if many elements move across many slides.

## 8. Stability and compatibility

- CSS Grid and `font-kerning` are widely stable.
- `backdrop-filter` is now Baseline 2024 in latest browsers but should still have fallback for older systems and PDF export inconsistencies.
- Reveal.js auto-animate is mature, but matching can surprise authors unless `data-id` is used.

## 9. Optimization/performance

- Use glass blur sparingly; too many blurred layers can hurt performance.
- Avoid animating layout-heavy properties where manual CSS is used; prefer transform/opacity. Reveal.js internally uses transforms for auto-animate movement.
- Compress background images and avoid huge translucent overlays over high-frequency photography.

## 10. Compatibility with this project

The existing project already uses warm brand colors, editorial headings, status chips, cards, and accessibility patterns such as skip links/focus styles/reduced-motion CSS. The v2 deck should add a dedicated presentation token layer rather than changing global site CSS. Keep recommendations scoped to the Reveal deck path when implemented.

## 11. Maintenance

Create a small deck CSS contract:
- `tokens.css`: color/type/space/motion variables.
- `layouts.css`: grid templates and safe zones.
- `components.css`: glass cards, metric cards, journey nodes, footers.
- `motion.css`: auto-animate helper classes and reduced-motion overrides.

This prevents visual drift across slides and makes future executive decks easier to produce.