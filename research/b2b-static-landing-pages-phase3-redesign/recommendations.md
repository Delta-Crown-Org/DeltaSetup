# Recommendations — DeltaSetup Phase 3.0 Static Site Redesign

## Priority 1 — Redesign around stakeholder actions

### Proposed top-level flow

1. **Hero: “Delta Crown’s Microsoft 365 operating model is live, governed, and ready for launch decisions.”**
   - Primary CTA: “Review launch blockers”
   - Secondary CTA: “Open MSP handoff”
   - Tertiary link: “See architecture evidence”

2. **Operational value cards**
   - Secure collaboration is now governed.
   - Brand/resource structure is deployed.
   - MSP handoff evidence exists.
   - Remaining work is owner decisions + metadata cleanup, not new architecture.

3. **Launch readiness matrix**
   - Done: SharePoint hubs/spokes, Teams workspace, DLP policies, Exchange setup, audits.
   - Blocked: Teams read context, user metadata gaps.
   - Decisions: group owners, DLP enforcement, stale branch, brand resources model.

4. **Audience paths**
   - Executive: “What decisions do I need to make?”
   - Operations: “What changes day one?”
   - MSP/CSP: “What needs monitoring/handoff?”
   - Technical: “Where is the evidence?”

5. **Security/governance evidence**
   - Use an evidence checklist, not a marketing claim wall.

6. **Next actions**
   - Numbered action list with owner/status/source link.

## Priority 2 — Convert vanity metrics to decision evidence

Use this rewrite table:

| Current-style stat | Better pattern |
|---|---|
| “89 users” | “89 users audited; only 6 have companyName, so metadata cleanup blocks dynamic access.” |
| “10 sites” | “10 SharePoint sites audited clean: no Everyone or anonymous links found.” |
| “48 scripts” | “Repeatable provisioning exists; MSP can rerun/verify via runbooks.” |
| “167 tests passing” | “Regression checks exist before launch/handoff.” |
| “$0 added license cost” | “Built on existing Microsoft 365 Business Premium licensing; no added platform subscription identified.” |

## Priority 3 — Component patterns for static HTML/CSS

### Decision card

```html
<article class="decision-card decision-card--blocked">
  <p class="eyebrow">Launch blocker</p>
  <h3>Teams read context still needs licensed validation</h3>
  <p>Current admin context cannot complete Teams channel-detail inventory.</p>
  <a class="button button--secondary" href="docs/teams-inventory-access-request.md">
    Review access request
  </a>
</article>
```

Rules:
- If the card has a CTA, do not also make the whole card clickable.
- Heading first, evidence second, action last.
- Modifier names should reflect state, not color: `--blocked`, `--decision`, `--complete`.

### Status badge

```html
<span class="status status--decision">
  <span aria-hidden="true">●</span>
  Decision needed
</span>
```

Rules:
- Text label is mandatory.
- Icon is decorative unless it adds unique information.
- Color must not be the only signal.

### Button/link system

- Primary CTA: one per section max.
- Secondary CTA: lower-contrast but still AA-compliant.
- Link text must describe destination/action: avoid “Learn more”.
- Minimum interactive box: 44×44 preferred; never below WCAG 2.2 24×24 without spacing exception.

## Priority 4 — Accessibility acceptance criteria

Before shipping Phase 3.0, verify:

- [ ] All text/background pairs pass WCAG 2.2 AA contrast.
- [ ] Focus indicator has at least 3:1 contrast against adjacent colors and is not obscured by sidebar/mobile menu.
- [ ] Keyboard can reach and operate all navigation, disclosure, and CTA controls.
- [ ] No non-interactive cards are focusable.
- [ ] Whole-card links, if used, have a single accessible name and no nested buttons/links.
- [ ] Reflow works at 320 CSS px / 400% zoom without horizontal scrolling except explicit wide tables/diagrams.
- [ ] Motion respects `prefers-reduced-motion`.
- [ ] Status, risk, and progress are conveyed by text, not color alone.
- [ ] Mobile menu button exposes `aria-expanded` and preserves focus order.

## Priority 5 — No-build design system guardrails

- Freeze tokens before page redesign: colors, text-on-dark ramp, spacing, grid breakpoints, status states.
- Use container-aware layouts: `grid-template-columns: repeat(auto-fit, minmax(min(100%, 18rem), 1fr));` for most card grids.
- Avoid 5-column desktop grids in sidebar pages.
- Keep raw implementation evidence in docs; landing page should summarize and link.
- Add a small “content pattern glossary” in comments or docs so future edits preserve the strategy.

## Suggested success metric for Phase 3.0

Do not measure success by number of sections or visual polish. Measure by whether a stakeholder can answer within 2 minutes:

1. What is live?
2. What remains?
3. What decision/action is needed from me?
4. Where is the evidence?
5. Who owns the next step?