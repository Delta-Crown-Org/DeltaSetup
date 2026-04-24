# Analysis

## Project-specific context

This repo’s architecture work is evaluating collaboration patterns for a **franchise / multi-brand environment**. That matters because Microsoft’s cross-tenant features are opinionated about trust level:

- **MTO** assumes a real shared organizational boundary and higher trust.
- **Cross-tenant sync** assumes you need provisioning automation across tenants.
- **Cross-tenant access settings** determine who can enter.
- **SharePoint / Teams / M365 authorization** determines what they can do after entry.

For a franchise model, those are not interchangeable.

---

## Topic 1: MTO vs non-MTO patterns

### What MTO is
Microsoft defines multitenant organization as a feature that lets you define a boundary around the tenants your organization owns. In practice, that means:
- an explicit tenant grouping
- reciprocal tenant relationship management
- optional policy templates
- Microsoft 365 awareness of “in-organization” external members

### How MTO differs from standard cross-tenant sync
**Cross-tenant sync alone**:
- is a **one-way provisioning service**
- creates B2B collaboration users in target tenants
- automates lifecycle actions
- does not itself create a broader “shared organization” boundary

**MTO**:
- creates the organizational boundary
- adds Microsoft 365 collaboration semantics on top of B2B member provisioning
- still depends on provisioning of B2B members, often through cross-tenant sync

### What MTO enables that standard cross-tenant sync does not
From Microsoft Learn, the differentiators are mainly:
- better distinction between **in-organization** and **out-of-organization** external users
- improved experience in **new Teams**
- improved experience in **Viva Engage**
- better Microsoft 365 people-search / collaboration alignment when users are provisioned as members and shown in address lists

Important nuance: **MTO does not replace cross-tenant access settings or provisioning**. It layers on top of them.

### MTO requirements and limitations
From the Microsoft Learn sources used:
- one tenant can only create or join **one** MTO
- MTO is **not allowed between a CSP and customer tenants**
- MTO needs at least one active owner tenant
- each active tenant must have cross-tenant access settings for all active tenants
- soft self-service limit is **100 active tenants** unless increased by support
- unsupported scenarios include several education/government/cross-cloud cases
- seamless MTO experiences rely on **B2B members**, not just guests

### Franchise / brand decision guidance
For this repo’s franchise scenario, MTO is **not automatically the best fit** just because there are multiple tenants.

Use **MTO** when:
- the brand tenants are truly one enterprise boundary
- you want broad, internal-like Teams/M365 collaboration
- users should generally be treated as trusted internal peers across brands
- you can sustain reciprocal configuration discipline across all tenants

Use **standard cross-tenant sync without MTO** when:
- the brands are semi-autonomous or legally distinct
- collaboration is selective rather than organization-wide
- some brand-to-brand paths should not exist at all
- you mainly need provisioning automation and lifecycle management, not MTO-specific Microsoft 365 semantics

### Recommendation for this project
Given the repo’s franchise pattern, **standard cross-tenant sync + partner-specific access controls** is the safer default architecture. MTO should be treated as an opt-in enhancement for a subset of tenants only if the business model really behaves like a single workforce.

---

## Topic 2: Cross-tenant sync attribute mapping, `userType`, `IsSoftDeleted`, and `showInAddressList`

### What can be mapped
Microsoft does not present a single short canonical list in the main overview page, but it does document that cross-tenant sync can synchronize:
- commonly used Entra user attributes such as `displayName` and `userPrincipalName`
- directory extension attributes
- `manager` in supported scenarios
- `userType`
- `showInAddressList`

This is enough for architectural planning: the engine is flexible, but not universal. Microsoft explicitly says photos, custom security attributes, and attributes outside the directory are not supported.

### How `userType` mapping works
Microsoft documents two target values:
- **Member**: creates an **external member** B2B user in target
- **Guest**: creates an **external guest** B2B user in target

Operationally:
- **Member** is the default for newer cross-tenant sync configs in MTO-focused documentation
- **Guest** remains valid for intentionally external treatment

### The big gotcha: changing `userType` after initial provisioning
This is one of the most important order-of-operations issues.

Microsoft states:
- existing B2B guests stay guests by default
- they are **not** flipped to member unless **Apply this mapping = Always**

That means if you pilot with Guest and later decide the same people should become Member:
- changing the mapping alone might not change already-provisioned users
- you may need to explicitly force that mapping behavior
- for mixed populations, Microsoft even suggests maintaining **separate configurations** for guest vs member outcomes

### `showInAddressList` impact
`showInAddressList` is more important than it looks.

Microsoft says:
- people search scenarios in Microsoft 365 need `showInAddressList=True`
- the attribute is set to true by default in cross-tenant sync mappings
- in broader M365 collaboration guidance, a B2B collaboration user generally needs to be **shown in address lists** and often be **userType=Member** for richer Microsoft 365 experiences

Implication:
- If you suppress address-list visibility, Outlook / people-search / M365 discovery scenarios may behave as if your cross-tenant sync “didn’t work,” even though provisioning succeeded.

### `IsSoftDeleted` impact
Microsoft’s public docs emphasize the behavior rather than the internal attribute name:
- removing a user from sync scope causes the user to be **soft deleted** in the target
- this can happen when you unassign the user, remove them from an assigned group, delete them in source, or make them fail a scoping filter

So the architectural implication of `IsSoftDeleted` is:
- it represents deprovisioning state that downstream admins may misread as an accidental outage
- a scoping change is effectively a lifecycle action
- scope edits in production are high risk and should be change-controlled

