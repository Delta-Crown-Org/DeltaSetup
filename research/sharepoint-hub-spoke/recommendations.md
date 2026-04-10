# Project-Specific Recommendations: Multi-Brand Franchise SharePoint Architecture

## Executive Decision Summary

**Recommended Architecture**: **Hub-per-Brand with Shared Services Hub**

For a multi-brand franchise operating on Microsoft 365 Business Premium, implement separate hub sites for each franchise brand plus a central Corporate/Shared Services hub for cross-brand functions.

---

## 1. Hub Site Topology Recommendation

### Architecture Pattern

```
CORPORATE SHARED SERVICES HUB
├── HR Hub (HR team site + associated sites)
├── IT Hub (IT team site + associated sites)  
├── Finance Hub (Finance team site + associated sites)
├── Training Hub (Training team site + associated sites)
└── [Other shared functions]

BRAND A HUB
├── Brand A Main Site (Communication Site)
├── Brand A Operations (Team Site)
├── Brand A Locations (Team Sites per location)
├── Brand A Teams-connected Sites
└── [Brand-specific sites]

BRAND B HUB
├── Brand B Main Site (Communication Site)
├── Brand B Operations (Team Site)
├── Brand B Locations (Team Sites per location)
└── [Brand-specific sites]

[Additional Brand Hubs...]
```

### Why This Pattern

| Factor | Single Hub | Nested Hubs | Hub-per-Brand (Recommended) |
|--------|-----------|-------------|---------------------------|
| **Brand Autonomy** | ❌ Low | ⚠️ Medium | ✅ High |
| **Navigation Clarity** | ⚠️ Crowded | ⚠️ Complex | ✅ Clear |
| **Search Scope** | ❌ Everything mixed | ⚠️ Overlapping | ✅ Brand-focused |
| **Governance** | ⚠️ Complex | ⚠️ Very Complex | ✅ Straightforward |
| **User Experience** | ⚠️ Brand confusion | ⚠️ Navigation depth | ✅ Brand-centric |
| **Performance** | ⚠️ Scale issues | ⚠️ Multiple hops | ✅ Distributed |

### Hub Count Planning

