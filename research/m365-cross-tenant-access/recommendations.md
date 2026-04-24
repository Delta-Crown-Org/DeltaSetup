# Recommendations

## Priority 1: Use standard cross-tenant sync as the default franchise pattern

For this repo’s franchise / brand scenario, start with:
- **cross-tenant access settings** for partner control
- **cross-tenant sync** for provisioning/lifecycle automation
- **SharePoint / Teams / M365 authorization** for actual resource access

### Why
This pattern gives you:
- selective trust per brand
- cleaner onboarding/offboarding
- less coupling than full MTO
- better control if some brand relationships should remain narrow or asymmetric

---

## Priority 2: Treat MTO as an enhancement, not the baseline

Use **MTO** only if these are true:
- the participating tenants are truly one organization
- broad cross-brand/internal-like collaboration is desired
- you want Microsoft 365 “in-organization” semantics, especially in **new Teams** / **Viva Engage**
- you can support reciprocal tenant governance and B2B member provisioning

### Avoid MTO as the default if
- the brands are semi-autonomous franchises
- legal/commercial boundaries remain meaningful
- not every brand should collaborate with every other brand
- you mainly need provisioning and access, not org-wide identity semantics

---

## Priority 3: Decide `userType` intentionally up front

### Recommended default
- Use **`userType=Member`** for brands/users who should behave like internal staff across tenants.
- Use **`userType=Guest`** for external-style collaboration, limited access, or brands that should remain clearly external.

### Operational rule
Do not assume you can safely “flip later” without planning.

If you might need to convert existing guests to members:
- explicitly review the mapping behavior
- use **Apply this mapping = Always** where appropriate
- test the outcome with existing users before production rollout

Microsoft’s own guidance implies that mixed populations may justify **separate configurations**.

---

## Priority 4: Keep `showInAddressList=True` unless you have a strong reason not to

### Why
For Microsoft 365 people search and Outlook-style collaboration, visibility matters.

If users should:
- appear in people search
- be discoverable in Outlook
- collaborate across Microsoft 365 more like internal users

then keep `showInAddressList=True` and pair it with the right `userType`.

### Governance warning
If admins later hide users from address lists, they may mistake the resulting collaboration degradation for a sync or permission issue.

---

## Priority 5: Use a deny-by-default posture only with explicit override governance

### Recommended model
1. Inventory current cross-tenant dependencies.
2. Change **default inbound/outbound** B2B collaboration settings to block.
3. Add only approved partners under **Organizational settings**.
4. Create partner-specific allow rules.
5. Scope users/groups/apps only where necessary.

### Important warning
Microsoft explicitly warns that blocking defaults can break existing business-critical access. So this should be deployed as a controlled change, not a cleanup task.

### Practical interpretation
If you:
- block all inbound by default
- then create a partner-specific inbound allow override

that partner-specific setting should win for that partner.

---

## Priority 6: Follow a strict order of operations for cross-tenant sync

### Safe rollout sequence
1. **Target tenant:** add partner
2. **Target tenant:** enable **Allow user synchronization into this tenant**
3. **Target tenant:** enable inbound **automatic redemption**
4. **Source tenant:** enable outbound **automatic redemption**
5. **Source tenant:** create sync configuration
6. review mappings (`userType`, address-list behavior, extensions, manager if needed)
7. pilot with a few users
8. inspect provisioning logs and resulting objects
9. only then broaden scope and assign production permissions

### Why
This avoids the most common failure family: `AzureActiveDirectoryCrossTenantSyncPolicyCheckFailure` caused by missing prerequisite policies.

---

## Priority 7: Treat scope changes as deprovisioning changes

This is the biggest operational gotcha.

Removing a user from:
- assigned scope
- assigned group membership
- scoping-filter match

can soft delete that user in the target tenant.

### Recommendation
- put scope changes through change control
- document group ownership
- avoid casual cleanup in pilot-to-production transitions
- review soft-delete implications before editing scope filters

---

## Priority 8: Preflight contact collisions before scale rollout

If the target tenant has older Exchange/contact-heavy history, review for contact-object collisions before mass sync. Microsoft says contact handling/conversion is not currently supported in this scenario.

### Practical action
Run a pre-migration hygiene step for:
- legacy mail contacts
- manually created external contacts
- duplicate representations of the same external people

---

## Decision summary for this project

### Best baseline
- **Standard cross-tenant sync + partner-specific cross-tenant access settings**
- **`Member`** for internal-like brand workforce users
- **`Guest`** for truly external brand/partner users
- **`showInAddressList=True`** for discoverable M365 collaboration cases
- **Deny-by-default** only if the team is ready to maintain explicit partner overrides

### Use MTO only if
- the business wants one real multi-tenant enterprise identity boundary, not just selective collaboration plumbing

### Avoid these anti-patterns
- enabling sync before inbound target settings are ready
- assuming auto-redemption on one side is enough
- assuming `userType` changes will retrofit existing users automatically
- treating scope edits as harmless
- using MTO where trust and collaboration are not truly organization-wide
