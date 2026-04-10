# ADR-003: HTTHQ Document Migration Strategy

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Date** | 2025-07-26 |
| **Decision Makers** | Tyler Granlund |
| **Depends On** | ADR-001 (Hub & Spoke), ADR-002 (Phase 3 Sites & Teams) |

---

## Context and Problem Statement

The **HTT Headquarters** SharePoint site (`httbrands.sharepoint.com/sites/HTTHQ`) currently houses all brand documents in a single "Shared Documents" library. This is the existing production environment for 41 users across 5 brands.

### The Current State (Audit: Oct 2025)

```
HTTHQ / Shared Documents
├── 0 HTT C Suite              (8 perms, broken inheritance)
├── 1-HTT Exec Leadership      (11 perms, broken inheritance)
├── 2-Brand Leads              (18 perms, broken inheritance)
├── Employee Resources         (11 perms, broken inheritance)
├── Education                  (? perms, broken inheritance)
├── Finance                    (11 perms, broken inheritance)
├── Fran Dev                   (50 perms, broken inheritance) ← MOST ACCESSIBLE
├── Head to Toe                (8 perms, broken inheritance)
├── IT-Technology              (17 perms, broken inheritance)
├── Legal                      (13 perms, broken inheritance)
├── Master BCC (Bishops)       (41 perms, broken inheritance)
├── Master CROWN               (7 perms, broken inheritance)
├── Master DCE                 (? perms, broken inheritance) ← OUR FOCUS
│   ├── _Franchisees           (5 items)
│   ├── Status                 (2 items)
│   ├── Corp Docs              (2 items)
│   ├── Financials & Proforma  (11 items)
│   ├── Fran Dev               (8 items)
│   ├── Marketing              (12 items)
│   ├── Operations             (10 items)
│   ├── Product                (7 items)
│   ├── Real Estate & Const.   (3 items)
│   ├── Strategy               (5 items)
│   ├── Training               (1 item)
│   ├── zArchive               (1 item)
│   └── DC - Letterhead.docx
├── Master FMN (Frenchies)     (39 perms, broken inheritance)
├── Master TLL (Lash Lounge)   (52 perms, broken inheritance) ← MOST PERMISSIVE
├── Product                    (6 perms, ONLY folder inheriting) ← ONLY CLEAN ONE
├── Real Estate, Construction  (7 perms, broken inheritance)
└── Vendors                    (? perms, broken inheritance)
```

### Security Issues Identified (Audit)

| Issue | Severity | Count |
|-------|----------|-------|
| External sharing links without expiration | 🔴 Critical | 127 |
| Overly permissive folder access | 🔴 Critical | 34 instances |
| Sensitive data in unsecured locations | 🔴 Critical | 12 instances |
| No DLP policies anywhere | 🟠 High | Tenant-wide |
| Inconsistent retention labels | 🟠 High | 17 folders |
| Orphaned content (no identifiable owner) | 🟡 Medium | 45 items |
| Duplicate content across brand folders | 🟡 Medium | 89 items |

### Core Problem

The current structure has **two tenants in play**:

1. **`httbrands`** — The existing HTT Brands tenant where HTTHQ lives (production)
2. **`deltacrown`** — The new DCE tenant where the hub-and-spoke architecture is being built

We need to decide:
- Which documents move to `deltacrown` (the new architecture)?
- Which stay on `httbrands` (for other brands not yet migrated)?
- How do we handle the transition period where both exist?
- How do we handle corporate documents needed by ALL brands?

---

## Decision Drivers

1. **User Disruption**: Minimize impact on existing DCE staff workflows
2. **Data Integrity**: Zero data loss during migration
3. **Security Improvement**: Every moved document should be MORE secure after migration
4. **Coexistence**: Other brands (BCC, FMN, TLL) still use HTTHQ — don't break them
5. **Audit Trail**: Document chain of custody for every file
6. **Reversibility**: Must be able to undo migration if needed
7. **Speed**: DCE users need the new experience ASAP

---

## Considered Options

### Option A: Big Bang Migration (Copy Everything at Once)

```
Day 1: Audit all Master DCE files
Day 2: Copy everything to deltacrown sites
Day 3: Redirect users to new sites
Day 4: Archive Master DCE folder on HTTHQ
```

**Pros**:
- ✅ Fastest to execute
- ✅ Clean cutover — one source of truth immediately
- ✅ Simplest mental model

**Cons**:
- ❌ High risk — any missed files = broken workflows
- ❌ No parallel running period
- ❌ Users need to learn new location immediately
- ❌ No fallback if something goes wrong
- ❌ External sharing links all break immediately

**Risk**: High

### Option B: Phased Migration with Dual-Access Period (Recommended)

