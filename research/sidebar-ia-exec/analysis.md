# Detailed Analysis — Three Questions

## Q1. Chapter-style left rail for non-technical exec readers

**Verdict: Effective and on-pattern. Keep it. No 2024–2026 consensus shift away from this.**

- NN/g's June 2024 menu-design checklist explicitly states the **expected location for local navigation on desktop websites is the left-hand side**, and that on larger screens navigation should be visible (not collapsed under a hamburger). Hiding nav reduces "information scent" — exactly what scan-first execs need. [NN/g 2024]
- Same source (#5, #7, #8): always indicate current location, use clear/specific/familiar wording, and **left-justify with front-loaded key terms** for fast scanning. Your active-section highlight on scroll satisfies #5.
- **Grouping count (5 ± 2):** No fresh dedicated study contradicts the long-standing Miller/chunking heuristic. NN/g's broader IA guidance treats "small number of meaningful chunks" as best practice; 5 chapters of 3–4 links (≤7 per group) sits comfortably in the safe zone.
- **Inline TOC vs sticky section headers vs accordion** — these are *alternatives for different content shapes*, not a newer/better default:
  - **Inline TOC** suits a single long-form article (one page = one document). Your microsite is multi-section + multi-page → left rail wins.
  - **Sticky section headers** (e.g., iOS contacts list) work for *list browsing*, not for jumping between chapters of a narrative.
  - **Collapsible accordions** add interaction cost and hide scent; NN/g's #1 ("show navigation on larger screens") argues against them when you have 288px of stable real estate. Accordion is a mobile/overflow strategy.
- **Label tone — gerund vs noun** ("How It Works" vs "Architecture"):
  - For non-technical exec audiences, **plain-language gerund/verb-phrase labels generally outperform domain-noun labels** (NN/g #7: "Menus are not the place to get cute with made-up words, internal jargon, or abstract high-level categorization. Stick to terminology that clearly describes your content.").
  - GOV.UK content-design principle (well-established, applied across UK gov services): use the words the audience uses, not internal/organizational labels. "How It Works" reads like a user task; "Architecture" reads like an IT artefact.
  - Recommendation: keep gerund/plain-language labels for execs; reserve nominal/technical labels (e.g., "Architecture") for the Ops View where the audience shifts to engineers.

## Q2. View switcher pattern (Project Site ↔ Ops View) — a11y

**Verdict: `role="tab"` on cross-page anchor links is incorrect. Use `<nav>` + `aria-current="page"`.**

- **W3C ARIA APG — Tabs Pattern** (authoritative): a tab "serves as a label for one of the **tab panels**" and is "contained within the element with role tablist." Each `tab` has **`aria-controls` referring to its associated `tabpanel`**. The whole pattern presupposes same-page panel switching with preloaded/controllable content. Cross-page anchor links have no `tabpanel` to control, so the contract is broken. [W3C ARIA APG, Tabs]
- **MDN, `aria-current`** is explicit about this boundary:
  > "When something is **selected** rather than **current**, such as a tab in a tablist, use `aria-selected` to indicate the currently-displayed tabpanel."
  > "Don't use `aria-current` as a substitute for `aria-selected` in gridcell, option, row or **tab**."
  Conversely: `aria-current="page"` is **defined precisely for "the link to the current document"** in a set of pages (its canonical example is breadcrumbs/pagination, but it applies to any nav-link set across pages). [MDN, aria-current]
- **Correct pattern for this layout:**
  ```html
  <nav aria-label="View">
    <ul>
      <li><a href="/index.html" aria-current="page">Project Site</a></li>
      <li><a href="/operations.html">Ops View</a></li>
    </ul>
  </nav>
  ```
  Style it as a "segmented control" if desired — semantics are independent of visual treatment. The "current view" treatment in CSS can hook off `[aria-current="page"]`.
- **Don't use:** `role="tablist"`, `role="tab"`, `aria-selected`, `aria-controls` here. They mislead screen-reader users (who'll expect arrow-key navigation with auto-activating panel switches and an in-page `tabpanel`).
- **Disclosure pattern** (button that expands a region) is also wrong — it implies hide/show same-page content.
- **Segmented control** is a *visual* paradigm; HIG/Material treat the underlying control as either a radio group (for filters) or links (for views). For routing between two pages → links + `aria-current="page"`.

## Q3. WCAG 2.2 considerations specific to this layout

### (a) Smooth scroll JS and `prefers-reduced-motion`

- **SC 2.3.3 Animation from Interactions (AAA)** requires that motion animation triggered by interaction can be disabled, with **technique SCR40: "Using the CSS prefers-reduced-motion query in JavaScript to prevent motion."** [W3C Understanding 2.3.3]
- The user's CSS already respects the preference, but `scrollIntoView({behavior:'smooth'})` in JS **does not inherit CSS `scroll-behavior`** — it's a JS argument, evaluated at call time. Browsers do not auto-clamp it on `prefers-reduced-motion`.
- **Required fix** (idiomatic):
  ```js
  const prefersReduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  el.scrollIntoView({ behavior: prefersReduce ? 'auto' : 'smooth', block: 'start' });
  ```
  Or strip `behavior` entirely and let `html { scroll-behavior: smooth; }` (already in CSS, presumably wrapped in the reduced-motion media query) handle it via `el.scrollIntoView()` without options — that path *does* honor CSS.
- This is also a defensive measure against **SC 2.2.2 Pause, Stop, Hide** complaints if the smooth scroll is long-running, though for typical single-jump scrolls 2.3.3 is the directly-relevant criterion.

### (b) Floating mobile menu button (top:14px, z-index:1100) — SC 2.4.11 Focus Not Obscured (Minimum, AA)

- **SC 2.4.11 (AA, new in WCAG 2.2):** "When a user interface component receives keyboard focus, the component is not entirely hidden due to author-created content." [W3C Understanding 2.4.11]
- **Failure F110** is explicitly: "due to a sticky footer or header completely hiding focused elements." Your fixed top-positioned button is the same class of risk.
- **Risk profile here:**
  - The button itself is small (likely ~44×44 area), so it's unlikely to *fully* cover most targets. **Partial obscuring is allowed at AA** ("at least partially visible"). AAA (2.4.12) requires fully unobscured.
  - **Real risk:** if the page later grows a sticky header *containing* the menu button, OR if the sidebar collapses on mobile leaving the button alone over content — a tab-stop scrolled to the very top of its scroll container could land under the button.
- **Sufficient technique: C43 — Using CSS `scroll-padding` to un-obscure content.** Apply:
  ```css
  html { scroll-padding-top: calc(14px + 44px + 8px); /* button top + height + buffer */ }
  ```
  This guarantees that anchor jumps and `scrollIntoView` calls leave clearance below any fixed top-positioned UI.
- Also relevant to call out (cheap wins):
  - **SC 2.5.8 Target Size (Minimum, AA, new in 2.2):** all interactive controls ≥ 24×24 CSS px (or use the spacing exception). Sidebar links and the menu button must comply. [W3C Understanding 2.5.8]
  - **SC 2.4.7 Focus Visible** (existing, AA): if `scrollIntoView` runs *before* focus is moved to the target, the focus indicator can briefly land off-screen. Move focus first, then scroll (or use `el.focus({preventScroll:true})` then animate).
  - **SC 2.4.13 Focus Appearance** (AAA, new in 2.2): only worth checking if you're aiming for AAA on the focus ring contrast/area.

### (c) `<aside aria-label="Site navigation">` wrapping `<nav>` — landmark double-up

- **Two issues, one is a real defect:**
- **Defect — role/label mismatch.** Per W3C ARIA APG Landmarks:
  - `<aside>` exposes the **`complementary`** landmark: "a supporting section of the document, designed to be **complementary to the main content**, ... remains meaningful when separated from the main content."
  - `<nav>` exposes the **`navigation`** landmark.
  - Site navigation is **not** complementary content — it *is* navigation. Putting `aria-label="Site navigation"` on the `aside` produces, in a screen-reader landmark list, an entry like "Site navigation, complementary" — semantically contradictory and surfaces in landmark-jump menus as a misleading region.
- **Defect — redundant nesting.** APG: "complementary landmarks should be top level landmarks (e.g. not contained within any other landmarks)." Putting a `nav` landmark *inside* a `complementary` landmark inverts that and clutters the landmark list with two entries for the same UI region.
- **Fix (preferred):**
  ```html
  <nav class="sidebar" aria-label="Primary">
    <!-- chapters and links -->
  </nav>
  ```
  Drop the `<aside>` wrapper. Move any visual layout concerns to a class on the `<nav>` itself.
- **Fix (if the wrapper element must stay for layout):**
  ```html
  <div class="sidebar">
    <nav aria-label="Primary"> ... </nav>
  </div>
  ```
  A plain `<div>` has no implicit role; no landmark double-up.
- **Label text:** prefer `aria-label="Primary"` (or `"Main"`) over `"Site navigation"` — screen readers append the role automatically ("Primary, navigation"). Including the word "navigation" in the label causes "navigation, navigation" duplication. [W3C ARIA APG Landmarks, Step 3 — naming landmarks]

### Quick reference: WCAG 2.2 SCs most relevant to this layout

| SC | Level | Status in 2.2 | Relevant because |
|---|---|---|---|
| 2.3.3 Animation from Interactions | AAA | existing | smooth-scroll JS must respect prefers-reduced-motion (SCR40) |
| 2.4.7 Focus Visible | AA | existing | smooth scroll can desync focus indicator |
| **2.4.11 Focus Not Obscured (Min)** | **AA** | **new in 2.2** | floating menu button + fixed sidebar (use C43 scroll-padding) |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | new in 2.2 | only if targeting AAA |
| 2.4.13 Focus Appearance | AAA | new in 2.2 | only if targeting AAA |
| **2.5.8 Target Size (Min)** | **AA** | **new in 2.2** | sidebar link rows + menu button ≥ 24×24 CSS px |
