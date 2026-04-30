# Legacy ClientServices Cleanup Register

## Purpose

This register tracks legacy `ClientServices`, `Client Services`, `Client Experience`, and client-record assumptions that no longer match the Delta Crown Microsoft 365 direction.

The current direction is:

> Brand Resources replaces old ClientServices assumptions for this project. Delta Crown does not plan to store client records in Microsoft 365.

This register does **not** authorize tenant changes. It identifies what needs review, documentation cleanup, test updates, or owner-approved tenant cleanup later.

## Source documents

This register is based on:

- `docs/brand-resources-target-model.md`
- `docs/master-dce-resource-map.md`
- `docs/team-showcase-readiness-checklist.md`
- repository grep for legacy ClientServices/client-record references

## Cleanup status legend

| Status | Meaning |
|---|---|
| Safe repo edit | Can likely be changed in docs/tests after confirming intent. |
| Needs tenant inventory | Must verify live tenant state before changing docs/scripts/tests. |
| Needs owner approval | Business/data owner must approve future state. |
| Do not change yet | Leave as-is until downstream dependencies are ready. |
| Remove/replace later | Should be replaced with Brand Resources model in a planned cleanup PR. |

## Register

| ID | Artifact | Current legacy assumption | Risk | Proposed future state | Impact type | Safe-to-change now? | Approval needed |
|---|---|---|---|---|---|---|---|
| CS-001 | `DEPLOYMENT-STATUS.md` | Lists `dce-clientservices` as deployed team site with `Consent Forms`, `Client Records`, `Service Catalog`, `Feedback`. | Implies M365 stores client records; conflicts with current scope. | Mark historical/deployment-era assumption; replace future-facing references with Brand Resources after tenant inventory. | Repo docs | Not yet | Tyler / technical owner |
| CS-002 | `DEPLOYMENT-RUNBOOK.md` | Describes `dce-clientservices` and SharePoint lists including `Client Records`, `Service History`, and client PII. | High compliance/story risk if reused as current runbook. | Add deprecation note or replace with Brand Resources implementation runbook after inventory. | Repo docs / future tenant ops | Not yet | Tyler / security/data owner |
| CS-003 | `docs/onboarding/dce-role-location-onboarding-model.md` | Uses `ClientServices` as a canonical business role and maps `/sites/dce-clientservices` to `DCE-ClientServices`. | Keeps identity model pointed at stale client-service resource. | Replace future model with `BrandResources` or explicit resource roles after tenant inventory. | Repo docs / identity model | Not yet | Tyler / identity owner |
| CS-004 | `docs/onboarding/dce-attribute-group-resource-matrix.md` | Uses `ClientServices` in `extensionAttribute1`, `DCE-ClientServices`, and `/sites/dce-clientservices`; notes broad `AllStaff = Contribute`. | Broad access + stale naming + possible client-record implication. | Replace with Brand Resources group/resource model and tighten access recommendations. | Repo docs / identity/access model | Not yet | Tyler / identity/security owner |
| CS-005 | `templates/dce-user-access-matrix-template.csv` | Example user has `Delta Crown Client Services`, `ClientServices`, and `DCE-ClientServices`. | Template can seed stale user metadata and group assignments. | Replace example with Brand Resources or Operations/Marketing role depending on final group model. | Repo template | Safe after group naming decision | Tyler / identity owner |
| CS-006 | `tests/architecture/test_adr_002_phase3_sites_teams.py` | Architecture fitness tests require `DCE-ClientServices`, `Client Records`, `Service Catalog`, `Feedback`, `Consent Forms`, and PII assertions. | Tests enforce obsolete architecture, causing future cleanup to fail CI. | Update or supersede ADR-002 tests after Brand Resources implementation decision. | Repo tests | Not yet | Technical owner |
| CS-007 | `tests/phase3/Phase3-Config.Tests.ps1` | Phase 3 config tests require `DCE-ClientServices`, `/sites/dce-clientservices`, `Client Records`, and PII columns. | Same obsolete architecture enforcement in PowerShell test suite. | Update tests once target tenant implementation is chosen. | Repo tests | Not yet | Technical owner |
| CS-008 | `phase2-week1/docs/URL-and-ID-Inventory.md` | Includes `Client Services` and `Client-Services.aspx`. | Historical docs may be misread as current naming. | Mark historical or update current-facing references to Brand Resources where appropriate. | Repo docs | Safe if clearly historical | Tyler |
| CS-009 | `phase2-week1/ROLLOUT-CHECKLIST.md` | Includes `Client Services link configured` and `Client-Services.aspx created`. | Could send future rollout down stale path. | Replace with Brand Resources link/page in future rollout checklist. | Repo docs | Safe after public navigation decision | Tyler |
| CS-010 | `phase2-week1/docs/DEV-TEST-RESULTS.md` | Mentions pages: Operations, Client Services, Marketing, Document Center. | Low risk if historical, medium if used as validation reference. | Mark historical or map Client Services to Brand Resources in current notes. | Repo docs | Safe if historical label added | Tyler |
| CS-011 | `phase2-week1/FINAL-EXECUTIVE-HANDOFF.md` | Mentions Operations, Client Services, Marketing pages. | Stakeholder-facing artifact may conflict with current story. | Add current-state note if reused; otherwise keep historical. | Repo docs | Safe if historical label added | Tyler |
| CS-012 | `docs/onboarding/tyler-cross-tenant-pilot-checklist.md` | Mentions future client-services resources and client-services-only resources. | Pilot validation language points at stale resource. | Replace with Brand Resources or generic restricted-resource wording after tenant inventory. | Repo docs | Safe after group/resource naming decision | Tyler / identity owner |
| CS-013 | `index.html` and `presentation/index.html` | Uses phrase “Financial data, client records, legal docs — all unprotected” in public/showcase copy. | Could imply current client records are in M365 or in scope. | Review public copy; replace with safer generic risk wording if needed. | Public site / presentation | Needs content review | Tyler |
| CS-014 | Live `/sites/dce-clientservices` if present | Prior docs say this site exists and contains client-record-style lists. | Highest live-tenant risk; unknown current contents/permissions. | Inventory first. Then decide: repurpose, archive, restrict, delete, or replace with Brand Resources. | Tenant-impacting | No | Tyler / tenant owner / data owner |
| CS-015 | Live `DCE-ClientServices` group if present | Prior docs use it as functional access group. | May drive access to stale resource or imply client-service role. | Inventory membership/rules; decide whether to retire, rename, or replace with Brand Resources group. | Tenant-impacting | No | Tyler / identity owner |
| CS-016 | Live Client Records / Service History / Feedback lists if present | Prior architecture expects client-record lists with PII. | Directly conflicts with no-client-records-in-M365 scope. | Inventory existence only; do not open/sample records. If present, route to data cleanup/security review. | Tenant-impacting / data risk | No | Tyler / security/data owner |
| CS-017 | Phase 3 provisioning scripts/configs, if they still create ClientServices artifacts | Existing docs/tests suggest scripts may provision stale resources. | Re-running scripts could recreate obsolete site/lists/permissions. | Review scripts before any future run; gate with explicit Brand Resources decision. | Repo scripts / tenant-impacting | No | Technical owner |

