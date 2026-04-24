# Microsoft 365 / Entra external collaboration realities for DeltaSetup

## Executive summary

For **DeltaSetup planning**, Microsoft currently gives you **three materially different cross-tenant patterns**:

1. **Entra B2B collaboration (guest or external member object)**
   - Best when external people need **broad access to SharePoint, Teams teams, M365 groups, apps, and files** in the resource tenant.
   - Creates a **B2B collaboration user object** in the resource tenant. By default this is `UserType=Guest`, but it can also be created/synced as an **external member** in some multitenant scenarios.
   - First-run experience may involve **invitation redemption / consent**, unless **automatic redemption** is configured on **both** tenants.

2. **Cross-tenant synchronization**
   - Automates creation/update/delete of **B2B collaboration users** across tenants using the provisioning engine.
   - Helpful when related tenants want **pre-created objects**, lifecycle automation, and potentially a more “member-like” experience for Microsoft 365 discovery scenarios.
   - Important reality: Microsoft says synced users still have **the same Microsoft 365 experience as B2B collaboration users today**, even though over time `UserType=Member` is intended to produce differentiated experiences.

3. **B2B Direct Connect**
   - **Only for Teams shared channels** today.
   - Does **not** create guest objects in the resource tenant.
   - Excellent for narrow collaboration in a shared channel, but **not** a substitute for SharePoint site access, Teams full-team access, or broad M365 navigation/search needs.

## DeltaSetup planning implication

If DeltaSetup stays **single-tenant**, most of this is design reference rather than an implementation requirement. If DeltaSetup expects **separate partner/brand/customer tenants**, then:

- Use **B2B collaboration** when people need **full team/site/document access**.
- Use **B2B Direct Connect** only when the requirement is specifically **shared channels without tenant switching**.
- Use **cross-tenant sync** only when there is a strong reason to maintain **pre-provisioned external identities** and lifecycle between related tenants.

## Key findings by requested topic

### 1) B2B guest access vs cross-tenant sync member objects vs B2B Direct Connect

| Model | Object in resource tenant | Main scope | Best fit | Major limitation |
|---|---|---|---|---|
| B2B collaboration | Yes, B2B user object | Broad M365/app access | SharePoint sites, Teams teams, app access | Guest-style first-run and limited discoverability unless carefully configured |
| Cross-tenant sync | Yes, auto-provisioned B2B user object (guest or external member) | Broad M365/app access with lifecycle sync | Related tenants needing pre-created identities | Still inherits many B2B collaboration realities today |
| B2B Direct Connect | No guest object | Teams shared channels only | Narrow channel collaboration | Not a general SharePoint / full-team / app-access solution |

Evidence:
- Microsoft says cross-tenant sync **creates, updates, and deletes Microsoft Entra B2B collaboration users** across tenants.
- Microsoft says B2B Direct Connect **currently works with Teams shared channels** and external users collaborate **without being added as guests**.
- Teams docs explicitly state **guests cannot be added to shared channels**; external participants use **B2B Direct Connect** instead.

### 2) Cross-tenant access settings and first-run blocking

Microsoft’s official model is that **cross-tenant access settings evaluate inbound and outbound access**, and admins can scope access to **specific external users, groups, and applications**. Microsoft explicitly says:

- inbound settings decide whether external users can access your resources,
- outbound settings decide whether your users can access external resources,
- organization-specific settings require the partner’s **user object IDs, group object IDs, or application IDs**, and
- if you allow only a subset of apps, you may also need to explicitly allow **My Apps / My Profile / My Sign-ins / App Access Panel** to avoid broken first-run flows.

**Planning reality:** first-run access can fail **before a useful guest experience exists** if resource-tenant scoping is too narrow.

Two practical failure modes are strongly supported by the docs:

1. **App allowlists break onboarding UX**
   - Microsoft warns that if you allow only selected apps, users may be unable to reach **My Apps** or complete **MFA registration** unless those supporting apps are also allowed.

2. **Pre-redemption / pre-effective-object dependency is risky**
   - Cross-tenant inbound scoping is built around **partner tenant IDs, user IDs, group IDs, and app IDs**, not resource-tenant dynamic guest grouping.
   - For manually invited B2B users, the object exists in `PendingAcceptance` state before redemption; for other first-run cross-tenant paths, access evaluation can happen before any resource-tenant grouping logic would practically help.
   - Therefore, **resource-tenant policies that rely on dynamic groups of external users are poor controls for first-run admission**.

**AADSTS500213-style issue note:** this exact dynamic-group/pre-redemption edge case is **not clearly documented by Microsoft Learn with that specific error code mapping** in the sources reviewed. However, it is consistent with Microsoft’s documented policy evaluation model and with observed “blocked by cross-tenant access settings / app scoping” behavior. Treat this point as **high-confidence operational inference, not directly documented Microsoft wording**.

