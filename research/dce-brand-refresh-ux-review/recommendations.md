# Project-Specific Recommendations

## Priority 1 — Review blockers / must-check before approval

1. **Confirm every responsive nav/drawer path by keyboard.**
   - Open with keyboard.
   - Focus moves to drawer title/first meaningful item.
   - Tab/Shift+Tab do not leave a modal drawer.
   - Escape and close button close it.
   - Focus returns to opener.
   - `aria-expanded` updates.
   - No focused control is fully hidden behind sticky/overlay content.

2. **Resolve gold contrast roles.**
   - Do not use `#D8A562` as normal-size text on white/ivory or emerald.
   - Do not use gold-only borders/icons to identify UI controls on light backgrounds.
   - Use gold for accent lines, large display text on emerald, or text/focus accents on almost-black/dark emerald.

3. **Make focus robust across all surfaces.**
   - Gold focus rings are fine on dark surfaces but weak on light surfaces.
   - Prefer a tokenized two-layer focus style, for example dark outer ring + light/gold inner offset, or context-specific `--color-focus-ring` tokens.
   - Validate focus on skip links, nav, buttons, cards, sidebars, accordions, presentation controls, and drawer close buttons.

4. **Target size check for mobile and presentation controls.**
   - Minimum AA: 24×24 CSS px targets or valid exception.
   - Recommended DCE quality target: 44×44 CSS px for mobile nav open/close, primary CTAs, slide/presentation controls, and icon-only actions.

5. **Do not treat axe/static audit as conformance.**
   - Use automated gates to catch regressions.
   - Record manual review outcomes for keyboard/focus/drawer/contrast decisions.

## Priority 2 — Token governance actions

1. **Establish one canonical DCE brand token source.**
   - Root current tokens already include `--dce-emerald`, `--dce-gold`, and `--dce-almost-black`.
   - Align `presentation/css/styles.css` and `dce-mockup/css/tokens.css` with refreshed values or document why they remain legacy.

2. **Use semantic tokens for roles.**
   Suggested minimal map:

   ```css
   :root {
     --color-brand-emerald: #03534D;
     --color-brand-gold: #D8A562;
     --color-brand-black: #231F20;
     --color-surface-page: #FAFAF7;
     --color-surface-dark: #231F20;
     --color-text-default: #231F20;
     --color-text-on-dark: #FAFAF7;
     --color-link: #03534D;
     --color-accent-decorative: #D8A562;
     --color-focus-ring-on-dark: #D8A562;
     --color-focus-ring-on-light: #03534D;
   }
   ```

3. **Document approved/forbidden color combinations.**
   - Approved: emerald on ivory/white; almost black on ivory/white; gold on almost black; ivory/white on emerald or almost black.
   - Conditional: gold on emerald for large text/decorative only.
   - Forbidden for meaningful UI/text: gold on ivory/white; emerald on almost black; gold-only thin borders on light backgrounds.

4. **Add a raw-hex review rule.**
   - Raw hex is allowed in token files and SVG/logo assets.
   - Component CSS/HTML should consume tokens.
   - For practical enforcement, use grep during review:
     `grep -R "#[0-9A-Fa-f]\{6\}" css presentation dce-mockup --exclude='tokens.css'` and assess intentional exceptions.

## Priority 3 — Review documentation / evidence

1. **Use a concise manual review table per page/deck section.**

   | Area | Viewport | Check | Pass/Fail | Notes |
   |---|---|---|---|---|
   | Header nav | 390px | Drawer focus trap/return/Escape |  |  |
   | Header nav | 1440px | Focus visible and not obscured |  |  |
   | Hero | all | Text contrast over image/overlay |  |  |
   | Cards/CTAs | 390px | 24×24 target min / 44×44 preferred |  |  |
   | Presentation controls | all | Keyboard operation and focus |  |  |

2. **Record automated vs manual scope separately.**
   - Automated: static audit, browser smoke, axe audit.
   - Manual: focus order, drawer modal behavior, target measurements, text-on-image contrast, semantic token use.

3. **Avoid conformance claims unless scoped.**
   - If producing a client-facing claim, include date, WCAG version/level, page/deck scope, technologies relied on, user agents/AT used, and known exceptions.
   - For internal review, phrase as “WCAG 2.2 AA-oriented review” unless full WCAG-EM-style evaluation is completed.

## Quick DCE review checklist

- [ ] Page/deck uses refreshed brand colors via tokens.
- [ ] No raw hex in components except documented exceptions.
- [ ] Gold is not body text on light or emerald surfaces.
- [ ] Text and UI states meet contrast in default, hover, active, focus, disabled where meaningful.
- [ ] Skip link appears and is usable.
- [ ] All controls reachable and operable by keyboard.
- [ ] Focus visible and not fully obscured.
- [ ] Mobile drawer open/close/focus behavior works.
- [ ] Pointer targets meet 24×24 minimum; primary mobile controls aim for 44×44.
- [ ] Automated gates pass, with manual limitations documented.