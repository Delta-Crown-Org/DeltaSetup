# Phase 3: SharePoint Site Structure & Teams Integration Diagram

## Complete Architecture View

```
┌──────────────────────────────────────────────────────────────────┐
│                    M365 TENANT (Business Premium)                 │
│                    Tenant: deltacrownext                          │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  CORPORATE SHARED SERVICES HUB (Phase 2 ✅)                 │ │
│  │  URL: /sites/corp-hub                                        │ │
│  │  Type: Communication Site                                    │ │
│  │                                                               │ │
│  │  Associated: corp-hr, corp-it, corp-finance, corp-training   │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  DELTA CROWN EXTENSIONS HUB (Phase 2 ✅)                    │ │
│  │  URL: /sites/dce-hub                                         │ │
│  │  Type: Communication Site (Gold #C9A227 / Black #1A1A1A)    │ │
│  │                                                               │ │
│  │  ┌───────────────────────────────────────────────────────┐   │ │
│  │  │  DCE-Operations (Phase 3 🆕)                          │   │ │
│  │  │  URL: /sites/dce-operations                            │   │ │
│  │  │  Type: Team Site — TEAMS-CONNECTED                     │   │ │
│  │  │  Team: "Delta Crown Operations"                        │   │ │
│  │  │                                                         │   │ │
│  │  │  📁 Libraries:                                          │   │ │
│  │  │  ├── Documents (General channel files)                  │   │ │
│  │  │  └── Daily Ops (Daily Ops channel files)               │   │ │
│  │  │                                                         │   │ │
│  │  │  📋 Lists:                                              │   │ │
│  │  │  ├── Bookings (client booking tracker)                 │   │ │
│  │  │  ├── Staff Schedule (weekly roster)                    │   │ │
│  │  │  ├── Tasks (operational tasks)                         │   │ │
│  │  │  ├── Inventory (product inventory)                     │   │ │
│  │  │  └── Calendar (team calendar)                          │   │ │
│  │  │                                                         │   │ │
│  │  │  🔗 Teams Channels:                                     │   │ │
│  │  │  ├── General → Documents library                       │   │ │
│  │  │  ├── Daily Ops → Daily Ops library                     │   │ │
│  │  │  ├── Bookings → [Tab: Bookings list]                   │   │ │
│  │  │  ├── Marketing → [Tab: DCE-Marketing site]             │   │ │
│  │  │  └── Leadership (PRIVATE) → Separate SPO site          │   │ │
│  │  └───────────────────────────────────────────────────────┘   │ │
│  │                                                               │ │
│  │  ┌───────────────────────────────────────────────────────┐   │ │
│  │  │  DCE-ClientServices (Phase 3 🆕)                       │   │ │
│  │  │  URL: /sites/dce-clientservices                         │   │ │
│  │  │  Type: Team Site — STANDALONE (no Teams)               │   │ │
│  │  │                                                         │   │ │
│  │  │  📁 Libraries:                                          │   │ │
│  │  │  ├── Documents (general client docs)                   │   │ │
│  │  │  └── Consent Forms (signed consent PDFs)               │   │ │
│  │  │                                                         │   │ │
│  │  │  📋 Lists:                                              │   │ │
│  │  │  ├── Client Records (⚠️ PII — name, email, phone)     │   │ │
│  │  │  ├── Service Catalog (services + pricing)              │   │ │
│  │  │  └── Feedback (client satisfaction)                    │   │ │
│  │  │                                                         │   │ │
│  │  │  🔒 Access: Leadership tab in Teams                    │   │ │
│  │  └───────────────────────────────────────────────────────┘   │ │
│  │                                                               │ │
│  │  ┌───────────────────────────────────────────────────────┐   │ │
│  │  │  DCE-Marketing (Phase 3 🆕)                            │   │ │
│  │  │  URL: /sites/dce-marketing                              │   │ │
│  │  │  Type: Communication Site — STANDALONE                  │   │ │
│  │  │                                                         │   │ │
│  │  │  📁 Libraries:                                          │   │ │
│  │  │  ├── Brand Assets (logos, photos, videos)              │   │ │
│  │  │  └── Templates (flyers, social posts)                  │   │ │
│  │  │                                                         │   │ │
│  │  │  📋 Lists:                                              │   │ │
│  │  │  ├── Campaigns (campaign tracker)                      │   │ │
│  │  │  └── Social Calendar (posting schedule)                │   │ │
│  │  │                                                         │   │ │
│  │  │  📄 Pages: Brand landing pages, announcements          │   │ │
│  │  │  🔒 Access: Marketing channel tab in Teams             │   │ │
│  │  └───────────────────────────────────────────────────────┘   │ │
│  │                                                               │ │
│  │  ┌───────────────────────────────────────────────────────┐   │ │
│  │  │  DCE-Docs (Phase 3 🆕)                                 │   │ │
│  │  │  URL: /sites/dce-docs                                   │   │ │
│  │  │  Type: Team Site — STANDALONE (Document Center)        │   │ │
│  │  │                                                         │   │ │
│  │  │  📁 Libraries (5):                                      │   │ │
│  │  │  ├── Policies (company policies, SOPs)                 │   │ │
│  │  │  ├── Training (training materials, videos)             │   │ │
│  │  │  ├── Forms (standardized forms)                        │   │ │
│  │  │  ├── Templates (document templates)                    │   │ │
│  │  │  └── Archive (historical documents)                    │   │ │
│  │  │                                                         │   │ │
│  │  │  📊 Metadata: Doc Type, Department, Review Date,       │   │ │
│  │  │               Version, Status, Owner                    │   │ │
│  │  │  🔒 Access: Leadership tab in Teams                    │   │ │
│  │  └───────────────────────────────────────────────────────┘   │ │
│  │                                                               │ │
│  │  Navigation: Home | Operations | Clients | Marketing | Docs  │ │
│  │              | Corporate Resources → /sites/corp-hub         │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  LEADERSHIP PRIVATE CHANNEL SITE (Auto-created)             │ │
│  │  URL: /sites/dce-operations-Leadership (auto-generated)     │ │
│  │  Type: Team Site — PRIVATE CHANNEL SITE                     │ │
│  │  Access: SG-DCE-Leadership ONLY                              │ │
│  │  Hub: Must be manually associated with DCE Hub               │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Permission Flow

```
AZURE AD DYNAMIC GROUPS
├── SG-DCE-AllStaff ──────────────────────────────────────────────┐
│   Rule: department contains "Delta Crown"                       │
│                                                                  │
├── SG-DCE-Leadership ────────────────────────────────────────────┤
│   Rule: company contains "Delta Crown" AND                      │
│         title contains Manager|Director|VP|Chief                │
│                                                                  │
└── SG-DCE-Marketing (🆕 Phase 3) ───────────────────────────────┤
    Rule: department eq "Delta Crown Marketing"                   │
                                                                   │
                                                                   │
