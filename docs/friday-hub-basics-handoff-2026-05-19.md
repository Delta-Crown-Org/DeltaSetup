# Post-Friday SharePoint hub basics handoff — Tyler + Jamie

**Status:** Draft — not approval evidence  
**Tracking bead:** `DeltaSetup-2dq`  
**Audience:** Tyler Granlund, Jamie Baer  
**Purpose:** concise handoff of what exists, what is safe to touch, and what still needs a decision before production movement  
**Drafted:** 2026-05-19, following the Friday 2026-05-15 audit

## Short version

The Delta Crown SharePoint foundation already exists in DCE, so Friday follow-up work should focus on confirming the target location and content plan — not creating a second hub by accident. The recommended default is to keep DCE as primary unless there is a clear business reason to duplicate the hub in HTT.

## What is already live

### DCE tenant

The DCE Microsoft 365 environment already has the core SharePoint structure in place:

- Delta Crown Extensions Hub: `https://deltacrown.sharepoint.com/sites/dce-hub`
- DCE Document Center: `/sites/dce-docs`
- DCE Marketing: `/sites/dce-marketing`
- DCE Operations: `/sites/dce-operations`
- DCE Client Services legacy site: `/sites/dce-clientservices`
- Corporate Shared Services: `/sites/corp-hub`
- Corporate HR: `/sites/corp-hr`
- Corporate IT: `/sites/corp-it`
- Corporate Finance: `/sites/corp-finance`
- Corporate Training: `/sites/corp-training`

Business meaning: there is already a working SharePoint foundation to build from; the open question is whether DCE remains the primary location or HTT also needs a separate landing area.

Known cleanup item: two duplicate `Delta Crown Extensions` group sites still exist and are tracked separately.

### HTT tenant

HTT has a Teams-provisioned SharePoint site named `Delta Crown Operations`:

```text
https://httbrands.sharepoint.com/sites/msteams_7f6ca9
```

This may be an active collaboration site, an old test site, or an unused placeholder. We should confirm its purpose before anyone builds another HTT-side Delta Crown hub.

## What Jamie can safely prepare

Jamie can prepare branding/content inputs without changing production structure:

- final copy for hub sections;
- brand imagery and visual preferences;
- owner/staff-facing navigation labels;
- document library/folder naming preferences;
- list of content owners by section;
- launch-readiness questions and missing materials.

Recommended posture: content-first, structure-light. Avoid redesigning folders or permissions until the target location is confirmed.

## What not to touch yet

Do not do these without explicit approval:

- create a new HTT-side Delta Crown hub;
- delete or repurpose `msteams_7f6ca9`;
- promote DCE Hub content to production;
- promote CrownConnection-dev to live Crown Connection;
- send user-facing launch, welcome, or incident-related communications without approval;
- change DCE cross-tenant sync scope or remove the temporary admin access assignment.

## Access caveat from recent sync recovery work

Tyler's Delta Crown admin access has been restored and verified. A temporary access assignment is currently preserving the HTT-to-DCE sync path.

This should not be removed as routine cleanup. It needs to stay in place until the permanent ownership and sync-scope decision is documented.

Break-glass requirement: DCE should maintain a cloud-only, DCE-native Global Administrator that is not sourced from HTT cross-tenant sync. That account should be documented outside this public handoff and validated before any major promotion or identity change.

## Decisions Tyler/Jamie still need to make

### Decision 1 — Target tenant/path for Friday hub work

Choose one:

1. **DCE tenant is primary.** Continue building on `dce-hub`; HTT gets links/landing as needed.
2. **HTT tenant needs a separate Delta Crown hub.** Create/prepare an HTT-side hub, accepting duplication risk.
3. **Hybrid.** DCE remains source of truth; HTT gets a thin landing/redirect/collaboration surface.

Recommended default: DCE tenant is primary unless there is a specific business reason to duplicate in HTT.

### Decision 2 — Disposition of HTT `Delta Crown Operations`

Choose one:

- keep as HTT collaboration site;
- repurpose as HTT landing site;
- archive/retire after confirming no active dependency;
- leave untouched until Teams inventory is complete.

Recommended default: leave untouched until Teams inventory confirms purpose and usage.

### Decision 3 — Owner/content approval path

Before production promotion, capture:

- final approving owner;
- what page/content is approved;
- rollback owner;
- launch/comms decision.

## Suggested next working session agenda

1. Confirm DCE vs HTT vs hybrid target.
2. Review `msteams_7f6ca9` purpose.
3. Decide what Jamie populates this week vs what remains structural/governance work.
4. Confirm production promotion approval process for DCE Hub and Crown Connection.
5. Confirm second owner for DCE sync ownership resilience.

## Current blockers

- Teams/channel inventory is still blocked because we do not yet have access that can read the Teams structure.
- Production promotions require owner approval.
- Tyler needs to identify a second owner so sync access does not depend on one person.

## Clean handoff statement

> The DCE SharePoint foundation exists and is ready for content planning, pending the target-location and production-approval decisions. Before building or promoting anything else, we need to confirm whether DCE remains the primary hub location, decide what the HTT `Delta Crown Operations` Teams site is for, and preserve the current DCE sync access assignment until the permanent sync-scope decision is made.

Tyler/Jamie — please confirm the preferred DCE vs. HTT vs. hybrid direction before the next working session. If there is no business reason to duplicate the hub in HTT, the recommended path is to keep DCE as primary and use HTT only as a light landing or collaboration surface.
