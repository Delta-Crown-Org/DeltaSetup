# Hub-and-Spoke Navigation Models

**Research ID**: web-puppy-3e7ada  
**Date**: January 2025  
**Source**: Microsoft Learn - Planning SharePoint Hub Sites, Nielsen Norman Group

## Overview

Hub-and-spoke architecture is the optimal pattern for enterprise multi-location organizations, particularly franchises. It balances **centralized governance** with **localized autonomy**, enabling brand consistency while supporting location-specific needs.

## Core Concepts

### Hub Sites: The Connective Tissue

Hub sites provide **three core capabilities**:

1. **Shared Navigation and Brand**
   - Common navigation across all associated sites
   - Consistent visual theming
   - Unified user experience

2. **Content Roll-Up and Search**
   - Aggregate news from associated sites
   - Unified search scope
   - Activity highlights

3. **Home Destination for the Hub**
   - Central landing page
   - Discovery of related content
   - Contextual information

### Key Principle: Links, Not Hierarchy

**Traditional Approach (Subsite Model)**:
```
HR (Root Site)
├── Benefits (Subsite)
├── Compensation (Subsite)
├── Training (Subsite)
└── Policies (Subsite)
```
**Problem**: Rigid hierarchy, broken URLs on reorganization

**Modern Approach (Hub Model)**:
```
HR Hub (Communication Site) ← Associated Sites
├── Benefits Site (Communication Site)
├── Compensation Site (Communication Site)
├── Training Site (Team Site)
└── Policies Site (Communication Site)
```
**Advantage**: Flexible associations, preserved URLs, dynamic relationships

## Enterprise IA Patterns

### Pattern 1: Functional Hub Model

**Best for**: Organizations with clear functional divisions

```
Home Site (Organization Portal)
│
├── HR Hub
│   ├── Benefits Site
│   ├── Compensation Site
│   ├── Training Site
│   └── Policies Site
│
├── Operations Hub
│   ├── Quality Site
│   ├── Safety Site
│   └── Standards Site
│
├── Marketing Hub
│   ├── Brand Site
│   ├── Campaigns Site
│   └── Assets Site
│
└── Support Hub
    ├── Help Center Site
    ├── IT Support Site
    └── Contact Directory
```

**Benefits**:
- Clear functional boundaries
- Easy content governance
- Role-based access control
- Expertise-based navigation

### Pattern 2: Geographic Hub Model

**Best for**: Multi-location organizations with regional autonomy

```
Home Site (Global Portal)
│
├── North America Hub
│   ├── USA West Sites
│   ├── USA East Sites
│   └── Canada Sites
│
├── Europe Hub
│   ├── UK Sites
│   ├── Germany Sites
│   └── France Sites
│
├── Asia Pacific Hub
│   ├── Japan Sites
│   ├── Australia Sites
│   └── Singapore Sites
│
└── Latin America Hub
    ├── Mexico Sites
    ├── Brazil Sites
    └── Argentina Sites
```

**Benefits**:
- Time-zone appropriate content
- Local language support
- Regional compliance
- Cultural customization

### Pattern 3: Hybrid Hub Model

**Best for**: Complex organizations with both functional and geographic needs

```
Home Site (Global Portal)
│
├── Operations Hub (Functional)
│   ├── Quality Standards Site
│   ├── Safety Guidelines Site
│   └── Compliance Site
│
├── Marketing Hub (Functional)
│   ├── Brand Assets Site
│   ├── Campaigns Site
│   └── Social Media Site
│
├── North America Hub (Regional)
│   ├── USA Operations Site → Associated with Operations Hub
│   ├── USA Marketing Site → Associated with Marketing Hub
│   └── Canada Sites
│
└── Europe Hub (Regional)
    ├── UK Operations Site → Associated with Operations Hub
    ├── UK Marketing Site → Associated with Marketing Hub
    └── Germany Sites
```

**Benefits**:
- Dual association through hub-to-hub linking
- Local context + global standards
- Flexible navigation paths
- Multi-dimensional organization

## Franchise-Specific Hub Architecture

### Recommended Architecture

```
Franchisor Home Site (Hub)
│
├── Training Hub
│   ├── Onboarding Site
│   ├── Certification Site
│   ├── Operations Training Site
│   └── Leadership Training Site
│
├── Operations Hub
│   ├── SOPs Site
│   ├── Quality Standards Site
│   ├── Safety Site
│   └── Compliance Site
│
├── Marketing Hub
│   ├── Brand Guidelines Site
│   ├── Campaigns Site
│   ├── Assets Library Site
│   └── Social Media Site
│
├── Support Hub
│   ├── Help Center Site
│   ├── Ticket System Site
│   ├── FAQ Site
│   └── Contact Directory Site
│
├── Community Hub
│   ├── Discussion Forums Site
│   ├── Events Site
│   ├── Recognition Site
│   └── Best Practices Site
│
└── Regional Hubs (by geography)
    ├── Northeast Region Hub
    │   ├── Location A Site
    │   ├── Location B Site
    │   └── Location C Site
    ├── Southeast Region Hub
    └── West Region Hub
```

### Association Strategy

