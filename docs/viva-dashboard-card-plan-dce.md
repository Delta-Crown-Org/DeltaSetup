# DCE Viva Connections dashboard card plan

**Status:** Draft — plan only, not approval evidence  
**Tracking bead:** `DeltaSetup-hyq`  
**Deployment state:** no Viva dashboard changes authorized

## Purpose

Define candidate Viva Connections dashboard cards for Delta Crown Extensions. This is planning only; card deployment requires approved destinations, audiences, and owners.

## Card candidates

| Card | Draft label | Destination | Audience | Owner | Status |
|---|---|---|---|---|---|
| Crown Connection | Crown Connection | Crown Connection page | Owners/franchisor | TBD | Approval-gated |
| Brand Resources | Brand Resources | DCE Hub brand/resources area | Staff/owners? | Jamie/Jenna TBD | Needs destination |
| Operations | Operations | DCE Operations site/library | Staff | TBD | Needs validation |
| Training | Training | Training system/link TBD | Staff/owners? | TBD | Blocked on source decision |
| Submit Request | Submit Request | Intake route TBD | Staff | TBD | Needs route |
| Help / Support | Help & Support | Support/contact route TBD | Staff | TBD | Needs route |
| Corporate Services | HR / IT / Finance | Corporate services hub/sites | Staff | TBD | Needs contact paths |

## Recommended card details

### Crown Connection

Label:

> Crown Connection

Description:

> Owner updates, franchisor questions, and owner-facing resources.

Audience:

- franchise owners;
- franchisor leadership;
- approved support users.

Gate:

- Crown Connection promotion approval;
- audience validation;
- link validation.

### Brand Resources

Label:

> Brand Resources

Description:

> Approved logos, imagery, voice, and marketing materials.

Audience:

- staff;
- owners, if approved.

Gate:

- final resource destination;
- content owner.

### Operations

Label:

> Operations

Description:

> Operating resources, checklists, and escalation paths.

Audience:

- DCE staff;
- managers/owners as approved.

Gate:

- operations content owner;
- approved destination.

### Training

Label:

> Training

Description:

> Training paths, certifications, and onboarding resources.

Audience:

- staff;
- owners, if approved.

Gate:

- training source-of-truth decision.

### Submit Request

Label:

> Submit Request

Description:

> Send access, content, or resource requests to the right owner.

Audience:

- staff;
- possibly owners.

Gate:

- approved intake route.

## Card design rules

- Use short labels; avoid “click here” nonsense.
- Every card must have a single owner.
- Every destination must be tested before deployment.
- Audience targeting must match the page/library permissions.
- Do not use Viva cards to expose owner-only resources to all staff.
- Do not deploy cards until DCE Hub/Crown Connection production direction is approved.

## Open questions

1. Should Crown Connection appear for all staff or only owner/franchisor audiences?
2. What is the approved request/intake route?
3. What is the training system of record?
4. Who owns card updates after launch?
5. Should cards be grouped by role/persona or by function?

## Deployment gate

Before deployment:

- [ ] card labels approved;
- [ ] destinations approved and tested;
- [ ] audiences approved;
- [ ] owners assigned;
- [ ] DCE Hub/Crown Connection production posture confirmed;
- [ ] no Teams dependency remains unresolved for Teams-linked cards;
- [ ] approval captured in `bd`.
