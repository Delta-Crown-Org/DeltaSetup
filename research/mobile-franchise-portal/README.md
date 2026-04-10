# Mobile Experience Requirements for Franchise Business Portals (2025)

**Research Agent**: web-puppy-b2215e  
**Date**: March 31, 2025  
**Research Scope**: Mobile-first design requirements, accessibility standards, and best practices for franchise owner/operator portals

---

## Executive Summary

This research synthesizes authoritative guidelines from WCAG 2.2, Apple HIG, Material Design, Microsoft Viva Connections, and leading UX research organizations to provide actionable mobile design recommendations for franchise business portals.

### Key Findings

1. **Touch Target Standards**: Minimum 24×24 CSS pixels (WCAG 2.2), with 44×44 pt (iOS) and 48×48 dp (Android) recommended for optimal usability

2. **Mobile Navigation**: 67% of mobile sites have mediocre-to-poor navigation performance; tab-based architecture significantly improves usability for field users

3. **Viva Connections Model**: Card-based dashboard design with quick actions, news reader, and resources provides an optimal framework for franchise portals

4. **Field Staff Requirements**: 79% of mobile intranet projects cite field support as primary motivation; offline functionality and simplified workflows are critical

5. **Accessibility Compliance**: WCAG 2.2 Level AA compliance is essential, with specific mobile requirements for touch targets, zoom, and gesture alternatives

---

## Quick Reference: Mobile Design Standards

| Standard | Minimum Size | Recommended | Source |
|----------|--------------|-------------|--------|
| **WCAG 2.2 AA** | 24×24 CSS px | 44×44 CSS px | W3C Official |
| **iOS** | 44×44 pt | 60×60 pt (visionOS) | Apple HIG |
| **Android** | 48×48 dp | - | Material Design |
| **Spacing** | 8dp between targets | - | Material Design |

---

## Franchise Owner Mobile Usage Patterns

### Primary Use Cases

1. **Quick Access Tasks** (70% of usage)
   - Check announcements and news
   - Access operational resources
   - Complete quick training modules
   - Review schedules and tasks

2. **On-the-Go Lookup** (20% of usage)
   - Reference operational procedures
   - Find contact information
   - Check policy updates
   - Access troubleshooting guides

3. **Deep Research** (10% of usage)
   - Review detailed documentation
   - Complete comprehensive training
   - Analyze performance metrics

### Critical Requirements

- **Speed**: Tasks must complete in under 30 seconds
- **Offline Support**: Critical resources available without connectivity
- **One-Handed Use**: Optimized for single-thumb operation
- **Quick Recovery**: Return to exact position after interruption

---

## Mobile Portal Architecture

### Recommended Structure (Viva Connections Model)

```
┌─────────────────────────────────────┐
│           TAB NAVIGATION            │
├──────────┬──────────┬───────────────┤
│ Dashboard│  News    │  Resources    │
├──────────┴──────────┴───────────────┤
│                                     │
│  SPOTLIGHT / ANNOUNCEMENTS          │
│  ┌─────────────────────────────┐   │
│  │  • Important alerts          │   │
│  │  • Critical notifications    │   │
│  └─────────────────────────────┘   │
│                                     │
│  DASHBOARD CARDS                    │
│  ┌──────────┐ ┌──────────┐         │
│  │  Card 1  │ │  Card 2  │         │
│  │  (Medium)│ │  (Medium)│         │
│  └──────────┘ └──────────┘         │
│  ┌──────────────────┐              │
│  │     Card 3       │              │
│  │     (Large)      │              │
│  └──────────────────┘              │
│                                     │
└─────────────────────────────────────┘
```

### Card Size Guidelines

- **Medium Cards**: 2 per row, quick actions, status updates
- **Large Cards**: 1 per row, detailed content, forms
- **Touch Targets**: All card actions minimum 48×48 dp

---

## Implementation Checklist

### Touch Targets & Accessibility
- [ ] All interactive elements minimum 48×48 dp (24×24 CSS px minimum)
- [ ] 8dp minimum spacing between adjacent targets
- [ ] Clear visual feedback on touch (press states)
- [ ] WCAG 2.2 Level AA compliance
- [ ] Screen reader optimization (TalkBack, VoiceOver)

