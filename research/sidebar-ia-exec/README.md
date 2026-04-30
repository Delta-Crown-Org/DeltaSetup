# Sidebar IA + View Switcher + WCAG 2.2 — Targeted Research

**Scope:** Three narrow questions for a UX/IA review of a static GitHub Pages microsite (288px dark left rail, chapter groupings, two-page view switcher, scroll-progress bar). Recent (2024–2026) primary sources only. Researched 2025.

**TL;DR**
1. **Sidebar IA** — Chapter-style left rail with ~5 grouped sections of 3–4 links is **on-pattern** for desktop "documentation/microsite" reading and aligns with NN/g 2024 menu guidance. Inline TOCs and accordions are alternatives, not replacements; for short scan-first content with a known IA they add interaction cost. Keep current structure; tighten labels.
2. **View switcher** — `role="tab"` + `aria-selected` on cross-page anchors **is incorrect** per W3C ARIA APG (tabs control same-page `tabpanel`s via `aria-controls`). Correct pattern: a labeled `<nav>` of two links with `aria-current="page"` on the active view (segmented-control styling is fine; the semantics are nav links, not tabs).
3. **WCAG 2.2** — Three concrete risks in this layout:
   - JS `scrollIntoView({behavior:'smooth'})` must check `prefers-reduced-motion` (CSS already does; JS must too — SC 2.3.3 + SCR40).
   - Floating mobile menu button (top:14px, z-index:1100) risks **SC 2.4.11 Focus Not Obscured (AA)** if it ever fully covers the focused element; mitigate with `scroll-padding-top` (technique C43).
   - `<aside aria-label="Site navigation">` wrapping `<nav>` creates a **redundant landmark + role/label mismatch** (`aside` exposes as "complementary," not navigation). Drop the `aside` wrapper or change it to a non-landmark element; put the label on the `<nav>`.

See `analysis.md` for the detailed bullet-point answers with citations, `sources.md` for source credibility, and `recommendations.md` for prioritized action items.
