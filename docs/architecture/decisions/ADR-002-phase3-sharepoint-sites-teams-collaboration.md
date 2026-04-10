# ADR-002: Phase 3 — SharePoint Brand Sites + Teams Collaboration Architecture

| Field | Value |
|-------|-------|
| **Status** | Proposed |
| **Date** | 2025-07-25 |
| **Decision Makers** | Solutions Architect (solutions-architect-261e7f) |
| **Security Co-Sign** | Security Auditor — PENDING |
| **Consulted** | Web-Puppy (research — unavailable, used existing), Experience Architect (UX) |
| **Supersedes** | None |
| **Depends On** | ADR-001 (Hub & Spoke Topology) |

---

## Context and Problem Statement

Phase 2 established the **hub site infrastructure** (Corporate Hub + DCE Hub) and **identity framework** (Azure AD dynamic groups, certificate auth). Phase 3 must now populate the DCE Hub with functional SharePoint sites, deploy a Teams workspace for daily operations, harden security with unique permissions, implement DLP policies, and capture the entire configuration as a reusable PnP template for future brand deployments.

### The Core Questions

1. **What site structure** should DCE-Operations, DCE-ClientServices, DCE-Marketing, and DCE-Docs have (lists, libraries, content types)?
2. **How should Teams integrate** with SharePoint (which site backs the Team, channel-to-library mapping)?
3. **What permission model** ensures zero cross-brand data leakage without Information Barriers?
4. **How do we capture** the complete configuration as a parameterized PnP template?

### Constraints (inherited from ADR-001)
- M365 Business Premium: 300-user max, NO Information Barriers
- Single tenant shared across all franchise brands
- Zero incremental licensing cost
- 14-day deployment window per subsequent brand
- DLP policy limit: 10 policies per tenant (Business Premium)

---

## Decision Drivers

1. **Operational Readiness**: Sites must support daily franchise operations (bookings, tasks, staff coordination)
2. **Teams-First UX**: Staff will primarily interact via Teams; SharePoint is the data layer
3. **Permission Isolation**: DCE content must be invisible to future brand users
4. **Template Fidelity**: Everything provisioned must be capturable via PnP for brand cloning
5. **DLP Coverage**: Sensitive data must not leak across brand boundaries
6. **Minimal Governance Overhead**: Small IT team cannot manage complex permission hierarchies
7. **Phase 2 Compatibility**: Must integrate with existing scripts, modules, and config

---

## Considered Options

### Option A: Teams-Connected Team Sites for All Brand Sites

```
DCE Hub (Communication Site — already exists)
├── DCE-Operations (Team Site + Teams-connected) ← Teams Team created
├── DCE-ClientServices (Team Site + Teams-connected) ← Separate Team
├── DCE-Marketing (Team Site + Teams-connected) ← Separate Team
└── DCE-Docs (Team Site + Teams-connected) ← Separate Team
```

**Pros**:
- Every site has its own Teams workspace
- Maximum Teams integration
- Each team manages its own membership

**Cons**:
- ❌ 4 separate Teams = fragmented communication
- ❌ Staff must switch between 4 Teams — terrible UX
- ❌ Permission management across 4 Teams is complex
- ❌ Shared mailbox integration unclear across multiple Teams
- ❌ Private channels multiply across Teams (governance nightmare)

**ATAM Score**: 3/10 — Fails UX and governance requirements

### Option B: Single Teams Team with SharePoint Sites as Backing Stores (RECOMMENDED)

```
DCE Hub (Communication Site — already exists from Phase 2)
├── DCE-Operations (Team Site — Teams-connected)
│   └── "Delta Crown Operations" Team
│       ├── General (standard) → Documents library
│       ├── Daily Ops (standard) → Daily Ops library
│       ├── Bookings (standard) → Bookings library
│       ├── Marketing (standard) → Marketing library
│       └── Leadership (private) → separate SPO site
├── DCE-ClientServices (Team Site — standalone, NOT Teams-connected)
├── DCE-Marketing (Communication Site — standalone)
└── DCE-Docs (Team Site — standalone, document center pattern)
```

**Pros**:
- ✅ Single Team = unified communication experience
- ✅ Operations Team is the daily hub; other sites are reference/archive
- ✅ Channel-based file organization maps cleanly to document libraries
- ✅ Private Leadership channel gets its own SPO site (auto-isolated)
- ✅ DCE-ClientServices, Marketing, Docs accessible via Hub navigation + Teams tabs
- ✅ Shared mailbox integrates with single Team
- ✅ Minimal permission surface area (1 Team + 3 standalone sites)
- ✅ PnP template can capture Team + sites in one template package

**Cons**:
- ⚠️ Marketing channel in Team has less capability than dedicated Communication Site
- ⚠️ Standalone sites require separate permission management
- ⚠️ Private channel SPO site needs separate hub association

**ATAM Score**: 9/10 — Best balance of UX, governance, and template fidelity

### Option C: No Teams Integration (SharePoint-Only)

