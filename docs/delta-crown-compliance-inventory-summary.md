# Delta Crown Purview / Compliance Inventory Summary

## Audit status

Completed a read-only Purview / Security & Compliance PowerShell inventory for Delta Crown DLP policies, sensitivity labels, label policies, and retention policies.

Tenant/domain:

```text
deltacrown.com
```

Method:

```powershell
pwsh -NoProfile -File phase4-migration/scripts/inventory-delta-crown-compliance.ps1 \
  -Organization deltacrown.com \
  -UserPrincipalName <delegated-admin-upn> \\
  -UseDelegatedOrganization
```

Authentication:

- ExchangeOnlineManagement PowerShell module
- delegated Purview / IPPS session
- read-only `Get-*` cmdlets only

Raw local outputs:

```text
.local/reports/tenant-inventory/compliance/compliance-dlp-policies.csv
.local/reports/tenant-inventory/compliance/compliance-dlp-rules.csv
.local/reports/tenant-inventory/compliance/compliance-sensitivity-labels.csv
.local/reports/tenant-inventory/compliance/compliance-label-policies.csv
.local/reports/tenant-inventory/compliance/compliance-retention-policies.csv
.local/reports/tenant-inventory/compliance/compliance-retention-rules.csv
.local/reports/tenant-inventory/compliance/compliance-inventory-errors.csv
.local/reports/tenant-inventory/compliance/compliance-summary.json
```

Raw outputs are local-only because they contain detailed policy/rule configuration and IDs.

No DLP policies, sensitivity labels, label policies, retention policies, compliance rules, or tenant settings were changed.

## Totals

| Area | Count |
|---|---:|
| DLP policies | 6 |
| DLP rules | 8 |
| Sensitivity labels | 12 |
| Label policies | 1 |
| Retention policies | 1 |
| Retention rules | 1 |
| Inventory errors | 0 |

## DLP policies

| Policy | Mode | Workloads |
|---|---|---|
| Default Office 365 DLP policy | Enable | Exchange, SharePoint, OneDriveForBusiness |
| Default policy for Teams | Enable | Exchange, SharePoint, OneDriveForBusiness, Teams |
| Default policy for devices | Enable | Exchange, SharePoint, OneDriveForBusiness, EndpointDevices |
| DCE-Data-Protection | TestWithNotifications | Exchange, SharePoint, OneDriveForBusiness |
| Corp-Data-Protection | TestWithNotifications | Exchange, SharePoint, OneDriveForBusiness |
| External-Sharing-Block | Enable | Exchange, SharePoint, OneDriveForBusiness |

Important readiness note:

- `DCE-Data-Protection` and `Corp-Data-Protection` are still in `TestWithNotifications` mode.
- `External-Sharing-Block` is enabled.
- Earlier architecture docs warned about DLP test-mode gaps; this inventory confirms that at least two project DLP policies remain in test mode.

## Sensitivity labels

12 sensitivity labels are present and enabled in the inventory:

| Priority | Label |
|---:|---|
| 0 | Personal |
| 1 | Public |
| 2 | General |
| 3 | Anyone (unrestricted) |
| 4 | All Employees (unrestricted) |
| 5 | Confidential |
| 6 | Anyone (unrestricted) |
| 7 | All Employees |
| 8 | Trusted People |
| 9 | Highly Confidential |
| 10 | All Employees |
| 11 | Specified People |

Note: repeated display names are present in the raw policy model because some labels appear as parent/sub-label structures. Do not rename or flatten labels from this summary alone.

## Label policies

| Policy | Enabled | Notes |
|---|---|---|
| Global sensitivity label policy | Yes | Publishes 12 labels. Raw label IDs are local-only. |

## Retention

| Policy | Enabled | Mode |
|---|---|---|
| 4-Year Email only Archive | True | Enforce |

Retention rule details are local-only.

## Readiness implications

1. Purview compliance controls do exist in the Delta Crown tenant.
2. The expected project DLP policies are present.
3. Two project DLP policies are not enforcing yet; they are in test-with-notifications mode.
4. Sensitivity labels and a global label policy exist.
5. A retention policy exists and is enforcing.
6. DLP rule details should be reviewed locally before making any public/team-showcase claims about exact protected info types or enforcement behavior.

## Follow-up needed

| Follow-up | Reason |
|---|---|
| Review DLP policies currently in `TestWithNotifications`. | Confirm whether test mode is intentional and when enforcement review should occur. |
| Review raw DLP rules locally. | Rule contents determine actual protection behavior and are not committed. |
| Confirm sensitivity label taxonomy with business/security owner. | Repeated display names and parent/sub-label structures need owner context. |
| Feed compliance findings into consolidated tenant inventory. | Required for `DeltaSetup-137`. |

## Safety notes

Do not perform any of these from this inventory alone:

- enable or disable DLP policies;
- change DLP policy mode;
- edit DLP rules;
- rename labels;
- publish or unpublish labels;
- change retention policies;
- make exact enforcement claims without reviewing local raw rule evidence.

Inventory is a map. Do not use the map as a bulldozer. Yes, I have to say this because tenants are fragile little goblins.
