# Raw Findings — Accessibility for Slide Decks

Sources:
- W3C WAI Making Events Accessible Checklist: https://www.w3.org/WAI/teach-advocate/accessible-presentations/
- W3C WCAG 2.2 Quick Reference: https://www.w3.org/WAI/WCAG22/quickref/
- Microsoft Support PowerPoint Accessibility: https://support.microsoft.com/en-US/accessibility/powerpoint/make-your-powerpoint-presentations-accessible-to-people-with-disabilities

## W3C WAI presentation guidance

- Accessible sessions benefit people with disabilities and many more audiences, including people with different learning styles and people not fluent in the language.
- For cognitive accessibility: start with an overview, end with a review of the most important points, use consistent slide design, and use clear understandable content.
- Provide slides/handouts/materials ahead of time in accessible formats. HTML, word processing, and EPUB are adaptable formats; avoid providing only formats users cannot adapt.
- Limit text on slides because many people cannot read text and listen to the speaker at the same time.
- Make text and important visuals big enough to read from the back of the room.
- Use easy-to-read fonts; thin or fancy fonts are harder to read from a distance.
- Use sufficient luminance contrast between text/background and within graphics.
- Consider motion carefully; unnecessary motion distracts and can make some people ill. Avoid blinking/flashing that could cause seizures.
- During presentation, describe relevant visual information and speak clearly.

## WCAG 2.2 relevant criteria

- 1.1.1 Non-text Content: meaningful visuals need text alternatives; decorative visuals can be ignored by assistive technology.
- 1.3.1 Info and Relationships and 1.3.2 Meaningful Sequence: structure and reading order must be programmatically determinable.
- 1.4.1 Use of Color: color cannot be the only means of conveying information.
- 1.4.3 Contrast (Minimum): 4.5:1 normal text, 3:1 large text.
- 1.4.6 Contrast (Enhanced): 7:1 normal text, 4.5:1 large text for AAA target.
- 1.4.10 Reflow: presentations/diagrams can be exceptions for two-dimensional layout, but alternative views are advisable.
- 1.4.11 Non-text Contrast: 3:1 for UI components and graphical objects needed to understand content.
- 2.1.1 Keyboard and 2.1.2 No Keyboard Trap: deck controls must be keyboard operable.
- 2.2.2 Pause, Stop, Hide: moving/blinking/auto-updating content needs controls if it lasts more than five seconds.
- 2.3.1 Three Flashes: avoid flashing more than three times per second.
- 2.3.3 Animation from Interactions: `prefers-reduced-motion` is a listed technique.
- 2.4.2 Page Titled, 2.4.6 Headings and Labels, 2.4.7 Focus Visible, 2.4.11/12 Focus Not Obscured, 2.4.13 Focus Appearance support deck navigation and controls.

## Microsoft deck guidance

- Give every slide a unique title, even if the title is visually hidden.
- Ensure slide contents can be read in intended order; screen readers may follow creation/order rather than visual arrangement.
- Include alt text for visuals.
- Use meaningful hyperlink text; avoid “click here,” “see this page,” etc.
- Ensure color is not the only means of conveying information.
- Use sufficient text/background contrast.
- Use larger font size: 18pt or larger, sans serif fonts, and sufficient whitespace.
- Avoid tables when possible; if necessary, use simple structures and headers.
- Use captions/subtitles/alternative audio tracks for video.
- Test with a screen reader.

Deck implications:

- Build HTML slides semantically from the start.
- Provide a linear handout and speaker notes as an accessibility and stakeholder artifact.
- Make visual descriptions part of the talk track.
