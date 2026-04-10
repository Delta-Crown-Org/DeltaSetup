# Multi-Tenant and Cross-Tenant Considerations

## Cross-Tenant Collaboration Limitations

## Source: Microsoft Learn - Cross-Tenant Access Overview
**URL**: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview
**Credibility**: Tier 1 - Official Microsoft Documentation
**Date Retrieved**: March 2025

## B2B Collaboration Limitations

### Cross-Tenant Access Settings Scope
- Applies to Microsoft Entra organizations only
- Does not apply to non-Microsoft Entra identities (social accounts, etc.)
- Requires mutual configuration for optimal experience

### Limitations by Feature

#### B2B Collaboration
| Capability | Supported | Notes |
|-----------|-----------|-------|
| SharePoint access | Yes | Guest account required |
| Teams access | Yes | Guest experience |
| Outlook integration | Limited | External recipient indicators |
| Planner | Yes | Guest tasks supported |
| Power BI | Yes | Sharing with guests |
| OneDrive | Yes | Sharing links |
| Yammer | Limited | Community dependent |

#### B2B Direct Connect
| Capability | Supported | Notes |
|-----------|-----------|-------|
| Teams shared channels | Yes | Mutual trust required |
| SharePoint | No | Not supported |
| Chat/Files | Yes | Within shared channel |
| Meetings | Yes | Scheduled meetings |

### What Cannot Be Shared Across Tenants

1. **Global Address List (GAL)**
   - External users don't appear in GAL by default
   - Address book policies may hide external contacts

2. **Distribution Lists**
   - Cannot add external users to DLs directly
   - Workaround: Mail-enabled security groups with guests

3. **Dynamic Distribution Groups**
   - Based on recipient filters
   - External users typically excluded

4. **SharePoint Hub Sites**
   - Hub association is tenant-scoped
   - Cannot associate cross-tenant sites to hub

5. **Microsoft 365 Group Discoverability**
   - Groups not discoverable across tenants
   - Must be invited/added directly

6. **Search Federation**
   - SharePoint search is tenant-scoped
   - No cross-tenant search aggregation

7. **OneDrive Sync**
   - Cannot sync external shared libraries
   - Must use web interface or Teams

## B2B Guest Access for Franchisees

### Guest Account Lifecycle

#### Provisioning Methods
1. **Invitation**: Resource tenant invites guest
2. **Redemption**: Guest accepts invitation
3. **Access**: Guest accesses resources
4. **Review**: Regular access reviews
5. **Deprovisioning**: Account disabled/deleted

#### Guest Account Properties
- **UserPrincipalName**: `user_externaldomain.com#EXT#@resourcetenant.onmicrosoft.com`
- **UserType**: Guest
- **Source**: External Azure AD
- **Created Date**: Redemption date

### Guest User Experience

#### Teams Experience
- "(Guest)" indicator in display name
- Limited app installation capability
- Cannot create teams (unless allowed)
- Cannot discover public teams
- Meeting experience may differ

#### SharePoint Experience
- "External" badge on user card
- Limited by sharing settings
- Cannot browse sites without direct link
- Search scoped to accessible content only

#### OneDrive/Outlook Experience
- External sharing indicators
- No automatic discovery
- Manual addition required

### Guest Limitations Summary

| Feature | Internal User | Guest User |
|---------|--------------|------------|
| Teams team creation | Yes | No (by default) |
| Browse directory | Yes | Limited |
| Search all sites | Yes | Accessible only |
| Power Automate flows | Full | Limited |
| Teams app install | Full | Restricted |
| Meeting recording | Full | May differ |
| Whiteboard | Full | Limited |
| Meeting lobby bypass | Configurable | Often in lobby |

## Cross-Tenant Synchronization (Preferred for Franchise)

### How It Differs from B2B

| Aspect | B2B Collaboration | Cross-Tenant Sync |
|--------|------------------|-------------------|
| Account Type | Guest | Member |
| User Experience | "External" badges | Native experience |
| Teams Features | Limited | Full |
| SharePoint Search | Limited | Full |
| License Requirement | Guest licenses | Member licenses |
| UPN Format | EXT suffix | Original UPN |
| Consent Prompt | Yes (first time) | No (with trust) |

### Cross-Tenant Sync Requirements

#### Technical Requirements
- Entra ID P1 license (both tenants)
- Configured cross-tenant access settings
- Automatic redemption enabled (both sides)
- Synchronization job configured

#### Limitations
- One-way sync only (source → target)
- Attribute filtering available
- Group sync available
- Password sync not applicable (federated)

## Sensitivity Labels Across Tenants

### Label Behavior

| Scenario | Behavior |
|----------|----------|
| Label applied in source tenant | Travels with content |
| Label policy in target tenant | May apply different enforcement |
| Encryption settings | Preserved across tenants |
| Content markings | Preserved across tenants |

### Cross-Tenant Label Considerations

1. **Label Consistency**
   - Same label names recommended
   - Different label policies possible
   - Export/import label configurations

2. **Encryption**
   - Protected content remains protected
   - Rights management applies across tenants
   - Key sharing required for access

3. **Auto-Labeling**
   - Evaluated in each tenant
   - Different rules may apply
   - Consistent policies recommended

## External Sharing Controls

### Organization-Level Settings

#### SharePoint External Sharing Options

| Setting | Description | Franchise Use Case |
|---------|-------------|-------------------|
| **Anyone** | Anonymous links | Not recommended |
| **New and existing guests** | Invited guests | Standard sharing |
| **Existing guests only** | Current directory guests | Restricted sharing |
| **Only people in your organization** | No external | Internal-only sites |

#### Per-Site External Sharing
- Can be more restrictive than tenant
- Cannot be less restrictive
- Site owners can control

### Domain Restrictions

#### Allow List
- Only specified domains allowed
- All others blocked
- Recommended: Franchise partner domains

#### Block List
- Specific domains blocked
- All others allowed
- Recommended: Consumer email domains

## Security Implications

### Conditional Access for Guests

#### Guest-Specific Policies
```
IF: UserType -eq "Guest"
THEN: Require MFA, Block High-Risk Locations
```

#### Franchise-Specific Policies
```
IF: User in "Franchise-Managers" group
AND: Location outside Trusted
THEN: Require Compliant Device
```

### Access Reviews

#### Automated Review Scenarios
- Quarterly franchisee access review
- Manager attestation for team access
- Automatic removal after inactivity

#### Review Types
- Self-attestation
- Manager review
- Owner review
- Group-based review

## Recommendations for Franchise Portals

### Preferred Architecture: Cross-Tenant Sync

**When Franchisees Have Their Own Tenants:**
1. Configure cross-tenant sync (member accounts)
2. Enable automatic redemption
3. Sync relevant groups
4. Apply conditional access
5. No "External" badges in Teams/SharePoint

**When Franchisees Don't Have Tenants:**
1. B2B collaboration (guest accounts)
2. Enable MFA for all guests
3. Regular access reviews
4. Accept "External" indicators

### Hybrid Scenarios

**Mixed Franchise Types:**
- Some franchisees: Synced members
- Other franchisees: B2B guests
- Third parties: B2B guests only
- Different policies per group

## Migration Considerations

### From B2B to Cross-Tenant Sync
1. Plan sync configuration
2. Configure cross-tenant access
3. Enable automatic redemption
4. Test with pilot users
5. Migrate groups
6. Remove B2B guests
7. Update documentation

### Timeline
- Configuration: 1-2 weeks
- Testing: 1-2 weeks
- Rollout: 2-4 weeks
- Total: 1-2 months
