# B2B Static Landing Pages — DeltaSetup Phase 3.0 Redesign Research

**Project context:** DeltaSetup is a GitHub Pages static HTML/CSS/JS showcase for a completed Microsoft 365 operations platform. Audiences include MSP/CSP partners, operations users, and executive/stakeholder reviewers. The current site already has strong evidence artifacts, but previous audits show over-dense sections, decorative/stat-heavy patterns, breakpoint fragility, and WCAG 2.2 contrast/focus issues.

## Key findings

1. **Lead with the decision/use case, not the build inventory.** High-conversion B2B pages work when the first screen answers: “Who is this for?”, “What changed operationally?”, “Why should I trust it?”, and “What should I do next?” For DeltaSetup, that means: “A governed Microsoft 365 operating model for Delta Crown — live, audited, ready for owner decisions/MSP handoff.”
2. **Replace vanity metric bands with evidence cards.** Large stat strips are often skimmed as decoration unless they connect to a decision. Convert counts into outcomes: “Anonymous sharing disabled”, “DLP policies deployed”, “metadata cleanup still blocks dynamic access.”
3. **Use action-oriented sections.** Each major section should end in a next action: review risk, approve owner decision, hand off to MSP, run QA, populate metadata, validate Teams blocker.
4. **Segment by audience, but keep one canonical story.** Use short audience paths/cards: Executive: business readiness; Operations: what changes day-to-day; MSP: tenant/security handoff; Technical reviewer: architecture evidence.
5. **WCAG 2.2 AA must be a design constraint, not QA polish.** Cards/buttons need semantic HTML, 4.5:1 body text contrast, 3:1 non-text/focus contrast, visible focus, at least 24×24 pointer targets (prefer 44×44 for primary CTAs), no hover-only disclosure, and layouts that reflow at 320 CSS px.
6. **GitHub Pages/no-build favors a small component system.** Use plain HTML partial discipline, CSS tokens, reusable classes, no dependency-heavy framework, minimal JS only for progressive enhancement, and content patterns that survive without JS.

## Recommended Phase 3.0 IA

1. **Hero / decision frame** — one-sentence value proposition + audience route buttons.
2. **Operational value summary** — 3–4 outcome cards; no free-floating stats.
3. **What is live / what remains** — “done / blocked / decision needed” evidence matrix.
4. **Audience paths** — MSP handoff, operations adoption, stakeholder approval.
5. **Security & governance evidence** — audited controls, DLP, external sharing posture, known blockers.
6. **Architecture narrative** — hub/spoke diagram and plain-English explanation.
7. **Action plan** — next decisions, owners, validation tasks, handoff package links.

## Practical patterns

- Use cards as **decision cards**: title = action/outcome; body = evidence; footer = next step/link.
- Use buttons as **verbs**: “Review MSP handoff”, “Approve group owners”, “Validate Teams access”, not “Learn more”.
- Use metrics only when followed by **so what**: “89 users audited → metadata cleanup is the access-scaling blocker.”
- Use status states consistently: `complete`, `blocked`, `decision`, `skipped`, `risk`, with text labels and icons, not color alone.
- Use progressive disclosure for detail-heavy evidence, but keep summaries visible and keyboard accessible.

## Confidence

High for accessibility and static-hosting findings (Tier 1 official sources). Medium-high for conversion/IA patterns: based on established UX research and B2B landing-page practitioner consensus; exact conversion gains vary by audience and offer quality.