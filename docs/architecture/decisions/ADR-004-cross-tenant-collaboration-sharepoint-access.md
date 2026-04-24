# ADR-004: Cross-Tenant Collaboration and SharePoint Access Overlay

| Field | Value |
|-------|-------|
| **Status** | Proposed |
| **Date** | 2025-08-08 |
| **Decision Makers** | Code Puppy (`code-puppy-6b0328`) |
| **Security Co-Sign** | Security Auditor — PENDING |
| **Consulted** | Solutions Architect, Experience Architect |
| **Supersedes** | None |
| **Depends On** | ADR-001 (Hub & Spoke Topology), ADR-002 (Phase 3 Sites & Teams) |

---

## Context and Problem Statement

ADR-001 and ADR-002 define DeltaSetup's **primary operating model**:
- one Microsoft 365 tenant
- hub-per-brand
- one Teams-connected operations site
- supporting standalone SharePoint sites
- dynamic groups used for SharePoint / Teams authorization

That baseline remains correct for current Delta Crown work.

The missing piece is a formal architecture overlay for **future cross-tenant collaboration** across HTT brand tenants and related partner organizations.

### Why this ADR now exists
Recent second-pass research and prior HTT project evidence showed that cross-tenant identity flows have failure modes that are easy to trigger when architects casually reuse single-tenant group logic in the wrong layer.

The clearest example came from `Convention-Page-Build`, where inbound B2B collaboration policy was scoped to **dynamic groups in the resource tenant**. That created a chicken-and-egg failure:

1. a first-time external user tried to access SharePoint
2. Entra evaluated inbound B2B collaboration policy
3. the policy required membership in a resource-tenant dynamic group
4. the user had no guest/member object in the resource tenant yet
5. no object meant no dynamic-group membership
6. access was denied before the identity path could complete
7. result: `AADSTS500213`

### The core questions
1. **How should DeltaSetup distinguish single-tenant baseline architecture from future cross-tenant collaboration scenarios?**
2. **When should future work use B2B collaboration guests versus cross-tenant sync users?**
3. **Where are dynamic groups safe, and where are they an anti-pattern?**
4. **What order of operations prevents first-run identity deadlocks and confusing SharePoint / Teams failures?**

### Constraints
- Current Delta Crown architecture remains primarily **single-tenant**
- Future cross-tenant collaboration must work within Microsoft Entra / Microsoft 365 product boundaries
- SharePoint external access and Teams collaboration are not governed by one control plane
- Business Premium and franchise-governance realities favor low-complexity defaults unless a stronger cross-tenant use case exists
- Architecture guidance must be reusable across future HTT brand collaboration scenarios

---

## Decision Drivers

1. **Safety of First Access**: External users must not be blocked by identity deadlocks before objects can be provisioned or redeemed
2. **Correct Layering**: Admission into a tenant and authorization to resources must be treated as separate concerns
3. **Operational Simplicity**: The default pattern should remain as simple as possible for current DCE work
4. **Future Reuse**: The architecture must support future HTT cross-tenant collaboration without repeating past mistakes
5. **Supportability**: Troubleshooting should be possible without guessing which Microsoft control plane is lying today
6. **Least Privilege**: App scoping and SharePoint authorization must still constrain access tightly
7. **UX Clarity**: Collaboration patterns should be chosen intentionally based on actual user journeys, not product buzzwords

---

## Considered Options

### Option A: Keep DeltaSetup Single-Tenant Only and Ignore Cross-Tenant Architecture

```
DeltaSetup
└── One tenant only
    ├── Corp Hub
    ├── DCE Hub
    ├── DCE-Operations
    ├── DCE-ClientServices
    ├── DCE-Marketing
    └── DCE-Docs
```

**Pros**:
- Simplest architecture story
- No new governance burden
- No risk of over-design for work not yet implemented

**Cons**:
- ❌ Leaves future cross-tenant planning undocumented
- ❌ Repeats tribal-knowledge failure mode from prior HTT work
- ❌ Encourages unsafe pattern reuse later
- ❌ Provides no formal guidance for guests vs sync vs Direct Connect

**ATAM Score**: 4/10 — Safe in the short term, irresponsible in the medium term

