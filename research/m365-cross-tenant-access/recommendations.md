# Recommendations

## Priority 1: Fix inbound SharePoint partner policy design

## Recommended configuration pattern
For a new partner tenant that needs standard SharePoint Online access:

1. Add the partner in **Entra ID > External Identities > Cross-tenant access settings > Organizational settings**.
2. In the **resource tenant inbound B2B collaboration settings**:
   - set **External users and groups = Allow access / All external users and groups**
   - set **Applications = Allow access / Select applications** and include the required app set
3. Use **SharePoint/M365 groups/dynamic groups** to grant actual site access after the user object exists.
4. If first-run experience or MFA registration is required in the resource tenant, include the supporting Microsoft apps Microsoft Learn calls out.

## Why
This avoids the object-existence deadlock that causes inbound-policy failures.

## Anti-pattern to avoid
Do **not** use a target-tenant dynamic group whose membership depends on the guest object as the first inbound B2B collaboration gate for SharePoint.

---

## Priority 2: If the partner is effectively internal, prefer cross-tenant sync

Use cross-tenant sync when:
- the partner tenant is part of the same broader organization
- you need repeatable onboarding/offboarding
- you want predictable SharePoint access without repeated invitation friction
- you may benefit from `userType=Member`

## Suggested posture
- provision users as **external Member** unless there is a governance reason to keep them as Guest
- keep SharePoint authorization explicit via groups and site permissions

## Why
Microsoft says external Member users **"will be able to function as any internal member of the target tenant."** That is the better long-term pattern for multitenant workforce-style collaboration.

---

## Priority 3: Keep B2B direct connect scoped only to Teams shared channels

Do not design ordinary SharePoint site access around B2B direct connect.

Use B2B direct connect only for:
- Teams shared channels
- scenarios where you explicitly want no guest object in the resource tenant

If a business owner says "we already enabled direct connect, why can't they open the SharePoint site?" the answer is:
- because direct connect is not the SharePoint external-sharing model
- SharePoint sharing still needs B2B collaboration-style identity presence

---

## Recommended order of operations for a new partner

### For B2B collaboration / SharePoint access
1. Review **Default settings** and keep them restrictive.
2. Add partner under **Organizational settings**.
3. Configure **Inbound B2B collaboration** in resource tenant.
4. Configure **Outbound B2B collaboration** in home/source tenant if mutual access is needed.
5. Configure **Trust settings**:
   - Trust MFA from partner if desired
   - Trust compliant device claims if desired
   - Trust hybrid-joined device claims if desired
6. Configure **Automatic redemption on both sides** if using sync or if you want first-run consent suppression.
7. If using SharePoint/OneDrive native sharing with Entra B2B integration, confirm **external collaboration settings/domain allowances** are correct.
8. Only then assign SharePoint permissions.

### For cross-tenant sync
1. **Target tenant:** add source partner
2. **Target tenant:** enable **Allow user synchronization into this tenant**
3. **Target tenant:** enable inbound **Automatically redeem invitations**
4. **Source tenant:** enable outbound **Automatically redeem invitations**
5. **Source tenant:** create sync configuration
6. test connection
7. assign initial pilot users/groups
8. review mappings, especially `Member (userType)`
9. start provisioning
10. then grant SharePoint permissions in target tenant

---

## SharePoint-specific guardrails

### Good patterns
- Cross-tenant sync + SharePoint authorization groups
- B2B collaboration with inbound users/groups broad enough to permit object creation, then SharePoint authorization narrowing actual content access
- Dynamic groups for already-provisioned users

### Bad patterns
- inbound users/groups allowlist that depends on target-tenant guest membership before the guest exists
- using direct connect as a substitute for site sharing
- allowing only SharePoint Online app without accounting for My Apps / My Sign-ins / MFA registration needs

---

## Decision summary for this project

Because this repo is centered on SharePoint collaboration architecture, the safest recommendation is:

- **Use cross-tenant sync with `userType=Member`** for recurring franchise/partner users who should feel internal
- **Use B2B collaboration** for narrower guest-style cases
- **Use B2B direct connect only for Teams shared channels**
- **Never make target-tenant dynamic group membership the first inbound cross-tenant gate for first-time SharePoint access**
