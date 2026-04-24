# DCE Role + Location Onboarding Model

## Goal
Create the **simplest repeatable onboarding pattern** for Delta Crown Extensions so an admin can:

1. label each person with the right **role**
2. label the **locations they own or work in**
3. apply those labels consistently to groups and resource access
4. validate the result with a real cross-tenant user (`tyler.granlund@httbrands.com`)
5. reuse the same pattern later in other HTT tenants

This model is intentionally boring. Boring is good. Boring scales.

---

## Core Principle
Use a **three-layer model**:

1. **Identity labels** — the source of truth on the user object
2. **Dynamic groups** — derived from those labels
3. **Resource permissions** — SharePoint, Teams, mailboxes, apps assigned to groups

Do **not** assign users directly to every resource unless there is a one-off exception.
That way lies chaos, sadness, and manual cleanup.

---

## Required Identity Labels
Each onboarded person should have these values defined before access is considered complete.

| Label | Purpose | Example |
|---|---|---|
| `companyName` | brand boundary | `Delta Crown Extensions` |
| `department` | function / team | `Delta Crown Operations` |
| `jobTitle` | role logic | `Manager`, `Stylist`, `Marketing Coordinator` |
| `officeLocation` | primary physical site | `DCE-LV`, `DCE-PHX` |
| `employeeType` | internal vs external pattern | `Employee`, `Partner`, `TestUser` |
| `extensionAttribute1` | canonical business role | `Operations`, `Leadership`, `Marketing`, `ClientServices` |
| `extensionAttribute2` | owned locations list or primary ownership code | `DCE-LV` |
| `extensionAttribute3` | access profile / onboarding cohort | `DCE-Standard`, `DCE-Leadership`, `DCE-CrossTenant-Test` |

## Why these labels
The existing repo already uses:
- `companyName`
- `department`
- `jobTitle`

Those are fine for baseline grouping, but they are **not enough** for scalable location-based access.

So the recommended model is:
- keep existing attributes for current scripts
- add a **small number of extension attributes** for cleaner long-term onboarding

That gives us YAGNI-friendly progress without painting ourselves into a gross corner.

---

## Access Model

### 1. Baseline groups
These should continue to exist or be normalized:

- `AllStaff`
- `Managers`
- `Marketing`
- optionally `Stylists`
- optionally `External` only if there is a clear business case

### 2. Functional groups
Add dynamic groups driven by `extensionAttribute1` where needed:

- `DCE-Operations`
- `DCE-ClientServices`
- `DCE-Marketing`
- `DCE-Leadership`

### 3. Location groups
Add dynamic groups driven by `officeLocation` or `extensionAttribute2`:

- `DCE-Loc-LV`
- `DCE-Loc-PHX`
- `DCE-Loc-DAL`
- etc.

### 4. Cross-tenant test group
Create a small static or dynamic validation group for pilot users:

- `DCE-CrossTenant-Pilot`

This group is where `tyler.granlund@httbrands.com` should land once the synced object exists in the DCE tenant.

---

## Recommended Mapping Logic

### Baseline dynamic group rules
Current rules already support:
- `AllStaff` from `department` or `companyName`
- `Managers` from `companyName` + title keywords

Keep those for now.

### Next-step rules to add
Use extension attributes to avoid overloading free-text titles forever.

#### Example: DCE-Leadership
- `user.extensionAttribute1 -eq "Leadership"`

#### Example: DCE-Operations
- `user.extensionAttribute1 -eq "Operations"`

#### Example: DCE-Loc-LV
- `user.officeLocation -eq "DCE-LV"`
  or
- `user.extensionAttribute2 -eq "DCE-LV"`

#### Example: Cross-tenant pilot
- `user.extensionAttribute3 -eq "DCE-CrossTenant-Test"`
  or manage with static membership for the pilot phase

---

## Resource Assignment Strategy

### SharePoint
Assign site/library permissions to groups, not people.

| Resource | Recommended group mapping |
|---|---|
| `/sites/dce-hub` | `AllStaff = Read`, `Managers = Full Control` |
| `/sites/dce-clientservices` | `DCE-ClientServices = Contribute`, `Managers = Full Control` |
| `/sites/dce-marketing` | `Marketing = Edit`, `AllStaff = Read`, `Managers = Full Control` |
| `/sites/dce-docs` | `AllStaff = Read`, `Managers = Full Control` |
| location-specific libraries/folders | `DCE-Loc-*` groups only where justified |

