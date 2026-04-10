# Microsoft Teams Private Channels - Raw Documentation

## Source Information
- **Source**: Microsoft Learn - Official Teams Documentation
- **URL**: https://learn.microsoft.com/en-us/microsoftteams/private-channels
- **Last Updated**: 10/28/2025
- **Source Tier**: Tier 1 (Official Microsoft Documentation)

---

## Private Channels Overview

Private channels in Microsoft Teams create focused spaces for collaboration within your teams. Only the users on the team who are owners or members of the private channel can access the channel.

### Key Characteristics

- **Scoped Access**: Only members of the private channel can see and participate
- **Lock Icon**: Indicates a private channel in the Teams interface
- **Parent Team Link**: Created within a parent team
- **No Conversion**: Cannot be converted to standard channels and vice versa

### Use Cases for Franchise Portals

Private channels are useful for:

1. **Franchisor-Franchisee Confidential Communications**
   - Private discussions between franchisor and individual franchisee
   - Financial or legal discussions
   - Performance improvement plans

2. **Regional Franchise Management**
   - Regional managers coordinating with specific franchise locations
   - Area development discussions
   - Regional marketing campaigns

3. **Franchise Advisory Councils**
   - Elected franchisee representatives communicating with franchisor
   - Strategic planning discussions
   - Confidential franchisee feedback

4. **Project-Based Collaboration**
   - New franchise location development
   - System-wide rollouts to specific pilot locations
   - Confidential vendor negotiations

---

## Creation and Management

### Creation Permissions

**Default Settings:**
- Any team owner or team member can create a private channel
- Guests CANNOT create private channels
- Creation can be managed at team level and organization level

**Policy Controls:**
- Admin policies control which users can create private channels
- Team owners can turn off/on member creation in Settings tab
- Recommended: Restrict private channel creation for franchise portals to maintain governance

### Owner and Member Management

**Private Channel Creator:**
- Becomes the private channel owner
- Only private channel owner can directly add or remove people
- Can add any team member including guests

**Member Experience:**
- New members can see all conversations (even old ones) when added
- Secure conversation space
- Cannot see channel if not a member

**Team Owner Access:**
- Team owners who aren't members can see channel under "Manage team" but not in channels list
- Team owners can delete private channel whether or not they're a member

**Automatic Promotion:**
- If private channel owner leaves organization or is removed from Microsoft 365 group, a member is automatically promoted to owner

---

## Private Channel SharePoint Sites

### Site Architecture

- Each private channel has its own **separate SharePoint site**
- Ensures access to private channel files is restricted to only members
- Sites can be enhanced to full-featured sites through site management

**Site Template IDs:**
- "TEAMCHANNEL#0" or "TEAMCHANNEL#1" for PowerShell/Graph API management
- Created in same geographic region as parent team site

**2025 Update:**
- Starting late October 2025: Migration to new infrastructure
- B2B collaboration users with UserType member may temporarily be unable to create private channels (through mid-November 2025)
- **Newly created private channels**: Document library not created by default; root folder used as default location

### Site Permissions

- Only people with owner or member permissions in the channel have access to the channel site
- People in parent team and admins don't have access unless also channel members
- Site permissions cannot be managed independently through SharePoint
- Teams manages lifecycle of private channel site

**Sync Behavior:**
- Data classification syncs from parent team
- Guest access permissions inherited from parent team
- Membership syncs with private channel within Teams

**Site Recovery:**
- If site deleted outside Teams: Background job restores within 4 hours (if channel still active)
- If private channel or team restored: Sites restored with it
- If site restored beyond 30-day soft delete: Operates as standalone site

---

## Retention and Compliance

### Retention Policies

- Retention policies can be applied to private channel sites
- Compliance copies of messages delivered to group mailbox (not individual member mailboxes)
- Message titles formatted to indicate which private channel they came from

### eDiscovery

- Full eDiscovery support for private channel messages
- See "eDiscovery of private channels" for detailed procedures

### Compliance Copies

- Messages sent in private channel copied to group mailbox
- Titles indicate originating private channel
- Enables compliance and legal hold scenarios

---

## Private Channel Limitations

### Feature Limitations

**Unsupported Features:**
- Connectors
- Tabs in Stream
- Tabs in Planner
- Tasks by Planner and To Do tabs
- Forms tabs
- Channel meetings
- Channel calendars

**Scale Limitations:**
- Maximum 30 private channels per team (included in 1000 total channel limit)
- Maximum 250 members per private channel
- Private channels don't copy when creating team from existing team

