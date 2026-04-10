# SharePoint Permissions and Hub Site Model

## Source: Microsoft Learn - Planning Hub Sites
**URL**: https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites
**Credibility**: Tier 1 - Official Microsoft Documentation
**Date Retrieved**: March 2025

## Hub Site Fundamentals

### Three Core Capabilities
1. **Shared navigation and brand** - Consistent navigation across associated sites
2. **Roll-up of content and search** - Aggregated content from all associated sites
3. **Home destination for the hub** - Central landing page for the hub

### Building Blocks for Intranet
- **Team sites** - Collaboration spaces
- **Communication sites** - Communication and publishing
- **Hub sites** - Connection and organization layer

## Hub Site Permissions Model

### Source: Microsoft Learn - Sharing & Permissions in Modern Experience
**URL**: https://learn.microsoft.com/en-us/sharepoint/modern-experience-sharing-permissions

### Permission Inheritance Behavior
- Hub sites do NOT enforce permissions on associated spoke sites
- Each spoke site maintains its own independent permission structure
- Hub site permissions control only:
  - Hub navigation configuration
  - Hub theme/branding
  - Who can associate sites with the hub

### Permission Management by Site Type

| Site Type | Permission Management Method |
|-----------|------------------------------|
| Group-connected team site | Microsoft 365 Group membership |
| Communication site | SharePoint groups (Owners/Members/Visitors) |
| Hub site | Depends on underlying site type |

### Hub Site Owner Responsibilities
- Define shared navigation and theme
- Control who can connect sites to the hub
- Cannot access content in spoke sites unless explicitly granted

### Spoke Site Autonomy
- Site owners control their own content
- Independent permission inheritance decisions
- Can break inheritance for document-level permissions
- Can have different external sharing settings

## Teams-Connected Sites Permissions

### Source: Microsoft Learn - Teams-Connected Sites
**URL**: https://learn.microsoft.com/en-us/sharepoint/teams-connected-sites

### Channel Types and Permission Behavior

| Channel Type | SharePoint Site | Site Sharing Behavior |
|--------------|-----------------|----------------------|
| **Standard** | One site shared by all channels | Team owners/members automatically included. Can share separately but Teams management recommended |
| **Private** | Each private channel has own site | Cannot be shared separately. Channel owners/members only |
| **Shared** | Each shared channel has own site | Cannot be shared separately. External participants in channel included |

### Permission Inheritance
- Standard channels: SharePoint folder within parent site
- Private/Shared channels: Separate SharePoint sites with isolated permissions

## External Sharing Integration

### Source: Microsoft Learn - Manage Sharing Settings
**URL**: https://learn.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off

### Two External Sharing Models

| Sharing Method | Files/Folders | Sites |
|---------------|---------------|-------|
| **SharePoint external auth** (B2B disabled) | No guest account created | N/A - B2B always used |
| **Entra B2B integration** (enabled) | Guest account created | Guest account created |

### Organization-Level Sharing Options

| Option | Description | Use Case |
|--------|-------------|----------|
| **Anyone** | Anonymous access links | Public sharing - NOT recommended for franchise |
| **New and existing guests** | Auth required, invites allowed | Standard B2B collaboration |
| **Existing guests** | Only current directory guests | Restricted external access |
| **Only people in your organization** | No external sharing | Internal-only content |

## Franchise Portal Implications

### Permission Architecture Recommendations

1. **Hub Site = Corporate Portal**
   - Navigation and branding consistency
   - Does not control spoke site access
   - Central news and announcements

2. **Spoke Sites = Franchise Locations**
   - Each franchise gets own site (or site collection)
   - Independent permission management
   - Can use M365 Groups for automatic membership

3. **Security Boundaries**
   - Document-level permissions for confidential materials
   - Sensitivity labels for content classification
   - Separate site collections for highest isolation

### Cross-Tenant Considerations
- Franchisees with external domains = B2B collaboration required
- Cross-tenant sync (member-type accounts) preferred over B2B guests
- Conditional Access policies apply to B2B guests