```
DCE Hub (Communication Site)
├── DCE-Operations (Team Site — no Teams)
├── DCE-ClientServices (Team Site — no Teams)
├── DCE-Marketing (Communication Site — no Teams)
└── DCE-Docs (Team Site — no Teams)
```

**Pros**:
- Simplest architecture
- No Teams governance complexity
- Full SharePoint control

**Cons**:
- ❌ Ignores Teams-first work pattern
- ❌ No real-time collaboration channel
- ❌ No mobile Teams app for field staff
- ❌ Misses shared mailbox integration
- ❌ Franchise staff will create ad-hoc Teams anyway (shadow IT)

**ATAM Score**: 2/10 — Fails operational readiness; creates shadow IT risk

---

## Decision Outcome

### Chosen Option: **Option B — Single Teams Team with SharePoint Backing Stores**

| Driver | Score |
|--------|-------|
| Operational Readiness | ✅ 9/10 |
| Teams-First UX | ✅ 10/10 |
| Permission Isolation | ✅ 8/10 |
| Template Fidelity | ✅ 8/10 |
| DLP Coverage | ✅ 7/10 |
| Minimal Governance | ✅ 9/10 |
| Phase 2 Compatibility | ✅ 10/10 |

### Consequences

**Good**:
- Staff have ONE Teams workspace for all daily operations
- Channel files automatically sync to SharePoint document libraries
- Private Leadership channel has technical isolation (separate SPO site)
- Hub navigation provides access to Client Services, Marketing, Docs
- Single Team simplifies shared mailbox integration
- PnP template captures entire workspace in one package

**Bad**:
- Marketing team may want richer Communication Site features (mitigated: DCE-Marketing exists as standalone)
- Private channel site requires manual hub association
- Leadership channel SPO site URL is auto-generated (not customizable)

**Neutral**:
- Tab-based integration lets standalone sites appear inside Teams
- Teams mobile app provides field staff access to all content
- Channel email addresses provide additional routing options

---

## Detailed Architecture Design

### 1. SharePoint Site Structure

#### DCE-Operations (Team Site — Teams-Connected)
**URL**: `https://deltacrownext.sharepoint.com/sites/dce-operations`
**Purpose**: Daily operations hub, Teams-connected
**Teams Team**: "Delta Crown Operations"

| Component | Type | Purpose |
|-----------|------|---------|
| Documents | Document Library | General team files, SOPs |
| Daily Ops | Document Library | Shift reports, daily checklists |
| Bookings | SharePoint List | Client booking tracker |
| Staff Schedule | SharePoint List | Weekly schedule / roster |
| Tasks | SharePoint List | Operational task tracking |
| Inventory | SharePoint List | Product inventory tracker |
| Calendar | SharePoint Calendar | Team calendar (syncs to Outlook) |

**Bookings List Schema**:
| Column | Type | Required |
|--------|------|----------|
| Client Name | Single line text | Yes |
| Service Type | Choice (Extensions, Maintenance, Removal, Consultation) | Yes |
| Booking Date | Date/Time | Yes |
| Stylist | Person | Yes |
| Status | Choice (Confirmed, Pending, Completed, Cancelled, No-Show) | Yes |
| Notes | Multi-line text | No |
| Revenue | Currency | No |

**Staff Schedule List Schema**:
| Column | Type | Required |
|--------|------|----------|
| Staff Member | Person | Yes |
| Shift Date | Date/Time | Yes |
| Start Time | Date/Time | Yes |
| End Time | Date/Time | Yes |
| Location | Choice (parameterized per brand) | Yes |
| Role | Choice (Stylist, Reception, Manager, Trainee) | Yes |
| Notes | Multi-line text | No |

**Tasks List Schema**:
| Column | Type | Required |
|--------|------|----------|
| Task Title | Single line text | Yes |
| Assigned To | Person | Yes |
| Due Date | Date/Time | Yes |
| Priority | Choice (Urgent, High, Medium, Low) | Yes |
| Status | Choice (Not Started, In Progress, Completed, Blocked) | Yes |
| Category | Choice (Operations, Maintenance, Admin, Training) | Yes |
| Description | Multi-line text | No |

#### DCE-ClientServices (Team Site — Standalone)
**URL**: `https://deltacrownext.sharepoint.com/sites/dce-clientservices`
**Purpose**: Client relationship management, service records

| Component | Type | Purpose |
|-----------|------|---------|
| Documents | Document Library | Client forms, consent docs |
| Client Records | SharePoint List | Client service history |
| Service Catalog | SharePoint List | Services offered + pricing |
| Feedback | SharePoint List | Client feedback tracker |
| Consent Forms | Document Library | Signed consent PDFs |

**Client Records List Schema**:
| Column | Type | Required |
|--------|------|----------|
| Client Name | Single line text | Yes |
| Email | Single line text | No |
| Phone | Single line text | No |
| Service History | Multi-line text | No |
| Last Visit | Date/Time | No |
| Preferred Stylist | Person | No |
| Allergy/Notes | Multi-line text | No |
| Total Spend | Currency | No |
| VIP Status | Yes/No | No |

