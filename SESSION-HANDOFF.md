

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

---

## 2026-05-19 — DCE SyncFabric recovery + SharePoint page build prep (code-puppy-73a4b6 / Richard)

### Branch / repo state

- Working branch: `gh-pages`.
- Remote: `origin/gh-pages`.
- All session commits were pushed during the session.
- No public HTML/CSS/JS files were changed in this work wave; public-page accessibility/browser/axe gates were not required.

### Critical identity recovery completed

DCE SyncFabric admin-guest deletion was investigated and stabilized.

Root cause identified:

- HTT source-side Azure2Azure sync app: `CTSync-HTT-to-DCE`.
- Target tenant: Delta Crown Extensions.
- Sync scope is assignment-based (`SyncAll=false`).
- Admin accounts that were not entitled to the sync app were treated as out-of-scope and soft-deleted in DCE by Microsoft.Azure.SyncFabric.

Tyler admin recovery:

- Tyler's DCE admin target object was restored.
- Tyler retained DCE Global Administrator.
- Tyler's HTT admin source account was directly assigned to `CTSync-HTT-to-DCE` as a bridge entitlement.
- Sync job is active again.

Dustin owner recovery:

- Tyler chose `dustin.boyd-admin@httbrands.com` as second owner for `DCE-HTT-Corporate-Sync`.
- Dustin's DCE admin target object was also found soft-deleted by the same SyncFabric incident.
- Safe order completed:
  1. Created HTT direct app assignment bridge for Dustin admin to `CTSync-HTT-to-DCE`.
  2. Restored Dustin's DCE target object.
  3. Added Dustin as owner of `DCE-HTT-Corporate-Sync`.
- Verified final `DCE-HTT-Corporate-Sync` owners:
  - Tyler Granlund - Admin
  - Dustin Boyd - Admin
- Dustin is **not** a DCE Global Administrator; no GA assignment was made.

Closed:

- `DeltaSetup-3ke` — Tyler DCE admin auth failure resolved.
- `DeltaSetup-0gv` — second owner added to `DCE-HTT-Corporate-Sync`.

Still open/in-progress:

- `DeltaSetup-b2i` — broader SyncFabric remediation remains open because direct assignments are bridge controls until permanent sync-scope policy is decided.

### New/updated incident and planning docs

Created/updated:

- `docs/dce-syncfabric-incident-2026-05-18.md`
- `docs/next-execution-lanes-2026-05-19.md`
- `docs/friday-hub-basics-handoff-2026-05-19.md`
- `docs/sharepoint-page-build-next-steps-2026-05-19.md`

Important guardrails now documented:

- Do not remove the temporary HTT-to-DCE direct app assignment bridge as routine cleanup.
- Keep concrete identity/app IDs out of broad public planning docs.
- Keep raw tenant evidence under `.local/` or private evidence stores.
- Maintain a DCE-native, cloud-only break-glass Global Administrator outside HTT cross-tenant sync.

### SharePoint page build artifacts drafted

Content/readiness artifacts created. These are **drafts only**, not production approval evidence.

DCE Hub:

- `docs/sharepoint-content/dce-hub-home-content-spec.md`
- Extracts production-safe DCE Hub Home copy from the mockup.
- Flags KPI tiles, owner spotlight, and events as approval-gated.
- Lists production-readiness checks.

Crown Connection:

- `docs/sharepoint-content/crown-connection-content-spec.md`
- Converts mockup content into owner-page sections.
- Flags Teams embed/moderation and HTT corporate collateral as gated.
- Live Crown Connection must not be used as sandbox.

Jamie/content input:

- `docs/sharepoint-content/jamie-content-input-packet.md`
- Table for final copy, destinations, owners, audiences, and approval status.

Promotion readiness:

- `docs/promotion-readiness/dce-hub-production-promotion-checklist.md`
- `docs/promotion-readiness/crown-connection-promotion-checklist.md`

Viva / template / audit:

- `docs/viva-dashboard-card-plan-dce.md`
- `docs/sharepoint-page-template-parameters.md`
- `docs/cross-brand-owner-site-audit-2026-05-19.md`

### Observability and canary scaffolding

Created/updated:

- `docs/observability/deploy-failure-audit-drift-alerting.md`
- `tools/check-dce-syncfabric-bridge.py`
- `.github/workflows/dce-syncfabric-bridge-drift-dry-run.yml`
- `docs/observability/github-actions-hardening-notes.md`
- `research/notification-suppression/canary-runbook.md`

Current workflow state:

- Dry-run only.
- No tenant mutation.
- No secrets.
- `contents: read` only.
- Weekly schedule + manual dispatch.
- Explicit concurrency group added.

Remaining before live alerting:

- Choose approved alert recipients.
- Choose out-of-tenant critical alert channel.
- Wire real Graph checks via private env/secrets.
- Run synthetic failure test.
- Pin GitHub Actions to immutable SHAs before secret-backed/live alerting.
- Make CODEOWNERS security-team enforcement real.

Promotion gate added:

- `DeltaSetup-b0f` and `DeltaSetup-3vu` must not promote production content until Class 3 DCE SyncFabric bridge drift alerting is live, not dry-run.

### SharePoint build next steps

Best next workstream when session resumes:

1. Confirm SharePoint location decision:
   - DCE primary
   - HTT duplicate
   - Hybrid
   - Recommendation documented: DCE primary, HTT light landing only if needed.
2. Get Jamie/Tyler content inputs from `docs/sharepoint-content/jamie-content-input-packet.md`.
3. Convert approved inputs into final DCE Hub Home candidate content.
4. Convert approved inputs into Crown Connection final candidate content.
5. Make Class 3 bridge drift alerting live.
6. Only after approval + live alerting, promote DCE Hub or Crown Connection.

### Current blockers / questions for Tyler/Jamie

Use questionnaire in the latest assistant response if continuing interactively. Key blockers:

- DCE primary vs HTT duplicate vs hybrid.
- Final DCE Hub hero wording.
- Quick-link destinations for Brand Resources, Operations, Training, Submit Request, People/Directory, Crown Connection.
- Whether to defer KPI tiles.
- Crown Connection visibility from DCE Hub.
- Ask-the-Franchisor intake route.
- Whether Crown Connection should link to Teams, remove Teams, or keep Teams as future placeholder.
- Viva v1 card set.
- DCE Hub production approver.
- Crown Connection promotion approver.
- Out-of-tenant critical alert channel.
- Next brand to audit when auth is available.

### Recent commits in this work wave

- `f76d3c5` — Plan parallel DeltaSetup execution lanes
- `342cade` — Add DeltaSetup promotion and canary scaffolds
- `5947115` — Add Dustin as DCE sync co-owner
- `6cd5485` — Define SharePoint page build next steps
- `403271c` — Draft SharePoint page content specs
- `af2297b` — Harden bridge drift dry-run workflow

### Quality checks run during work wave

- `python3 tools/check-dce-syncfabric-bridge.py`
- `python3 -m py_compile tools/check-dce-syncfabric-bridge.py`
- Ruby stdlib YAML parse for `.github/workflows/dce-syncfabric-bridge-drift-dry-run.yml`
- Sensitive identifier scans against new broad docs/workflows/runbooks
- Line-count checks for new docs/tools

### Resume command checklist

```bash
cd /Users/tygranlund/dev/04-other-orgs/DeltaSetup
bd sync
bd ready --limit 20
git status -sb
```

Start with either:

- content decisions / DCE Hub final candidate copy; or
- live Class 3 bridge drift alerting implementation; or
- Teams read-context blocker if access is available.
