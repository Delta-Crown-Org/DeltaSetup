# Brand Resources Target Model

## Purpose

Brand Resources is the Delta Crown area for brand reference material, product information, approved templates, selected playbooks, franchise support references, and other reusable operating/brand knowledge.

It replaces old `ClientServices` / `Client Experience` assumptions for this project because Delta Crown does **not** plan to store client records in Microsoft 365.

Plain version:

> Brand Resources is where staff find approved brand materials and reusable reference content. It is not a client database, CRM, booking system, or customer record store.

## Source evidence

This target model is based on:

- `docs/master-dce-audit-findings.md`
- `docs/master-dce-resource-map.md`
- `docs/team-showcase-readiness-checklist.md`

The source folder audited was:

```text
https://httbrands.sharepoint.com/sites/HTTHQ
Shared Documents / Master DCE
```

No content migration, permission change, or tenant cleanup is authorized by this document. This is a model and decision guide, not a yeet-the-files script.

## Core principles

1. **No client records** — client PII, service history, appointments, notes, or CRM-style records do not belong in Brand Resources.
2. **Clean names for humans** — use `Brand Resources`, not `DCE Brand Resources`, in user-facing navigation.
3. **Do not mirror the source mess** — do not recreate `Master DCE` 1:1 unless an owner explicitly requires it.
4. **Restrict sensitive content first** — strategy, finance, pro forma, development, and construction content stay restricted until owners approve the target access model.
5. **Shortcut corporate-owned content** — HTT-owned or cross-brand materials should usually remain in HTT and be referenced from Delta Crown instead of copied.
6. **Access by role, not folder accident** — permissions should be explainable in one sentence.
7. **Archive is not a pillar** — historical material should not become first-class navigation unless actively used.

## Intended audience

| Audience | Intended use |
|---|---|
| AllStaff | Find approved reference material, templates, and non-sensitive brand resources. |
| Managers | Use operating, franchise, and brand reference material for daily leadership. |
| Stylists | Access approved reference/training material that supports role-specific work. |
| Marketing | Maintain and publish approved brand/creative/campaign references. |
| Leadership | Review restricted strategy, financial, or planning resources. |
| Finance | Review restricted financial/pro forma material. |
| Corporate support | Reference or maintain HTT-owned cross-brand resources where approved. |

## Recommended target structure

This is the conceptual target shape. Actual SharePoint/Teams implementation depends on tenant inventory and owner approval.

```text
Brand Resources
├── Approved Templates
├── Product Reference
├── Brand Playbooks
├── Franchise Resources
├── Marketing Reference
├── Training Reference
├── Leadership Reference (restricted)
├── Finance Reference (restricted)
├── Corporate Reference Shortcuts
└── Archive Index
```

### Approved Templates

Purpose:

- approved reusable templates;
- letterhead;
- branded document shells;
- controlled staff-facing forms that are not client records.

Source candidates:

- `DC - Letterhead.docx`
- selected `Corp Docs` materials after owner review

Access:

- broad read access if approved;
- edit access limited to content owners.

Do not include:

- draft/unapproved templates;
- client intake forms containing submitted client data;
- stale marketing proofs pretending to be final.

### Product Reference

Purpose:

- product information;
- service/product reference docs;
- vendor/product context approved for internal use.

Source candidates:

- `Product`

Access:

- likely AllStaff or role-based read access;
- owner/editor access for product or operations leads.

Decision needed:

- confirm no vendor-confidential or restricted pricing material is mixed into this folder.

### Brand Playbooks

Purpose:

- reusable brand operating references;
- approved playbooks;
- brand standards that are not primarily marketing campaign assets.

Source candidates:

- selected `Strategy` material only after leadership review;
- selected `Operations` or `Product` material if it is reusable reference rather than daily workflow.

Access:

- managers and leadership by default;
- broader read access only after sensitivity review.

Decision needed:

- define the line between operational procedures and brand playbooks.

### Franchise Resources

Purpose:

- franchise support references;
- franchise-facing or franchise-management resources;
- approved internal franchise material.

Source candidates:

- `_Franchisees`
- selected `Fran Dev` material after owner classification

Access:

- restricted until reviewed;
- likely operations/managers/franchise support roles.

Decision needed:

- classify whether materials are franchisee-facing, internal-only, development pipeline, or mixed.

### Marketing Reference

Purpose:

- approved brand assets and marketing reference material that other teams need to find;
- links/shortcuts into the Marketing workspace where campaign execution happens.

Source candidates:

- selected `DCE Marketing` reference material

Access:

- read access for staff where appropriate;
- edit access for Marketing.

Relationship to Marketing:

- Campaign execution, working files, and active creative production belong in `Marketing`.
- Final approved brand references or reusable marketing standards may be surfaced in `Brand Resources`.

Do not include:

- active campaign production clutter;
- unapproved creative drafts;
- assets with licensing restrictions unless clearly labeled.

### Training Reference

Purpose:

- stable training references;
- role aids;
- onboarding resources that support brand/operations knowledge.