### Option B: Add a Cross-Tenant Collaboration Overlay with B2B Collaboration Default and Cross-Tenant Sync for Repeat Collaboration (RECOMMENDED)

```
PRIMARY MODE: Single-Tenant DeltaSetup
└── ADR-001 + ADR-002 remain default for DCE

OVERLAY MODE: Cross-Tenant Collaboration
├── Admission Layer (Entra cross-tenant access policy)
│   ├── deny-by-default defaults where feasible
│   ├── partner-specific overrides
│   ├── users/groups usually = AllUsers
│   └── apps scoped to required workloads
└── Authorization Layer (SharePoint / Teams / M365)
    ├── dynamic groups
    ├── SharePoint groups and site permissions
    ├── Teams membership
    └── labels / DLP / lifecycle controls
```

**Pros**:
- ✅ Preserves current single-tenant DCE baseline
- ✅ Formalizes cross-tenant guidance before it is needed in anger
- ✅ Explicitly bans resource-tenant dynamic-group inbound gating
- ✅ Allows B2B collaboration for bounded access and cross-tenant sync for recurring collaboration
- ✅ Keeps dynamic groups in the place where they are safe: authorization
- ✅ Matches real-world lessons from prior HTT projects
- ✅ Provides better future supportability and troubleshooting clarity

**Cons**:
- ⚠️ Adds architectural complexity to the repo
- ⚠️ Requires future teams to learn admission vs authorization separation
- ⚠️ Cross-tenant sync still introduces governance overhead when used

**ATAM Score**: 9/10 — Best balance of safety, clarity, and future reuse

### Option C: Treat Cross-Tenant Access Policy as the Primary Authorization Engine

```
Partner Policy
└── Highly scoped users/groups and apps
    └── SharePoint authorization minimized or secondary
```

**Pros**:
- Looks very secure on paper
- Encourages centralized access gates
- Reduces perceived reliance on SharePoint permission design

**Cons**:
- ❌ Easy to create first-run identity deadlocks
- ❌ Tempts architects to scope inbound access to resource-tenant dynamic groups
- ❌ Hard to troubleshoot because failures happen before resource-layer authorization
- ❌ Encourages brittle designs where app admission and business authorization are mixed
- ❌ Caused the known `AADSTS500213` pattern in prior HTT work

**ATAM Score**: 2/10 — Elegant in PowerPoint, cursed in production

### Option D: Use B2B Direct Connect as the Standard Cross-Tenant Pattern for SharePoint and Teams

```
Partner Tenant
└── Direct Connect
    ├── Teams shared channels
    └── (attempted) SharePoint site access
```

**Pros**:
- Good fit for Teams shared-channel collaboration
- Avoids some full-guest-experience friction in narrow scenarios
- Useful in selected Teams use cases

**Cons**:
- ❌ Not the standard mechanism for normal SharePoint site access
- ❌ Encourages wrong mental model for portal and site navigation
- ❌ Creates support confusion when shared-channel semantics are mixed with normal site access expectations
- ❌ Does not replace B2B collaboration or cross-tenant sync for typical SharePoint patterns

**ATAM Score**: 3/10 — Strong niche tool, bad default architecture

---

## Decision Outcome

### Chosen Option: **Option B — Add a Cross-Tenant Collaboration Overlay with Clear Layer Separation**

DeltaSetup will keep ADR-001 and ADR-002 as the **single-tenant baseline** and add this ADR as the **cross-tenant collaboration overlay**.

### Core Decision
Cross-tenant collaboration in DeltaSetup will follow a two-layer model:

#### Layer 1 — Admission
Managed by **Entra cross-tenant access policy**.

Question answered:
> Can this external identity enter the tenant at all?

Rules:
- Prefer deliberate defaults, ideally deny-by-default with explicit partner overrides where operationally feasible
- Scope by **partner organization** and **application**
- Do **not** use resource-tenant dynamic groups as inbound B2B collaboration gates when those groups depend on post-provisioning state
- Use bilateral automatic redemption when B2B collaboration or sync requires seamless first-run experience

