# Session Handoff — Exchange Online Setup (Phase 5)

---

# Session Update — Cleanup Sprint (DeltaSetup-106, DeltaSetup-107)

**Date:** 2025-06-14 (continued)
**Agent:** code-puppy-1a19cb (Richard)
**Branch:** gh-pages

---

## What Was Accomplished This Session

### DeltaSetup-107: Domain Typo Fix ✅
- Replaced all 37 occurrences of `deltacrown.com.au` → `deltacrown.com`
- Fixed across 12 files: scripts, Python tests, ADRs, specs, docs

### DeltaSetup-106: Group Name Cleanup ✅
- Tyler decided: **no prefix** on group names (domain identifies the brand)
- Full mapping applied across **45 files**:
  - `SG-DCE-AllStaff` → `AllStaff`
  - `SG-DCE-Leadership` → `Managers`
  - `SG-DCE-Marketing` → `Marketing`
  - `DCE-AllStaff` → `AllStaff`
  - `DCE-Managers` → `Managers`
  - `DCE-Stylists` → `Stylists`
  - `DCE-External` → `External`
- Preserved: `SG-DCE-Sync-Users` (HTT Brands tenant), DCE-* site/policy names
- Fixed special patterns: `startsWith` filter in 5.1, `-replace` in 4.1

### New Files
| File | Purpose |
|------|---------|
| `phase2-week1/scripts/rename-groups.ps1` | Renames live Azure AD groups to match updated scripts |

---

## ⚠️ ACTION REQUIRED — Before Running Any Scripts

Tyler must rename the live Azure AD groups:
```powershell
cd ~/dev/DeltaSetup/phase2-week1/scripts
pwsh -File ./rename-groups.ps1
```

This renames DCE-AllStaff→AllStaff, DCE-Managers→Managers, DCE-Stylists→Stylists, DCE-External→External in the live tenant.

---

## Next Session Priorities

1. **Run rename-groups.ps1** to rename live Azure AD groups
2. **Run Exchange pre-flight** → `5.1-Exchange-Setup.ps1 -VerifyOnly`
3. **If Exchange active** → run full `5.1-Exchange-Setup.ps1`
4. **Phase 4 migration** → document migration execution
5. **E2E Testing** → validate all sites, lists, permissions, mailboxes

---


**Date:** 2025-06-14
**Agent:** planning-agent-ba064f (Richard)
**Branch:** gh-pages

---

## What Was Accomplished This Session

### New Files Created
| File | Purpose |
|------|---------|
| `phase3-week2/scripts/5.1-Exchange-Setup.ps1` | Exchange Online setup for deltacrown.com — DDGs + shared mailboxes + verification mode |
| `phase3-week2/EXCHANGE-QUICKSTART.md` | Step-by-step guide for Tyler to deploy Exchange |

### Files Modified
| File | Change |
|------|--------|
| `phase2-week1/modules/DeltaCrown.Auth.psm1` | `Connect-DeltaCrownExchange` now supports cross-tenant via `-Organization` and `-UserPrincipalName` splatting |
| `phase2-week1/modules/DeltaCrown.Config.psd1` | Added `TenantId`, `Domain`, `AdminUPN`, `ExchangeOrganization` to Tenant block |
| `phase3-week2/scripts/3.5-Shared-Mailboxes.ps1` | Domain `httbrands.com` → `deltacrown.com`, group names `SG-DCE-*` → `DCE-*` |
| `DEPLOYMENT-RUNBOOK.md` | Fixed `deltacrown.com.au` typo, added DDG reference |
| `DEPLOYMENT-STATUS.md` | Added Phase 5 section with DDGs, shared mailboxes, prerequisites |

### Reviews Completed
- Shepherd code review of 5.1 script → WhatIf bug found and fixed
- Shepherd review of auth module cross-tenant changes → Approved
- Shepherd integration consistency check → Found pre-existing naming issues (filed as issues)
- Watchdog QA → All tests pass

---

## Blocker: Exchange Online Activation

**Unknown:** Whether Exchange Online is active on the deltacrown tenant.

Exchange activates only when at least one user has an Exchange Online license. If Megan/Pax8 hasn't provisioned Lindy Sturgill's license yet, Exchange is not active.

**To check:**
```powershell
cd ~/dev/DeltaSetup/phase3-week2/scripts
pwsh -File ./5.1-Exchange-Setup.ps1 -VerifyOnly
```

**If not active:** Send the email template at `templates/email-megan-csp-request.md` to Megan.

---

## Known Issues — Must Fix Before Running Old Phase 3 Scripts

### Issue 1: Group Name Mismatch (CRITICAL for Phase 3 scripts)

The groups that **actually exist** in the deltacrown Azure AD tenant were created by `create-dce-groups.ps1`:
- `DCE-AllStaff`
- `DCE-Managers`
- `DCE-Stylists`
- `DCE-External`

But most Phase 2/3 scripts reference a different naming convention:
- `SG-DCE-AllStaff`
- `SG-DCE-Leadership`
- `SG-DCE-Marketing`

