# Prioritized Recommendations: Delta Crown Presentation Redesign

## Project Context
- **Product:** Delta Crown Extensions Executive Business Presentation
- **Stack:** HTML/CSS/JS on GitHub Pages
- **Design system:** Material 3 + custom luxury tokens (Deep Teal #006B5E, Royal Gold #D4A84B)
- **Typography:** Playfair Display (headings) + Tenor Sans (body)
- **Current state:** 13 slides with keyboard nav, dark/light variants, glassmorphism, card grids

---

## Implementation Phases

### Phase 1: Accessibility Foundation (Priority: CRITICAL)
**Estimated effort: 12–16 hours**  
**Rationale:** Accessibility is a legal requirement and foundational — all design changes must be accessible from day one.

#### 1.1 Add ARIA Carousel Pattern to HTML
```
Files to modify: presentation/index.html
```
- Add `role="region"` + `aria-roledescription="carousel"` + `aria-label` to the presentation container
- Add `role="group"` + `aria-roledescription="slide"` + `aria-label="[Title], N of 13"` to every slide
- Wrap visible slide area in `aria-live="polite"` region
- Add `role="status"` to the slide counter
- Add a skip link: `<a href="#slide-content" class="skip-link">Skip to presentation</a>`

#### 1.2 Fix Keyboard Shortcuts
```
Files to modify: presentation/js/presentation.js
```
- Gate `F` and `O` shortcuts to only fire when presentation container has focus, OR change to `Ctrl+F` / `Ctrl+O`
- Prevent `Space` from advancing slides when a button is focused (check `event.target`)
- Ensure rotation control (play/pause) is first in tab order within the presentation

#### 1.3 Add `prefers-reduced-motion` Support
```
Files to modify: presentation/css/design-system.css, presentation/js/presentation.js
```
CSS:
```css
@media (prefers-reduced-motion: reduce) {
  .md-slide {
    animation: none !important;
  }
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```
JS: Detect `prefers-reduced-motion` and set `transitionDuration = 0`

#### 1.4 Fix Focus Indicators
```
Files to modify: presentation/index.html (inline styles or design-system.css)
```
- Add two-color focus ring visible on both dark and light slides
- Use `:focus-visible` (not `:focus`) to avoid showing focus ring on mouse clicks

#### 1.5 Audit Glassmorphism Contrast
```
Files to modify: presentation/css/design-system.css, presentation/index.html
```
- Test all text-over-glass combinations with WebAIM contrast checker
- Increase glass background opacity if any combination fails 4.5:1
- **Critical:** Verify Royal Gold (#D4A84B) text passes on light backgrounds — likely needs darkening to #B8943F for text

---

### Phase 2: Narrative Restructuring (Priority: HIGH)
**Estimated effort: 8–12 hours**  
**Rationale:** Content structure drives all visual decisions. Must be settled before design changes.

#### 2.1 Audit Current Slides Against SCR Framework
Map each of the 13 existing slides to the recommended structure:

| Slide | Current Content (estimated) | Recommended Role | Framework |
|-------|---------------------------|-----------------|-----------|
| 1 | Title | **Title** — Brand identity | — |
| 2 | Company overview? | **Situation** — Market context + size | SCR: S |
| 3 | Problem/opportunity? | **Complication** — Market gap / unmet need | SCR: C |
| 4 | Vision? | **Sparkline: What Could Be** — The ideal state | Sparkline |
| 5 | Solution? | **Resolution** — Delta Crown's answer | SCR: R |
| 6 | Competition? | **Sparkline: What Is** — Current competitive reality | Sparkline |
| 7 | Differentiation? | **Sparkline: What Could Be** — DCE advantages | Sparkline |
| 8 | Metrics/data? | **Proof Points** — Supporting evidence (Pyramid detail) | Minto |
| 9 | More data? | **S.T.A.R. Moment** — One unforgettable visualization | Duarte |
| 10 | Risk? | **Risk → Mitigation** — What Is → What Could Be | Sparkline |
| 11 | Architecture? | **Execution Plan** — How/when/who (Pyramid detail) | Minto |
| 12 | Future? | **New Bliss** — Transformed future vision | Duarte |
| 13 | Close? | **Call to Action** — Specific asks with timeline | SCR: R+ |

#### 2.2 Rewrite Slide Titles
Titles should follow the narrative arc:
- **Bad:** "Market Overview" (descriptive, passive)
- **Good:** "A $6.2B Market Growing at 12% CAGR" (narrative, specific, S.T.A.R.)
- **Bad:** "Our Solution"
- **Good:** "The Missing Link in Premium Hair Extensions" (positions audience as hero)

#### 2.3 Add Contrast Points
Identify the "what is" / "what could be" transitions and mark them visually:
- "What Is" slides: Use dark backgrounds (existing `md-slide--dark`)
- "What Could Be" slides: Use light backgrounds with gold accents
- The alternation creates the Sparkline rhythm

#### 2.4 Design the S.T.A.R. Moment
This is the single most important slide. Options:
- A dramatic data visualization (e.g., animated revenue projection)
- A before/after visual comparison
- A live demo or video embed
- A shocking statistic displayed at 8rem+ font size

---

### Phase 3: Visual Upgrade — Luxury Design Patterns (Priority: MEDIUM)
**Estimated effort: 20–30 hours**  
**Rationale:** Visual polish amplifies the narrative. Do AFTER narrative structure is locked.

#### 3.1 Create 4 Slide Variant Classes
```
Files to create/modify: presentation/css/design-system.css or new slide-variants.css
```

| Variant | Used For | Slides |
|---------|---------|--------|
| `.slide--cinematic` | Full-bleed hero moments | 1, 9, 12 |
| `.slide--editorial` | Data + narrative with editorial layout | 2, 3, 8 |
| `.slide--standard` | Card-based content (existing pattern) | 5, 6, 7, 10, 11 |
| `.slide--minimal` | Maximum whitespace, single message | 4, 13 |

#### 3.2 Implement Cinematic Slides
- 100vw × 100vh with gradient/image background
- Centered content with 800px max-width
- Playfair Display at 5rem+ for titles
- Royal Gold uppercase subtitle with 0.15em letter-spacing
- Reduce padding to 0 (content is centered, not offset)

#### 3.3 Implement Editorial Slides
- 6-column CSS Grid with asymmetric content placement
- Pull quotes in Playfair Display italic at 2–3rem
- Giant metrics (5–10rem) with small labels
- 30-50% whitespace per slide
- Text columns limited to 40ch max-width

#### 3.4 Upgrade Transitions
- Replace `slideIn` animation with crossfade (opacity only)
- Add 150ms stagger between exit and enter
- Respect `prefers-reduced-motion` (instant cut)

#### 3.5 Add Progressive Disclosure
- `[data-reveal]` attribute on elements that should animate in
- Staggered reveal with 150ms delays
- Triggered by keyboard shortcut or click (presenter controls when content appears)
- Fully respect reduced motion preference

---

### Phase 4: Polish & Testing (Priority: STANDARD)
**Estimated effort: 8–12 hours**

#### 4.1 Screen Reader Testing
- Test with VoiceOver (macOS) — the likely primary screen reader for the audience
- Verify: slide changes are announced, counter updates are read, navigation is intuitive
- Test the full keyboard-only flow from Slide 1 to Slide 13

#### 4.2 Contrast Audit
- Run every slide through axe DevTools or Lighthouse
- Manually verify glassmorphism text with WebAIM contrast checker
- Document all color pairs and their contrast ratios

#### 4.3 Performance Testing
- Test on a standard laptop (not just high-end dev machine)
- Verify glassmorphism doesn't cause jank on integrated graphics
- Check total page weight (currently 320KB — target: under 500KB with images)

#### 4.4 Print Styles
- Ensure `@media print` disables all glassmorphism, shows all slides, uses solid backgrounds
- Add page breaks between slides
- Verify text is legible in grayscale (for B&W printing)

---

## Success Metrics

| Metric | Current | Target | How to Measure |
|--------|---------|--------|----------------|
| WCAG 2.2 AA compliance | Unknown (likely partial) | 100% AA | axe DevTools + manual testing |
| Lighthouse Accessibility score | Unknown | 95+ | Chrome DevTools |
| Keyboard-navigable | Partial | 100% | Manual testing |
| `prefers-reduced-motion` support | None | Full | OS setting + visual verification |
| Screen reader usability | None | Full carousel pattern | VoiceOver testing |
| Information density per slide | High | 40% reduction | Visual audit |
| Whitespace ratio | ~20% | 35–50% | Visual audit |
| Narrative arc clarity | Linear report | SCR + Sparkline hybrid | Peer review |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Over-designing slides reduces clarity | Medium | High | "One idea per slide" rule; design review gate |
| Glassmorphism contrast failures | High | High | Increase glass opacity; test every combination |
| CSS `scroll-timeline` not supported in Safari | High | Low | Use as progressive enhancement only |
| Narrative restructuring changes meaning | Medium | Medium | Stakeholder review before implementation |
| Accessibility regressions on future updates | Medium | High | Add axe-core to CI; document ARIA patterns |
| Large image files slow GitHub Pages load | Medium | Medium | Use WebP, lazy-loading, target <500KB total |

---

## Recommended Implementation Order

```
Week 1:  Phase 1 (Accessibility) + Phase 2.1–2.2 (Narrative audit + titles)
Week 2:  Phase 2.3–2.4 (Contrast points + S.T.A.R. moment) + Phase 3.1 (Variant classes)
Week 3:  Phase 3.2–3.5 (Visual patterns + transitions + disclosure)
Week 4:  Phase 4 (Testing, audit, polish)
```

Total estimated effort: **48–70 hours** across all phases.
