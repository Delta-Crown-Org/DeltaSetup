# ADR-001 — Hub-and-spoke topology

**Status:** Accepted
**Date:** 2026-05-15
**Decision-maker:** Tyler Granlund
**Implements:** `01-architecture.md`

## Context

DCE has two SharePoint sites today (DCE Hub, Crown Connection) and will
add more (Brand Center, Operations Manuals, Training). We need a topology
that scales without forcing every page to re-do navigation/theming/search.

## Decision

Use SharePoint's **hub-and-spoke** model:

- **Hub** = DCE Hub (`/sites/dce-hub`). Sets theme, global nav, search.
- **Spokes** = Crown Connection, Brand Center, and any future site,
  associated to DCE Hub.
- One hub per DCE tenant (not nested hubs).

## Alternatives considered

### A. Flat (no hub)

Each site standalone. Every site duplicates theme + nav config.

- Pro: simple to set up initially.
- Con: brand changes require N updates; navigation inconsistencies inevitable.
- Rejected.

### B. Multi-hub (one hub per audience)

E.g., Owner Hub and Staff Hub as parallel structures.

- Pro: cleaner audience separation at the topology level.
- Con: SharePoint's hub model isn't designed for cross-hub navigation;
  users can only "follow" one hub at a time in modern Microsoft 365 UI.
- Rejected.

### C. Microsoft Viva Connections (no SharePoint hubs)

Replace SharePoint hub with Viva as the navigation layer.

- Pro: mobile-first, cross-tenant friendly.
- Con: Viva is overkill for DCE's current scale; adds licensing
  complexity.
- Deferred. Revisit when DCE has 50+ staff or mobile is primary.

## Consequences

- All new DCE sites must be associated to DCE Hub.
- DCE Hub theme is the canonical theme; spokes pick it up.
- One person (Tyler today, transferable) owns hub configuration.

## Open

- Should the public-facing site `deltacrown.com` be involved in the hub
  navigation? Probably not — it's a separate (Astro/static) property. But
  cross-linking should be intuitive (footer + about page).
