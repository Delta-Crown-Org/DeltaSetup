# SharePoint Hub Sites - Raw Documentation

## Source Information
- **Source**: Microsoft Learn - Official SharePoint Documentation
- **URLs**: 
  - https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites
  - https://learn.microsoft.com/en-us/sharepoint/create-hub-site
- **Last Updated**: 01/13/2025 and 05/29/2025
- **Source Tier**: Tier 1 (Official Microsoft Documentation)

---

## Hub Sites Overview

SharePoint hub sites provide an important building block for your intranet. They're the "connective tissue" you use when organizing families of team sites and communication sites together.

### Key Principles

One of the key principles of modern intranets based on Microsoft SharePoint is that **each unit of work should get a separate site collection**. This helps you to manage governance and growth over time. Each communication site and Microsoft 365 group-connected team site is created as a site collection that can have its own permissions.

A hub site (most commonly created from a communication site) should also be considered its own unit of work that brings together many other sites.

### Hub Sites vs. Subsites

In the past, many organizations used subsites to create connective tissue for their intranets. However, subsites don't give any room for flexibility and change:

- Subsites are a physical construct reflected in the URL for content
- If you reorganize your business relationships, you break all the intranet relationships in your content
- Subsites create challenges with governance because many features (retention and classification) apply to all sites within the site collection
- You must frequently enable a feature for the entire site collection, even if it's only applicable to one subsite

**Key Benefit**: Hub sites model relationships as links, rather than hierarchy or ownership, so that you can adapt to the changes in the way you work in a dynamic, changing world.

---

## Three Things Hub Sites Give You

1. **Shared navigation and brand**
2. **Roll-up of content and search**
3. **A home destination for the hub**

---

## Building Blocks Comparison

| Aspect | Team Site | Communication Site | Hub Site |
|--------|-------------|-------------------|----------|
| **Primary Objective** | Collaborate | Communicate | Connect |
| **Content Authors** | All members | Small number of authors | Hub owner defines shared experiences |
| **Governance** | Team norms | Organization policies | Each associated site owner determines |
| **Permissions** | Microsoft 365 group + SharePoint groups | SharePoint groups | Same as original site type |
| **Created By** | Site owner or admin | Site owner or admin | SharePoint administrators and above |

---

## Hub Site Capabilities for Franchise Portals

### Content Roll-Up Features

Hub sites complement the search experience by helping you discover information in context. Hub sites enable:

- **Serendipitous discovery** of information - surfacing contextually relevant content from sites you may not follow but are associated with the hub
- **Narrowed search experiences** - limiting search to only hub-affiliated sites rather than the entire organization
- **Contextual content surfacing** - if you're on the HR hub reading about open enrollment, you might see related content from Talent Acquisition

### Cross-Site Navigation

Hub sites provide two primary organizational experiences:

#### Association
- A site becomes part of a hub family by **associating** with a hub site
- SharePoint Administrators can allow only certain site owners to associate sites with the hub
- When sites associate, they inherit the hub site theme and shared navigation
- Content from their site will roll up to the hub site in web parts
- Site will be included in the hub site search scope

**Important**: Association with the hub does not automatically add the site to the hub navigation. Hub site owners determine which sites are included in the navigation.

#### Navigation
- The hub site owner determines which sites are reflected in the shared navigation
- Navigation appears at the top, below the suite bar
- Hub navigation can have **up to three levels**
- Most of the time, you will want to add associated sites to your hub navigation

**Note**: The default navigation menu style for team sites hub navigation will be cascading.

---

## Hub Site Governance

### Association Permissions

When creating a hub site:
1. SharePoint Administrators can allow only certain site owners to associate sites with the hub
2. After permission is granted, site owners can choose to associate their sites with the hub
3. Sites inherit the hub site theme and shared navigation upon association

### Permission Considerations

- Association with a hub **does not change the permissions on a site**
- Information surfaced on the hub site is **security trimmed** - if you don't have access to the content, you won't see it
- Consider adjusting permissions on associated sites or adding a hub "read" permission group

### Hub Site Governance Controls

- Hub site owner defines the shared experiences for hub navigation and theme
- Hub site members create content on the hub site as with any other SharePoint site
- Owners and members of associated sites create content on individual sites

---

## Hub Site Technical Limits