**Single Association Rule**:
- Each site can associate with **only one hub**
- Strategic decision: functional vs. geographic alignment
- Consider: "How do users think about this content?"

**Cross-Hub Connection**:
- Use **links in navigation** to connect related hubs
- **Hub-to-hub associations** expand search scope
- Content can appear on multiple hubs through roll-up

**Example Decision Matrix**:

| Site Type | Primary Association | Secondary Connection | Rationale |
|-----------|-------------------|---------------------|-----------|
| Benefits | HR Hub | Link in Regional Hub | Functional first, regional access |
| Location Ops | Regional Hub | Link in Operations Hub | Geographic first, functional access |
| Training | Training Hub | Links in Regional Hubs | Centralized content, regional delivery |

## Navigation Design Patterns

### Hub Navigation Structure

**Level 1: Primary Navigation** (5-7 items max)
```
[Logo] Home | Training | Operations | Marketing | Support | Community | [Search]
```

**Level 2: Secondary Navigation** (5-7 items per category)
```
Training Hub
├── Onboarding
├── Certifications
├── Operations Training
├── Leadership
└── Resources
```

**Level 3: Tertiary Navigation** (limit to essentials)
```
Onboarding (under Training)
├── New Franchisee Orientation
├── Pre-Opening Checklist
├── First 30 Days
└── First 90 Days
```

### Mega Menu Pattern

**Best for**: Complex hierarchies with deep content

```
[Training] [Operations] [Marketing] [Support] [Community]

Training Mega Menu:
├─ Onboarding        ├─ Certifications      ├─ Operations Training
│  ├─ Orientation    │  ├─ Level 1          │  ├─ Daily Operations
│  ├─ Pre-Opening    │  ├─ Level 2          │  ├─ Quality Control
│  ├─ First 30 Days  │  └─ Specializations  │  └─ Safety
│  └─ First 90 Days  └─                     └─
└─                   └─                     └─
```

**Guidelines**:
- Maximum 3 columns
- Clear visual hierarchy
- Icons for quick scanning
- Featured/promoted items

### Breadcrumb Navigation

**Essential for**: Deep navigation paths

```
Home > Training Hub > Onboarding > First 30 Days > Week 1 Tasks
```

**Benefits**:
- Orientation within hierarchy
- Quick navigation to parent levels
- Reduced need for "back" button
- SEO-friendly structure

### Quick Links Pattern

**Best for**: Task-based navigation

```
Quick Tasks:
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ 📋 Submit    │ 📞 Contact   │ 📅 Register  │ 📖 Access    │
│    Weekly    │    Support   │    Event     │    Training  │
│    Report    │              │              │              │
└──────────────┴──────────────┴──────────────┴──────────────┘

Recent Resources:
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ 📄 Updated   │ 🎥 New       │ 📊 Monthly   │ 📋 Compliance│
│    Safety    │    Training  │    Metrics   │    Checklist │
│    Guide     │    Video     │              │    Due       │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

## Multi-Tenant Portal Strategies

### Cross-Tenant Considerations

**For Franchise Organizations**:

1. **Franchisor Tenant** (Hub)
   - Central resources
   - Brand assets
   - Training content
   - Communication
   - Governance

2. **Franchisee Tenant** (Spoke)
   - Local operations
   - Team collaboration
   - Local resources
   - Customer data
   - Local governance

**Connection Methods**:
- **Cross-tenant sync** (member-type accounts)
- **B2B guest access** (limited, external user experience)
- **Shared channels** (Microsoft Teams)
- **External sharing** (document-level)

### Hub Association Across Tenants

**Current Limitation**: SharePoint hub sites don't directly support cross-tenant association

**Workarounds**:

1. **Shared Navigation Links**
   - Manual links to external resources
   - Consistent navigation pattern
   - Clear external indicators

2. **Power Automate Integration**
   - Sync content between tenants
   - Automated distribution
   - Version control

3. **Microsoft Teams Shared Channels**
   - Cross-tenant collaboration
   - Shared chat and files
   - No tenant switching

4. **Third-Party Solutions**
   - Akumina, Unily, LiveTiles
   - Cross-tenant aggregation
   - Unified search

## Search Scope Management

### Hub-Level Search

**Scope**: All associated sites
**Use for**: Finding content within functional/geographic area

**Example**: 
- Search on HR Hub → Benefits, Compensation, Training sites
- Search on Northeast Hub → Location A, B, C sites

### Global Search

**Scope**: Entire organization
**Use for**: Finding content regardless of location

**Implementation**:
- SharePoint Search Center
- Microsoft Search (Bing integration)
- Custom search verticals
- Federated search

### Scoped Search Patterns

**Progressive Disclosure**:
1. **Local site search** (current site)
2. **Hub search** (associated sites)
3. **Global search** (entire organization)

**Implementation**:
```
Search: [_______________] [v] Hub Scope
        Site Only | This Hub | All Sites
