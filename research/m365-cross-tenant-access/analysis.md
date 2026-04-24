# Analysis

## Project-specific context

This repository’s architecture docs show a strong SharePoint / Teams collaboration focus. That makes the **policy-layer vs authorization-layer distinction** the most important design point:

- **Cross-tenant access settings** determine whether a user from tenant A may enter tenant B at all.
- **SharePoint permissions / groups / audiences** determine what that already-allowed user may access inside tenant B.

If those two layers are mixed incorrectly, SharePoint access fails before SharePoint authorization is even evaluated.

---

## Topic 1 analysis: AADSTS500213 and inbound policy scoping

## What AADSTS500213 actually means
Microsoft Learn’s identity platform reference defines AADSTS500213 as:

> "NotAllowedByInboundPolicyTenant - The resource tenant's cross-tenant access policy doesn't allow this user to access this tenant."

That means the failure is not primarily a SharePoint ACL problem. It is a **resource-tenant Entra cross-tenant access problem**.

## Why dynamic-group gating at inbound policy is risky
Microsoft Learn says:

> "Both allow/block list and cross-tenant access settings are checked at the time of invitation."

Microsoft Learn also says SharePoint with Entra B2B integration creates a guest account when sharing:

> "Microsoft Entra B2B integration enabled -> Guest account always created"

### Synthesized failure mode
If your inbound policy expects the user to already be in a target-tenant dynamic group, but the guest/B2B object is only created as part of the invite/share flow, the policy check happens first and the group membership can never be true in time.

That is the practical **chicken-and-egg** problem:

1. user tries to access / is invited to SharePoint in resource tenant
2. inbound policy evaluates first
3. policy expects target-tenant group membership
4. but target-tenant guest object does not yet exist
5. dynamic group cannot contain a non-existent object
6. inbound policy denies access
7. object is never provisioned through the normal sharing path
8. result surfaces as AADSTS500213 / inbound-policy denial

## Correct pattern
For partner-specific SharePoint access, the more stable pattern is:

- **Users and groups:** allow **All external users and groups** for that partner tenant
- **Applications:** use app allowlisting to restrict entry to the minimum required app set
- **Authorization:** enforce site/library/page access through SharePoint/M365 groups after the object exists

### Important caveat on app allowlists
Microsoft Learn explicitly warns:

> "if you configure an allowlist and only allow SharePoint Online, the user can't access My Apps or register for MFA in the resource tenant."

So the fix is not just "allow SharePoint only and nothing else" without thought. For a smooth first-run experience, you may need to also allow supporting Microsoft apps such as My Apps, My Profile, and My Sign-ins depending on your MFA/trust model.

---

## Topic 2 analysis: cross-tenant sync vs B2B collaboration for SharePoint

## What cross-tenant sync creates
Microsoft Learn says:

> "Cross-tenant synchronization automates creating, updating, and deleting Microsoft Entra B2B collaboration users and groups across tenants in an organization."

This matters because cross-tenant sync is not a different identity family from B2B collaboration. It is an **automation layer that provisions B2B collaboration users**.

## SharePoint relevance
Microsoft Learn says users created by cross-tenant sync:

> "are able to access both Microsoft applications (such as Teams and SharePoint)"

So for SharePoint, cross-tenant sync primarily solves the object-provisioning and lifecycle-management problem.

## Member vs Guest
Microsoft Learn configuration guidance says:

> "Member... Users will be created as external member (B2B collaboration users) in the target tenant. Users will be able to function as any internal member of the target tenant."

> "Guest... Users will be created as external guests (B2B collaboration users) in the target tenant."

### Practical interpretation for SharePoint
- **Member:** best fit when the partner tenant is effectively part of the broader organization and should behave like an internal workforce for resource access.
- **Guest:** best fit when the user is still intentionally treated as an external collaborator.

Microsoft Learn also notes:

> "Over time, the member userType will be used by the various Microsoft 365 services to provide differentiated end user experiences"

So Microsoft clearly intends userType=Member to matter increasingly across Microsoft 365. For SharePoint design, assume **Member is the strategic choice for internal-like multitenant users**, but do not assume it bypasses the need for explicit SharePoint permissions.

## Prerequisites and order of operations
Cross-tenant sync requires policy prerequisites before provisioning will work:

1. **Target tenant**: enable **Allow user synchronization into this tenant**
2. **Target tenant**: enable **Automatically redeem invitations** inbound
3. **Source tenant**: enable **Automatically redeem invitations** outbound
4. **Source tenant**: create sync configuration and test connection
5. assign at least one in-scope internal user/group

