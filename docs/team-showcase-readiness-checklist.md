# Team Showcase Readiness Checklist

## Purpose

This checklist freezes the story before the Delta Crown Microsoft 365 operating model is shown to the team. It separates what is already safe to say from what still needs tenant evidence.

The showcase should build confidence without pretending the live tenant is fully cleaned up. Pretty slides are not a substitute for verified permissions. That is the whole point of this checklist.

## Approved user-facing names

Inside the Delta Crown tenant, use simple contextual names. Do not add redundant `DCE-` prefixes to user-facing names.

Approved labels:

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

Technical/internal IDs may still contain older names until the tenant audit proves what exists and what is safe to rename or repurpose.

## Scope freeze

### In scope for the showcase

- Explain the intended Microsoft 365 operating model.
- Show the public project site and Ops View.
- Explain identity-driven access: each person's role and location determine which workspaces they can see.
- Explain Brand Resources as the replacement direction for legacy client-service/client-record assumptions.
- Explain that the HTT Brands `Master DCE` folder must be audited before content is moved, copied, shortcut, or retired.
- Explain that tenant inventory is the next gate before production cleanup.

### Out of scope for the showcase

- Claiming all Master DCE files have migrated.
- Claiming all live tenant resources are already production-clean.
- Claiming every SharePoint/Teams permission is verified.
- Claiming client records live in Microsoft 365.
- Performing live tenant cleanup during the showcase.
- Renaming/deleting live resources just to make the story prettier.

## Current narrative

Use this plain-language version:

> Delta Crown has defined a clean Microsoft 365 operating model and is validating it against the live tenant: identity drives access, access opens the right workspaces, and the old HTT Brands Master DCE folder is being audited before anything is rationalized into Operations, Brand Resources, Marketing, Docs, Training, Corporate Reference, or Archive.

## What is safe to say now

| Statement | Status | Notes |
|---|---|---|
| The public showcase site is live. | Safe | Root and Ops View are published and accessible. |
| User-facing names should be generic inside the tenant. | Safe | Hub, Operations, Brand Resources, Marketing, Docs, etc. |
| Client records are out of Microsoft 365 scope. | Safe | Do not present Client Services/Client Experience as client data storage. |
| Master DCE is the source folder to audit. | Safe | It lives in HTTHQ Shared Documents. |
| Brand Resources is the intended replacement concept for legacy ClientServices assumptions. | Safe | Exact tenant implementation pending audit. |
| Tenant resources need inventory before production cleanup. | Safe | Identity, SharePoint, Exchange, security singleton policies, apps/licenses, and duplicate group evidence have been inventoried; Teams/channel detail is blocked on a licensed Teams-readable context. |

## What must be phrased carefully

| Topic | Careful wording |
|---|---|
| Brand Resources | “This is the target resource model. The audit will confirm whether we repurpose an existing resource, create a new one, or use shortcuts.” |
| Teams channels | “The DCE Operations Microsoft 365 group exists and has known group membership, but Teams/channel layout is blocked until we use a licensed Teams-readable DCE context or owner attestation.” |
| Automatic role groups | “AllStaff currently resolves to six users; Managers, Marketing, Stylists, and External currently resolve to zero because user metadata is incomplete.” |
| Master DCE content | “We are auditing and mapping, not bulk-migrating.” |
| Security posture | “Security defaults are disabled, admin consent request workflow is disabled, and authentication method states are documented. Do not claim the full security model is final until consolidated inventory/readiness review is complete.” |
| Duplicate Delta Crown Extensions groups | “Two public Teams-provisioned Microsoft 365 groups have the same display name and identical member/owner sets. Do not delete either until Teams dependencies are reviewed.” |

## What not to say

Do not say:

- “Everything has been migrated.”
- “Permissions are fixed.”
- “Client records are in SharePoint.”
- “Brand Resources is fully live and production-ready.”
- “All security policies are final.”
- “Every group automatically works already.”
- “We can just rename/delete the old ClientServices stuff.”

A small overstatement now creates a real cleanup problem later.

## Do-not-change guardrails

Do not change any live tenant resources until audit evidence exists and the owner approves the action.

Specifically, do not:

- rename SharePoint site URLs;
- delete or repurpose legacy ClientServices resources;
- copy, move, or delete Master DCE content;
- change Master DCE permissions;
- alter security, compliance, data-protection, or sharing policies;
- delete registered apps or integrations;
- change email lists, groups, Teams, channels, or license settings;
- add client records to Microsoft 365.


## Data handling rule

Client records and client PII are out of scope. Do not search for, export, open, sample, screenshot, or commit client records as part of showcase readiness. If any old demo/client-record list appears during audit, stop and classify it as a legacy artifact for cleanup review.

## Demo safety rule

