# Raw Findings: Microsoft Learn - Planning Your SharePoint Hub Sites

**Source**: https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites  
**Date Extracted**: April 2025  
**Author**: Susan Hanley, MVP  

---

## Core Hub Site Concepts

### Three Things Hub Sites Give You
1. **Shared navigation and brand**
2. **Aggregated search**
3. **News and activity rollups**

### Three Types of Building Blocks
All three site types (Team site, Communication site, Hub site) share:
- Same set of internal web parts
- Common structure

Differences exist in:
- Intent
- Usage expectations
- Governance (including how they are created)
- Which web parts to use

Building blocks visual:
- Theme and logo
- Search scope
- News and activity rollup

---

## Site Type Comparison Table

| Aspect | Team Site | Communication Site | Hub Site |
|--------|-----------|-------------------|----------|
| **Primary Business Objective** | Collaborate - Create place where work group/project team can work together on deliverables, plan events, track status, exchange ideas | Communicate - Broadcast message, tell story, share content for viewing (not editing), showcase services or people | Connect - Create shared experience for family of related sites to discover related content by rolling up site activity and news |
| **Permissions** | Microsoft 365 group, plus SharePoint groups and permission levels | SharePoint group | Same as original site type. Hub sites do not alter an associated site's permissions - but you may add a "reader" group to the hub to make it easier to provide read access to associated sites |
| **Created by** | Site owner (unless disabled) or admin | Site owner (unless disabled) | SharePoint site administrators and above in Microsoft 365 |
| **Examples** | Project team working together, team working on deliverables | Travel team publishing guidelines, corporate communications | HR hub providing connection and rollup for HR family of sites |

---

## Hub Site Search and Discovery

### Three "Find" Scenarios Hub Sites Enable:
1. "I know it exists, and I know where it is"
2. "I know it exists, but I don't know where it is"
3. "I don't know if it exists"

### Serendipitous Discovery
Hub sites surface contextually relevant content from sites users may not follow but are associated with the hub.

Example: Reading news about open enrollment on HR hub may surface "Welcome to the Company" onboarding toolkit from Talent Acquisition site.

---

## Hub Site Limits and Recommendations

### Maximum Limits
- **Hub sites per organization**: Up to 2,000 hub sites
- **Sites per hub (search scope)**: Approximately 2,000 sites
  - Technically no hard limit from search perspective
  - Performance issues may occur with large numbers
  - Consider if primary purpose is searching across related files

### Navigation Limits
- **Navigation depth**: Up to three levels
- **Technical maximum navigation nodes**: 500
- **Practical/recommended maximum**: 100 links
- **Sites web part limit**: 99 sites maximum

### Document Libraries
- Within each library: up to 30 million files and folders
- 2,000 lists and libraries in a site collection

---

## Association Mechanics

### How Association Works
- A site becomes part of a hub family by "Associating a SharePoint site with a hub site"
- SharePoint Administrators can allow only certain site owners to associate sites with the hub
- When associated, site inherits:
  - Hub site theme
  - Shared navigation
- Content rolls up to hub site in web parts where source is "all sites in the hub"
- Site is included in hub site search scope

### Multi-Hub Association
- An individual site can be associated with only ONE hub
- Content from a site can appear on multiple hubs through web part customization
- Sources that can be customized for hub web parts:
  - News
  - Highlighted content
  - Sites
  - Events

---

## Hub Site Navigation

### Navigation Characteristics
- Hub site owner determines which sites are reflected in shared navigation
- Can include links to other resources
- Appears at top, below suite bar
- Default style for team sites hub navigation: cascading

### Navigation Planning Considerations

**Should you add private/restricted access sites to navigation?**
- Maybe - depends on goals
- Example: HR may want to associate private team site for convenience to HR hub
- But HR hub owner may not want to display link in shared navigation because it makes private site more discoverable
- Consider using audience targeting so link only appears for private site members

**Hub-to-Hub Navigation Implications**
If HR hub is associated with Regional hub:
- Navigating from Regional hub to HR hub: see HR navigation and theme
- Within HR hub: see HR-specific navigation
- Content rolls up from regional HR sites to HR hub (not to Regional hub)
- This creates nested navigation experiences to be aware of

---

## One Hub vs Multiple Hubs

### Single Hub Approach
**Advantages**:
- Every site in intranet shares consistent top navigation

**Disadvantages**:
- Lose ability to easily surface related information in context
- Lose ability to easily define search scope for related content

### Multiple Hubs Approach
Better when:
- Need distinct context for different parts of organization
- Want to create experiences for specific user groups
- Need different navigation structures for different functions

---

## Practical Guidance Table

| Key Benefit/Outcome Goal | Practical Guidance |
|-------------------------|-------------------|
| Share common theme across all sites | Don't establish hub ONLY for theme sharing - use theming PowerShell cmdlets instead |
| Display links to all sites in hub in site navigation | Technically no more than 500, practically no more than 100. Technical limit to navigation nodes exists. Recommended number of links: 100 maximum |
| Display security trimmed, dynamic list of all sites without code | No more than 99. Sites web part can filter for "all sites in the hub" up to maximum 99 sites |
| Shared search scope for all sites in hub | Approximately 2,000. Technically no hard limit but performance issues possible with large numbers |

---

## Additional Important Considerations

### Making Hubs Discoverable
- Add hubs to global navigation (SharePoint app bar)
- Add key hubs to SharePoint start page (pin to Featured links)
- Encourage users to "follow" hub sites

### News Distribution
- News doesn't flow DOWN to associated sites
- News only rolls UP from associated site to hub
- For broadest news reach, publish to hub site
- Consider two news web parts on home page: one for hub home news, one including associated sites

### Home Site Considerations
- Consider leaving home site as "regular" site if planning multiple hubs
- Users can leverage SharePoint app bar for global navigation
- Not every site needs to be connected to hub
- Some sites may have both local and hub navigation; others only local

---

## Tips and Best Practices

1. **Don't associate extranet sites with hub** if you don't want extranet users to see shared navigation. Instead, add external sites to hub navigation so internal users have quick access.

2. **Start with consistent approach** for all functions that have a pattern (e.g., align region-specific functions to regional hub consistently)

3. **Plan before creating hubs** - you might not need a hub site for every function

4. **Think about user outcomes first** - align hub to create experiences that enable the user

5. **Content organization** - 2,000 lists/libraries per site collection, 30 million files/folders per library

---

## Author Information

**Principal Author**: Susan Hanley, MVP  
- LinkedIn: http://www.linkedin.com/in/susanhanley
- Website: www.susanhanley.com

---

*Extracted from Microsoft Learn - Planning your SharePoint hub sites*
*URL: https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites*
