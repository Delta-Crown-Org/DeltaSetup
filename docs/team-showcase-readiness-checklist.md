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
| Tenant resources need inventory before production cleanup. | Safe | Security policies, groups, sites, Teams, email, apps, and licenses all need review. |

## What must be phrased carefully

| Topic | Careful wording |
|---|---|
| Brand Resources | “This is the target resource model. The audit will confirm whether we repurpose an existing resource, create a new one, or use shortcuts.” |
| Teams channels | “The Operations group/member state is known from prior checks, but channel layout still needs verification.” |
| Automatic role groups | "AllStaff has live membership; role-specific groups (Managers, Stylists) depend on employee data cleanup and verification." |
| Master DCE content | “We are auditing and mapping, not bulk-migrating.” |
| Security posture | “Security policies are part of the inventory and readiness gates; do not claim full production readiness until verified.” |

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

## Required evidence before final showcase signoff

| Evidence | Source issue | Required for final signoff? |
|---|---|---|
| Master DCE audit runbook | DeltaSetup-126 | Yes |
| Master DCE audit outputs or documented auth blocker | DeltaSetup-127 | Yes |
| Master DCE resource map | DeltaSetup-128 | Yes |
| Tenant inventory access matrix | DeltaSetup-131 | Yes |
| Tenant inventory outputs or documented blockers | DeltaSetup-132 – DeltaSetup-137 | Yes |
| Showcase-vs-tenant gap analysis | DeltaSetup-138 | Yes |
| Team showcase runbook/FAQ/scorecard/demo script | DeltaSetup-139 | Yes |

## Go / no-go checklist

### Green: safe to showcase

- [ ] Public root site loads.
- [ ] Ops View loads.
- [ ] Public site uses generic resource names.
- [ ] No public-facing client-record claims remain.
- [ ] Presenter can explain Master DCE audit status.
- [ ] Presenter can explain tenant inventory status.
- [ ] Known gaps are documented.
- [ ] No sensitive live tenant screens are part of the demo flow.

### Yellow: mention carefully

- [ ] Brand Resources implementation path is not yet final.
- [ ] Teams/channel state may still need verification.
- [ ] Role-specific automatic groups (Managers, Stylists) may depend on employee data cleanup.
- [ ] Some corporate-owned resources may remain in HTT and be referenced by shortcut.

### Red: do not showcase as complete

- [ ] Unverified permissions.
- [ ] Financial/strategy folders before access review.
- [ ] Client records or client PII.
- [ ] Admin screens exposing secrets, app credentials, or sensitive tenant details.
- [ ] Anything requiring an unapproved live tenant change.

## First sprint completion criteria

This issue is complete when:

- this checklist exists;
- it uses generic resource names;
- it states client records are out of scope;
- it separates showcase-ready from production-ready;
- it points to the audit and inventory gates;
- no live tenant change is required to satisfy it.
