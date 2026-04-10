# Raw Findings: Luxury Brand Digital Presentation Design Patterns

## Core Principle: Luxury = Restraint + Intentionality

Luxury brands communicate through what they *don't* show as much as what they do. Every pixel must feel deliberate. The Delta Crown deck currently uses Material 3 card grids — functional but not differentiated. The following patterns move beyond generic card layouts toward editorial, cinematic experiences.

---

## Pattern 1: Full-Bleed Cinematic Sections

### What It Is
Hero imagery or color fields spanning the full viewport width (100vw) and often full height (100vh), with minimal overlaid text. Creates an immersive, theater-like experience.

### How Luxury Brands Use It
- **Chanel:** Product launches use full-screen video backgrounds with a single line of serif text
- **Hermès:** Their annual digital report uses full-bleed illustrated scenes that transition to content
- **Apple:** Product pages use full-bleed product shots against solid backgrounds with dramatic reveals on scroll
- **Prada:** Full-viewport editorial photography with type overlay

### Implementation for Delta Crown
```css
.slide--cinematic {
  width: 100vw;
  height: 100vh;
  position: relative;
  overflow: hidden;
  display: grid;
  place-items: center;
}

.slide--cinematic__bg {
  position: absolute;
  inset: 0;
  background: var(--dce-gradient-hero);
  /* OR: background-image with object-fit: cover */
}

.slide--cinematic__content {
  position: relative;
  z-index: 1;
  max-width: 800px;
  text-align: center;
}

.slide--cinematic__title {
  font-family: 'Playfair Display', serif;
  font-size: clamp(3rem, 5vw, 5rem);
  font-weight: 600;
  color: #FFFFFF;
  letter-spacing: -0.02em;
  line-height: 1.1;
}

.slide--cinematic__subtitle {
  font-family: 'Tenor Sans', sans-serif;
  font-size: clamp(0.875rem, 1.2vw, 1.125rem);
  color: var(--dce-royal-gold);
  letter-spacing: 0.15em;
  text-transform: uppercase;
  margin-top: 1.5rem;
}
```

### Best For
- Title slide (Slide 1)
- S.T.A.R. Moment slide (Slide 9/10)
- New Bliss / vision slide (Slide 12)
- Any slide where emotional impact > information density

---

## Pattern 2: Editorial Magazine Layout (Asymmetric Grid)

### What It Is
Inspired by print editorial design (Vogue, Monocle, Kinfolk). Uses asymmetric grid layouts with:
- Oversized typography as a visual element
- Pull quotes with dramatic sizing
- Mixed column widths (e.g., 2/3 + 1/3 splits)
- Generous whitespace (minimum 30% of slide area)
- Art-directed image placement (not centered — offset, cropped, bleeding off-edge)

### How Luxury Brands Use It
- **Bottega Veneta:** Minimal grid, huge product images with small text blocks
- **Aesop:** Product pages use a 2-column layout with one column being purely image/texture
- **The Row:** Extreme whitespace, single image + single text block
- **Louis Vuitton:** Editorial lookbooks with magazine-quality layouts online

### Implementation for Delta Crown
```css
.slide--editorial {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr 1fr 1fr;
  grid-template-rows: 1fr 1fr 1fr 1fr;
  gap: 0;
  height: 100vh;
  padding: 0;
}

/* Variant: 2/3 image + 1/3 text */
.slide--editorial-left .editorial__image {
  grid-column: 1 / 5;
  grid-row: 1 / -1;
}

.slide--editorial-left .editorial__content {
  grid-column: 5 / 7;
  grid-row: 1 / -1;
  padding: 4rem 3rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

/* Pull quote styling */
.editorial__pullquote {
  font-family: 'Playfair Display', serif;
  font-size: clamp(2rem, 3vw, 3.5rem);
  font-weight: 400;
  font-style: italic;
  color: var(--dce-deep-teal);
  line-height: 1.3;
  border-left: 2px solid var(--dce-royal-gold);
  padding-left: 2rem;
  margin: 2rem 0;
}

/* Oversize stat */
.editorial__stat {
  font-family: 'Playfair Display', serif;
  font-size: clamp(4rem, 8vw, 8rem);
  font-weight: 700;
  color: var(--dce-royal-gold);
  line-height: 0.9;
  letter-spacing: -0.03em;
}

.editorial__stat-label {
  font-family: 'Tenor Sans', sans-serif;
  font-size: 0.875rem;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: var(--color-text-secondary);
  margin-top: 0.5rem;
}
```

### Best For
- Market data slides (present one key stat HUGE, with supporting context small)
- Competitive analysis (editorial comparison rather than cramped table)
- Team/about slides

---

## Pattern 3: Progressive Disclosure (Layered Reveal)

### What It Is (per NN/g)
Initially show only the most important information. Reveal complexity on demand. In a slide deck context: animate or reveal supporting details when the presenter is ready, rather than showing everything at once.

### Key UX Principles (Nielsen Norman Group)
1. **The right split** — Primary content visible immediately; secondary on interaction
2. **Obvious progression** — Clear visual cue that more content exists
3. **Strong information scent** — Labels that set expectations for what's hidden
4. **Maximum 2 levels** — Beyond 2 disclosure levels, users get lost

