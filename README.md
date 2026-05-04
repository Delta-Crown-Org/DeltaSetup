# Delta Crown Extensions — Microsoft 365 Tenant Build

> ## ⚠️ You are looking at a legacy branch
>
> **The actual current build lives on `gh-pages`**, not here. This `main` branch contains an **earlier abandoned architecture** (cross-tenant synchronization between HTT Brands and DCE) that was superseded by the hub-and-spoke model now deployed in the `deltacrown` tenant.
>
> - 🌐 **Live executive site:** <https://delta-crown-org.github.io/DeltaSetup/>
> - 📦 **Current canonical branch:** [`gh-pages`](https://github.com/Delta-Crown-Org/DeltaSetup/tree/gh-pages)
> - 📋 **Branch disposition:** tracked in `bd` issue **`DeltaSetup-165`**
>
> The "Current state" summary below mirrors what's on `gh-pages` so the GitHub landing page tells the truth. The old design notes are preserved at the bottom of this file for historical context.

---

## What's built and what remains

> **Tenant:** `deltacrown` (Microsoft 365 Business Premium) · **Last reconciled:** 2026-05-04

The hub-and-spoke Microsoft 365 architecture is **deployed, security-hardened, and audited**. Five workstreams are complete, one (document migration) was **skipped by decision**, and the platform is functionally ready for users. The remaining work is **operational cleanup, owner decisions, and a Teams workload read-access blocker** — not new architecture.

| Workstream | Status |
|---|---|
| Phase 1 — Email Trust (SPF/DKIM/DMARC) | ✅ Live on `deltacrown.com` |
| Phase 2 — Hub Foundation (Corp-Hub + DCE-Hub + spokes) | ✅ Live |
| Phase 3 — Brand Sites + Teams workspace + DLP | ✅ Live, security-hardened |
| Phase 4 — HTTHQ Document Migration | ⏭️ Skipped by Tyler on 2026-04-29 |
| Phase 5 — Exchange Online (mailboxes, DDGs) | ✅ Live |
| Tenant inventory (read-only audit) | ✅ Substantially complete; Teams channel detail blocked |
| User metadata cleanup | ⏳ Major gaps — blocks dynamic groups |
| Production launch readiness | ⏳ In progress — `DeltaSetup-e46` |

### ✅ Built and live in the tenant

**Identity (Entra ID)**
- 89 users (3 disabled)
- 5 dynamic security groups configured: `AllStaff`, `Managers`, `Marketing`, `Stylists`, `External`
- All groups are processing; only `AllStaff` is currently populated (6 users) — see metadata gap below

**SharePoint**
- **Corp-Hub** + 4 service spokes: `corp-hr`, `corp-it`, `corp-finance`, `corp-training`
- **DCE-Hub** (gold/black brand theme) + 4 brand sites: `dce-operations`, `dce-clientservices` *(legacy)*, `dce-marketing`, `dce-docs`
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
- 3 dynamic distribution groups: `allstaff@`, `managers@`, `stylists@`
- Auto-replies enabled on `bookings@` and `info@`

**Security & Compliance**
- Tenant locked down: `existingExternalUserSharingOnly`, legacy auth disabled, anonymous resharing disabled
- 3 DLP policies deployed: `DCE-Data-Protection`, `Corp-Data-Protection`, `External-Sharing-Block`
- Live security hardening applied via PnP DeviceLogin on 2026-04-29
- HTT Brands source-migration Entra app deleted on 2026-04-30

**Audit / inventory (read-only, evidence-based)**
- Identity, SharePoint (Graph + PnP), Exchange, Security/apps/licenses, Compliance — all complete on `gh-pages`
- HTT source folder (Master DCE) audited: 13 top-level items, 275 permission rows visible — no content moved
- ClientServices artifacts confirmed empty (no client content present)

**Automation** *(on `gh-pages`)*
- 48 PowerShell scripts across `phase2-week1/`, `phase3-week2/`, `phase4-migration/`
- 167 tests passing: 117 Python ADR fitness tests + 50 Phase-3 Pester tests
- Master orchestrators with idempotency + rollback

**Public-facing**
- Live executive site published from `gh-pages`
- 4 ADRs: hub-and-spoke, sites/Teams, migration, cross-tenant access

### ⏳ What still needs to happen

**To make dynamic groups actually populate** *(highest leverage gap)*
- `companyName` populated on only **6 of 89 users** → `Managers`/`Marketing`/`Stylists`/`External` all resolve to **zero**
- `department` 45/89 · `jobTitle` 44/89 · `employeeType` 0/89
- Bulk metadata cleanup is the prerequisite for role-driven access at scale

**Blocked on Teams read context**
- `DeltaSetup-151` — Provide licensed Teams-readable context (current admin lacks the Teams license check Graph requires)
- Cascade: `134` (Teams inventory) · `124` (full tenant inventory) · `137` (consolidated report) · `142` (duplicate-group review) · `rfn` (Teams integration) · `gqk` (template capture)

**Owner decisions needed**

| ID | What's pending |
|---|---|
| `DeltaSetup-165` | Fate of stale `main` branch *(this one)* |
| `DeltaSetup-150` | Brand Resources vs Brand Assets SharePoint model |
| `DeltaSetup-143` | Owners for Delta Crown dynamic security groups |
| `DeltaSetup-148` | DLP test-mode policies (still in `TestWithNotifications`, not `Enforce`) |
| `DeltaSetup-145` | `DeltaCrown-TeamsProvisioner-TEMP` app — credentials expired |
| `DeltaSetup-164` | `DEPLOYMENT-RUNBOOK.md` ClientServices deprecation banner |

**Production launch path**
- `DeltaSetup-e46` *(in progress)* — Production launch
- `DeltaSetup-agr` — End-to-end testing
- `DeltaSetup-140` — Cleanup roadmap and backlog
- `DeltaSetup-137` — Consolidated tenant inventory report
- `DeltaSetup-138` / `139` — Public-showcase gap analysis + readiness package
- `DeltaSetup-nfb` — Governance policies implementation
- `DeltaSetup-89t` — Security & permissions configuration

**Future brand rollout** *(~2-week pattern per brand, when sponsored)*
- `DeltaSetup-yo1` — HTT & TLL hub
- `DeltaSetup-ql3` — Frenchies hub
- `DeltaSetup-la0` — Bishops hub

**Tooling**
- `DeltaSetup-162` — Mitigate `bd create` parallel-write race (real-world hit during the documentation reconciliation audit)

### 📍 Where to look for details *(on `gh-pages`)*

| Question | File / command |
|---|---|
| What's deployed in the tenant? | `DEPLOYMENT-STATUS.md` |
| How do I rerun a phase? | `DEPLOYMENT-RUNBOOK.md` |
| What did the audits find? | `docs/delta-crown-*-inventory-summary.md` |
| Why was ClientServices retired? | `docs/legacy-clientservices-cleanup-register.md` |
| What's the architecture? | `docs/architecture/decisions/ADR-001..004` |
| Onboarding/offboarding model? | `docs/onboarding/` |
| Open work? | `bd ready` · `bd list --status=open` |

---

## 📜 Historical context — what this `main` branch was

Originally, the plan was to keep DCE users in the HTT Brands tenant and **synchronize** them into a separate DCE tenant via Entra ID Cross-Tenant Sync, with cross-tenant Send-As permissions for shared `@deltacrown.com` mailboxes. The repository structure on this branch (`scripts/00-08`, `docs/00-07`, `config/tenant-config.json`) reflects that earlier model.

That direction was abandoned in favor of the hub-and-spoke architecture now deployed on the `deltacrown` tenant directly. Everything still useful from that earlier work has been replaced by ADRs and provisioning scripts on `gh-pages`. The content below is preserved only to keep the historical context legible.

<details>
<summary>Original tenant overview (legacy)</summary>

| Tenant | Domain | Org ID | Original role |
|--------|--------|--------|------|
| Head to Toe Brands | `httbrands.com` | `0c0e35dc-188a-4eb3-b8ba-61752154b407` | Source (parent org) |
| Delta Crown Extensions | `deltacrown.com` | `ce62e17d-2feb-4e67-a115-8ea4af68da30` | Target |

Original phase roadmap (cross-tenant sync model — **superseded**):
1. Pax8 CSP — Azure Subscription & Licensing
2. Cross-Tenant Sync Configuration
3. SharePoint, Teams & Groups
4. Email — Shared Mailboxes & Send-As
5. DNS — SPF/DKIM/DMARC
6. Conditional Access & Security
7. Validation & UAT

The corresponding `docs/00-07*.md` and `scripts/00-08*.ps1` on this branch describe that legacy plan. **They are not the current build.**

</details>

## Working agreements

- **Issue tracking is `bd` (beads)**, not GitHub Issues — see `AGENTS.md`.
- **Tenant changes are gated**: read-only inventory only, no production cleanup without owner approval.
- **Document migration is out of scope** for the current rollout (Tyler's decision, 2026-04-29).
- **Do not commit** `.local/`, raw permission CSVs, or anything containing user PII.

## Contact / ownership

Tyler Granlund (owner). Agent assistants: Richard (`code-puppy-*`).
