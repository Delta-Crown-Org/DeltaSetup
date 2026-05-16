# ADR-006 — Repo placement: new `Delta-Crown-Org/dce-sharepoint`

**Status:** Proposed (pending Tyler confirmation)
**Date:** 2026-05-15
**Implements:** `07-ci-cd-pipeline.md`, `12-implementation-plan.md`

## Context

We need to put PnP templates, GitHub Actions workflows, and SPFx
artifacts somewhere. Three candidates.

## Decision

Create a **new repository** `Delta-Crown-Org/dce-sharepoint`.

## Alternatives considered

### A. This repo (`Delta-Crown-Org/DeltaSetup`)

- Pro: keeps DCE knowledge centralized; gh-pages branch already has
  audit gates.
- Con: gh-pages is the public site; mixing intranet automation in is
  confusing. Also: SP-deploy workflows would trigger on gh-pages
  pushes, which is the wrong trigger surface.
- Rejected.

### B. The HTT-side `Convention-Page-Build` repo

- Pro: leverages the existing SPFx scaffold and audit scripts.
- Con: DCE is its own org with its own GitHub org (`Delta-Crown-Org`).
  Putting DCE SP code in a HTT-side repo creates a cross-org
  dependency that's hard to maintain.
- Rejected.

### C. New repo `Delta-Crown-Org/dce-sharepoint`

- Pro: clean separation, lives in the right GitHub org, can be cloned
  by DCE engineers without HTT credentials.
- Con: one more repo to maintain.
- **Accepted.**

## Consequences

- Scaffold from `Convention-Page-Build/spfx/` (copy, not fork — we'll
  diverge).
- Reference this spec pack by linking back to the DeltaSetup repo.
- Brand Center configuration also lives in this new repo (Theme JSON,
  Brand Center provisioning template).
