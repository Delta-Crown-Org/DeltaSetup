# Raw Microsoft Learn quotes

## Multitenant organization overview
Source: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview

> "Multitenant organization is a feature in Microsoft Entra ID and Microsoft 365 that enables you to define a boundary around the Microsoft Entra tenants that your organization owns."

> "Each pair of tenants in the group is governed by cross-tenant access settings that you can use to configure B2B collaboration."

> "The multitenant organization capability in Microsoft Teams is built on the assumption of reciprocal provisioning of B2B collaboration member users across multitenant organization tenants."

> "The multitenant organization capability in Viva Engage is built on the assumption of centralized provisioning of B2B collaboration member users into a hub tenant."

> "As such, the multitenant organization capability is best deployed with the use of a bulk provisioning engine for B2B collaboration users, for example with cross-tenant synchronization."

> "Any given tenant can only create or join a single multitenant organization."

> "A multitenant organization isn't allowed between a Cloud Solution Provider (CSP) and their customer tenants."

> "Maximum number of active tenants, including the owner tenant: 100"

---

## Multitenant organization capabilities
Source: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/overview

> "Cross-tenant synchronization - Provides a synchronization service that automates creating, updating, and deleting B2B collaboration users across your organization of multiple tenants."

> "Multitenant organization - Defines a boundary around the Microsoft Entra tenants that your organization owns... In conjunction with B2B member provisioning, enables seamless collaboration experiences in Microsoft Teams and Microsoft 365 applications like Microsoft Viva Engage."

> "Compare multitenant capabilities... cross-tenant synchronization and multitenant organization capabilities are independent of each other, though both rely on underlying B2B collaboration."

> "Users are synchronized from their home tenant to the resource tenant as B2B collaboration users."

> "If shown in address list, B2B collaboration users are available as contacts in Outlook. If elevated to user type Member, B2B collaboration member users are available in most Microsoft 365 applications."

> "For collaboration in most Microsoft 365 applications, a B2B collaboration user should be shown in address lists as well as be set to user type Member."

> "For enterprise organizations with complex identity topologies, consider using cross-tenant synchronization in Microsoft Entra ID."

---

## Limitations in multitenant organizations
Source: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-known-issues

> "If you're already using Microsoft Entra cross-tenant synchronization, for various multi-hub multi-spoke topologies, you don't need to use the Microsoft 365 admin center share users functionality. Instead, you might want to continue using your existing Microsoft Entra cross-tenant synchronization jobs."

> "For enterprise organizations with complex identity configurations, use cross-tenant synchronization in Microsoft Entra admin center."

> "By default, new B2B users are provisioned as B2B members, while existing B2B guests remain B2B guests. You can opt to convert B2B guests into B2B members by setting Apply this mapping to Always."

> "By default, showInAddressList is synchronized into a target tenant as true."

> "The at-scale provisioning of B2B users might collide with contact objects. The handling or conversion of contact objects isn't currently supported."

> "By default, when provisioning scope is reduced while a synchronization job is running, users fall out of scope and are soft deleted, unless Target Object Actions for Delete is disabled."

> "Currently, SkipOutOfScopeDeletions works for application provisioning jobs, but not for cross-tenant synchronization."

---

## Cross-tenant synchronization overview
Source: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview

> "Cross-tenant synchronization automates creating, updating, and deleting Microsoft Entra B2B collaboration users and groups across tenants in an organization."

> "Users created with cross-tenant synchronization are able to access both Microsoft applications (such as Teams and SharePoint) and non-Microsoft applications..."

> "Is a push process from the source tenant, not a pull process from the target tenant."

> "Attribute mapping is configured in the source tenant."

> "Extension attributes are supported."

> "Cross-tenant synchronization utilizes a feature that improves the user experience by suppressing the first-time B2B consent prompt and redemption process in each tenant."

> "The automatic redemption setting will only suppress the consent prompt and invitation email if both the home/source tenant (outbound) and resource/target tenant (inbound) checks this setting."

