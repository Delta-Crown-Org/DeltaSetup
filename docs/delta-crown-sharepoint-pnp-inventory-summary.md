# Delta Crown Enhanced SharePoint / PnP Inventory Summary

## Audit status

Completed an enhanced read-only SharePoint inventory using PnP.PowerShell for the Delta Crown tenant.

Tenant:

```text
deltacrown.com
```

Method:

```powershell
pwsh -NoProfile -File phase4-migration/scripts/inventory-delta-crown-sharepoint-pnp.ps1 \
  -ClientId <approved-pnp-app-client-id>
```

Authentication:

- PnP.PowerShell 3.1.0
- approved `DeltaCrown-PnP-Provisioning` app registration client ID
- interactive delegated login
- read-only PnP cmdlets only

Raw local outputs:

```text
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-tenant-sites.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-webs.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-lists.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-site-groups.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-site-group-members.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-web-role-assignments.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-list-role-assignments.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-errors.csv
.local/reports/tenant-inventory/sharepoint-pnp/sharepoint-pnp-summary.json
```

Raw outputs are local-only because they contain owner/login names, group membership details, role assignments, URLs, and SharePoint object metadata.

No SharePoint sites, lists, libraries, files, permissions, sharing settings, hub associations, or tenant settings were changed.

## Scope and safety

The script captured:

- tenant site metadata;
- site sharing capability metadata;
- hub association IDs;
- site/web metadata;
- full list/library names and item counts;
- list/library unique-permission flags;
- site group names and member counts;
- site group member rows;
- web-level role assignment summaries;
- list/library role assignment summaries for risk-named or uniquely-permissioned lists/libraries.

The script did **not** read:

- list items;
- file contents;
- OneDrive file contents;
- item-level permissions;
- client-record contents.

## Totals

| Area | Count |
|---|---:|
| Tenant sites | 18 |
| Site/web detail rows | 16 |
| Lists/libraries | 287 |
| Document libraries | 200 |
| Risk-named lists/libraries | 3 |
| Lists/libraries with unique permissions | 52 |
| Site groups | 48 |
| Site group member rows | 26 |
| Web role assignment rows | 60 |
| List/library role assignment rows | 19 |
| Sites allowing broad/new external sharing | 0 |
| `/sites/dce-clientservices` sites | 1 |
| Brand resource/asset name matches | 1 |
| Site-detail inventory errors | 2 |

## Sites found

| Site | URL | Template | Sharing capability |
|---|---|---|---|
| My Site host | `https://deltacrown-my.sharepoint.com/` | `SPSMSITEHOST#0` | Disabled |
| Root communication site | `https://deltacrown.sharepoint.com/` | `SitePagePublishing#0` | Existing external users only |
| Search Center | `https://deltacrown.sharepoint.com/search` | `SRCHCEN#0` | Disabled |
| All Company | `https://deltacrown.sharepoint.com/sites/allcompany` | `GROUP#0` | Existing external users only |
| Corporate Finance | `https://deltacrown.sharepoint.com/sites/corp-finance` | `SITEPAGEPUBLISHING#0` | Disabled |
| Corporate HR | `https://deltacrown.sharepoint.com/sites/corp-hr` | `SITEPAGEPUBLISHING#0` | Disabled |
| Corporate Shared Services | `https://deltacrown.sharepoint.com/sites/corp-hub` | `SITEPAGEPUBLISHING#0` | Disabled |
| Corporate IT | `https://deltacrown.sharepoint.com/sites/corp-it` | `SITEPAGEPUBLISHING#0` | Disabled |
| Corporate Training | `https://deltacrown.sharepoint.com/sites/corp-training` | `SITEPAGEPUBLISHING#0` | Disabled |
| DCE Client Services | `https://deltacrown.sharepoint.com/sites/dce-clientservices` | `STS#3` | Disabled |
| DCE Document Center | `https://deltacrown.sharepoint.com/sites/dce-docs` | `STS#3` | Disabled |
| Delta Crown Extensions Hub | `https://deltacrown.sharepoint.com/sites/dce-hub` | `SITEPAGEPUBLISHING#0` | Disabled |
| DCE Marketing | `https://deltacrown.sharepoint.com/sites/dce-marketing` | `SITEPAGEPUBLISHING#0` | Disabled |
| DCE Operations | `https://deltacrown.sharepoint.com/sites/dce-operations` | `STS#3` | Disabled |
| Delta Crown Operations | `https://deltacrown.sharepoint.com/sites/dce-operations-team` | `GROUP#0` | Existing external users only |
| Delta Crown Extensions | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions` | `GROUP#0` | Existing external users only |
| Delta Crown Extensions | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions379` | `GROUP#0` | Existing external users only |
| Delta Crown Operations-Leadership | `https://deltacrown.sharepoint.com/sites/DeltaCrownOperations-Leadership` | `TEAMCHANNEL#1` | Existing external users only |

