# Delta Crown Extensions — Live Deployment Status

**Tenant:** deltacrown (`ce62e17d-2feb-4e67-a115-8ea4af68da30`)  
**Last Updated:** June 14, 2025  
**Deployed By:** code-puppy-1a19cb (Richard) + pack-leader

---

## ✅ Phase 2: Hub & Spoke — COMPLETE

### Hub Sites (2)
| Site | Type | Hub ID | Status |
|------|------|--------|--------|
| corp-hub | Communication | `a2d9c03e-ec39-4ac5-b8ca-1504681c0b4d` | ✅ Registered |
| dce-hub | Communication | `c5efc225-1d3c-4d5f-a3f0-bcae08ac5d87` | ✅ Registered |

### Spoke Sites (4)
| Site | Associated To | Status |
|------|---------------|--------|
| corp-hr | corp-hub | ✅ |
| corp-it | corp-hub | ✅ |
| corp-finance | corp-hub | ✅ |
| corp-training | corp-hub | ✅ |

### Configuration
- ✅ DCE Gold/Black theme applied
- ✅ Corp-Hub navigation: Home, HR, IT, Finance, Training, DCE Hub
- ✅ DCE-Hub navigation + placeholder pages
- ✅ 4 Azure AD dynamic groups: AllStaff, Managers, Stylists, External

---

## ✅ Phase 3: DCE Sites — COMPLETE

