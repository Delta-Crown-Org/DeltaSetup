# Viva Connections - Raw Documentation

## Source Information
- **Source**: Microsoft Learn - Official Viva Documentation
- **URL**: https://learn.microsoft.com/en-us/viva/connections/viva-connections-overview
- **Last Updated**: 04/16/2025
- **Source Tier**: Tier 1 (Official Microsoft Documentation)

---

## Viva Connections Overview

Microsoft Viva Connections is your gateway to a modern user experience designed to keep everyone engaged and informed. Connections is a customizable app that can be accessed through Microsoft Teams or the web from desktop, mobile, or tablet devices.

### Key Value Propositions

Connections gives different roles in your organization a personalized landing page where users can discover:
- Helpful tools to complete tasks
- SharePoint news from organizational sites, boosted news, user followed sites, frequent sites, and from people the user works with
- Resources in the form of links provided by the organization
- Other Viva apps your organization is licensed for

---

## Core Components

Connections is composed of **three primary components**:

### 1. News Reader

**Capabilities:**
- Provides users with SharePoint news from across organizational sites
- Includes boosted news, user's followed sites, frequent sites
- News from people the user works with
- Presented as news cards in an immersive reader experience
- Users can Like interesting news and Save content for later
- **Copilot powered news summary** available for Microsoft 365 Copilot licensed users (desktop only)

**Mobile Experience:**
- News reader experience rolling out by end of April 2025 to replace current Feed experience
- Accessible via News tab at top of Connections experience

**Audience Targeting:**
- News can be targeted to specific groups of people using Microsoft Entra ID groups
- Useful for presenting franchise-specific information to relevant franchisees

### 2. Dashboard

The dashboard is your user's digital toolset that brings together resources users need whether in the office or in the field.

**Key Features:**
- Uses dynamic cards that users can interact with
- Can be used as a web part on SharePoint home sites
- Cards based on **Adaptive Cards** and **SharePoint Framework (SPFx)**
- Provides low-code solution to bring line-of-business apps into the dashboard
- Can be authored directly in Connections app in Teams desktop or from SharePoint home site

**Card Capabilities:**
- Display quick views with more information or input forms
- Navigate to SharePoint pages
- Access Teams apps
- Integrate with partner apps, services, and other Viva apps
- Reflect dynamic content that refreshes based on user actions

**Dashboard Layout:**

| Element | Mobile Experience | Desktop Experience |
|---------|------------------|-------------------|
| Layout | Fixed portrait mode | Portrait or landscape |
| Card sizes | Medium (2 cards/row) or Large (1 card/row) | Varies by column layout |
| Card UI | Native | HTML based |
| Card order | Same as Desktop | Same as Mobile |
| User customization | Users can reorder, show/hide cards | Author controlled |

**Dashboard Card Limits:**
- Users see all cards without audience targeting
- Plus audience-targeted cards where viewer is part of targeted audience
- Desktop: Number of cards to show can be specified in web part settings
- Users can expand by selecting "See all"

### 3. Resources

**Purpose:**
- Enables wayfinding across popular destinations
- Organizations can curate a list of useful links
- Can be customized from Teams app and web experience
- Displayed on desktop, web, and mobile

**Key Capabilities:**
- Customized links from any URL (external or internal)
- Links can be customized with audience targeting
- Up to **48 resource links** can be created
- Global navigation bar from SharePoint home site can be imported

**Mobile Access:**
- Users view resources by selecting Resources tab
- Provides familiar navigation structure
- Users can open sites, pages, news from mobile devices

---

## Mobile Experience Capabilities

### Mobile App Features

The Connections mobile app experience is anchored around three key concepts:
1. **Dashboard** - Digital toolset for task completion
2. **News reader** - Personalized news feed
3. **Resources** - Wayfinding to popular destinations

**Mobile-Specific Benefits:**
- More compact experience using tabs for easier scrolling
- Accessible via Microsoft Teams mobile app
- Native card UI for better mobile performance
- Users can reorder and customize their dashboard cards
- Clock in/out capabilities for shift workers
- Access to training materials and paystub information
- Mobile-optimized resource navigation

**Platform Support:**
- iOS and Android apps
- Tablet support with optimized layout
- Responsive design across device sizes

---

## Desktop Experience Capabilities

### Key Desktop Features

- **Viva suite integration**: Easy discovery and navigation to all licensed Viva modules
- **Web accessibility**: Access via SharePoint home site or Viva Suite home website without Teams app
- **Navigation**: Elements in top-right and top-left for easy movement between experiences
- **Announcements**: Important time-sensitive notices targeted to users appear at top
- **Company resources**: Navigation panel appears when selecting branded app icon in Teams
- **Role-based tools**: Content targeting ensures right tools at right time
- **Personalized news**: News tab provides personalized feed with organizational and industry news
- **Easy sharing**: Content can be shared into Teams chats or channels

### Multiple Entry Points

Users can access Connections from:
1. **Connections app in Microsoft Teams**: Select from Teams app bar
2. **SharePoint home site**: "Go to Connections" link from intranet
3. **Viva Suite home website**: Select Connections card from spotlight

---

## Brand Customization Options

### Branding Capabilities

**Organization Branding:**
- Branding applied in Teams to Connections desktop app includes logo and colors
- Automatically applied to mobile app
- Custom fonts NOT supported on mobile

**Dark Mode Limitation:**
- Organization branding is currently disabled for users who have enabled dark mode under Microsoft Teams Appearance and Accessibility settings

**Additional Desktop Branding:**
- Desktop app offers further branding customization
- Custom banner images
- Custom themes