| Limit | Value |
|-------|-------|
| **Maximum hub sites per organization** | 2,000 |
| **Sites per hub (navigation)** | No hard limit, practically no more than 100 |
| **Sites per hub (Sites web part)** | 99 maximum for dynamic display |
| **Sites per hub (search)** | Approximately 2,000 |
| **Navigation levels** | Up to 3 levels |

---

## Hub-to-Hub Associations

Hub sites can now be **associated to other hubs** to create an extended search scope:

- You can have a hub called "Northeast Region Sales" that connects to a "Global Sales" hub
- This creates a network of hubs that roll-up to each other
- When hubs are associated with each other, content can be searched for and displayed on hubs up to **three levels of association**

**Important**: A site can only associate with **one hub family**. However, hub families can be connected to one another using links either on the page or in hub navigation.

---

## Creating Hub Sites

### Prerequisites
- SharePoint Administrator or higher permissions in Microsoft 365
- Any existing site can be transformed into a hub site
- Recommend selecting a communication site or a team site that uses the new template

### Limitations
- Sites that are already associated with another hub can't be converted to a hub site
- You can create up to **2,000 hub sites** for an organization
- This applies to hub-to-hub associations as well
- Any site labeled as a hub site counts against this limit
- There's **no limit on the number of sites that can be associated with a hub site**

### PowerShell Management
- `Register-SPOHubSite` - Create a hub site
- `Add-SPOHubSiteAssociation` - Associate a site with a hub
- `Remove-SPOHubSiteAssociation` - Remove association
- `Get-SPOHubSite` - Get hub site information
- `Revoke-SPOHubSiteRights` - Manage permissions

---

## Multi-Tenant Considerations for Franchise Portals

### Cross-Tenant Hub Site Limitations

Based on the Delta Crown Extensions project context (multi-tenant scenario):

1. **Hub sites are tenant-specific**: Hub sites cannot span across multiple Microsoft 365 tenants
2. **Site associations are intra-tenant**: Sites from one tenant cannot be associated with a hub in another tenant
3. **Navigation links can cross-reference**: While sites can't be associated across tenants, you can add navigation links to sites in other tenants

### Workarounds for Multi-Tenant Franchise Portals

#### Option 1: Hub per Tenant with Navigation Links
- Create a hub site in each tenant
- Add navigation links in each hub pointing to the other tenant's hub
- Use consistent branding across hubs
- Manually sync key content or use Power Automate for cross-tenant content flow

#### Option 2: Central Hub with Associated Sites
- Use cross-tenant sync (like the DCE project) to bring users into a single tenant
- Create hub sites in the primary tenant
- Associate all franchise sites to the central hub
- Benefit from unified search, navigation, and content roll-up

#### Option 3: Hub Federation Pattern
- Create franchise-specific hubs in each tenant
- Use Viva Connections to provide unified entry point
- Implement Power Platform solutions for cross-tenant workflows

---

## Best Practices for Franchise Portal Hub Architecture

### Recommended Hub Structure

```
Franchise Portal Hub (Communication Site)
├── Operations Hub (Hub Site)
│   ├── Franchise Location 1 Site (Team Site)
│   ├── Franchise Location 2 Site (Team Site)
│   └── Franchise Location 3 Site (Team Site)
├── Resources Hub (Hub Site)
│   ├── Policies & Procedures Site
│   ├── Training & Certification Site
│   └── Brand Standards Site
└── Support Hub (Hub Site)
    ├── FAQ Site
    ├── Contact Directory Site
    └── Troubleshooting Site
```

### Navigation Planning
- Use audience targeting for private/restricted sites
- Limit navigation to no more than 100 links per hub
- Use descriptive naming like "(restricted)" or "(private)" for restricted sites
- Consider multi-language support for international franchises

### Governance Recommendations
- Establish consistent naming conventions (e.g., "Franchise Operations Hub")
- Define who can associate sites with each hub
- Plan permission inheritance carefully
- Document hub site hierarchy and ownership

---

## Key Takeaways for Franchise Portals

1. **Hub sites provide the connective tissue** for organizing franchise location sites
2. **Content roll-up** enables franchisees to discover relevant content across the network
3. **Shared navigation** creates consistent wayfinding across all franchise sites
4. **Search scoping** allows franchisees to search within relevant content areas
5. **Multi-tenant limitations** require careful architecture planning for cross-tenant scenarios
6. **Governance controls** allow franchisors to manage who can associate sites and what content appears
