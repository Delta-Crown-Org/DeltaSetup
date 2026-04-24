# Sources

All sources below are **Tier 1** unless noted otherwise because they are official Microsoft Learn or Microsoft Graph Learn documentation.

## Primary Microsoft Learn sources used

1. **What is a multitenant organization in Microsoft Entra ID?**  
   https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview
   - **Authority:** Official Microsoft Learn product documentation
   - **Why used:** Canonical definition of MTO, benefits, constraints, limits, and required provisioning model
   - **Key points used:** MTO definition, boundary model, MTO constraints, P1 licensing, reciprocal tenant relationship, need to provision external member users

2. **Multitenant organization capabilities in Microsoft Entra ID**  
   https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/overview
   - **Authority:** Official Microsoft Learn
   - **Why used:** Best comparative source across B2B collaboration, B2B direct connect, cross-tenant sync, and MTO
   - **Key points used:** Difference between MTO and cross-tenant sync, user type defaults, capability comparison, people search, high-trust assumptions

3. **Limitations in multitenant organizations**  
   https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-known-issues
   - **Authority:** Official Microsoft Learn
   - **Why used:** Required for gotchas, unsupported scenarios, showInAddressList behavior, contact collisions, deprovisioning caveats
   - **Key points used:** MTO unsupported scenarios, complex topology guidance, B2B guest→member conversion caveat, showInAddressList default, contact collision limitation, delete behavior

4. **What is cross-tenant synchronization?**  
   https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview
   - **Authority:** Official Microsoft Learn
   - **Why used:** Best overview for scope, supported attributes, automatic redemption, existing-user behavior, deprovisioning, showInAddressList, and FAQ-style gotchas
   - **Key points used:** one-way sync model, source-of-authority behavior, existing B2B user handling, user types, deprovisioning triggers, `showInAddressList`, B2B direct connect limits

5. **Configure cross-tenant synchronization**  
   https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure?pivots=same-cloud-synchronization
   - **Authority:** Official Microsoft Learn
   - **Why used:** Operational sequence, troubleshooting, `userType` mapping behavior, failure messages, quarantine references
   - **Key points used:** Allow user sync into target tenant, automatic redemption prerequisites, `Member` vs `Guest`, `Apply this mapping = Always`, `AzureActiveDirectoryCrossTenantSyncPolicyCheckFailure`, monitoring/quarantine

6. **Cross-tenant access overview**  
   https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview
   - **Authority:** Official Microsoft Learn
   - **Why used:** Default-vs-organization-specific settings, precedence rules, default posture, implementation warnings
   - **Key points used:** B2B collaboration enabled by default, organization settings precedence, deny-by-default implications, app/user/group conflict rules, access breakage warnings

7. **Cross-tenant access settings**  
   https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration
   - **Authority:** Official Microsoft Learn
   - **Why used:** Detailed scoping behavior, invitation-time policy checks, inbound sync checkbox, automatic redemption details
   - **Key points used:** invitation-time evaluation, partner-specific scoping, Allow user sync into this tenant, auto-redemption notes, app allowlist caveats

8. **B2B guest user properties**  
   https://learn.microsoft.com/en-us/entra/external-id/user-properties
   - **Authority:** Official Microsoft Learn
   - **Why used:** Definitions of external Guest vs external Member and their intended semantics
   - **Key points used:** meaning of `userType`, host-tenant interpretation of Member vs Guest

9. **synchronizationJob resource type**  
   https://learn.microsoft.com/en-us/graph/api/resources/synchronization-synchronizationjob?view=graph-rest-1.0
   - **Authority:** Official Microsoft Graph Learn reference
   - **Why used:** Precise behavior for starting jobs out of quarantine
   - **Key points used:** starting a job clears quarantine status

## Key credibility notes
- These sources are the highest-authority public references available for Entra/M365 cross-tenant behavior.
- Microsoft Learn pages include version-specific operational guidance and were preferred over blogs or community answers.
- Some behaviors, especially Microsoft 365 app experience differences for B2B Members, are explicitly described by Microsoft as evolving. Those were treated as directional product guidance rather than hard guarantees for every workload.

## Most important quotes

### MTO definition and benefits
- "Multitenant organization is a feature in Microsoft Entra ID and Microsoft 365 that enables you to define a boundary around the Microsoft Entra tenants that your organization owns."
- "Each pair of tenants in the group is governed by cross-tenant access settings that you can use to configure B2B collaboration."
- "Improved collaborative experience in new Microsoft Teams"
- "Improved collaborative experience in Viva Engage"

### MTO vs cross-tenant sync
- "Cross-tenant synchronization - Provides a synchronization service that automates creating, updating, and deleting B2B collaboration users across your organization of multiple tenants."
- "Multitenant organization - Defines a boundary around the Microsoft Entra tenants that your organization owns... In conjunction with B2B member provisioning, enables seamless collaboration experiences in Microsoft Teams and Microsoft 365 applications like Microsoft Viva Engage."
- "Compare multitenant capabilities... cross-tenant synchronization and multitenant organization capabilities are independent of each other, though both rely on underlying B2B collaboration."

### userType and mappings
- "Member... Default. Users will be created as external member (B2B collaboration users) in the target tenant. Users will be able to function as any internal member of the target tenant."
- "Guest... Users will be created as external guests (B2B collaboration users) in the target tenant."
- "If the B2B user already exists in the target tenant, then Member (userType) won't be changed to Member, unless the Apply this mapping setting is set to Always."
- "By default, new B2B users are provisioned as B2B members, while existing B2B guests remain B2B guests."
- "By default, showInAddressList is synchronized into a target tenant as true."

### Default vs override posture
- "By default, B2B collaboration with other Microsoft Entra organizations is enabled"
- "The default cross-tenant access settings apply to all Microsoft Entra organizations external to your tenant, except organizations for which you configure custom settings."
- "Organizational settings take precedence over default settings."
- "Changing the default inbound or outbound settings to block access could block existing business-critical access to apps in your organization or partner organizations."

### Failure modes
- "The source tenant has not enabled automatic user consent with the target tenant."
- "The target tenant has not enabled inbound synchronization with this tenant."
- "If provisioning seems to be in an unhealthy state, the configuration will go into quarantine."
- "when provisioning scope is reduced while a synchronization job is running, users fall out of scope and are soft deleted"
- "Start synchronization. If the job is in quarantine, the quarantine status is cleared."
