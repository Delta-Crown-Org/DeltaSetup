# ADR-002 — CI/CD ambition: Medium (PnP + GitHub Actions)

**Status:** Accepted (pending Tyler final confirmation)
**Date:** 2026-05-15
**Implements:** `07-ci-cd-pipeline.md`

## Context

`docs/architecture/dce-sharepoint-design-roadmap.md` § 7 defined three CI/CD
ambition tiers (Light / Medium / Heavy). We pick one as the default for v1.

## Decision

**Medium: PnP PowerShell + GitHub Actions.**

Implementation: `07-ci-cd-pipeline.md`.

## Alternatives considered

### A. Light (manual PnP runs from a workstation)

- Pro: zero infra cost.
- Con: no audit trail, no quality gates, error-prone.
- Rejected for production. Acceptable as a fallback during incidents.

### B. Heavy (SPFx + App Catalog + GitHub Actions)

- Pro: pixel-perfect control over chrome via Application Customizer;
  custom web parts.
- Con: ~2-3 weeks of incremental setup before first deploy; requires
  App Catalog admin role; locked into Microsoft's SPFx release cadence.
- Deferred. Layer onto Medium when Medium can't deliver a specific UX
  requirement.

## Consequences

- The first delivery target is "DCE Hub with branded theme + 5 home-page
  sections" — achievable with Medium in ~2 weeks (per `12-implementation-plan.md`).
- Custom web parts (e.g., a fancier hero with animation) wait for Heavy.
- The team learns PnP idioms first; SPFx is a later upgrade path that
  layers cleanly.

## Trigger to upgrade to Heavy

We adopt Heavy when one of:

1. We need a global tenant-wide header/footer that site owners can't
   override (Application Customizer use case).
2. We need a custom web part with logic SharePoint OOTB doesn't provide
   (e.g., real-time KPI dashboards pulling Power BI).
3. We need Viva Connections Adaptive Card Extensions for mobile.

Until then: Medium.
