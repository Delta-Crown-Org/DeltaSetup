# ClientServices to Brand Resources Transition Plan

## Purpose

This plan defines how Delta Crown should move from legacy `ClientServices` / client-record assumptions toward the approved `Brand Resources` model.

It does not authorize live tenant changes. It exists so docs, tests, templates, and future tenant cleanup can be updated in the right order without accidentally preserving stale client-record architecture.

Plain version:

> Stop treating ClientServices as a Microsoft 365 client-record area. Use Brand Resources for approved brand reference material. Inventory anything live before changing it.

## Inputs

This plan depends on:

- `docs/master-dce-audit-findings.md`
- `docs/master-dce-resource-map.md`
- `docs/brand-resources-target-model.md`
- `docs/legacy-clientservices-cleanup-register.md`
- `docs/tenant-inventory-access-matrix.md`

## Current position

The project repository (repo) contains old ClientServices assumptions in deployment docs, onboarding models, templates, and tests. Those assumptions include:

- `/sites/dce-clientservices`
- `DCE-ClientServices`
- `Client Services`
- `Client Records`
- `Service History`
- `Feedback`
- `Consent Forms`
- PII (personally identifiable information) / client-record test assertions

The current approved direction is different:

- Client records are out of Microsoft 365 scope.
- Brand Resources is the replacement concept for reusable approved reference material.
- Sensitive Strategy/Financials/Fran Dev content stays restricted pending owner review.
- Corporate-owned HTT material should usually remain in HTT and be referenced from Delta Crown.
- No live resource should be renamed, deleted, moved, copied, or repermissioned until inventory and owner approval are complete.

## Target state

Future-facing docs, tests, templates, and implementation plans should point to this model:

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

Client records, CRM exports, appointment/service history, client intake submissions, and consent submissions do not belong in Brand Resources.

## Transition principles

1. **Preserve historical docs as historical** — do not silently rewrite old status/runbook artifacts as if they never existed.
2. **Update future-facing docs first** — current-state and readiness docs should use Brand Resources language.
3. **Inventory before changing live resources** — especially `/sites/dce-clientservices`, `DCE-ClientServices`, and any client-record-style lists.
4. **Do not open or export client data** — inventory metadata, field names, structure, and permissions only; rely on owner attestation for content classification.
5. **Tests follow architecture decisions** — update architecture tests only after the Brand Resources implementation option is chosen.
6. **Scripts stay gated** — do not run setup/provisioning scripts (automated tools that create tenant resources) that create ClientServices artifacts until they are reviewed or replaced.

## Repurpose strategy by item type

| Item type | Examples | Transition action | When to do it |
|---|---|---|---|
| Historical deployment docs | `DEPLOYMENT-STATUS.md`, old Phase 2/3 handoffs | Add historical/deprecated notes rather than silently rewriting. | Repo-only cleanup pass after inventory confirms what remains live. |
| Active/future runbooks | `DEPLOYMENT-RUNBOOK.md`, future showcase docs | Replace ClientServices/client-record language with Brand Resources model. | After tenant inventory confirms implementation path. |
| Onboarding/access docs | role/location model, attribute/group matrix | Replace `ClientServices` role/group assumptions with Brand Resources/resource-specific groups. | After identity/group inventory. |
| Templates | `templates/dce-user-access-matrix-template.csv` | Remove `ClientServices` example metadata; use Brand Resources or another approved role. | After group naming decision. |
| Architecture tests | ADR-002 (architecture decision record) tests, Phase 3 tests | Supersede or update tests so automated checks validate Brand Resources, not client-record lists. | After new architecture decision / implementation issue. |
| Public/showcase copy | `index.html`, `presentation/index.html` | Avoid implying client records live in M365; use generic risk wording. | Can be reviewed earlier if public story needs tightening. |
| Provisioning scripts/configs | Phase 3 scripts/configs | Review before any run; block scripts that create client-record lists. | Before any future tenant provisioning. |
| Live tenant resources | `/sites/dce-clientservices`, `DCE-ClientServices`, Client Records lists | Metadata-only inventory first; then owner-approved archive/replace/repurpose plan. | During tenant inventory and cleanup roadmap. |

