# Phase 3: Collaboration + SharePoint — Delta Crown Extensions

## Status: 📋 PLANNING COMPLETE — Ready for Implementation

| Property | Value |
|----------|-------|
| **Phase** | 3 — Collaboration + SharePoint |
| **Timeline** | 10 working days |
| **Depends On** | Phase 2 (Infrastructure + Identity) — ✅ Complete |
| **ADR** | ADR-002: Phase 3 SharePoint Sites + Teams Collaboration |
| **Architect** | Solutions Architect (solutions-architect-261e7f) |

---

## What Phase 3 Delivers

### SharePoint Brand Sites (4 sites)
| Site | Type | Purpose |
|------|------|---------|
| DCE-Operations | Team Site (Teams-connected) | Daily ops hub with bookings, tasks, schedules |
| DCE-ClientServices | Team Site (standalone) | Client records, service catalog, feedback |
| DCE-Marketing | Communication Site (standalone) | Brand assets, campaigns, social calendar |
| DCE-Docs | Team Site (document center) | Policies, training, forms, templates, archive |

### Teams Workspace (1 team, 5 channels)
| Channel | Type | Purpose |
|---------|------|---------|
| General | Standard | Team announcements, general coordination |
| Daily Ops | Standard | Shift handover, daily checklists |
| Bookings | Standard | Client booking coordination |
| Marketing | Standard | Campaign coordination, social media |
| Leadership | Private | Management discussions, HR, financials |

### Security Hardening
- Unique permissions on ALL DCE sites
- Remove Everyone/All Users from all sites
- 3 DLP policies (within 10-policy budget)
- Guest access disabled at team level

### Template Capture
- PnP site templates for all 4 sites
- Parameterized for brand reuse (Bishops, Frenchies, etc.)
- Companion scripts for Teams + mailbox provisioning

---

## Script Inventory

| # | Script | Purpose | Dependencies |
|---|--------|---------|--------------|
| 3.0 | `3.0-Master-Phase3.ps1` | Master orchestrator | Auth, Common modules |
| 3.1 | `3.1-DCE-Sites-Provisioning.ps1` | Create 4 SharePoint sites | Hub exists |
| 3.2 | `3.2-Teams-Provisioning.ps1` | Create Teams + channels | DCE-Operations exists |
| 3.3 | `3.3-Security-Hardening.ps1` | Permissions + group cleanup | All sites exist |
| 3.4 | `3.4-DLP-Policies.ps1` | Create DLP policies | Hardened sites |
| 3.5 | `3.5-Shared-Mailboxes.ps1` | Create shared mailboxes | Team exists |
| 3.6 | `3.6-Template-Export.ps1` | Export PnP templates | All configured |
| 3.7 | `3.7-Phase3-Verification.ps1` | Verify everything | All above |

### Execution Order
```
Phase 2 ✅ → 3.1 → 3.2 → 3.5 → 3.3 → 3.4 → 3.6 → 3.7
                ↓       ↓                        ↑
            Sites   Teams+Mail            Template Export
                ↓       ↓
            Security Hardening → DLP
```

---

## Quick Start (for Implementers)

### Prerequisites
```powershell
# Required modules
Install-Module PnP.PowerShell -MinimumVersion 2.0.0
Install-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0
Install-Module Microsoft.Graph.Teams -MinimumVersion 2.0.0
Install-Module Microsoft.Graph.Groups -MinimumVersion 2.0.0
Install-Module ExchangeOnlineManagement -MinimumVersion 3.0.0

# Required roles
# - SharePoint Administrator
# - Teams Administrator  
# - Compliance Administrator
# - Groups Administrator (or Global Admin)
```

### Phase 2 Verification
Before starting Phase 3, verify Phase 2 is deployed:
```powershell
# Run Phase 2 verification
.\phase2-week1\scripts\2.4-Verification.ps1

# Confirm these exist:
# ✅ /sites/corp-hub (Corporate Hub)
# ✅ /sites/dce-hub (DCE Hub)
# ✅ AllStaff (Azure AD group)
# ✅ Managers (Azure AD group)
```

---

## Timeline

| Day | Task | Script | Status |
|-----|------|--------|--------|
| 1-2 | SharePoint sites + lists + libraries | 3.1 | ⬜ |
| 3-4 | Teams workspace + channels + mailboxes | 3.2, 3.5 | ⬜ |
| 5-6 | Security hardening + permission cleanup | 3.3 | ⬜ |
| 7 | DLP policies implementation | 3.4 | ⬜ |
| 8-10 | Template capture + verification | 3.6, 3.7 | ⬜ |

---

## Architecture References

- **ADR-002**: `docs/architecture/decisions/ADR-002-phase3-sharepoint-sites-teams-collaboration.md`
- **ADR-001**: `docs/architecture/decisions/ADR-001-sharepoint-hub-spoke-multi-brand-franchise.md`
- **Fitness Functions**: `tests/architecture/test_adr_002_phase3_sites_teams.py`
- **Research**: `research/phase3-sharepoint-teams/`

---

## Key Architecture Decisions (Summary)

1. **Single Team per brand** (not multiple) — Option B from ADR-002
2. **Only DCE-Operations is Teams-connected** — other sites are standalone
3. **DCE-Marketing is a Communication Site** — enables publishing features
4. **Private Leadership channel** — auto-creates separate isolated SPO site
5. **3 DLP policies in Phase 3** — leaves 7 for future brands
6. **PnP templates + companion scripts** — Teams/mailboxes require Graph/Exchange API
7. **Guest access disabled** — by default at team + site level
