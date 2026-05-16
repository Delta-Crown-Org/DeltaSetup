# 11 — Decisions (ADRs)

ADRs live under `decisions/`. Format: one decision per file, numbered
sequentially, status-tagged.

## Index

| # | Decision | Status |
|---|---|---|
| [001](decisions/001-hub-and-spoke.md) | Hub-and-spoke topology | Accepted |
| [002](decisions/002-ci-cd-tier.md) | CI/CD ambition: Medium (PnP + GitHub Actions) | Accepted |
| [003](decisions/003-dynamic-sync-gate.md) | Dynamic membership rule for SG-DCE-Sync-Users | Accepted, Implemented |
| [004](decisions/004-permissions-philosophy.md) | Inherit by default; audience-target for visibility | Accepted |
| [005](decisions/005-defer-spfx-custom-webparts.md) | Defer SPFx custom web parts to sprint 2+ | Accepted |
| [006](decisions/006-repo-placement.md) | New repo `Delta-Crown-Org/dce-sharepoint` | Proposed |
| [007](decisions/007-auth-model.md) | Cert-based app-only auth for CI | Accepted |

## ADR template

When adding a new ADR, use this template:

```markdown
# ADR-NNN — <title>

**Status:** Proposed | Accepted | Superseded by ADR-X
**Date:** YYYY-MM-DD
**Decision-maker:** <name or role>
**Implements:** <which chapter(s)>

## Context

What problem are we solving? What facts on the ground motivate this?

## Decision

The actual choice. Concise.

## Alternatives considered

### A. <alternative>
- Pro / Con / Verdict

### B. <alternative>
- Pro / Con / Verdict

(More as needed.)

## Consequences

What does this make easier? What does it make harder?

## Open follow-ups

Anything we know we'll need to revisit.
```

## When to write an ADR

You owe an ADR when:

- A choice has more than one plausible alternative.
- The choice is hard to reverse cheaply.
- The choice affects more than one chapter of this spec pack.
- An outside-the-team contributor would reasonably question the choice.

You don't owe an ADR for:

- Renaming a variable.
- Picking between two equivalent JSON keys.
- Pure aesthetic CSS tweaks.

## Superseding ADRs

When an ADR is superseded by a newer one:

1. The new ADR opens with "Supersedes: ADR-NNN".
2. The old ADR's status changes to "Superseded by ADR-MMM".
3. The decision history is preserved (don't delete old ADRs).
