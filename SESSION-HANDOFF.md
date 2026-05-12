

## Security Hardening Status — TENANT LOCKED DOWN ✅

### Breakthrough: Graph Beta SharePointTenantSettings.ReadWrite.All
- Granted `SharePointTenantSettings.ReadWrite.All` to temp app
- Used `PATCH /beta/admin/sharepoint/settings` to harden tenant

### Changes Made (LIVE)
| Setting | Before | After |
|---------|--------|-------|
| sharingCapability | externalUserAndGuestSharing (WIDE OPEN) | existingExternalUserSharingOnly |
| isResharingByExternalUsersEnabled | true | **false** |
| isLegacyAuthProtocolsEnabled | true | **false** |

### Graph API Audit Results
- ✅ Original 2026-04-29 security group snapshot verified (AllStaff=6, Managers=0, Marketing=0, Stylists=0); current 2026-05-12 dynamic group state is documented below.
- ✅ No "Everyone" / forbidden groups in Azure AD
- ✅ No forbidden groups in Graph-level site permissions
- ✅ 10 sites audited clean

### Still Needs PnP (internal access controls, not security-critical)
- ⏳ Break permission inheritance on DCE sites
- ⏳ Apply group→role matrix (AllStaff=Read, Managers=Full Control)
- Run: `pwsh -File ./phase3-week2/scripts/deploy-security-hardening.ps1`

### 2026-04-29 Follow-up — Auth Blocker
- Richard/code-puppy-bf0453 patched `deploy-security-hardening.ps1` for PnP.PowerShell 3.x by loading `PnPClientId` from `phase2-week1/modules/pnp-app-config.json` and passing `-ClientId` + tenant ID to `Connect-PnPOnline -DeviceLogin`.
- Local syntax checks passed for hardening and migration scripts.
- Phase 3 Pester tests passed: 50/50.
- Live SPO security hardening was retried with Tyler present and completed successfully on 2026-04-29 for dce-docs, dce-clientservices, dce-marketing, dce-hub, corp-hub, corp-hr, corp-it, corp-finance, and corp-training.
- HTT Brands source tenant auth was fixed on 2026-04-29 during investigation, but Tyler subsequently decided that **no HTTHQ document migration will be performed at all**.
- Do not run Phase 4 document migration for production cutover. Migration scripts/config remain historical tooling only.
- E2E testing should proceed without document migration assumptions.
- Tracking: document migration work (`DeltaSetup-98`/migration portions of `DeltaSetup-117`) closed as skipped/not planned.
- Cleanup complete on 2026-04-30: unused HTT Brands Entra app `DeltaSetup-HTT-SourceMigration-PnP` / `3657525b-b24a-43bc-9510-cbdd375da6e5` was deleted from tenant `httbrands.onmicrosoft.com`.

---

## 2026-05-11 — WCAG 2.2 AAA push (code-puppy-e7999e / Richard)

### Closed beads (4)
| Bead | Pri | Outcome |
|---|---|---|
| `DeltaSetup-did` | P2 | Automated axe/pa11y regression gate (`tests/accessibility_axe_audit.py` + vendored axe-core 4.10.2). |
| `DeltaSetup-1kp` | P2 | Added `role="group"` to 28 labeled `<div>` containers across all 3 public pages. |
| `DeltaSetup-ewq` | P2 | Wrapped 32 first-occurrence technical abbreviations in `<abbr>` markup. |
| `DeltaSetup-ta9` | P2 | Added `<details>` plain-language summary disclosure to all 3 public pages (FK 3.0–4.0). |

### Open beads (1)
- `DeltaSetup-9gq` (P1, in_progress, assigned to Tyler) — manual WCAG 2.2 AAA cert pass. Blocked on human/browser/AT testing per the structured checklist at `research/wcag-22-aaa-readiness-2026-05-07/AAA-CERTIFICATION-CHECKLIST.md`.

### Quality gate state at session end
```
python3 tests/accessibility_static_audit.py    # 0 FAIL, 0 WARN, 14 PASS
python3 tests/browser_smoke_audit.py           # passed
python3 tests/accessibility_axe_audit.py       # 0 violations, 6 incomplete (color-contrast on gradient surfaces; routed to Section B16 of cert checklist), 92 passes
```

### AAA cert checklist Section D status
All four pre-flagged Section D gaps either resolved or routed:
- D1 (abbreviations) ✅ closed via DeltaSetup-ewq
- D2 (reading level) ✅ closed via DeltaSetup-ta9
- D3 (`aria-prohibited-attr`) ✅ closed via DeltaSetup-1kp
- D4 (color-contrast incomplete) → manual cert Section B16 (pixel-level color-picker check)

### Live deploy
- https://delta-crown-org.github.io/DeltaSetup/ verified live with all changes at 2026-05-11 15:22:07Z.
- All commits on `gh-pages` are pushed to `origin/gh-pages`.

---

## 2026-05-12 — DCE metadata + Exchange DDG live update (code-puppy-e7999e / Richard)

### Live tenant changes completed
- Applied validated metadata to the six current Delta Crown Extensions users via `phase4-migration/scripts/apply-dce-user-metadata.ps1 -Apply`.
- Live result: 6 rows updated, 20 field changes, 0 errors.
- Created live Exchange Dynamic Distribution Group `DCE Franchise Owners <franchise_owners@deltacrown.com>`.
- Exchange recipient preview returned 5 owner mailboxes: Allynn Shepherd, Amit Shah, Jay Miller, Sarah Miller, and Toni Careccia.
- Lindy Sturgill is intentionally excluded from `franchise_owners@` because her metadata is `Department = Salon Operations`, `Title = Salon Manager`, `EmployeeType = Franchisee`.

### Current dynamic group state
| Group | Count | Notes |
|---|---:|---|
| AllStaff | 6 | `companyName = Delta Crown Extensions` |
| Managers | 1 | Lindy matches title contains `Manager` |
| Marketing | 0 | No current exact `Delta Crown Marketing` department matches |
| Stylists | 0 | No current DCE title contains `Stylist` |
| External | 0 | No matching DCE guest users |

### Docs/site reconciled
- README, deployment docs, Exchange quickstart, tenant inventory summaries, showcase checklist, and public pages were updated to reflect the 2026-05-12 live state.
- Public-page gates passed after touching `index.html`, `operations.html`, and `msp.html`.

### Open beads at handoff
- `DeltaSetup-1b3` — still in progress/blocked for broader full-tenant metadata cleanup beyond the six validated DCE users.
- `DeltaSetup-nge` — production launch readiness and E2E validation.
- `DeltaSetup-4ay` — Teams read-context blocker and Teams/channel inventory completion.
- `DeltaSetup-gf9` — owner-decision cleanup bucket.

### What next-session-Richard should pick up
- Run `bd ready` / `bd list` and choose between production launch validation, Teams read-context resolution, or owner-decision cleanup.
- For the GitHub Pages accuracy pass, verify live page copy against `README.md`, `DEPLOYMENT-STATUS.md`, and the inventory docs after GitHub Pages finishes deploying the latest `gh-pages` push.
