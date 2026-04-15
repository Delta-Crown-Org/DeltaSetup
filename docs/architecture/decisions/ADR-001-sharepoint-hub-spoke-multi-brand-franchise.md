# ADR-001: SharePoint Hub & Spoke Architecture for Multi-Brand Franchise Ecosystem

| Field | Value |
|-------|-------|
| **Status** | Proposed |
| **Date** | 2025-04-22 |
| **Decision Makers** | Solutions Architect (solutions-architect-7f7af3) |
| **Security Co-Sign** | Security Auditor (security-auditor) — CONDITIONAL APPROVAL |
| **Consulted** | Web-Puppy (research), Experience Architect (UX contracts) |

---

## Context and Problem Statement

Delta Crown Extensions (DCE) is the first "template brand" being deployed on a Corporate Microsoft 365 tenant with Business Premium licenses. The architecture vision is:

```
Corporate M365 → Framework Layer → Brand Instance
```

The Email Trust Framework (SPF/DKIM/DMARC) is already deployed and verified. We are now at **Week 2: Collaboration + Email** — requiring Teams, SharePoint & brand email configuration.

**The core question**: How should we structure the SharePoint Hub & Spoke topology to support Delta Crown as the first brand, while creating a repeatable template for rapid onboarding of future brands (Bishops, Frenchies, HTT & TLL) within 2-week deployment windows?

### Constraints
- **M365 Business Premium**: 300-user maximum, NO Information Barriers
- **Single Tenant**: All brands share one M365 tenant
- **Zero Incremental Cost**: Must use existing licensing
- **14-Day Brand Deployment**: Each subsequent brand must deploy in ≤2 weeks
- **Brand Isolation**: Competing franchise brands must not access each other's data

---

## Decision Drivers

1. **Brand Autonomy**: Each franchise brand needs independent navigation, search, branding, and content without interference from other brands
2. **Template Repeatability**: The architecture must support cloning for 2-week brand deployments
3. **Security Isolation**: Brand data must be isolated despite sharing a single tenant (without Information Barriers)
4. **Zero Incremental Cost**: No license upgrades beyond existing Business Premium
5. **Governance at Scale**: Corporate must maintain oversight while brands operate independently
6. **User Experience**: Brand employees should experience a branded, cohesive workspace
7. **Operational Simplicity**: Small IT team must manage multiple brands without excessive overhead

---

## Considered Options

### Option A: Single Corporate Hub (All Brands as Associated Sites)

```
Corporate Hub
├── Delta Crown Operations (Team Site)
├── Delta Crown Comms (Communication Site)
├── Bishops Operations (Team Site)
├── Bishops Comms (Communication Site)
├── Frenchies Operations (Team Site)
└── [... all brands mixed]
```

**Pros**:
- Simplest to set up and manage
- Single navigation hierarchy
- Unified search across all brands
- Minimal administrative overhead

**Cons**:
- ❌ No brand-specific navigation — all brands share one navigation bar
- ❌ Search results leak across brands (search scope = entire hub)
- ❌ No brand-specific theming at hub level
- ❌ Navigation becomes unmanageable at 20+ sites
- ❌ Violates brand autonomy requirement
- ❌ Cannot support brand-specific news rollup

**ATAM Score**: 3/10 — Fails brand autonomy and isolation requirements

### Option B: Hub-per-Brand with Shared Services Hub (RECOMMENDED)

```
Corporate Shared Services Hub (Communication Site)
├── HR Policies (Team Site)
├── IT Knowledge Base (Team Site)
├── Finance Shared (Team Site)
└── Training & Onboarding (Team Site)

Delta Crown Hub (Communication Site — branded)
├── DCE Operations (Team Site — Teams-connected)
├── DCE Client Services (Team Site)
├── DCE Marketing (Communication Site)
└── DCE [Location Sites as needed]

Bishops Hub (Communication Site — branded)
├── Bishops Operations (Team Site — Teams-connected)
└── [Brand-specific sites]

[Additional Brand Hubs follow same template]
```

