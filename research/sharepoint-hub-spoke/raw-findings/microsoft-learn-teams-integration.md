# Raw Findings: Microsoft Learn - Teams and SharePoint Integration

**Source**: https://learn.microsoft.com/en-us/sharepoint/teams-connected-sites  
**Date Extracted**: April 2025

---

## Core Integration Concepts

### Basic Relationship
- Every Microsoft Team creates an underlying SharePoint site
- This is automatic and required for Teams file storage
- Site is used for all standard channel file storage

---

## Key Terminology

### Private Team
- Person can only join when invited by team owner
- Both public and private teams offer same channel types
- Channel types: standard, private, and shared

### Parent Site
- The SharePoint site created when you create the team
- Used for file storage for all standard channels
- All team owners and members have access

### Channel
- Location in team where you collaborate on specific things
- Team can have multiple channels for different purposes
- Three types: standard, private, shared

### Standard Channel
- All members of team have access
- Each team comes with standard channel called "General"
- Cannot be deleted (every team must have at least one channel)
- Always shows up first in channel list
- Team owners and members can add additional standard channels

### Private Channel
- Only some of the team's members have access
- Used for private conversations and collaboration
- **Each private channel has its own SharePoint site** for file storage
- Only members of the private channel can access this site
- Independent permissions from parent team

### Shared Channel
- You can add anyone, even if they're not a member of the team
- Used for broader collaboration
- Cross-team and cross-organization collaboration

---

## SharePoint Site Architecture per Teams Channel Type

| Channel Type | SharePoint Site Structure | Permissions |
|--------------|--------------------------|-------------|
| Standard | Shares parent team site | Inherited from team |
| Private | Separate SharePoint site | Independent, channel-specific |
| Shared | Separate SharePoint site | Custom, can include external |

---

## Hub Sites and Teams-Connected Sites

### Integration Points
- Teams-connected SharePoint sites CAN be associated with Hub sites
- Hub site navigation can include Teams-connected sites
- Hub site themes apply to Teams-connected sites when associated
- Search scope includes Teams-connected sites when part of hub

### Considerations for Multi-Brand
- Each brand's Teams will have underlying SharePoint sites
- These sites can be organized into brand-specific hub structures
- Private channels create additional sites that may need governance
- Shared channels require careful planning in multi-brand scenario

---

## File Storage Architecture

### Standard Channels
- Files stored in parent SharePoint site document library
- Folder structure organized by channel
- All team members can access (with appropriate permissions)

### Private Channels
- Separate SharePoint site created
- Only private channel members have access
- Site ownership managed separately from parent team
- Requires additional governance consideration

### Shared Channels
- Separate SharePoint site for file storage
- Custom membership model
- External users can be invited
- Information governance implications

---

## Permissions Model

### Teams Level
- Team owners: Full control
- Team members: Edit/contribute
- Team guests: Limited access (configurable)

### SharePoint Site Level
- Mirrors Teams permissions for standard channels
- Independent permissions for private channel sites
- Custom permissions for shared channel sites

### Hub Association Impact
- Hub association does NOT change underlying site permissions
- Hub navigation respects existing permissions (security trimming)
- Hub themes apply to all associated sites regardless of permissions

---

## Multi-Brand Franchise Implications

### Teams + SharePoint + Hub Sites Pattern
For each franchise brand:
1. Create Teams for brand operations
2. Teams automatically create SharePoint sites
3. Associate brand's Teams-connected sites with brand Hub
4. Brand Hub provides:
   - Shared navigation across all brand sites
   - Aggregated search for brand content
   - Brand-specific theme and look

### Shared Services Hub
- Corporate/shared Teams (HR, IT, Finance) connect to Shared Services Hub
- Brand teams can access shared services through hub navigation
- Permissions control what brand users can access

### Governance Considerations
- Private channels in brand teams create sites outside direct brand hub control
- Need governance plan for private channel creation
- Shared channels may need restrictions in multi-brand scenario
- Site ownership must be clearly defined

---

## Key Takeaways

1. **Teams and SharePoint are inseparable** - Every team has a SharePoint site
2. **Channel type determines site structure** - Standard shares site, private/shared get separate sites
3. **Hub sites work with Teams-connected sites** - Can include them in navigation and search
4. **Permissions remain independent** - Hub association doesn't change who can access what
5. **Private channels need special attention** - Create separate sites with independent permissions

---

*Extracted from Microsoft Learn - Teams and SharePoint integration*
*URL: https://learn.microsoft.com/en-us/sharepoint/teams-connected-sites*
