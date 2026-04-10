# SharePoint Provisioning Research: Microsoft 365 Franchise/Multi-Brand Deployment

**Research ID**: web-puppy-72a06f  
**Date**: April 2025  
**Focus**: Microsoft 365 implementation for franchise/multi-brand scenarios

## Executive Summary

This research covers the key technical considerations for deploying Microsoft 365 (SharePoint Online, Teams) in a franchise or multi-brand organization. The focus is on practical implementation approaches, current limitations, and best practices for 2025.

## Key Findings Summary

### 1. SharePoint Hub Site Limits (2025)
- **2,000 hub sites per tenant** (substantial headroom)
- Sites can associate to only one hub at a time
- Navigation limit: 500 child links per level
- **Recommendation**: Hub sites are the primary architecture for multi-brand deployment

### 2. PnP Provisioning Framework
- **Current Version**: v1.18.0 (April 2025)
- **Status**: Active development, successor to PnP Sites Core
- **Recommendation**: Use for complex provisioning needs; use Site Scripts for simple scenarios

### 3. Teams Provisioning via Graph API
- **Primary Permissions**: Team.Create (recommended) or Group.ReadWrite.All
- **Approach**: Create M365 Group → Add members → Create Team → Add channels
- **SharePoint Integration**: Automatic - each team gets a linked SharePoint site

### 4. Information Barriers Assessment
- **Verdict**: Likely overkill for franchise model
- **Better Alternative**: Hub sites + permissions provide appropriate separation
- **Reserve IB for**: Compliance/regulatory requirements only

### 5. Taxonomy for Multi-Brand
- **Recommended Structure**: Hybrid approach
  - Corporate term group (shared terms)
  - Shared term group (cross-brand terms)
  - Brand-specific term groups (unique terms)
- **Content Types**: Corporate hub with brand inheritance

## Architecture Recommendations

### Hub Site Model (Primary Recommendation)

```
[Corporate Hub Site]
    ├── [Brand A Hub Site]
    │   ├── Site 1
    │   ├── Site 2
    │   └── Site 3
    ├── [Brand B Hub Site]
    │   ├── Site 1
    │   └── Site 2
    └── [Brand C Hub Site]
        └── Site 1
```

**Benefits:**
- Clear brand boundaries
- Shared navigation per brand
- Search scope inheritance
- Corporate-level aggregation possible
- Native SharePoint feature (no additional cost)

### Provisioning Strategy

**Complex Sites (with custom structure):**
- Use PnP Framework for full provisioning
- XML-based templates for consistency
- Apply via Azure Functions or PowerShell

**Standard Sites:**
- Use Site Scripts/Site Designs
- Native SharePoint integration
- Non-developer friendly

**Teams + SharePoint:**
- Graph API for batch Team creation
- Automatic SharePoint site creation
- PnP Framework for site customization

## Implementation Priorities

### Phase 1: Foundation
1. Set up Content Type Hub
2. Configure Term Store structure
3. Create corporate content types
4. Establish hub site architecture

### Phase 2: Provisioning
1. Develop PnP templates for brand sites
2. Create Site Scripts for standard sites
3. Build Teams provisioning automation
4. Document deployment procedures

### Phase 3: Governance
1. Permission model implementation
2. Term store governance
3. Content type lifecycle management
4. Monitoring and reporting

## Technical Limits to Consider

| Resource | Limit |
|----------|-------|
| Hub sites per tenant | 2,000 |
| Sites per organization | 2,000,000 |
| Sites per hub | No explicit limit |
| Navigation links | 500 per level |
| Term store terms | 1,000,000 |
| Content types per site | Not limited by architecture |

## Cost Considerations

### Licensing
- **SharePoint Online**: Included in M365 Business/Enterprise
- **Teams**: Included in M365 Business/Enterprise
- **Information Barriers**: May require E5 or compliance SKUs
- **PnP Framework**: Open source (free)

### Infrastructure
- **PnP Provisioning**: May require Azure Functions/App Service (~$10-50/month)
- **Graph API**: No additional cost (throttling applies)
- **Site Scripts**: Native (no cost)

## Files in This Research

```
./research/sharepoint-provisioning/
├── README.md (this file)
├── sources.md (source credibility assessment)
├── analysis.md (multi-dimensional analysis)
├── recommendations.md (project-specific recommendations)
└── raw-findings/
    ├── sharepoint-limits.md
    ├── pnp-framework.md
    ├── teams-graph-api.md
    ├── site-designs-scripts.md
    ├── information-barriers.md
    └── taxonomy-content-types.md
```

## Next Steps

1. Review findings with stakeholders
2. Validate architecture against specific franchise requirements
3. Develop proof of concept for hub site model
4. Create detailed provisioning scripts
5. Establish governance procedures

## Questions for Stakeholders

1. How many brands/franchises will be deployed?
2. What level of separation is required between brands?
3. Are there compliance/regulatory requirements?
4. What is the budget for custom development?
5. Who will manage ongoing governance?

---

**Research conducted by**: Web-Puppy (web-puppy-72a06f)  
**Sources**: Official Microsoft documentation, GitHub repositories, Microsoft Learn  
**Confidence Level**: High (based on authoritative sources)
