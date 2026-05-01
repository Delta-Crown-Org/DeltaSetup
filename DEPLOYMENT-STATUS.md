# Delta Crown Extensions — Live Deployment Status

**Tenant:** deltacrown (`ce62e17d-2feb-4e67-a115-8ea4af68da30`)  
**Last Updated:** April 30, 2026  
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

> **Current readiness note:** This status reflects the earlier Phase 3 ClientServices model. Current readiness planning treats ClientServices/client-record assumptions as legacy and uses Brand Resources for approved reference material. See `docs/brand-resources-target-model.md` and `docs/legacy-clientservices-cleanup-register.md` before treating this section as implementation guidance.


### Sites (4)
| Site | Type | Hub | Theme |
|------|------|-----|-------|
| dce-operations | Team Site (STS#3) | ✅ DCE-Hub | ✅ Gold/Black |
| dce-clientservices *(legacy — see DeltaSetup-130)* | Team Site (STS#3) | ✅ DCE-Hub | ✅ Gold/Black |
| dce-marketing | Communication Site | ✅ DCE-Hub | ✅ Gold/Black |
| dce-docs | Document Center | ✅ DCE-Hub | ✅ Gold/Black |

### Libraries (8)
| Site | Libraries |
|------|-----------|
| dce-operations | Daily Ops |
| dce-clientservices *(legacy)* | Consent Forms |
| dce-marketing | Brand Assets, Templates |
| dce-docs | Policies, Training, Forms, Templates, Archive |

### Lists (6)
| Site | Lists |
|------|-------|
| dce-operations | Bookings, Staff Schedule, Tasks, Inventory, Calendar |
| dce-clientservices *(legacy)* | Client Records, Service Catalog, Feedback |
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
                        ├── dce-clientservices (Team Site) [legacy — see DeltaSetup-130]
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

## ⏭️ Phase 4: Document Migration — SKIPPED BY DECISION

### Decision
Tyler explicitly decided on 2026-04-29 that **no HTTHQ document migration will be performed** as part of this rollout.

### Status
- ⏭️ No files will be copied from `httbrands.sharepoint.com/sites/HTTHQ` to `deltacrown`.
- ⏭️ Migration scripts/config remain in the repo as historical tooling only; they are not part of the active deployment path.
- ✅ SharePoint/Teams architecture continues without migrated HTTHQ content.
- ⏳ E2E testing should validate sites, navigation, permissions, Exchange, DLP, and onboarding **without document migration assumptions**.
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

2. **Document Migration** — SKIPPED ⏭️
   - Tyler confirmed on 2026-04-29 that no HTTHQ document migration will be performed.
   - Do not run `phase4-migration/scripts/4.3-Document-Migration.ps1` for production cutover.

3. **E2E Testing** — validate all sites, lists, permissions, mailboxes, Exchange, DLP, and onboarding without document migration assumptions.

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
