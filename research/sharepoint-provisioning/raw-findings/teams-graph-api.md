# Microsoft Teams Provisioning via Microsoft Graph API

Source: https://learn.microsoft.com/en-us/graph/teams-create-group-and-team
API Reference: https://learn.microsoft.com/en-us/graph/api/team-post

## Overview

Microsoft Graph API allows programmatic creation of Teams, channels, and integration with SharePoint sites.

## Key Concept: Teams are M365 Groups

All teams are backed by Microsoft 365 groups. The recommended approach is:
1. Create a Microsoft 365 Group
2. Add members/owners
3. Create a team from the group
4. Add channels
5. Link to SharePoint (automatic - each team gets a SharePoint site)

## Required Permissions

### For Creating Teams via Graph API:

| Permission Type | Least Privileged | Higher Privileged |
|----------------|------------------|-------------------|
| **Delegated (work/school account)** | Team.Create | Group.ReadWrite.All |
| **Application** | Team.Create | Group.ReadWrite.All |

**Note**: Group.ReadWrite.All and Directory.ReadWrite.All are supported only for backward compatibility. Microsoft recommends using Team.Create instead.

### Permission Details:

**Team.Create** (Recommended):
- Allows creating teams
- Creating team will create a group automatically
- Does not require Group.ReadWrite.All

**Group.ReadWrite.All** (Legacy):
- Full access to all groups
- Can read/write all group properties
- Overly permissive for team creation only

## API Endpoints

### Create a Team
```
POST https://graph.microsoft.com/v1.0/teams
```

### Create a Channel
```
POST https://graph.microsoft.com/v1.0/teams/{team-id}/channels
```

### List Teams
```
GET https://graph.microsoft.com/v1.0/me/joinedTeams
```

### Get Team's Associated Site (SharePoint)
```
GET https://graph.microsoft.com/v1.0/groups/{group-id}/sites/root
```

## JSON Schema for Team Creation

```json
{
  "template@odata.bind": "https://graph.microsoft.com/v1.0/teamsTemplates('standard')",
  "displayName": "Team Name",
  "description": "Team Description",
  "members": [
    {
      "@odata.type": "#microsoft.graph.aadUserConversationMember",
      "roles": ["owner"],
      "user@odata.bind": "https://graph.microsoft.com/v1.0/users('user-id')"
    }
  ]
}
```

## Channel Types

1. **Standard** - Regular conversation channel
2. **Private** - Invite-only channel within team
3. **Shared** - Shared with other teams (cross-tenant)

## Teams Templates

Microsoft provides built-in templates:
- `standard` - Default team template
- `educationClass` - Class team
- `educationStaff` - Staff team
- `educationProfessionalLearningCommunity` - PLC team

Custom templates can be created via Graph API for organizational standards.

## Batch Creation Recommendations

### Rate Limiting Considerations:
- Graph API has throttling limits
- Implement retry logic with exponential backoff
- Batch operations should include delays between requests

### Best Practices for Multi-Brand Deployment:

1. **Create Groups First** - Batch create M365 groups
2. **Add Members** - Assign owners and members to groups
3. **Create Teams** - Convert groups to teams (or create teams directly)
4. **Create Channels** - Add standard channels per team
5. **Apply Templates** - Use PnP Framework for SharePoint site customization

### PowerShell/PnP Approach:
```powershell
# Connect to Microsoft Graph
Connect-PnPOnline -ClientId $clientId -ClientSecret $clientSecret -Url $tenantUrl

# Create group
$group = New-PnPMicrosoft365Group -DisplayName "Brand A Team" -Description "Team for Brand A"

# Add team to group
New-PnPTeam -GroupId $group.Id
```

## Linking Teams to SharePoint Sites

**Automatic**: Each team gets:
- Default General channel → SharePoint folder
- Files tab → SharePoint document library
- Wiki tab → SharePoint pages

**Access the SharePoint Site**:
```
GET /groups/{group-id}/sites/root
```

Returns:
- SharePoint site URL
- Document library location
- Lists and content associated

## Monitoring and Error Handling

- Teams creation is asynchronous
- Use webhook notifications or polling to check status
- Handle permission errors (insufficient privileges)
- Monitor for throttling (429 responses)

## Compliance Considerations

- Teams inherit M365 group membership
- Retention policies apply to channel messages
- eDiscovery includes Teams content
- Information barriers can restrict communication