**Pros**:
- ✅ Each brand gets independent navigation, search scope, and theming
- ✅ Hub search is scoped to brand sites only
- ✅ News rollup is brand-specific by default
- ✅ Clear governance boundaries per brand
- ✅ Shared Services Hub provides cross-brand corporate functions
- ✅ Template can be cloned for 2-week deployments via PnP
- ✅ Hub limit is 2,000 per tenant — scales to hundreds of brands
- ✅ Brand employees see only their brand in navigation

**Cons**:
- ⚠️ More hub sites to manage (N brands + 1 corporate = N+1 hubs)
- ⚠️ No single "all brands" view without a portal page
- ⚠️ Shared services navigation must be manually added to each brand hub

**ATAM Score**: 9/10 — Best balance of autonomy, isolation, and template repeatability

### Option C: Separate M365 Tenants per Brand

```
Corporate Tenant (HTT Brands)
├── Corporate SharePoint

Delta Crown Tenant
├── DCE Hub & Sites

Bishops Tenant  
├── Bishops Hub & Sites
```

**Pros**:
- ✅ Maximum isolation — complete data separation
- ✅ Independent admin control per brand
- ✅ No risk of cross-brand data leakage

**Cons**:
- ❌ Requires separate licensing per tenant (NOT zero cost)
- ❌ Cross-tenant collaboration is complex (requires B2B invitations)
- ❌ Cannot share Business Premium license pool
- ❌ Multiplies administrative overhead exponentially
- ❌ Cross-tenant identity sync required for shared services
- ❌ Violates "zero incremental cost" constraint

**ATAM Score**: 4/10 — Strong isolation but violates cost and simplicity constraints

---

## Decision Outcome

### Chosen Option: **Option B — Hub-per-Brand with Shared Services Hub**

This option provides the optimal balance across all decision drivers:

| Driver | Score |
|--------|-------|
| Brand Autonomy | ✅ 10/10 |
| Template Repeatability | ✅ 9/10 |
| Security Isolation | ⚠️ 7/10 (permission-based, not technical) |
| Zero Incremental Cost | ✅ 10/10 |
| Governance at Scale | ✅ 8/10 |
| User Experience | ✅ 9/10 |
| Operational Simplicity | ⚠️ 7/10 |

### Consequences

**Good**:
- Each brand operates as an independent, branded workspace
- PnP Tenant Templates enable 2-week brand deployments
- Search, navigation, and news are brand-scoped by default
- Corporate maintains oversight via Shared Services Hub
- Scales to all 5 brands (and beyond) within M365 limits

**Bad**:
- Brand isolation is policy-based, not technically enforced (Business Premium limitation)
- Requires disciplined permission governance to prevent cross-brand data leakage
- Hub search scope leakage is a real risk requiring active monitoring
- PnP provisioning requires PowerShell expertise to maintain

**Neutral**:
- Each brand hub needs manual navigation link to Shared Services Hub
- Hub site count grows linearly with brands (acceptable at this scale)
- Private Teams channels create separate SPO sites requiring governance

---

## Hub Site Architecture — Detailed Design

### Topology

```
┌─────────────────────────────────────────────────────────┐
│                   M365 TENANT (Business Premium)         │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         CORPORATE SHARED SERVICES HUB             │   │
│  │    (Communication Site — Corporate branded)        │   │
│  │                                                    │   │
│  │  Associated Sites:                                 │   │
│  │  ├── HR Policies & Procedures (Team Site)          │   │
│  │  ├── IT Knowledge Base (Team Site)                 │   │
│  │  ├── Finance & Reporting (Team Site)               │   │
│  │  ├── Training & Onboarding (Communication Site)    │   │
│  │  └── Brand Templates & Guidelines (Team Site)      │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │           DELTA CROWN EXTENSIONS HUB              │   │
│  │    (Communication Site — DCE gold/black theme)     │   │
│  │                                                    │   │
│  │  Associated Sites:                                 │   │
│  │  ├── DCE Operations (Team Site — Teams-connected)  │   │
│  │  ├── DCE Client Services (Team Site)               │   │
│  │  ├── DCE Marketing & Brand (Communication Site)    │   │
│  │  └── DCE Document Center (Team Site)               │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │              BISHOPS HUB (Week 6-8)               │   │
│  │    (Communication Site — Bishops themed)           │   │
│  │    [Cloned from DCE template]                      │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │ Frenchies   │ │ HTT Hub     │ │ TLL Hub     │       │
│  │ Hub (Wk10+) │ │ (Wk12+)    │ │ (Wk14+)    │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
```

