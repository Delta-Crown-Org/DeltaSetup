# Delta Crown Security, Apps, and Licenses Inventory Summary

## Audit status

Completed a read-only Microsoft Graph inventory for Delta Crown security policies, app registrations, enterprise apps, consent grants, and license state where current Graph access allowed.

Tenant:

```text
deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30
```

Method:

```bash
python3 phase4-migration/scripts/inventory_delta_crown_security_apps_graph.py
```

Authentication:

- existing Azure CLI account/session
- Microsoft Graph token for the Delta Crown tenant
- read-only `GET` requests only

Raw local outputs:

```text
.local/reports/tenant-inventory/security-apps/security-subscribed-skus.csv
.local/reports/tenant-inventory/security-apps/security-user-license-assignments.csv
.local/reports/tenant-inventory/security-apps/security-applications.csv
.local/reports/tenant-inventory/security-apps/security-service-principals.csv
.local/reports/tenant-inventory/security-apps/security-application-credentials.csv
.local/reports/tenant-inventory/security-apps/security-service-principal-credentials.csv
.local/reports/tenant-inventory/security-apps/security-oauth2-permission-grants.csv
.local/reports/tenant-inventory/security-apps/security-conditional-access-policies.csv
.local/reports/tenant-inventory/security-apps/security-named-locations.csv
.local/reports/tenant-inventory/security-apps/security-inventory-errors.csv
.local/reports/tenant-inventory/security-apps/security-singleton-policies.json
.local/reports/tenant-inventory/security-apps/security-summary.json
.local/reports/tenant-inventory/security-apps/security-summary.md
```

Raw outputs are local-only because they contain app IDs, service principal IDs, credential metadata, consent grant rows, and user license assignment details.

No licenses, Conditional Access policies, app registrations, enterprise apps, consent grants, credentials, or tenant settings were changed.

## Totals

| Area | Count |
|---|---:|
| Subscribed SKUs | 2 |
| Licensed users | 6 |
| App registrations | 3 |
| Enterprise apps / service principals | 204 |
| Application password credentials | 4 |
| Application key credentials | 0 |
| Service principal password credentials | 0 |
| Service principal key credentials | 0 |
| OAuth2 permission grants | 13 |
| Conditional Access policies | 3 |
| Named locations | 1 |

## License inventory

| SKU | Enabled | Consumed | Available | Suspended | Warning |
|---|---:|---:|---:|---:|---:|
| `AAD_PREMIUM_P2` | 1 | 0 | 1 | 0 | 0 |
| `O365_BUSINESS_ESSENTIALS` | 6 | 6 | 0 | 0 | 0 |

Implications:

- Exchange Online activation is supported by six consumed Business Basic-style licenses.
- There is no available `O365_BUSINESS_ESSENTIALS` capacity left according to subscribed SKU data.
- One Entra ID P2 license is available/unused.

## Conditional Access

| Policy | State | Modified |
|---|---|---|
| Require MFA for Admins | enabled | 2026-03-12T17:16:52.2346165Z |
| Require MFA for all users | enabled | n/a |
| SGI Login | enabled | n/a |

Summary:

| State | Count |
|---|---:|
| Enabled | 3 |
| Report-only | 0 |
| Disabled | 0 |

Named locations:

| Name | Notes |
|---|---|
| SGI | One named location exists; raw IDs/details are local-only. |

## App registrations

| App registration | Sign-in audience | Notes |
|---|---|---|
| DeltaCrown-PnP-Provisioning | AzureADMyOrg | No application credential rows found in this inventory. |
| Riverside-Governance-DCE | AzureADMyOrg | One password credential found; expires 2027-03-04. |
| DeltaCrown-TeamsProvisioner-TEMP | AzureADMyOrg | Three password credentials found; all expired on 2026-04-16. |

Credential summary:

| Credential category | Count |
|---|---:|
| Active/future-dated app password credentials visible in summary | 1 |
| Expired app password credentials visible in summary | 3 |
| App key/certificate credentials | 0 |
| Service principal credentials | 0 |

The expired credentials are local evidence for cleanup planning. Do not remove app registrations or credentials until dependencies are reviewed and an owner-approved cleanup change exists.

## Enterprise apps and consent grants

| Area | Count |
|---|---:|
| Enterprise apps / service principals | 204 |
| OAuth2 permission grants | 13 |

Raw consent grant rows are local-only because they include object IDs and scopes. They should be reviewed during production cleanup for excessive or stale delegated permissions.

## Graph access limitations

The following Graph policy reads returned access-denied errors with the current token:

| Scope | Result |
|---|---|
| Security defaults enforcement policy | Access denied / missing scopes |
| Authentication methods policy | Access denied |
| Admin consent request policy | Access denied |

Impact:

- this inventory cannot confirm security defaults state;
- this inventory cannot fully confirm authentication method posture;
- this inventory cannot confirm admin consent request workflow state.

## Purview / DLP / sensitivity label limitation

This Graph inventory did not capture Purview DLP policies or sensitivity labels.

Those likely require Compliance PowerShell/Purview access such as:

- Compliance Reader / Purview reader role;
- Security & Compliance PowerShell connection;
- read-only `Get-DlpCompliancePolicy`, `Get-DlpComplianceRule`, `Get-Label`, and `Get-LabelPolicy` style commands.

Because DLP and sensitivity labels are specifically called out in earlier architecture docs, they need a separate enhanced compliance inventory before consolidated readiness claims.

## Readiness implications

1. Conditional Access exists and all visible CA policies are enabled.
2. License capacity is tight: all six Business Basic-style licenses are consumed.
3. The expected Exchange license activation path appears consistent with six licensed users and the Exchange inventory.
4. There are three app registrations, including one explicitly named `TEMP` with expired credentials.
5. App/service-principal/consent review is needed before production cleanup.
6. Current Graph access is not enough to fully confirm security defaults, authentication methods, admin consent workflow, DLP, or sensitivity labels.

## Follow-up needed

| Follow-up | Reason |
|---|---|
| Review `DeltaCrown-TeamsProvisioner-TEMP` app registration and expired credentials. | Temporary app and expired credentials should not linger without an owner-approved reason. |
| Review app registrations, enterprise apps, and OAuth2 consent grants. | Raw consent grant and app metadata are local-only and need owner/security review. |
| Run Purview/Compliance inventory for DLP and sensitivity labels. | Graph inventory did not cover DLP/labels. |
| Confirm security defaults/authentication methods/admin consent policy with sufficient role/scopes. | Current Graph token returned access denied. |
| Feed security/apps/licenses findings into consolidated tenant inventory. | Required for `DeltaSetup-137`. |

## Safety notes

Do not perform any of these from this inventory alone:

- delete app registrations;
- remove credentials;
- grant or revoke consent;
- change Conditional Access policies;
- assign or remove licenses;
- enable or disable security defaults;
- change authentication methods;
- create or edit DLP/sensitivity policies.

Inventory evidence is not a cleanup flamethrower. It is a flashlight. Use accordingly.
