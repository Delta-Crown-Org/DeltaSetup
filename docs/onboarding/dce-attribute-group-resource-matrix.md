# DCE Attribute → Group → Resource Mapping Matrix

## Purpose
This document turns the DCE onboarding model into a concrete mapping system.

It answers three operational questions:

1. **Which identity attributes matter?**
2. **Which groups should those attributes drive?**
3. **Which resources should each group receive?**

This is the working bridge between:
- onboarding data
- dynamic group logic
- SharePoint / Teams / mailbox / app permissions
- Tyler's cross-tenant pilot validation

---

## Design Rules

### Rule 1 — Attributes are the source of truth
If a person's role or location changes, update the identity labels.
The groups and permissions should follow from that.

### Rule 2 — Groups are the permission boundary
Assign resources to groups, not users.
Direct user assignment is an exception, not the operating model.

### Rule 3 — Keep baseline and specialized access separate
A user may be:
- baseline staff
- leadership
- function-specific
- location-specific
- cross-tenant pilot

These are different dimensions. Do not mash them into one gross mega-group.

### Rule 4 — Cross-tenant access still follows ADR-004
Admission is not authorization.
The synced or admitted user still needs clean group-based authorization inside DCE.

---

## Canonical Attribute Set

| Attribute | Description | Example values | Notes |
|---|---|---|---|
| `companyName` | Brand boundary | `Delta Crown Extensions` | Required for baseline group logic and Exchange routing |
| `department` | Functional department label | `Delta Crown Operations`, `Delta Crown Marketing` | Keep controlled vocabulary |
| `jobTitle` | Human-readable title | `Manager`, `Stylist`, `Marketing Coordinator` | Useful, but not ideal as sole auth driver |
| `officeLocation` | Primary work location | `DCE-LV`, `DCE-PHX` | Recommended for location-based groups |
| `employeeType` | Internal/external/test distinction | `Employee`, `Partner`, `TestUser` | Useful for lifecycle and pilot handling |
| `extensionAttribute1` | Canonical business role | `Operations`, `Leadership`, `Marketing`, `ClientServices`, `Stylist` | Preferred functional group driver |
| `extensionAttribute2` | Primary owned or governed location | `DCE-LV` | Useful when ownership matters more than office |
| `extensionAttribute3` | Access profile / pilot cohort | `DCE-Standard`, `DCE-Leadership`, `DCE-LocationOwner`, `DCE-CrossTenant-Test` | Preferred pilot/profile driver |

---

## Group Taxonomy

### Tier 1 — Baseline groups
These apply broadly across DCE.

| Group | Membership basis | Type | Purpose |
|---|---|---|---|
| `AllStaff` | `companyName` or approved DCE department match | Dynamic | Broad baseline access |
| `Managers` | leadership title pattern or leadership access profile | Dynamic | Elevated baseline access |
| `Marketing` | marketing department or marketing role | Dynamic | Marketing site/edit access |
| `Stylists` | stylist title or role | Dynamic | Mail routing and future workload partitioning |

### Tier 2 — Functional groups
These should be driven mainly by `extensionAttribute1`.

| Group | Suggested rule basis | Purpose |
|---|---|---|
| `DCE-Operations` | `extensionAttribute1 = Operations` | operations resources |
| `DCE-ClientServices` | `extensionAttribute1 = ClientServices` | client-services resources |
| `DCE-Marketing` | `extensionAttribute1 = Marketing` | marketing workloads |
| `DCE-Leadership` | `extensionAttribute1 = Leadership` or leadership access profile | leadership-only access |
| `DCE-Stylists` | `extensionAttribute1 = Stylist` | stylist-specific targeting |

### Tier 3 — Location groups
These should be driven by `officeLocation` or `extensionAttribute2`.

