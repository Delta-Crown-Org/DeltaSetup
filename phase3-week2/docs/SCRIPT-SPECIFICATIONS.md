# Phase 3: Script Specifications

## Overview

Phase 3 requires 8 PowerShell scripts that build on the Phase 2 module framework (DeltaCrown.Auth, DeltaCrown.Common, DeltaCrown.Config).

## Script Dependency Chain

```
Phase 2 Complete ✅
    │
    ▼
3.1-DCE-Sites-Provisioning.ps1 ─────────────────────────────┐
    │                                                          │
    ├──▶ 3.2-Teams-Provisioning.ps1                           │
    │       │                                                  │
    │       └──▶ 3.5-Shared-Mailboxes.ps1                    │
    │                                                          │
    ├──▶ 3.3-Security-Hardening.ps1 ◀────── All sites ready  │
    │       │                                                  │
    │       └──▶ 3.4-DLP-Policies.ps1                        │
    │                                                          │
    └──▶ 3.6-Template-Export.ps1 ◀────── All configured ──────┘
            │
            ▼
        3.7-Phase3-Verification.ps1
```

## Script Details

### 3.0-Master-Phase3.ps1 — Master Orchestrator
**Purpose**: Execute all Phase 3 scripts in correct dependency order
**Est. Lines**: ~300
**Module Dependencies**: DeltaCrown.Auth, DeltaCrown.Common, DeltaCrown.Config
**Parameters**:
- `-WhatIf` — Dry run all scripts
- `-Phase` — Run specific phase (Sites, Teams, Security, DLP, Templates, Verify)
- `-Environment` — Development/Staging/Production
- `-SkipVerification` — Skip Phase 2 pre-check

**Capabilities**:
- Validates Phase 2 is deployed before proceeding
- Executes scripts in dependency order
- Supports partial execution (run from specific step)
- Comprehensive logging with timestamps
- Exit codes for CI/CD integration

---

### 3.1-DCE-Sites-Provisioning.ps1 — SharePoint Sites
**Purpose**: Create 4 DCE SharePoint sites with lists, libraries, and columns
**Est. Lines**: ~500
**Module Dependencies**: PnP.PowerShell ≥ 2.0.0
**Prerequisites**: DCE Hub exists (/sites/dce-hub)

**Creates**:
| Site | Type | Template |
|------|------|----------|
| /sites/dce-operations | Team Site | STS#3 |
| /sites/dce-clientservices | Team Site | STS#3 |
| /sites/dce-marketing | Communication Site | SITEPAGEPUBLISHING#0 |
| /sites/dce-docs | Team Site | STS#3 |

**Per-Site Actions**:
1. Create site collection
2. Associate with DCE Hub
3. Apply DCE brand theme
4. Create document libraries (per ADR-002 spec)
5. Create SharePoint lists with columns (per ADR-002 schema)
6. Create views for each list
7. Set site logo
8. Configure navigation

**Idempotency**: Checks if site exists before creating; skips if present.

---

### 3.2-Teams-Provisioning.ps1 — Teams Workspace
**Purpose**: Create Teams team, channels, and configure tabs
**Est. Lines**: ~400
**Module Dependencies**: Microsoft.Graph.Teams, Microsoft.Graph.Groups ≥ 2.0.0
**Prerequisites**: DCE-Operations site exists

**Creates**:
| Component | Details |
|-----------|---------|
| M365 Group | "Delta Crown Operations" (Private, Unified) |
| Team | From M365 Group |
| Standard Channels | Daily Ops, Bookings, Marketing |
| Private Channel | Leadership |
| Tabs | SharePoint lists/libraries in each channel |

**Steps**:
1. Create M365 Group with correct settings
2. Enable as Teams team
3. Configure team settings (guest off, member permissions restricted)
4. Create standard channels
5. Create private channel (Leadership)
6. Add tabs to each channel (SharePoint list/library connections)
7. Set owners from Managers
8. Set members from AllStaff
9. Associate Leadership channel SPO site with DCE Hub

**Idempotency**: Checks if team/channels exist before creating.

---

### 3.3-Security-Hardening.ps1 — Permission Hardening
**Purpose**: Break inheritance, remove dangerous groups, apply security groups
**Est. Lines**: ~350
**Module Dependencies**: PnP.PowerShell, Microsoft.Graph.Groups
**Prerequisites**: All 4 DCE sites exist + Leadership channel SPO site

**Actions**:
1. Create Marketing dynamic group (new in Phase 3)
2. For EACH DCE site:
   a. Break permission inheritance
   b. Remove "Everyone" group
   c. Remove "Everyone except external users"
   d. Remove "All Users"
   e. Apply correct security groups per permission matrix
3. Disable external sharing on all DCE sites
4. Configure Teams guest access = Disabled
5. Apply Teams app governance (block sideloading)
6. Verify no cross-brand access possible

