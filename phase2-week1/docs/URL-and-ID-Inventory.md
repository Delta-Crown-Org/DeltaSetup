# Phase 2.1-2.3: URL and ID Inventory
## Delta Crown Extensions - SharePoint Hub & Spoke Architecture

> **Generated:** Will be populated during provisioning  
> **Tenant:** deltacrown.sharepoint.com  
> **Status:** Template - Update after execution

---

## 1. Corporate Shared Services Hub

### Primary Hub
| Property | Value |
|----------|-------|
| **Title** | Corporate Shared Services |
| **URL** | https://deltacrown.sharepoint.com/sites/corp-hub |
| **Hub ID** | *{Populated after provisioning}* |
| **Template** | Communication Site (SITEPAGEPUBLISHING#0) |
| **Owner** | *{Admin email}* |
| **Created Date** | *{Date}* |

### Associated Sites

| Site Name | URL | Hub Association | Status |
|-----------|-----|-----------------|--------|
| Corporate HR | https://deltacrown.sharepoint.com/sites/corp-hr | Corp-Hub | *{Created/Existing}* |
| Corporate IT | https://deltacrown.sharepoint.com/sites/corp-it | Corp-Hub | *{Created/Existing}* |
| Corporate Finance | https://deltacrown.sharepoint.com/sites/corp-finance | Corp-Hub | *{Created/Existing}* |
| Corporate Training | https://deltacrown.sharepoint.com/sites/corp-training | Corp-Hub | *{Created/Existing}* |

### Hub Navigation Structure
```
Corp-Hub Navigation
├── Home (/sites/corp-hub)
├── HR Resources (/sites/corp-hr)
├── IT Support (/sites/corp-it)
├── Finance (/sites/corp-finance)
└── Training (/sites/corp-training)
```

---

## 2. Delta Crown Extensions Hub

### Brand Hub
| Property | Value |
|----------|-------|
| **Title** | Delta Crown Extensions Hub |
| **URL** | https://deltacrown.sharepoint.com/sites/dce-hub |
| **Hub ID** | *{Populated after provisioning}* |
| **Parent Hub** | Corp-Hub (sites/corp-hub) |
| **Theme** | Delta Crown Extensions Theme |
| **Primary Color** | #C9A227 (Gold) |
| **Secondary Color** | #1A1A1A (Black) |
| **Owner** | *{Admin email}* |

### Hub Navigation Structure
```
DCE-Hub Navigation (Inherits from Corp-Hub)
├── Home (/sites/dce-hub)
├── Operations
├── Client Services
├── Marketing
└── Document Center
```

### Initial Pages Created
- Operations.aspx
- Client-Services.aspx
- Marketing.aspx
- Document-Center.aspx

---

## 3. Azure AD Dynamic Groups

### Group Inventory

| Group Name | Object ID | Type | Membership Rule |
|------------|-----------|------|-----------------|
| **AllStaff** | *{GUID}* | Dynamic Security | `(user.department -contains "Delta Crown") -or (user.companyName -contains "Delta Crown Extensions")` |
| **Managers** | *{GUID}* | Dynamic Security | `(user.companyName -contains "Delta Crown") -and ((user.jobTitle -contains "Manager") -or (user.jobTitle -contains "Director") -or (user.jobTitle -contains "VP"))` |

### Group Usage Matrix

| Resource | AllStaff | Managers |
|----------|-----------------|-------------------|
| DCE-Hub (Visitors) | ✅ | ✅ |
| DCE-Hub (Members) | ✅ | ✅ |
| DCE-Hub (Owners) | ❌ | ✅ |
| Corp-Hub | ❌ | ❌ |
| Confidential Libraries | ❌ | ✅ |

---

## 4. Hub & Spoke Topology

```
                    ┌─────────────────────────────────────┐
                    │                                     │
                    │     CORPORATE SHARED SERVICES       │
                    │         (Corp-Hub)                  │
                    │     /sites/corp-hub                 │
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Corp-HR       │    │   Corp-IT       │    │ Corp-Finance    │
│ /sites/corp-hr  │    │ /sites/corp-it  │    │/sites/corp-finance
└─────────────────┘    └─────────────────┘    └─────────────────┘

                                   │
                                   │ (Hub-to-Hub)
                                   ▼
                    ┌─────────────────────────────────────┐
                    │                                     │
                    │   DELTA CROWN EXTENSIONS HUB        │
                    │         (DCE-Hub)                   │
                    │      /sites/dce-hub                 │
                    │         [Gold Theme]                │
                    └─────────────────────────────────────┘
```

---

## 5. Security Boundaries

### Site Permission Matrix

| Site | Owners | Members | Visitors |
|------|--------|---------|----------|
| Corp-Hub | *Admin* | *TBD* | *TBD* |
| Corp-HR | *Admin* | HR Staff | All Staff |
| Corp-IT | *Admin* | IT Staff | All Staff |
| Corp-Finance | *Admin* | Finance Staff | Leadership Only |
| Corp-Training | *Admin* | Training Staff | All Staff |
| DCE-Hub | Managers | AllStaff | AllStaff |

### Important Notes
- **No Information Barriers** in Business Premium
- Never use "Everyone" or "All Users" groups
- Use dynamic groups for automatic membership management
- Review permissions quarterly

---

## 6. File Locations

### Generated Files
| File | Location | Description |
|------|----------|-------------|
| Corp Hub ID | `phase2-week1/docs/corp-hub-id.txt` | Hub Site ID |
| DCE Hub ID | `phase2-week1/docs/dce-hub-id.txt` | Hub Site ID |
| Site Inventory | `phase2-week1/docs/corp-sites-inventory.csv` | All created sites |
| Group Config | `phase2-week1/docs/azure-ad-groups-config.json` | Group details |
| Provisioning Log | `phase2-week1/logs/*.log` | Execution logs |

---

*This document should be updated after each provisioning run with actual IDs and URLs.*