| Group | Suggested rule basis | Purpose |
|---|---|---|
| `DCE-Loc-LV` | `officeLocation = DCE-LV` or `extensionAttribute2 = DCE-LV` | Las Vegas location access |
| `DCE-Loc-PHX` | `officeLocation = DCE-PHX` or `extensionAttribute2 = DCE-PHX` | Phoenix location access |
| `DCE-Loc-DAL` | `officeLocation = DCE-DAL` or `extensionAttribute2 = DCE-DAL` | Dallas location access |

### Tier 4 — Pilot and exception-control groups
Keep these small and deliberate.

| Group | Membership basis | Purpose |
|---|---|---|
| `DCE-CrossTenant-Pilot` | static pilot membership or `extensionAttribute3 = DCE-CrossTenant-Test` | pilot validation cohort |
| `DCE-Location-Owners` | `extensionAttribute3 = DCE-LocationOwner` | location-owner admin-ish scenarios |

---

## Recommended Membership Logic

### Baseline groups

#### `AllStaff`
Short-term:
- existing rule can remain based on `department` / `companyName`

Long-term preferred:
- `companyName = Delta Crown Extensions`
- exclude disabled or out-of-scope identities where needed

#### `Managers`
Short-term:
- existing title-based logic remains acceptable

Long-term preferred:
- `extensionAttribute1 = Leadership`
  or
- `extensionAttribute3 = DCE-Leadership`

That is cleaner than asking free-text job titles to be your IAM platform. Gross.

#### `Marketing`
Current script basis:
- `department = Delta Crown Marketing`

Preferred future basis:
- `extensionAttribute1 = Marketing`

### Functional groups
Preferred basis:
- `extensionAttribute1`

That gives one clean business-role axis instead of guessing from every department/title combination.

### Location groups
Preferred basis:
- `officeLocation` for where the person primarily works
- `extensionAttribute2` for the location they own or govern

If ownership and work location diverge, use both attributes intentionally.
Do not fake ownership with a department label.

### Pilot group
Preferred basis for first rollout:
- **static membership**

Why?
Because pilot groups should be explicit and tiny.
That keeps the blast radius low while validating the model.

---

## Resource Mapping Matrix

### SharePoint Sites

| Resource | Baseline access | Specialized access | Notes |
|---|---|---|---|
| `/sites/dce-hub` | `AllStaff = Read` | `Managers = Full Control` | Aligns to current hardening script |
| `/sites/dce-clientservices` | `AllStaff = Contribute` (current) | `Managers = Full Control`, preferred future: `DCE-ClientServices = Contribute` | Current script is broad; future should tighten to function-driven access where practical |
| `/sites/dce-marketing` | `AllStaff = Read` | `Managers = Full Control`, `Marketing = Edit`, optional `DCE-Marketing = Edit` | Current script already special-cases Marketing |
| `/sites/dce-docs` | `AllStaff = Read` | `Managers = Full Control` | Use library-level tightening only where justified |
| `/sites/dce-operations` | Teams-managed | `DCE-Operations`, `DCE-Leadership` via Team/channel membership | Keep Teams governance aligned to group model |

### SharePoint location-specific pattern
Use location groups only where the business truly needs location-segmented access.

| Scope | Recommended group |
|---|---|
| Location-specific document library | `DCE-Loc-*` |
| Location-specific folder set | `DCE-Loc-*` |
| Location-owner review workspace | `DCE-Location-Owners` + relevant `DCE-Loc-*` |

Do not create location groups for decoration. Only do it where access really differs.

### Teams

| Teams workload | Group alignment |
|---|---|
| Delta Crown Operations Team | `AllStaff` baseline, with channel-specific tightening as needed |
| Leadership private channel | `DCE-Leadership` |
| Marketing channel / future team | `Marketing` or `DCE-Marketing` |
| Future client-services collaboration area | `DCE-ClientServices` |

### Shared Mailboxes

