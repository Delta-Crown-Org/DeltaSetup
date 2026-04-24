# Lessons from Other HTT Projects

## Why This Exists
These lessons are the stuff that usually gets lost in Slack threads, post-mortems, and human memory. Which is adorable right up until the same mistake happens again.

This file captures the practical lessons DeltaSetup should inherit from prior HTT cross-tenant work.

---

## Lesson 1: Dynamic Groups Are Great Authorization Tools, Not First-Admission Gates

### Where we learned it
`Convention-Page-Build` — `AADSTS500213-ROOT-CAUSE-AND-FIX.md`

### What happened
Inbound B2B collaboration policy for partner tenants was scoped to dynamic groups in the resource tenant.

### Why it failed
Those dynamic groups depended on guest objects already existing.
But inbound policy was evaluated before the guest object could exist.

### Result
First-time users were blocked with `AADSTS500213`.

### Durable lesson
Use dynamic groups after the identity object exists:
- SharePoint permissions
- Teams membership
- M365 groups

Do not use them as the first gate for inbound B2B collaboration if they rely on resource-tenant directory state.

---

## Lesson 2: Admission and Authorization Must Be Designed Separately

### Where we learned it
`Convention-Page-Build` + `Cross-Tenant-Utility`

### What happened
There was a tendency to push business authorization rules upward into Entra partner-policy scoping.

### Why that is risky
It mixes two different concerns:
- **admission** — can this external identity enter the tenant?
- **authorization** — what can this user access once they exist in the tenant?

### Durable lesson
Keep partner policy broad enough to let the identity path complete.
Then enforce business access where the platform is clearer and more observable:
- SharePoint groups
- Team membership
- dynamic groups
- M365 groups

---

## Lesson 3: B2B Direct Connect Is Not a General SharePoint Access Strategy

### Where we learned it
`CROSS-TENANT-DIRECT-ACCESS-INVESTIGATION.md`

### What happened
There was understandable hope that direct connect might provide “no-guest-object” access to regular SharePoint sites.

### Reality
It is the right tool for **Teams shared channels**, not standard SharePoint site access.

### Durable lesson
Use Direct Connect when the collaboration object is a shared channel.
Do not promise normal SharePoint site navigation off that model.

---

## Lesson 4: Automatic Redemption Must Be Bilateral for a Smooth First Run

### Where we learned it
`Convention-Page-Build` audits + `Cross-Tenant-Utility`

### What happened
User experience depended heavily on whether inbound and outbound automatic redemption settings were configured on both sides.

### Durable lesson
If you want “user clicks link and it just works,” check both directions.
One-sided configuration often leaves you with prompts, odd handoffs, or inconsistent first-access behavior.

---

## Lesson 5: Domain-Based Dynamic Groups Are Useful, but Crude

### Where we learned it
`Convention-Page-Build` and broader HTT identity analysis

### What happened
Domain-based rules were effective for broad brand-level grouping.

### Limitation
They are coarse:
- good for "all users from tenant/domain X"
- weak for nuanced role/location logic
- dependent on consistent mail/UPN realities

### Durable lesson
Use domain-based groups for broad brand segmentation.
If finer-grained authorization is needed, sync the attributes required to support it.

---

## Lesson 6: Sync Configuration Is Governance, Not Just Plumbing

### Where we learned it
`Cross-Tenant-Utility`

### What happened
Cross-tenant sync surfaced issues around:
- userType expectations
- attribute mappings
- showInAddressList behavior
- scope changes acting like deprovisioning

### Durable lesson
Treat sync decisions like architecture decisions:
- decide userType early
- map attributes intentionally
- pilot before broad rollout
- assume filter/scope changes have real downstream effects

---

## Lesson 7: SharePoint Access Troubleshooting Is Usually Layer Confusion

### Where we learned it
Both repos, repeatedly, because Microsoft loves nested control planes.

### Common confusion patterns
- sign-in failure blamed on SharePoint permissions
- Team shell visibility mistaken for file access readiness
- guest object existence mistaken for effective site authorization
- direct-link success mistaken for full navigation/search readiness

### Durable lesson
Troubleshoot in this order:
1. identity admission
2. object existence / redemption / sync
3. authorization group membership
4. site / team binding
5. UX/navigation/search expectations

---

## Lesson 8: Deny-by-Default Is Good, But Only If Overrides Are Deliberate

### Where we learned it
`Cross-Tenant-Utility`

### What happened
Default cross-tenant posture across HTT was more permissive than ideal.

### Durable lesson
Set tenant defaults deliberately.
Then add explicit partner overrides.
But do not confuse “tight defaults” with “randomly over-scoped partner rules that break first access.”

Good security is precise, not performative.

---

## What DeltaSetup Should Inherit Immediately
1. Keep current DCE work single-tenant by default.
2. Add a cross-tenant collaboration ADR before future external/franchise overlays expand.
3. Explicitly ban resource-tenant dynamic-group gating for inbound B2B collaboration.
4. Document B2B collaboration, cross-tenant sync, and Direct Connect as distinct patterns.
5. Add order-of-operations guidance before any future cross-tenant build work starts.
