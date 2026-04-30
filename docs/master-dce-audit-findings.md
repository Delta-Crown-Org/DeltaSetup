# Master DCE Audit Findings

## Audit status

Completed a read-only top-level audit of the HTT Brands `Master DCE` folder using Microsoft Graph via the existing Azure CLI HTT tenant login.

Source:

```text
https://httbrands.sharepoint.com/sites/HTTHQ
Shared Documents / Master DCE
```

Committed summary date:

```text
2026-04-30
```

Raw output location, local only:

```text
.local/reports/master-dce/master-dce-folder-inventory.csv
.local/reports/master-dce/master-dce-permissions.csv
.local/reports/master-dce/master-dce-summary.md
```

Raw CSV files were not committed because they include permission principals and tenant object details.

## Method

The original PnP.PowerShell delegated auth path was blocked by:

```text
AADSTS500113: No reply address is registered for the application.
```

The audit was completed through the existing HTT Azure CLI session instead:

```bash
python3 phase4-migration/scripts/audit_master_dce_graph.py
```

The script used Microsoft Graph read calls only. No tenant writes, file operations, permission changes, copy/move/delete actions, or cleanup actions were performed.

## Top-level results

| Metric | Result |
|---|---:|
| Top-level items scanned | 13 |
| Top-level folders | 12 |
| Top-level files | 1 |
| Permission rows visible through Graph | 275 |
| Sharing link rows visible through Graph | 0 |

## Top-level inventory

| Name | Type | Direct files | Direct folders | Modified | Modified by |
|---|---|---:|---:|---|---|
| Corp Docs | Folder | 1 | 1 | 2026-01-06 | Joe Honkala |
| DC - Letterhead.docx | File | n/a | n/a | 2026-01-21 | Kristin Kidd |
| DCE Marketing | Folder | 2 | 13 | 2026-04-14 | Taylor Hulyksmith |
| Financials & Proforma | Folder | 8 | 3 | 2025-06-30 | Meg Roberts |
| Fran Dev | Folder | 2 | 6 | 2025-07-03 | Meg Roberts |
| Operations | Folder | 9 | 5 | 2025-07-03 | Meg Roberts |
| Product | Folder | 5 | 2 | 2025-06-30 | Meg Roberts |
| Real Estate & Construction | Folder | 1 | 2 | 2025-07-07 | Meg Roberts |
| Strategy | Folder | 5 | 0 | 2025-08-26 | Meg Roberts |
| Training | Folder | 1 | 0 | 2025-07-03 | Meg Roberts |
| _Franchisees | Folder | 1 | 4 | 2025-07-03 | Meg Roberts |
| _Status | Folder | 2 | 0 | 2025-11-03 | Meg Roberts |
| zArchive | Folder | 1 | 0 | 2026-03-05 | Kristin Kidd |

## Initial mapping signals

These are audit observations, not final migration decisions.

| Source item | Initial mapping signal | Notes |
|---|---|---|
| Operations | Operations | Likely first-class operations resource. |
| _Status | Operations | Status tracking; validate whether still active. |
| _Franchisees | Operations / Franchise Resources | Needs owner review before broad exposure. |
| DCE Marketing | Marketing | Large folder tree; likely brand/campaign materials. |
| Strategy | Brand Resources / Leadership restricted | Should not be exposed broadly before permission review. |
| Financials & Proforma | Brand Resources / Finance restricted | Treat as sensitive until owner confirms access model. |
| Product | Brand Resources / Docs | Likely reference material. |
| Training | Training / Docs | Validate whether Delta Crown-owned or corporate training. |
| Corp Docs | Corporate Reference / Shortcut | Likely HTT corporate-owned reference material. |
| Real Estate & Construction | Corporate Reference / Shortcut | Likely HTT-owned or cross-brand resource. |
| Fran Dev | Operations / Corporate Development | Needs owner review. |
| zArchive | Archive | Keep read-only unless owner approves specific migration. |
| DC - Letterhead.docx | Brand Resources / Docs | Single top-level file; should be relocated into a clean folder if migrated. |

## Permission note

Graph returned 275 permission rows visible to the current account for top-level Master DCE items. Those raw rows are local-only because they include people/groups and object-level permission detail.

Important limitations:

- Graph permission output is useful audit evidence, but it is not a complete replacement for SharePoint/PnP role assignment detail.
- Permission cleanup decisions require owner review.
- Sensitive folders such as Strategy and Financials should remain restricted until the access model is confirmed.

## Next step

Create `docs/master-dce-resource-map.md` from these findings and the local raw permission evidence.

Do not migrate, copy, delete, rename, or repermission content from this audit alone. The next step is mapping and owner decisions. The cleanup goblin can wait its turn.
