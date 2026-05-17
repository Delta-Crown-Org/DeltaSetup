# Raw findings — WCAG 2.2 AA implications for HTML/CSS decks

Sources:

- https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- https://www.w3.org/WAI/WCAG22/Understanding/info-and-relationships.html

Credibility: Tier 1 — W3C WCAG Understanding documentation.

## Contrast minimum — SC 1.4.3 Level AA

- Text and images of text require at least 4.5:1 contrast.
- Large-scale text requires 3:1 contrast.
- Logotypes are exempt from text contrast requirements.
- Thin/unusual fonts can render fainter due to anti-aliasing; best practice is to use stronger strokes or exceed thresholds.
- Images of text do not scale/adapt as well as real text; use text wherever possible.

## Non-text contrast — SC 1.4.11 Level AA

- Meaningful graphical objects and UI component indicators require at least 3:1 contrast against adjacent colors.
- Applies to icons, chart lines, graph lines, diagram objects, state indicators, focus indicators, and meaningful boundaries.
- Not every decorative graphic must pass; the requirement applies to parts required to understand content.
- If equivalent visible text conveys the same information, some graphical objects may not be required for understanding.

## Use of color — SC 1.4.1 Level A

- Color cannot be the only visual means of conveying information, indicating action, prompting response, or distinguishing an element.
- Pair hue with text, icon, shape, pattern, position, or lightness/contrast.
- For diagrams, color may reinforce meaning but cannot be the sole cue.

## Info and relationships — SC 1.3.1 Level A

- Structure and relationships conveyed by visual presentation must be programmatically determined or available in text.
- Use semantic elements: headings, lists, tables for tabular data, captions, labels, landmarks, and text descriptions.
- If visual relationships cannot be encoded, provide a text description near the content.

## Deck-specific interpretation

- The HTML deck is web content; use WCAG AA as the baseline for the browser version.
- Reveal slides should retain semantic headings and readable document title.
- Diagrams need visible labels and/or text alternatives.
- PDF export requires separate accessibility review if distributed as the accessible artifact.