**Permission Matrix Applied**:
| Site | AllStaff | Leadership | Marketing |
|------|----------|------------|-----------|
| DCE Hub | Read | Full Control | — |
| DCE-Operations | Teams managed | Teams managed | — |
| DCE-ClientServices | Contribute | Full Control | — |
| DCE-Marketing | Read | Full Control | Edit |
| DCE-Docs | Read | Full Control | — |

**Idempotency**: Checks current permissions before modifying.

---

### 3.4-DLP-Policies.ps1 — DLP Policy Creation
**Purpose**: Create 3 DLP policies for Phase 3
**Est. Lines**: ~300
**Module Dependencies**: ExchangeOnlineManagement ≥ 3.0.0
**Prerequisites**: Security hardening complete, sites associated with hub

**Creates**:
| Policy | Mode | Scope |
|--------|------|-------|
| DCE-Data-Protection | TestWithNotifications (30 days per SEC-002-1) | DCE sites + Teams |
| Corp-Data-Protection | TestWithNotifications (30 days) | Corp sites |
| External-Sharing-Block | Enforce | All sites |

**DLP Rules per Policy**:
- DCE-Data-Protection:
  - Block sharing with non-DCE recipients
  - Warn on external sharing
  - Block external download of labeled content
- Corp-Data-Protection:
  - Block external sharing of Corporate-Confidential
  - Warn on sharing outside Corp-SharedServices
- External-Sharing-Block:
  - Block anonymous link creation
  - Block personal email domain sharing

**Security Auditor Condition**: Test mode reduced to 30 days (SEC-002-1)

---

### 3.5-Shared-Mailboxes.ps1 — Shared Mailbox Setup
**Purpose**: Create brand shared mailboxes and integrate with Teams
**Est. Lines**: ~200
**Module Dependencies**: ExchangeOnlineManagement ≥ 3.0.0
**Prerequisites**: Teams team exists

**Creates**:
| Mailbox | Email | Auto-Reply | Teams Channel |
|---------|-------|------------|---------------|
| DCE Operations | operations@deltacrown.com | Off | General |
| DCE Bookings | bookings@deltacrown.com | On | Bookings |
| DCE Info | info@deltacrown.com | On | Group mailbox |

**Steps**:
1. Create each shared mailbox
2. Set Send-As permissions (AllStaff)
3. Set Full Access permissions (per spec)
4. Configure auto-reply messages
5. Set up mail forwarding to Teams channel email addresses
6. Verify SPF/DKIM/DMARC passes for brand domain

---

### 3.6-Template-Export.ps1 — PnP Template Capture
**Purpose**: Export all configured sites as reusable PnP templates
**Est. Lines**: ~400
**Module Dependencies**: PnP.PowerShell ≥ 2.0.0
**Prerequisites**: ALL Phase 3 components deployed and verified

**Exports**:
| Template | Source Site | Content |
|----------|------------|---------|
| DCE-Operations-Template.xml | /sites/dce-operations | Lists, libraries, columns, views |
| DCE-ClientServices-Template.xml | /sites/dce-clientservices | Lists, libraries, columns, views |
| DCE-Marketing-Template.xml | /sites/dce-marketing | Libraries, lists, pages |
| DCE-Docs-Template.xml | /sites/dce-docs | Libraries, metadata columns |
| DCE-Hub-Theme.json | /sites/dce-hub | Color palette, theme settings |

**Post-Export Steps**:
1. Parameterize brand-specific values (replace DCE with {BrandPrefix})
2. Calculate SHA-256 hash for each template file
3. Store hashes in template-hashes.json
4. Generate companion script templates (Teams, mailboxes, DLP, groups)
5. Create brand-config.psd1 template
6. Test template application against dev/test site (if available)

---

### 3.7-Phase3-Verification.ps1 — Comprehensive Verification
**Purpose**: Verify all Phase 3 components are correctly deployed
**Est. Lines**: ~500
**Module Dependencies**: All modules
**Prerequisites**: All Phase 3 scripts executed

**Verification Checks**:
| Category | Checks |
|----------|--------|
| Sites | All 4 sites exist and accessible |
| Hub Association | All sites associated with DCE Hub |
| Lists | All required lists created with correct columns |
| Libraries | All required libraries exist |
| Teams | Team exists with 5 channels |
| Channels | Private channel correctly configured |
| Tabs | All tabs correctly configured |
| Permissions | Unique permissions on all sites |
| Forbidden Groups | No Everyone/All Users on any site |
| Security Groups | Marketing created and populated |
| DLP | All 3 policies exist and active |
| Mailboxes | All 3 shared mailboxes functional |
| External Sharing | Disabled on all DCE sites |
| Guest Access | Disabled at team level |
| Templates | All exported with valid hashes |

**Output**: JSON verification report + console summary
**Exit Codes**: 0 = all pass, 1 = warnings, 2 = failures
