# SharePoint Hub & Spoke Architecture Research

## Executive Summary

This research provides comprehensive guidance for implementing a SharePoint Hub & Spoke architecture within a multi-brand franchise scenario using Microsoft 365 Business Premium. The findings address five critical decision areas: hub site architecture best practices, multi-brand governance patterns, site provisioning automation, cross-brand security/governance, and Teams integration.

## Key Findings at a Glance

### Hub Site Architecture
- **Maximum Limits**: Up to 2,000 hub sites per tenant; ~2,000 sites per hub for search scope
- **Navigation**: Maximum 3 levels deep; recommended maximum 100 navigation links per hub
- **Sites Web Part**: Maximum 99 sites displayable
- **Key Principle**: Hub sites model relationships as links (not hierarchy/ownership), enabling dynamic organizational change

### Multi-Brand Governance Recommendation
**Recommended Pattern**: **Hub-per-Brand with Shared Services Hub**

Rather than a single master hub or nested hub architecture, each franchise brand should have its own hub for brand-specific content and collaboration, with a separate Corporate/Shared Services hub for cross-brand resources (HR, IT, Finance, Training).

**Rationale**:
- Provides brand autonomy and distinct branding
- Enables proper search scoping per brand
- Allows franchise-specific navigation structures
- Supports information barriers where needed
- Maintains shared corporate services accessibility

### Site Provisioning Recommendation
**Primary Approach**: **PnP Provisioning Engine with Tenant Templates**

For repeatable "brand template" deployments:
- Use PnP Tenant Templates for complete brand packages (SharePoint sites + Teams + structure)
- Combine with SharePoint Site Designs for user self-service creation
- Use Microsoft Graph API for programmatic operations

### Security & Governance
- **Permissions**: Hub sites do NOT alter associated site permissions - this is critical for multi-brand isolation
- **Information Barriers**: Available but support only two-way restrictions; requires Microsoft 365 E5 or compliance add-ons (NOT included in Business Premium)
- **Sensitivity Labels**: Available in Business Premium for content classification
- **DLP Policies**: Can be scoped per brand using location filters

### Teams Integration
- Every Teams team creates an underlying SharePoint site
- Hub sites can include Teams-connected sites in their navigation
- Private channels create separate SharePoint sites with independent permissions

## Research Structure

```
./research/sharepoint-hub-spoke/
├── README.md (this file)
├── sources.md (Source credibility assessment)
├── analysis.md (Multi-dimensional analysis)
├── recommendations.md (Project-specific recommendations)
└── raw-findings/ (Extracted content from sources)
```

## Quick Decision Matrix

| Decision Factor | Recommendation | Notes |
|----------------|----------------|-------|
| Hub Topology | Hub-per-Brand + Shared Services | Avoid nested hubs |
| Brand Isolation | Permission-based + Sensitivity Labels | Information Barriers require E5 |
| Site Provisioning | PnP Tenant Templates | Supports Teams + SharePoint |
| Teams Integration | Connect to brand hubs | Leverage existing Teams structure |
| Navigation Depth | Max 2 levels for usability | Hub → Brand Hub → Sites |

## Critical Constraints

1. **M365 Business Premium Limitations**:
   - No Information Barriers (requires E5 or compliance add-on)
   - Limited to 300 users maximum per tenant
   - No Multi-Geo capabilities

2. **Hub Site Limitations**:
   - No built-in permission inheritance from hub to associated sites
   - News and activities roll UP to hub, not down to associated sites
   - Site can only be associated with ONE hub at a time
   - Cannot associate extranet sites if shared navigation visibility is a concern

## Next Steps for Implementation

See [recommendations.md](./recommendations.md) for detailed implementation guidance, phased rollout strategy, and governance framework templates.

---

*Research conducted: April 2025*
*Sources: Microsoft Learn, PnP Community, Microsoft 365 Architecture Center*