Source candidates:

- `Training`
- selected docs from `Operations` or `Product`

Access:

- broad staff read access if approved;
- owner/editor access for training/content owners.

Relationship to Training:

- Training delivery paths, curriculums, or learning workflows belong in `Training`.
- Reusable reference docs can be linked or surfaced in `Brand Resources`.

### Leadership Reference

Purpose:

- sensitive strategy materials;
- leadership-only planning references;
- selected strategic playbooks after review.

Source candidates:

- `Strategy`
- selected `Fran Dev` material

Access:

- leadership restricted by default.

Decision needed:

- confirm which items are current, historical, or too sensitive for Delta Crown tenant hosting.

### Finance Reference

Purpose:

- financial/pro forma reference material approved for Delta Crown hosting or shortcutting.

Source candidates:

- `Financials & Proforma`

Access:

- finance/leadership restricted by default.

Decision needed:

- confirm whether material should stay in HTT, be shortcut, be migrated, or be archived.

### Corporate Reference Shortcuts

Purpose:

- provide navigable references to HTT-owned or cross-brand resources without duplicating ownership.

Source candidates:

- `Corp Docs`
- `Real Estate & Construction`
- selected corporate-owned `Training` or `Financials & Proforma` material

Access:

- controlled by the source HTT location;
- Delta Crown should not weaken the original access model.

Implementation preference:

- shortcut/reference first;
- migration only if ownership and access model are clearly Delta Crown-specific.

### Archive Index

Purpose:

- make historical material discoverable without promoting it as active guidance.

Source candidates:

- `zArchive`
- stale content discovered during owner review

Access:

- restricted/read-only by default.

Do not include:

- archive content in primary navigation unless actively needed.

## What belongs in Brand Resources

| Content type | Belongs? | Notes |
|---|---|---|
| Approved brand templates | Yes | Staff-facing reusable materials. |
| Product reference docs | Yes | After confidentiality review. |
| Brand playbooks | Yes | If approved and current. |
| Franchise support references | Usually | Must classify audience first. |
| Final brand/marketing reference assets | Sometimes | Working campaign files belong in Marketing. |
| Training reference docs | Sometimes | Training programs/workflows belong in Training. |
| Strategy docs | Restricted only | Leadership review required. |
| Financial/pro forma docs | Restricted only | Finance review required. |
| Corporate-owned docs | Shortcut preferred | Do not duplicate ownership without approval. |
| Historical archive | Index only | Do not promote stale content. |

## What does not belong

Brand Resources must not contain:

- client records;
- client PII;
- appointment history;
- service notes;
- CRM exports;
- booking-system exports;
- client intake submissions;
- mailbox dumps;
- unapproved financial exports;
- app secrets, API keys, certificates, or credentials;
- live admin exports;
- raw permission CSVs;
- stale `ClientServices` artifacts presented as current client operations.

If any legacy ClientServices artifact appears to contain client data, stop and route it to cleanup/security review. Do not normalize it into Brand Resources. Bad data architecture does not become good data architecture by getting a nicer folder name.

## Relationship to other lanes

| Lane | Relationship to Brand Resources |
|---|---|
| Operations | Active day-to-day operating resources live in Operations; stable reusable references may be linked from Brand Resources. |
| Marketing | Marketing owns active campaigns and creative production; Brand Resources surfaces approved final/reference materials. |
| Docs | General documentation may live in Docs; brand-specific reusable materials can be grouped or linked from Brand Resources. |
| Training | Training owns learning workflows; Brand Resources can surface stable training references. |
| Leadership | Leadership owns restricted strategic materials; Brand Resources may include a restricted leadership reference area only if approved. |
| Finance | Finance owns restricted financial/pro forma material; Brand Resources may include a restricted finance reference area only if approved. |
| Corporate Reference | HTT-owned material should usually remain in HTT and be shortcut/reference-linked. |
| Archive | Archive preserves historical material; Brand Resources may include an index, not active guidance. |

## Ownership model

`Technical owner` means the Microsoft 365 administrator or SharePoint site owner responsible for the underlying site, library, navigation, and permissions.

Every Brand Resources section needs:

- a business owner;
- a technical owner;
- an access model;
- a review cadence;
- a stale-content decision rule.

Recommended starting ownership:

| Section | Business owner | Technical owner | Review cadence |
|---|---|---|---|
| Approved Templates | Operations / Brand owner | M365 admin / site owner | Quarterly |
| Product Reference | Operations / Product owner | M365 admin / site owner | Quarterly |
| Brand Playbooks | Leadership / Operations | M365 admin / site owner | Quarterly |
| Franchise Resources | Operations / Franchise owner | M365 admin / site owner | Quarterly |
| Marketing Reference | Marketing | M365 admin / site owner | Monthly or campaign-close |
| Training Reference | Training / Operations | M365 admin / site owner | Quarterly |
| Leadership Reference | Leadership | M365 admin / site owner | As needed / restricted review |
| Finance Reference | Finance / Leadership | M365 admin / site owner | As needed / restricted review |
| Corporate Reference Shortcuts | HTT / Delta Crown leadership | M365 admin / site owner | Semiannual |
| Archive Index | Content owner / compliance | M365 admin / site owner | Annual |

