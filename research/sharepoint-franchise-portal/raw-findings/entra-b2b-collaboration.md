# Microsoft Entra B2B Collaboration and Cross-Tenant Access

## Source: Microsoft Learn - Cross-Tenant Access Overview
**URL**: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview
**Credibility**: Tier 1 - Official Microsoft Documentation
**Date Retrieved**: March 2025

## Cross-Tenant Access Settings

### Default Settings
- **B2B collaboration**: All internal users enabled by default
- **B2B direct connect**: Blocked by default (mutual trust required)
- **Cross-tenant sync**: Disabled by default
- **Organizational settings**: No organizations added by default

### License Requirements
- Microsoft Entra ID P1 required for:
  - Trust settings configuration
  - Access settings for specific users/groups/applications
  - Per-tenant configuration

### B2B Direct Connect
- Requires mutual trust relationship
- Both organizations must enable
- No guest account created
- User's home tenant manages identity
- Best for: Ongoing collaboration, Teams shared channels

### B2B Collaboration
- Guest account created in resource tenant
- Resource tenant manages access
- Supports Conditional Access
- Best for: Access to resources, SharePoint sites, Teams

## Automatic Redemption Setting

### Description
Automatically redeem invitations so users don't see consent prompts on first access.

### Behavior Matrix

| Scenario | Automatic Redemption | Invitation Email | Consent Prompt | Notification Email |
|----------|---------------------|------------------|----------------|-------------------|
| **Cross-tenant sync** | Required | No | No | No |
| **B2B collaboration** | Optional | No | No | Yes |
| **B2B direct connect** | Optional | N/A | No | N/A |

### Configuration Requirements
- Both source (outbound) AND target (inbound) tenants must enable
- If only one tenant enables, consent prompt still appears

## Tenant Restrictions

### Purpose
Control external accounts users can use on managed devices:
- Accounts created in unknown tenants
- External accounts given by other organizations

### Benefits of B2B over Ad-Hoc Accounts
- Conditional Access enforcement
- MFA capability
- Inbound/outbound access management
- Session termination when employment changes
- Sign-in log visibility

## Franchise Portal Scenarios

### Scenario 1: Franchisees in Same Tenant
- Use M365 Groups for segmentation
- Dynamic groups based on location attributes
- No B2B complexity

### Scenario 2: Franchisees in External Tenants
- B2B collaboration for resource access
- Cross-tenant sync for member-type accounts
- Automatic redemption for seamless experience

### Scenario 3: Franchisees with Consumer Accounts
- Microsoft accounts (Outlook.com, Gmail)
- Social identity providers
- Limited governance capabilities

## Security Considerations

### Access Reviews
- Regular review of B2B guest access
- Automated expiration of inactive guests
- Manager attestation for continued access

### Conditional Access
- Location-based policies
- Device compliance requirements
- Risk-based policies

### Guest User Lifecycle
1. Invitation sent
2. Redemption (manual or automatic)
3. Access granted based on policies
4. Regular access reviews
5. Access removal when no longer needed
