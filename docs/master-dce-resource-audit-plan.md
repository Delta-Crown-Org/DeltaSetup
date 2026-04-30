# Master DCE Resource Audit Plan

## Why this exists

The HTT Brands tenant currently stores Delta Crown material under:

`httbrands.sharepoint.com/sites/HTTHQ / Shared Documents / Master DCE`

That folder is not a clean information architecture. It is a production shared-library folder with mixed content, inherited/broken permissions, corporate users, brand-specific documents, and historical material. The goal is not to blindly migrate it. The goal is to understand it, map it, and then create a cleaner Delta Crown resource model.

## Updated pillar language

Because Delta Crown does **not** plan to store client records in Microsoft 365, any old client-service/client-experience pillar language should not be presented as client-record storage.

Use this language instead:

> **Brand Resources** — mapped Master DCE reference folders, playbooks, financial packs, product materials, and franchise resources with permissions based on actual role and corporate support needs.

## Known Master DCE top-level folders from current review

From the current SharePoint view and existing migration mapping, Master DCE includes:

| Folder | Likely destination / pillar | Notes |
|---|---|---|
| Strategy | Brand Resources or Docs, leadership restricted | Do not expose broadly until permissions are audited. |
| Financials & Proforma | Brand Resources or Finance-controlled area | Needs file-by-file review; may contain finance-sensitive material. |
| Product | Docs / Brand Resources | Reference material. |
| Operations | Operations | Daily operating resources. |
| DCE Marketing (source folder name) | Marketing | Brand assets/campaign materials. |
| Training | Docs or Training | Could be Delta Crown-owned or corporate training depending on content. |
| _Franchisees | Operations / Franchise Resources | Likely franchise management resources. |
| Fran Dev | Operations or corporate development | Needs owner review. |
| Real Estate & Construction | Corporate reference / shortcut | Likely HTT corporate owned, not Delta Crown-owned. |
| _Status | Operations | Status tracking; validate current use. |
| Corp Docs | Corporate reference / shortcut | Likely remains HTT-owned unless Delta Crown-specific. |
| zArchive | Archive | Keep read-only or migrate only if needed. |

## Recommended target model

Do not recreate the messy folder tree 1:1 unless the audit proves it is necessary. Use the current tree as source evidence, then map folders into cleaner resource lanes:

1. **Operations**
   - Operations
   - _Status
   - _Franchisees
   - possibly Fran Dev

2. **Marketing**
   - DCE Marketing source folder
   - brand templates and campaign assets

3. **Brand Resources**
   - Strategy
   - Financials & Proforma
   - Product
   - selected franchise resources

4. **Training / Docs**
   - Training
   - SOPs
   - reference documents

5. **Corporate Reference / Shortcuts**
   - Corp Docs
   - Real Estate & Construction
   - any HTT-owned cross-brand materials

6. **Archive**
   - zArchive
   - old or deprecated materials after owner review

## Audit outputs needed before showcase

Run `phase4-migration/scripts/audit-master-dce.ps1` to produce:

- `reports/master-dce-folder-inventory.csv`
- `reports/master-dce-permissions.csv`
- `reports/master-dce-summary.md`

The audit should answer:

- What top-level folders exist?
- How many files/folders are in each?
- Which folders have unique permissions?
- Which people/groups currently have access?
- Which folders are corporate-owned vs brand-owned?
- Which folders should move, be replicated, stay as shortcuts, or archive?

## Access model decision rules

Use these rules after the audit:

- If content is Delta Crown-owned and needed by Delta Crown staff, host it in the Delta Crown tenant.
- If content is HTT corporate-owned and used across brands, keep it in HTT and expose a shortcut/reference from Delta Crown.
- If content is leadership/finance/strategy-sensitive, restrict it by role, not by inherited folder accidents.
- If content is historical, archive it rather than making it a first-class pillar.
- If access cannot be explained in one sentence, the permission model is too weird. Fix the model, not the sentence.

## Showcase-safe wording

Safe to say:

> We are auditing the existing Master DCE folder and mapping its real content into cleaner Delta Crown resource pillars. Some resources will become Delta Crown-owned, while corporate-owned materials can remain in HTT and be referenced from the DCE ecosystem.

Do not say yet:

> All Master DCE content has been migrated.

Do not say yet:

> Every folder already has clean permissions.

Do not say yet:

> Client records live in Microsoft 365.

They do not, and saying that would be how we summon the compliance goblin.
