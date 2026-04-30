# Delta Crown SharePoint Inventory Summary

## Audit status

Completed a read-only Microsoft Graph SharePoint inventory for known Delta Crown site paths and Microsoft 365 group-connected root sites.

Tenant:

```text
deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30
```

Method:

```bash
python3 phase4-migration/scripts/inventory_delta_crown_sharepoint_graph.py
```

Authentication:

- existing Azure CLI account/session
- Microsoft Graph token for the Delta Crown tenant
- read-only `GET` requests only

Raw local outputs:

```text
.local/reports/tenant-inventory/sharepoint/sharepoint-sites.csv
.local/reports/tenant-inventory/sharepoint/sharepoint-drives.csv
.local/reports/tenant-inventory/sharepoint/sharepoint-lists.csv
.local/reports/tenant-inventory/sharepoint/sharepoint-list-columns.csv
.local/reports/tenant-inventory/sharepoint/sharepoint-inventory-errors.csv
.local/reports/tenant-inventory/sharepoint/sharepoint-summary.json
.local/reports/tenant-inventory/sharepoint/sharepoint-summary.md
```

Raw outputs are local-only because they contain IDs, URLs, list metadata, and schema details.

No SharePoint, OneDrive, group, permission, or tenant settings were changed.

## Important limitation

Tenant-wide Graph site search returned `accessDenied`, so this inventory used:

1. known Delta Crown site paths from repo evidence;
2. Microsoft 365 group-connected root sites discovered through Graph groups.

Graph list/drive detail was visible for group-connected root sites, but not for all known standalone/communication sites. SharePoint admin/PnP-level inventory is still needed for:

- hub association details;
- tenant sharing settings;
- site collection admins/owners;
- unique permissions;
- full library/list inventory on every site;
- external sharing posture;
- deeper OneDrive inventory.

A follow-up issue should track that enhanced inventory. Microsoft Graph gave us a flashlight, not the building blueprint. Very on brand.

## Totals

| Area | Count |
|---|---:|
| Sites inventoried | 15 |
| Document libraries/drives visible through Graph | 4 |
| Lists visible through Graph | 4 |
| List/library columns inventoried | 548 |
| Known site lookup failures | 0 |
| Detail read errors | 0 |
| `/sites/dce-clientservices` sites found | 1 |
| Risk-named lists found through Graph | 0 |
| Risk-named libraries found through Graph | 0 |
| Brand Resources named site/list/library objects found | 0 |

## Sites found

| Site | URL | Source | Group-connected? |
|---|---|---|---|
| Communication site | `https://deltacrown.sharepoint.com` | Known path | No |
| Corporate Shared Services | `https://deltacrown.sharepoint.com/sites/corp-hub` | Known path | No |
| Corporate HR | `https://deltacrown.sharepoint.com/sites/corp-hr` | Known path | No |
| Corporate IT | `https://deltacrown.sharepoint.com/sites/corp-it` | Known path | No |
| Corporate Finance | `https://deltacrown.sharepoint.com/sites/corp-finance` | Known path | No |
| Corporate Training | `https://deltacrown.sharepoint.com/sites/corp-training` | Known path | No |
| Delta Crown Extensions Hub | `https://deltacrown.sharepoint.com/sites/dce-hub` | Known path | No |
| DCE Operations | `https://deltacrown.sharepoint.com/sites/dce-operations` | Known path | No |
| DCE Client Services | `https://deltacrown.sharepoint.com/sites/dce-clientservices` | Known path | No |
| DCE Marketing | `https://deltacrown.sharepoint.com/sites/dce-marketing` | Known path | No |
| DCE Document Center | `https://deltacrown.sharepoint.com/sites/dce-docs` | Known path | No |
| Delta Crown Operations | `https://deltacrown.sharepoint.com/sites/dce-operations-team` | Group root site | Yes |
| Delta Crown Extensions | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions379` | Group root site | Yes |
| Delta Crown Extensions | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions` | Group root site | Yes |
| All Company | `https://deltacrown.sharepoint.com/sites/allcompany` | Group root site | Yes |

## Visible libraries/lists through Graph

Graph exposed these document libraries/lists:

| Site | Library/list | URL |
|---|---|---|
| Delta Crown Operations | Documents | `https://deltacrown.sharepoint.com/sites/dce-operations-team/Shared%20Documents` |
| Delta Crown Extensions | Documents | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions379/Shared%20Documents` |
| Delta Crown Extensions | Documents | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions/Shared%20Documents` |
| All Company | Documents | `https://deltacrown.sharepoint.com/sites/allcompany/Shared%20Documents` |

No `Client Records`, `Service History`, `Feedback`, or `Consent Forms` list/library names were visible through this Graph inventory.

Important: because Graph did not expose full list/library detail for all known sites, this does **not** prove those artifacts are absent from every site. It only means they were not visible through this inventory method.

## ClientServices finding

`/sites/dce-clientservices` exists:

```text
https://deltacrown.sharepoint.com/sites/dce-clientservices
```

Current summary finding:

- site exists;
- risk-named lists/libraries were not visible through Graph;
- no file contents or list items were opened;
- future action must wait for enhanced SharePoint inventory and owner approval.

Recommended handling:

1. Treat the site as a legacy ClientServices artifact.
2. Do not rename, delete, archive, or repurpose it yet.
3. Use enhanced SharePoint admin/PnP inventory to confirm libraries/lists, permissions, owners, sharing, and dependencies.
4. Decide whether to replace, archive, or carefully repurpose only after owner approval.

## Duplicate group-connected sites

The duplicate Microsoft 365 groups named `Delta Crown Extensions` also have distinct group-connected SharePoint sites:

```text
https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions379
https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions
```

This supports follow-up `DeltaSetup-142`.

Do not delete or rename either group or site until Teams/SharePoint dependencies are fully understood.

## Brand Resources finding

No site, list, or library with a visible name containing `Brand Resources` was found through this inventory.

Implication:

- Brand Resources appears to be a target model, not an implemented SharePoint resource yet;
- implementation should wait for inventory consolidation and owner decision;
- do not repurpose `dce-clientservices` blindly as Brand Resources.

## Follow-up needed

| Follow-up | Reason |
|---|---|
| Enhanced SharePoint admin/PnP inventory | Needed for hub associations, owners/admins, sharing, unique permissions, and full list/library inventory. |
| Review duplicate Delta Crown Extensions group-connected sites | Two duplicate group-connected sites exist and likely map to the duplicate Microsoft 365 groups. |
| ClientServices metadata-only deep check | Confirm whether old client-record-style lists/libraries exist without opening/exporting client data. |
| Brand Resources implementation decision | No Brand Resources resource appears implemented yet. |

## Safety notes

Do not perform any of these from this inventory alone:

- rename or delete `/sites/dce-clientservices`;
- rename or delete duplicate `Delta Crown Extensions` group-connected sites;
- open/export client-record-style lists or files;
- create Brand Resources resources;
- migrate Master DCE content;
- change SharePoint permissions;
- change hub associations or navigation.

This is evidence for planning, not permission to start cleaning with a flamethrower.