```

## Content Roll-Up Strategies

### News Aggregation

**Hub News Web Part Configuration**:
- Source: "All sites in hub"
- Filter: Last 30 days
- Sort: Most recent first
- Layout: Hub layout (cards)

**Content Strategy**:
- Publish important news to hub home
- Location-specific news to local sites
- Auto-roll-up to hub
- "Featured" capability for promotion

### Events Roll-Up

**Use Cases**:
- Regional training events
- Franchisee conferences
- Webinars and workshops
- Local community events

**Configuration**:
- Events web part
- Source: All sites in hub
- Filter: Future events
- Sort: Chronological

### Highlighted Content

**Use Cases**:
- New resources
- Updated documents
- Featured training
- Important announcements

**Configuration**:
- Highlighted content web part
- Filter by content type
- Audience targeting
- Manual curation option

## Navigation Governance

### Ownership Model

**Hub Site Owner**:
- Manage hub navigation
- Configure shared theme
- Approve site associations
- Monitor content roll-up

**Site Owners**:
- Manage local navigation
- Create local content
- Control local permissions
- Maintain content freshness

**Content Owners**:
- Create and maintain content
- Follow content standards
- Update expiration dates
- Respond to feedback

### Navigation Standards

**Naming Conventions**:
- Consistent terminology
- No abbreviations (unless universal)
- Action-oriented labels
- User-centric language

**Structure Standards**:
- Maximum depth: 3 levels
- Maximum items per level: 7
- Logical grouping
- Alphabetical within groups

**Review Schedule**:
- Monthly: Usage analytics review
- Quarterly: Navigation audit
- Annually: Full IA review
- As needed: Major organizational changes

## Mobile Navigation Considerations

### Responsive Design

**Desktop**: Horizontal navigation, mega menus
**Tablet**: Collapsible navigation, touch-friendly targets
**Mobile**: Hamburger menu, prioritized links, bottom actions

### Mobile-First Navigation

**Priority 1** (Always Visible):
- Home
- Search
- Quick tasks
- Notifications

**Priority 2** (One Tap):
- Most-used resources
- Recent items
- Bookmarks

**Priority 3** (Menu):
- Full navigation
- Settings
- Help
- Profile

### Touch Optimization

**Target Sizes**:
- Minimum 44x44 pixels
- Adequate spacing between items
- No hover-dependent interactions

**Gestures**:
- Swipe for menus
- Pull to refresh
- Pinch to zoom (where appropriate)

## Performance Optimization

### Navigation Performance

**Practical Limits** (per Microsoft documentation):
- **100 sites** per hub (practical limit for UX)
- **500 navigation nodes** (technical limit)
- **99 sites** for sites web part
- **3 levels** of hub navigation

**Optimization Strategies**:
- Archive old sites
- Consolidate redundant sites
- Use audience targeting
- Implement pagination

### Load Time Optimization

**Hub Navigation**:
- Cached for performance
- Lazy loading for deep menus
- CDN for assets

**Content Roll-Up**:
- Index-based search (not real-time)
- Scheduled updates
- Progressive loading

## Implementation Checklist

### Phase 1: Planning
- [ ] Identify hub candidates
- [ ] Define association strategy
- [ ] Map navigation structure
- [ ] Plan governance model
- [ ] Design for mobile

### Phase 2: Configuration
- [ ] Create hub sites
- [ ] Configure shared themes
- [ ] Set up hub navigation
- [ ] Enable site associations
- [ ] Configure content roll-up

### Phase 3: Content
- [ ] Create initial content
- [ ] Set up content roll-up
- [ ] Configure audience targeting
- [ ] Test navigation flows
- [ ] Train content owners

### Phase 4: Launch
- [ ] Pilot with champions
- [ ] Gather feedback
- [ ] Iterate based on usage
- [ ] Full rollout
- [ ] Monitor and optimize

## Common Pitfalls

### 1. Over-Association
**Problem**: Too many sites per hub
**Solution**: Limit to 100 sites, create sub-hubs if needed

### 2. Deep Navigation
**Problem**: 4+ levels of navigation
**Solution**: Flatten structure, use content organization

### 3. Unclear Ownership
**Problem**: No one maintains navigation
**Solution**: Assign hub owners, review schedule

### 4. Desktop-Only Design
**Problem**: Navigation doesn't work on mobile
**Solution**: Mobile-first design, responsive patterns

### 5. Content Silos
**Problem**: Sites not associated, content hidden
**Solution**: Clear association strategy, regular audits

### 6. Permission Confusion
**Problem**: Users see links they can't access
**Solution**: Audience targeting, security trimming

## Success Metrics

### Navigation Effectiveness
- Time to find content
- Search vs. browse ratio
- Navigation abandonment rate
- Mobile navigation success

### Content Discovery
- News readership rates
- Event registration rates
- Resource download rates
- Training completion rates

### User Satisfaction
- Navigation satisfaction scores
- Help desk calls about finding content
- User feedback on organization
- Content freshness ratings

## Future Considerations

### Viva Connections
- Dashboard integration
- Feed integration
- Mobile app
- Adaptive cards

### AI-Powered Navigation
- Personalized recommendations
- Predictive search
- Automated content organization
- Chatbot integration

### Multi-Geo Expansion
- Regional hubs
- Data residency
- Performance optimization
- Compliance requirements
