# HTT Operational Fluidity Design System Review — Research Notes

**Date:** 2026-05-17  
**Project context:** `decks/htt-operational-fluidity/` is a 10-slide Reveal.js operator walkthrough for a 10–12 minute executive/operator audience. The deck uses a warm cream/green/gold HTT style, logo rails, footer metadata, journey/relationship diagrams, and brand-card moments.

## Executive summary

For an operator briefing deck, the design system should optimize for **fast comprehension, speaker support, and trust** rather than screen-dense documentation. The current direction — warm brand canvas, short operator language, diagrams over paragraphs, 10 slides / 12 minutes — is appropriate. The highest-value improvements are to formalize rules that prevent layout collisions and keep diagrams/metadata legible under projection and PDF export.

## Key implementation guidance

1. **Set slide density budgets.** For a 10–12 minute briefing, treat each slide as one idea: one headline, one supporting sentence, and either 3–5 cards or one diagram. Move backup detail into notes or handouts.
2. **Reserve protected header/footer zones.** Define CSS variables for top rail, footer, content inset, and safe area. Content components must never occupy those zones.
3. **Make metadata intentionally secondary but readable.** Footer/header text should be at least 13–16px in HTML and pass WCAG text contrast. Avoid ultra-wide letterspacing on very small text.
4. **Normalize logo optical balance.** Size logos by perceived visual weight, not raw image dimensions. Use fixed max-height, max-width, and object-fit; adjust individual brand tokens when marks differ in density.
5. **Use diagrams as relationship explanations, not decoration.** Every connector, arrow, cluster, or color state must have a semantic purpose and a visible non-color cue.
6. **Confirm WCAG 2.2 AA applicability.** Because the deck is HTML/CSS web content, WCAG 2.2 AA applies to the delivered deck and exported web/PDF materials where claimed. Critical implications: 4.5:1 normal text contrast, 3:1 large text and meaningful graphics, no color-only meaning, semantic structure/alt text, keyboard operability, visible focus, captions/transcripts if media is added, and accessible materials distributed ahead of meetings.

## Recommended deck review rubric

| Area | Pass condition |
|---|---|
| Narrative | 10 slides tell one operator story: reality → principle → journey → brand expression → practice → human support → metrics → commitments → close. |
| Density | No slide exceeds 1 headline + 1 lede + 5 visual items, or a single table/diagram with 3 rows. |
| Typography | Headline line length is controlled; body/metadata remains legible at projector distance and PDF export. |
| Safe zones | Header/footer rails never overlap diagrams, cards, or large logos at 1600×900 and print-PDF. |
| Brand warmth | Cream/green/gold palette supports emotional warmth but does not reduce contrast or make operational content feel decorative. |
| Logos | HTT/DCE and sibling brand marks feel optically balanced; no mark dominates unless intentionally featured. |
| Diagrams | Relationship cues use position, labels, lines/arrows, grouping, and contrast — not color alone. |
| Accessibility | WCAG 2.2 AA checks are run against HTML; PDF export is treated as a secondary artifact requiring its own review if distributed. |

## Bottom line

Keep the deck **spacious, warm, and operator-literal**. The implementation priority is not more visual richness; it is **codified constraints**: density budgets, protected zones, contrast tokens, logo sizing rules, and diagram semantics that survive projection, PDF export, and assistive technology review.
