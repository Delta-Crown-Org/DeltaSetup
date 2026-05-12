# DeltaSetup — Delta Crown Extensions

> **Branch:** `gh-pages` · **Live site:** <https://delta-crown-org.github.io/DeltaSetup/>
> **Tenant:** `deltacrown` (Microsoft 365 Business Premium) · **Last reconciled:** 2026-05-12

---

## What's built and what remains

The hub-and-spoke Microsoft 365 architecture is **deployed, security-hardened, and audited**. Five workstreams are complete, one (document migration) was **skipped by decision**, and the platform is functionally ready for users. The remaining work is **operational cleanup, owner decisions, and a Teams workload read-access blocker** — not new architecture.

| Workstream | Status |
|---|---|
| Phase 1 — Email Trust (SPF/DKIM/DMARC) | ✅ Live on `deltacrown.com` |
| Phase 2 — Hub Foundation (Corp-Hub + DCE-Hub + spokes) | ✅ Live |
| Phase 3 — Brand Sites + Teams workspace + DLP | ✅ Live, security-hardened |
| Phase 4 — HTTHQ Document Migration | ⏭️ Skipped by Tyler on 2026-04-29 |
| Phase 5 — Exchange Online (mailboxes, DDGs) | ✅ Live |
| Tenant inventory (read-only audit) | ✅ Substantially complete; Teams channel detail blocked |
| User metadata cleanup | ⏳ Major gaps — blocks dynamic groups (`DeltaSetup-1b3`) |
| Production launch readiness | ⏳ Open — `DeltaSetup-nge` |

### ✅ Built and live in the tenant

**Identity (Entra ID)**
- 89 users (3 disabled)
- 5 dynamic security groups configured: `AllStaff`, `Managers`, `Marketing`, `Stylists`, `External`
- All groups are processing; `AllStaff` is populated (6 users) and `Managers` now has 1 member after validated DCE metadata cleanup — see metadata gap below

**SharePoint**
- **Corp-Hub** + 4 service spokes: `corp-hr`, `corp-it`, `corp-finance`, `corp-training`
- **DCE-Hub** (gold/black brand theme) + 4 brand sites: `dce-operations`, `dce-clientservices` *(legacy — see register)*, `dce-marketing`, `dce-docs`
- 8 document libraries, 6 SharePoint lists, hub-to-hub association
- Permission inheritance broken on DCE sites; group → role matrix applied
- 10 sites Graph-audited clean (no "Everyone", no anonymous links)

**Microsoft Teams**
- "Delta Crown Operations" team provisioned with 5 channels (General, Daily Ops, Bookings, Marketing, Leadership-private)
- Group ID `03255d50-…` connected to `dce-operations-team` SharePoint site
- Leadership private-channel site verified

**Exchange Online**
- `deltacrown.com` authoritative accepted domain
- 3 shared mailboxes: `operations@`, `bookings@`, `info@`
- 4 dynamic distribution groups: `allstaff@`, `managers@`, `stylists@`, `franchise_owners@`
- Auto-replies enabled on `bookings@` and `info@`

**Security & Compliance**
- Tenant locked down: `existingExternalUserSharingOnly`, legacy auth disabled, anonymous resharing disabled
- 3 DLP policies deployed: `DCE-Data-Protection`, `Corp-Data-Protection`, `External-Sharing-Block`
- Live security hardening applied via PnP DeviceLogin on 2026-04-29
- HTT Brands source-migration Entra app deleted on 2026-04-30

**Audit / inventory (read-only, evidence-based)**
- Identity, SharePoint (Graph + PnP), Exchange, Security/apps/licenses, Compliance — all complete
- HTT source folder (Master DCE) audited: 13 top-level items, 275 permission rows visible — no content moved
- ClientServices artifacts confirmed empty (no client content present)

**Automation**
- 48 PowerShell scripts across `phase2-week1/`, `phase3-week2/`, `phase4-migration/`
- 167 tests passing: 117 Python ADR fitness tests + 50 Phase-3 Pester tests
- Master orchestrators with idempotency + rollback

