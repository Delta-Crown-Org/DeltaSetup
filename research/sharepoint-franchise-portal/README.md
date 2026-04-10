# SharePoint Franchise Portal: Identity-Driven Personalization & Security

**Research Date**: March 2025  
**Researcher**: Web-Puppy (ID: web-puppy-15ce3f)  
**Project Context**: Delta Crown Extensions (DCE) / Head to Toe Brands (HTT) Cross-Tenant Collaboration

---

## Executive Summary

This research provides comprehensive analysis and recommendations for implementing secure, personalized SharePoint franchise portals using Microsoft's identity and security infrastructure. The research covers SharePoint audience targeting, access control, multi-tenant considerations, and conditional access - all contextualized for a franchise business model.

### Key Findings

1. **Cross-tenant synchronization (member-type accounts) is the optimal approach** for franchise scenarios, providing native user experience without B2B guest limitations

2. **Hub sites provide navigation consistency but NOT security boundaries** - spoke sites maintain independent permission control

3. **Dynamic groups based on Entra ID attributes** enable scalable franchise segmentation without manual administration

4. **Sensitivity labels with container protection** provide persistent content classification across tenant boundaries

5. **Conditional Access policies** can be tailored to franchise scenarios including location-based and device compliance requirements

---

## Research Structure

```
research/sharepoint-franchise-portal/
├── README.md                          # This file - Executive summary
├── sources.md                         # Source credibility assessment
├── analysis.md                        # Multi-dimensional analysis
├── recommendations.md                 # Actionable recommendations
└── raw-findings/                      # Detailed research notes
    ├── sharepoint-permissions-model.md
    ├── entra-b2b-collaboration.md
    ├── conditional-access-location.md
    ├── sensitivity-labels.md
    ├── user-profiles-personalization.md
    └── multi-tenant-limitations.md
```

---

## Quick Reference: Franchise Portal Architecture

### Recommended Architecture