### Project impact
For a franchise portal or shared SharePoint/Teams environment:
- **Member + showInAddressList=True** is the right combination for users who should appear and behave like internal collaborators
- **Guest** is safer where brands remain intentionally external
- scoping changes are not “just filter changes”; they can deprovision users

---

## Topic 3: Deny-by-default cross-tenant access posture

### What Microsoft’s documented defaults actually are
Microsoft explicitly says:
- B2B collaboration with other Entra organizations is **enabled by default**
- B2B direct connect is **blocked by default**
- no partner orgs are added to organizational settings by default

So a real deny-by-default strategy for B2B collaboration is **not the out-of-box state**.

### How to implement deny-by-default
The Microsoft Learn-aligned model is:
1. review current sign-in/access dependencies
2. change **default** inbound/outbound B2B collaboration settings to block
3. add required partners under **Organizational settings**
4. configure partner-specific inbound/outbound allow rules
5. optionally scope users/groups/apps inside each partner config

### How default settings and partner overrides interact
Microsoft states clearly:
- default settings apply to all external orgs unless org-specific settings exist
- organization-specific settings **take precedence** over default settings

Therefore:
- **Default = Block**, **Partner X override = Allow** means Partner X can still be allowed.
- The deny-by-default baseline remains in effect for every other org.

### What happens if you block inbound by default but have a partner allow override?
The partner allow override wins for that partner organization.

However, there are two important practical caveats from Microsoft’s docs:
1. **User/group settings and application settings must be consistent**. Example: if you block all inbound users/groups, all apps must also be blocked.
2. If you over-constrain app allowlists, users might fail first-run experiences such as **MFA registration** or access to **My Apps**.

### Recommendation for this project
For a franchise estate, deny-by-default is attractive because it reduces accidental trust sprawl. But it only works well if you also maintain:
- a partner inventory
- documented override intent
- sign-in log review before tightening defaults
- a first-run app allowlist design that covers registration/consent edge cases

---

## Topic 4: Cross-tenant sync failure modes, gotchas, and order-of-operations

### Common provisioning failures
The highest-frequency failure modes in Microsoft’s docs are policy/setup issues:
- target tenant did not enable **Allow user synchronization into this tenant**
- outbound/inbound **automatic redemption** not configured bilaterally
- partner-specific cross-tenant access settings not aligned
- user not actually in sync scope

### Failure: automatic redemption not enabled
Microsoft documents `AzureActiveDirectoryCrossTenantSyncPolicyCheckFailure` with a message like:
- source tenant has not enabled automatic user consent with the target tenant

Effect:
- test connection fails early
- provisioning cannot proceed as expected
- if you somehow rely on later remediation, your deployment order is already wrong

### Failure: inbound sync not enabled in target
Microsoft also documents the same failure family when:
- target tenant has not enabled inbound synchronization with this tenant

Effect:
- source-side configuration/testing fails before real provisioning begins
- admins often misdiagnose this as bad credentials, but the root cause is policy gating in the target tenant

### Failure: users silently disappear because they fell out of scope
This is the operational failure mode most likely to surprise production teams.

Microsoft says users are soft deleted in target when they:
- are deleted in source
- are unassigned from the sync configuration
- are removed from an assigned group
- stop matching scoping filters

So a “minor cleanup” in group membership can deprovision access.

### Failure: contact collisions
Microsoft explicitly warns that at-scale provisioning of B2B users can collide with **contact objects**, and handling/conversion of those contact objects is not supported.

That means older Exchange/contact-heavy tenants need preflight cleanup before large sync rollout.

### Failure: quarantine
Microsoft’s configure doc says unhealthy provisioning sends the configuration into **quarantine**.
Microsoft Graph documentation adds that starting the synchronization job clears quarantine status.

Operationally:
- quarantine is a symptom, not the root cause
- you should inspect provisioning logs before simply restarting
- repeated restarts without fixing mapping/scope/policy issues create churn instead of progress

### Recommended order of operations
For production-safe rollout, the best order is:
1. **Target tenant:** add partner organization
2. **Target tenant:** enable inbound cross-tenant sync
3. **Target tenant:** enable inbound automatic redemption
4. **Source tenant:** enable outbound automatic redemption
5. **Source tenant:** create sync config
6. **Source tenant:** review mappings, especially `userType`
7. **Source tenant:** test with one/few users
8. **Source + target:** review provisioning logs and resulting user objects
9. **Only then** expand scope and grant production app/site permissions

### Why this matters in this repo
This repo’s SharePoint-centric architecture is especially sensitive to order-of-operations because a failed or half-provisioned B2B object leads to confusing downstream symptoms:
- missing site access
- missing people search entries
- unexpected Guest vs Member behavior
- address book visibility issues

---

## Multi-dimensional view

### Security
- Deny-by-default reduces accidental exposure but increases operational risk if not staged carefully.
- MTO assumes high trust; that may be too broad for franchise relationships.
- `Member` users expand internal-like reach and should be intentional.

### Implementation complexity
- Standard cross-tenant sync is simpler than full MTO governance.
- MTO adds concept count, tenant-role lifecycle, and Microsoft 365-specific expectations.
- Deny-by-default requires partner override hygiene.

### Stability
- The core Entra patterns are mature, but Microsoft 365 end-user behavior for B2B Members continues to evolve.
- Existing-object behavior (`Guest` staying `Guest`) is stable but easy to overlook.

### Maintenance
- Scope management is lifecycle management.
- Address-list visibility and `userType` need governance, not just technical setup.
- Contact collisions and existing B2B population state should be reviewed before broad rollout.