#### Layer 2 — Authorization
Managed by **SharePoint permissions, Teams membership, M365 groups, dynamic groups, labels, and DLP**.

Question answered:
> Now that the identity object exists in the resource tenant, what may this user access?

Rules:
- Dynamic groups are valid and encouraged here
- SharePoint group / site / library permissions remain the primary resource authorization model
- Teams membership and channel design remain workload-specific authorization tools
- Labels and DLP remain defense-in-depth controls, not primary admission gates

### Pattern Selection Guidance

#### Use B2B Collaboration Guests When
- access is bounded to specific sites, teams, or resources
- the collaboration is temporary or moderately scoped
- guest lifecycle management is acceptable
- a fully internal-like identity experience is not required

#### Use Cross-Tenant Sync When
- partner collaboration is recurring and operationally significant
- invitation churn is too costly
- target-side authorization depends on mapped attributes and predictable object presence
- a closer-to-internal collaboration experience is worth the extra governance cost

#### Use B2B Direct Connect When
- the scenario is specifically a **Teams shared-channel** scenario
- broad SharePoint site access is not required
- the collaboration scope is intentionally narrow

#### Do Not Use B2B Direct Connect As
- the default SharePoint portal strategy
- a substitute for normal SharePoint site authorization
- a vague catch-all answer to “cross-tenant collaboration”

### Mandatory Anti-Pattern Prohibition

**DeltaSetup explicitly prohibits this pattern:**

> Scoping inbound B2B collaboration `usersAndGroups` to dynamic groups in the resource tenant when those groups require the guest/member object to exist before first admission.

This prohibition exists because:
- it mixes admission and authorization
- it is vulnerable to first-run deadlock
- it caused real-world access failure in prior HTT work
- it makes support and troubleshooting materially worse

### Order of Operations

#### Safe Partner Onboarding Sequence
1. establish cross-tenant default posture deliberately
2. add partner organization
3. configure inbound B2B collaboration
   - users/groups = `AllUsers` unless there is a proven safe pre-existing model
   - applications = required workloads only
4. configure outbound partner settings as needed
5. enable bilateral automatic redemption where relevant
6. enable cross-tenant sync prerequisites if sync is part of the design
7. decide `userType` and attribute mappings before production onboarding
8. onboard pilot users first
9. verify target object creation
10. verify dynamic-group resolution at the authorization layer
11. assign SharePoint / Teams / M365 access
12. test first-run user experience before broad rollout

#### Unsafe Sequence
1. create resource-tenant dynamic groups
2. scope inbound partner admission to those groups
3. expect first-time users to satisfy those rules before their objects exist
4. burn time chasing auth errors that were designed into the system

### Consequences

**Good**:
- Future cross-tenant work gets a clear safety model
- Current DCE single-tenant architecture remains intact
- Dynamic groups remain usable where they are strongest
- Pattern selection becomes explicit instead of accidental
- Troubleshooting can distinguish identity failure from SharePoint / Teams authorization failure

**Bad**:
- Adds another architecture layer to the repo
- Future teams must understand more than one collaboration model
- Cross-tenant sync remains operationally heavier than plain B2B collaboration

**Neutral**:
- Not every external collaboration scenario deserves sync
- Direct Connect remains useful, but in a narrower box than people often hope
- Attribute mapping becomes a strategic concern if cross-tenant sync is introduced later

---

## Design Guardrails

### Guardrail 1: Default to Single-Tenant Unless There Is a Real Cross-Tenant Requirement
Do not introduce cross-tenant complexity for fun, fashion, or because Microsoft naming is irresistible.

### Guardrail 2: Separate Admission From Authorization
If the user cannot enter the tenant, SharePoint permissions do not matter.
If the user can enter the tenant, Entra partner policy should not be carrying all business authorization logic.

### Guardrail 3: Keep Dynamic Groups at the Authorization Layer
Dynamic groups remain appropriate for:
- SharePoint access groups
- Teams membership groups
- M365 resource authorization
- audience targeting
- DLP scoping

### Guardrail 4: Treat Attribute Mapping as Architecture, Not Plumbing
If cross-tenant sync is used, mapped attributes must support the target authorization model.
Examples:
- `department`
- `companyName`
- `jobTitle`
- future extension attributes