## Hub association findings

The enhanced inventory captured hub association IDs in raw output.

Summary:

- Corporate sites are associated with the Corporate Shared Services hub ID in raw evidence.
- DCE sites are associated with the Delta Crown Extensions Hub ID in raw evidence.
- Group-connected Team sites and the private channel site are not hub-associated in this inventory.
- No hub association changes were made.

## ClientServices finding

`/sites/dce-clientservices` exists and contains the legacy client-service-style artifacts previously only suspected from repository evidence.

Visible non-hidden lists/libraries on `DCE Client Services`:

| Name | Type | Item count | Unique permissions? |
|---|---|---:|---|
| Client Records | Generic list | 0 | No |
| Consent Forms | Document library | 0 | No |
| Documents | Document library | 0 | No |
| Feedback | Generic list | 0 | No |
| Form Templates | Document library | 0 | No |
| Service Catalog | Generic list | 0 | No |
| Site Assets | Document library | 1 | No |
| Site Pages | Document library | 1 | No |
| Style Library | Document library | 0 | No |

Risk-named artifacts:

| Name | Type | Item count | Unique permissions? |
|---|---|---:|---|
| Client Records | Generic list | 0 | No |
| Consent Forms | Document library | 0 | No |
| Feedback | Generic list | 0 | No |

### ClientServices group and role detail

Site-level web role assignments for `DCE Client Services`:

| Principal | Principal type | Role(s) |
|---|---|---|
| DCE Client Services Owners | SharePointGroup | Full Control |
| DCE Client Services Visitors | SharePointGroup | Read |
| DCE Client Services Members | SharePointGroup | Edit |
| AllStaff | SecurityGroup | Contribute |
| Managers | SecurityGroup | Full Control |

Site group member counts:

| Site group | Members | Owner group |
|---|---:|---|
| DCE Client Services Owners | 1 | DCE Client Services Owners |
| DCE Client Services Members | 0 | DCE Client Services Owners |
| DCE Client Services Visitors | 0 | DCE Client Services Owners |

The only committed member-level statement is the member count. Raw member rows are local-only.

Risk-named list/library role detail:

| Artifact | List/library role detail |
|---|---|
| Client Records | Inherits from web |
| Consent Forms | Inherits from web |
| Feedback | Inherits from web |

Important:

- No list items or file contents were opened.
- These risk-named lists/libraries currently show zero items.
- They do not have list-level unique permissions according to PnP metadata.
- They inherit the `DCE Client Services` web permission model, including `AllStaff` Contribute and `Managers` Full Control at the web level.
- This still does **not** authorize deletion, permission changes, or repurposing. It is inventory evidence only.

## Brand Resources / Brand Assets finding

No visible site/list/library named exactly `Brand Resources` was found.

One brand-resource-adjacent library exists:

| Site | Library | Path |
|---|---|---|
| DCE Marketing | Brand Assets | `/sites/dce-marketing/Brand Assets` |

Implication:

- The implemented tenant currently has `Brand Assets`, not a dedicated `Brand Resources` site/library by that name.
- The ClientServices-to-Brand Resources transition plan should treat `Brand Assets` as existing evidence and decide whether it is sufficient, should be renamed, or should be complemented by a separate approved Brand Resources area.
- Do not rename `Brand Assets` from this inventory alone.

## Duplicate Delta Crown Extensions sites

The two duplicate `Delta Crown Extensions` Microsoft 365 groups have distinct group-connected SharePoint sites:

```text
https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions
https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions379
```

This confirms the cleanup concern in `DeltaSetup-142`.

Do not delete or rename either group/site until Teams and M365 group dependencies are reviewed.

## Sharing posture

No sites showed broad/new external sharing enabled in this inventory.

Observed states:

- Most Corporate and DCE standalone sites: `Disabled`.
- Root/group-connected/private-channel sites: `ExistingExternalUserSharingOnly`.

Interpretation:

- Existing external users may be usable on some group-connected/root/private-channel sites.
- This is not the same as allowing anyone links or new external invitations.
- Tenant-level sharing settings still belong in the consolidated security/sharepoint review before final public claims.

## Unique permissions

PnP found 52 lists/libraries with unique permissions. Most visible examples are standard SharePoint system libraries/lists such as:

- User Information List;
- TaxonomyHiddenList;
- Converted Forms;
- Maintenance Log Library.

The risk-named `Client Records`, `Consent Forms`, and `Feedback` artifacts did **not** show list-level unique permissions; the detailed role output marks them as inherited from the web.

Raw unique-permission list names, role assignment rows, group membership rows, and sites are local-only. They should be reviewed during production cleanup, but most unique-permission examples appear to be platform/system artifacts rather than custom business libraries.

## Inventory errors

Two site-detail reads returned access errors:

| Site | Error |
|---|---|
| `https://deltacrown.sharepoint.com/sites/allcompany` | Skipped: known access-limited site from prior PnP inventory |
| `https://deltacrown.sharepoint.com/sites/DeltaCrownOperations-Leadership` | Skipped: known access-limited site from prior PnP inventory |

Tenant-level metadata for those sites was still captured, but detailed list/group/role rows were intentionally skipped after prior access-denied behavior caused the detailed pass to hang.

## Readiness implications

1. Enhanced SharePoint evidence confirms the ClientServices site and legacy client-style artifacts exist.
2. Those risk-named ClientServices lists/libraries are empty, inherit web permissions, and do not have list-level unique permissions.
3. A `Brand Assets` library exists in DCE Marketing; no exact `Brand Resources` object was found.
4. Duplicate `Delta Crown Extensions` group-connected sites are real and should be reviewed with Teams/M365 group dependencies.
5. Sharing posture appears conservative, with no broad/new external sharing at the site level.
6. Final Teams dependency review is still needed before duplicate group/site cleanup decisions.

## Follow-up needed

| Follow-up | Reason |
|---|---|
| Review duplicate Delta Crown Extensions groups/sites. | Two distinct group-connected sites exist with the same display name. |
| Decide whether `Brand Assets` satisfies the Brand Resources target model. | Tenant evidence shows Brand Assets, not Brand Resources. |
| Keep ClientServices cleanup on hold until owner approval. | Legacy artifacts exist, are empty, and need approved disposition. |
| Review access-denied sites if deeper evidence is needed. | `allcompany` and leadership private channel site details were not fully readable. |
| Feed enhanced SharePoint findings into consolidated tenant inventory. | Required for `DeltaSetup-137`. |

## Safety notes

Do not perform any of these from this inventory alone:

- delete or rename `/sites/dce-clientservices`;
- delete `Client Records`, `Consent Forms`, or `Feedback`;
- rename `Brand Assets`;
- create `Brand Resources`;
- delete duplicate `Delta Crown Extensions` sites/groups;
- change SharePoint sharing settings;
- change permissions or group membership;
- treat inherited ClientServices access as approved target-state access;
- open/export client records or document contents.

The inventory says what exists. It does not grant permission to start “tidying.” Tenant cleanup without approvals is how you summon the Microsoft 365 clown car.
