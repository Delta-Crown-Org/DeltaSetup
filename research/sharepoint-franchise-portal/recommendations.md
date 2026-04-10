# Recommendations: SharePoint Franchise Portal Implementation

## Executive Summary

This document provides actionable recommendations for implementing a secure, personalized franchise portal in SharePoint based on comprehensive research of Microsoft's identity, security, and collaboration platforms. The recommendations are tailored for the Delta Crown Extensions (DCE) / Head to Toe Brands (HTT) cross-tenant scenario.

### Current Context
- **Source Tenant**: HTT Brands (httbrands.com) - Corporate
- **Target Tenant**: Delta Crown Extensions (deltacrown.com) - Franchise operations
- **Sync Method**: Cross-tenant synchronization (member-type accounts) - Already implemented
- **Infrastructure**: SharePoint Online, Microsoft 365 Groups, Teams

---

## Priority 1: Hub Site Architecture (High Priority)

### Recommendation: Implement Hub-and-Spoke Model

**Architecture Overview:**
```
┌─────────────────────────────────────────┐
│     CORPORATE HUB (Head to Toe)         │
│  • Navigation consistency               │
│  • Corporate news & announcements       │
│  • Cross-franchise resources            │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       │               │
┌──────▼──────┐  ┌─────▼─────────┐
│ Franchise 1 │  │  Franchise 2  │
│   (Spoke)   │  │    (Spoke)    │
│             │  │               │
│ Operations  │  │  Operations   │
│ Team Site   │  │  Team Site    │
└─────────────┘  └───────────────┘
```

**Key Points:**
- Hub sites provide **shared navigation and branding** but do NOT enforce permissions
- Each franchise spoke site maintains **independent permission control**
- Cross-tenant synced users (from HTT) can access DCE resources as **member-type accounts**

**Implementation Steps:**
1. Create communication site for Corporate Hub
2. Register as Hub site in SharePoint Admin Center
3. Configure hub navigation with franchise-wide resources
4. Associate franchise location sites to hub
5. Do NOT rely on hub for security boundaries

**Why This Fits Your Context:**
- Already using cross-tenant sync (member accounts)
- Need consistent navigation across franchise network
- Require site-level autonomy for each location

---

## Priority 2: Permission Architecture (Critical Priority)

### Recommendation: Layered Permission Model

**Three-Tier Security Model:**

#### Tier 1: Organization Level (Tenant-wide)
| Setting | Value | Reasoning |
|---------|-------|-----------|
| External Sharing | Existing guests only | Franchise partners already synced |
| Domain Allow List | httbrands.com, deltacrown.com | Restrict to known domains |
| Guest Access | Disabled (not needed) | Using member sync instead |

#### Tier 2: Site Level (Per Franchise)
| Permission Group | Membership | Access |
|-----------------|------------|--------|
| Site Owners | DCE admins + HTT IT | Full control |
| Site Members | Franchise location staff | Contribute |
| Site Visitors | Read-only users | Read |

#### Tier 3: Content Level (Document/Folder)
| Content Type | Permission | Method |
|-------------|------------|--------|
| Standard ops docs | Inherited | Default |
| Confidential franchisor docs | Break inheritance | Direct permissions |
| Financial reports | HTT executives only | Specific user/group |

**Implementation:**
```powershell
# Site-level: Use M365 Group for automatic membership
# Document-level: Break inheritance for confidential items

# Break inheritance example via PnP PowerShell:
Set-PnPListItemPermission -List "Documents" `
  -Identity $itemId `
  -InheritPermissions:$false `
  -User "c-schaefer@httbrands.com" `
  -AddRole "Full Control"
```

**Critical Note:** Hub sites do NOT propagate permissions to spoke sites. Each site must be secured independently.

---

## Priority 3: Dynamic Groups for Franchise Segmentation (High Priority)

### Recommendation: Implement Attribute-Based Dynamic Groups

**Group Strategy:**

| Group Name | Membership Rule | Purpose |
|-----------|----------------|---------|
| `DCE-All-Franchisees` | `user.companyName -eq "Delta Crown Extensions"` | All franchise users |
| `DCE-Operations` | `user.department -eq "Operations"` | Operations team |
| `DCE-Leadership` | `user.jobTitle -contains "Director" -or user.jobTitle -contains "Manager"` | Leadership |
| `DCE-Corporate-Only` | `user.userPrincipalName -endsWith "@httbrands.com"` | HTT corporate staff |

**Required Entra ID Attributes:**
Ensure these attributes are populated in HTT tenant and synced to DCE:
- `companyName`: "Delta Crown Extensions"
- `department`: "Operations", "Finance", "Marketing"
- `jobTitle`: Role-based titles
- `physicalDeliveryOfficeName`: Franchise location
- `state`: Geographic region