Use public pages, sanitized screenshots, or a least-privilege non-admin demo account for the showcase. Do not show live admin portals, registered app credentials, user lists, mailbox views, group membership screens, permission pages, finance/strategy folders, or tenant policy pages unless they are specifically approved and redacted for the demo.

## Current evidence snapshot

| Area | Evidence | Showcase impact |
|---|---|---|
| User metadata | `companyName` populated for 6/89 users; `department` 49/89; `jobTitle` 48/89; `officeLocation` 22/89; `employeeType` 6/89. | Explain identity-driven access as the target/control model, but state broader metadata cleanup is required before all role groups are complete. |
| Dynamic groups | AllStaff = 6; Managers = 1; Marketing/Stylists/External = 0. | Safe to explain the mechanism; not safe to claim all automatic groups are fully populated. |
| SharePoint | PnP inventory verifies DCE sites, sharing posture, ClientServices list/library detail, and permissions. | Safe to discuss audited site/resource direction; do not claim all cleanup actions are approved. |
| ClientServices artifacts | Client Records, Consent Forms, and Feedback lists are empty and inherit broad web permissions from DCE Client Services. | Safe to say these appear to be legacy artifacts, but do not delete/repurpose until owner-approved cleanup. |
| Duplicate groups | Two public Teams-provisioned `Delta Crown Extensions` groups exist with identical 86-member/4-owner sets and distinct SharePoint sites. | Mention as a known cleanup item only if needed; do not show as production-clean. |
| Teams/channels | DCE Operations group is readable; Teams endpoints fail for current context due license/read access. | Do not demo or claim channel layout is verified unless owner attestation or licensed Teams-readable access is provided. |
| Security singleton policies | Security defaults disabled; admin consent request workflow disabled; auth method states documented. | Safe to say security policy evidence has improved; not safe to claim final production governance. |

## Required evidence before final showcase signoff

| Evidence | Source issue | Required for final signoff? | Current status |
|---|---|---|---|
| Master DCE audit runbook | DeltaSetup-126 | Yes | Complete from prior work. |
| Master DCE audit outputs or documented auth blocker | DeltaSetup-127 | Yes | Complete/documented from prior work. |
| Master DCE resource map | DeltaSetup-128 | Yes | Complete. |
| Tenant inventory access matrix | DeltaSetup-131 | Yes | Complete. |
| Identity inventory | DeltaSetup-132 / DeltaSetup-120 | Yes | Complete; metadata gaps documented. |
| SharePoint inventory | DeltaSetup-133 / DeltaSetup-144 / DeltaSetup-149 | Yes | Complete for current accessible scope; detailed PnP evidence documented. |
| Teams/channel inventory | DeltaSetup-134 / DeltaSetup-151 | Yes | Blocked on licensed Teams-readable context or owner attestation. |
| Security/apps/licenses inventory | DeltaSetup-136 / DeltaSetup-147 | Yes | Security singleton gaps resolved; full consolidation still pending. |
| Tenant inventory consolidation | DeltaSetup-137 | Yes | Blocked behind Teams inventory. |
| Showcase-vs-tenant gap analysis | DeltaSetup-138 | Yes | Blocked behind consolidated inventory. |
| Team showcase runbook/FAQ/scorecard/demo script | DeltaSetup-139 | Yes | Blocked behind gap analysis. |

## Go / no-go checklist

### Green: safe to showcase

- [x] Public root site loads.
- [x] Ops View loads.
- [x] Public site uses generic resource names.
- [x] No public-facing client-record claims remain.
- [x] Presenter can explain Master DCE audit status.
- [x] Presenter can explain tenant inventory status.
- [x] Known gaps are documented.
- [x] No sensitive live tenant screens are part of the demo flow.

### Yellow: mention carefully

- [x] Brand Resources implementation path is not yet final.
- [x] Teams/channel state still needs licensed Teams-readable verification or owner attestation.
- [x] Role-specific automatic groups (Managers, Marketing, Stylists, External) depend on employee metadata cleanup.
- [x] Some corporate-owned resources may remain in HTT and be referenced by shortcut.
- [x] Duplicate `Delta Crown Extensions` groups are known and must not be deleted before Teams dependency review.

### Red: do not showcase as complete

- [x] Unverified permissions.
- [x] Financial/strategy folders before access review.
- [x] Client records or client PII.
- [x] Admin screens exposing secrets, app credentials, or sensitive tenant details.
- [x] Anything requiring an unapproved live tenant change.

## First sprint completion criteria

This issue is complete when:

- this checklist exists;
- it uses generic resource names;
- it states client records are out of scope;
- it separates showcase-ready from production-ready;
- it points to the audit and inventory gates;
- no live tenant change is required to satisfy it.

Status: complete for checklist/readiness framing. Final showcase signoff still depends on the remaining inventory/gap-analysis issues above. Tiny distinction, huge consequences — the kind of boring precision that keeps demos from becoming incident reports.