> "If a user is removed from the scope of sync in a source tenant, cross-tenant synchronization will soft delete them in the target tenant."

> "Cross-tenant synchronization will sync commonly used attributes on the user object in Microsoft Entra ID, including (but not limited to) displayName, userPrincipalName, and directory extension attributes."

> "Cross-tenant synchronization supports provisioning the manager attribute in the Azure commercial cloud."

> "Attributes including (but not limited to) photos, custom security attributes, and user attributes outside of the directory can't be synchronized by cross-tenant synchronization."

> "What user types can be synchronized?... Users can be synchronized to target tenants as external members (default) or external guests."

> "Cross-tenant synchronization will match the user and make any necessary updates to the user, such as update the display name. By default, the UserType won't be updated from guest to member, but you can configure this in the attribute mappings."

> "Yes, cross-tenant synchronization can enable people search in Microsoft 365. Ensure that the showInAddressList attribute is set to True on users in the target tenant. The showInAddressList attribute is set to true by default in the cross-tenant synchronization attribute mappings."

> "B2B collaboration is recommended for all other cross-tenant application access scenarios, including both Microsoft and non-Microsoft applications."

> "There's no plan to extend support for B2B direct connect beyond Teams Connect shared channels."

---

## Configure cross-tenant synchronization
Source: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure?pivots=same-cloud-synchronization

> "Select the Allow user synchronization into this tenant checkbox."

> "This setting must be checked in both the source tenant (outbound) and target tenant (inbound)."

> "Member... Default. Users will be created as external member (B2B collaboration users) in the target tenant. Users will be able to function as any internal member of the target tenant."

> "Guest... Users will be created as external guests (B2B collaboration users) in the target tenant."

> "If the B2B user already exists in the target tenant, then Member (userType) won't be changed to Member, unless the Apply this mapping setting is set to Always."

> "Symptom - Test connection fails with AzureActiveDirectoryCrossTenantSyncPolicyCheckFailure"

> "Details: The source tenant has not enabled automatic user consent with the target tenant."

> "Details: The target tenant has not enabled inbound synchronization with this tenant."

> "If provisioning seems to be in an unhealthy state, the configuration will go into quarantine."

---

## Cross-tenant access overview
Source: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview

> "By default, B2B collaboration with other Microsoft Entra organizations is enabled, and B2B direct connect is blocked."

> "The default cross-tenant access settings apply to all Microsoft Entra organizations external to your tenant, except organizations for which you configure custom settings."

> "Organizational settings take precedence over default settings."

> "Changing the default inbound or outbound settings to block access could block existing business-critical access to apps in your organization or partner organizations."

> "Example 1: If you block inbound access for all external users and groups, access to all your applications must also be blocked."

> "Conditional Access policies that require MFA or Terms of Use (ToU) can prevent users from completing MFA registration or ToU consent."

---

## Cross-tenant access settings
Source: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration

> "Both allow/block list and cross-tenant access settings are checked at the time of invitation."

> "Allow users sync into this tenant"

> "Automatically redeem invitations with the tenant <tenant>"

> "This setting only suppresses the consent prompt if the specified tenant also checks this setting for outbound access."

> "if you configure an allowlist and only allow SharePoint Online, the user can't access My Apps or register for MFA in the resource tenant."

---

## B2B guest user properties
Source: https://learn.microsoft.com/en-us/entra/external-id/user-properties

> "Member: This value indicates an employee of the host organization... this user expects to have access to internal-only sites."

> "Guest: This value indicates a user who isn't considered internal to the company, such as an external collaborator, partner, or customer."

> "External member... The user object created in the resource Microsoft Entra directory has a UserType of Member."

> "External guest... The user object created in the resource Microsoft Entra directory has a UserType of Guest."

---

## Microsoft Graph reference for quarantine handling
Source: https://learn.microsoft.com/en-us/graph/api/resources/synchronization-synchronizationjob?view=graph-rest-1.0

> "Start synchronization. If the job is in quarantine, the quarantine status is cleared."
