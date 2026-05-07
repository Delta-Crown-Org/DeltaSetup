# Multi-Dimensional Analysis

## Information architecture

**Best-practice direction:** Use a decision-oriented narrative, not a chronological implementation diary.

Recommended IA model:

| Section | User question answered | DeltaSetup pattern |
|---|---|---|
| Hero | What is this and why should I care? | “Microsoft 365 operating model is live, governed, and ready for owner/MSP decisions.” |
| Value outcomes | What changed operationally? | Cards for secure collaboration, role-driven access, MSP handoff, launch readiness. |
| Evidence matrix | Can I trust it? | Done / blocked / decision-needed rows tied to docs. |
| Audience paths | Where do I go? | Executive, Operations, MSP, Technical reviewer cards. |
| Security/governance | Is it safe? | DLP, external sharing, legacy cleanup, known Teams read blocker. |
| Next actions | What decision/action is needed? | Owner approvals, metadata cleanup, Teams context, QA, launch package. |

## Avoiding vanity metrics/stat bands

Vanity stat bands fail when numbers are disconnected from decisions. For this project, counts should be subordinate to operational meaning.

**Replace:**
- “89 users / 10 sites / 48 scripts / 167 tests” as a decorative row.

**With:**
- “89 users audited → metadata cleanup is the access-scaling blocker.”
- “10 SharePoint sites audited clean → no Everyone/anonymous links found.”
- “167 tests passing → automation is regression-checkable before handoff.”
- “48 scripts → repeatable provisioning exists; hide script count unless MSP asks.”

Pattern: `Evidence → implication → action`.

## Action-oriented section design

Each section should contain:

1. **Outcome headline** — e.g., “External sharing is locked down.”
2. **Evidence bullet(s)** — concise, verifiable, linked to source docs.
3. **Decision/action** — e.g., “Approve DLP enforcement date.”
4. **Audience tag** — Executive / Ops / MSP / Technical.

Avoid passive headings like “Progress” or “Architecture Overview” when the goal is stakeholder action. Prefer “What is ready for MSP handoff” or “Decisions blocking launch readiness.”

## Accessibility / WCAG 2.2 considerations

Hard requirements and practical defaults:

| Area | Requirement / pattern |
|---|---|
| Text contrast | WCAG 1.4.3: 4.5:1 for normal text, 3:1 for large text. Avoid low-alpha white text on dark teal/black. |
| Non-text contrast | WCAG 1.4.11: visible UI boundaries/states/icons need 3:1 against adjacent colors. |
| Focus | WCAG 2.4.7 focus visible; 2.4.11 focus not entirely obscured; use a 3px outline with 3:1 contrast and offset. Test sticky sidebar/mobile menu. |
| Target size | WCAG 2.5.8 minimum 24×24 CSS px; prefer 44×44 for primary CTAs and navigation. |
| Cards | Non-interactive cards should not be focusable. If the whole card navigates, use a single `<a>` with descriptive accessible name and visible focus. Avoid nested interactive controls. |
| Buttons vs links | Use `<button>` only for in-page actions; use `<a href>` for navigation/downloads. Visual style can match, semantics should not. |
| Status | Do not rely on color alone. Include text labels (“Blocked”, “Decision needed”) and optionally icons with `aria-hidden="true"`. |
| Disclosure | Avoid hover-only reveals. Use native `<details><summary>` or JS-enhanced buttons with `aria-expanded` where needed. |
| Reflow | Layout must work at 320 CSS px / 400% zoom without horizontal scrolling except true data tables/diagrams. |
| Motion | Keep reveal animations non-essential and respect `prefers-reduced-motion`. |

## GitHub Pages / no-build constraints

GitHub Pages can serve HTML/CSS/JS directly from the repository. That supports a no-build design system, but increases the need for discipline.

Recommended constraints:

- Keep a small set of CSS files: `tokens.css`, `base.css`, `components.css`, page overrides only when necessary.
- Use custom properties for color/space/type/status tokens; no inline hex or one-off alpha values.
- Prefer utility-light component classes over framework conventions that require build tooling.
- Use semantic HTML components: `section`, `article`, `nav`, `table`, `dl`, `details`, `a`, `button`.
- Minimal JS: mobile nav, scroll progress, optional disclosure. Site content and navigation should still be usable if JS fails.
- Avoid npm/CDN dependencies that create supply-chain, privacy, or CSP concerns.
- Because project pages live under `/DeltaSetup/`, use relative URLs or validated root/path handling.

## Project-specific risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| Over-long single page | Stakeholders skim; MSPs need targeted handoff. | Audience paths + concise summaries + linked evidence. |
| Decorative stats | Can look like self-congratulation rather than operational value. | Evidence cards with implications/actions. |
| Sidebar breakpoints | Existing audit found content well is smaller than viewport due to sidebar. | Design to container width; avoid fixed 4/5-column grids. |
| Contrast drift | Current CSS has alpha-on-dark failures. | Tokenize text-on-dark ramp and run contrast checks. |
| Card/link ambiguity | Whole-card links and nested CTAs can break keyboard/screen reader UX. | One interaction per card; visible focus; descriptive link text. |
| Technical jargon | MSP and executive audiences need different detail levels. | Plain-English outcome first; technical evidence second.