SITE PERMISSION ASSIGNMENTS (ALL UNIQUE — NO INHERITANCE)         │
                                                                   │
┌──────────────┬─────────────┬─────────────┬──────────────┐       │
│ Site          │ AllStaff    │ Leadership  │ Marketing    │       │
├──────────────┼─────────────┼─────────────┼──────────────┤       │
│ DCE Hub      │ Read        │ Full Ctrl   │ —            │       │
│ DCE-Ops      │ (Teams mgd) │ (Teams mgd) │ —            │       │
│ DCE-Client   │ Contribute  │ Full Ctrl   │ —            │       │
│ DCE-Market   │ Read        │ Full Ctrl   │ Edit         │       │
│ DCE-Docs     │ Read        │ Full Ctrl   │ —            │       │
└──────────────┴─────────────┴─────────────┴──────────────┘       │
                                                                   │
❌ BLOCKED: Everyone, Everyone except external users, All Users    │
❌ BLOCKED: External sharing (disabled at site level)              │
❌ BLOCKED: Guest access (disabled at team level)                  │
```

## Teams Integration Map

```
MICROSOFT TEAMS
└── Delta Crown Operations (Private Team)
    │
    ├── 📢 General Channel (Standard)
    │   ├── Files → /sites/dce-operations/Shared Documents/
    │   ├── Tab: Staff Schedule (SharePoint list)
    │   └── Tab: Tasks (Planner/Tasks)
    │
    ├── 📋 Daily Ops Channel (Standard)
    │   ├── Files → /sites/dce-operations/Daily Ops/
    │   └── Used for: Shift handover, daily checklists
    │
    ├── 📅 Bookings Channel (Standard)
    │   ├── Tab: Booking Tracker (SharePoint list from DCE-Operations)
    │   └── Used for: Client booking coordination
    │
    ├── 📣 Marketing Channel (Standard)
    │   ├── Tab: Brand Assets (Doc library from DCE-Marketing)
    │   ├── Tab: Campaigns (SharePoint list from DCE-Marketing)
    │   └── Used for: Social media coordination
    │
    └── 🔒 Leadership Channel (PRIVATE)
        ├── Files → /sites/dce-operations-Leadership/ (SEPARATE SPO)
        ├── Tab: Client Records (SharePoint list from DCE-ClientServices)
        ├── Tab: Docs & Policies (Doc library from DCE-Docs)
        └── Used for: Management, financials, HR decisions
