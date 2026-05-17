# Raw findings — WCAG 2.2 key criteria for this review

Source: W3C, Web Content Accessibility Guidelines (WCAG) 2.2, Recommendation 12 Dec 2024.  
URL: https://www.w3.org/TR/WCAG22/

Relevant extracted guidance:

- WCAG 2.2 is the current W3C Recommendation and W3C encourages use of the most current version when developing/updating policies.
- WCAG 2.2 new criteria include 2.4.11 Focus Not Obscured (Minimum) AA, 2.5.7 Dragging Movements AA, 2.5.8 Target Size (Minimum) AA.
- 1.4.3 Contrast (Minimum): normal text and images of text need 4.5:1; large-scale text needs 3:1; logotypes exempt.
- 1.4.10 Reflow: content can be presented without loss of information/functionality and without two-dimensional scrolling at 320 CSS px width or 256 CSS px height, except for content requiring two-dimensional layout.
- 1.4.11 Non-text Contrast: visual information required to identify UI components/states and graphical objects needs 3:1 against adjacent colors.
- 1.4.13 Content on Hover or Focus: additional content triggered by hover/focus must be dismissible, hoverable, and persistent.
- 2.1.1 Keyboard: all functionality operable through keyboard except path-dependent input.
- 2.1.2 No Keyboard Trap: focus can move away from a component using keyboard.
- 2.4.3 Focus Order: focus order preserves meaning and operability.
- 2.4.7 Focus Visible: keyboard-operable UI has visible focus indicator.
- 2.4.11 Focus Not Obscured (Minimum): when component receives keyboard focus, it is not entirely hidden by author-created content.
- 2.4.13 Focus Appearance is AAA but useful for quality: focus indicator area and 3:1 contrast requirements.
- 2.5.8 Target Size (Minimum): pointer target is at least 24×24 CSS px except spacing/equivalent/inline/user-agent/essential exceptions.
- Full-page conformance includes automatically presented screen-size variations in responsive pages.

DCE implication:

Review all responsive states, especially nav/drawer, sticky headers, focus order, target sizes, and brand color contrast. Gold on emerald is below normal text AA even though it passes large text threshold.