| Mailbox | Send-As | Full Access | Notes |
|---|---|---|---|
| `operations@deltacrown.com` | `AllStaff` | `Managers` | current documented model |
| `bookings@deltacrown.com` | `AllStaff` | `AllStaff` | current documented model |
| `info@deltacrown.com` | `AllStaff` | `Managers` | current documented model |

Future refinement option:
- if broad mailbox access becomes noisy, shift from `AllStaff` to functional groups.
But don’t overcomplicate it before you’ve earned that pain.

### Apps

| App pattern | Recommended assignment |
|---|---|
| Everyone in DCE uses it | `AllStaff` |
| Leadership-only app | `DCE-Leadership` or `Managers` |
| Marketing app | `Marketing` or `DCE-Marketing` |
| Location-specific app | relevant `DCE-Loc-*` group |
| Pilot validation access | `DCE-CrossTenant-Pilot` only during testing |

---

## Tyler Pilot Mapping

## Target identity
- `tyler.granlund@httbrands.com`

## Intended test posture
| Attribute | Recommended value |
|---|---|
| `sourceTenant` | `httbrands.com` |
| `identityType` | `CrossTenantPilot` |
| `companyName` | `Delta Crown Extensions` |
| `department` | `Delta Crown Operations` |
| `jobTitle` | `Manager` or real target test title |
| `officeLocation` | chosen pilot location code, e.g. `DCE-LV` |
| `employeeType` | `TestUser` or `Partner` |
| `extensionAttribute1` | `Leadership` or target function being tested |
| `extensionAttribute2` | target owned location code |
| `extensionAttribute3` | `DCE-CrossTenant-Test` |

## Expected group outcome
At minimum Tyler should land in:
- `AllStaff`
- `Managers` or `DCE-Leadership` depending on chosen test role
- relevant functional group(s)
- relevant location group(s)
- `DCE-CrossTenant-Pilot`

## Expected resource outcome
Tyler should be able to validate:
- DCE hub visibility
- correct SharePoint sites
- correct Teams/channel access
- correct shared mailbox visibility if assigned
- correct app access if assigned
- lack of access to out-of-scope resources

---

## Implementation Priorities

### Priority 1 — Data readiness
1. fill out `templates/dce-user-access-matrix-template.csv`
2. confirm canonical role values
3. confirm canonical location codes
4. decide whether ownership uses `officeLocation`, `extensionAttribute2`, or both

### Priority 2 — Group rule normalization
1. keep current `AllStaff` / `Managers` rules for now
2. add functional groups based on `extensionAttribute1`
3. add location groups based on `officeLocation` or `extensionAttribute2`
4. create `DCE-CrossTenant-Pilot` as a static pilot group

### Priority 3 — Resource alignment
1. verify current SharePoint permissions match intended groups
2. identify places where `AllStaff` is too broad
3. shift specialized access toward functional/location groups
4. keep mailbox permissions group-based

### Priority 4 — Verification
1. onboard Tyler as pilot
2. confirm synced object exists
3. confirm attribute values are correct
4. confirm group memberships resolve
5. execute positive and negative access tests

---

## Script Impact Summary

### Existing scripts impacted
- `phase2-week1/scripts/2.3-AzureAD-DynamicGroups.ps1`
- `phase3-week2/scripts/3.3-Security-Hardening.ps1`
- `phase3-week2/scripts/3.7-Phase3-Verification.ps1`
- any future Exchange or app-assignment automation

### Changes implied
1. add new dynamic-group definitions for functional and location groups
2. stop relying only on free-text `jobTitle` for leadership/functional logic
3. update security hardening permission matrix to optionally use functional groups
4. update verification to check new groups and pilot access expectations

---

## Definition of Done
This mapping is operationally ready when:
- user rows are filled out in the access matrix
- attributes are normalized
- dynamic groups are created
- resource mappings are assigned to groups
- Tyler pilot onboarding succeeds
- positive and negative access tests pass
- no one needed direct user permissions to fake success
