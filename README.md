# DeltaSetup — Delta Crown Extensions

> **You are looking at the `gh-pages` branch.** This branch hosts the live executive site at <https://delta-crown-org.github.io/DeltaSetup/> and contains the canonical Microsoft 365 hub-and-spoke build for Delta Crown Extensions (DCE).

## What lives here

| Surface | Where | Purpose |
|---|---|---|
| Live executive site | <https://delta-crown-org.github.io/DeltaSetup/> | Public showcase of the DCE M365 operating model |
| Project status page | `index.html` | Architecture, phases, deployment status |
| Operations view | `operations.html` | Role-lens story for ops audiences |
| Provisioning scripts | `phase2-week1/`, `phase3-week2/`, `phase4-migration/` | PowerShell + Python automation, ordered by phase |
| Architecture decisions | `docs/architecture/decisions/ADR-001..004` | Hub/spoke, sites, migration, cross-tenant |
| Tenant inventory | `docs/delta-crown-*-inventory-summary.md` | Read-only audit evidence per workload |
| Onboarding model | `docs/onboarding/` | Identity-driven access, attribute matrix, pilot checklist |
| Runbook & status | `DEPLOYMENT-RUNBOOK.md`, `DEPLOYMENT-STATUS.md` | Deployment instructions and live state |
| QA plan | `QA-TEST-PLAN.md` | Validation approach |
| Session handoff | `SESSION-HANDOFF.md` | Context for the next agent/operator |
| Issue tracking | `.beads/` (bd) | All work tracked via `bd ready` / `bd show <id>` |

## Quick start (read-only)

```bash
# View open work
bd ready

# Inspect a doc
ls docs/

# Browse the deployed site
open https://delta-crown-org.github.io/DeltaSetup/
```

## Branch layout

This repo has **two orphan branches with no shared history**:

- **`gh-pages`** *(this branch)* — current canonical work: site, hub-and-spoke provisioning, audited architecture, onboarding model.
- **`main`** — abandoned earlier architecture (cross-tenant sync between HTT Brands and DCE via `scripts/00-08`). Disposition tracked in **DeltaSetup-165**. Do not treat `main` as current.

If you arrived here from the GitHub repo landing page (which defaults to `main`), the README on `main` describes the old direction. Use this branch for anything current.

## Working agreements

- **Issue tracking is `bd` (beads)**, not GitHub Issues — see `AGENTS.md`.
- **Tenant changes are gated**: read-only inventory only, no production cleanup without owner approval. See `docs/legacy-clientservices-cleanup-register.md` for the cleanup posture.
- **Document migration is out of scope** for this rollout (Tyler's decision, 2026-04-29). HTTHQ files stay where they are.
- **Do not commit** `.local/`, raw permission CSVs, or anything containing user PII.

## Key facts (as of latest update)

| | |
|---|---|
| Tenant | `deltacrown` (Microsoft 365 Business Premium) |
| Architecture | Corp-Hub + DCE-Hub with 4 brand sites and Teams workspace |
| Identity | Entra ID dynamic groups: AllStaff, Managers, Marketing, Stylists, External |
| Phases live | Phase 1 (Email Trust), Phase 2 (Hubs), Phase 3 (Brand sites + Teams + DLP), Phase 5 (Exchange) |
| Phase 4 | Document migration **skipped by decision** |
| Security hardening | Applied 2026-04-29 via PnP DeviceLogin |

## Contact / ownership

Tyler Granlund (owner). Agent assistants: Richard (`code-puppy-*`).
