# Recommendations — Prioritized for the DeltaSetup Microsite

Ordered by severity × ease. Citations refer to `sources.md`.

## P0 — Fix before next exec review (correctness defects)

### 1. Replace any `role="tab"` / `aria-selected` on the view switcher with nav semantics
**Why:** Misuses ARIA Tabs Pattern, which contractually requires same-page `tabpanel` + `aria-controls`. Misleads screen-reader users (W3C ARIA APG; MDN aria-current).
**Change:**
```html
<nav aria-label="View">
  <ul role="list">
    <li><a href="./index.html"     aria-current="page">Project Site</a></li>
    <li><a href="./operations.html">Ops View</a></li>
  </ul>
</nav>
```
On `operations.html`, swap which link carries `aria-current="page"`. Style with `[aria-current="page"]` selector — keep the segmented-control look if desired.

### 2. Fix the `<aside aria-label="Site navigation"><nav>...</nav></aside>` landmark stack
**Why:** `<aside>` exposes role `complementary`, not navigation; nesting `nav` inside `complementary` violates APG ("complementary should be top-level") and the label "Site navigation" creates a role/label semantic mismatch.
**Preferred change:** drop the `<aside>` wrapper; promote the `<nav>` and label it directly:
```html
<nav class="sidebar" aria-label="Primary"> ... </nav>
```
**If `<aside>` must stay for layout/styling:** change to `<div class="sidebar">` and keep `<nav aria-label="Primary">` inside.
**Bonus:** drop the word "navigation" from the label — screen readers already announce the role; "Primary" or "Main" reads better.

### 3. Make `scrollIntoView` respect `prefers-reduced-motion` in JS
**Why:** WCAG 2.2 SC 2.3.3 + technique SCR40. CSS `@media (prefers-reduced-motion)` does not propagate into the `behavior:'smooth'` JS argument.
**Change:**
```js
const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
target.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
```
Or call `target.scrollIntoView()` with no options and let CSS `scroll-behavior` (already wrapped in your reduced-motion media query) decide.

## P1 — Should fix this iteration (WCAG 2.2 AA exposure)

### 4. Add `scroll-padding-top` to mitigate SC 2.4.11 Focus Not Obscured
**Why:** Floating mobile menu button at `top:14px, z-index:1100` could fully cover a focused element near the top of a scrolled-to section. Sufficient technique C43.
**Change (CSS):**
```css
html { scroll-padding-top: 72px; } /* tune to button bottom + small buffer */
```
Combine with item #3 (the `block:'start'` jumps will respect padding).

### 5. Audit target sizes for SC 2.5.8 (24×24 CSS px minimum)
**Why:** New AA criterion in WCAG 2.2. Easy to miss on tightly-spaced sidebar link rows or chapter-group headers.
**Action:** Quick measure pass — sidebar link hit-areas, the floating menu button, the view-switcher controls, and any inline links in the body. If any are <24×24, either pad them, or rely on the spacing exception (24px diameter circle from the bounding box must not intersect another target).

### 6. Move focus before/independently of smooth scroll
**Why:** Touches SC 2.4.7 Focus Visible. If JS scrolls *then* focuses, users on slow machines can see focus ring travel; if it focuses *then* the browser auto-scrolls, you can fight the smooth animation.
**Change:** `target.focus({ preventScroll: true });` followed by your animated scroll.

## P2 — IA polish (no defect; copy/structure tuning)

### 7. Keep the 5-chapter / 3–4 link structure; tighten labels
**Why:** Aligns with NN/g 2024 menu guidance and Miller-style chunking. No 2024–2026 source argues for switching to inline TOC or accordion for this content shape.
**Suggestions:**
- Keep gerund/plain-language labels for the **Project Site** view (exec audience): "Start Here," "The Vision," "How It Works," "Where We Are," "What's Next" — these test well against NN/g #7 (familiar, non-jargon) and GOV.UK plain-language principle.
- For the **Ops View**, you may switch to noun/technical labels (e.g., "Architecture," "Runbooks," "SLOs") because the audience shifts to engineers — different audience, different vocabulary is the right call, not an inconsistency.
- Within each chapter group: front-load the most distinguishing word in each link label (NN/g #8). E.g., "Deployment runbook" beats "How to deploy."

### 8. Confirm the active-section highlight uses `aria-current="location"` (not just CSS)
**Why:** Sighted users get the visual cue; screen-reader users should get a programmatic equivalent. Per MDN, `aria-current="location"` is defined for "the current location within an environment or context" — an excellent fit for "current chapter section while scrolling within a page."
**Change (in your scroll-spy JS):** when a section becomes active, set `aria-current="location"` on its sidebar link and remove from the others. (Use `"page"` only on the across-pages view switcher — don't double-up.)

## P3 — Optional / AAA / nice-to-have

- SC 2.4.12 Focus Not Obscured (Enhanced, AAA): reach this only if you want zero overlap; the scroll-padding fix for P1 #4 will likely satisfy it for free.
- SC 2.4.13 Focus Appearance (AAA): verify focus ring meets the 2px / 3:1 contrast / area thresholds.
- Consider a "Skip to main content" link if not present — pre-2.2 SC 2.4.1 Bypass Blocks; trivial add given the dense sidebar.

---

## Cross-reference to project files
- `index.html` (82.5 KB) — apply #1, #2, #7
- `operations.html` (23.7 KB) — apply #1, #2 (mirror)
- `js/` (whichever file owns scroll-spy + smooth scroll) — apply #3, #6, #8
- `css/` (existing reduced-motion media query) — apply #4 (`scroll-padding-top`)
