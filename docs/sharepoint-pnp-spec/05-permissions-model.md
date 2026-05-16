# 05 — Permissions Model

## North star

> **Inherit unless there's a documented reason not to. Audience-target,
> don't break inheritance, for visibility-only concerns.**

This is the philosophical antidote to the HTT Brands Headquarters
cluster, where permission breaks proliferate organically and end up
creating a maintenance nightmare.

## SharePoint permission primitives (the short version)

Each securable object (site, list, library, folder, item) has a
**role assignment** that's either **inherited** (from its parent) or
**unique** (broken, hand-curated). Permissions cannot be partially
inherited.

A role assignment is `{ principal, role definition }` where:

- **Principal** = a user, security group, or SharePoint group.
- **Role definition** = `Read`, `Contribute`, `Edit`, `Design`,
  `Full Control`, or a custom-defined role.

## Permission set-up per site

### DCE Hub (`/sites/dce-hub`)

| Principal | Role | Mechanism |
|---|---|---|
| Tyler Granlund (Admin) | Site Collection Admin + Full Control | Site Collection Admin assignment (separate from groups) |
| `DCE-Site-Owners` (M365 group) | Owner / Full Control | SharePoint Owner group |
| `DCE-Franchisor-Leadership` | Member / Edit | SharePoint Member group |
| `DCE-Managers` | Member / Edit | SharePoint Member group |
| `DCE-AllStaff` | Visitor / Read | SharePoint Visitor group |
| `Crown Connection` (the M365 group for owners) | Visitor / Read | Added to Visitor group |
| HTT corp users (via cross-tenant sync) | Visitor / Read | Added to Visitor group implicitly via "DCEAllHTT" placeholder group |

**No permission breaks anywhere by default.** Audience targeting
handles visibility variations (e.g., Admin page).

### Crown Connection (`/sites/CrownConnection`)

| Principal | Role | Mechanism |
|---|---|---|
| Tyler Granlund (Admin) | Site Collection Admin | Manual assignment |
| Kristin Kidd, Jenna Bowden | Group Owner | M365 group owner |
| `Crown Connection` group members (57) | Group Member / Edit | M365 group implicit |

**Permission breaks:** one library — "Owner-only library" — breaks
inheritance and is shared only with R3 (DCE Franchise Owners). All
other content uses audience targeting at the web-part level.

### Future: DCE Brand Center

| Principal | Role |
|---|---|
| Tyler, Jenna | Site Collection Admin / Full Control |
| Designer-of-the-day (single user or small group) | Edit |
| Everyone else | Read |

Read is broad because brand assets benefit from discoverability. No
permission breaks expected.

## Permission breaks — when and why

Breaks are ALLOWED only when the use case satisfies ALL of:

1. The content is confidential (executive comp, HR investigation,
   pending acquisition).
2. Audience targeting would be insufficient (e.g., someone could find
   the content via search and request access).
3. The break has an owner documented and a sunset date (if known).
4. The break is registered in `reference/permission-breaks.csv` (see
   `09-deployment.md` for the artifact).

Anything else uses audience targeting.

## Audit mechanism

> **You cannot manage what you don't measure.**

We implement a **permission audit job** that:

1. Runs weekly (cron-style, via GitHub Actions on a schedule).
2. For each DCE site, enumerates all sub-objects (libraries, lists,
   folders, items) where `HasUniqueRoleAssignments == true`.
3. Cross-references against `reference/permission-breaks.csv`.
4. Flags discrepancies: undocumented breaks (drift) or documented
   breaks that no longer exist (stale entries).
5. Posts results to a SharePoint list at `/sites/dce-hub/Lists/PermissionAuditLog`
   and emails Tyler.

The existing `sharepointagent/audit_folder_permissions.py` is the
foundation. Wrap it in a GitHub Actions workflow.

Sample audit output schema (CSV):

```csv
SiteUrl,Path,Type,HasUniqueRoleAssignments,DocumentedBreak,DriftStatus
/sites/dce-hub,/Documents,Library,false,n/a,OK
/sites/CrownConnection,/Documents/Owner-only library,Library,true,YES (DOC-001),OK
/sites/CrownConnection,/Documents/Marketing,Folder,true,NO,DRIFT
```

## Sharing settings

### Tenant-level

Configured in SharePoint Admin Center. Tyler maintains.

- External sharing: **New and existing guests** (most restrictive
  that still allows our B2B flow).
- Default sharing link type: **Specific people**.
- Default link permission: **View** (recipients need explicit
  permission grant; no "Edit" link sprawl).
- Anonymous links: **Disabled**.

### Site-level overrides

| Site | External sharing |
|---|---|
| DCE Hub | Tenant default (New and existing guests) |
| Crown Connection | **Existing guests only** — no new B2B invites from inside the site, must come via admin or sync |
| DCE Brand Center | Tenant default |
| Owner-only library (in Crown Connection) | **No external sharing** |

## SharePoint group membership matrix

Each site has the standard three SharePoint groups (Owners / Members /
Visitors). For DCE Hub:

| SharePoint group | Backing M365 group / principal |
|---|---|
| Hub Owners | `DCE-Site-Owners` |
| Hub Members | `DCE-Franchisor-Leadership` + `DCE-Managers` |
| Hub Visitors | `DCE-AllStaff` + (via implicit B2B propagation) HTT corp synced users |

This means a new manager hired tomorrow is added to `DCE-Managers`
once → automatically gets Edit on the Hub.

## Cross-tenant guest specifics

HTT corp users (`userType: Member` via sync) participate normally in
permissions. They don't trigger any special handling — they're just
DCE Members.

Real B2B guests (from outside HTT — partners, vendors) would have
`userType: Guest` and are subject to the tenant external-sharing
policy.

## Edge cases

### "I want this one file readable by everyone but writable by only me"

- Don't break inheritance.
- Use **document-level versioning + check-out** in the library.
- If true exclusivity is needed, move to your OneDrive and share a
  link from there.

### "We need an audit trail for who accessed this folder"

- Enable **Audit log** in Microsoft Purview at the tenant level (Tyler
  enables once; covers all of DCE).
- Query via Microsoft Graph `auditLogs/signIns` and
  `auditLogs/directoryAudits`.
- Don't break permissions to "track access" — that's not what breaks
  do.

### "This content is owners-only forever"

- Owner-only library in Crown Connection (already planned). One
  break, well documented, with an audit alert.

## Anti-patterns

1. **Item-level permission breaks.** Files break inheritance from the
   library. Almost never necessary; almost always a bug.
2. **Permission breaks for "temporary visibility."** Use audience
   targeting; revisit when the temporary status changes.
3. **Per-user permissions.** Always go through a group. Per-user is
   noise we can't easily audit.
4. **Granting "Full Control" to non-admins.** Use Edit instead — Full
   Control includes the ability to change permissions, which they
   don't need.