**Implementation:**
```powershell
# Example: Create dynamic group for franchise operations
New-AzureADMSGroup `
  -DisplayName "DCE-Franchise-Operations" `
  -Description "All DCE franchise operations staff" `
  -MailEnabled $false `
  -SecurityEnabled $true `
  -GroupTypes "DynamicMembership" `
  -MembershipRule '(user.companyName -eq "Delta Crown Extensions") -and (user.department -eq "Operations")' `
  -MembershipRuleProcessingState "On"
```

**Why Dynamic Groups:**
- Automatic membership updates
- Scales to hundreds of franchise locations
- Reduces manual administration
- Consistent with cross-tenant sync automation

---

## Priority 4: Audience Targeting Implementation (Medium Priority)

### Recommendation: Multi-Tier Content Targeting

**Targeting Hierarchy:**

#### Level 1: Corporate Portal (All Users)
- **Content**: Company news, policies, benefits
- **Target**: All DCE users (Tenant-wide)
- **Method**: No targeting (default visible)

#### Level 2: Franchise Network (Franchise Users)
- **Content**: Operations manuals, training, support
- **Target**: `DCE-All-Franchisees` M365 Group
- **Method**: Hub navigation targeting

#### Level 3: Location-Based (Regional)
- **Content**: Regional events, local contacts, state-specific procedures
- **Target**: Dynamic group by `user.state`
- **Method**: Page section targeting

#### Level 4: Role-Based (Management)
- **Content**: Management resources, confidential docs
- **Target**: `DCE-Leadership` group
- **Method**: Document library targeting

**Implementation Steps:**
1. Configure M365 Groups (see Priority 3)
2. Wait 24-48 hours for groups to sync to SharePoint
3. Navigate to hub site → Settings → Hub site settings
4. Configure navigation with audience targeting
5. Test with different user personas

**Limitations to Note:**
- Maximum 10 audience targets per navigation item
- Groups must be M365 or Security groups (not distribution lists)
- Dynamic groups update near real-time, but SharePoint cache may delay visibility

---

## Priority 5: Sensitivity Labels for Content Protection (High Priority)

### Recommendation: 4-Tier Classification System

**Label Structure:**

| Label | Description | Protection | Use Case |
|-------|-------------|------------|----------|
| **Internal** | General franchise content | Header/footer marking | Operations manuals, marketing |
| **Franchise Confidential** | Franchise-specific, no external | Encryption + watermark | Franchise agreements, local procedures |
| **Corporate Confidential** | HTT corporate only | Encryption + restricted permissions | Financials, strategic plans |
| **Highly Confidential** | Executive/Board only | Encryption + view only + no copy/print | M&A, legal, HR investigations |

**Configuration:**

```powershell
# Label policy - Auto-apply to SharePoint libraries
# Create labels in Microsoft Purview compliance center

# Example: Franchise Confidential label settings:
- Content marking: Header "CONFIDENTIAL - FRANCHISE INTERNAL"
- Watermark: "CONFIDENTIAL - [USERNAME] - [DATE]"
- Encryption: User-defined permissions
- External sharing: Blocked
- Offline access: 30 days
```

**Container Labels (Sites/Teams):**
- Apply to franchise site collections
- Controls external sharing settings
- Manages guest access
- Enforces authentication context

**Implementation Priority:**
1. Create labels in Purview compliance center
2. Publish to DCE users
3. Configure auto-labeling policies
4. Train franchise users
5. Monitor label usage reports

---

## Priority 6: Conditional Access Refinement (Medium Priority)

### Recommendation: Franchise-Specific CA Policies

**Leverage existing cross-tenant trust (already configured):**
- MFA trust from HTT → DCE configured ✓
- Device compliance trust configured ✓
- Hybrid join trust configured ✓

**Recommended Policies for Franchise Scenario:**

#### Policy 1: Require Compliant Device for Confidential Access
```
Name: "CA-DCE-Confidential-DeviceRequired"
Users: DCE-Leadership group
Cloud Apps: SharePoint Online, Exchange Online
Conditions: None
Grant: Require device compliance OR Hybrid Azure AD joined
State: Report-only → Enable after validation
```

#### Policy 2: Block Legacy Authentication
```
Name: "CA-DCE-BlockLegacyAuth"
Users: All users
Cloud Apps: All cloud apps
Conditions: Client apps = Exchange ActiveSync, Other clients
Grant: Block access
State: Enabled
```

#### Policy 3: Location-Based for Sensitive Operations
```
Name: "CA-DCE-HighRiskLocation-MFA"
Users: DCE-All-Franchisees
Cloud Apps: SharePoint Online
Conditions: 
  - Location = Any location EXCEPT trusted locations
  - Sign-in risk = High
