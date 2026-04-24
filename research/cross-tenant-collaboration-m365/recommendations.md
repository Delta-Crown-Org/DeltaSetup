# Recommendations: How DeltaSetup Should Plan for Cross-Tenant Collaboration

## Recommendation 1: Keep Single-Tenant as the Default Baseline
DeltaSetup should continue treating the current DCE architecture as the primary operating model:
- one tenant
- hub-per-brand
- one Teams-connected operations site
- standalone supporting sites
- dynamic groups for SharePoint / Teams authorization

That baseline is simpler, supportable, and not infected by cross-tenant complexity.

## Recommendation 2: Add a Formal Cross-Tenant Overlay, Not a Silent Assumption
Future cross-tenant planning should be documented as a separate architecture overlay.

That overlay should answer:
- who is external versus internal-like?
- which collaboration pattern applies?
- what identity object should exist in the resource tenant?
- where is access admitted versus where is it authorized?

## Recommendation 3: Use This Pattern Selection Logic

### Use B2B Collaboration Guests When
- access is bounded to a few sites, teams, or resources
- external users are not long-term internal-like collaborators
- temporary access is common
- invitation and guest lifecycle are acceptable tradeoffs

### Use Cross-Tenant Sync When
- partner users collaborate repeatedly
- invitation churn is too costly
- better lifecycle management is needed
- target-side authorization depends on consistent object presence and mapped attributes
- Teams / directory experience should feel closer to internal usage

### Use B2B Direct Connect When
- the problem is specifically a **Teams shared channel** problem
- the user does not need normal SharePoint site access
- you want narrow collaboration without full Team membership

### Do Not Use B2B Direct Connect When
- the real requirement is a normal SharePoint portal or site
- the real requirement is Team membership plus broad file/site access

## Recommendation 4: Ban the Dangerous Pattern Explicitly
DeltaSetup research and future ADRs should explicitly prohibit this:

> Do not scope inbound B2B collaboration `usersAndGroups` to dynamic groups in the resource tenant when those groups depend on guest/member objects that are created only after first admission.

That should be called out as a hard anti-pattern with incident evidence.

## Recommendation 5: Use the Correct Order of Operations

### Partner Onboarding Sequence
1. set tenant default posture deliberately; prefer deny-by-default with explicit partner overrides
2. add partner organization
3. configure inbound B2B collaboration
   - users/groups = `AllUsers` unless there is a truly safe pre-existing gating model
   - applications = scoped to needed apps
4. configure bilateral automatic redemption if using B2B collaboration or sync
5. enable cross-tenant sync prerequisites if sync is part of the design
6. configure attribute mappings and `userType`
7. onboard pilot users only
8. verify object creation and attribute population in target tenant
9. verify dynamic-group resolution
10. assign SharePoint / Teams access
11. test first-run experience before broad rollout

### SharePoint Authorization Sequence
1. confirm target object exists
2. confirm correct dynamic-group membership
3. confirm site / team / M365 group bindings
4. confirm site sharing restrictions are compatible
5. then test navigation, search, and Teams tabs

## Recommendation 6: Make Attribute Strategy a First-Class Concern
If DeltaSetup ever plans cross-tenant sync, the target authorization model must inform the source attribute mapping.

If target dynamic groups depend on:
- `department`
- `companyName`
- `jobTitle`
- extension attributes

then sync must carry those values correctly.

Otherwise you end up with wonderfully synchronized users who still fail authorization because the attributes needed for grouping never showed up. Love that for us.

## Recommendation 7: Add Research and ADR Artifacts
Add a dedicated research pack plus a future ADR.

### Research pack
- `research/cross-tenant-collaboration-m365/README.md`
- `research/cross-tenant-collaboration-m365/analysis.md`
- `research/cross-tenant-collaboration-m365/recommendations.md`
- `research/cross-tenant-collaboration-m365/sources.md`
- `research/cross-tenant-collaboration-m365/lessons-from-htt-projects.md`

### Future ADR
- `docs/architecture/decisions/ADR-004-cross-tenant-collaboration-sharepoint-access.md`

### Future fitness tests
A future architecture test should verify that:
- B2B Direct Connect is never described as the normal SharePoint access mechanism
- inbound partner policy is not gated by resource-tenant dynamic groups
- bilateral redemption is documented when relevant
- userType and attribute mapping are called out explicitly
- admission and authorization layers are kept separate

## Recommendation 8: Add an Operator-Facing Troubleshooting Model
Cross-tenant troubleshooting should begin with symptom classification:

### Identity-layer symptom examples
- sign-in error before site or Team loads
- `AADSTS` errors
- invitation/redemption mismatch
- cross-tenant sync object missing

### Authorization-layer symptom examples
- site opens but content is missing
- Team is visible but Files tab fails
- direct link works but navigation/search does not
- shared channel works but parent site does not

That split will cut support confusion dramatically.

## Recommendation 9: Prefer Task-Based Navigation for External Users
When external or synced cross-tenant users are involved:
- use direct links
- use pinned Teams tabs
- use clear “start here” pages
- do not rely on broad search-discovery expectations
- keep hub navigation honest and intentional

External users usually do better with task paths than with free-form intranet wandering.

## Recommended Immediate Next Steps
1. Keep current DeltaSetup single-tenant direction intact.
2. Add this research package to the repo.
3. Create ADR-004 for future cross-tenant collaboration scenarios.
4. Use lessons from `Convention-Page-Build` as explicit anti-pattern evidence.
5. Revisit any future “dynamic groups + SharePoint + external identity” plan through the admission-vs-authorization lens before implementation.