#### DCE-Marketing (Communication Site — Standalone)
**URL**: `https://deltacrownext.sharepoint.com/sites/dce-marketing`
**Purpose**: Brand assets, campaign management, social media coordination

| Component | Type | Purpose |
|-----------|------|---------|
| Brand Assets | Document Library | Logos, photos, videos |
| Campaigns | SharePoint List | Campaign tracker |
| Social Calendar | SharePoint List | Social media posting schedule |
| Pages | Site Pages | Landing pages, announcements |
| Templates | Document Library | Marketing templates (flyers, posts) |

**Campaigns List Schema**:
| Column | Type | Required |
|--------|------|----------|
| Campaign Name | Single line text | Yes |
| Start Date | Date/Time | Yes |
| End Date | Date/Time | Yes |
| Channel | Choice (Instagram, Facebook, TikTok, Email, In-Store, Google) | Yes |
| Status | Choice (Planning, Active, Paused, Completed) | Yes |
| Budget | Currency | No |
| Target Audience | Multi-line text | No |
| Results | Multi-line text | No |
| Owner | Person | Yes |

#### DCE-Docs (Team Site — Standalone, Document Center Pattern)
**URL**: `https://deltacrownext.sharepoint.com/sites/dce-docs`
**Purpose**: Central document repository, policies, training materials

| Component | Type | Purpose |
|-----------|------|---------|
| Policies | Document Library | Company policies, SOPs |
| Training | Document Library | Training materials, videos |
| Forms | Document Library | Standardized forms |
| Templates | Document Library | Document templates |
| Archive | Document Library | Historical documents |

**Document Library Metadata** (applied to all libraries):
| Column | Type | Purpose |
|--------|------|----------|
| Document Type | Choice (Policy, SOP, Form, Template, Training, Reference) | Classification |
| Department | Choice (Operations, Marketing, Finance, HR, IT) | Ownership |
| Review Date | Date/Time | Compliance tracking |
| Version | Number | Version tracking |
| Status | Choice (Draft, Under Review, Published, Archived) | Lifecycle |
| Owner | Person | Document owner |

### 2. Teams Configuration

#### Team: "Delta Crown Operations"
**Visibility**: Private
**Owners**: SG-DCE-Leadership members
**Members**: SG-DCE-AllStaff members

| Channel | Type | SharePoint Library | Purpose |
|---------|------|-------------------|---------|
| General | Standard | Documents | Team announcements, general files |
| Daily Ops | Standard | Daily Ops | Shift handover, daily checklists, incident reports |
| Bookings | Standard | (Tab: Bookings list) | Client booking coordination |
| Marketing | Standard | (Tab: DCE-Marketing site) | Social media coordination, campaign updates |
| Leadership | Private | (Separate SPO site) | Management discussions, financials, HR matters |

**Tabs Configuration**:
| Channel | Tab Name | Tab Type | Target |
|---------|----------|----------|--------|
| General | Schedule | SharePoint List | Staff Schedule list |
| General | Tasks | Planner/Tasks | Team task board |
| Bookings | Booking Tracker | SharePoint List | Bookings list from DCE-Operations |
| Marketing | Brand Assets | SharePoint Library | Brand Assets from DCE-Marketing |
| Marketing | Campaigns | SharePoint List | Campaigns list from DCE-Marketing |
| Leadership | Client Records | SharePoint List | Client Records from DCE-ClientServices |
| Leadership | Docs & Policies | SharePoint Library | Policies from DCE-Docs |

**Shared Mailbox Integration**:
- `operations@deltacrown.com.au` → Connected to General channel (via connector or forwarding rule)
- `bookings@deltacrown.com.au` → Connected to Bookings channel
- `info@deltacrown.com.au` → General team mailbox

**Guest Access Policy**:
- Guest access: **Disabled** at team level
- External sharing: **Disabled** for all associated SharePoint sites
- B2B invitations: Require admin approval

### 3. Permission Model

```
┌─────────────────────────────────────────────────────┐
│            PERMISSION HIERARCHY                      │
│                                                      │
│  Tier 0: Tenant Admin                               │
│  └── SharePoint Admin, Global Admin                  │
│                                                      │
│  Tier 1: Azure AD Dynamic Groups                    │
│  ├── SG-DCE-AllStaff (auto from department attr)    │
│  ├── SG-DCE-Leadership (auto from title attr)       │
│  └── SG-DCE-Marketing (NEW — needed for Phase 3)   │
│                                                      │
│  Tier 2: Site Permissions (ALL unique, NO inherit)  │
│  ├── DCE Hub: SG-DCE-AllStaff=Read                  │
│  ├── DCE-Operations: Teams membership manages       │
│  ├── DCE-ClientServices: SG-DCE-AllStaff=Contribute │
│  ├── DCE-Marketing: AllStaff=Read, Marketing=Edit   │
│  └── DCE-Docs: SG-DCE-AllStaff=Read, Leaders=Edit  │
│                                                      │
│  Tier 3: Sensitivity Labels                         │
│  └── DCE-Internal auto-applied to all DCE sites     │
│                                                      │
│  Tier 4: DLP Policies                               │
│  └── DCE-Data-Protection blocks cross-brand sharing │
└─────────────────────────────────────────────────────┘
```

