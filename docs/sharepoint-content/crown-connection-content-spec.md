# Crown Connection content spec

**Status:** Draft — not approval evidence  
**Tracking bead:** `DeltaSetup-b0f`  
**Source reference:** `dce-mockup/crown-connection.html`  
**Promotion state:** readiness only; live page is not a sandbox

## Page purpose

Crown Connection is the owner/franchisor collaboration surface for Delta Crown Extensions.

Recommended positioning:

> A private owner-facing space for updates, questions, resources, and franchisor communication.

## Audience posture

Primary audience:

- franchise owners;
- franchisor leadership;
- approved HTT/DCE corporate support users.

Not intended as:

- general staff hub;
- public marketing site;
- broad file dump;
- replacement for DCE Hub.

## Hero section

### Current mockup copy

Eyebrow:

> Crown Connection

Title:

> Where DCE owners and HTT franchisor meet.

Subtitle:

> A private space for franchise owners and HTT corporate leadership. Conversation moderated by Tyler & Jenna. Threads escalate to the Teams channel below.

### Recommended production-safe draft

Eyebrow:

> Crown Connection

Title:

> Your owner connection point for Delta Crown.

Subtitle:

> Find owner updates, key resources, and approved franchisor communication in one private space.

Primary CTA:

> Ask the Franchisor

Secondary CTA:

> View owner resources

## Pinned announcement

Current mockup announcement is brand-refresh specific and should not go live without approval.

Recommended placeholder until approved:

Title:

> Welcome to Crown Connection

Summary:

> This private space is for owner-facing updates, key resources, and questions for the franchisor team. Final launch content will be published after approval.

Author line:

> Delta Crown Extensions

## Quick actions

Recommended first-pass actions:

| Label | Destination | Audience | Status |
|---|---|---|---|
| Documents | Crown Connection documents | Owners/franchisor | Needs validation |
| Calendar | Group/site calendar | Owners/franchisor | Needs source confirmation |
| Ask the Franchisor | Form/list/intake route | Owners/franchisor | Needs route approval |
| Owner Library | Owner resource library | Owners only | Needs permission validation |

## Document hub cards

Current mockup cards:

- SOP
- Brand
- HR
- Marketing
- Operations

Recommended refinement:

| Card | Draft description | Owner | Audience |
|---|---|---|---|
| Owner Library | Owner-facing resources and approved reference materials. | TBD | Owners |
| Brand Updates | Approved brand announcements and launch materials. | Jamie/Jenna TBD | Owners/franchisor |
| Operations | Owner-facing operating guidance and escalation paths. | TBD | Owners/franchisor |
| Marketing | Campaign launch kits and approved local marketing materials. | TBD | Owners |
| Forms / Requests | Submit questions or requests to the franchisor team. | TBD | Owners/franchisor |

## Ask the Franchisor

Current mockup uses a form concept. Keep the concept, but final implementation needs a source of truth.

Implementation options:

- Microsoft Forms;
- SharePoint list with form view;
- existing ticket/intake system;
- curated email/shared mailbox;
- Teams Q&A workflow.

Recommended draft copy:

> Submit a question or request for the franchisor team. Questions will be reviewed and routed to the right owner before a response is published or shared.

Needed decisions:

- intake mechanism;
- who triages;
- expected response time;
- whether questions are private or visible to all owners;
- whether Teams is involved.

## Teams/channel section

The mockup includes a moderated Teams channel embed concept. This should not be treated as production-ready.

Reasons:

- Teams inventory is still blocked.
- Channel moderation behavior requires empirical canary before production use.
- SharePoint does not have a simple first-party “embed moderated channel” pattern that matches the mockup.

Recommended production-safe approach:

- Use a link to Teams only after Teams/channel model is approved.
- Keep the page copy neutral:

> Owner discussions may be supported through Teams after the channel model and moderation approach are approved.

## HTT corporate collateral

Current mockup includes HTT corporate collateral visible to owners and HTT corporate users.

This should be approval-gated because it affects cross-tenant visibility.

Needed decisions:

- which HTT corporate users should see the section;
- which materials are owner-facing;
- whether materials belong in Crown Connection or DCE Hub;
- who owns updates.

## Production-readiness checklist for this page

- [ ] Hero copy approved.
- [ ] Pinned announcement approved.
- [ ] Quick action destinations tested.
- [ ] Document cards approved.
- [ ] Owner Library permissions validated.
- [ ] Ask the Franchisor intake route approved.
- [ ] Teams section either removed, linked, or approved after Teams inventory/canary.
- [ ] HTT corporate collateral visibility approved.
- [ ] Rollback/export captured.
- [ ] Class 3 DCE SyncFabric bridge drift alerting live.
- [ ] Owner approval captured in `bd`.

## Explicit non-goals

- Do not promote this page from dev to live without approval.
- Do not use live Crown Connection as a sandbox.
- Do not create Teams/channel changes from this page spec.
- Do not send launch communications from this page spec.
