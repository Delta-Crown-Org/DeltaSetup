# M365 / Entra ID Cross-Tenant Access Research

**Date:** 2025-08-08  
**Researcher:** Web-Puppy (`web-puppy-08d789`)  
**Project context:** SharePoint-centric cross-tenant collaboration research for this repo’s architecture work.

## Executive summary

### Key findings
1. **AADSTS500213** means the **resource tenant inbound cross-tenant access policy** blocked the user.
2. **Do not use target-tenant dynamic group membership as the first inbound B2B collaboration gate** for first-time SharePoint access.
3. **For SharePoint Online**, the stable pattern is typically:
   - inbound B2B collaboration **users/groups = All external users and groups**
   - inbound **applications = scoped allowlist** to SharePoint Online and any supporting Microsoft apps required for first-run UX/MFA
   - actual content authorization handled later in **SharePoint / M365 groups / target-tenant groups**
4. **Cross-tenant sync** provisions **B2B collaboration users**; it can coexist with normal B2B collaboration.
5. **B2B direct connect** is **not** the model for regular SharePoint site access; Microsoft says it currently works with **Teams shared channels**.

## Direct answers

### Topic 1: AADSTS500213 and inbound B2B collaboration scoping
- Microsoft Learn defines AADSTS500213 as: **"NotAllowedByInboundPolicyTenant - The resource tenant's cross-tenant access policy doesn't allow this user to access this tenant."**
- When inbound B2B collaboration policy is evaluated, Microsoft says cross-tenant access settings are checked **"at the time of invitation."**
- If your rule depends on a guest object already being in a target-tenant dynamic group, you have a **chicken-and-egg problem**:
  - the policy must allow the invitation/access first
  - but the guest object and target-tenant membership exist only after invite/provisioning succeeds
  - therefore the policy blocks before the group can ever include the user
- Best fix: use **All external users and groups** at the inbound policy layer, then use **Applications** scoping and SharePoint authorization to narrow actual access.

### Topic 2: Cross-tenant sync vs B2B collaboration for SharePoint
- Cross-tenant sync creates **B2B collaboration users** in the target tenant.
- `userType=Member`: **"Users will be created as external member ... Users will be able to function as any internal member of the target tenant."**
- `userType=Guest`: **"Users will be created as external guests ... in the target tenant."**
- Automatic redemption must be enabled on **both sides** to suppress first-run consent for sync.
- Sequence matters: target inbound sync + target inbound auto redemption first, then source outbound auto redemption, then source sync configuration/testing.
- Coexistence: yes. Microsoft says cross-tenant sync can manage **existing B2B users** and its sync settings **don't impact** B2B invitations from other processes.

### Topic 3: B2B direct connect limitations
- Microsoft: **"This feature currently works with Microsoft Teams shared channels."**
- Microsoft FAQ: **"There's no plan to extend support for B2B direct connect beyond Teams Connect shared channels."**
- Therefore B2B direct connect does **not** provide normal SharePoint site access.
- If you try to use it for normal site sharing, expect failure because SharePoint external sharing relies on **B2B collaboration identity presence** in the resource tenant.

### Topic 4: Dynamic groups in cross-tenant patterns
- **Safe:** dynamic groups used after the user object exists in the target tenant, such as SharePoint permissions, audience targeting, or access to downstream apps.
- **Dangerous:** dynamic groups used as the **initial inbound B2B collaboration policy scope** when membership depends on a not-yet-provisioned guest.
- Difference:
  - **Entra cross-tenant access policy layer** = can the user enter the tenant?
  - **SharePoint authorization layer** = what can an already-provisioned user access?

### Topic 5: Cross-tenant access settings order of operations
1. Review **default** settings and keep them restrictive.
2. Add the partner under **Organizational settings**.
3. Configure **inbound** partner settings in the resource tenant.
4. Configure **outbound** settings in the source/home tenant if needed.
5. Configure **trust settings** for MFA / compliant device / hybrid join as needed.
6. Configure **automatic redemption on both sides** if using sync or wanting consent suppression.
7. For SharePoint/OneDrive native sharing with Entra B2B integration, ensure **external collaboration settings/domain allowances** are also correct.
8. Only then rely on groups and SharePoint permissions for granular authorization.

## Files
- `sources.md`
- `analysis.md`
- `recommendations.md`
- `raw-findings/microsoft-learn-quotes.md`