**Maximum Hubs**: 2,000 per tenant (you won't approach this limit)

**Recommended Distribution**:
- 1 Corporate/Shared Services Hub
- 1 Hub per franchise brand (if 5 brands = 5 brand hubs)
- Reserve capacity for future brands or functional hubs

---

## 2. Site Provisioning Strategy

### Recommended Approach: **PnP Tenant Templates + Site Designs**

#### Three-Tier Provisioning Model

**Tier 1: Brand Template (PnP Tenant Template)**
- Complete brand workspace package
- Includes: SharePoint sites + Teams team + structure + content types
- Used for: Initial brand setup, new franchise onboarding

**Tier 2: Site Design (SharePoint Site Designs)**
- Standardized site templates
- Used for: Self-service site creation within brands
- Examples: "Location Site", "Project Site", "Department Site"

**Tier 3: Manual/Ad-hoc**
- Custom sites as needed
- Governance-controlled
- Exception-based

#### Brand Template Components

```xml
PnP Tenant Template Structure:
├── Teams Team (with channels)
├── SharePoint Communication Site (Brand Hub)
├── SharePoint Team Site (Operations)
├── Document Libraries (standard structure)
├── Content Types (brand-specific)
├── Site Columns (metadata)
├── Page Templates
├── Navigation Structure
└── Branding (themes, logos)
```

#### Provisioning Comparison

| Method | Best For | Complexity | Automation Level |
|--------|----------|------------|------------------|
| **PnP Tenant Templates** | Complete brand deployment | Medium-High | Full |
| **PnP Site Templates** | Individual site provisioning | Medium | Full |
| **SharePoint Site Designs** | User self-service | Low | Semi |
| **Microsoft Graph API** | Programmatic operations | Medium | Full |
| **SharePoint REST API** | Custom development | High | Custom |
| **Manual Creation** | One-offs, exceptions | Low | None |

**Recommendation**: Use PnP Tenant Templates for brand onboarding, Site Designs for ongoing site creation.

### Implementation Steps

1. **Phase 1**: Create base PnP template for first brand
2. **Phase 2**: Test and refine template
3. **Phase 3**: Deploy to remaining brands (customize per brand)
4. **Phase 4**: Implement Site Designs for self-service
5. **Phase 5**: Automate provisioning pipeline

---

## 3. Multi-Brand Security & Governance

### Critical Constraint: M365 Business Premium

**Information Barriers are NOT available** in Business Premium. Alternative approaches required.

### Recommended Security Framework

#### Layer 1: Permission-Based Isolation

**Site Collection Strategy**:
- Each brand operates in distinct site collections
- Brand users are site owners/members of their brand sites
- No cross-brand permission inheritance

**Permission Model**:
```
Brand A Hub Site
├── Owners: Brand A Leadership
├── Members: Brand A Staff
└── Visitors: [As needed]

Brand A Associated Sites
├── Inherit permissions OR
├── Unique permissions with Brand A users only
```

#### Layer 2: Sensitivity Labels

**Label Structure**:
```
┌─────────────────────────────────────────────────────┐
│  PUBLIC                                            │
│  • Internal content shareable within org           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  BRAND A - INTERNAL                                │
│  • Brand A confidential, not for other brands      │
│  • Auto-label by site location                     │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  BRAND B - INTERNAL                                │
│  • Brand B confidential, not for other brands      │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  CORPORATE CONFIDENTIAL                            │
│  • Shared services, cross-brand visible            │
└─────────────────────────────────────────────────────┘
```

#### Layer 3: DLP Policies

**Policy Configuration**:
```
Policy: Brand A Data Protection
├── Scope: Brand A sites
├── Actions: 
│   ├── Block sharing with other brands
│   ├── Warn on external sharing
│   └── Audit all sharing
└── Exceptions: Corporate Shared Services

Policy: Brand B Data Protection
[Same structure]

Policy: External Sharing Control
├── Scope: All sites
├── Actions:
│   ├── Block external sharing for [Confidential]
│   └── Require approval for external sharing
```

#### Layer 4: Site Design Governance

**Creation Controls**:
- Use Site Designs to enforce naming conventions
- Require approval for site creation (optional)
- Auto-apply brand-specific labels
- Enforce retention policies

### Governance Decision Matrix

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| **External Sharing** | Disabled by default, enabled per site | Brand protection |
| **Guest Access** | Require approval | Control brand exposure |
| **Site Creation** | Governed + Templates | Consistency |
| **Private Channels** | Limited to site owners | Governance |
| **Sensitivity Labels** | Mandatory | Content classification |
| **Retention Policies** | Brand-specific | Compliance |

---

## 4. Teams Integration Pattern

### Teams Structure per Brand

```
Brand A Teams
├── Brand A - General Team
│   ├── Standard Channels:
│   │   ├── General
│   │   ├── Operations
│   │   └── Marketing
│   └── Private Channels (controlled):
│       ├── Leadership
│       └── Finance
└── Brand A - Location Teams (if needed)
    └── [Location-specific channels]

Corporate Shared Teams
├── HR Team
├── IT Support Team
├── Finance Team
└── All-Company Team
```

### Teams + Hub Integration

**Association Strategy**:
1. Each brand's main Team site is associated with Brand Hub
2. Location Teams sites associated with Brand Hub
3. Corporate Teams sites associated with Shared Services Hub
4. Private channel sites: Evaluate case-by-case

**Navigation Integration**:
- Brand Hub navigation includes link to Brand Team
- Brand Team "Files" tab = SharePoint document library
- Shared Services Hub links to Corporate Teams

### Shared Mailbox Consideration

Microsoft 365 Groups (Teams) include shared mailboxes:
- Each Team has associated group mailbox
- Brand Teams = Brand communication hub
- Corporate Teams = Cross-brand communication
- No additional licensing needed (included in Business Premium)

### Private Channel Governance

**Critical**: Private channels create separate SharePoint sites with independent permissions.

**Recommended Controls**:
1. Limit private channel creation to site owners
2. Document all private channels and their purpose
3. Include private channel sites in permission audits
4. Consider whether private channel should associate with hub

---

## 5. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Establish core hub infrastructure

Tasks:
- [ ] Create Corporate Shared Services Hub
- [ ] Create first Brand Hub (pilot brand)
- [ ] Establish basic navigation structure
- [ ] Configure sensitivity labels
- [ ] Set up basic DLP policies

Deliverables:
- Functional hub structure
- Brand template v1.0
- Governance documentation

### Phase 2: Pilot Brand Deployment (Weeks 3-4)
**Goal**: Validate approach with pilot brand

Tasks:
- [ ] Deploy brand template to pilot brand
- [ ] Create Teams structure
- [ ] Associate Teams sites with brand hub
- [ ] Configure brand-specific navigation
- [ ] Train pilot brand users

Deliverables:
- Working brand environment
- User feedback
- Refined templates

### Phase 3: Template Refinement (Week 5)
**Goal**: Optimize based on pilot learnings

Tasks:
- [ ] Update PnP templates based on feedback
- [ ] Finalize Site Designs
- [ ] Create governance automation
- [ ] Document standard operating procedures

Deliverables:
- Brand template v2.0
- Site Designs library
- Governance runbook

### Phase 4: Multi-Brand Rollout (Weeks 6-8)
**Goal**: Deploy to remaining brands

Tasks:
- [ ] Deploy brand template to each remaining brand
- [ ] Customize per brand (logo, colors, specific content)
- [ ] Configure brand-specific Teams
- [ ] Train brand administrators

Deliverables:
- All brand hubs operational
- Brand-specific customizations
- Admin training completed

### Phase 5: Shared Services Integration (Week 9)
**Goal**: Connect brands to shared services

Tasks:
- [ ] Finalize Shared Services Hub content
- [ ] Add shared services navigation to brand hubs
- [ ] Configure cross-brand access where needed
- [ ] Implement final governance policies

Deliverables:
- Connected hub ecosystem
- Cross-brand navigation
- Final governance implementation

### Phase 6: Optimization (Week 10+)
**Goal**: Continuous improvement

Tasks:
- [ ] Monitor usage analytics
- [ ] Gather user feedback
- [ ] Optimize search and navigation
- [ ] Plan for next phase enhancements

Deliverables:
- Usage reports
- Enhancement roadmap

---

## 6. Quick Decision Reference

### Immediate Decisions Needed

| Decision | Recommendation | Timeline |
|----------|---------------|----------|
| Hub topology | Hub-per-Brand + Shared Services | Week 1 |
| Provisioning method | PnP Tenant Templates + Site Designs | Week 1 |
| Isolation strategy | Permission-based + Sensitivity Labels | Week 1 |
| Teams structure | Brand Teams + Corporate Teams | Week 2 |
| Pilot brand | Select most engaged brand | Week 2 |

### Design Decisions

| Decision | Option A | Option B | Recommendation |
|----------|----------|----------|----------------|
| Navigation depth | 2 levels | 3 levels | 2 levels (better UX) |
| News publishing | Hub only | Hub + Sites | Hub focus, site roll-up |
| Site creation | Self-service | Approval required | Governed self-service |
| External sharing | Allowed | Blocked | Blocked by default |
| Private channels | Enabled | Restricted | Restricted to owners |

---

## 7. Risk Mitigation Checklist

### Pre-Implementation Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| User adoption challenges | Medium | High | Phased rollout, training |
| Permission sprawl | High | Medium | Governance framework |
| Brand isolation failures | Low | High | Multi-layer security |
| Performance issues | Low | Medium | Hub distribution |
| Template maintenance | Medium | Low | Version control |

### Ongoing Monitoring

- [ ] Monthly: Hub site usage analytics
- [ ] Quarterly: Permission audits
- [ ] Quarterly: Security reviews
- [ ] Annually: Template effectiveness review
- [ ] Continuous: User feedback collection

---

## 8. Success Metrics

### Technical Metrics
- Site provisioning time: < 30 minutes per brand
- Navigation discoverability: > 80% task completion
- Search effectiveness: < 3 clicks to find content
- Hub performance: < 3 second page load

### Adoption Metrics
- Active users per brand: > 80% of licensed users
- Content creation: > 10 new items per user per month
- Teams engagement: > 50% active Teams users
- Self-service site creation: > 70% using templates

### Governance Metrics
- Zero unauthorized cross-brand data exposure
- 100% sites with proper sensitivity labels
- < 5% sites with unique permissions (exceptions)
- 100% compliance with retention policies

---

*Recommendations based on Microsoft Learn documentation, PnP community patterns, and multi-brand SharePoint best practices*
*Last updated: April 2025*
