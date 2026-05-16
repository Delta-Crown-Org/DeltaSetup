# ADR-005 — Defer SPFx custom web parts

**Status:** Accepted
**Date:** 2026-05-15
**Implements:** `06-tooling-pnp.md`, `12-implementation-plan.md`

## Context

`DESIGN_SYSTEM_MEGA_BRIEF.md` (HTT side) proposes a full SPFx project with
custom web parts (`hero-banner`, `card-grid`, etc.). That's a significant
investment.

## Decision

For DCE sprint 1: use **out-of-the-box SharePoint web parts** themed via
Brand Center + global CSS. Custom SPFx web parts are deferred until a
specific need can't be met OOTB.

## Alternatives considered

### A. Build all custom web parts up front

- Pro: pixel-perfect design fidelity.
- Con: ~2 weeks of work before first deploy; OOTB might be 90% as good.
- Rejected for sprint 1.

### B. Use SPFx Application Customizer only (global header/footer)

- Pro: highest-impact SPFx slice; doesn't require custom web parts.
- Con: still requires App Catalog setup + SPFx pipeline.
- Deferred to sprint 2 — if Brand Center alone can't deliver the look.

## Triggers to revisit

Custom web parts will be built when one of:

1. Brand Center themed OOTB hero doesn't deliver the visual we need.
2. We need a multi-source news web part (e.g., HTT + DCE news combined).
3. We need real-time KPI tiles pulling Microsoft Graph data.
4. Mobile / Viva Connections experience requires Adaptive Card Extensions.

## Consequences

- Sprint 1 mockup is OOTB-themed.
- Brand fidelity for sprint 1 is "good not great." Acceptable trade-off
  for first ship.
- Sprint 2 plan must explicitly evaluate whether to start SPFx work.
