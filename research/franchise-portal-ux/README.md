# Franchise Portal UX Research - Executive Summary

**Research ID**: web-puppy-3e7ada  
**Date**: January 2025  
**Project Context**: SharePoint-based franchise portal for multi-tenant architecture (Head To Toe Brands / Delta Crown Extensions)

## Research Scope

This comprehensive research examines franchise portal UX best practices for 2025, with specific focus on SharePoint-based implementations in multi-location franchise environments. The research synthesizes findings from authoritative sources including Nielsen Norman Group, Microsoft Learn, and industry best practices.

## Key Findings Overview

### 1. Franchise Portal Design Patterns
- **Hub-and-spoke architecture** is the dominant pattern for multi-location franchise operations
- **Shared navigation + localized content** balances brand consistency with location-specific needs
- **Mobile-first design** essential for franchisees who work in the field
- **Progressive disclosure** reduces cognitive load while maintaining access to deep resources

### 2. Hub-and-Spoke Navigation Models
- Microsoft SharePoint's **hub site architecture** perfectly models hub-and-spoke patterns
- **3-level navigation depth** maximum recommended for usability
- **100-site practical limit** per hub for performance and UX
- **Association model** (not hierarchy) enables flexible reorganization

### 3. Success Patterns vs. Failures
- **Success factors**: Executive sponsorship, clear governance, user-centered design, mobile focus
- **Failure patterns**: Over-engineering, lack of franchisee involvement, desktop-only design
- **Key metrics**: Task completion rates, mobile usage, content freshness, franchisee satisfaction

### 4. Franchisee Personas
- **Time-constrained operators** who need quick access to operational resources
- **Mobile-first users** accessing portal while managing locations
- **Mixed technical proficiency** requiring intuitive, task-focused interfaces
- **Pain points**: Finding current documents, training access, communication fragmentation

## SharePoint-Specific Recommendations

### Immediate Actions (Phase 1)
1. **Establish hub architecture** with Home Site as franchisor hub
2. **Create communication sites** for brand resources and training
3. **Deploy team sites** for franchisee collaboration
4. **Configure mobile access** via SharePoint mobile app

### Short-term (Phase 2)
1. **Implement hub navigation** for consistent wayfinding
2. **Enable news aggregation** across franchise locations
3. **Set up audience targeting** for role-based content
4. **Deploy Viva Engage** for franchisee community

### Long-term (Phase 3)
1. **Multi-geo deployment** if international expansion
2. **Advanced analytics** and usage monitoring
3. **Workflow automation** for approvals and processes
4. **Power BI integration** for performance dashboards

## Critical Success Factors

1. **Franchisee involvement** in design and content creation
2. **Mobile-first approach** - most access will be mobile/tablet
3. **Just-in-time resources** - training and support when needed
4. **Clear governance** - rules before tools
5. **Continuous feedback** - iterate based on usage data

## Project Context Alignment

This research directly supports the Delta Crown Extensions / Head To Toe Brands multi-tenant architecture:

- **HTT Brands** (franchisor) = Hub with central resources
- **DCE** (franchisee) = Associated site with shared navigation
- **Cross-tenant sync** enables member-type access (not guest)
- **SharePoint hub sites** provide the hub-and-spoke model
- **Mobile access** supports field-based franchise operations

## Documentation Structure

- `design-patterns.md` - Franchise portal UX patterns and best practices
- `hub-spoke-navigation.md` - Enterprise hub-and-spoke IA patterns
- `case-studies.md` - Success patterns and failure analysis
- `franchisee-personas.md` - User personas, needs, and workflows
- `recommendations.md` - SharePoint-specific implementation recommendations
- `sources.md` - Complete source list with credibility assessments
- `raw-findings/` - Extracted content from authoritative sources

## Research Methodology

Sources evaluated using tier system:
- **Tier 1**: Official documentation, academic research, primary sources
- **Tier 2**: Established industry publications, expert blogs
- **Tier 3**: Community forums, case studies
- **Tier 4**: General articles, opinion pieces

All findings cross-referenced for validation.
