# Raw Microsoft Learn quotes

## AADSTS500213
Source: https://learn.microsoft.com/en-us/entra/identity-platform/reference-error-codes#aadsts500213

> "AADSTS500213 NotAllowedByInboundPolicyTenant - The resource tenant's cross-tenant access policy doesn't allow this user to access this tenant."

---

## Cross-tenant access settings for B2B collaboration
Source: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration

> "Both allow/block list and cross-tenant access settings are checked at the time of invitation."

> "All external users and groups: Applies the action you chose under Access status to all users and groups from external Microsoft Entra organizations."

> "Select external users and groups... Lets you apply the action you chose under Access status to specific users and groups within the external organization."

> "In the Add other users and groups pane, in the search box, type the user object ID or group object ID you obtained from your partner organization."

> "If you are using the native sharing capabilities in Microsoft SharePoint and Microsoft OneDrive with Microsoft Entra B2B integration enabled, you must add the external domains to the external collaboration settings. Otherwise, invitations from these applications might fail, even if the external tenant has been added in the cross-tenant access settings."

> "Automatically redeem invitations with the tenant <tenant>: Check this setting if you want to automatically redeem invitations. If so, users from the specified tenant won't have to accept the consent prompt the first time they access this tenant using cross-tenant synchronization, B2B collaboration, or B2B direct connect. This setting only suppresses the consent prompt if the specified tenant also checks this setting for outbound access."

> "If you want to configure Cross-tenant access settings to allow only a designated set of applications... if you configure an allowlist and only allow SharePoint Online, the user can't access My Apps or register for MFA in the resource tenant."

---

## Cross-tenant synchronization overview
Source: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview

> "Cross-tenant synchronization automates creating, updating, and deleting Microsoft Entra B2B collaboration users and groups across tenants in an organization."

> "Users created with cross-tenant synchronization are able to access both Microsoft applications (such as Teams and SharePoint)..."

> "Users created by cross-tenant synchronization will have the same experience when accessing Microsoft Teams and other Microsoft 365 services as B2B collaboration users created through a manual invitation."

> "Over time, the member userType will be used by the various Microsoft 365 services to provide differentiated end user experiences for users in a multitenant organization."

> "The cross-tenant synchronization settings are an inbound only organizational settings... These settings don't impact B2B invitations created through other processes such as manual invitation or Microsoft Entra entitlement management."

> "The automatic redemption setting will only suppress the consent prompt and invitation email if both the home/source tenant (outbound) and resource/target tenant (inbound) checks this setting."

> "Will cross-tenant synchronization manage existing B2B users? Yes."

> "Cross-tenant synchronization can update existing B2B users, ensuring that each user has only one account."

> "What user types can be synchronized? ... Users can be synchronized to target tenants as external members (default) or external guests."

> "B2B direct connect is the underlying identity technology required for Teams Connect shared channels."

> "B2B collaboration is recommended for all other cross-tenant application access scenarios, including both Microsoft and non-Microsoft applications."

> "B2B direct connect and cross-tenant synchronization are designed to co-exist..."

> "There's no plan to extend support for B2B direct connect beyond Teams Connect shared channels."

---

## Configure cross-tenant synchronization
Source: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure?pivots=same-cloud-synchronization

> "Select the Allow user synchronization into this tenant checkbox."

> "In this step, you automatically redeem invitations so users from the source tenant don't have to accept the consent prompt. This setting must be checked in both the source tenant (outbound) and target tenant (inbound)."

> "For cross-tenant synchronization to work, at least one internal user must be assigned to the configuration."

> "Member... Default. Users will be created as external member (B2B collaboration users) in the target tenant. Users will be able to function as any internal member of the target tenant."

> "Guest... Users will be created as external guests (B2B collaboration users) in the target tenant."

Troubleshooting quotes:

> "Details: The source tenant has not enabled automatic user consent with the target tenant."

> "Details: The target tenant has not enabled inbound synchronization with this tenant."

---

## B2B direct connect overview
Source: https://learn.microsoft.com/en-us/entra/external-id/b2b-direct-connect-overview

> "B2B direct connect is a feature of Microsoft Entra External ID... This feature currently works with Microsoft Teams shared channels."

> "Currently, B2B direct connect capabilities work with Teams shared channels."

> "B2B direct connect users don't have a presence in your Microsoft Entra organization..."

> "With B2B direct connect, you add the external user to a shared channel within a team. This user can access the resources within the shared channel, but they don't have access to the entire team or any other resources outside the shared channel."

---

## B2B direct connect setup
Source: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-direct-connect

> "By default, outbound B2B direct connect is blocked for your entire tenant, and inbound B2B direct connect is blocked for all external Microsoft Entra organizations."

> "Because B2B direct connect is established through mutual trust, both you and the other organization need to enable B2B direct connect with each other in your cross-tenant access settings."

---

## SharePoint external sharing overview
Source: https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview

> "Microsoft Entra B2B integration enabled -> Guest account always created... What happens when sharing sites? Guest account always created Microsoft Entra settings apply"

> "When users share with people outside the organization, an invitation is sent to the person in email, which contains a link to the shared item."

---

## B2B guest user properties
Source: https://learn.microsoft.com/en-us/entra/external-id/user-properties

> "External guest... The user object created in the resource Microsoft Entra directory has a UserType of Guest."

> "External member... The user object created in the resource Microsoft Entra directory has a UserType of Member."

> "Member: This value indicates an employee of the host organization... this user expects to have access to internal-only sites."

> "Guest: This value indicates a user who isn't considered internal to the company, such as an external collaborator, partner, or customer."
