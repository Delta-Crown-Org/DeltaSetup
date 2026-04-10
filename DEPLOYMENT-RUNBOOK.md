# Delta Crown Extensions — Deployment Runbook

## Overview

This runbook deploys the complete SharePoint Hub & Spoke architecture for Delta Crown Extensions (DCE) — the first brand on the `deltacrownext` M365 tenant.

**Total deployment time**: ~45 minutes (Phase 2) + ~30 minutes (Phase 3)
**Browser prompts**: 4 per phase (SharePoint, Graph, Exchange, IPPS)
**Prerequisites**: PowerShell 7+, PnP.PowerShell ≥ 2.0, Microsoft.Graph ≥ 2.0, ExchangeOnlineManagement ≥ 3.0

## Pre-Flight Checklist

- [ ] PowerShell 7+ installed (`pwsh --version`)
- [ ] Required modules installed:
  ```powershell
  Install-Module PnP.PowerShell -MinimumVersion 2.0.0
  Install-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0
  Install-Module Microsoft.Graph.Groups -MinimumVersion 2.0.0
  Install-Module Microsoft.Graph.Teams -MinimumVersion 2.0.0
  Install-Module Microsoft.Graph.Identity.DirectoryManagement -MinimumVersion 2.0.0
  Install-Module ExchangeOnlineManagement -MinimumVersion 3.0.0
  ```
- [ ] You have Global Admin or SharePoint Admin on `deltacrownext`
- [ ] You know your admin email (e.g., `tyler@deltacrownext.onmicrosoft.com`)

## Phase 2: Foundation (Hub Sites + Security Groups)

### What It Creates

