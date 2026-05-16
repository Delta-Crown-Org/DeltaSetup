# ADR-004 — Permissions philosophy: inherit by default

**Status:** Accepted
**Date:** 2026-05-15
**Implements:** `05-permissions-model.md`

## Context

HTT Brands Headquarters is described as "a giant cluster block" of
permission breaks, audience guesswork, and orphaned grants. We want
the DCE topology to NOT become that.

## Decision

DCE SharePoint defaults to **inherited permissions everywhere**.
Permission inheritance is broken only when ALL of the following hold:

1. Content is genuinely confidential.
2. Audience targeting can't achieve the goal.
3. The break has a documented owner + (when applicable) sunset date.
4. The break is registered in `reference/permission-breaks.csv`.
5. A weekly audit job detects drift from the registry.

Anything else uses **audience targeting** at the web-part, page, or
nav-node level — visibility without losing search/audit/governance
properties.

## Alternatives considered

### A. Break inheritance liberally, configure case-by-case

- Pro: maximum control per item.
- Con: this is exactly what HTT HQ has. Unsustainable.
- Rejected.

### B. Never break inheritance; everything is at least site-readable

- Pro: simplest model.
- Con: there are genuinely confidential things (executive comp,
  HR investigations). They need a hard wall.
- Rejected — but is the default for 99% of content.

## Consequences

- New sites must NOT pre-break inheritance.
- New libraries inherit from their site by default.
- A permission audit job runs weekly (`05-permissions-model.md` §
  "Audit mechanism").
- Engineers who add a break must update the registry CSV.
- Drift is detected and surfaced; not silently accepted.

## Open follow-ups

- Initial registry seed: just the Crown Connection "Owner-only library"
  break (documented).
- Audit threshold: how many days of detected drift triggers an
  escalation? Recommend 7 (a single missed weekly run).