## Access model

Default access posture:

| Area | Default access |
|---|---|
| Approved Templates | AllStaff read, owners edit after approval. |
| Product Reference | Role-based or AllStaff read after confidentiality review. |
| Brand Playbooks | Managers/Leadership read by default; broader only if approved. |
| Franchise Resources | Restricted until classified. |
| Marketing Reference | AllStaff read for approved assets; Marketing edit. |
| Training Reference | AllStaff or role-based read; owners edit. |
| Leadership Reference | Leadership restricted. |
| Finance Reference | Finance/Leadership restricted. |
| Corporate Reference Shortcuts | Source-system permissions apply. |
| Archive Index | Restricted/read-only. |

Access implementation should prefer group-based permissions. Avoid giving access to individual people instead of groups unless there is a documented exception.

Suggested groups/roles to validate during tenant inventory:

- AllStaff
- Managers
- Stylists
- Marketing
- Leadership
- Finance, if present or needed
- Operations managers/franchise support, if present or needed

## Implementation options

The tenant inventory (our review of what currently exists in the Delta Crown Microsoft 365 environment) should decide which option is safest:

| Option | Use when | Pros | Risks |
|---|---|---|---|
| Repurpose existing legacy resource | Existing ClientServices resource is empty/low-risk and technically suitable. | Faster; less new infrastructure. | May preserve confusing old names/URLs/permissions. |
| Create a new Brand Resources site/library | Legacy resource is messy, misnamed, or permission-risky. | Clean information architecture. | Requires setting up new site infrastructure and planning content moves or shortcuts. |
| Use shortcuts/references only | Content remains HTT-owned/cross-brand. | Avoids duplicating ownership. | Depends on source permissions between the HTT and Delta Crown Microsoft 365 environments. |
| Hybrid | Some content is Delta Crown-owned, some stays HTT-owned. | Most realistic. | Requires clear navigation and ownership labels. |

Recommended default:

> Use a clean Brand Resources model and only repurpose legacy ClientServices artifacts if inventory proves they are safe, understandable, and not carrying stale client-record assumptions.

## Migration readiness gates

Before any content is moved, copied, shortcut, deleted, renamed, or repermissioned:

- [ ] Tenant inventory confirms the current Brand Resources / ClientServices technical state.
- [ ] Owner approves the source-to-target mapping.
- [ ] Sensitive folders have explicit restricted access models.
- [ ] Corporate-owned content is marked shortcut/reference unless ownership transfers.
- [ ] Archive content is marked read-only or excluded from primary navigation.
- [ ] No client records/client PII are included.
- [ ] A plan exists to undo changes and verify results if something goes wrong.
- [ ] A tracked change request exists for the actual Microsoft 365 operation.

## Showcase-safe wording

Safe:

> Brand Resources is the target lane for approved brand reference materials, templates, product information, selected playbooks, and reviewed franchise resources. It replaces old ClientServices assumptions because client records are not stored in Microsoft 365.

Safe:

> Some content may move into Delta Crown, while HTT-owned resources may remain in HTT and appear as shortcuts or references.

Careful:

> Strategy and financial materials are mapped as restricted pending owner review.

Not safe:

> Brand Resources is fully migrated and production-ready.

Not safe:

> ClientServices can just be renamed to Brand Resources.

Not safe:

> Everyone can access all brand resources.

## Decisions still needed

| Decision | Why it matters | Blocks |
|---|---|---|
| Whether to repurpose or replace legacy ClientServices resources. | Determines cleanup path and technical target. | ClientServices cleanup register. |
| Whether Product is broad-read or role-restricted. | Prevents accidental exposure of confidential/vendor material. | Access model. |
| Whether Strategy belongs in Delta Crown or remains HTT/leadership-only. | Prevents strategic overexposure. | Leadership reference implementation. |
| Whether Financials & Proforma stays in HTT, shortcuts, or migrates restricted. | Prevents finance-sensitive overexposure. | Finance reference implementation. |
| How Fran Dev should be classified. | Development material may be sensitive or corporate-owned. | Franchise/corporate development model. |
| Which DCE Marketing materials are final reference vs working campaign files. | Keeps Brand Resources from becoming a messy Marketing clone. | Marketing relationship. |
| Whether Corporate Reference shortcuts are enough. | Avoids duplicating HTT-owned resources. | Navigation and ownership. |

## Completion criteria

This model is complete when it can be used to create the legacy ClientServices cleanup register and tenant implementation plan without inventing more scope.

Specifically:

- Brand Resources purpose is clear.
- Client records are explicitly out of scope.
- Content categories are defined.
- Sensitive categories are restricted by default.
- Corporate reference handling is defined.
- Relationship to Operations, Marketing, Docs, Training, Leadership, and Archive is defined.
- Repurpose-vs-replace decision rules are documented.
- Migration readiness gates are explicit.