```
Week 1: Deploy hub-and-spoke architecture (Phase 2 + 3 scripts)
Week 1: Audit Master DCE contents, map every file to destination
Week 2: Copy files to new sites (don't delete originals)
Week 2: Set Master DCE folder to READ-ONLY
Week 2-4: Dual access period — users work in new sites, old files still readable
Week 4: Verify all files accessible in new locations
Week 5: Archive Master DCE folder (move to zArchive, retain 90 days)
Week 8: Delete archived content
```

**Pros**:
- ✅ Low risk — originals preserved during transition
- ✅ Users can compare old/new during training
- ✅ Natural fallback — just unlock old folder if needed
- ✅ Time to fix any mapping errors
- ✅ External sharing links still work during transition

**Cons**:
- ⚠️ Temporary duplicate storage (acceptable at this scale)
- ⚠️ Users might get confused about which is "real"
- ⚠️ Takes longer overall

**Risk**: Low

### Option C: Shortcut/Redirect-First (Mirror Then Migrate)

```
Week 1: Deploy hub-and-spoke
Week 1: Create shortcuts in new sites pointing to HTTHQ files
Week 2-4: Users work through new sites (files still on HTTHQ)
Week 4: Copy actual files to new sites, remove shortcuts
Week 5: Archive HTTHQ Master DCE
```

**Pros**:
- ✅ Users get new experience immediately
- ✅ No file movement needed initially
- ✅ Very low risk

**Cons**:
- ❌ Cross-tenant shortcuts are unreliable
- ❌ Performance issues accessing files across tenants
- ❌ DLP policies can't protect files still on HTTHQ
- ❌ Permission model doesn't apply until files actually move

**Risk**: Medium (technical complexity)

---

## Decision Outcome

### Chosen Option: **Option B — Phased Migration with Dual-Access**

This provides the best balance of speed, safety, and user experience.

---

## Detailed Migration Plan

### Phase A: Preparation (Pre-Deployment)

**A.1 — Full Audit of Master DCE**
Before migrating anything, run a complete audit:
- File inventory (name, size, last modified, last accessed, modified by)
- Version history (capture version count per file)
- Sharing links (document all external/internal shares)
- Permission snapshot (who has access to what right now)

**A.2 — File-to-Site Mapping**
Map every file/folder to its destination in the new architecture:

| Current Location | → Destination Site | Destination Library/Folder | Rationale |
|------------------|--------------------|--------------------------|-----------|
| Master DCE/Operations/* | `/sites/dce-operations` | Documents/Operations | Brand daily ops |
| Master DCE/_Franchisees/* | `/sites/dce-operations` | Documents/Franchisees | Brand franchise management |
| Master DCE/Status/* | `/sites/dce-operations` | Documents/Status | Brand status tracking |
| Master DCE/Fran Dev/* | `/sites/dce-operations` | Documents/Franchise-Development | Brand growth |
| Master DCE/Marketing/* | `/sites/dce-marketing` | Brand Assets | Brand marketing materials |
| Master DCE/DC - Letterhead.docx | `/sites/dce-marketing` | Brand Assets/Templates | Brand template |
| Master DCE/Product/* | `/sites/dce-docs` | Documents/Product | Reference material |
| Master DCE/Strategy/* | `/sites/dce-docs` | Documents/Strategy | Leadership only — restrict access |
| Master DCE/Training/* | `/sites/dce-docs` | Documents/Training | Or Corp-Training if cross-brand |
| Master DCE/zArchive/* | `/sites/dce-docs` | Documents/Archive | Historical reference |
| Master DCE/Corp Docs/* | `/sites/corp-hub` | Shared Documents/Corporate | Cross-brand corporate docs |
| Master DCE/Financials & Proforma/* | Split: Brand → `dce-operations`, Corp → `corp-finance` | Review each file individually | Mixed content |
| Master DCE/Real Estate & Const./* | `/sites/corp-hub` | Shared Documents/Real-Estate | Cross-brand function |

**A.3 — Corporate Document Triage**
Some documents in "Master DCE" are actually corporate-wide:
- **Corporate → Corp Hub**: Templates used by all brands, corporate policies, cross-brand procedures
- **Brand-specific → DCE site**: Anything with "DCE", "Delta Crown", or brand-specific content
- **Ambiguous → Flag for review**: Tyler decides on case-by-case basis

### Phase B: Deploy Architecture

Run the Phase 2 and Phase 3 master orchestrators per the Deployment Runbook.

### Phase C: Copy Files (Week 2)

**C.1 — Automated Copy Script**
Create a PowerShell migration script that:
1. Reads the file-to-site mapping CSV
2. Copies each file preserving metadata (created date, modified date, author)
3. Preserves version history where possible (PnP `Move-PnPFile` with `-OverwriteIfAlreadyExists`)
4. Logs every operation (source, destination, size, hash, timestamp)
5. Generates a migration report

**C.2 — Set Source to Read-Only**
After copy is verified:
```powershell
# Break inheritance on Master DCE folder
# Set all permissions to READ-ONLY
# Add banner to Master DCE: "This folder is archived. New location: [link]"
```

**C.3 — Verify Copy Integrity**
- File count matches (source vs destination)
- File sizes match
- Spot-check 10% of files by SHA-256 hash
- Verify metadata preservation

### Phase D: User Onboarding (Week 2-4)

1. **Set Azure AD properties** on existing DCE users (companyName, jobTitle, department)
2. Dynamic groups automatically populate
3. Users get access to new sites + Teams workspace
4. Provide training deck: "Your documents moved — here's where to find everything"
5. Pin new DCE Hub as homepage for DCE users

### Phase E: Archive and Cleanup (Week 5+)

1. Move Master DCE folder to "zArchive-Master-DCE-MIGRATED" folder
2. Set 90-day retention on archived folder
3. Monitor access logs — if anyone accesses archived content, redirect them
4. After 90 days with zero access, delete

---

## Corporate Document Strategy

### The Cross-Tenant Problem

Corporate documents (C Suite, Exec Leadership, Finance, HR, Legal, IT) currently live on `httbrands.sharepoint.com`. These are needed by ALL brands, not just DCE.

**Options**:

1. **Copy corporate docs to `deltacrown` Corp Hub** — DCE users get fast access, but documents become stale copies
2. **Keep corporate docs on `httbrands`, give DCE users cross-tenant access** — Single source of truth, but complex permissions
3. **SharePoint cross-site shortcut (same tenant solution for later)** — When HTT brand migrates to `deltacrown`, all corporate docs come naturally

**Recommended**: **Option 1 for now, transition to native when HTT migrates**

Copy the corporate documents DCE needs to the Corp Hub on `deltacrown`. Accept that these are copies for now. When HTT (the parent brand) migrates in Phase 5 (Q4), the Corp Hub becomes the canonical location and everything converges.

### What DCE Actually Needs from Corporate

| Corporate Content | Frequency of Change | Action |
|-------------------|---------------------|--------|
| HR Policies & Procedures | Quarterly | Copy to Corp-HR, refresh quarterly |
| Employee Handbook | Annual | Copy to Corp-HR |
| Finance Reporting Templates | Monthly | Copy to Corp-Finance |
| Brand Guidelines | Rarely | Copy to Corp Hub |
| IT Knowledge Base | As needed | Copy to Corp-IT |
| Legal Templates (NDA, etc) | Rarely | Copy to Corp Hub |
| Training Materials | As needed | Copy to Corp-Training |

---

## Existing User Onboarding

### Current Users on `deltacrown` Tenant

These users already exist on the tenant. We need to:
1. **Audit current Azure AD properties** — Check what `companyName`, `department`, `jobTitle` are set to
2. **Set missing properties** — Script to bulk-update user properties
3. **Verify dynamic group membership** — After property update, confirm users appear in correct groups

### Key User Properties for Dynamic Groups

| Property | Purpose | Example Value | Group Triggered |
|----------|---------|---------------|-----------------|
| `companyName` | Brand assignment | "Delta Crown Extensions" | SG-DCE-AllStaff |
| `jobTitle` | Role-based access | "Operations Manager" | SG-DCE-Leadership |
| `department` | Function-based access | "Marketing" | SG-DCE-Marketing |
| `usageLocation` | Compliance | "AU" | Data residency |

### Onboarding Script Requirements

```powershell
# 1. Get all users
# 2. Identify DCE users (by current group membership or email domain)
# 3. Set companyName = "Delta Crown Extensions"
# 4. Set appropriate department and jobTitle
# 5. Wait for dynamic group evaluation (~15 min)
# 6. Verify group membership
# 7. Verify site access
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Files missed in mapping | Medium | Medium | Pre-migration audit + post-migration file count verification |
| User confusion during dual-access | Medium | Low | Clear communication + "archived" banner on old folder |
| Version history loss | Low | Medium | Use PnP migration cmdlets that preserve history |
| External sharing links break | High | Medium | Audit all external links pre-migration, recreate in new location |
| Cross-tenant corporate doc staleness | Medium | Low | Quarterly sync schedule until HTT brand migrates |
| Dynamic group propagation delay | Low | Low | Azure AD evaluates within 15 min, script includes wait + verify |

---

## Success Criteria

- [ ] All Master DCE files accounted for in new locations
- [ ] Zero data loss (verified by file count + hash checks)
- [ ] All DCE users have correct Azure AD properties
- [ ] All DCE users can access new hub and sites
- [ ] Master DCE folder set to read-only within 1 week of copy
- [ ] Master DCE folder archived after 90 days
- [ ] No user complaints about missing files after 30 days