```

## Shared Mailbox Integration

```
EXCHANGE ONLINE SHARED MAILBOXES
├── operations@deltacrown.com.au
│   └── → Forwarding rule → General channel email address
│
├── bookings@deltacrown.com.au
│   └── → Forwarding rule → Bookings channel email address
│
└── info@deltacrown.com.au
    └── → Team group mailbox (general)

SPF/DKIM/DMARC: Already configured (Phase 1) ✅
```

## DLP Policy Coverage

```
DLP POLICY BUDGET: 3 of 10 used in Phase 3

┌─────────────────────────────────────────────────────┐
│ Policy 1: DCE-Data-Protection (Test Mode 90 days)   │
│ Scope: DCE-Operations, DCE-ClientServices,           │
│        DCE-Marketing, DCE-Docs, DCE Teams            │
│ Rules:                                                │
│ ├── Block cross-brand sharing (DCE-Internal label)   │
│ ├── Warn on external sharing attempts                 │
│ └── Block external download of labeled content        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Policy 2: Corp-Data-Protection (Test Mode 90 days)   │
│ Scope: Corp-Hub, Corp-HR, Corp-IT, Corp-Finance,     │
│        Corp-Training                                  │
│ Rules:                                                │
│ ├── Block external sharing of Corp-Confidential       │
│ └── Warn on sharing outside SG-Corp-SharedServices    │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Policy 3: External-Sharing-Block (ENFORCE)           │
│ Scope: ALL SharePoint sites                           │
│ Rules:                                                │
│ ├── Block anonymous link creation                     │
│ └── Block sharing with personal email domains         │
└─────────────────────────────────────────────────────┘

Remaining budget: 7 policies for future brands
```

## Template Export Strategy

```
PnP TEMPLATE PACKAGE
├── Site Templates (PnP PowerShell export)
│   ├── DCE-Operations-Template.xml
│   │   └── Lists, libraries, columns, views, content types
│   ├── DCE-ClientServices-Template.xml
│   ├── DCE-Marketing-Template.xml
│   └── DCE-Docs-Template.xml
│
├── Theme Template (PnP export)
│   └── DCE-Hub-Theme.json (parameterized colors)
│
├── Companion Scripts (NOT capturable by PnP)
│   ├── Teams-Template.ps1 (Graph API — team, channels, tabs)
│   ├── Mailbox-Template.ps1 (Exchange — shared mailboxes)
│   ├── DLP-Template.ps1 (Compliance — DLP policies)
│   ├── Groups-Template.ps1 (Graph API — security groups)
│   └── Labels-Template.ps1 (Compliance — sensitivity labels)
│
├── Brand Config File
│   └── brand-config.psd1 (all parameterized values)
│       ├── {BrandName} = "Delta Crown Extensions"
│       ├── {BrandPrefix} = "DCE"
│       ├── {BrandDomain} = "deltacrown.com.au"
│       ├── {PrimaryColor} = "#C9A227"
│       └── ... (see ADR-002 Appendix A)
│
└── Master Deployer
    └── Deploy-Brand.ps1
        ├── Input: brand-config.psd1
        ├── Step 1: Create Azure AD groups
        ├── Step 2: Apply PnP site templates
        ├── Step 3: Create Teams + channels
        ├── Step 4: Create shared mailboxes
        ├── Step 5: Apply permissions
        ├── Step 6: Create DLP policies
        └── Step 7: Verify deployment
```