### 3) Automatic redemption / invitation redemption / invitation state and first access UX

Microsoft documents these states and behaviors clearly:

- When a B2B guest is added, the account’s consent status starts as **`PendingAcceptance`**.
- In the admin center, the invited user shows **Invitation state = Pending acceptance** before redemption.
- After the user accepts, it becomes **Accepted / Invitation accepted = Yes**.
- **Automatic redemption** suppresses the first consent prompt **only if both sides enable it**:
  - source/home tenant outbound trust setting, and
  - resource/target tenant inbound trust setting.
- For **cross-tenant sync**, automatic redemption is **required**.
- For B2B collaboration and B2B Direct Connect, automatic redemption is **optional** but improves first-run UX.

Practical UX impact:
- **No automatic redemption on both sides** => more consent friction on first access.
- **Automatic redemption on both sides** => smoother first access, but **application consent** or Conditional Access requirements can still interrupt the flow.
- Invitation/link type still matters: direct links, My Apps, team/site URLs, and invitation emails can behave differently if app allowlists or MFA registration apps are blocked.

### 4) SharePoint / Teams implications for navigation, permissions, search/discoverability, and troubleshooting

#### SharePoint and Teams with B2B guests
- SharePoint with Entra B2B integration **always creates a guest account** when sharing sites, and also for files/folders under that integration model.
- Guests can navigate shared sites/subsites **based on granted permissions**, but they do **not** become equivalent to internal discoverability users by default.
- Teams guest access requires the guest to be added to **at least one team** before Teams guest functionality is available.
- Teams docs note access can take **up to 12 hours** after adding a guest to a team.

#### Shared channels / B2B Direct Connect
- Shared channels have a **separate SharePoint site** for files.
- Only channel owners/members have access to that site; **parent team members and admins do not automatically have access** unless they are also channel members.
- Site permissions for a shared channel site **cannot be independently managed in SharePoint**; membership is synced from Teams.
- External shared-channel participants can work without tenant switching, but this model is intentionally **narrow**.

#### Search and discoverability
- Cross-tenant sync can help enable **people search** in Microsoft 365 if `showInAddressList` is true in the target tenant.
- B2B Direct Connect does **not** create a guest presence in the tenant, so it is not a people-search/discoverability model in the same way.
- Guest users are generally less naturally discoverable in navigation/search than internal users; admin/operators should assume **direct links and explicit membership** matter.

#### Operator troubleshooting realities
Operators should check, in roughly this order:
1. **Cross-tenant access settings** on both tenants.
2. Whether **B2B collaboration** or **B2B Direct Connect** is the intended pattern.
3. Whether **automatic redemption** is enabled on both sides.
4. Whether the user is **PendingAcceptance** or already redeemed.
5. Whether app scoping forgot required apps like **My Apps**, **My Profile**, **My Sign-ins**, or **App Access Panel**.
6. For Teams shared channels, whether the user was added as the correct **external participant identity** rather than an existing guest object.
7. For SharePoint, whether tenant/site external sharing settings and domain restrictions permit the share.

## Recommended DeltaSetup posture

1. **Default to single-tenant collaboration wherever politically possible.** It avoids the guest/direct-connect/sync edge cases entirely.
2. If cross-tenant is required, pick **one primary pattern per use case**:
   - **full site/team/workspace access** → B2B collaboration,
   - **narrow Teams shared channel collaboration** → B2B Direct Connect,
   - **related-tenant lifecycle + pre-created external identities** → cross-tenant sync.
3. For first-run reliability, do **not** rely on resource-tenant dynamic guest groups for admission. Use **partner tenant scoping + app scoping + pre-provisioned objects where needed**.
4. If you use app allowlists, include the documented Microsoft support apps for onboarding UX.
5. Explicitly document for support staff whether a user is expected to appear as:
   - guest/external member object, or
   - shared-channel external participant with no guest object.

## Uncertain / needs lab validation

1. The exact mapping from **AADSTS500213** to the specific “resource-tenant dynamic-group dependency before redemption” pattern was **not directly documented** in the official Microsoft Learn pages reviewed.
2. Microsoft says `UserType=Member` will increasingly produce differentiated M365 experiences, but current docs also say synced users still have **the same M365 experience as B2B collaboration users** today. The service-by-service gap is still evolving.
3. Teams docs state that external shared-channel collaboration uses **B2B Direct Connect** and does **not** use guest accounts, yet also say **guest access in Teams must be enabled** to invite them. That is documented, but operationally counterintuitive, so it should be validated in a pilot.