**Affected scripts (17+ references):**
- `phase3-week2/scripts/3.0-Master-Phase3.ps1`
- `phase3-week2/scripts/3.2-Teams-Provisioning.ps1`
- `phase3-week2/scripts/3.3-Security-Hardening.ps1`
- `phase3-week2/scripts/3.7-Phase3-Verification.ps1`
- `phase3-week2/scripts/deploy-phase3-complete.ps1`
- `phase2-week1/scripts/2.3-AzureAD-DynamicGroups.ps1` (defines SG-DCE-*)
- `phase2-week1/scripts/2.4-Verification.ps1`
- `phase2-week1/scripts/Execute-DevTestDeployment.ps1`
- `phase2-week1/scripts/security-controls/*.ps1` and `*.md`
- `phase2-week1/modules/DeltaCrown.Config.psd1` (DynamicGroups section still has SG-DCE-*)

**Already fixed:** `3.5-Shared-Mailboxes.ps1` and new `5.1-Exchange-Setup.ps1` use correct names.

**Decision needed:** Either rename the Azure AD groups to match scripts (SG-DCE-*), or update all scripts to match reality (DCE-*). Recommend updating scripts since groups are already live.

### Issue 2: `deltacrown.com.au` Domain Typo (~37 occurrences in 10 files)

The correct domain is `deltacrown.com`. The `.com.au` typo exists in:
- `docs/architecture/decisions/ADR-001-*.md` (5 occurrences)
- `docs/architecture/decisions/ADR-002-*.md` (11 occurrences)
- `phase3-week2/scripts/3.0-Master-Phase3.ps1` (1 — sets BrandDomain!)
- `phase3-week2/scripts/3.6-Template-Export.ps1` (1)
- `phase3-week2/scripts/3.7-Phase3-Verification.ps1` (2)
- `phase3-week2/docs/TEAMS-CONFIGURATION-SPEC.md` (6)
- `phase3-week2/docs/SITE-STRUCTURE-DIAGRAM.md` (4)
- `phase3-week2/docs/SCRIPT-SPECIFICATIONS.md` (3)
- `phase2-week1/scripts/security-controls/2-DLP-Policies-Specification.md` (1)
- `tests/architecture/test_adr_002_phase3_sites_teams.py` (4 — tests assert .com.au!)

**Already fixed:** `DEPLOYMENT-RUNBOOK.md`, `3.5-Shared-Mailboxes.ps1`, and new `5.1-Exchange-Setup.ps1` all use `deltacrown.com`.

---

## What Works vs What Doesn't

### Safe to run today ✅
- `phase3-week2/scripts/5.1-Exchange-Setup.ps1` — correct names, correct domain
- `phase3-week2/scripts/3.5-Shared-Mailboxes.ps1` — fixed this session

### Would fail against live tenant ❌
- `phase3-week2/scripts/3.0-Master-Phase3.ps1` — passes deltacrown.com.au
- `phase3-week2/scripts/3.2-Teams-Provisioning.ps1` — SG-DCE-Leadership, SG-DCE-AllStaff
- `phase3-week2/scripts/3.3-Security-Hardening.ps1` — SG-DCE-* everywhere
- `phase3-week2/scripts/3.7-Phase3-Verification.ps1` — SG-DCE-* AND deltacrown.com.au
- `phase3-week2/scripts/deploy-phase3-complete.ps1` — SG-DCE-* checks
- Security audit/control scripts — SG-DCE-* group names
- Python tests — assert deltacrown.com.au

### Already deployed to tenant (ran previously, output in tenant) ✅
- Phase 2 hub/spoke sites
- Phase 3 DCE sites, lists, libraries
- Phase 3 security hardening (⚠️ may have applied to wrong group names)

---

## Next Session Priorities

1. **Run Exchange pre-flight** → `5.1-Exchange-Setup.ps1 -VerifyOnly`
2. **If Exchange active** → run full `5.1-Exchange-Setup.ps1`
3. **Cleanup sprint** → fix SG-DCE-* → DCE-* across all scripts
4. **Cleanup sprint** → fix deltacrown.com.au → deltacrown.com across all files
5. **Verify** → check what Phase 3 security hardening actually applied to the live tenant
6. **Phase 4 migration** → document migration execution

---

## Key Files Quick Reference

| Need to... | File |
|------------|------|
| Deploy Exchange | `phase3-week2/scripts/5.1-Exchange-Setup.ps1` |
| Read the guide | `phase3-week2/EXCHANGE-QUICKSTART.md` |
| Check deployment status | `DEPLOYMENT-STATUS.md` |
| Send Pax8 license email | `templates/email-megan-csp-request.md` |
| See tenant config | `phase2-week1/modules/DeltaCrown.Config.psd1` |
| Understand auth | `phase2-week1/modules/DeltaCrown.Auth.psm1` |
| User mapping | `phase4-migration/config/dce-user-mapping.csv` |

## Tenant Quick Reference

| Item | Value |
|------|-------|
| Tenant name | deltacrown |
| Tenant ID | `ce62e17d-2feb-4e67-a115-8ea4af68da30` |
| Domain | `deltacrown.com` |
| Admin URL | `https://deltacrown-admin.sharepoint.com` |
| Cross-tenant admin | `tyler.granlund-admin@httbrands.com` |
| Native users | Allynn.Shepherd, Jay.Miller, Lindy.Sturgill, Sarah.Miller (all @deltacrown.com) |
| Azure AD groups | DCE-AllStaff, DCE-Managers, DCE-Stylists, DCE-External |