## Proposed replacement vocabulary

| Legacy term | Replacement / handling |
|---|---|
| `ClientServices` role | Avoid. Use `BrandResources`, `Operations`, `Marketing`, `Leadership`, `Finance`, or explicit resource group depending on purpose. |
| `DCE-ClientServices` group | Do not reuse blindly. Inventory first; likely supersede with Brand Resources/resource-specific group. |
| `Client Services` navigation/page | Replace future-facing navigation with `Brand Resources` if intent is approved reference material. |
| `/sites/dce-clientservices` | Inventory first; prefer deprecate/archive or replace unless proven empty/low-risk and approved for repurpose. |
| `Client Records` list | Out of Microsoft 365 scope. Metadata-only inventory; route to security/data owner if present. |
| `Service History` list | Out of scope if client-specific. Metadata-only inventory; route to security/data owner if present. |
| `Feedback` list | Metadata, field names, structure, and permission inventory only; owner attestation required before classification. |
| `Consent Forms` library | Metadata, field names, structure, and permission inventory only; submitted client consent records are not Brand Resources. |
| `Client Experience` | Avoid unless referring to external/customer systems outside this M365 model. |

## Proposed Brand Resources groups

Do not create these yet. Validate through tenant inventory first.

| Proposed group | Purpose | Notes |
|---|---|---|
| `BrandResources-Owners` | Owners/editors for Brand Resources site/library. | Could be M365 group/site owners or security group. |
| `BrandResources-Readers` | Broad read access to approved non-sensitive material. | May map to `AllStaff` if appropriate. |
| `BrandResources-MarketingEditors` | Edit approved marketing reference assets. | Could map to existing Marketing group. |
| `BrandResources-FranchiseRestricted` | Restricted franchise/development resource access. | Owner review required. |
| `BrandResources-LeadershipRestricted` | Restricted strategy/playbook access. | Leadership only. |
| `BrandResources-FinanceRestricted` | Restricted finance/pro forma access. | Finance/leadership only. |

Prefer group-based permissions. Avoid direct person-by-person access unless there is a documented exception.

## Implementation options

The tenant inventory (our review of what currently exists in the Delta Crown Microsoft 365 environment) should decide which path is safest.

| Option | Description | Use when | Not acceptable when |
|---|---|---|---|
| Replace | Create a clean Brand Resources destination and deprecate old ClientServices artifacts. | Legacy site/group/list structure is confusing or risky. | Tenant cannot support new destination yet. |
| Repurpose | Reuse an existing ClientServices resource as Brand Resources. | It is empty/low-risk, permissions are clean, and owner approves the URL/name tradeoff. | Any client data, confusing URL, or unexplainable permissions exist. |
| Archive | Freeze old ClientServices resources read-only or remove from navigation. | Content is historical but must be retained. | Active workflows still depend on it. |
| Shortcut/reference | Keep HTT-owned material in HTT and link from Delta Crown. | Ownership remains corporate/cross-brand. | Shortcut weakens access controls or confuses owners. |
| Remove | Delete stale artifacts. | Inventory proves no content/dependency/data risk and owner approves. | Anything contains client data, sensitive content, or unknown dependencies. |

Recommended default:

> Prefer a clean Brand Resources target and archive/deprecate old ClientServices artifacts unless inventory proves repurpose is safe.

## Metadata-only tenant inventory requirements

Before any live cleanup, collect only metadata needed for decisions:

| Resource | Metadata to collect | Do not collect |
|---|---|---|
| `/sites/dce-clientservices` | existence, URL, title, owners, template, hub, sharing setting, libraries/lists names, permission summary | file contents, list items, client records, submitted forms |
| `DCE-ClientServices` group | existence, type, owners, membership count, dynamic rule (auto-membership criteria) if any | unnecessary full user exports beyond approved inventory scope |
| `Client Records` list | existence, field names/structure, item count, permissions, owner attestation | list item contents, client names, PII |
| `Service History` list | existence, field names/structure, item count, permissions, owner attestation | service record contents, client names, PII |
| `Feedback` list | existence, field names/structure, item count, permissions, owner attestation | feedback item contents, client names, PII |
| `Consent Forms` library | existence, field names/structure, item count, permissions, owner attestation | submitted forms, signed consent files, client PII |
| Phase 3 scripts/configs | whether they create ClientServices/client-record artifacts | executing scripts against tenant |