**Public-facing**
- Live executive site published from this branch
- 4 ADRs: hub-and-spoke, sites/Teams, migration, cross-tenant access

### ⏳ What still needs to happen

**To make dynamic groups actually populate** *(highest leverage gap)*
- `companyName` populated on only **6 of 89 users**; those six DCE users now have validated department/title/location/type metadata
- `department` 49/89 · `jobTitle` 48/89 · `officeLocation` 22/89 · `employeeType` 6/89
- `AllStaff` resolves to 6 and `Managers` now resolves to 1; `Marketing`/`Stylists`/`External` remain 0
- Full-tenant bulk metadata cleanup is still the prerequisite for role-driven access at scale
- Evidence: `docs/dce-user-metadata-and-teams-state-verification.md`

**Blocked on Teams read context**
- `DeltaSetup-4ay` — Provide licensed Teams-readable context, finish Teams/channel inventory, and update consolidated evidence. Current admin context lacks the Teams license/read check Graph requires.

**Owner decisions needed**

| ID | What's pending |
|---|---|
| `DeltaSetup-gf9` | Owner-decision cleanup bucket: stale `main` branch disposition; Brand Resources vs Brand Assets model; dynamic security-group owners; DLP test-mode vs enforce decision; expired `DeltaCrown-TeamsProvisioner-TEMP` app; ClientServices deprecation banner. |

**Production launch path**
- `DeltaSetup-nge` — Production launch readiness and end-to-end validation: access tests, owner acceptance, onboarding/offboarding smoke, DLP posture decision, and final readiness package.
- `DeltaSetup-1b3` — Metadata cleanup so dynamic groups populate.
- `DeltaSetup-4ay` — Teams read-context blocker and inventory completion.
- `DeltaSetup-gf9` — Owner-decision cleanup bucket.

**Future brand rollout** *(~2-week pattern per brand, when sponsored)*
- `DeltaSetup-yo1` — HTT & TLL hub
- `DeltaSetup-ql3` — Frenchies hub
- `DeltaSetup-la0` — Bishops hub

**Tooling**
- No open tooling bead right now. If parallel `bd create` races recur, re-file a small tooling issue; this session created follow-up beads serially to avoid the race.

### 📍 Where to look for details

| Question | File / command |
|---|---|
| What's deployed in the tenant? | `DEPLOYMENT-STATUS.md` |
| How do I rerun a phase? | `DEPLOYMENT-RUNBOOK.md` |
| What did the audits find? | `docs/delta-crown-*-inventory-summary.md` |
| Why was ClientServices retired? | `docs/legacy-clientservices-cleanup-register.md` |
| What's the architecture? | `docs/architecture/decisions/ADR-001..004` |
| What's the current showcase narrative? | `docs/team-showcase-readiness-checklist.md` |
| Onboarding/offboarding model? | `docs/onboarding/` |
| Open work? | `bd ready` · `bd list --status=open` |

---

## Branch layout

This repo has **two orphan branches with no shared history**:

- **`gh-pages`** *(this branch)* — current canonical work: site, hub-and-spoke provisioning, audited architecture, onboarding model.
- **`main`** — abandoned earlier architecture (cross-tenant sync between HTT Brands and DCE via `scripts/00-08`). Disposition is tracked in the owner-decision cleanup bucket **`DeltaSetup-gf9`**. Do not treat `main` as current.

If you arrived here from the GitHub repo landing page (which currently defaults to `main`), the README on `main` flags itself as legacy and points back here. Use this branch for anything current.

## Working agreements

- **Issue tracking is `bd` (beads)**, not GitHub Issues — see `AGENTS.md`.
- **Tenant changes are gated**: read-only inventory only, no production cleanup without owner approval. See `docs/legacy-clientservices-cleanup-register.md`.
- **Document migration is out of scope** for this rollout (Tyler's decision, 2026-04-29). HTTHQ files stay where they are.
- **Do not commit** `.local/`, raw permission CSVs, or anything containing user PII.

## Contact / ownership

Tyler Granlund (owner). Agent assistants: Richard (`code-puppy-*`).