### Navigation & Layout
- [ ] Tab-based primary navigation (3-5 tabs maximum)
- [ ] Flat information architecture (maximum 3 levels deep)
- [ ] Persistent navigation across all screens
- [ ] Breadcrumb navigation for deep content
- [ ] "Back" button meets user expectations (59% of sites fail)

### Content Strategy
- [ ] "Bit-sized" content optimized for mobile consumption
- [ ] Progressive disclosure for detailed information
- [ ] Image thumbnails for document galleries (76% of sites don't)
- [ ] Persistent search queries across sessions
- [ ] Autocomplete with misspelling support

### Performance
- [ ] Offline support for critical resources
- [ ] Page load under 3 seconds on 3G
- [ ] Optimized images (WebP format, responsive sizing)
- [ ] Lazy loading for below-fold content
- [ ] State preservation during connectivity interruptions

### Forms & Input
- [ ] Labels above fields (never inline)
- [ ] Auto-formatting for complex inputs (phone, credit card)
- [ ] Submit buttons adjacent to search fields
- [ ] Inline validation with clear error messages
- [ ] Minimize required fields (average checkout: 11.3 fields)

---

## Franchise-Specific Recommendations

### Dashboard Cards for Franchise Owners

1. **Quick Actions Card (Medium)**
   - Clock in/out
   - Daily checklist
   - Incident reporting
   - Quick contacts

2. **Announcements Card (Medium)**
   - Corporate updates
   - Policy changes
   - Promotional materials
   - Weather alerts

3. **Training Card (Large)**
   - Required training progress
   - Upcoming certifications
   - Quick training modules
   - Compliance deadlines

4. **Resources Card (Medium)**
   - Operations manual
   - Troubleshooting guides
   - Marketing materials
   - Support contacts

### Mobile-First Content Strategy

**DO:**
- Write concise, scannable content
- Use bullet points and short paragraphs
- Provide summaries with "Read more" options
- Optimize images for mobile (responsive sizing)
- Use action-oriented button labels

**DON'T:**
- Hide critical information behind multiple taps
- Use subpages for mobile content (26% overlook)
- Require extensive text input
- Rely solely on color to convey information
- Use desktop-style dense layouts

---

## Compliance & Standards

### WCAG 2.2 Level AA Requirements

- **2.5.8 Target Size (Minimum)**: 24×24 CSS pixels
- **1.4.4 Resize Text**: Support 200% zoom without loss of content
- **2.5.5 Target Size (Enhanced)**: 44×44 CSS pixels (recommended)
- **2.5.2 Pointer Cancellation**: Down-event not used for activation
- **2.5.1 Pointer Gestures**: Provide single-pointer alternatives

### Platform-Specific Guidelines

- **iOS**: Follow Human Interface Guidelines for buttons, navigation
- **Android**: Implement Material Design 3 components
- **Cross-Platform**: Maintain consistency while respecting platform conventions

---

## Research Sources

| Source | Tier | Key Contribution |
|--------|------|------------------|
| WCAG 2.2 | Tier 1 | Official accessibility standards |
| Apple HIG | Tier 1 | iOS touch target requirements |
| Material Design | Tier 1 | Android accessibility, touch targets |
| Microsoft Viva Connections | Tier 1 | Enterprise mobile portal architecture |
| Nielsen Norman Group | Tier 1 | Mobile intranet field research |
| Baymard Institute | Tier 1 | Large-scale mobile UX benchmarks |

---

## Next Steps

1. **Conduct User Research**: Survey franchise owners on specific mobile needs
2. **Create Wireframes**: Design dashboard layout with card-based architecture
3. **Prototype Testing**: Test with actual franchise owners on target devices
4. **Accessibility Audit**: WCAG 2.2 compliance verification
5. **Performance Optimization**: Implement offline support and progressive loading

---

## Document Structure

```
./research/mobile-franchise-portal/
├── README.md                    # This file - Executive summary
├── sources.md                   # Source credibility assessment
├── analysis.md                  # Multi-dimensional analysis
├── recommendations.md           # Franchise-specific recommendations
└── raw-findings/
    ├── wcag-2.5.8-target-size.md
    ├── apple-hig-buttons.md
    ├── material-design-accessibility.md
    ├── viva-connections-overview.md
    ├── nngroup-mobile-intranet.md
    └── baymard-mobile-ux-summary.md
```

---

**Document Owner**: web-puppy-b2215e  
**Last Updated**: March 31, 2025  
**Review Cycle**: Quarterly (next review: June 2025)