```
┌─────────────────────────────────────────────────────────┐
│              HEAD TO TOE BRANDS (Source)                 │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Entra ID User Attributes                       │    │
│  │  • companyName: "Delta Crown Extensions"        │    │
│  │  • department: "Operations"                     │    │
│  │  • jobTitle: "Franchise Manager"                │    │
│  │  • state: "CA"                                  │    │
│  └────────────────────┬────────────────────────────┘    │
│                       │                                  │
│           Cross-Tenant Sync (Member accounts)            │
│                       │                                  │
└───────────────────────┼──────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│           DELTA CROWN EXTENSIONS (Target)                │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Dynamic Groups                                   │  │
│  │  • DCE-All-Franchisees (companyName-based)        │  │
│  │  • DCE-Operations (department-based)              │  │
│  │  • DCE-Leadership (jobTitle-based)                │  │
│  └─────────────────────┬─────────────────────────────┘  │
│                        │                                 │
│  ┌─────────────────────▼─────────────────────────────┐  │
│  │           SharePoint Hub Site                     │  │
│  │        "Corporate Franchise Portal"               │  │
│  │  • Shared navigation                              │  │
│  │  • Corporate news & announcements                 │  │
│  │  • Audience-targeted navigation                   │  │
│  └──────────┬──────────────────────┬─────────────────┘  │
│             │                      │                    │
│  ┌──────────▼────────┐  ┌──────────▼────────┐           │
│  │ Franchise Site 1  │  │ Franchise Site 2  │           │
│  │   (Spoke Site)    │  │   (Spoke Site)    │           │
│  │                   │  │                   │           │
│  │ Independent       │  │ Independent       │           │
│  │ permissions       │  │ permissions       │           │
│  │ Sensitivity       │  │ Sensitivity       │           │
│  │ labels applied    │  │ labels applied    │           │
│  └───────────────────┘  └───────────────────┘           │
└─────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### 1. SharePoint Audience Targeting
- **Navigation targeting** based on M365 Group membership
- **Content targeting** for pages and web parts
- **Requirements**: Groups must sync to SharePoint (24-48 hours)
- **Limitations**: Max 10 audiences per item

### 2. Access Control & Permissions
- **Hub sites**: Navigation/branding only, no permission inheritance
- **Spoke sites**: Independent permission control
- **M365 Groups**: Automatic membership for team sites
- **Dynamic groups**: Attribute-based, near real-time updates

### 3. Multi-Tenant Considerations
- **Cross-tenant sync**: Member accounts, best experience
- **B2B collaboration**: Guest accounts, limited experience
- **Limitations**: No cross-tenant search, no hub association across tenants
- **Security**: Conditional Access applies to both

### 4. Conditional Access
- **Location-based**: Define trusted franchise office IPs
- **Device compliance**: Require managed devices for confidential access
- **Risk-based**: Block high-risk sign-ins automatically
- **Integration**: Works with both member and guest accounts

---

## Project Context: DCE/HTT Implementation

### Current State
- ✅ Cross-tenant sync implemented (member-type accounts)
- ✅ MFA trust established (no double-prompting)
- ✅ M365 Business Premium licensing (includes P1)
- ✅ Shared mailbox strategy for @deltacrown.com email

### Recommended Next Steps

1. **Week 1-2**: Deploy Corporate Hub site with navigation
2. **Week 3-4**: Create dynamic groups based on user attributes
3. **Week 5-6**: Implement sensitivity labels for content protection
4. **Week 7-8**: Configure audience targeting for personalization
5. **Ongoing**: Access reviews, monitoring, optimization

See [recommendations.md](recommendations.md) for detailed implementation guidance.

---

## Source Reliability Summary

| Tier | Sources | Assessment |
|------|---------|------------|
| **Tier 1** | Microsoft Learn (11 sources) | Official documentation, highest reliability |
| **Tier 2** | Microsoft Support (1 source) | Official support content, high reliability |
| **Total** | 12 primary sources | All authoritative, current as of March 2025 |

All sources verified for:
- ✅ Currency (2024-2025 documentation)
- ✅ Authority (Official Microsoft)
- ✅ Validation (Cross-referenced multiple sources)
- ✅ Relevance (Directly applicable to franchise scenarios)

---

## Key Recommendations Summary

### High Priority
1. **Use hub sites for navigation/branding** (NOT security)
2. **Implement dynamic groups** for scalable franchise segmentation
3. **Deploy sensitivity labels** for persistent content protection
4. **Leverage cross-tenant sync advantages** (already implemented)

### Medium Priority
5. **Configure Conditional Access** for device/location policies
6. **Implement audience targeting** for personalized experiences
7. **Establish access reviews** for ongoing governance

### Ongoing
8. **Monitor and optimize** based on usage patterns
9. **Scale to additional franchise locations**
10. **Refine based on franchisee feedback**

---

## Technical Requirements

### Licensing
- Microsoft 365 Business Premium (or E3/E5) - for P1 features
- Microsoft Entra ID P1 - for Conditional Access and dynamic groups
- Microsoft Purview Information Protection - for sensitivity labels

### Administrative Roles Required
- SharePoint Administrator
- Global Administrator (or Privileged Role Administrator)
- Compliance Administrator (for sensitivity labels)
- Security Administrator (for Conditional Access)

### Prerequisites
- Cross-tenant access settings configured
- User attributes populated in source tenant
- SharePoint Online environment provisioned
- Microsoft 365 Groups enabled

---

## Limitations & Considerations

### Known Limitations
1. **No cross-tenant hub association** - Spoke sites must be in same tenant as hub
2. **Max 10 audience targets** per navigation item
3. **Dynamic group evaluation delay** - May take minutes for membership updates
4. **Cross-tenant search** - Not available; search is tenant-scoped
5. **Guest experience limitations** - Avoid B2B guests for franchise (use sync instead)

### Scalability Considerations
- Hub sites: Up to 2,000 per tenant
- Sites per hub: Up to 1,000 (monitor navigation performance)
- Dynamic groups: Up to 5,000 per tenant
- Group members: Soft limit ~50,000 for performance

---

## Research Methodology

This research followed the Web-Puppy methodology:

1. **Project Exploration**: Analyzed existing DCE/HTT documentation
2. **Information Gathering**: Retrieved content from 12 authoritative Microsoft sources
3. **Source Evaluation**: All sources rated Tier 1 (Official Documentation)
4. **Multi-Dimensional Analysis**: Security, cost, complexity, stability, compatibility
5. **Project Contextualization**: Tailored recommendations to DCE/HTT scenario
6. **Structured Documentation**: Created organized, actionable deliverables

---

## Contact & Updates

**Research Agent**: Web-Puppy (web-puppy-15ce3f)  
**Date**: March 2025  
**Status**: Complete

For updates, verify against:
- Microsoft 365 Roadmap: https://www.microsoft.com/en-us/microsoft-365/roadmap
- SharePoint Blog: https://techcommunity.microsoft.com/t5/sharepoint-blog/bg-p/SharePointBlog
- Entra ID Blog: https://techcommunity.microsoft.com/t5/microsoft-entra-blog/bg-p/Identity

---

## Document Versions

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | March 2025 | Initial research complete |

---

*This research was conducted using authoritative Microsoft documentation and best practices for enterprise SharePoint implementations in franchise scenarios.*
