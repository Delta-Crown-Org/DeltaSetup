# Delta Crown Tenant Inventory Plan

## Purpose

After the Master DCE folder audit, run a full Microsoft 365 tenant inventory so the team can explain every major resource created in the Delta Crown environment: what it is, why it exists, who owns it, who has access, and whether it is ready for showcase or production use.

This is the control sheet for avoiding mystery infrastructure. Mystery infrastructure is just technical debt wearing a fake mustache.

## Naming principle

Inside the Delta Crown tenant, resource names should be simple and contextual. Avoid redundant prefixes like `DCE-` in user-facing names because the tenant and domain already establish the brand context.

Preferred user-facing names:

- Hub
- Operations
- Brand Resources
- Marketing
- Docs
- Training
- Leadership
- AllStaff
- Managers
- Stylists

Technical/internal IDs may still retain legacy names until they are intentionally renamed or recreated. Do not rename production resources blindly just to make a slide prettier.

## Inventory outputs

Create a final inventory workbook or CSV set with these columns:

| Column | Purpose |
|---|---|
| Resource type | Conditional Access, group, SharePoint site, Team, mailbox, app, policy, etc. |
| Display name | User-facing name. |
| Technical name / ID | Object ID, mail nickname, URL, app ID, or policy ID. |
| Purpose | Why this exists. |
| Owner | Business/technical owner. |
| Access model | Who gets access and how. |
| Provisioning driver | Manual, static group, dynamic group, script, Graph, Exchange, SharePoint, etc. |
| Dependencies | Groups, users, sites, apps, policies this relies on. |
| Current status | Live, draft, pending verification, deprecated, needs cleanup. |
| Showcase status | Safe to show, mention carefully, do not show yet. |
| Follow-up | Any remediation needed. |

## Areas to inventory

### Identity and access

- Users in the tenant
- User metadata completeness
- Managers / departments / titles / locations
- Dynamic group rules
- Static group memberships
- Guest/external/corporate users
- Cross-tenant access settings
- MFA/passkey/security registration posture

### Groups

- Security groups
- Microsoft 365 groups
- Dynamic groups
- Mail-enabled security groups
- Distribution lists
- Group owners
- Group purpose
- Membership rules or manual membership source

### Conditional Access and security policies

- Conditional Access policies
- Authentication strength / MFA requirements
- Named locations
- Session controls
- External sharing controls
- Sensitivity labels
- DLP policies
- Retention/governance policies
- Audit/logging status

### SharePoint

- Sites
- Site URLs
- Site owners
- Hub associations
- Libraries
- Lists
- Navigation
- Unique permissions
- External sharing status
- Any broken inheritance that is intentional vs accidental

### Teams

- Teams
- Channels
- Private/shared channels
- Owners
- Members
- Tabs/apps
- Connected SharePoint folders
- Channel moderation/settings

### Exchange

- Accepted domains
- User mailboxes
- Shared mailboxes
- Distribution lists
- Aliases
- Send As / Full Access permissions
- Mail flow or routing rules if any

### Applications and automation

- App registrations
- Enterprise applications
- PnP app registrations
- Graph permissions
- Automation scripts used
- Secrets/certificates/thumbprints
- Expiration dates
- Admin consent status

### Licensing and billing

- License SKUs
- Assigned licenses by user
- Unassigned licenses
- Service plan availability
- Any license-dependent features used by the deployment

## Showcase readiness rules

A resource is safe to showcase when:

- its purpose is explainable in one sentence;
- its owner is known;
- its access model is known;
- its status is verified in the live tenant;
- it does not expose stale client-service/client-record assumptions;
- any pending work is clearly labeled.

## Sequence

1. Complete Master DCE folder audit.
2. Decide what content maps to Operations, Brand Resources, Marketing, Docs/Training, Corporate Reference, or Archive.
3. Run full tenant inventory.
4. Compare inventory to the public showcase story.
5. Fix names, permissions, or docs where reality and story disagree.
6. Prepare final team showcase runbook.

## Current tracking issues

- `DeltaSetup-121` — Prepare team showcase readiness checklist
- `DeltaSetup-122` — Audit HTTHQ Master DCE folder structure and permissions
- `DeltaSetup-123` — Repurpose legacy client-service artifacts to Brand Resources model
- `DeltaSetup-124` — Inventory all Delta Crown tenant resources and policies
