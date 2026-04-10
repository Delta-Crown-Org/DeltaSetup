# Microsoft Viva Connections - Official Documentation

**Source**: Microsoft Learn - Official Documentation
**URL**: https://learn.microsoft.com/en-us/viva/connections/viva-connections-overview
**Date Retrieved**: March 31, 2025
**Source Tier**: Tier 1 (Highest - Official Microsoft Documentation)
**Last Updated**: April 16, 2025

## Overview

Microsoft Viva Connections is a customizable app that serves as a gateway to modern user experience, designed to keep everyone engaged and informed. It can be accessed through Microsoft Teams or the web from desktop, mobile, or tablet devices.

### Key Characteristics

- **User Experience App**: Allows organizations to create unique experiences for different audiences (information workers, frontline workers, educators, researchers, students)
- **Gateway to Viva Apps**: Curates specific content and tools with easy access to resources, tools, relevant news, announcements, and popular destinations
- **Built on Microsoft 365**: Leverages existing capabilities in SharePoint, Teams, and Microsoft Entra
- **Multi-Platform Access**: Desktop, tablet, mobile versions of Teams app, SharePoint home site, or Viva Suite home website

## Core Components

### 1. Spotlight
- **Position**: Top of Connections experience
- **Content**: Dynamically displays content from home site, SharePoint news, or links to articles/sites
- **Capacity**: Up to 11 customizable items
- **Behavior**: Collapses if no items available

### 2. News Reader
- **Content Sources**: SharePoint news from organizational sites, boosted news, followed sites, frequent sites, people user works with
- **Format**: News cards in immersive reader experience
- **Features**: Like interesting news, Save content for later
- **Copilot Integration**: AI-generated summary of top news items (desktop Teams only, requires Microsoft 365 Copilot license)
- **Rollout**: Being rolled out to replace current Feed experience by end of April 2025

### 3. Dashboard
- **Purpose**: Digital toolset bringing together resources users need (office or field)
- **Technology**: Dynamic cards based on Adaptive Cards and SharePoint Framework (SPFx)
- **Card Types**: Medium-sized and large-sized cards
- **Customization**: Authors can target cards to specific audiences using Microsoft Entra ID groups

### 4. Resources
- **Purpose**: Wayfinding across popular destinations
- **Content**: Curated list of useful links (health benefits, forms, department websites)
- **Capacity**: Up to 48 resource links
- **Integration**: Can import from SharePoint global navigation

## Mobile Experience Architecture

### Key Mobile Characteristics

The mobile experience in Teams app is anchored around three key concepts:
1. **Dashboard** - Quick access tools
2. **News Reader** - Personalized news feed
3. **Resources** - Curated navigation links

### Mobile-Specific Design

- **Compact Experience**: More compact than desktop, uses tabs for easier scrolling
- **Fixed Portrait Layout**: Dashboard fixed in portrait mode
- **Card Layout**:
  - Medium cards: 2 cards per row
  - Large cards: 1 card per row
- **User Customization**: Users can reorder, show, or hide cards (settings don't carry over to desktop/tablet)

### Mobile vs Desktop Comparison

| Element | Mobile Experience | Desktop Experience |
|---------|------------------|-------------------|
| **Dashboard Display** | Default tab in Teams app | Prominent display, can add as web part to SharePoint |
| **Layout** | Fixed portrait, 2 cards (medium) or 1 card (large) per row | Portrait or landscape, varies by column layout |
| **Card UI** | Native | HTML based |
| **Card Order** | Same as Desktop | Same as Mobile |
| **Card Reflow** | Same as Desktop | Same as Mobile |
| **Cards Shown** | All cards + audience-targeted cards | Configurable in web part settings, expandable |

### Dashboard Card Capabilities

Users can interact with cards to:
- Display quick view with more information or input form
- Navigate to SharePoint page
- Access Teams app
- Integrate with partner apps, services, and other Viva apps

**Dynamic Content**: Cards can refresh based on user action or events (e.g., new tasks, required training)

## Curated Experiences

### Audience Targeting

Connections enables curated experiences using Microsoft Entra ID groups for:
- **Dashboard**: Card-level targeting
- **Global Navigation**: Menu-item targeting
- **News**: Audience-targeted news stories
- **Resources**: Targeted navigation links

### Role-Based Access

Content can be targeted to ensure users have:
- Right tools at the right time
- Job-specific content and resources
- Relevant news based on role and interests

## Branding and Customization

### Automatic Branding
- Organization branding in Teams (logo, colors) automatically applies to mobile
- Desktop app allows further customization (banner image, theme)

### Limitations
- Organization branding disabled for users with dark mode enabled
- Custom fonts not supported on mobile

## Localization

### Multi-Language Support
- **Dashboard**: Content can support multiple languages
- **News Reader**: Displays content in authoring format, SharePoint news shows translated posts in user's preferred language
- **Resources**: Follows site's default language

## Technical Requirements

### Licensing
- **Microsoft 365**: E, F, or A license type for creating Connections experience
- **Single Experience**: All users with Microsoft 365 subscription (E, F, or A license)
- **Multiple Experiences** (up to 50): Requires Microsoft Viva Suite or Viva Communications and Communities license for all users

### Integration Points

1. **SharePoint Home Sites** (Optional)
   - Not required for Connections
   - Can serve as secondary landing destination
   - Connections automatically detects home sites
   - Users can navigate between both experiences

2. **SharePoint Framework (SPFx)**
   - Recommended customization model
   - Only extensibility option for Connections
   - Tight integration between SharePoint, Teams, and Connections

3. **Adaptive Cards**
   - Foundation for dashboard cards
   - Low-code solution for line-of-business apps
   - Support for custom card development

## Mobile Implementation Considerations for Franchise Portals

### Design Principles

1. **Tab-Based Navigation**
   - Dashboard, News, Resources as primary tabs
   - Easy switching between content types
   - Reduces cognitive load on mobile

2. **Card-Based Layout**
   - Consistent card sizes (medium/large)
   - Predictable positioning
   - Touch-friendly spacing

3. **Native UI for Mobile**
   - Native card rendering on mobile devices
   - Platform-appropriate interactions
   - Optimized for touch input

4. **Offline Considerations**
   - No explicit offline access mentioned
   - Dynamic content refreshes when connected
   - Consider caching strategies for critical resources

### Franchise Owner Use Cases

**Quick Tasks** (Dashboard cards):
- Clock in/out for shift
- Access training materials
- Review paystub information
- Book resources (shuttle, equipment)
- Complete required training

**Information Consumption** (News Reader):
- Corporate announcements
- Policy updates
- Best practices from other franchisees
- Industry news

**Resource Access** (Resources tab):
- Benefits information
- Important forms
- Department websites
- Support contacts

### Recommendations

1. **Card Design**
   - Prioritize medium cards for quick-scan layouts
   - Use large cards for high-priority actions
   - Ensure cards have clear visual hierarchy

2. **Content Prioritization**
   - Use audience targeting for franchise-specific content
   - Front-load most-used tools in dashboard
   - Curate resources by franchisee needs

3. **Mobile-First Approach**
   - Design for portrait orientation
   - Test touch interactions at 48dp minimum targets
   - Ensure quick views are mobile-optimized

4. **Performance**
   - Leverage SPFx for efficient rendering
   - Use dynamic content for real-time updates
   - Consider network conditions for franchise locations