### Guardrail 5: Pilot Before Broad Rollout
Every cross-tenant pattern should be piloted with a small user set before broad rollout.

---

## STRIDE Security Analysis

### S — Spoofing
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| External identity enters via untrusted tenant | Entra cross-tenant access | Prefer deny-by-default defaults, explicit partner overrides, trust settings | MEDIUM |
| Partner MFA posture is weaker than assumed | Cross-tenant trust | Review trust settings and Conditional Access posture per partner | MEDIUM |

### T — Tampering
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| Overly broad inbound partner policy grants unintended application access | Admission layer | Scope apps deliberately, avoid blanket partner access without review | MEDIUM |
| Attribute mapping is altered and dynamic-group authorization breaks silently | Cross-tenant sync | Review mapping changes, pilot and verify before rollout | MEDIUM |

### R — Repudiation
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| Support cannot determine whether failure is Entra admission or SharePoint authorization | Operations | Use two-layer troubleshooting model and preserve clear logs/evidence | LOW |

### I — Information Disclosure
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| External user gains access through overly broad SharePoint permissions | Authorization layer | Unique permissions, group-based access, labels, DLP | HIGH |
| External user is admitted too broadly at tenant edge | Admission layer | Partner-specific overrides, scoped apps, careful review of defaults | MEDIUM |

### D — Denial of Service
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| Legitimate external users are denied by deadlocked admission rules | Entra partner policy | Ban resource-tenant dynamic-group inbound gating, pilot with real users | LOW |
| Sync scope changes remove users unexpectedly | Cross-tenant sync | Treat scope changes as controlled changes, not harmless filters | MEDIUM |

### E — Elevation of Privilege
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| External users receive broader access through misapplied group logic | SharePoint / Teams authorization | Use least-privilege group bindings and verify effective permissions | MEDIUM |
| B2B Direct Connect is misapplied as a broad access model | Collaboration design | Constrain it to Teams shared-channel scenarios | LOW |

### Critical Findings Requiring Continued Attention
1. **Admission/authorization confusion remains a design risk** unless future docs and tests enforce the distinction
2. **Cross-tenant sync attribute mapping** can silently undermine authorization if not aligned to target dynamic-group logic
3. **Overly broad partner app scoping** still creates a blast-radius problem even when `AllUsers` is used safely at the admission layer

---

## Implementation Guidance

### Near-Term
- Keep current DCE implementation anchored to ADR-001 and ADR-002
- Use this ADR as guidance for future external/franchise collaboration scenarios
- Add architecture fitness tests to prevent regression into known anti-patterns

### Future Follow-Up
- Add `tests/architecture/test_adr_004_cross_tenant_access.py`
- Review existing docs and scripts for language that confuses admission and authorization
- Create pilot planning guidance if a cross-tenant collaboration implementation becomes active work

---

## Research References

| Source | Tier | URL / Reference |
|---|---|---|
| Cross-tenant access overview | 1 | https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview |
| Cross-tenant access settings for B2B collaboration | 1 | https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration |
| B2B Direct Connect overview | 1 | https://learn.microsoft.com/en-us/entra/external-id/b2b-direct-connect-overview |
| Cross-tenant synchronization overview | 1 | https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview |
| Configure cross-tenant synchronization | 1 | https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure |
| Multi-tenant organization overview | 1 | https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview |
| SharePoint external sharing overview | 1 | https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview |
| Entra B2B user properties | 1 | https://learn.microsoft.com/en-us/entra/external-id/user-properties |
| Identity platform error codes | 1 | https://learn.microsoft.com/en-us/entra/identity-platform/reference-error-codes |
| DeltaSetup cross-tenant research pack | Internal | `research/cross-tenant-collaboration-m365/` |
| Convention-Page-Build incident evidence | Internal | `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/AADSTS500213-ROOT-CAUSE-AND-FIX.md` |
| Cross-Tenant-Utility architecture evidence | Internal | `/Users/tygranlund/dev/03-personal/Cross-Tenant-Utility/HTT-CROSS-TENANT-IDENTITY-ANALYSIS.md` |
