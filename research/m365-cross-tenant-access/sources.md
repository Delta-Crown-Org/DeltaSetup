# Sources

## Microsoft Learn URLs used

1. **AADSTS500213 reference**  
   https://learn.microsoft.com/en-us/entra/identity-platform/reference-error-codes#aadsts500213

2. **Cross-tenant access settings for B2B collaboration**  
   https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration

3. **Cross-tenant access overview**  
   https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview

4. **Cross-tenant synchronization overview**  
   https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview

5. **Configure cross-tenant synchronization**  
   https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure?pivots=same-cloud-synchronization

6. **B2B direct connect overview**  
   https://learn.microsoft.com/en-us/entra/external-id/b2b-direct-connect-overview

7. **Set up B2B direct connect**  
   https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-direct-connect

8. **SharePoint external sharing overview**  
   https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview

9. **B2B guest user properties**  
   https://learn.microsoft.com/en-us/entra/external-id/user-properties

## Most important direct quotes

- **AADSTS500213**: "NotAllowedByInboundPolicyTenant - The resource tenant's cross-tenant access policy doesn't allow this user to access this tenant."
- **Invitation timing**: "Both allow/block list and cross-tenant access settings are checked at the time of invitation."
- **Targeted inbound user/group scoping**: "type the user object ID or group object ID you obtained from your partner organization."
- **SharePoint native sharing note**: "If you are using the native sharing capabilities in Microsoft SharePoint and Microsoft OneDrive with Microsoft Entra B2B integration enabled, you must add the external domains to the external collaboration settings. Otherwise, invitations from these applications might fail..."
- **Auto redemption bilateral requirement**: "This setting must be checked in both the source tenant (outbound) and target tenant (inbound)."
- **Cross-tenant sync Member**: "Users will be created as external member ... Users will be able to function as any internal member of the target tenant."
- **Cross-tenant sync Guest**: "Users will be created as external guests ... in the target tenant."
- **Direct connect scope**: "This feature currently works with Microsoft Teams shared channels."
- **Direct connect roadmap**: "There's no plan to extend support for B2B direct connect beyond Teams Connect shared channels."
- **SharePoint sharing object creation**: "Guest account always created"

## Credibility assessment
All sources above are **Tier 1** because they are official Microsoft Learn documentation or official Microsoft Learn reference pages. They are the most authoritative public documentation available for these behaviors.
