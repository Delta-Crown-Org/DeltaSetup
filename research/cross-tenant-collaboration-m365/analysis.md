# Analysis: Cross-Tenant Collaboration, SharePoint Access, and Identity Sequencing

## Executive Summary
DeltaSetup's current architecture is still right: **single-tenant brand hub + Teams-connected operations site + standalone functional sites**.

The second-pass question is not whether that architecture is wrong. It is whether we understand the failure modes when we later extend similar patterns into **cross-tenant collaboration**.

The answer from the HTT incident history is very clear:

> **Do not use resource-tenant dynamic groups as the inbound B2B collaboration gate.**

That is how you get the classic chicken-and-egg failure:
- user needs a guest/member object in the resource tenant
- dynamic group needs that object to evaluate membership
- inbound policy requires dynamic-group membership before the object can exist
- user gets blocked before the system can provision the identity path

## The Two-Layer Model

### Layer 1: Cross-Tenant Admission
This is controlled by **Microsoft Entra cross-tenant access policy**.

Question answered here:
> Can this external identity enter the tenant at all?

Characteristics:
- evaluated before SharePoint permission logic matters
- controls inbound/outbound B2B collaboration trust
- controls automatic redemption and cross-tenant sync prerequisites
- should be scoped by **partner tenant** and **application**, not by resource-tenant dynamic groups

### Layer 2: Resource Authorization
This is controlled by **SharePoint permissions, Teams membership, M365 groups, dynamic groups, sensitivity labels, and DLP**.

Question answered here:
> Now that the user object exists, what can they actually access?

Characteristics:
- safe place for dynamic groups
- safe place for SharePoint groups and site-level ACLs
- safe place for business authorization and least-privilege design

## Why Convention-Page-Build Failed
The prior HTT incident hit `AADSTS500213` because inbound B2B collaboration policy was scoped to **dynamic groups in the resource tenant**.

That created a deadlock:
1. user attempted first access
2. Entra evaluated inbound B2B collaboration
3. policy expected the user to be in a resource-tenant dynamic group
4. user had no guest object yet
5. no object meant no dynamic-group membership
6. no dynamic-group membership meant policy deny
7. policy deny prevented the user from ever reaching the object-creation path

The eventual fix was sane:
- set inbound B2B collaboration `usersAndGroups` to `AllUsers`
- keep application scoping tight, especially to SharePoint Online where appropriate
- enforce actual access at SharePoint via groups and permissions

That preserved security without breaking first-run access.

## Pattern Comparison

| Pattern | Best Fit | SharePoint Site Access | Teams | Admin Overhead | UX Friction |
|---|---|---:|---:|---:|---:|
| Single-tenant internal users | DeltaSetup baseline | Excellent | Excellent | Low | Low |
| B2B collaboration guests | External access / bounded collaboration | Yes | Yes | Medium | Medium/High |
| Cross-tenant sync | Repeat collaboration between related orgs | Yes | Yes | High | Medium |
| B2B Direct Connect | Teams shared channels only | No for normal site access | Yes, shared channels | Medium | Medium |

## When Dynamic Groups Are Safe
Dynamic groups are safe when they evaluate **after** the user object exists in the resource tenant.

Examples:
- SharePoint Visitors / Members / Owners group membership
- Teams team membership
- M365 group authorization
- DLP policy scoping
- audience targeting

## When Dynamic Groups Are Dangerous
Dynamic groups are dangerous when used as a dependency for **first admission** into the tenant.

Danger zone:
- inbound B2B collaboration `usersAndGroups`
- partner-policy scoping that assumes a guest/member object already exists

## User Experience Differences by Pattern

### B2B Guest
- works well for normal SharePoint and Team access
- often produces guest/external badges and tenant-switching friction
- first-run depends on invite/redemption state and bilateral trust settings
- support burden is usually highest here

### Cross-Tenant Sync
- reduces invitation churn
- can create more predictable directory state before access is granted
- improves repeat collaboration patterns
- still requires careful sync scope, attribute mapping, and lifecycle governance

### B2B Direct Connect
- best for Teams shared channels
- wrong mental model for standard SharePoint portal/site access
- should be documented as a specialized option, not a general answer

## Critical Order-of-Operations Insight
Order matters because Microsoft evaluates these systems at different points in the identity journey.

### Safe Sequence
1. establish deny-by-default tenant posture with explicit partner overrides
2. configure partner-specific inbound/outbound B2B collaboration
3. enable bilateral automatic redemption where needed
4. enable cross-tenant sync prerequisites if using sync
5. decide `userType` and attribute mappings **before production onboarding**
6. provision pilot identities
7. verify objects exist in resource tenant
8. verify dynamic groups evaluate correctly
9. assign SharePoint / Teams authorization
10. expand scope gradually

### Unsafe Sequence
1. create dynamic groups in resource tenant
2. scope inbound B2B partner policy to those groups
3. expect first-time users to pass that gate
4. discover nobody can get in
5. suffer

## Sync-Specific Concerns
Cross-tenant sync is useful, but it introduces its own traps:
- attribute mapping must support the authorization model
- `department`, `companyName`, and `jobTitle` matter if target dynamic groups depend on them
- `showInAddressList=True` matters if collaboration should feel more internal
- `userType` must be decided early; changing it later is messy
- scope changes can behave like deprovisioning events, not harmless filters

## Design Implications for DeltaSetup

### For current Delta Crown work
Nothing here invalidates the current single-tenant architecture.
It reinforces it.

### For future HTT / multi-tenant reuse
DeltaSetup should add a cross-tenant architecture layer that says:
- stay single-tenant when possible
- use B2B guests for bounded external collaboration
- use cross-tenant sync when collaboration is recurring and worth the overhead
- reserve B2B Direct Connect for Teams shared-channel use cases
- separate admission policy from SharePoint authorization every single time

## Failure Modes to Plan For
- `AADSTS500213` from inbound policy denial before object creation
- one-sided automatic redemption causing confusing first-run prompts
- over-narrow app scoping that blocks supporting sign-in/MFA experience
- userType mismatch between intended and actual synced result
- sync timing delays misdiagnosed as permission failures
- Team membership propagation lag misdiagnosed as SharePoint denial
- shared-channel assumptions leaking into standard Team/site troubleshooting

## Architectural Conclusion
The architecture lesson is not “dynamic groups are bad.”
The lesson is:

> **Dynamic groups are excellent authorization tools, but terrible first-admission gates in cross-tenant B2B collaboration when they depend on objects that do not yet exist.**

That distinction needs to become part of DeltaSetup’s formal architecture language before future cross-tenant planning continues.