### Site Naming Convention

```
Pattern: {BrandPrefix}-{Function}

Corporate:    Corp-HR, Corp-IT, Corp-Finance, Corp-Training
Delta Crown:  DCE-Operations, DCE-ClientServices, DCE-Marketing, DCE-Docs
Bishops:      BSH-Operations, BSH-ClientServices, BSH-Marketing, BSH-Docs
Frenchies:    FRN-Operations, FRN-ClientServices, FRN-Marketing, FRN-Docs
HTT:          HTT-Operations, HTT-ClientServices, HTT-Marketing, HTT-Docs
TLL:          TLL-Operations, TLL-ClientServices, TLL-Marketing, TLL-Docs
```

### Navigation Structure (per Brand Hub)

```
Brand Hub Navigation (max 2 levels):
├── Home
├── Operations
│   ├── Daily Operations
│   ├── Staff Schedules
│   └── Inventory
├── Clients
│   ├── Client Portal
│   └── Booking
├── Marketing
│   ├── Brand Assets
│   └── Social Media
├── Documents
│   ├── Policies
│   ├── Templates
│   └── Training
└── Corporate Resources → [Link to Shared Services Hub]
```

---

## Provisioning Strategy

### Three-Tier Provisioning Model

| Tier | Tool | Use Case | Automation |
|------|------|----------|------------|
| **1. Brand Onboarding** | PnP Tenant Templates | Full brand workspace deployment | Full automation |
| **2. Standard Sites** | SharePoint Site Designs + Site Scripts | Self-service site creation within brands | Semi-automated |
| **3. Ad-hoc** | Manual creation with governance | Exception-based custom sites | None |

### PnP Brand Template Contents

```xml
Brand Template Package:
├── Hub Site (Communication Site with brand theme)
├── Operations Team (Teams-connected, auto-associated with Hub)
├── Client Services (Team Site, associated with Hub)
├── Marketing (Communication Site, associated with Hub)
├── Document Center (Team Site, associated with Hub)
├── Content Types (brand-specific document types)
├── Site Columns (brand metadata)
├── Term Store Groups (brand-specific taxonomy)
├── Sensitivity Labels (auto-applied to brand sites)
├── Navigation Structure (pre-built hub navigation)
├── Page Templates (branded page layouts)
└── Theme (brand colors, logo, favicon)
```

### 2-Week Brand Deployment Timeline

```
Day 1-2:   Execute PnP Brand Template (automated)
Day 3-4:   Customize branding (logos, colors, hero images)
Day 5-6:   Configure Teams channels + shared mailbox
Day 7-8:   Set up permissions + sensitivity labels
Day 9-10:  Content migration + document structure
Day 11-12: User acceptance testing
Day 13-14: Training + go-live
```

---

## Security Architecture

### Permission Model

```
Tier 1: Azure AD Dynamic Groups (Brand Membership)
├── SG-DCE-AllStaff       → All Delta Crown employees
├── SG-DCE-Leadership     → DCE management team
├── SG-BSH-AllStaff       → All Bishops employees
├── SG-Corp-SharedServices → Users needing shared services access
└── SG-Corp-IT-Admins     → IT administrators (all brands)

Tier 2: SharePoint Permission Levels (per Brand)
├── Hub Site:     SG-{Brand}-AllStaff = Read, SG-{Brand}-Leadership = Full Control
├── Operations:   SG-{Brand}-AllStaff = Contribute (Teams manages)
├── Client Svcs:  SG-{Brand}-AllStaff = Contribute
├── Marketing:    SG-{Brand}-AllStaff = Read, SG-{Brand}-Marketing = Contribute
└── Shared Svcs:  SG-Corp-SharedServices = Read (cross-brand)

Tier 3: Sensitivity Labels
├── Public (general content)
├── DCE-Internal (Delta Crown confidential)
├── BSH-Internal (Bishops confidential)
├── [Brand]-Internal (per brand)
└── Corporate-Confidential (shared services, executive)

Tier 4: DLP Policies
├── Block sharing of [Brand]-Internal content outside brand group
├── Warn on external sharing of any Internal content
└── Block external sharing of Corporate-Confidential
```