### Sites (4)
| Site | Type | Hub | Theme |
|------|------|-----|-------|
| dce-operations | Team Site (STS#3) | ✅ DCE-Hub | ✅ Gold/Black |
| dce-clientservices | Team Site (STS#3) | ✅ DCE-Hub | ✅ Gold/Black |
| dce-marketing | Communication Site | ✅ DCE-Hub | ✅ Gold/Black |
| dce-docs | Document Center | ✅ DCE-Hub | ✅ Gold/Black |

### Libraries (8)
| Site | Libraries |
|------|-----------|
| dce-operations | Daily Ops |
| dce-clientservices | Consent Forms |
| dce-marketing | Brand Assets, Templates |
| dce-docs | Policies, Training, Forms, Templates, Archive |

### Lists (6)
| Site | Lists |
|------|-------|
| dce-operations | Bookings, Staff Schedule, Tasks, Inventory, Calendar |
| dce-clientservices | Client Records, Service Catalog, Feedback |
| dce-marketing | Campaigns, Social Calendar |

### Metadata (dce-docs)
- DocType, Department, ReviewDate, DocVersion, DocStatus

---

## Architecture Overview

```
                        CORP-HUB (Root)
                        ├── corp-hr
                        ├── corp-it
                        ├── corp-finance
                        └── corp-training

                        DCE-HUB (Brand Hub)
                        ├── dce-operations (Team Site)
                        │   └── Lists: Bookings, Staff Schedule, Tasks, Inventory, Calendar
                        │   └── Library: Daily Ops
                        ├── dce-clientservices (Team Site)
                        │   └── Lists: Client Records, Service Catalog, Feedback
                        │   └── Library: Consent Forms
                        ├── dce-marketing (Communication Site)
                        │   └── Lists: Campaigns, Social Calendar
                        │   └── Libraries: Brand Assets, Templates
                        └── dce-docs (Document Center)
                            └── Libraries: Policies, Training, Forms, Templates, Archive
                            └── Metadata: DocType, Department, ReviewDate, Version, Status
```

---

## ✅ Phase 4: Document Migration — READY

### Migration Plan
| Priority | Folders | Destination |
|----------|---------|-------------|
| P1 (Critical) | 4 | Operations, Franchisees, Financials, Marketing |
| P2 (Standard) | 4 | Status, Fran Dev, Product, Strategy |
| P3 (Deferred) | 4 | Training, Archive, Corp Docs, Real-Estate |

### Source → Destination Mapping
| Source (HTTHQ) | Destination (DCE) |
|----------------|-------------------|
| Master DCE/Operations | dce-operations/Documents/Operations |
| Master DCE/_Franchisees | dce-operations/Documents/Franchisees |
| Master DCE/Marketing | dce-marketing/Brand Assets/Marketing |
| Master DCE/Training | dce-docs/Training |
| Master DCE/Corp Docs | corp-hub/Shared Documents/Corporate |

### Status
- ✅ Migration mapping complete (12 folders)
- ✅ Preview scripts ready
- ⏳ File copy pending Tyler execution
- ⏳ E2E testing pending
- ⏳ User onboarding pending

---

## ⏳ Phase 5: Exchange Online — READY TO DEPLOY

### Prerequisites
- [ ] Pax8 CSP relationship established for deltacrown tenant
- [ ] At least one licensed mailbox user (Lindy Sturgill) to activate Exchange Online
- [ ] DNS records (SPF, DKIM, DMARC) verified for deltacrown.com ✅

### Script: `phase3-week2/scripts/5.1-Exchange-Setup.ps1`

**Run verification first:**
```powershell
cd ~/dev/DeltaSetup/phase3-week2/scripts
pwsh -File ./5.1-Exchange-Setup.ps1 -VerifyOnly
```

**Then full deployment:**
```powershell
pwsh -File ./5.1-Exchange-Setup.ps1
```

### Dynamic Distribution Groups (3)
| DDG | Email | Recipient Filter |
|-----|-------|-----------------|
| DCE All Staff | allstaff@deltacrown.com | Company = "Delta Crown Extensions" |
| DCE Managers | managers@deltacrown.com | Company = "DCE" + Title contains "Manager" |
| DCE Stylists | stylists@deltacrown.com | Company = "DCE" + Title contains "Stylist" |

### Shared Mailboxes (3)
| Mailbox | Email | Send-As | Full Access | Auto-Reply |
|---------|-------|---------|-------------|------------|
| DCE Operations | operations@deltacrown.com | AllStaff | Managers | None |
| DCE Bookings | bookings@deltacrown.com | AllStaff | AllStaff | 24hr confirmation |
| DCE Info | info@deltacrown.com | AllStaff | Managers | 48hr response |

### Architecture Note
> **Hybrid group strategy**: Azure AD dynamic security groups (AllStaff, Managers, etc.) remain for SharePoint/Teams permissions. Exchange Dynamic Distribution Groups provide independent mail routing at @deltacrown.com. This gives maximum versatility on Business Premium licensing.

---

## ✅ Resolved Issues

### Issue 1: Group Name Mismatch (DeltaSetup-106) — FIXED

All scripts now use prefix-free group names: `AllStaff`, `Managers`, `Stylists`, `External`, `Marketing`.

**✅ COMPLETED:** Live Azure AD groups renamed via `rename-groups.ps1`.

### Issue 2: `deltacrown.com.au` Domain Typo (DeltaSetup-107) — FIXED

All 37 occurrences of `.com.au` replaced with `.com` across scripts, tests, ADRs, and docs.

---

## Next Steps

1. **Security Hardening** — COMPLETE ✅
   - Completed live on 2026-04-29 via PnP DeviceLogin.
   - Applied DCE group→role matrix and disabled external sharing across DCE + corp sites.

2. **Execute Phase 4 migration** (blocked on HTT Brands source PnP auth):
   ```bash
   cd ~/dev/DeltaSetup/phase4-migration/scripts
   pwsh -File ./4.3-Document-Migration.ps1 -MappingFile '../config/dce-file-mapping.csv'
   ```

3. **E2E Testing** — validate all sites, lists, permissions, mailboxes, Exchange

4. **Delete temp app** `DeltaCrown-TeamsProvisioner-TEMP` from Azure AD (secret auto-expires 2026-04-16)

5. **Production Launch** 🚀

## Completed Milestones

| Milestone | Date | Status |
|-----------|------|--------|
| Phase 2: Hub & Spoke | Prior | ✅ |
| Phase 3: DCE Sites | Prior | ✅ |
| DeltaSetup-106: Group cleanup | 2025-06-14 | ✅ |
| DeltaSetup-107: Domain typo fix | 2025-06-14 | ✅ |
| Azure AD group rename | 2025-06-14 | ✅ |
| Phase 5.1: Exchange Online | 2025-06-14 | ✅ |
| Phase 3.2: Teams workspace | 2025-06-15 | ✅ |
| Phase 3.4: DLP Policies (3 custom) | 2025-06-15 | ✅ |
| Marketing dynamic group created | 2025-06-15 | ✅ |
| DLP PII type fix (AU→US) | 2025-06-15 | ✅ |

**Let's go, Tyler! 🐶**