**New Security Group Required**:
| Group | Rule | Purpose |
|-------|------|---------|
| SG-DCE-Marketing | `(user.department -eq "Delta Crown Marketing")` | Marketing site edit access |

**Permission Matrix**:
| Site | SG-DCE-AllStaff | SG-DCE-Leadership | SG-DCE-Marketing | Teams Managed |
|------|----------------|-------------------|-------------------|---------------|
| DCE Hub | Read | Full Control | Read | No |
| DCE-Operations | — | — | — | Yes (Team membership) |
| DCE-ClientServices | Contribute | Full Control | Read | No |
| DCE-Marketing | Read | Full Control | Edit | No |
| DCE-Docs | Read | Full Control | Read | No |

### 4. DLP Policy Design

**Policy Budget** (10 max for Business Premium):
| # | Policy Name | Scope | Phase |
|---|------------|-------|-------|
| 1 | DCE-Data-Protection | DCE SharePoint + Teams | Phase 3 |
| 2 | Corp-Data-Protection | Corporate shared sites | Phase 3 |
| 3 | BSH-Data-Protection | Bishops (future) | Phase 5 |
| 4 | FRN-Data-Protection | Frenchies (future) | Phase 6 |
| 5 | HTT-Data-Protection | HTT (future) | Phase 7 |
| 6 | TLL-Data-Protection | TLL (future) | Phase 8 |
| 7 | External-Sharing-Block | All sites | Phase 3 |
| 8 | PII-Protection | All sites | Phase 4 |
| 9 | Financial-Data | Finance sites | Phase 4 |
| 10 | (Reserved) | — | Future |

**Phase 3 DLP Policies (3 of 10 budget)**:

**Policy 1: DCE-Data-Protection**
- Scope: DCE-Operations, DCE-ClientServices, DCE-Marketing, DCE-Docs, DCE Teams
- Rule 1: Block sharing with non-DCE recipients
- Rule 2: Warn on any external sharing attempt
- Rule 3: Block external download of DCE-Internal content
- Mode: TestWithNotifications (90 days)

**Policy 2: Corp-Data-Protection**
- Scope: Corp-Hub, Corp-HR, Corp-IT, Corp-Finance, Corp-Training
- Rule 1: Block external sharing of Corporate-Confidential
- Rule 2: Warn on sharing outside SG-Corp-SharedServices
- Mode: TestWithNotifications (90 days)

**Policy 3: External-Sharing-Block**
- Scope: All SharePoint sites
- Rule 1: Block all anonymous link creation
- Rule 2: Block sharing with personal email domains (gmail, hotmail, etc.)
- Mode: Enforce immediately

### 5. Template Capture Strategy

#### What Gets Captured by PnP Template
| Component | Captured | Notes |
|-----------|----------|-------|
| Site structure | ✅ Yes | Sites, URLs, templates |
| Document libraries | ✅ Yes | Structure, columns, views |
| SharePoint lists | ✅ Yes | Columns, views, formatting |
| Content types | ✅ Yes | Custom content types + columns |
| Site theme | ✅ Yes | Color palette, logo reference |
| Hub association | ⚠️ Partial | Hub ID must be parameterized |
| Navigation | ✅ Yes | Hub + site navigation |
| Pages | ✅ Yes | Page layouts + web parts |
| Permissions | ⚠️ Partial | Group assignments, not group creation |
| Teams Team | ❌ No | Must be created separately via Graph API |
| Teams Channels | ❌ No | Must be created separately via Graph API |
| DLP Policies | ❌ No | Must be created via Compliance PowerShell |
| Sensitivity Labels | ❌ No | Must be created via Compliance PowerShell |
| Shared Mailboxes | ❌ No | Must be created via Exchange PowerShell |

#### Parameterization Strategy
| Parameter | DCE Value | Template Variable |
|-----------|-----------|-------------------|
| Brand Name | Delta Crown Extensions | `{BrandName}` |
| Brand Prefix | DCE | `{BrandPrefix}` |
| Brand Domain | deltacrown.com.au | `{BrandDomain}` |
| Hub URL | /sites/dce-hub | /sites/`{prefix}`-hub |
| Primary Color | #C9A227 (Gold) | `{PrimaryColor}` |
| Secondary Color | #1A1A1A (Black) | `{SecondaryColor}` |
| Light Accent | #D4B43F | `{LightAccent}` |
| Dark Accent | #B08D1F | `{DarkAccent}` |
| Logo URL | /sites/dce-hub/SiteAssets/logo.png | /sites/`{prefix}`-hub/SiteAssets/logo.png |
| AllStaff Group | SG-DCE-AllStaff | SG-`{BrandPrefix}`-AllStaff |
| Leadership Group | SG-DCE-Leadership | SG-`{BrandPrefix}`-Leadership |
| Marketing Group | SG-DCE-Marketing | SG-`{BrandPrefix}`-Marketing |
| Operations Email | operations@deltacrown.com.au | operations@`{BrandDomain}` |
| Bookings Email | bookings@deltacrown.com.au | bookings@`{BrandDomain}` |
| Location Choices | (brand-specific locations) | `{LocationChoices}` |