## Immediate safe actions

These are safe repo-only next steps after tenant/resource naming decisions are confirmed:

1. Add historical/deprecated notes to old Phase 2/Phase 3 docs that mention Client Services.
2. Update user-facing future-state docs to say Brand Resources instead of Client Services.
3. Update example templates to avoid `ClientServices` metadata.
4. Update architecture tests only after the implementation target is decided.
5. Keep public showcase wording clear that client records are out of Microsoft 365 scope.

## Actions that are not safe yet

Do not do these until tenant inventory and owner approval are complete:

- rename `/sites/dce-clientservices`;
- delete `/sites/dce-clientservices`;
- delete or modify any Client Records / Service History / Feedback lists;
- change `DCE-ClientServices` group membership or dynamic rules;
- migrate Master DCE content into any live site;
- grant broader access to Strategy, Financials, or franchise/development material;
- run Phase 3 provisioning scripts that may recreate ClientServices artifacts.

## Decision tree

Use this after tenant inventory:

```text
Does /sites/dce-clientservices exist?
├── No
│   └── Clean repo docs/tests/templates to remove obsolete assumptions.
└── Yes
    ├── Does it contain client records/client PII?
    │   ├── Yes
    │   │   └── Stop. Route to security/data owner cleanup plan. Do not repurpose.
    │   └── No
    │       ├── Is the URL/name acceptable for Brand Resources?
    │       │   ├── Yes
    │       │   │   └── Consider controlled repurpose after owner approval.
    │       │   └── No
    │       │       └── Prefer new Brand Resources target and archive/deprecate old site.
    └── Are permissions explainable in one sentence?
        ├── Yes
        │   └── Document and validate.
        └── No
            └── Do not repurpose until permissions are cleaned up under a change plan.
```

## Recommended future states

| Legacy item | Preferred future state |
|---|---|
| `ClientServices` user-facing label | Replace with `Brand Resources` where the intent is reusable brand material. |
| `DCE-ClientServices` group | Replace or supersede with Brand Resources/resource-specific groups after inventory. |
| `/sites/dce-clientservices` | Inventory first; likely deprecate, archive, or carefully repurpose only if empty/low-risk. |
| `Client Records` list | Out of scope for M365; route to cleanup/security review if present. |
| `Service History` list | Out of scope if client-specific; route to cleanup/security review if present. |
| `Feedback` list | Inventory existence, schema, permissions, and owner attestation only; do not open, sample, or export items. Treat as client-data risk if owner cannot confirm non-client content. |
| `Consent Forms` library | Inventory existence, schema, permissions, and owner attestation only; do not open, sample, or export submissions. Submitted client consent records are out of Brand Resources scope. |
| Architecture tests requiring ClientServices | Update after new Brand Resources implementation decision. |

## Cleanup readiness gates

Before changing any live resource or architecture test:

- [ ] Delta Crown tenant inventory confirms whether the resource exists.
- [ ] Owner confirms whether content is empty, active, historical, or sensitive.
- [ ] Client-data risk is assessed without opening/exporting client records.
- [ ] Brand Resources implementation option is chosen.
- [ ] Rollback/validation plan exists for any tenant-impacting action.
- [ ] A tracked change request exists for tenant changes.
- [ ] Inventory outputs are metadata-only and redacted as needed; do not export client records, list items, file contents, or PII.

## Showcase-safe wording

Safe:

> We found legacy ClientServices assumptions in old deployment materials. Those are being cleaned up because Delta Crown is using Brand Resources for approved reference material, not client records in Microsoft 365.

Careful:

> Any live ClientServices resources must be inventoried before we decide whether to archive, repurpose, replace, or remove them.

Not safe:

> We can just rename ClientServices to Brand Resources.

Not safe:

> Client Records are part of the new Microsoft 365 model.

Not safe:

> It is safe to delete the old site now.
