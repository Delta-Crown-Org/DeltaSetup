# Raw Findings: WCAG 2.2 Accessibility for HTML Slide Presentations

## Overview: Why This Matters

The Delta Crown presentation is an HTML/CSS/JS slide deck served via GitHub Pages — it IS a web page and MUST comply with WCAG. The presentation has 13 slides with keyboard navigation, glassmorphism effects, dark/light variants, and animation transitions. Each of these has specific accessibility implications.

---

## 1. Keyboard Navigation Requirements

### Relevant WCAG Criteria
- **2.1.1 Keyboard (Level A):** All functionality operable via keyboard without specific timings
- **2.1.2 No Keyboard Trap (Level A):** Focus can always be moved away from any component
- **2.1.4 Character Key Shortcuts (Level A):** Single-character shortcuts must be remappable or deactivatable

### Current State Analysis (from presentation.js)
The presentation currently uses:
- `←` / `→` arrow keys for navigation
- `Space` for next slide
- `F` for fullscreen
- `O` for overview
- `Esc` to exit modes

### Issues
1. **F, O, Esc are single-character shortcuts** → Must meet 2.1.4. Since `F` and `O` are NOT active only when a specific component has focus (they're document-level), they need either:
   - A mechanism to turn them off, OR
   - A mechanism to remap them
   - **Recommendation:** Make them only active when the presentation container has focus, OR use modifier keys (Ctrl+F, Ctrl+O)

2. **Space key hijacking** → If the user is focused on a button and presses Space, it should activate the button, NOT advance the slide. Current implementation may need to check `event.target`.

### WAI-ARIA Carousel Keyboard Pattern
Per W3C APG, carousel keyboard interaction requires:
- **Auto-rotation stops when ANY element receives keyboard focus** (must not restart unless user explicitly requests)
- **Tab / Shift+Tab** moves through interactive elements in normal tab sequence (no custom scripting needed for Tab)
- **Rotation control is FIRST in Tab sequence** inside the carousel (so screen reader users find it before the rotating content)
- **Activating next/prev/rotation controls does NOT move focus** (users can repetitively activate without losing position)

---

## 2. Screen Reader Announcements on Slide Change

### Relevant WCAG Criteria
- **4.1.3 Status Messages (Level AA):** Status messages must be programmatically determinable via role or properties without receiving focus
- **1.3.1 Info and Relationships (Level A):** Structure and relationships conveyed through presentation must be programmatically determinable

### WAI-ARIA Carousel Roles & Properties

#### Required on Each Slide
```html
<section
  role="group"
  aria-roledescription="slide"
  aria-label="Market Overview, 3 of 13"
>
  <!-- slide content -->
</section>
```
- `role="group"` — Identifies the slide as a group of related content
- `aria-roledescription="slide"` — Overrides the generic "group" announcement with "slide"
- `aria-label` — Provides the slide name. Since `aria-roledescription` says "slide", do NOT include "slide" in the label. Include position info: "Market Overview, 3 of 13"

#### Required on Carousel Container
```html
<div
  role="region"
  aria-roledescription="carousel"
  aria-label="Executive Presentation"
>
  <!-- all slides and controls -->
</div>
```
- `role="region"` or `role="group"` — Container is a landmark if warranted
- `aria-roledescription="carousel"` — Screen readers announce "carousel" instead of "region"
- `aria-label` — Name of the carousel (do NOT include "carousel" in the label)

#### Live Region for Slide Changes
```html
<div
  aria-atomic="false"
  aria-live="polite"
>
  <!-- visible slide(s) go here -->
</div>
```
- `aria-live="polite"` — Screen reader announces new slide content after current speech finishes
- `aria-live="off"` — Use when auto-rotating (to prevent constant interruptions)
- `aria-atomic="false"` — Only announce the changed content, not the entire region
- **Toggle between "polite" and "off"** based on whether auto-rotation is active

#### Rotation Control
```html
<button aria-label="Stop slide rotation">
  <!-- icon -->
</button>
```
- Label CHANGES based on state: "Stop slide rotation" ↔ "Start slide rotation"
- Do NOT use `aria-pressed` — the label change is sufficient and clearer

### Tabbed Variant (Alternative Pattern)
If using tabs as slide pickers:
```html
<div role="tablist" aria-label="Choose slide to display">
  <button role="tab" aria-selected="true" aria-controls="slide-1">Market Overview</button>
  <button role="tab" aria-selected="false" aria-controls="slide-2">Problem Statement</button>
  <!-- ... -->
</div>

<section role="tabpanel" id="slide-1" aria-labelledby="tab-1">
  <!-- slide content -->
</section>
```

---

## 3. Focus Management

### Relevant WCAG Criteria
- **2.4.3 Focus Order (Level A):** Focusable components receive focus in order that preserves meaning
- **2.4.7 Focus Visible (Level AA):** Keyboard focus indicator is visible
- **2.4.11 Focus Not Obscured — Minimum (Level AA, NEW in 2.2):** Focused component is not entirely hidden by author-created content
- **2.4.12 Focus Not Obscured — Enhanced (Level AAA, NEW in 2.2):** No PART of focused component is hidden
- **2.4.13 Focus Appearance (Level AAA, NEW in 2.2):** Focus indicator is at least as large as 2px perimeter, with 3:1 contrast between focused/unfocused states

### Implementation Requirements

#### Focus indicator on dark slides
```css
/* Two-color focus indicator (W3C technique C40) */
*:focus-visible {
  outline: 3px solid #FFFFFF;
  outline-offset: 2px;
  box-shadow: 0 0 0 6px rgba(0, 107, 94, 0.8);
}

/* Dark slide variant */
.md-slide--dark *:focus-visible {
  outline: 3px solid var(--dce-royal-gold);
  outline-offset: 2px;
  box-shadow: 0 0 0 6px rgba(255, 255, 255, 0.3);
}
```

#### Focus management on slide change
```javascript
// When navigating to a new slide:
goToSlide(index) {
  // 1. Hide current slide
  this.hideSlide(this.currentSlide);
  
  // 2. Show new slide
  this.showSlide(index);
  
  // 3. Move focus to the new slide container (for screen readers)
  const newSlide = this.elements.slides[index];
  newSlide.setAttribute('tabindex', '-1');
  newSlide.focus({ preventScroll: true });
  
  // 4. Update live region (if not auto-rotating)
  this.updateLiveRegion(index);
}
```

#### Sticky controls must not obscure focus (2.4.11)
```css
/* Ensure sticky nav controls don't cover focused elements */
.presentation-controls {
  position: fixed;
  bottom: 0;
  /* ... */
}

/* Add scroll-padding to account for sticky element */
.md-slide {
  scroll-padding-bottom: 60px; /* height of controls */
}
```

---

## 4. Reduced Motion Preferences

### Relevant WCAG Criteria
- **2.3.3 Animation from Interactions (Level AAA):** Motion animation triggered by interaction can be disabled
- **2.2.2 Pause, Stop, Hide (Level A):** Moving content can be paused/stopped
- **2.3.1 Three Flashes or Below Threshold (Level A):** No content flashes more than 3 times/second

### CSS Implementation
```css
@media (prefers-reduced-motion: reduce) {
  /* Disable all transitions */
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
  
  /* Specifically target slide transitions */
  .md-slide {
    animation: none !important;
  }
  
  /* Disable decorative animations */
  .md-slide--title::before {
    animation: none;
  }
  
  /* Replace motion with opacity changes */
  .reveal-group [data-reveal] {
    transform: none;
    /* Keep opacity transition but make it instant */
  }
}
```

### JavaScript Detection
```javascript
// Detect and respect user preference
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

if (prefersReducedMotion.matches) {
  this.transitionDuration = 0;
  // Disable auto-rotation
  this.stopAutoRotation();
}

// Listen for changes
prefersReducedMotion.addEventListener('change', (e) => {
  this.transitionDuration = e.matches ? 0 : 400;
});
```

### `prefers-reduced-motion` Details (MDN)
- **Values:** `no-preference` (no setting) | `reduce` (user wants less motion)
- **Browser support:** Baseline since January 2020 — ALL modern browsers
- **User settings by platform:**
  - macOS: System Settings > Accessibility > Display > Reduce motion
  - iOS: Settings > Accessibility > Motion
  - Windows 11: Settings > Accessibility > Visual Effects > Animation Effects
  - Android 9+: Settings > Accessibility > Remove animations

---

## 5. Contrast Requirements for Glassmorphism

### Relevant WCAG Criteria
- **1.4.3 Contrast Minimum (Level AA):** 4.5:1 for normal text, 3:1 for large text (18pt+ or 14pt+ bold)
- **1.4.6 Contrast Enhanced (Level AAA):** 7:1 for normal text, 4.5:1 for large text
- **1.4.11 Non-text Contrast (Level AA):** 3:1 for UI components and graphical objects

### The Glassmorphism Problem
The Delta Crown deck uses glassmorphism:
```css
background: var(--dce-glass-bg);           /* rgba(255,255,255,0.08) likely */
backdrop-filter: blur(var(--dce-glass-blur));
border: 1px solid var(--dce-glass-border); /* rgba(255,255,255,0.15) likely */
```

**The issue:** `backdrop-filter: blur()` means the background is DYNAMIC — it depends on what's behind the glass element. Text contrast over glassmorphism cannot be guaranteed because the background varies.

### Solutions
1. **Ensure minimum opacity on glass background:**
   ```css
   .md-card--elevated {
     /* Instead of rgba(255,255,255,0.08) — too transparent */
     background: rgba(10, 31, 28, 0.75); /* Dark with enough opacity to guarantee contrast */
     backdrop-filter: blur(20px);
   }
   ```

2. **Add a text shadow for extra contrast:**
   ```css
   .md-slide--dark .md-card--elevated p,
   .md-slide--dark .md-card--elevated li {
     text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
   }
   ```

3. **Test against worst-case background:**
   - Check contrast with the lightest possible background behind the glass
   - Check contrast with the darkest possible background behind the glass
   - If either fails 4.5:1, increase the glass opacity

### Specific Color Pairs to Verify

| Text Color | Background | Expected Ratio | Status |
|-----------|-----------|----------------|--------|
| `#FFFFFF` on `rgba(10,31,28,0.75)` over `#0A1F1C` | Dark slide | ~15:1 | ✅ Pass |
| `#FFFFFF` on `rgba(255,255,255,0.08)` over `#0A1F1C` | Dark glass | ⚠️ Varies | Must test |
| `rgba(255,255,255,0.8)` on glass | Dark glass labels | ⚠️ Varies | Must test |
| `var(--dce-royal-gold)` on `#0A1F1C` | Dark slide gold text | ~5.2:1 | ✅ Pass |
| `var(--dce-royal-gold)` on `#F5F5F3` | Light slide gold text | ~2.8:1 | ❌ FAIL — too low |

**Critical finding:** Royal Gold (#D4A84B) on light backgrounds (#F5F5F3) likely FAILS 4.5:1 contrast. Options:
- Darken the gold to #B8943F for text use on light backgrounds
- Use gold only for decorative elements on light slides, not body text
- Use the dark variant (#8A6F2F) for text specifically

---

## 6. aria-live Regions for Dynamic Content

### Relevant WCAG Criteria
- **4.1.3 Status Messages (Level AA):** Status messages can be presented to assistive technologies without receiving focus

### Implementation for Slide Counter
```html
<!-- Live region for slide position updates -->
<span
  class="slide-counter"
  id="slide-counter"
  role="status"
  aria-live="polite"
  aria-atomic="true"
>
  Slide 1 of 13
</span>
```
- `role="status"` implies `aria-live="polite"` — screen reader announces changes without interrupting
- `aria-atomic="true"` — Announce the entire text, not just the changed part

### Implementation for Slide Content
```html
<!-- Wrapper around slides — toggles between polite and off -->
<div
  id="slide-live-region"
  aria-live="polite"
  aria-atomic="false"
>
  <section role="group" aria-roledescription="slide" aria-label="Market Overview, 3 of 13">
    <!-- current slide content -->
  </section>
</div>
```

```javascript
// Toggle aria-live based on interaction
goToSlide(index) {
  const liveRegion = document.getElementById('slide-live-region');
  
  // If auto-rotating, suppress announcements
  if (this.isAutoRotating) {
    liveRegion.setAttribute('aria-live', 'off');
  } else {
    liveRegion.setAttribute('aria-live', 'polite');
  }
  
  // Update visible slide
  this.showSlide(index);
}
```

---

## 7. New WCAG 2.2 Criteria Relevant to This Project

### 2.4.11 Focus Not Obscured (Minimum) — Level AA
When a UI component receives keyboard focus, it is not ENTIRELY hidden by author-created content.
- **Impact:** The sticky presentation controls at the bottom could obscure focused elements
- **Fix:** Use `scroll-padding-bottom` and ensure focus management accounts for control bar height

### 2.4.13 Focus Appearance — Level AAA
Focus indicator must be at least 2px thick perimeter with 3:1 contrast between focused/unfocused states.
- **Impact:** Default browser focus rings may not meet this on dark slides
- **Fix:** Custom two-color focus ring (see Section 3 above)

### 2.5.8 Target Size (Minimum) — Level AA
Pointer targets must be at least 24×24 CSS pixels (with spacing exceptions).
- **Impact:** Small navigation dots, close buttons, or control buttons
- **Fix:** Ensure all interactive elements are minimum 24×24px, or have sufficient spacing

### 3.2.6 Consistent Help — Level A
Help mechanisms must appear in same relative position across pages.
- **Impact:** If keyboard shortcut help is shown, it should always be accessible from the same place
- **Fix:** Add a consistent "?" button in the control bar

### 3.3.8 Accessible Authentication (Minimum) — Level AA
Not directly applicable (no auth), but relevant if the presentation ever requires login.

---

## 8. Complete ARIA Markup Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Delta Crown Extensions - Executive Business Presentation</title>
</head>
<body>

<!-- Skip link -->
<a href="#slide-content" class="skip-link">Skip to presentation content</a>

<!-- Presentation container -->
<main
  role="region"
  aria-roledescription="carousel"
  aria-label="Executive Business Presentation"
  id="presentation"
>
  <!-- Rotation / playback control (FIRST in tab order) -->
  <button
    id="rotation-control"
    aria-label="Start automatic slide advancement"
    class="control-btn"
  >
    ▶
  </button>

  <!-- Slide live region -->
  <div aria-live="polite" aria-atomic="false" id="slide-viewport">

    <!-- Slide 1 -->
    <section
      role="group"
      aria-roledescription="slide"
      aria-label="Delta Crown Extensions, 1 of 13"
      class="md-slide md-slide--title"
      id="slide-1"
      tabindex="-1"
    >
      <h1>Delta Crown Extensions</h1>
      <p class="md-slide__subtitle">Elevating the Standard in Luxury Hair</p>
    </section>

    <!-- Slide 2 (hidden) -->
    <section
      role="group"
      aria-roledescription="slide"
      aria-label="Market Overview, 2 of 13"
      class="md-slide"
      id="slide-2"
      hidden
      tabindex="-1"
    >
      <!-- content -->
    </section>

  </div>

  <!-- Navigation controls -->
  <nav aria-label="Slide controls" class="presentation-controls">
    <button aria-label="Previous slide" id="prev-btn">←</button>
    <span role="status" aria-live="polite" aria-atomic="true" id="slide-counter">
      Slide 1 of 13
    </span>
    <button aria-label="Next slide" id="next-btn">→</button>
  </nav>

</main>

</body>
</html>
```