#### Template Export Procedure
```powershell
# Step 1: Export SharePoint sites as PnP templates
Get-PnPSiteTemplate -Out "DCE-Operations-Template.xml" `
    -IncludeAllPages `
    -IncludeSiteCollectionTermGroup `
    -Handlers Lists,Fields,ContentTypes,Pages,Navigation,Theme

# Step 2: Export each standalone site
# DCE-ClientServices, DCE-Marketing, DCE-Docs

# Step 3: Create master brand template package
# Combine individual templates into tenant template

# Step 4: Parameterize brand-specific values
# Replace hardcoded DCE values with {variables}

# Step 5: Create companion Graph API script for Teams
# Teams/channels/tabs cannot be in PnP template

# Step 6: Create companion Exchange script for mailboxes
# Shared mailboxes cannot be in PnP template
```

---

## Script Specification

### Phase 3 Scripts Required

| # | Script | Purpose | Dependencies | Est. Lines |
|---|--------|---------|--------------|------------|
| 3.0 | `3.0-Master-Phase3.ps1` | Orchestrator for all Phase 3 tasks | DeltaCrown.Auth, DeltaCrown.Common | ~300 |
| 3.1 | `3.1-DCE-Sites-Provisioning.ps1` | Create 4 DCE SharePoint sites + lists + libraries | Phase 2 hub exists, PnP.PowerShell | ~500 |
| 3.2 | `3.2-Teams-Provisioning.ps1` | Create Teams team + channels + tabs | Microsoft.Graph, DCE-Operations site exists | ~400 |
| 3.3 | `3.3-Security-Hardening.ps1` | Unique perms, remove Everyone, apply groups | Azure AD groups exist, sites exist | ~350 |
| 3.4 | `3.4-DLP-Policies.ps1` | Create 3 DLP policies (test mode) | ExchangeOnlineManagement, sites exist | ~300 |
| 3.5 | `3.5-Shared-Mailboxes.ps1` | Create brand shared mailboxes + Teams integration | ExchangeOnlineManagement | ~200 |
| 3.6 | `3.6-Template-Export.ps1` | Export PnP templates from configured sites | All above complete, PnP.PowerShell | ~400 |
| 3.7 | `3.7-Phase3-Verification.ps1` | Verify all Phase 3 components | All above complete | ~500 |

### Script Dependency Chain
```
Phase 2 Complete (Hub sites + Azure AD groups exist)
    │
    ▼
3.1-DCE-Sites-Provisioning.ps1
    │
    ├──▶ 3.2-Teams-Provisioning.ps1 (needs DCE-Operations site)
    │       │
    │       └──▶ 3.5-Shared-Mailboxes.ps1 (needs Team for integration)
    │
    ├──▶ 3.3-Security-Hardening.ps1 (needs all sites)
    │       │
    │       └──▶ 3.4-DLP-Policies.ps1 (needs hardened sites)
    │
    └──▶ [Wait for all above]
            │
            ▼
        3.6-Template-Export.ps1 (needs fully configured environment)
            │
            ▼
        3.7-Phase3-Verification.ps1 (validates everything)
