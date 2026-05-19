# ADR-012: DCE Microsoft 365 Multi-Tenant Organization membership evaluation

**Status:** Proposed / evaluation only — not approval evidence  
**Date:** 2026-05-19  
**Tracking bead:** `DeltaSetup-a3d`  
**Decision owner:** Tyler Granlund, with Megan + security review  
**Re-evaluate by:** 2026-07-03

## Context

Delta Crown Extensions currently operates as a separate Microsoft 365 tenant and is not a Microsoft 365 Multi-Tenant Organization (MTO) member.

DCE uses cross-tenant synchronization from HTT for selected users. The 2026-05-18 SyncFabric incident showed why this identity architecture needs explicit governance:

- The HTT-to-DCE sync application is an HTT source-side Azure2Azure sync app targeting DCE.
- Scope is assignment-based, not `SyncAll`.
- The HTT admin source account was out of entitlement scope and the DCE target admin object was soft-deleted by SyncFabric.
- A temporary direct app assignment bridge now explicitly entitles the admin account.

Separately, ADR-011 identified notification-suppression risk around Microsoft 365 Groups, guests, and cross-tenant users. MTO membership may reduce the guest-user autosubscribe trap by promoting synced users from `Guest` to `Member` userType in participating tenants.

This ADR evaluates whether DCE should join an MTO. It does **not** authorize implementation.

MTO is not authorized at this time. Any MTO configuration, pilot, tenant-pair setup, or cross-tenant synchronization change requires a new implementation ADR or ADR update, STRIDE review, data exposure assessment, rollback plan, and security approval.

## Decision options

### Option A — Join MTO

DCE joins an MTO with HTT and relevant brand tenants.

Potential benefits:

- Synced users can appear as `Member` rather than `Guest` where MTO behavior applies.
- Reduces the group guest autosubscribe trap described in ADR-011.
- Improves cross-tenant collaboration experience across Teams and identity surfaces.
- Makes the multi-brand operating model more explicit instead of relying on ad hoc B2B/sync behavior.

Costs/risks:

- More shared identity blast radius.
- More governance complexity.
- Requires tenant admin coordination and business approval.
- Requires review of conditional access, cross-tenant access settings, Terms of Use, access reviews, lifecycle controls, and notification side effects.
- Rollback/exit behavior must be understood before joining.

Best fit if:

- DCE and HTT will continue deep operational collaboration.
- Cross-brand shared workspaces are strategic, not temporary.
- Security/governance owner accepts the shared identity posture.

### Option B — Defer MTO

Keep current cross-tenant sync/B2B model while hardening controls.

Potential benefits:

- Avoids broad tenant-level change while DCE setup is still stabilizing.
- Allows time to complete canaries, owner-site audit, Teams inventory, and production content promotion.
- Keeps the direct CTSync assignment bridge in place while dynamic group behavior settles.

Costs/risks:

- Continued guest/member edge cases.
- Continued need for explicit notification-suppression controls.
- More manual governance around sync scope and app assignments.

Best fit if:

- Current priority is safe launch and stabilization.
- There is not yet business/security consensus for MTO.
- Teams inventory and canary evidence are incomplete.

### Option C — Never join MTO

DCE remains separate permanently and uses explicit sync/B2B patterns.

Potential benefits:

- Strong tenant separation.
- Smaller shared-identity blast radius.
- Simpler mental model for tenant boundaries.

Costs/risks:

- Persistent friction for cross-tenant collaboration.
- Persistent `Guest` edge cases where users are not converted/represented as members.
- More custom governance for every brand tenant.

Best fit if:

- DCE needs strong independence from HTT.
- Cross-brand collaboration is limited or can be handled with explicit B2B controls.
- Security prioritizes separation over collaboration smoothness.

## Evaluation matrix

| Criterion | Join MTO | Defer MTO | Never join MTO |
|---|---|---|---|
| Notification quietness | Positive; may reduce guest autosubscribe trap | Neutral; requires ADR-011 controls | Neutral/negative; guest edge cases persist |
| Collaboration UX | Strongest | Medium | Weakest |
| Tenant separation | Weakest | Strong | Strongest |
| Governance complexity | High | Medium | Medium/high recurring manual work |
| Immediate risk | High if rushed | Low | Low |
| Reversibility confidence | Unknown; must research | High | High |
| Fit with current incident posture | Too soon to implement | Best near-term | Possible but premature |

## Recommended provisional decision

**Defer MTO implementation. Continue evaluation. Re-evaluate by 2026-07-03 with Tyler, Megan, and security review.**

Rationale:

1. DCE identity was just stabilized after a SyncFabric deletion incident.
2. The direct app assignment bridge is working and should not be disturbed during immediate launch work.
3. Teams inventory and notification canaries are still incomplete.
4. Owner-site audit and production hub promotion are not finished.
5. MTO may be beneficial, especially for notification quietness and collaboration UX, but it is tenant-level architecture and needs explicit business/security approval.

## Minimum prerequisites before joining MTO

Before any implementation decision, complete:

- `DeltaSetup-b2i`: permanent decision for DCE SyncFabric admin entitlement/scope.
- `DeltaSetup-4ay`: Teams read-context blocker and inventory.
- `DeltaSetup-j3c`: initial empirical notification canaries, if MTO is used as a notification-risk reducer.
- `DeltaSetup-33c`: recurring canary plan.
- `DeltaSetup-rod`: cross-brand owner-site audit, at least for DCE + HTT.
- Conditional Access and cross-tenant access policy review.
- Rollback/exit plan.
- Named break-glass access path that does not depend on HTT cross-tenant sync.
- Owner/security approval.

## If MTO is later approved

Implementation must be treated as a controlled release:

1. Create a pre-change tenant configuration export.
2. Confirm cross-tenant access policies.
3. Confirm target users/groups and lifecycle owner.
4. Run canary with a test HTT user first.
5. Confirm no unexpected user-facing mail.
6. Confirm Teams/collaboration UX changes.
7. Expand only after approval gate.
8. Monitor SyncFabric/audit drift for at least one full sync cycle.

## Non-goals

This ADR does not:

- join DCE to an MTO;
- change cross-tenant sync configuration;
- change direct app assignments;
- change conditional access;
- approve production promotions;
- approve tenant-wide user sync expansion.

## Open questions

- Which tenants would be in the MTO: HTT, DCE, TLL, BCC, Frenchies, Bishops, others?
- What is the authoritative lifecycle owner for cross-brand identities?
- What rollback/exit behavior does Microsoft currently support for this tenant shape?
- How does MTO interact with existing brand-specific conditional access and Terms of Use?
- Does MTO materially improve the Teams experience for the exact DCE/HTT collaboration patterns in use?

## Current decision

Defer implementation. Continue research and use this ADR as the decision matrix for leadership/security review. Re-open this decision no later than 2026-07-03, or earlier if Teams inventory, canary evidence, or cross-brand collaboration requirements materially change.
