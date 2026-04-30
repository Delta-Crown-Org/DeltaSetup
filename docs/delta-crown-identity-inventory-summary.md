# Delta Crown Identity Inventory Summary

## Audit status

Completed a read-only Microsoft Graph identity inventory for the Delta Crown tenant.

Tenant:

```text
deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30
```

Method:

```bash
python3 phase4-migration/scripts/inventory_delta_crown_identity_graph.py
```

Authentication:

- existing Azure CLI account/session
- Microsoft Graph token for the Delta Crown tenant
- read-only `GET` requests only

Raw local outputs:

```text
.local/reports/tenant-inventory/identity/identity-users.csv
.local/reports/tenant-inventory/identity/identity-groups.csv
.local/reports/tenant-inventory/identity/identity-group-memberships.csv
.local/reports/tenant-inventory/identity/identity-group-owners.csv
.local/reports/tenant-inventory/identity/identity-group-counts.csv
.local/reports/tenant-inventory/identity/identity-directory-roles.csv
.local/reports/tenant-inventory/identity/identity-directory-role-members.csv
.local/reports/tenant-inventory/identity/identity-summary.json
.local/reports/tenant-inventory/identity/identity-summary.md
```

Raw outputs are local-only because they contain user names, UPNs, group memberships, owners, and role assignments.

No users, groups, roles, licenses, or tenant settings were changed.

## Totals

| Area | Count |
|---|---:|
| Users | 89 |
| Member users | 89 |
| Guest users | 0 |
| Disabled users | 3 |
| Groups | 10 |
| Dynamic groups | 5 |
| Mail-enabled groups | 4 |
| Security-enabled groups | 7 |
| Activated directory roles | 9 |
| Raw group membership rows | 194 |
| Raw group owner rows | 11 |
| Raw directory role member rows | 5 |

## User metadata completeness

| Field | Populated users | Gap |
|---|---:|---:|
| `companyName` | 6 / 89 | 83 missing |
| `department` | 45 / 89 | 44 missing |
| `jobTitle` | 44 / 89 | 45 missing |
| `officeLocation` | 16 / 89 | 73 missing |
| `employeeType` | 0 / 89 | 89 missing |

## Immediate identity findings

### 1. AllStaff currently only captures six users

The `AllStaff` dynamic rule is:

```text
(user.companyName -eq "Delta Crown Extensions")
```

Only 6 of 89 users currently have `companyName` populated, so `AllStaff` resolves to 6 members.

Impact:

- any access model that depends on `AllStaff` is only as complete as `companyName` coverage;
- this matches the earlier follow-up tracked by `DeltaSetup-120`.

### 2. Role-specific dynamic groups are empty

| Group | Members | Dynamic rule |
|---|---:|---|
| Managers | 0 | `(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Manager")` |
| Marketing | 0 | `(user.department -eq "Delta Crown Marketing")` |
| Stylists | 0 | `(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Stylist")` |
| External | 0 | `(user.userType -eq "Guest") and (user.companyName -eq "Delta Crown Extensions")` |

Impact:

- role-specific access is not ready to trust until employee metadata is normalized;
- Marketing may be empty because no users currently match exactly `Delta Crown Marketing`;
- Managers/Stylists depend on both `companyName` and title text.

### 3. Duplicate “Delta Crown Extensions” Microsoft 365 groups exist

Two Microsoft 365 / Unified groups share the display name `Delta Crown Extensions`:

| Display name | Mail | Members | Owners | Dynamic? |
|---|---|---:|---:|---|
| Delta Crown Extensions | `DeltaCrownExtensions379@deltacrown.com` | 86 | 4 | No |
| Delta Crown Extensions | `DeltaCrownExtensions@deltacrown.com` | 86 | 4 | No |

Impact:

- duplicate display names can confuse owners, navigation, Teams/SharePoint backing groups, and access reviews;
- do not delete or rename either group until SharePoint/Teams inventory identifies dependencies.

