# Raw findings — WCAG 2.2 relevance

Source: W3C WCAG 2.2 Recommendation, 12 Dec 2024, https://www.w3.org/TR/WCAG22/

Relevant findings for DeltaSetup landing redesign:

- WCAG 2.2 is current W3C recommendation and extends WCAG 2.1; W3C encourages using current version to maximize future applicability.
- 1.4.3 Contrast Minimum: normal text 4.5:1; large text 3:1.
- 1.4.11 Non-text Contrast: UI component/state visuals and graphical objects need 3:1 against adjacent colors.
- 1.4.10 Reflow: content must reflow at 320 CSS px width without two-dimensional scrolling except specific exceptions.
- 2.4.7 Focus Visible: keyboard focus indicator must be visible.
- 2.4.11 Focus Not Obscured Minimum: focused component must not be entirely hidden by author-created content.
- 2.4.13 Focus Appearance AAA: when author-styled, focus indicator area should be at least a 2px perimeter equivalent and 3:1 contrast. Even though AAA, this is a strong practical design target.
- 2.5.8 Target Size Minimum: pointer targets at least 24×24 CSS px or valid spacing/equivalent exception.
- 3.2.6 Consistent Help: repeated help/contact mechanisms should appear in consistent order.
- 4.1.2 Name, Role, Value: custom controls must expose programmatic name/role/state; native HTML controls are safer.

Implication: For static HTML/CSS, prefer native semantics and make contrast/focus/target sizes token-level design constraints.