### Compensating Controls (for Missing Information Barriers)

| Control | Purpose | Implementation |
|---------|---------|----------------|
| Azure AD Dynamic Groups | Automated brand membership | Department/Company attribute |
| Strict Unique Permissions | No inherited cross-brand access | Every brand site = unique perms |
| Sensitivity Labels | Content classification + encryption | Auto-label by site location |
| DLP Policies | Prevent cross-brand sharing | Brand-scoped sharing rules |
| Weekly Permission Scan | Detect permission drift | PowerShell scheduled task |
| Quarterly Access Review | Human verification | Brand manager attestation |
| Hub Search Scope Control | Prevent search leakage | Disabled hub search inheritance |
| Teams Creation Governance | Prevent ad-hoc cross-brand Teams | Approval workflow + naming policy |

---

## STRIDE Security Analysis

> **Security Auditor Co-Sign**: CONDITIONAL APPROVAL with mandatory monitoring controls and 90-day re-audit.

### Summary Risk Matrix

| Component | S | T | R | I | D | E | Highest Risk |
|-----------|---|---|---|---|---|---|-------------|
| Hub & Spoke Topology | 🟡H | 🟢M | 🟢M | 🔴C | 🟢M | 🟡H | Info Disclosure (search leakage) |
| Permission Boundaries | 🟡H | 🔴C | 🟢M | 🔴C | 🟢M | 🔴C | Elevation (admin lateral movement) |
| PnP Provisioning | 🟡H | 🔴C | 🟢M | 🔴C | 🟢M | 🔴C | Tampering (template injection) |
| Teams Integration | 🟡H | 🟡H | 🟢M | 🔴C | 🟢M | 🟡H | Info Disclosure (cross-team sharing) |
| Shared Services | 🟢M | 🟢M | 🟢M | 🔴C | 🟢M | 🟡H | Info Disclosure (data leakage) |
| Labels & DLP | 🟢M | 🟡H | 🟢L | 🔴C | 🟢M | 🟡H | Info Disclosure (DLP bypass) |

**Legend**: 🔴C = Critical, 🟡H = High, 🟢M = Medium, 🟢L = Low

### Critical Findings (Requiring Immediate Action)

#### CRITICAL-1: No Technical Brand Isolation
- **Threat**: Business Premium lacks Information Barriers; brand isolation is policy-based only
- **Impact**: Permission misconfiguration exposes Brand A data to Brand B
- **Mitigation**: Azure AD dynamic groups + sensitivity labels + weekly permission scanning
- **Residual Risk**: HIGH — human error remains possible
- **Action**: Implement all compensating controls before go-live; evaluate E5 upgrade at 90-day review

#### CRITICAL-2: Hub Search Scope Leakage
- **Threat**: Content from Brand A appears in Brand B hub search if permissions misconfigured
- **Impact**: Franchise agreement violation; competitive intelligence leak
- **Mitigation**: Unique permissions on ALL brand sites; search scope controls; weekly search testing
- **Residual Risk**: HIGH — search indexing is complex

#### CRITICAL-3: Cross-Brand Teams File Sharing
- **Threat**: Users share files across brand Teams via chat/channels
- **Impact**: Uncontrolled brand data movement
- **Mitigation**: DLP policies; sensitivity labels with encryption; external sharing disabled
- **Residual Risk**: HIGH — user behavior difficult to fully control

#### CRITICAL-4: PnP App Registration Over-Privilege
- **Threat**: PnP provisioning app has excessive Graph API permissions
- **Impact**: Compromised app = tenant-wide access
- **Mitigation**: Least-privilege permissions; certificate auth; PIM; quarterly review
- **Residual Risk**: HIGH — application permissions are inherently broad

---

## Week 2 Implementation Steps

### "Collaboration + Email: Teams, SharePoint & Brand Email Config"

#### Day 1: Corporate Shared Services Hub
```
□ Create Communication Site: "Corporate Shared Services"
□ Register as Hub Site in SharePoint Admin Center
□ Apply corporate theme (colors, logo)
□ Create associated sites: Corp-HR, Corp-IT, Corp-Finance, Corp-Training
□ Associate sites with Corporate Hub
□ Configure hub navigation (Home, HR, IT, Finance, Training)
□ Set permissions: SG-Corp-SharedServices = Visitors
```