| Component | Details |
|-----------|---------|
| **Corp Hub** | `/sites/corp-hub` — Corporate Shared Services (Communication Site) |
| **Service Sites** | `/sites/corp-hr`, `/sites/corp-it`, `/sites/corp-finance`, `/sites/corp-training` |
| **DCE Hub** | `/sites/dce-hub` — Delta Crown Extensions Hub (Communication Site, gold/black theme) |
| **Hub-to-Hub Link** | DCE-Hub → Corp-Hub parent association |
| **Security Groups** | `SG-DCE-AllStaff` (dynamic), `SG-DCE-Leadership` (dynamic) |
| **Navigation** | Hub navigation on both Corp and DCE hubs |
| **Branding** | Delta Crown gold (#C9A227) / black (#1A1A1A) theme applied to DCE Hub |

### Run It

```powershell
cd phase2-week1/scripts

# Option A: Full deployment (recommended first time)
./2.0-Master-Provisioning.ps1 `
    -TenantName "deltacrownext" `
    -OwnerEmail "YOUR_ADMIN_EMAIL" `
    -Environment Development `
    -SkipBusinessPremiumWarning

# Option B: Dry run first (see what would happen)
./2.0-Master-Provisioning.ps1 `
    -TenantName "deltacrownext" `
    -OwnerEmail "YOUR_ADMIN_EMAIL" `
    -Environment Development `
    -SkipBusinessPremiumWarning `
    -WhatIf
```

### What You'll See

1. ⚠️ Business Premium warning banner (skipped with `-SkipBusinessPremiumWarning`)
2. 🔐 Browser pop-up → SharePoint Admin (approve once)
3. 📦 Corp Hub creation (~2 min)
4. 📦 4 service site creation (~5 min)
5. 🔒 Permission hardening on all sites
6. 📦 DCE Hub creation + branding (~3 min)
7. 🔗 Hub-to-hub association
8. 🔐 Browser pop-up → Microsoft Graph (approve once)
9. 👥 Dynamic security group creation (~1 min)
10. ✅ Verification sweep

### If Something Fails

The orchestrator has **automatic rollback** — if a step fails, it cleans up created resources. To resume from a specific step:

```powershell
# Run only the DCE Hub step
./2.0-Master-Provisioning.ps1 -ExecuteTasks "2.2" -OwnerEmail "YOUR_EMAIL" -SkipBusinessPremiumWarning

# Run only the groups step
./2.0-Master-Provisioning.ps1 -ExecuteTasks "2.3" -OwnerEmail "YOUR_EMAIL" -SkipBusinessPremiumWarning
```

---

## Phase 3: Brand Sites + Teams + Security (requires Phase 2 complete)

### What It Creates

| Component | Details |
|-----------|---------|
| **DCE Sites** | `dce-operations` (Team), `dce-clientservices` (Team), `dce-marketing` (Comm), `dce-docs` (Team) |
| **SharePoint Lists** | Bookings, Staff Schedule, Tasks, Inventory, Calendar, Client Records, Marketing Calendar, Brand Assets |
| **Document Libraries** | Per-site document libraries with metadata columns |
| **Teams Workspace** | "Delta Crown Operations" team with 5 channels (General, Daily Ops, Bookings, Marketing, Leadership) |
| **Private Channel** | Leadership channel (SG-DCE-Leadership only) |
| **Channel Tabs** | SharePoint list/library tabs in each channel |
| **Security Hardening** | Unique permissions on all sites, "Everyone" groups removed, permission matrix applied |
| **DLP Policies** | DCE-Data-Protection (test), Corp-Data-Protection (test), External-Sharing-Block (enforce) |
| **Shared Mailboxes** | operations@, bookings@, info@ (deltacrown.com.au) |
| **SG-DCE-Marketing** | New dynamic security group for marketing staff |
| **PnP Templates** | Exported templates for brand replication |

### Run It

```powershell
cd phase3-week2/scripts

# Full deployment
./3.0-Master-Phase3.ps1 `
    -TenantName "deltacrownext" `
    -Environment Development `
    -AdminUrl "https://deltacrownext-admin.sharepoint.com"
```

### What You'll See

1. ✅ Phase 2 pre-check (verifies Corp Hub + DCE Hub exist)
2. 🔐 4 browser pop-ups at start (SharePoint, Graph, Exchange, IPPS) — approve all
3. 📦 4 DCE sites with all lists/columns/views (~10 min)
4. 💬 Teams workspace + channels + tabs (~5 min)
5. 🔒 Security hardening + permission matrix (~5 min)
6. 🛡️ DLP policy creation (~2 min)
7. 📧 Shared mailbox setup (~3 min)
8. 📋 PnP template export (~5 min)
9. ✅ Full verification sweep (JSON report)

### Resume From a Step

```powershell
# Resume from Security Hardening (steps 1-2 already done)
./3.0-Master-Phase3.ps1 -StartFrom "3.3" -TenantName "deltacrownext"

# Run only DLP policies
./3.0-Master-Phase3.ps1 -Phase "DLP" -TenantName "deltacrownext"
```

---

## Post-Deployment Verification

After both phases complete:

```powershell
# Phase 2 verification
cd phase2-week1/scripts
./2.4-Verification.ps1 -TenantName "deltacrownext" -CheckPermissions -ExportResults

# Phase 3 verification
cd phase3-week2/scripts
./3.7-Phase3-Verification.ps1 -TenantName "deltacrownext"
```

### Expected Verification Output

| Category | Expected Result |
|----------|----------------|
| Corp Hub | PASS — Site exists, registered as hub |
| DCE Hub | PASS — Site exists, linked to Corp Hub |
| 4 DCE Sites | PASS — All created, hub-associated |
| Teams | PASS — Team + 5 channels + tabs |
| Permissions | PASS — Unique on all sites, no "Everyone" |
| DLP | PASS — 3 policies active |
| Mailboxes | PASS — 3 shared mailboxes functional |
| Templates | PASS — Exported with SHA-256 hashes |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "Site already exists" | Script is idempotent — skips existing, continues |
| "Access denied" | Verify you're Global Admin or SharePoint Admin |
| "Module not found" | Run `Install-Module <name> -MinimumVersion <ver>` |
| Browser pop-up doesn't appear | Close existing auth sessions: `Disconnect-PnPOnline; Disconnect-MgGraph` |
| DLP policy creation fails | Ensure your account has Compliance Admin role |
| Phase 3 pre-check fails | Run Phase 2 first, or use `-SkipPreCheck` |

## Architecture Reference

```
M365 Tenant: deltacrownext (Business Premium)
│
├── Corp-Hub (Communication Site) ◄── Shared Services
│   ├── Corp-HR
│   ├── Corp-IT
│   ├── Corp-Finance
│   └── Corp-Training
│
└── DCE-Hub (Communication Site, Gold/Black) ◄── Brand Hub
    ├── DCE-Operations (Team Site, Teams-connected)
    │   └── Lists: Bookings, Staff Schedule, Tasks, Inventory, Calendar
    ├── DCE-ClientServices (Team Site)
    │   └── Lists: Client Records (PII), Service History
    ├── DCE-Marketing (Communication Site)
    │   └── Lists: Marketing Calendar, Brand Assets
    └── DCE-Docs (Team Site)
        └── Libraries: Policies, SOPs, Training Materials

Security Groups:
├── SG-DCE-AllStaff (Dynamic: department contains "Delta Crown")
├── SG-DCE-Leadership (Dynamic: company "Delta Crown" + Manager/Director/VP)
└── SG-DCE-Marketing (Dynamic: company "Delta Crown" + Marketing title)

DLP Policies:
├── DCE-Data-Protection (TestWithNotifications, 30 days)
├── Corp-Data-Protection (TestWithNotifications, 30 days)
└── External-Sharing-Block (Enforce)
```