```

### Integration with Phase 2 Modules

All Phase 3 scripts will:
- Import `DeltaCrown.Auth.psm1` for authentication
- Import `DeltaCrown.Common.psm1` for logging/error handling
- Read `DeltaCrown.Config.psd1` for configuration
- Follow same `-WhatIf` and idempotency patterns
- Output to same log directory

### Config Extensions Required

New keys needed in `DeltaCrown.Config.psd1`:
```powershell
# Phase 3 additions
Phase3 = @{
    Sites = @{
        DCEOperations = @{
            Url = "/sites/dce-operations"
            Title = "DCE Operations"
            Template = "STS#3"  # Team Site (no M365 Group)
            TeamsConnected = $true
        }
        DCEClientServices = @{
            Url = "/sites/dce-clientservices"
            Title = "DCE Client Services"
            Template = "STS#3"
            TeamsConnected = $false
        }
        DCEMarketing = @{
            Url = "/sites/dce-marketing"
            Title = "DCE Marketing"
            Template = "SITEPAGEPUBLISHING#0"  # Communication Site
            TeamsConnected = $false
        }
        DCEDocs = @{
            Url = "/sites/dce-docs"
            Title = "DCE Document Center"
            Template = "STS#3"
            TeamsConnected = $false
        }
    }
    Teams = @{
        TeamName = "Delta Crown Operations"
        TeamDescription = "Daily operations hub for Delta Crown Extensions"
        Visibility = "Private"
        Channels = @(
            @{ Name = "Daily Ops"; Description = "Shift reports and daily operations" }
            @{ Name = "Bookings"; Description = "Client booking coordination" }
            @{ Name = "Marketing"; Description = "Marketing campaigns and social media" }
            @{ Name = "Leadership"; Description = "Management discussions"; Private = $true }
        )
    }
    SharedMailboxes = @(
        @{ Name = "DCE Operations"; Email = "operations"; Domain = "deltacrown.com.au" }
        @{ Name = "DCE Bookings"; Email = "bookings"; Domain = "deltacrown.com.au" }
        @{ Name = "DCE Info"; Email = "info"; Domain = "deltacrown.com.au" }
    )
    DLPPolicies = @(
        @{ Name = "DCE-Data-Protection"; Mode = "TestWithNotifications" }
        @{ Name = "Corp-Data-Protection"; Mode = "TestWithNotifications" }
        @{ Name = "External-Sharing-Block"; Mode = "Enforce" }
    )
}
```

---

## STRIDE Security Analysis

### Summary Risk Matrix

| Component | S | T | R | I | D | E | Highest Risk |
|-----------|---|---|---|---|---|---|-------------|
| SharePoint Brand Sites | 🟡H | 🟢M | 🟢M | 🔴C | 🟢M | 🟡H | Info Disclosure (permission gaps) |
| Teams Workspace | 🟡H | 🟡H | 🟢L | 🔴C | 🟢M | 🟡H | Info Disclosure (file sharing in chat) |
| Private Leadership Channel | 🟡H | 🟢M | 🟢L | 🟡H | 🟢L | 🟡H | Elevation (membership management) |
| Shared Mailboxes | 🟡H | 🟢M | 🟢M | 🟡H | 🟢M | 🟡H | Spoofing (mailbox impersonation) |
| DLP Policies | 🟢M | 🟡H | 🟢L | 🟡H | 🟢L | 🟢M | Tampering (policy bypass) |
| PnP Templates | 🟡H | 🔴C | 🟢M | 🔴C | 🟢M | 🔴C | Tampering (template injection) |
| SharePoint Lists (PII) | 🟢M | 🟡H | 🟢M | 🔴C | 🟢M | 🟡H | Info Disclosure (client data leak) |

**Legend**: 🔴C = Critical, 🟡H = High, 🟢M = Medium, 🟢L = Low

### Detailed STRIDE Analysis

#### S — Spoofing
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| Attacker sends email as operations@deltacrown.com.au | Shared Mailboxes | SPF/DKIM/DMARC already configured (Phase 1) | LOW |
| User impersonates Leadership group member | Teams Private Channel | Azure AD dynamic group prevents manual addition | MEDIUM |
| Compromised service account accesses brand sites | PnP Templates | Certificate-based auth with time-limited tokens | MEDIUM |

#### T — Tampering
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| Modified PnP template deploys backdoor permissions | PnP Templates | Template files in git with hash verification | HIGH |
| DLP policy modified to allow data exfiltration | DLP Policies | Compliance admin role required; audit logging | MEDIUM |
| SharePoint list data modified without audit trail | SharePoint Lists | Versioning enabled on all lists; audit log | LOW |

#### R — Repudiation
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| User denies sharing client data externally | DLP/Sharing | DLP audit logs capture all sharing events | LOW |
| Admin denies changing site permissions | Permission Model | Unified Audit Log tracks permission changes | LOW |

#### I — Information Disclosure
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| Client PII in SharePoint lists exposed to wrong brand | SharePoint Lists | Unique permissions + sensitivity labels + DLP | HIGH |
| Teams chat file sharing bypasses DLP | Teams Workspace | DLP applies to Teams chat + channels | MEDIUM |
| Search returns cross-brand results | Hub Search | Hub search scoped; unique permissions prevent access | MEDIUM |
| PnP template contains credentials or secrets | PnP Templates | Template review checklist; no credentials in templates | LOW |

#### D — Denial of Service
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| Mass file upload exhausts storage quota | SharePoint Sites | Storage quotas per site collection | LOW |
| Recursive PnP template application | PnP Templates | Idempotent scripts with pre-check | LOW |

#### E — Elevation of Privilege
| Threat | Component | Mitigation | Residual Risk |
|--------|-----------|------------|---------------|
| User adds themselves to Leadership group | Azure AD Groups | Dynamic groups only; no manual membership | LOW |
| Teams owner grants guest access | Teams Workspace | Guest access disabled at team level; tenant policy | MEDIUM |
| PnP app registration has excessive permissions | PnP Templates | Least-privilege; certificate auth; PIM for admin | HIGH |

### Critical Findings Requiring Action

**CRITICAL-P3-1: Client PII in SharePoint Lists**
- **Threat**: Client Records list contains PII (name, email, phone, allergy notes)
- **Impact**: Privacy breach if exposed to wrong brand or externally
- **Mitigation**: Unique permissions; DCE-Internal sensitivity label; DLP block on external sharing
- **Action**: Implement column-level security review; consider encrypting allergy/medical fields

**CRITICAL-P3-2: PnP Template Security**
- **Threat**: Template files contain permission structures that could be tampered with
- **Impact**: Future brand deployments could have backdoor access
- **Mitigation**: Git-tracked templates; hash verification before deployment; template review process
- **Action**: Add SHA-256 hash verification to template export/import scripts

**HIGH-P3-1: DLP Test Mode Gap**
- **Threat**: 90-day test mode means DLP rules are not enforcing for 3 months
- **Impact**: Data leakage possible during test period
- **Mitigation**: Manual monitoring; weekly DLP match review; accelerate to enforce if no false positives
- **Action**: Weekly DLP report review during test period; document in runbook

---

## Phase 3 Implementation Timeline

### Day 1-2: SharePoint Sites Creation
```
□ Execute 3.1-DCE-Sites-Provisioning.ps1
□ Create DCE-Operations (Team Site)
  → Create Bookings list with schema
  → Create Staff Schedule list with schema
  → Create Tasks list with schema
  → Create Inventory list with schema
  → Create Daily Ops document library
  → Create Calendar
