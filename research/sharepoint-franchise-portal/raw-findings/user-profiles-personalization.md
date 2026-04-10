# User Profile Properties and Personalization in SharePoint

## Source: Microsoft Learn - User Profile Sync
**URL**: https://learn.microsoft.com/en-us/sharepoint/user-profile-sync
**Credibility**: Tier 1 - Official Microsoft Documentation
**Date Retrieved**: March 2025

## SharePoint User Profile Service

### Sync Process
- Microsoft Entra ID attributes sync to SharePoint User Profile Application (UPA)
- Automatic synchronization for new users
- Synchronization times vary based on workloads
- Profile properties synced by UPA process are NOT configurable

## Entra ID Attributes Synced to SharePoint

| Entra ID Attribute | SharePoint Profile Property | Syncs to Sites | Use Case |
|-------------------|---------------------------|----------------|----------|
| **UserPrincipalName** | Account Name, User Name, User Principal Name | Yes | Identity, login |
| **DisplayName** | Name | Yes | User display |
| **GivenName** | FirstName | Yes | Profile info |
| **sn** (Surname) | LastName | Yes | Profile info |
| **telephoneNumber** | Work phone | Yes | Contact info |
| **proxyAddresses** | Work Email, SIP Address | Yes | Email, Teams |
| **PhysicalDeliveryOfficeName** | Office | Yes | Location-based |
| **Title** | Title, Job Title | Yes | Role-based |
| **Department** | Department | Yes | Org structure |
| **PreferredLanguage** | Language Preferences | Yes | Localization |
| **Manager** | Manager | Yes | Org hierarchy |
| **WWWHomePage** | Public site redirect | No | External links |
| **msExchHideFromAddressList** | SPS-HideFromAddressLists | No | Directory visibility |

## Dynamic Group Membership for Audience Targeting

## Source: Microsoft Learn - Dynamic Membership Groups
**URL**: https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership
**Credibility**: Tier 1 - Official Microsoft Documentation
**Date Retrieved**: March 2025

### License Requirements
- Microsoft Entra ID P1 or Intune for Education required
- One license per unique user member of any dynamic group
- Device members do not require licenses

### Dynamic Membership Rules

#### Rule Structure
```
<Property> <Operator> <Value>
```

#### Supported Properties for Users

**String Properties** (Location & Role-Based):
- `city` - City attribute
- `country` - Country/region
- `companyName` - Company/organization
- `department` - Department
- `jobTitle` - Job title
- `physicalDeliveryOfficeName` - Office location
- `postalCode` - ZIP/postal code
- `state` - State/province
- `streetAddress` - Street address

**String Properties** (Identity-Based):
- `displayName` - Display name
- `employeeId` - Employee ID
- `givenName` - First name
- `mail` - Email address
- `mailNickName` - Email alias
- `userPrincipalName` - UPN

**Collection Properties**:
- `memberOf` - Group membership
- `proxyAddresses` - Email aliases

**Boolean Properties**:
- `accountEnabled` - Account status
- `dirSyncEnabled` - Sync status

**Date/Time Properties**:
- `employeeHireDate` - Hire date

### Franchise-Specific Dynamic Group Examples

#### Location-Based Groups
```
# All users in California franchise locations
user.state -eq "CA" -and user.department -startsWith "Franchise"

# Specific franchise office
user.physicalDeliveryOfficeName -eq "Phoenix - Downtown"
```

#### Role-Based Groups
```
# Franchise managers
user.jobTitle -contains "Franchise Manager"

# Operations team
user.department -eq "Franchise Operations"

# Regional directors
user.jobTitle -match "Regional.*Director"
```

#### Hybrid Groups
```
# California franchise managers
user.state -eq "CA" -and user.jobTitle -contains "Franchise Manager"

# New hires in franchise division
user.department -eq "Franchise" -and user.employeeHireDate -gt "2024-01-01"
```

## Microsoft 365 Groups for Audience Targeting

### Group Types

| Group Type | Membership Management | Use Case |
|-----------|---------------------|----------|
| **Assigned** | Manual add/remove | Small, static groups |
| **Dynamic User** | Rule-based (user attributes) | Location, role, dept |
| **Dynamic Device** | Rule-based (device attributes) | Device management |

### Group Settings for Franchise Scenarios

#### Privacy Settings
- **Public**: Anyone can join, view membership
- **Private**: Owner-managed membership
- **Recommended**: Private for franchise groups

#### Guest Access
- Allow external members
- Block external members
- Recommended: Allow for B2B collaboration

## Audience Targeting in SharePoint

### Current Capabilities (2025)

#### Navigation Targeting
- Target hub navigation to specific groups
- Show/hide navigation items based on audience
- Group-based visibility control

#### Content Targeting
- Page/section visibility to groups
- Web part targeting
- News post targeting

#### Search Personalization
- Personalized search results based on group membership
- Promoted results for specific audiences
- Content suggestions based on profile

### Requirements for Audience Targeting

1. **Microsoft 365 Groups** or **Security Groups**
   - Targeting requires group membership
   - Dynamic groups update automatically
   - Maximum audience size limits apply

2. **User Profile Sync**
   - Properties must be synced to SharePoint
   - May take 24-48 hours for new attributes

3. **Permissions**
   - Site Owner or Site Collection Admin
   - Groups must be available in tenant

## Franchise Portal Personalization Strategy

### Tier 1: Corporate (All Users)
- Navigation: Company news, policies, benefits
- Content: Corporate announcements, HR updates
- Target: All employees (Tenant-wide)

### Tier 2: Franchise Network (Franchise Users)
- Navigation: Operations, training, support
- Content: Franchise-specific procedures
- Target: Franchise department M365 Group

### Tier 3: Regional (Location-Based)
- Navigation: Regional events, local contacts
- Content: Location-specific information
- Target: Dynamic group based on state/city

### Tier 4: Role-Based (Manager/Staff)
- Navigation: Management tools, reports
- Content: Leadership resources, confidential docs
- Target: Job title dynamic groups

### Tier 5: Individual (Personalized)
- Navigation: My team, my tasks, my training
- Content: Based on manager relationship
- Target: Individual user targeting

## Technical Implementation Notes

### Custom Profile Properties
- Bulk update API available for custom properties
- Connectors for external HR systems
- Power Automate integration for updates

### Synchronization Timing
- Initial sync: Up to 24 hours
- Attribute changes: 24-48 hours
- Group membership changes: Near real-time (dynamic groups)

### Limitations
- Maximum 10 audience targets per navigation item
- Dynamic group evaluation can take time
- Some properties not syncable to SharePoint

## Security Considerations

### Attribute Write Permissions
- Review who can modify attributes used in rules
- On-premises AD self-write permissions
- Cloud attribute modification rights

### Access Control
- Dynamic groups for access control = higher security requirement
- Audit attribute changes
- Monitor group membership changes

### Role-Assignable Groups
- Cannot be dynamic (security feature)
- Used for privileged access management
- Separate from franchise targeting groups
