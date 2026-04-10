# SharePoint Hub Sites Planning - Microsoft Learn
**Source**: https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites  
**Date Accessed**: 2025-01-XX  
**Source Tier**: Tier 1 (Official Microsoft Documentation)  

## Key Concepts for Franchise/Hub-and-Spoke Architecture

### Hub Sites Purpose
Hub sites provide the "connective tissue" for organizing families of team sites and communication sites together. They're designed for modern intranets where each unit of work gets a separate site collection.

### Three Core Capabilities
1. **Shared navigation and brand** - Common navigation across associated sites
2. **Roll-up of content and search** - Aggregate content from all associated sites
3. **Home destination for the hub** - Central landing page

### Critical Principle: Links vs. Hierarchy
- Hub sites model relationships as **links rather than hierarchy or ownership**
- This allows dynamic adaptation to organizational changes
- Unlike subsites, if you reorganize business relationships, you don't break content URLs
- Sites can be re-associated to different hubs as business needs change

## Essential Elements of Successful Intranets

### Communication Elements
- Home page with news from around organization
- Overall navigation and links to key tools
- Internal marketing promotions
- Employee engagement areas

### Content Organization
- HR: Benefits, compensation, talent acquisition, performance management, training, manager portal
- Legal: Policies, agreements, compliance resources
- IT: Systems, support, training materials

### Key Capabilities
- **Actions/Activities**: Links to time-tracking, expense reports, approval workflows
- **Collaboration**: Teams workspaces, role-based communities
- **Culture**: Stories, profiles, communities, branding
- **Mobility**: Multi-device access critical for franchisees
- **Search**: Finding content without knowing location

## Hub vs. Team vs. Communication Sites

| Aspect | Team Site | Communication Site | Hub Site |
|--------|-----------|-------------------|----------|
| **Primary Objective** | Collaborate | Communicate | Connect |
| **Content Authors** | All members | Small author, large reader | Hub owner defines shared experience |
| **Governance** | Team norms | Organizational policies | Determined by each associated site |
| **Permissions** | M365 group + SP groups | SharePoint groups | Same as original site type |
| **Created By** | Site owner or admin | Site owner | SP administrators and above |

## Key Considerations for Multi-Location Organizations

### Association Strategy
- **One site = One unit of work** principle
- Sites inherit hub theme and shared navigation
- Content rolls up to hub (hub-to-spoke: theme/navigation, Spoke-to-hub: content)
- Search scope limited to associated sites
- Permissions remain independent unless explicitly shared

### Navigation Best Practices
- Hub navigation appears below suite bar (top of page)
- Up to **3 levels** of navigation depth
- **Maximum 100 links** recommended (technical limit ~500)
- Consider audience targeting for private/restricted sites
- Can include non-associated sites via links

### Content Roll-up Limits
- **Sites web part**: Max 99 sites for "all sites in hub" filter
- **Search scope**: ~2,000 sites technically possible, but performance considerations apply
- News flows UP from associated sites to hub, not down

## Franchise-Specific Insights

### Regional vs. Functional Organization
Microsoft describes a classic challenge: "Do we make the Southeast Sales site a subsite of the Southeast Region site or the Global Sales site?"

**Hub solution**: Sites can be associated based on primary workflow:
- Associate Austria Sales with Austria hub for local operations
- Add link to Global Sales hub in navigation
- Hubs can be associated to other hubs (up to 3 levels)

### Multi-Geo Considerations
- Hub sites support multi-geo capabilities
- Associate location-specific sites with regional hubs
- Use hub-to-hub associations for cross-regional roll-up
- Example: Northeast Region Sales hub → Global Sales hub

## Practical Guidelines

### Hub Quantity
- Organizations can have up to **2,000 hub sites**
- Don't create hubs just for theme consistency
- Focus on business outcomes and user needs

### Navigation Design
- Start with key functions: HR, Finance, Communications, Legal, IT
- Consider hub naming conventions (e.g., "HR Central", "Operations Hub")
- Add hubs to global navigation in SharePoint app bar
- Pin key hubs to SharePoint start page Featured links

### Security and Permissions
- Association doesn't change site permissions
- Content is security trimmed in roll-ups
- Consider adding "reader" group to hub for easy access distribution
- Private sites: Consider marking as "(restricted)" in navigation

## News and Content Strategy
- News rolls UP from associated sites to hub
- For broadest reach, publish to hub home
- Consider dual news web parts: hub-published + associated site roll-up
- Hub news doesn't flow down to associated sites

## Migration from Classic (Subsite) Model
- Hub sites solve most use cases previously requiring subsites
- Subsites remain supported but hub architecture preferred
- New team site template available as subsite option for legacy needs

## Key Success Factors
1. **Start with user outcomes** - What do they need to accomplish?
2. **Plan navigation structure** before creating hubs
3. **Consider governance** at both hub and associated site levels
4. **Design for change** - Organizational structure will evolve
5. **Balance standardization vs. flexibility** - Consistent where needed, adaptable where valuable