□ Create DCE-ClientServices (Team Site)
  → Create Client Records list with schema
  → Create Service Catalog list
  → Create Feedback list
  → Create Consent Forms library
□ Create DCE-Marketing (Communication Site)
  → Create Brand Assets library
  → Create Campaigns list with schema
  → Create Social Calendar list
  → Create Templates library
□ Create DCE-Docs (Team Site — Document Center)
  → Create Policies library
  → Create Training library
  → Create Forms library
  → Create Templates library
  → Create Archive library
  → Apply document metadata columns to all libraries
□ Associate all sites with DCE Hub
□ Update DCE Hub navigation to include new sites
□ Verify all sites accessible
```

### Day 3-4: Teams Workspace Setup
```
□ Execute 3.2-Teams-Provisioning.ps1
□ Create M365 Group for "Delta Crown Operations"
□ Enable as Teams team (Private)
□ Set owners: SG-DCE-Leadership members
□ Set members: SG-DCE-AllStaff members
□ Create standard channels:
  ├── Daily Ops (with Daily Ops library)
  ├── Bookings (with Bookings list tab)
  └── Marketing (with DCE-Marketing site tab)
□ Create private channel:
  └── Leadership (auto-creates separate SPO site)
□ Configure tabs in each channel:
  ├── General: Staff Schedule tab, Tasks tab
  ├── Bookings: Booking Tracker tab
  ├── Marketing: Brand Assets tab, Campaigns tab
  └── Leadership: Client Records tab, Docs & Policies tab
□ Associate Leadership channel SPO site with DCE Hub
□ Execute 3.5-Shared-Mailboxes.ps1
□ Create shared mailboxes (operations@, bookings@, info@)
□ Configure mailbox forwarding rules to Teams channels
□ Verify Teams ↔ SharePoint file sync
□ Test channel messaging and file upload
```

### Day 5-6: Security Hardening
```
□ Execute 3.3-Security-Hardening.ps1
□ Create SG-DCE-Marketing dynamic group
□ Break permission inheritance on ALL DCE sites:
  ├── DCE Hub
  ├── DCE-Operations
  ├── DCE-ClientServices
  ├── DCE-Marketing
  ├── DCE-Docs
  └── Leadership channel SPO site
□ Remove dangerous groups from ALL sites:
  ├── "Everyone"
  ├── "Everyone except external users"
  └── "All Users"
□ Apply security groups per permission matrix:
  ├── DCE Hub: SG-DCE-AllStaff=Read, SG-DCE-Leadership=Full Control
  ├── DCE-Operations: Managed by Teams
  ├── DCE-ClientServices: AllStaff=Contribute, Leadership=Full Control
  ├── DCE-Marketing: AllStaff=Read, Marketing=Edit, Leadership=Full Control
  └── DCE-Docs: AllStaff=Read, Leadership=Full Control
□ Disable external sharing on ALL DCE sites
□ Configure Teams guest access = Disabled
□ Verify no cross-brand access possible
□ Run Weekly-Permission-Audit.ps1 for baseline
□ Run Test-CrossBrandIsolation.ps1
```

### Day 7: DLP Policies Implementation
```
□ Execute 3.4-DLP-Policies.ps1
□ Create Policy 1: DCE-Data-Protection (TestWithNotifications)
  → Rule: Block cross-brand sharing
  → Rule: Warn on external sharing
  → Rule: Block external downloads
□ Create Policy 2: Corp-Data-Protection (TestWithNotifications)
  → Rule: Block external sharing of Corporate-Confidential
□ Create Policy 3: External-Sharing-Block (Enforce)
  → Rule: Block anonymous links
  → Rule: Block personal email sharing
□ Verify policies appear in Compliance Center
□ Test DLP by attempting blocked sharing action
□ Configure DLP alert notifications
□ Document DLP monitoring runbook
```

### Day 8-10: Template Capture
```
□ Execute 3.6-Template-Export.ps1
□ Export DCE-Operations site template
  → Lists, libraries, columns, views, content types