### Implementation for Delta Crown
```css
/* Slide content that reveals progressively */
.reveal-group [data-reveal] {
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.6s ease, transform 0.6s ease;
}

.reveal-group [data-reveal].is-revealed {
  opacity: 1;
  transform: translateY(0);
}

/* Staggered reveal timing */
.reveal-group [data-reveal]:nth-child(1) { transition-delay: 0s; }
.reveal-group [data-reveal]:nth-child(2) { transition-delay: 0.15s; }
.reveal-group [data-reveal]:nth-child(3) { transition-delay: 0.3s; }
.reveal-group [data-reveal]:nth-child(4) { transition-delay: 0.45s; }

/* Reduced motion: instant reveal, no animation */
@media (prefers-reduced-motion: reduce) {
  .reveal-group [data-reveal] {
    opacity: 1;
    transform: none;
    transition: none;
  }
}
```

### Best For
- Data-heavy slides (metrics, financials) — reveal one insight at a time
- Architecture/technical slides — build up diagram progressively
- Risk analysis — show risks, then reveal mitigations

---

## Pattern 4: Scroll-Driven Storytelling (CSS Scroll Timeline)

### What It Is
Animations tied to scroll position rather than time. As the user navigates (scrolls or advances slides), visual elements animate in response. Creates a sense of cinematic progression.

### CSS API (MDN, March 2026)
```css
/* Named scroll timeline */
.presentation {
  scroll-timeline-name: --slide-progress;
  scroll-timeline-axis: inline; /* or block */
}

/* Animation linked to scroll */
.progress-indicator {
  animation: grow-bar linear;
  animation-timeline: --slide-progress;
}

@keyframes grow-bar {
  from { width: 0%; }
  to { width: 100%; }
}

/* View-based timeline (element entering viewport) */
.slide__content {
  animation: fade-in linear;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}

@keyframes fade-in {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}
```

### Browser Support
- Chrome 115+, Edge 115+: Full support
- Firefox: Behind flag (as of 2026)
- Safari: Partial support (WebKit tracking)
- **Recommendation:** Use as progressive enhancement with JS fallback

### Best For
- Progress bar tied to slide advancement
- Background color transitions between slides
- Parallax effects on slide backgrounds
- Data visualization reveals

---

## Pattern 5: Typography as Design Element

### What It Is
Using oversized, art-directed typography as the primary visual element rather than relying on images or illustrations. This is a hallmark of luxury editorial design.

### Techniques
1. **Giant numerals** — Display key stats at 6rem–10rem with hairline weight
2. **Split headlines** — Break a headline across the grid, with each word in different columns
3. **Layered type** — Large background text (opacity 0.05-0.1) with smaller foreground text
4. **Metric pairing** — Large number + small label (e.g., "47%" huge / "market growth" small)

### Implementation for Delta Crown
```css
/* Background watermark text */
.slide__watermark {
  position: absolute;
  font-family: 'Playfair Display', serif;
  font-size: clamp(10rem, 20vw, 25rem);
  font-weight: 700;
  color: var(--dce-deep-teal);
  opacity: 0.04;
  line-height: 0.85;
  pointer-events: none;
  user-select: none;
  z-index: 0;
}

/* Giant metric display */
.metric--hero {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.metric--hero__value {
  font-family: 'Playfair Display', serif;
  font-size: clamp(5rem, 10vw, 10rem);
  font-weight: 700;
  line-height: 0.9;
  color: var(--dce-royal-gold);
  letter-spacing: -0.04em;
}

.metric--hero__label {
  font-family: 'Tenor Sans', sans-serif;
  font-size: 1rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--color-text-secondary);
  margin-top: 1rem;
}

.metric--hero__context {
  font-family: 'Tenor Sans', sans-serif;
  font-size: 1.125rem;
  color: var(--color-text);
  max-width: 40ch;
  margin-top: 1.5rem;
  line-height: 1.6;
}
```

---

## Pattern 6: Transition Design Between Slides

### What It Is
How slides transition to each other communicates brand quality. Luxury brands use:
- **Crossfade** (not slide/swipe) — More cinematic, less app-like
- **Staggered exit/enter** — Content fades out before new content fades in (brief darkness)
- **Directional reveals** — Content slides in from consistent direction (left-to-right = forward)
- **Color transitions** — Background color morphs between slides

### Implementation for Delta Crown
```css
/* Crossfade transition (replaces current slideIn) */
.slide--exiting {
  animation: slide-exit 0.4s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

.slide--entering {
  animation: slide-enter 0.4s cubic-bezier(0.4, 0, 0.2, 1) 0.15s both;
}

@keyframes slide-exit {
  from { opacity: 1; }
  to { opacity: 0; }
}

@keyframes slide-enter {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Reduced motion: instant cut */
@media (prefers-reduced-motion: reduce) {
  .slide--exiting,
  .slide--entering {
    animation: none;
  }
  .slide--exiting { display: none; }
  .slide--entering { display: flex; opacity: 1; }
}
```

---

## Design Principles Summary: Luxury Web Presentation

| Principle | Description | Delta Crown Application |
|-----------|-------------|----------------------|
| **Restraint** | Less is more. One idea per slide. | Reduce current information density by ~40% |
| **Whitespace** | 30-50% of each slide should be empty space | Increase padding from 56px/64px to 80px/96px on key slides |
| **Typography hierarchy** | 3 sizes max per slide (title, body, caption) | Already using Playfair + Tenor Sans well — amplify size contrasts |
| **Color discipline** | 2-3 colors per slide maximum | Deep Teal + Royal Gold + one neutral — avoid Material 3 rainbow |
| **Quality signals** | Micro-interactions, smooth transitions, precise alignment | Upgrade transitions from slide-in to crossfade |
| **Negative space as luxury** | Empty space = confidence = premium | Let the brand palette do the talking |
| **Consistency** | Strict grid adherence, repetitive rhythms | Standardize slide templates to 3-4 variants |