This is reinforced by Microsoft troubleshooting guidance. If automatic redemption or inbound sync is not enabled, test connection fails with `AzureActiveDirectoryCrossTenantSyncPolicyCheckFailure`.

## Can cross-tenant sync and normal B2B collaboration coexist?
Yes.

Microsoft Learn says:

> "These settings don't impact B2B invitations created through other processes such as manual invitation"

and:

> "Will cross-tenant synchronization manage existing B2B users? Yes."

That means coexistence is not just possible; it is expected.

---

## Topic 3 analysis: B2B direct connect limitations

Microsoft Learn is explicit:

> "This feature currently works with Microsoft Teams shared channels."

and in the FAQ:

> "There's no plan to extend support for B2B direct connect beyond Teams Connect shared channels."

## Why this matters for SharePoint
B2B direct connect users:

> "don't have a presence in your Microsoft Entra organization"

By contrast, SharePoint external sharing with Entra B2B integration says:

> "Guest account always created"

for site sharing.

### Resulting conclusion
Regular SharePoint site sharing relies on a **B2B collaboration object model**; B2B direct connect does not create that target-tenant presence. Therefore, **direct connect is the wrong pattern for normal site access**.

### What happens if someone tries anyway?
The most defensible Microsoft-backed answer is:
- direct connect only gives access to Teams shared-channel resources
- it does not establish broad SharePoint site access semantics
- normal SharePoint site sharing still requires the B2B collaboration path that creates a guest/external-member object

So a direct-connect-only user should not be expected to succeed with ordinary site sharing outside the Teams shared channel scenario.

---

## Topic 4 analysis: dynamic groups in cross-tenant patterns

## Safe uses
Dynamic groups are safe when they are used **after identity materialization** in the correct tenant, for example:
- grouping already-provisioned cross-tenant sync users
- assigning SharePoint site membership
- audience targeting
- downstream app authorization

They are also safe in the **source tenant** for deciding who should be in scope for cross-tenant sync. Microsoft Learn explicitly allows assigning a static or dynamic group to the sync configuration.

## Dangerous uses
Dynamic groups are dangerous when used as the **first-pass inbound cross-tenant B2B collaboration gate** and their membership depends on a target-tenant guest object that does not exist yet.

## Key distinction
- **Policy layer:** who may enter the tenant at all
- **Authorization layer:** what the now-existing user may access

This distinction is the core design guardrail for this project.

---

## Topic 5 analysis: cross-tenant access settings order of operations

## Defaults vs partner-specific overrides
Microsoft Learn says default settings apply to all external organizations unless you create organization-specific settings, and partner-specific settings take precedence.

### Recommended pattern
- keep **defaults restrictive**
- add **partner-specific overrides** only where collaboration is required

## Inbound vs outbound
- **Inbound** = what users from the partner can access in your tenant
- **Outbound** = what your users can access in the partner tenant

For any mutual scenario, especially B2B direct connect and automatic redemption, both sides matter.

## Automatic redemption
This setting is bilateral for consent suppression:

> "The automatic redemption setting will only suppress the consent prompt and invitation email if both the home/source tenant (outbound) and resource/target tenant (inbound) checks this setting."

## Trust settings
Trust settings control whether you trust partner-tenant claims for:
- MFA
- compliant devices
- Microsoft Entra hybrid joined devices

These settings affect Conditional Access behavior and user experience. They do **not** replace application/user scoping.

---

## Security lens
- The biggest security anti-pattern is trying to enforce app-entry authorization with a mechanism that depends on an object not yet created.
- App allowlists reduce blast radius, but if you allowlist too narrowly you can break first-run UX and MFA registration.
- Trusting partner MFA/device claims can reduce prompt fatigue but must align with Conditional Access intent.

## Implementation complexity lens
- **B2B collaboration only** is simpler but can create manual lifecycle overhead.
- **Cross-tenant sync** adds setup complexity but removes repeated guest onboarding friction and gives better lifecycle control.
- **B2B direct connect** should be reserved for Teams shared channels only; using it as a general external-collaboration strategy creates design confusion.

## Stability / maintenance lens
- Microsoft documentation strongly positions cross-tenant sync + B2B collaboration as durable patterns.
- Microsoft explicitly limits B2B direct connect’s scope, so designing SharePoint access around it would be fragile and contrary to product direction.
