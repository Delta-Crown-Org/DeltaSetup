# Master DCE Resource Map

## Purpose

This map translates the audited HTT Brands `Master DCE` source folder into a cleaner Delta Crown resource model.

It is a decision aid, not a migration instruction. Nothing in this document authorizes copying, moving, deleting, renaming, or repermissioning live content. The cleanup goblin still needs an owner-approved leash.

## Source evidence

Audit source:

```text
https://httbrands.sharepoint.com/sites/HTTHQ
Shared Documents / Master DCE
```

Evidence:

- `docs/master-dce-audit-findings.md`
- local raw audit outputs under `.local/reports/master-dce/`

Audit method:

- Microsoft Graph via existing HTT Azure CLI login
- read-only calls only
- no tenant writes
- no file operations
- no permission changes

## Target resource lanes

| Lane | Purpose |
|---|---|
| Operations | Active operating resources and status/workflow materials. |
| Brand Resources | Brand reference material, product info, playbooks, templates, and selected strategic/financial resources with role-based access. |
| Marketing | Campaign, creative, brand asset, and marketing execution materials. |
| Docs / Training | SOPs, training references, onboarding, and knowledge material. |
| Leadership / Finance Restricted | Strategy, financial, pro forma, and sensitive planning material. |
| Corporate Reference / Shortcut | HTT-owned or cross-brand materials that should likely remain in HTT and be referenced from Delta Crown. |
| Archive | Historical or deprecated content retained read-only after owner review. |
| Needs Owner Review | Content whose ownership, sensitivity, or target location cannot be decided from metadata alone. |

## Folder map

| Source item | Type | Audit signal | Recommended lane | Proposed action | Access posture | Owner decision needed |
|---|---|---|---|---|---|---|
| Operations | Folder | 9 direct files, 5 direct folders | Operations | Candidate for Delta Crown-owned operating resource area. | Operations staff / managers after verification. | Confirm current use and owner. |
| _Status | Folder | 2 direct files, 0 direct folders | Operations | Candidate status/reporting reference. | Restricted to users who need operational status visibility. | Confirm whether active or historical. |
| _Franchisees | Folder | 1 direct file, 4 direct folders | Operations / Franchise Resources | Candidate franchise resource area; do not expose broadly until reviewed. | Franchise/operations roles only after content review. | Confirm whether franchisee-facing, internal-only, or mixed. |
| DCE Marketing | Folder | 2 direct files, 13 direct folders | Marketing | Candidate for Marketing workspace or Brand Resources marketing lane. | Marketing owners/editors; broader read access only after review. | Confirm owner and whether campaign materials are current. |
| Product | Folder | 5 direct files, 2 direct folders | Brand Resources / Docs | Candidate brand/product reference area. | Read access for relevant staff; edit access for owners. | Confirm whether any material is confidential/vendor-controlled. |
| Training | Folder | 1 direct file, 0 direct folders | Docs / Training | Candidate training resource. | Staff read access if current; owner edit access. | Confirm whether material is Delta Crown-owned or HTT corporate-owned. |
| Strategy | Folder | 5 direct files, 0 direct folders | Leadership / Finance Restricted | Do not migrate or expose until leadership review. | Leadership restricted by default. | Confirm sensitivity, owner, and target location. |
| Financials & Proforma | Folder | 8 direct files, 3 direct folders | Leadership / Finance Restricted | Do not migrate or expose until finance review. | Finance/leadership restricted by default. | Confirm retention, sensitivity, and access model. |
| Fran Dev | Folder | 2 direct files, 6 direct folders | Needs Owner Review / Corporate Development | Hold for owner review before mapping. | Restricted until classified. | Confirm whether Delta Crown-owned, HTT corporate-owned, or development pipeline material. |
| Corp Docs | Folder | 1 direct file, 1 direct folder | Corporate Reference / Shortcut | Likely keep in HTT and reference from Delta Crown if needed. | HTT/corporate-controlled. | Confirm corporate ownership and shortcut need. |
| Real Estate & Construction | Folder | 1 direct file, 2 direct folders | Corporate Reference / Shortcut | Likely keep in HTT and reference from Delta Crown if needed. | HTT/corporate-controlled; possibly restricted. | Confirm ownership and whether Delta Crown needs read-only reference. |
| zArchive | Folder | 1 direct file, 0 direct folders | Archive | Keep read-only unless owner approves selected migration. | Restricted/archive access. | Confirm retention requirements. |
| DC - Letterhead.docx | File | Single top-level file | Brand Resources / Docs | Move only after owner approval into a clean folder/lane; do not leave as loose top-level content in target model. | Broad staff read may be appropriate after review. | Confirm whether current approved letterhead. |

## Recommended target shape

Do not recreate `Master DCE` exactly. Use the audit as source evidence and build a cleaner model:

```text
Hub
├── Operations
│   ├── Operating Resources
│   ├── Status / Reporting
│   └── Franchise Resources
├── Brand Resources
│   ├── Product
│   ├── Approved Templates
│   └── Selected Playbooks
├── Marketing
│   ├── Campaigns
│   ├── Creative Assets
│   └── Brand Materials
├── Docs / Training
│   ├── SOPs
│   ├── Training
│   └── Reference
├── Leadership / Finance Restricted
│   ├── Strategy
│   └── Financials & Proforma
├── Corporate Reference
│   ├── Corp Docs shortcut/reference
│   └── Real Estate & Construction shortcut/reference
└── Archive
    └── zArchive / retired material
```

## Decision rules

Use these rules before any migration or cleanup:

1. If content is Delta Crown-owned and actively used, map it into the Delta Crown tenant.
2. If content is HTT corporate-owned or cross-brand, leave it in HTT and expose a shortcut/reference only if needed.
3. If content is strategy, finance, pro forma, leadership, development, or construction-sensitive, restrict first and review with the owner.
4. If content is historical, archive rather than promoting it as a first-class resource.
5. If a folder mixes audiences or purposes, split it logically in the target model instead of preserving the messy source tree.
6. If the access model cannot be explained in one sentence, do not migrate yet.

## Immediate follow-up decisions

| Decision | Why it matters | Suggested owner |
|---|---|---|
| Confirm Operations and _Status current use. | Determines what can become active operating resources. | Operations lead |
| Confirm DCE Marketing owner and currency. | Determines Marketing workspace structure. | Marketing lead |
| Review Strategy and Financials sensitivity. | Prevents accidental overexposure. | Leadership / Finance |
| Classify Fran Dev. | Ambiguous ownership and likely sensitive pipeline/development material. | Leadership / Development owner |
| Confirm Corporate Reference shortcut approach. | Avoids duplicating HTT-owned resources into Delta Crown. | HTT / Delta Crown leadership |
| Confirm archive/retention posture. | Prevents promoting stale material. | Content owner / compliance |

## Showcase-safe wording

Safe:

> We audited the existing HTT Master DCE source folder and mapped its top-level contents into a cleaner Delta Crown resource model. Active operations, marketing, brand resources, training, corporate references, restricted leadership/finance material, and archive content are now separated conceptually before any migration or cleanup.

Not safe yet:

> Everything has been migrated.

Not safe yet:

> Permissions are cleaned up.

Not safe yet:

> Financials and strategy folders are broadly available.

## Completion criteria for this map

This map is complete enough to unblock the Brand Resources target model when:

- each top-level source item has a recommended lane;
- sensitive folders are explicitly restricted pending owner review;
- corporate-owned reference candidates are separated from Delta Crown-owned candidates;
- no migration or permission change is implied;
- owner decisions are listed for ambiguous items.
