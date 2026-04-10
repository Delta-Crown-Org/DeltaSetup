# Microsoft Purview Sensitivity Labels

## Source: Microsoft Learn - Sensitivity Labels
**URL**: https://learn.microsoft.com/en-us/purview/sensitivity-labels
**Credibility**: Tier 1 - Official Microsoft Documentation
**Date Retrieved**: March 2025

## Core Capabilities

### Protection Settings
- **Encryption** - Content-level encryption
- **Content markings** - Headers, footers, watermarks
- **Protection enforcement** - Download/print/copy restrictions

### Label Scopes

| Scope | Description |
|-------|-------------|
| **Files & emails** | Office documents, Outlook emails |
| **Groups & sites** | Teams, M365 Groups, SharePoint sites |
| **Meetings** | Teams meeting invites and content |
| **Azure Purview** | Data map assets (preview) |
| **Power BI** | Reports and datasets |

## Container Labels (Groups, Sites, Meetings)

### Protection for Teams, M365 Groups, and SharePoint Sites

#### Privacy Settings
- Public vs Private
- External access controls
- External sharing settings

#### Access Controls
- Unmanaged device access
- Authentication context
- Conditional Access integration

### Default Label for SharePoint Document Libraries

#### Behavior
- Automatically apply label to new files
- Extend protection on download
- Automatic or optional labeling

#### Use Case for Franchise
- All franchisor confidential docs get "Confidential" label
- Franchisee docs get "Internal" or "Franchise" label
- Automatic protection without user action

## Franchise Portal Label Strategy

### Recommended Label Hierarchy

| Label | Description | Protection |
|-------|-------------|------------|
| **Public** | Public-facing content | None |
| **Internal** | All franchisees and corporate | View only for external |
| **Franchise Confidential** | Franchise-specific, no external | Encryption, no external sharing |
| **Corporate Confidential** | Corporate only, no franchisees | Encryption, restricted access |
| **Highly Confidential** | Executive/board level | Encryption, view only, no copy/print |

### Label Policies

#### Auto-Labeling
- Pattern matching for sensitive data
- Regular expressions for keywords
- Machine learning classifiers

#### Mandatory Labeling
- Require label before save/send
- Default label suggestions
- Tooltip guidance for users

## Implementation Scenarios

### Scenario 1: Franchise Operations Manual
```
Label: Franchise Confidential
Protection: 
  - Encryption enabled
  - No external sharing
  - Watermark: "CONFIDENTIAL - [Username]"
  - No print/copy for external users
```

### Scenario 2: Financial Reports
```
Label: Corporate Confidential
Protection:
  - Encryption required
  - View only permissions
  - Expiration: 90 days
  - No offline access
```

### Scenario 3: Marketing Materials
```
Label: Internal
Protection:
  - No encryption (for ease of use)
  - Header/footer marking
  - External sharing allowed with watermark
```

## Technical Requirements

### Licensing
- Microsoft 365 E3/A3/G3 or higher
- Microsoft Purview Information Protection
- For auto-labeling: E5/A5/G5 or add-on

### Prerequisites
- Labels published to users
- Label policies configured
- Client apps updated (minimum versions)

### Client Support
- Office 365 desktop apps (latest)
- Office for the web
- Mobile apps (iOS, Android)
- SharePoint/OneDrive web

## Governance and Compliance

### Label Analytics
- Label usage reports
- Unlabeled content discovery
- Policy match reports

### eDiscovery Integration
- Search by sensitivity label
- Hold content with specific labels
- Review labeled content

### Retention Integration
- Combine with retention labels
- Different retention by sensitivity
- Auto-delete based on label

## Franchise Portal Recommendations

1. **Start Simple**
   - 3-4 labels maximum
   - Clear, business-relevant names
   - Gradual rollout

2. **Train Franchisees**
   - Label selection guidance
   - Impact of each label
   - When to override defaults

3. **Monitor and Refine**
   - Regular policy review
   - False positive/negative analysis
   - User feedback incorporation

4. **Integration with CA**
   - Authentication contexts for highly confidential
   - Block access from non-compliant devices
   - Require MFA for specific labels
