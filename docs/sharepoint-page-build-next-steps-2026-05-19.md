# SharePoint page build next steps — 2026-05-19

**Status:** Draft — not approval evidence  
**Tracking beads:** `DeltaSetup-2dq`, `DeltaSetup-3vu`, `DeltaSetup-b0f`, `DeltaSetup-hyq`, `DeltaSetup-9bo`  
**Default assumption:** DCE tenant remains the primary Delta Crown SharePoint location unless Tyler/Jamie approve an HTT-side duplicate or hybrid model.

## Build rules

1. Build content and templates before production promotion.
2. Do not create a new HTT-side Delta Crown hub unless explicitly approved.
3. Do not promote DCE Hub or Crown Connection content until owner approval is captured in `bd`.
4. Do not run production promotions until Class 3 DCE SyncFabric bridge drift alerting is live, not dry-run.
5. Keep raw tenant evidence, break-glass details, and concrete identity IDs out of public docs.

## Workstream 1 — DCE Hub page content backlog

**Primary bead:** `DeltaSetup-3vu`  
**Current mode:** readiness/content build only

### Page: DCE Hub Home

Buildable now:

- Hero/title copy.
- Short purpose statement.
- Quick links section.
- Department/resource cards.
- Help/contact section.
- Content-owner map by section.

Needs owner/Jamie input:

- final hero wording;
- exact quick-link destinations;
- approved brand imagery;
- final department labels;
- which links are staff-wide vs owner-only.

Promotion gate:

- owner approval in `bd`;
- live Class 3 bridge drift alerting;
- rollback export/copy.

### Page/section: Operations

Buildable now:

- section intro copy;
- placeholders for operating manuals, SOPs, store-opening resources, escalation paths;
- candidate links from existing DCE operations/library structure.

Needs input:

- authoritative owner for operations content;
- which docs are current vs legacy;
- whether any operations content is owner-facing only.

### Page/section: Marketing

Buildable now:

- section intro copy;
- brand assets callout;
- campaign/materials placeholders.

Needs input:

- final brand asset location;
- owner for marketing materials;
- visibility rules for internal vs owner-facing assets.

### Page/section: Training

Buildable now:

- section intro copy;
- training-path placeholders;
- link placeholders to LMS/WiseTail/HTT Beauty University if applicable.

Needs input:

- final training system of record;
- which links are approved for DCE staff;
- whether franchise owners should see training links from Crown Connection instead.

### Page/section: Finance / HR / IT / Corporate Services

Buildable now:

- service-card structure;
- plain-English descriptions;
- support/contact placeholders.

Needs input:

- service owners;
- approved intake/contact routes;
- confidentiality/audience requirements.

## Workstream 2 — Crown Connection owner page backlog

**Primary bead:** `DeltaSetup-b0f`  
**Current mode:** readiness only; live page is not sandbox

Buildable now:

- finalize dev page copy candidates;
- prepare source/destination/rollback record;
- validate owner-facing navigation labels;
- prepare screenshot and link QA checklist.

Needs approval:

- owner/content approval for exact promoted page;
- live destination confirmation;
- launch/comms decision.

Promotion gate:

- owner approval in `bd`;
- permission/audience validation;
- live Class 3 bridge drift alerting;
- rollback copy/export.

## Workstream 3 — Jamie content input packet

**Primary bead:** `DeltaSetup-2dq`

Jamie can safely prepare:

- final copy by section;
- approved imagery/logo preferences;
- quick-link labels and destinations;
- owner/staff-facing navigation labels;
- section content owners;
- documents that are ready to link;
- documents that should stay hidden until launch;
- questions for Tyler/Jenna/Meg/Erica.

Recommended packet format:

| Section | Final copy? | Link destination | Content owner | Audience | Notes |
|---|---:|---|---|---|---|
| Home hero | No | n/a | Jamie/Tyler | Staff | Need final wording |
| Operations | No | TBD | TBD | Staff/owners? | Need current docs |
| Marketing | No | TBD | TBD | Staff/owners? | Need brand asset source |
| Training | No | TBD | TBD | Staff/owners? | Confirm LMS path |
| Crown Connection | No | TBD | Tyler/Jamie | Owners | Approval-gated |

## Workstream 4 — Viva Connections dashboard planning

**Primary bead:** `DeltaSetup-hyq`  
**Current mode:** plan only

Candidate cards:

| Card | Audience | Destination | Owner | Status |
|---|---|---|---|---|
| Crown Connection | Owners | Crown Connection page | TBD | Needs approval |
| Brand Resources | Staff | DCE Hub / Brand Resources | TBD | Draft |
| Operations | Staff | DCE Operations | TBD | Draft |
| Training | Staff/owners | Training destination TBD | TBD | Blocked on LMS/source decision |
| Help / Support | Staff | Intake/contact route TBD | TBD | Draft |
| Finance / HR / IT | Staff | Corporate service sites | TBD | Draft |

Do not deploy Viva cards until card destinations and audiences are approved.

## Workstream 5 — Brand template parameterization

**Primary bead:** `DeltaSetup-9bo`  
**Current mode:** design/spec only

Extract these parameters from DCE/Crown patterns:

| Parameter | DCE value | Future brand value |
|---|---|---|
| Brand name | Delta Crown Extensions | TBD |
| Primary hub URL | DCE Hub | TBD |
| Owner/community page | Crown Connection | TBD |
| Logo asset | DCE logo | TBD |
| Primary color tokens | DCE royal/gold | TBD |
| Audience groups | DCE staff/owners | TBD |
| Support/contact path | TBD | TBD |
| Key resource cards | Operations, Marketing, Training, Corporate Services | TBD |

Goal: make future TLL/BCC/Frenchies/Bishops spoke pages configurable instead of copy-paste nonsense. Copy-paste is a gateway drug to entropy.

## Immediate next actions

1. Ask Tyler/Jamie to confirm DCE primary vs HTT duplicate vs hybrid.
2. Ask Jamie for final copy/link/content-owner input using the packet table above.
3. Fill DCE Hub Home content blocks from approved inputs.
4. Prepare Crown Connection dev source/version/rollback record.
5. Turn Class 3 bridge drift alerting live before any production promotion.
6. Only then promote DCE Hub or Crown Connection after explicit approval.
