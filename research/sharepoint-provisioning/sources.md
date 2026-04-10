# Source Credibility Assessment

## Tier 1 (Highest Authority) - Official Microsoft Documentation

### 1. Microsoft Learn - SharePoint Limits
- **URL**: https://learn.microsoft.com/en-us/office365/servicedescriptions/sharepoint-online-service-description/sharepoint-online-limits
- **Last Updated**: 11/06/2025
- **Authority**: Official Microsoft service description
- **Currency**: Current (2025)
- **Content**: Service limits including hub sites (2,000 max), managed metadata limits
- **Reliability**: Highest - Official source for service limits

### 2. Microsoft Learn - Planning Hub Sites
- **URL**: https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites
- **Authority**: Official Microsoft documentation
- **Currency**: Current
- **Content**: Hub site planning, architecture recommendations
- **Reliability**: Highest

### 3. Microsoft Learn - Site Design JSON Schema
- **URL**: https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-json-schema
- **Authority**: Official developer documentation
- **Currency**: Current
- **Content**: Site script actions, JSON schema reference
- **Reliability**: Highest

### 4. Microsoft Learn - Information Barriers
- **URL**: https://learn.microsoft.com/en-us/purview/information-barriers
- **Authority**: Official Microsoft Purview documentation
- **Currency**: Current
- **Content**: IB policies, configuration, use cases
- **Reliability**: Highest

### 5. Microsoft Learn - Microsoft Graph Teams API
- **URL**: https://learn.microsoft.com/en-us/graph/teams-create-group-and-team
- **Authority**: Official Microsoft Graph documentation
- **Currency**: Current
- **Content**: Teams creation, permissions, best practices
- **Reliability**: Highest

### 6. Microsoft Learn - Managed Metadata
- **URL**: https://learn.microsoft.com/en-us/sharepoint/managed-metadata
- **Authority**: Official SharePoint documentation
- **Currency**: Current
- **Content**: Term store, taxonomy management
- **Reliability**: Highest

## Tier 2 (High Authority) - Official PnP/Community Resources

### 7. PnP Framework GitHub Repository
- **URL**: https://github.com/pnp/pnpframework
- **Authority**: Official PnP community repository (Microsoft-affiliated)
- **Currency**: Last commit 2 weeks ago, version 1.18.0 (April 2025)
- **Content**: Current version, migration status, capabilities
- **Reliability**: High - Microsoft-backed community project

### 8. PnP Framework Documentation Site
- **URL**: https://pnp.github.io/pnpframework/
- **Authority**: Official PnP documentation
- **Currency**: Synchronized with GitHub releases
- **Content**: Framework overview, versioning, getting started
- **Reliability**: High

## Source Evaluation Summary

| Source | Tier | Bias | Primary Value |
|--------|------|------|---------------|
| Microsoft Learn (Limits) | 1 | None | Official service limits |
| Microsoft Learn (Hub Sites) | 1 | None | Architecture guidance |
| Microsoft Learn (Site Designs) | 1 | None | JSON schema reference |
| Microsoft Learn (Information Barriers) | 1 | None | Compliance features |
| Microsoft Learn (Graph API) | 1 | None | API permissions |
| Microsoft Learn (Managed Metadata) | 1 | None | Taxonomy limits |
| PnP Framework GitHub | 2 | Promotes PnP | Current version, capabilities |
| PnP Framework Docs | 2 | Promotes PnP | Framework overview |

## Cross-Reference Validation

### Hub Site Limits Validation
- **Source 1**: Microsoft Learn - 2,000 hub sites max
- **Validation**: Consistent across all Microsoft documentation
- **Conclusion**: Reliable, current limit

### PnP Framework Status
- **Source**: GitHub repository README
- **Validation**: Active development (2 weeks ago), releases current
- **Conclusion**: Actively maintained, successor to PnP Sites Core

### Teams Graph API Permissions
- **Source**: Microsoft Graph documentation
- **Validation**: Team.Create recommended over Group.ReadWrite.All
- **Conclusion**: Current best practices documented

## Outdated/Deprecated Information Flagged

### PnP Sites Core
- **Status**: RETIRED (per PnP Framework documentation)
- **Replacement**: PnP Framework
- **Action**: Do not use for new projects

### Group.ReadWrite.All Permission
- **Status**: Legacy compatibility only
- **Replacement**: Team.Create (for Teams) or more specific permissions
- **Action**: Use least-privilege permissions

## Information Gaps

The following were not found in official documentation and would require additional research:

1. **Exact hub site association limits** - No explicit limit documented beyond general site limits
2. **PnP Framework specific limits** - No documented limits found
3. **Site script performance guidance** - No official performance metrics documented
4. **Teams + SharePoint provisioning timing** - No explicit timing documentation

## Confidence Assessment

| Finding | Confidence | Basis |
|---------|------------|-------|
| 2,000 hub site limit | **Very High** | Official Microsoft documentation |
| PnP Framework v1.18.0 | **Very High** | GitHub release page, dated |
| Team.Create permission | **Very High** | Official Graph API docs |
| IB overkill for franchise | **High** | Documentation analysis + architecture best practices |
| Taxonomy recommendations | **High** | Official limits + best practice synthesis |

## Overall Source Quality

**Grade: A** (Excellent)

- All Tier 1 sources are official Microsoft documentation
- Tier 2 sources are official community projects (PnP)
- No reliance on third-party blogs or outdated sources
- All sources checked for current status
- Cross-referenced where possible
