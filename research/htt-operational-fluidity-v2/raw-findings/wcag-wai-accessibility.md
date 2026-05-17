# Raw findings — WCAG 2.2 and WAI presentation accessibility

Sources:
- https://www.w3.org/TR/WCAG22/
- https://www.w3.org/WAI/teach-advocate/accessible-presentations/

Accessed: 2026-05-17

## WCAG 2.2 deck-relevant requirements

- **1.4.3 Contrast Minimum (AA):** normal text/images of text require 4.5:1 contrast; large-scale text requires 3:1.
- **1.4.11 Non-text Contrast (AA):** visual information required to identify UI components/states and meaningful graphics requires 3:1 contrast against adjacent colors.
- **1.4.12 Text Spacing (AA):** no loss of content/functionality when users override line height to 1.5, paragraph spacing to 2× font size, letter spacing to .12× font size, and word spacing to .16× font size.
- **2.1.1 Keyboard (A):** all functionality operable through keyboard.
- **2.2.2 Pause, Stop, Hide (A):** moving/blinking/scrolling content that starts automatically, lasts more than 5 seconds, and appears alongside other content must be pausable/stoppable/hidable unless essential.
- **2.3.1 Three Flashes or Below Threshold (A):** no content flashing more than three times in one second or exceeding thresholds.
- **2.4.7 Focus Visible (AA):** keyboard focus indicator must be visible.
- **2.4.11 Focus Not Obscured Minimum (AA):** focused component cannot be entirely hidden by author-created content.
- **2.5.7 Dragging Movements (AA):** functionality using dragging must have a non-drag single-pointer alternative unless essential.
- **2.5.8 Target Size Minimum (AA):** pointer targets at least 24×24 CSS px except for listed exceptions.

## WAI presentation guidance

- Start with an overview and end with a review of important points.
- Use consistent slide design to limit cognitive load.
- Limit text on each slide because reading and listening simultaneously is difficult.
- Make text and important visuals big enough to read from the back of the room.
- Use easy-to-read fonts; thin/fancy fonts are harder from distance.
- Use sufficient contrast between text/background and graph colors.
- Consider whether motion/animation makes information easier to understand or is unnecessary.
- Avoid distracting motion and blinking/flashing that could cause seizures.
- Describe relevant visual information verbally.
- Provide accessible material ahead of time when possible.

## Deck implications

WCAG 2.2 AA applies to the HTML deck as web content. The v2 premium treatment must be tested as a full web page, including keyboard controls, focus, motion preferences, and PDF/export variants if distributed.