#### Day 2: Delta Crown Hub Site
```
□ Create Communication Site: "Delta Crown Extensions"
□ Register as Hub Site
□ Apply DCE brand theme (royal gold/black palette)
□ Upload DCE logo and brand assets
□ Create hub navigation structure (see Navigation Structure above)
□ Add "Corporate Resources" navigation link to Shared Services Hub
```

#### Day 3: Delta Crown Associated Sites
```
□ Create Team Site: "DCE-Operations" (Teams-connected)
  → This auto-creates the "Delta Crown Operations" Team in Teams
□ Create Team Site: "DCE-ClientServices"
□ Create Communication Site: "DCE-Marketing"
□ Create Team Site: "DCE-Docs" (Document Center)
□ Associate all sites with Delta Crown Hub
□ Verify hub navigation shows all associated sites
```

#### Day 4: Teams Configuration
```
□ Configure "Delta Crown Operations" Team:
  ├── General channel (auto-created)
  ├── Create "Daily Operations" channel
  ├── Create "Client Bookings" channel
  ├── Create "Marketing" channel
  └── Create "Leadership" private channel
□ Configure shared mailbox: operations@deltacrown.com
□ Link shared mailbox to Teams (if needed)
□ Verify Teams ↔ SharePoint file sync works
```

#### Day 5: Permissions & Security
```
□ Create Azure AD Dynamic Groups:
  ├── SG-DCE-AllStaff (Department = "Delta Crown")
  ├── SG-DCE-Leadership (Title contains "Manager" AND Department = "Delta Crown")
  └── SG-DCE-Marketing (Department = "Delta Crown Marketing")
□ Apply permissions to all DCE sites (unique, NOT inherited):
  ├── DCE Hub: SG-DCE-AllStaff = Read
  ├── DCE-Operations: Managed by Teams membership
  ├── DCE-ClientServices: SG-DCE-AllStaff = Contribute
  ├── DCE-Marketing: SG-DCE-AllStaff = Read, SG-DCE-Marketing = Contribute
  └── DCE-Docs: SG-DCE-AllStaff = Contribute
□ Remove "Everyone" and "All Users" from ALL DCE sites
□ Disable external sharing on all DCE sites (default)
```

#### Day 6: Sensitivity Labels & DLP
```
□ Create sensitivity label: "DCE-Internal"
  ├── Auto-label: Apply to all content in DCE site collections
  ├── Protection: Encrypt; restrict to SG-DCE-AllStaff
  └── Markings: Header "Delta Crown — Internal"
□ Create DLP policy: "DCE Data Protection"
  ├── Scope: DCE SharePoint sites + Teams
  ├── Rule: Block sharing of DCE-Internal content outside SG-DCE-AllStaff
  └── Mode: Test mode for 90 days (then enforce)
□ Publish labels and DLP policies
```

#### Day 7: Brand Email Configuration
```
□ Verify deltacrown.com domain in M365 Admin
□ Configure brand-specific email addresses:
  ├── operations@deltacrown.com (shared mailbox)
  ├── info@deltacrown.com (shared mailbox)
  └── bookings@deltacrown.com (shared mailbox)
□ Verify SPF/DKIM/DMARC for deltacrown.com (should be done)
□ Configure email signatures with DCE branding
□ Test email flow: send/receive from all brand addresses
```

#### Day 8-10: Template Capture & Validation
```
□ Export DCE configuration as PnP Tenant Template
□ Document all manual steps for template gaps
□ Test template by applying to dev/test site
□ Create Site Design JSON for "DCE Standard Team Site"
□ Create Site Design JSON for "DCE Communication Site"
□ Validate hub navigation, search, and permissions
□ Run permission audit (PowerShell: Get-PnPSiteCollectionAdmin)
□ Test search isolation (search from DCE hub should NOT return Corp content)
□ Test DLP policy (attempt to share DCE-Internal externally)
```

---

## Taxonomy & Content Types

### Term Store Structure