### Teams
Use Teams for collaboration membership, not as the master source of identity logic.

- broad operations team membership → `AllStaff`
- private leadership access → `DCE-Leadership`
- specialty channels or teams → functional groups

### Shared mailboxes
Mailbox permissions should follow stable role groups.

Current documented pattern already supports:
- `operations@deltacrown.com`
- `bookings@deltacrown.com`
- `info@deltacrown.com`

Keep mailbox access group-based.
Do not hand-wire every mailbox to every user forever like a gremlin.

### Apps
If an app is location-specific or role-specific:
- assign via Entra groups using the same role/location model
- do not invent a separate app-only role taxonomy unless absolutely required

---

## Tyler Cross-Tenant Test User Pattern

## Objective
Use **`tyler.granlund@httbrands.com`** as the first realistic validation user for:
- cross-tenant identity admission
- synced object creation in DCE
- group-driven authorization
- SharePoint / Teams / app access experience

## Recommended approach
1. onboard Tyler through the **same repeatable process** as any other future partner user
2. let the object appear in the DCE tenant as a **Member** if cross-tenant sync is the chosen pattern
3. set labels on the DCE-side synced object:
   - `companyName = Delta Crown Extensions`
   - `employeeType = TestUser` or `Partner`
   - `extensionAttribute1 = Leadership` or the real business role you want to test
   - `extensionAttribute2 = <owned location code>`
   - `extensionAttribute3 = DCE-CrossTenant-Test`
4. add Tyler to `DCE-CrossTenant-Pilot`
5. verify he can access only the expected resources

## Important
Tyler should be used as a **pilot user**, not as the permanent exception path.
If Tyler requires special direct permissions to make the pilot work, the model is wrong.

---

## Simplest Admin Workflow

### Step 1 — Fill out the access matrix
Use `templates/dce-user-access-matrix-template.csv` together with `templates/dce-group-resource-mapping-template.csv`.

For each person define:
- identity email
- role
- department
- title
- primary location
- owned locations
- baseline access profile
- whether they are internal, external, or cross-tenant pilot

### Step 2 — Normalize attribute values
Use a controlled vocabulary.
Do not let this become:
- `manager`
- `Manager`
- `Mgr`
- `Store Manager`
- `Boss Wizard`

Pick one standard and stick to it.

### Step 3 — Sync or create the user
- internal DCE user → native account flow
- HTT user or partner user → approved cross-tenant flow from ADR-004

### Step 4 — Apply labels
Populate the chosen identity attributes.
This is the real onboarding event, not the email saying “welcome aboard.”

### Step 5 — Let dynamic groups resolve
Verify the user lands in the expected groups.

### Step 6 — Test actual experience
Verify:
- SharePoint home / hub visibility
- site access
- Teams/team/channel access
- mailbox visibility if relevant
- app access if relevant

### Step 7 — Capture exceptions
If access needed a direct user assignment, document it as technical debt and fix the model.

---

## Initial Controlled Vocabulary

### Business roles (`extensionAttribute1`)
- `Operations`
- `ClientServices`
- `Marketing`
- `Leadership`
- `Stylist`
- `Finance`
- `Test`

### Access profiles (`extensionAttribute3`)
- `DCE-Standard`
- `DCE-Leadership`
- `DCE-LocationOwner`
- `DCE-CrossTenant-Test`

### Location codes (`officeLocation` or `extensionAttribute2`)
Use short stable codes only.

Examples:
- `DCE-LV`
- `DCE-PHX`
- `DCE-DAL`

---

## Definition of Done for Onboarding
A user is onboarded only when all of these are true:

- correct labels are present on the identity object
- expected dynamic groups are populated
- expected SharePoint resources are visible
- unexpected resources are not visible
- Teams access matches role
- mailbox/app access matches role
- test evidence is captured

If we only create the account but skip the verification, that is not onboarding.
That is clerical cosplay.

---

## Immediate Next Actions
1. finalize the canonical list of DCE roles
2. finalize the canonical list of DCE location codes
3. fill out the user access CSV for current users
4. fill out the group-to-resource mapping CSV
5. decide which attributes will be authoritative in Entra
6. add or update dynamic group rules to use those attributes
7. onboard `tyler.granlund@httbrands.com` as the pilot cross-tenant user
8. validate SharePoint, Teams, mailbox, and app access end to end
9. refine the model before scaling to other tenants
