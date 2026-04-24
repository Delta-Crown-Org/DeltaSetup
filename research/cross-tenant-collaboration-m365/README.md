# Cross-Tenant Collaboration in Microsoft 365

## Research Status
- **Date**: 2025-08-08
- **Contributors**:
  - Solutions Architect (`solutions-architect-5bb64d`)
  - Experience Architect (`experience-architect-session-9fc05d` synthesis)
  - Code Puppy (`code-puppy-6b0328`)
- **Context**: Second-pass research for DeltaSetup to capture lessons from prior HTT cross-tenant work before extending SharePoint / Teams architecture decisions.

## Why This Research Exists
DeltaSetup currently documents a strong **single-tenant** SharePoint / Teams architecture for Delta Crown. That remains the primary design.

What was missing was a clean research layer for the moment we need to support **cross-tenant collaboration** across HTT brand tenants and external partner identities without repeating the mistakes seen in:

- `Convention-Page-Build`
- `Cross-Tenant-Utility`

The critical lesson: **cross-tenant admission and SharePoint authorization are not the same thing**.

If we blur them together, Microsoft Entra politely punches us in the throat with errors like `AADSTS500213`.

## Key Findings
1. **Single-tenant DCE remains the correct baseline** for current DeltaSetup work.
2. **B2B collaboration** is the right fallback for regular external SharePoint / Teams access.
3. **Cross-tenant sync** is the preferred advanced pattern for repeat collaboration between related tenants when better lifecycle management and less invitation friction are worth the extra governance.
4. **B2B Direct Connect is not a normal SharePoint site access solution**. It is for Teams shared-channel scenarios.
5. **Never gate inbound B2B collaboration on resource-tenant dynamic groups** that depend on guest/member objects being created first.
6. **Dynamic groups are still good** — just at the **authorization layer** (SharePoint / Teams / M365 groups), not the **admission layer** (cross-tenant access policy).

## Research Questions Answered
- When should DeltaSetup stay single-tenant versus plan for cross-tenant collaboration?
- When should we use guests versus synced member-type users?
- Where are dynamic groups safe, and where are they a trap?
- What order of operations avoids B2B deadlocks and first-run access failures?
- How should future ADRs separate identity admission from resource authorization?

## File Inventory
- `analysis.md` — architecture model, layer separation, patterns, and failure modes
- `recommendations.md` — pragmatic design guidance, sequencing, and action plan
- `sources.md` — Microsoft + internal project references
- `lessons-from-htt-projects.md` — distilled lessons from prior HTT repos

## Relationship to Existing DeltaSetup Research
This research extends, but does not replace:
- `research/sharepoint-hub-spoke/`
- `research/sharepoint-franchise-portal/`
- `research/sharepoint-provisioning/`
- `research/phase3-sharepoint-teams/`

Those files explain the **current single-tenant architecture**.
This package explains the **cross-tenant collaboration overlay** that must be understood before reusing the same patterns across multiple tenants.

## Recommended Next Architecture Artifact
Create a future:
- `docs/architecture/decisions/ADR-004-cross-tenant-collaboration-sharepoint-access.md`

That ADR should formalize:
- single-tenant baseline vs cross-tenant overlay
- B2B collaboration vs cross-tenant sync decision criteria
- prohibition on resource-tenant dynamic-group gating in inbound partner policy
- order of operations for partner onboarding