### 4. Dynamic security groups have no owners

The dynamic groups below show zero owners in Graph:

| Group | Owners |
|---|---:|
| AllStaff | 0 |
| External | 0 |
| Managers | 0 |
| Marketing | 0 |
| Stylists | 0 |

Impact:

- ownerless groups create governance and troubleshooting risk;
- owner assignment should wait for identity/access owner decisions and a tracked change request.

### 5. Global Administrator has five members

Activated directory roles show:

| Role | Members |
|---|---:|
| Global Administrator | 5 |
| Azure AD Joined Device Local Administrator | 0 |
| Billing Administrator | 0 |
| Directory Readers | 0 |
| Directory Writers | 0 |
| Global Reader | 0 |
| Privileged Authentication Administrator | 0 |
| Privileged Role Administrator | 0 |
| Service Support Administrator | 0 |

Impact:

- role membership details are in local raw output only;
- role membership review should be part of the security/apps/licenses inventory and production cleanup roadmap.

## Group inventory summary

| Group | Mail | Type | Members | Owners | Dynamic rule present |
|---|---|---|---:|---:|---|
| All Company | `allcompany@deltacrown.com` | Microsoft 365 / Unified | 1 | 1 | No |
| AllStaff | n/a | Dynamic security | 6 | 0 | Yes |
| Delta Crown Extensions | `DeltaCrownExtensions379@deltacrown.com` | Microsoft 365 / Unified | 86 | 4 | No |
| Delta Crown Extensions | `DeltaCrownExtensions@deltacrown.com` | Microsoft 365 / Unified | 86 | 4 | No |
| Delta Crown Operations | `dce-operations-team@deltacrown.com` | Microsoft 365 / Unified + security-enabled | 6 | 2 | No |
| External | n/a | Dynamic security | 0 | 0 | Yes |
| Managers | n/a | Dynamic security | 0 | 0 | Yes |
| Marketing | n/a | Dynamic security | 0 | 0 | Yes |
| SGI Techs | n/a | Security | 9 | 0 | No |
| Stylists | n/a | Dynamic security | 0 | 0 | Yes |

## Brand Resources implications

The identity inventory supports the Brand Resources transition plan, but it also shows why tenant cleanup must wait:

- `AllStaff` is not complete enough to be blindly used as broad Brand Resources access.
- `Managers`, `Marketing`, and `Stylists` are not currently populated enough for role-specific Brand Resources permissions.
- No `BrandResources-*` groups exist yet, and they should not be created until implementation decisions are approved.
- Existing legacy groups such as `DCE-ClientServices` were not found by display name in this inventory summary, but SharePoint/Teams/mail dependencies still need separate workload inventory before declaring anything safe to remove.

## Recommended follow-up

| Follow-up | Reason | Suggested issue |
|---|---|---|
| Normalize user metadata for `companyName`, `department`, `jobTitle`, `officeLocation`, and optionally `employeeType`. | Dynamic groups depend on these fields. | `DeltaSetup-120` or dedicated metadata remediation issue. |
| Review duplicate `Delta Crown Extensions` Microsoft 365 groups. | Duplicate display names create access/navigation ambiguity. | New cleanup issue after SharePoint/Teams inventory. |
| Decide owners for dynamic security groups. | Ownerless groups are governance risk. | Security/governance cleanup roadmap. |
| Re-check Managers/Marketing/Stylists after metadata cleanup. | Current membership is zero. | `DeltaSetup-120`. |
| Feed identity results into consolidated tenant inventory. | Required for showcase-vs-tenant gap analysis. | `DeltaSetup-137`. |

## Safety notes

Do not perform any of these from the inventory alone:

- update user metadata;
- change dynamic group rules;
- add/remove group owners;
- delete duplicate groups;
- change role assignments;
- create Brand Resources groups;
- grant SharePoint/Teams access based only on this summary.

This is evidence, not a change plan. Tiny but important difference, unless we enjoy cleaning up identity soup with a fork.