**Notification Limitations:**
- Notifications from private channels NOT included in missed activity emails

**Conversion Limitations:**
- Cannot convert private channel to standard channel
- Cannot convert standard channel to private channel
- Cannot move private channel to different team

---

## File Access Considerations

### File Sharing

- Works same as other SharePoint sites
- Sharable links based on SharePoint Administrator sharing settings
- Standard SharePoint sharing controls apply

### OneNote Considerations

- Sharing OneNote notebooks same as sharing any other item
- Granting access through SharePoint doesn't remove access when user removed from team/channel
- Existing notebooks added as tabs retain existing permissions

### Special Considerations

**For Franchise Portals:**
- Private channel files are truly private to channel members
- Good for confidential franchisee-franchisor documents
- Not suitable for resources that should be broadly shared
- Consider regular channels for franchise resource sharing

---

## Architecture for Franchise Portals

### Recommended Structure

```
Franchise Teams Team
├── General Channel (All franchisees)
│   └── Public announcements, resources
├── Operations Channel
│   └── Daily operations discussions
├── Marketing Channel
│   └── Marketing campaigns and materials
├── CONF-Franchisee001 (Private Channel)
│   └── Confidential: Franchisee 001 specific
├── CONF-Franchisee002 (Private Channel)
│   └── Confidential: Franchisee 002 specific
└── Advisory Council (Private Channel)
    └── Franchisee representatives
```

### Governance Recommendations

**Creation Policies:**
- Restrict private channel creation to team owners
- Require naming conventions (e.g., "CONF-FranchiseeName")
- Document purpose and owner for each private channel

**Membership Management:**
- Review private channel membership quarterly
- Ensure franchisee access removed when franchise agreement ends
- Maintain audit log of private channel access

**Compliance:**
- Apply retention policies appropriate to content type
- Enable eDiscovery for legal/compliance scenarios
- Regular compliance review of private channel content

---

## Integration with Microsoft 365 Groups

### Group Membership Impact

**When Users Leave:**
- User removed from team: Removed from all private channels
- User added back to team: Must be re-added to private channels

**When Users Are Added:**
- Must be explicitly added to private channels by channel owner
- Not automatically granted access to all private channels

**Guest Access:**
- Guests can be added to private channels
- Must already be members of the team
- Subject to team-level guest access policies

---

## Best Practices for Franchise Portals

### When to Use Private Channels

**DO Use Private Channels For:**
- Confidential franchisor-franchisee discussions
- Financial negotiations or reviews
- Performance improvement discussions
- Legal matters
- Strategic planning with select franchisees
- Sensitive vendor negotiations

**DON'T Use Private Channels For:**
- Resources that should be shared with all franchisees
- General franchise community discussions
- Marketing materials distribution
- Training content that all franchisees need
- Operational procedures and standards

### Alternative Approaches

**For Broad Distribution:**
- Use standard channels with audience-targeted content
- SharePoint site permissions for sensitive documents
- Private SharePoint document libraries within standard team sites

**For One-to-One:**
- Direct Teams chats for brief confidential conversations
- Email for formal confidential communications
- SharePoint with unique permissions for document sharing

---

## Migration and Modernization

### October 2025 Changes

**Infrastructure Migration:**
- Starting late October 2025: Private channels migrate to new infrastructure
- Temporary limitation: B2B collaboration users may be unable to create or own private channels (through mid-November 2025)
- End of 2025: Move to group compliance

**New Behavior:**
- Newly created private channels: No document library by default
- Root folder used as default file location
- Streamlined compliance management

### PowerShell Commands

```powershell
# Check migration status
Get-TenantPrivateChannelMigrationStatus

# Manage private channel sites
Get-SPOSite -Template "TEAMCHANNEL#0"
Get-SPOSite -Template "TEAMCHANNEL#1"
```

---

## Key Takeaways for Franchise Portals

1. **True Privacy**: Private channels offer genuine isolation for confidential franchise communications
2. **Separate SharePoint Sites**: Each private channel has its own site for file isolation
3. **Limited Scale**: Max 30 private channels per team, 250 members per channel
4. **Owner-Controlled**: Only channel owner can add/remove members
5. **No Automatic Access**: Team owners don't automatically have access
6. **Feature Gaps**: Some Teams features not available in private channels
7. **Governance Critical**: Need clear policies for creation and management
8. **Not for Everything**: Use judiciously - most franchise content should be in standard channels