□ Export DCE-ClientServices site template
□ Export DCE-Marketing site template
□ Export DCE-Docs site template
□ Export DCE Hub navigation and theme
□ Create Teams provisioning script template
  → Parameterize team name, channels, group assignments
□ Create shared mailbox script template
  → Parameterize email addresses and domain
□ Create DLP policy script template
  → Parameterize policy names and scopes
□ Parameterize all brand-specific values:
  → Brand name, prefix, colors, logo, domain
  → Group names, site URLs, email addresses
□ Create master brand deployment script (3.0-Brand-Deploy.ps1)
  → Accepts brand config as input
  → Executes all templates in sequence
□ Test template against dev/test site
□ Document template usage for Bishops deployment
□ Calculate SHA-256 hashes for all template files
□ Store templates in templates/ directory
□ Execute 3.7-Phase3-Verification.ps1
□ Generate final verification report
```

---

## Fitness Functions

See `tests/architecture/test_adr_002_phase3_sites_teams.py` for automated checks.

---

## Research References

| Source | Tier | URL |
|--------|------|-----|
| Microsoft Learn — Planning Hub Sites | 1 | https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites |
| Microsoft Learn — PnP Provisioning Engine | 1 | https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/introducing-the-pnp-provisioning-engine |
| Microsoft Learn — Teams Connected Sites | 1 | https://learn.microsoft.com/en-us/sharepoint/teams-connected-sites |
| Microsoft Learn — Sensitivity Labels | 1 | https://learn.microsoft.com/en-us/purview/sensitivity-labels |
| Microsoft Learn — DLP Policies | 1 | https://learn.microsoft.com/en-us/purview/dlp-learn-about-dlp |
| Microsoft Learn — Teams Private Channels | 1 | https://learn.microsoft.com/en-us/microsoftteams/private-channels |
| PnP PowerShell Documentation | 2 | https://pnp.github.io/powershell/ |

**Research Directories**:
- `./research/sharepoint-hub-spoke/` — Hub & Spoke architecture
- `./research/sharepoint-provisioning/` — Provisioning patterns
- `./research/phase3-sharepoint-teams/` — Phase 3 specific research

**web-puppy Note**: Agent was unavailable during Phase 3 planning. Recommendations based on existing validated research from Phase 2 planning rounds + domain expertise. Research gaps documented in `research/phase3-sharepoint-teams/README.md`.

---

## Appendix A: Brand Template Variables Reference

| Variable | Description | DCE Value | BSH Value (example) |
|----------|-------------|-----------|---------------------|
| `{BrandName}` | Full brand name | Delta Crown Extensions | Bishops Barbershop |
| `{BrandPrefix}` | 3-letter prefix | DCE | BSH |
| `{BrandDomain}` | Email domain | deltacrown.com.au | bishops.com.au |
| `{PrimaryColor}` | Brand primary color | #C9A227 | #1B365D |
| `{SecondaryColor}` | Brand secondary color | #1A1A1A | #FFFFFF |
| `{LightAccent}` | Light accent color | #D4B43F | #3B5998 |
| `{DarkAccent}` | Dark accent color | #B08D1F | #0F1F3D |
| `{LogoUrl}` | Brand logo URL | (DCE logo path) | (BSH logo path) |
| `{TeamName}` | Operations team name | Delta Crown Operations | Bishops Operations |
| `{LocationChoices}` | Location list values | (DCE locations) | (BSH locations) |
| `{ServiceTypes}` | Service type choices | Extensions,Maintenance,Removal,Consultation | Cut,Shave,Beard,Color |

## Appendix B: Module Version Requirements

| Module | Version | Required By |
|--------|---------|-------------|
| PnP.PowerShell | ≥ 2.0.0 | Sites, templates, hub association |
| Microsoft.Graph.Authentication | ≥ 2.0.0 | Teams, groups |
| Microsoft.Graph.Teams | ≥ 2.0.0 | Teams provisioning |
| Microsoft.Graph.Groups | ≥ 2.0.0 | Security groups |
| ExchangeOnlineManagement | ≥ 3.0.0 | DLP, shared mailboxes |
| Microsoft.Graph.Sites | ≥ 2.0.0 | SharePoint via Graph |

## Appendix C: Rollback Procedures

| Component | Rollback Method | Impact |
|-----------|----------------|--------|
| SharePoint Sites | Remove-PnPTenantSite | Data loss (backup first) |
| Hub Associations | Unregister-PnPHubSite | Navigation removed |
| Teams Team | Remove-Team | Channel history lost |
| DLP Policies | Remove-DlpCompliancePolicy | Protection removed |
| Shared Mailboxes | Remove-Mailbox -SharedMailbox | Email data lost |
| Sensitivity Labels | Remove-Label | Classification removed |
| Security Groups | Remove-MgGroup | Permission references break |

**Rollback Order** (reverse of deployment):
1. Remove DLP policies
2. Remove sensitivity label associations
3. Remove Teams team
4. Remove shared mailboxes
5. Dissociate sites from hub
6. Remove SharePoint sites
7. Remove new security groups (SG-DCE-Marketing)