If client data may exist, stop at metadata and route to data owner/security review.

## Repo cleanup sequence

The following sections detail work inside the project repository. They are primarily for the technical team, but they explain why some old files should not be edited until tenant evidence exists.

### Step 1 — Add current-state transition docs

Completed by this plan and the cleanup register.

Outputs:

- `docs/brand-resources-target-model.md`
- `docs/legacy-clientservices-cleanup-register.md`
- `docs/clientservices-to-brand-resources-transition-plan.md`

### Step 2 — Inventory live tenant state

Required issues:

- `DeltaSetup-132` — identity/groups
- `DeltaSetup-133` — SharePoint/OneDrive
- `DeltaSetup-135` — Exchange mail resources
- `DeltaSetup-136` — security/apps/licenses
- `DeltaSetup-137` — consolidated inventory report

### Step 3 — Decide implementation option

Owner decision required:

- new Brand Resources resource;
- repurpose legacy resource;
- archive/deprecate legacy resource;
- shortcut/reference only;
- hybrid.

### Step 4 — Update docs/templates/tests

After Step 3:

- update future-facing deployment docs;
- update onboarding/access model docs;
- update user access matrix template;
- update or supersede ADR-002 (architecture decision record) / Phase 3 tests;
- add deprecation notes to historical docs.

### Step 5 — Tenant cleanup under change control

Only after inventory, owner approval, and rollback/validation plan:

- hide/deprecate old navigation;
- archive old site/list/library if needed;
- create/repurpose Brand Resources destination;
- apply group-based permissions;
- validate no client data was moved into Brand Resources.

## Safe repo edits now

These are safe now because they document direction and do not modify live tenant behavior:

- create this transition plan;
- keep cleanup register updated;
- update readiness/showcase docs to use Brand Resources wording;
- add warnings to future runbooks not to run old ClientServices provisioning blindly.

## Repo edits to defer

Defer these until tenant inventory and implementation decision:

- changing architecture tests that currently encode ClientServices;
- changing provisioning scripts/configs;
- rewriting historical deployment status as if the old model never existed;
- changing onboarding dynamic group recommendations;
- changing templates that might still reflect current live tenant state.

## Tenant actions explicitly prohibited by this plan

Do not:

- rename `/sites/dce-clientservices`;
- delete `/sites/dce-clientservices`;
- open/export Client Records, Service History, Feedback, or Consent Forms contents;
- change `DCE-ClientServices` membership or dynamic rules;
- move/copy Master DCE content into Delta Crown;
- broaden access to Strategy, Financials, Fran Dev, or franchise material;
- run old provisioning scripts that create ClientServices artifacts;
- create client records in Microsoft 365.

## Decision log template

Use this once tenant inventory is complete:

| Decision | Selected option | Evidence | Owner approval | Follow-up issue |
|---|---|---|---|---|
| ClientServices site future | TBD | Tenant inventory | TBD | TBD |
| ClientServices group future | TBD | Identity/group inventory | TBD | TBD |
| Client-record-style lists future | TBD | Metadata-only inventory + owner attestation | TBD | TBD |
| Brand Resources destination | TBD | SharePoint inventory + owner decision | TBD | TBD |
| Repo tests/docs cleanup | TBD | Implementation decision | TBD | TBD |

## Completion criteria

This transition plan is complete when it clearly states:

- old ClientServices/client-record assumptions are deprecated for the current model;
- Brand Resources is the replacement direction for approved reference material;
- live tenant cleanup must wait for inventory and owner approval;
- client data must not be opened/exported/migrated into Brand Resources;
- repo docs/templates/tests should be updated only in the correct order;
- provisioning scripts must not be rerun blindly.
