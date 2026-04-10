# Information Barriers in Microsoft 365

Source: https://learn.microsoft.com/en-us/purview/information-barriers

## Overview

Microsoft Purview Information Barriers (IB) is a compliance solution that restricts two-way communication and collaboration between groups and users in Microsoft Teams, SharePoint, and OneDrive.

## Primary Use Cases

Information Barriers are designed for:
- **Highly regulated industries** (financial services, healthcare, government)
- **Conflict of interest prevention** (e.g., trading vs. advisory)
- **Safeguarding internal information** between organizational areas
- **Legal/compliance requirements** for separation of duties

## How Information Barriers Work

### Core Concept
When IB policies are created, users who can't communicate or share files with other specific users:
- Can't find or select those users
- Can't chat or call those users
- IB policies automatically put up barriers

### Affected Services

1. **Microsoft Teams**
   - Chat
   - Channel participation
   - Meeting participation
   - File sharing

2. **SharePoint and OneDrive**
   - File sharing
   - Site access
   - Content discovery

3. **Microsoft Planner**
   - Plan membership
   - Task assignment

4. **Exchange Online**
   - Email communication
   - Calendar sharing

## Policy Types

### 1. Block Policies
Prevent communication between segments:
- Segment A cannot communicate with Segment B
- Two-way blocking

### 2. Allow Policies
Explicitly allow communication between specific segments:
- Only specified segments can communicate
- All other combinations are blocked

## Configuration Requirements

### Prerequisites
- Microsoft Purview compliance center access
- M365 E5 or specific compliance licensing
- User segments defined (based on Azure AD attributes)
- Admin role: Global Administrator or Compliance Administrator

### User Segments
Segments are defined using user attributes:
- Department
- Office location
- Job title
- Custom attributes
- Group membership

## Information Barriers vs. Other M365 Isolation Methods

| Method | Level | Use Case | Complexity |
|--------|-------|----------|------------|
| **Information Barriers** | User/Group | Compliance, conflicts of interest | High |
| **Separate Teams** | Team | Natural separation | Low |
| **Private Channels** | Channel | Sensitive sub-team work | Low |
| **Separate Sites** | Site | Complete isolation | Medium |
| **Hub Sites** | Site collection | Organized separation | Medium |
| **Separate Tenants** | Tenant | Complete organizational separation | Very High |

## Is Information Barriers Appropriate for Brand Isolation?

### Assessment: Likely Overkill for Franchise Model

**Reasons IB Might Be Overkill:**
1. **Designed for compliance** - Not organizational structure
2. **Complex to manage** - Requires ongoing maintenance
3. **Restricts natural collaboration** - May hinder cross-brand cooperation
4. **Licensing requirements** - May require additional compliance SKUs
5. **Not self-service** - Requires admin intervention for changes

### Better Alternatives for Brand Isolation

#### Option 1: Hub Site Architecture (Recommended)
- **Each brand gets a hub site**
- **Associated sites per brand** join the hub
- **Search scope inheritance** keeps brand content discoverable within brand
- **Shared navigation** at hub level
- **Simple governance** - built into SharePoint

**Benefits:**
- Native SharePoint feature
- Easy to manage
- Supports both separation AND collaboration
- No additional licensing

#### Option 2: Separate Site Collections per Brand
- **Each brand = separate site collection**
- **Independent permissions**
- **No search inheritance** unless explicitly configured
- **Complete separation**

**Benefits:**
- True isolation
- Simple permission model
- Can still be searched across if needed

#### Option 3: Teams + SharePoint Separation
- **Each brand = separate Team**
- **Linked SharePoint site per Team**
- **Private channels** for sensitive areas

**Benefits:**
- Modern collaboration
- Integrated with M365
- Natural boundaries

### When Information Barriers MIGHT Be Appropriate

Consider IB if:
1. **Regulatory requirement** mandates strict separation
2. **Legal/compliance** department requires it
3. **Conflicts of interest** exist between brands
4. **Sensitive IP** must be completely isolated
5. **Audit requirements** demand IB logging

## Recommendation for Multi-Brand Deployment

**Primary Approach: Hub Sites + Permissions**

1. **Create hub sites per brand** (or brand group)
2. **Associate sites to appropriate hub**
3. **Use permission groups** to control access
4. **Separate site collections** for complete isolation needs

**Reserve Information Barriers for:**
- Specific compliance scenarios
- Legal/regulatory requirements
- Conflict of interest situations
- Not for general brand organization

## Implementation Complexity Comparison

| Approach | Setup Time | Maintenance | User Experience | Governance |
|----------|-----------|-------------|-----------------|------------|
| Information Barriers | High | High | Restrictive | Complex |
| Hub Sites | Medium | Low | Collaborative | Simple |
| Separate Sites | Low | Low | Isolated | Simple |
| Hub Sites + Permissions | Medium | Low | Balanced | Moderate |

## Summary

For a franchise/multi-brand model, **Information Barriers are likely overkill**. The simpler approach using SharePoint hub sites, separate site collections, and proper permission management will provide appropriate brand separation while maintaining usability and reducing administrative overhead.

Only implement Information Barriers if there are specific compliance or legal requirements that mandate strict user-level separation.