```
Term Store
├── Corporate (Group — managed by Corp IT)
│   ├── Brands (Term Set): Delta Crown | Bishops | Frenchies | HTT | TLL
│   ├── Document Types: Policy | Procedure | Template | Form | Report
│   ├── Compliance: Confidential | Internal | Public
│   └── Departments: Operations | Marketing | Finance | HR | IT
│
├── Shared (Group — managed by Corp IT)
│   ├── Service Categories: Hair Extensions | Barbering | Styling
│   └── Locations: [Franchise locations]
│
├── Delta Crown (Group — managed by DCE admin)
│   ├── DCE Products: [Product terms]
│   ├── DCE Services: [Service terms]
│   └── DCE Clients: [Client segment terms]
│
└── [Additional Brand Groups as onboarded]
```

### Content Types (Published from Content Type Hub)

```
Corporate Content Types (inherited by all brands):
├── Corporate Document (base)
├── Corporate Policy (requires approval workflow)
├── Corporate Form (template-based)
└── Corporate Report (with metadata)

Brand Content Types (brand-specific):
├── Brand Client Record
├── Brand Service Record
├── Brand Marketing Asset
└── Brand Operational Document
```

---

## Fitness Functions

See `tests/architecture/test_adr_001_sharepoint_hub_spoke.py` for automated checks.

---

## Research References

| Source | Tier | URL |
|--------|------|-----|
| Microsoft Learn — Planning Hub Sites | 1 | https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites |
| Microsoft Learn — Create Hub Site | 1 | https://learn.microsoft.com/en-us/sharepoint/create-hub-site |
| Microsoft Learn — PnP Provisioning Engine | 1 | https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/introducing-the-pnp-provisioning-engine |
| Microsoft Learn — Teams Connected Sites | 1 | https://learn.microsoft.com/en-us/sharepoint/teams-connected-sites |
| Microsoft Learn — Information Barriers | 1 | https://learn.microsoft.com/en-us/purview/information-barriers |
| Microsoft Learn — Sensitivity Labels | 1 | https://learn.microsoft.com/en-us/purview/sensitivity-labels |
| PnP Community GitHub | 2 | https://pnp.github.io/ |

**Research Directories**:
- `./research/sharepoint-hub-spoke/` — Hub & Spoke architecture research
- `./research/sharepoint-provisioning/` — Provisioning & governance research

---

## Appendix A: M365 Business Premium Constraints

| Feature | Available | Impact on Architecture |
|---------|-----------|----------------------|
| SharePoint Hub Sites | ✅ Yes | Core architecture component |
| Teams | ✅ Yes | Brand collaboration |
| Sensitivity Labels | ✅ Yes | Content classification |
| DLP Policies | ✅ Yes (limited) | Brand data protection |
| Information Barriers | ❌ No (requires E5) | Policy-based isolation only |
| Multi-Geo | ❌ No | Single region deployment |
| Customer Lockbox | ❌ No | Accept Microsoft data access |
| Advanced Audit | ❌ Limited | 90-day retention only |
| User Limit | 300 maximum | Plan franchise headcount |
| Storage | 1TB + 10GB/user | Shared across all brands |

## Appendix B: Governance Decision Matrix

| Decision | Chosen | Alternative | Rationale |
|----------|--------|-------------|-----------|
| External Sharing | Disabled by default | Per-site enable | Brand protection |
| Guest Access | Require approval | Open | Control brand exposure |
| Site Creation | Governed + templates | Self-service | Consistency |
| Private Channels | Restricted to owners | Open | Governance complexity |
| Sensitivity Labels | Mandatory | Optional | Content classification |
| Hub Search | Brand-scoped | Tenant-wide | Isolation requirement |
| Navigation Depth | 2 levels max | 3 levels | UX simplicity |
| Retention Policies | Brand-specific | Tenant-wide | Compliance flexibility |

## Appendix C: Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Brand provisioning time | ≤ 14 days | Calendar days from template execution |
| Site provisioning (automated) | < 30 minutes | PnP template execution time |
| Search isolation | 100% | Zero cross-brand results in brand hub search |
| Permission compliance | 100% | Weekly audit shows no cross-brand access |
| User adoption | > 80% | Active users / licensed users per brand |
| Hub page load | < 3 seconds | Measured via browser performance |
| Zero cross-brand data exposure | 0 incidents | Security incident count |