### Customization Through SPFx

- **SharePoint Framework (SPFx)** is the recommended customization model
- Tight integration between SharePoint, Microsoft Teams, and Viva Connections
- SPFx is the ONLY extensibility and customization option for Connections
- Supports custom web parts and extensions

---

## Distribution Lists and Targeting

### Audience Targeting

**How It Works:**
- Audience targeting uses Microsoft Entra ID groups
- Works for card-level targeting in dashboard
- Works for menu-item targeting in global navigation

**Targeting Capabilities:**
- Home site content can be targeted to specific audiences
- News stories can be targeted to specific groups (e.g., franchise-specific news)
- Dashboard cards can be targeted to specific audiences
- Resources can have audience-targeted links

**Benefits:**
- Create different experiences for each franchise group
- Dynamic group memberships reduce administrative overhead
- Authors can preview what dashboard looks like across devices and audiences

### Multiple Experiences

**Capability:**
- Organizations can set multiple home sites using multiple Connections experiences
- Create targeted experiences content-specific for different groups
- Example: Separate dashboard and resources with frontline worker focus

**Licensing Requirements:**
- Users with Microsoft 365 subscription (E, F, or A license): Limited to one experience
- **Microsoft Viva Suite or Viva Communications and Communities license**: Up to 50 experiences per user

---

## Localization

### Language Support

Connections is available in most major languages used in Microsoft 365.

**Multi-language Capabilities:**

| Component | Localization Support |
|-----------|---------------------|
| **Dashboard** | Content can be set to support multiple languages by authors |
| **News reader** | Content available in authored format; SharePoint news posts display author-translated posts in user's preferred language |
| **Resources** | Content follows site's default language |

### Setup Options
- Set up Connections mobile experience in specific language
- Create dashboard in more than one language
- Supports international franchise networks

---

## Integration with SharePoint Home Sites

### How They Work Together

Connections and home sites are complementary methods for creating powerful user experiences:

- **Connections**: Primary destination for job-specific tools and news
- **Home Site**: Secondary source for organizational news, events, and resources

### Shared Functionality
- Both share news roll-ups, navigation, and partner extensibility
- Both use audience targeting
- Both distribute organizational and industry news
- Same permissions model for easy editor access

### Automatic Detection
- Connections automatically detects home sites
- Prominent link displays at top-right of desktop experience
- Users can easily navigate between both experiences

### Choosing Default Experience
- Connections is default unless specified otherwise
- When Connections is default: Link to home site in top-right
- When home site is default: Link to Connections in top-right

---

## Extensibility

### SharePoint Framework (SPFx)

- **Only extensibility option** for Connections
- Recommended for tight integration between SharePoint, Teams, and Connections
- Supports:
  - Custom dashboard cards
  - Web parts on home sites
  - Extensions and customizations

### Partner Integrations

- Cards can integrate with partner apps and services
- Other Viva apps can be integrated
- Line-of-business apps can be brought into dashboard

---

## Privacy, Security, and Compliance

### Inherited Security

Security largely inherited from Microsoft 365, SharePoint, and Teams:
- Governed under Microsoft Product Terms and Data Protection Agreement (DPA)
- Inherits privacy features from Microsoft 365, Teams, SharePoint
- Owners should confirm who has access to sites within SharePoint

### Compliance

- Compliance copies of messages available
- Retention policies can be applied
- eDiscovery support

---

## Licensing

### Base Licensing
- Microsoft 365 subscription (E, F, or A license)
- One Connections experience per user

### Premium Licensing
- **Microsoft Viva Suite**: Multiple experiences (up to 50)
- **Viva Communications and Communities**: Multiple experiences (up to 50)

### Franchise Portal Considerations

For franchise portal with multiple franchisee groups:
- May need Viva Suite for multiple targeted experiences
- Allows creating franchise-specific experiences
- Enables franchisee-specific dashboards and resources

---

## Implementation Recommendations for Franchise Portals

### Dashboard Cards for Franchisees

**Recommended Card Types:**

1. **Operational Cards**
   - Clock in/out for shift workers
   - Schedule viewing
   - Task management

2. **Resource Cards**
   - Quick links to franchise resources
   - Brand guidelines access
   - Training materials

3. **Communication Cards**
   - News from franchisor
   - Announcements
   - Franchise community updates

4. **Performance Cards**
   - KPI displays
   - Sales metrics (via Power BI integration)
   - Compliance checklists

### Mobile-First Design

**Critical for Franchise Portals:**
- Many franchisees operate via mobile devices
- Design dashboard cards for mobile experience first
- Ensure critical tasks can be completed on mobile
- Test on actual mobile devices before deployment

### Multi-Experience Strategy

For large franchise networks:
- Create separate Connections experiences by franchise region or type
- Use Viva Suite licensing for multiple experiences
- Maintain consistent branding across experiences
- Share common resources across experiences

### Integration with Hub Sites

**Recommended Architecture:**
- Hub sites provide structural organization
- Viva Connections provides entry point and mobile experience
- Dashboard cards link to hub site content
- Resources provide quick navigation to hub sites

---

## Key Takeaways

1. **Mobile-first design** is critical for franchisee adoption
2. **Dashboard cards** provide quick access to franchise tools and resources
3. **Audience targeting** enables franchise-specific content delivery
4. **Multi-experience support** allows regional or franchise-type variations
5. **News reader** keeps franchisees informed with personalized content
6. **Resources** provide consistent wayfinding across all franchise touchpoints
7. **SPFx extensibility** enables custom franchise-specific solutions