Grant: Require MFA, Block access (if high risk)
State: Report-only → Enable after validation
```

**Trusted Locations:**
- Define franchise office IP ranges
- Mark as trusted in Conditional Access
- Apply reduced restrictions for trusted locations

---

## Priority 7: Multi-Tenant Optimization (Ongoing)

### Recommendation: Leverage Cross-Tenant Sync Advantages

**You're Already Using the Best Practice:**
Cross-tenant sync (member accounts) is **preferred** over B2B guest collaboration for franchise scenarios.

**Benefits You're Getting:**
- No "External" badges in Teams/SharePoint
- Full search capabilities
- Full Teams feature access
- Native user experience
- Better Conditional Access integration

**Optimization Actions:**

#### 1. Automatic Redemption (Verify Configuration)
Ensure automatic redemption is enabled in both tenants:
- HTT (source): Outbound trust with automatic redemption
- DCE (target): Inbound trust with automatic redemption

#### 2. Attribute Sync Optimization
Review sync attribute mappings:
```json
// From your existing config: sync-attribute-mappings.json
// Ensure franchise-relevant attributes are mapped:
{
  "sourceAttribute": "companyName",
  "targetAttribute": "companyName"
},
{
  "sourceAttribute": "department",
  "targetAttribute": "department"
},
{
  "sourceAttribute": "physicalDeliveryOfficeName",
  "targetAttribute": "physicalDeliveryOfficeName"
}
```

#### 3. Sensitivity Label Consistency
If HTT uses sensitivity labels:
- Use consistent label names across tenants
- Share label configurations
- Consider unified label taxonomy

---

## Priority 8: Monitoring and Governance (Ongoing)

### Recommendation: Establish Ongoing Oversight

**Access Reviews:**
| Scope | Frequency | Reviewers |
|-------|-----------|-----------|
| Franchise Leadership | Quarterly | HTT executives |
| Franchise Operations | Bi-annually | Operations managers |
| Cross-tenant sync | Annually | IT administrators |

**Audit Monitoring:**
- Sign-in logs: Monitor failed attempts from franchise users
- Audit logs: Track permission changes on confidential docs
- Label usage: Review sensitivity label application
- CA insights: Analyze policy impact

**Metrics to Track:**
- Time to provision new franchise user: Target <4 hours
- Access review completion rate: Target >95%
- Sensitivity label coverage: Target >90% confidential docs
- Support tickets per franchise: Track trends

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Configure Corporate Hub site
- [ ] Establish site creation standards
- [ ] Document permission model
- [ ] Configure base Conditional Access policies

### Phase 2: Identity & Access (Weeks 3-4)
- [ ] Populate Entra ID attributes for franchise users
- [ ] Create dynamic groups
- [ ] Test group membership rules
- [ ] Verify cross-tenant sync attributes

### Phase 3: Content Protection (Weeks 5-6)
- [ ] Create sensitivity labels
- [ ] Publish labels to users
- [ ] Configure auto-labeling
- [ ] Train franchise users

### Phase 4: Personalization (Weeks 7-8)
- [ ] Implement audience targeting
- [ ] Configure hub navigation
- [ ] Test with pilot franchise locations
- [ ] Gather feedback and refine

### Phase 5: Optimization (Ongoing)
- [ ] Conduct access reviews
- [ ] Monitor and tune CA policies
- [ ] Refine sensitivity labels
- [ ] Scale to additional franchises

---

## Project-Specific Considerations

### Delta Crown Extensions Context

**Advantages You Have:**
1. **Cross-tenant sync already implemented** - Avoids B2B guest limitations
2. **M365 Business Premium** - Includes Entra ID P1 for Conditional Access and dynamic groups
3. **Shared mailbox strategy** - Cost-effective email solution
4. **MFA trust established** - No double-prompting for synced users

**Challenges to Address:**
1. **Synced user licensing** - Ensure DCE licenses for full features
2. **Attribute population** - HTT must maintain accurate user attributes
3. **Franchise growth** - Scale considerations for hub model
4. **Multi-location coordination** - Regional variations in procedures

**Recommendations for Your Stack:**
- Keep using cross-tenant sync (do not migrate to B2B)
- Leverage M365 Business Premium features (P1 capabilities)
- Use hub sites for 10-50 franchise locations (scale up monitoring if >50)
- Consider site collections for franchise locations needing complete isolation

---

## Success Criteria

### 30-Day Goals
- Hub site deployed with navigation
- First franchise location onboarded
- Base permissions configured
- Users can access content

### 90-Day Goals
- All current franchise locations onboarded
- Dynamic groups populating correctly
- Sensitivity labels applied to confidential content
- CA policies in production

### 180-Day Goals
- Full personalization implemented
- Access reviews completed quarterly
- <0.1 support tickets per user
- Franchisee satisfaction >4/5

---

## Conclusion

The combination of **cross-tenant synchronization**, **hub sites**, **dynamic groups**, and **sensitivity labels** provides a robust foundation for secure, personalized franchise portal experiences. The key is to leverage the member-type account benefits you already have while implementing layered security and personalization on top.

**Key Takeaways:**
1. Hub sites for navigation/branding, NOT security
2. Dynamic groups for scalable franchise segmentation
3. Document-level permissions for confidential content
4. Sensitivity labels for persistent protection
5. Cross-tenant sync is your advantage - use it fully

**Next Steps:**
1. Review recommendations with stakeholders
2. Prioritize based on franchise needs
3. Begin Phase 1 implementation
4. Establish ongoing governance processes
