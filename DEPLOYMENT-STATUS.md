# Delta Crown Extensions — Live Deployment Status

**Tenant:** deltacrown (`ce62e17d-2feb-4e67-a115-8ea4af68da30`)  
**Last Updated:** June 2025  
**Deployed By:** planning-agent-ba064f (Richard) + pack-leader

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
- ✅ 4 Azure AD dynamic groups: DCE-AllStaff, DCE-Managers, DCE-Stylists, DCE-External

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
| DCE Operations | operations@deltacrown.com | DCE-AllStaff | DCE-Managers | None |
| DCE Bookings | bookings@deltacrown.com | DCE-AllStaff | DCE-AllStaff | 24hr confirmation |
| DCE Info | info@deltacrown.com | DCE-AllStaff | DCE-Managers | 48hr response |

### Architecture Note
> **Hybrid group strategy**: Azure AD dynamic security groups (DCE-AllStaff, DCE-Managers, etc.) remain for SharePoint/Teams permissions. Exchange Dynamic Distribution Groups provide independent mail routing at @deltacrown.com. This gives maximum versatility on Business Premium licensing.

---

## ⚠️ Known Issues — Pre-Existing Naming Conflicts

> **These do NOT block Phase 5 Exchange deployment.** They block re-running older Phase 3 scripts.

### Issue 1: Group Name Mismatch (DeltaSetup-106)

Azure AD groups in the live tenant: `DCE-AllStaff`, `DCE-Managers`, `DCE-Stylists`, `DCE-External`

Most Phase 2/3 scripts reference: `SG-DCE-AllStaff`, `SG-DCE-Leadership`, `SG-DCE-Marketing`

**Affected:** 3.0-Master-Phase3.ps1, 3.2-Teams-Provisioning.ps1, 3.3-Security-Hardening.ps1, 3.7-Phase3-Verification.ps1, deploy-phase3-complete.ps1, 2.3-AzureAD-DynamicGroups.ps1, 2.4-Verification.ps1, security-controls/*.ps1, DeltaCrown.Config.psd1 (DynamicGroups section)

**Already fixed:** 3.5-Shared-Mailboxes.ps1, 5.1-Exchange-Setup.ps1

### Issue 2: `deltacrown.com.au` Domain Typo (DeltaSetup-107)

Correct domain: `deltacrown.com`. ~37 occurrences of `.com.au` across ADRs, scripts, specs, and Python tests. Most critically in `3.0-Master-Phase3.ps1` which sets `BrandDomain = "deltacrown.com.au"`.

**Already fixed:** DEPLOYMENT-RUNBOOK.md, 3.5-Shared-Mailboxes.ps1, 5.1-Exchange-Setup.ps1

---

## Next Steps

1. **Run Phase 5 pre-flight** to verify Exchange Online is active:
   ```bash
   cd ~/dev/DeltaSetup/phase3-week2/scripts
   pwsh -File ./5.1-Exchange-Setup.ps1 -VerifyOnly
   ```

2. **Execute Phase 5** once Exchange is confirmed active:
   ```bash
   pwsh -File ./5.1-Exchange-Setup.ps1
   ```

3. **Execute Phase 4 migration** from Tyler's local machine:
   ```bash
   cd ~/dev/DeltaSetup/phase4-migration/scripts
   pwsh -File ./4.3-Document-Migration.ps1 -MappingFile '../config/dce-file-mapping.csv'
   ```

4. **E2E Testing** — validate all sites, lists, permissions, mailboxes

5. **User Onboarding** — add DCE users, assign licenses, set up personal shared mailboxes

6. **Production Launch** 🚀

**Ready when you are, Tyler! 🐶**
