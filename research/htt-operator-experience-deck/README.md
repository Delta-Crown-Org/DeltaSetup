# HTT Operator Experience Deck — Research Summary

**Research date:** 2026-05-17  
**Researcher:** web-puppy-7f7f48  
**Project context:** HTT family brands / Delta Crown ecosystem, operator-facing 10-slide / 12-minute Reveal.js or HTML presentation. Focus is operational fluidity and experience impact for franchise/brand operators, not technical architecture.

## Executive summary

A strong operator deck should behave less like an architecture briefing and more like a guided experience map: “Here is the friction operators feel today, here is the smoother path, here is what changes in their day.” The most credible guidance converges on five design rules:

1. **One assertion per slide, supported by one visual proof.** Use assertion-evidence titles instead of topic titles. Example: “Operators get one clear place to start the day” rather than “Portal overview.”
2. **Tell the operational journey, not the system build.** Anchor around actor → scenario → phases → pain/emotion → opportunity/action, using NN/g journey-map components.
3. **Design for glance comprehension.** A 12-minute, 10-slide deck allows ~60–70 seconds per slide plus opening/transition. Each slide should have a 3-second takeaway and a speaker-led detail layer.
4. **Use accessible HTML as the source of truth.** W3C WAI and WCAG 2.2 support HTML/EPUB/word-processing formats because they are adaptable; for a Reveal.js deck, semantic headings, DOM order, alt text, visible focus, reduced motion, captions/transcripts, and contrast are mandatory.
5. **Keep the visual system premium but operational.** HTT/DCE emerald, gold, ivory, and restrained photography can communicate brand value; dense diagrams, animated dashboards, and technical icons will undermine operator trust.

## Recommended 10-slide narrative arc for 12 minutes

| # | Slide assertion | Purpose | Visual pattern |
|---|---|---|---|
| 1 | “HTT operators need fewer handoffs, not more tools.” | Set operator-first premise | Full-bleed calm operations photo + one-line promise |
| 2 | “Today’s workday starts with scattered signals.” | Current-state friction | 3-lane experience snapshot: Find / Decide / Act |
| 3 | “Fragmentation shows up as lost time, missed context, and inconsistent brand execution.” | Translate friction into business impact | Three impact cards; avoid architecture labels |
| 4 | “The better experience is a single operating rhythm.” | Introduce future-state concept | Simple before/after flow with one entry point |
| 5 | “Operators see what matters by role, brand, and moment.” | Personalization as experience, not tech | Persona/role cards with scenario prompts |
| 6 | “Each brand keeps its identity while sharing the same operating backbone.” | HTT family brand fit | Brand-system matrix / family-of-brands layout |
| 7 | “The day becomes easier at the moments that currently break momentum.” | Journey proof | Experience map with emotion line and opportunity markers |
| 8 | “Operational fluidity compounds across launch, training, requests, and support.” | Show repeatable value | Four-phase operational lifecycle |
| 9 | “Success is measured in operator confidence and response speed.” | Define outcomes | Metrics framed as operator outcomes, not system metrics |
| 10 | “Decision: align on the operator experience model and next proof point.” | Clear close / ask | One decision box + 30-day proof action |

## Immediate HTML/CSS recommendations

- Use **Reveal.js semantic slides**: `<section aria-labelledby="slide-03-title">` with a single `h2` assertion per slide.
- Add a **visually hidden deck outline** or PDF/HTML handout link for screen-reader and leave-behind use.
- Configure Reveal with predictable sizing: `width: 1280`, `height: 720`, `margin: 0.06`, `center: false`; avoid content that depends on exact scaling.
- Prefer CSS Grid/Flex layouts with max 2–3 regions per slide: `kicker`, `assertion`, `evidence`, `operator takeaway`.
- Use project tokens: emerald/teal for authority, ivory for reading surfaces, gold as an accent only. Do not place small gold text on ivory or photo backgrounds without tested contrast.
- Keep live slide text to **one headline + 1–3 evidence points**. Put details in speaker notes or an accessible handout.
- Use `prefers-reduced-motion` and keep Reveal transitions subtle (`fade` or `none`); fragments should reveal comprehension, not create suspense.
- Every journey-map or flow visual needs a text equivalent near the visual or linked from the slide.

## Key pitfalls to avoid

- Turning the operator deck into a SharePoint/M365 architecture deck.
- Using “hub/spoke,” “tenant,” “permissions,” “migration,” or “dynamic groups” without translating to operator benefit.
- Overusing dark luxury backgrounds for body text; premium slides still need readable contrast and large type.
- Relying on color-only status cues such as red/yellow/green without text labels, icons, or patterns.
- Using screenshots as proof when they contain tiny unreadable UI text.
- Treating accessibility as a PowerPoint export issue; build accessible HTML from the beginning.

## Source basis

Primary/high-reliability sources used: Reveal.js official documentation, W3C WAI event/presentation accessibility guidance, W3C WCAG 2.2 Quick Reference, Microsoft Support accessible PowerPoint guidance, and Nielsen Norman Group journey mapping guidance. See `sources.md` for credibility assessments and `analysis.md` for synthesis.
