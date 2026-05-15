# DCE SharePoint Hub — Final Stretch (Friday 5/15/2026 Delivery)

You are operating inside the **HTT-BRANDS/DeltaSetup** repo. Today is **Friday, May 15, 2026** — this is the day we deliver the basic Delta Crown Extensions (DCE) SharePoint hub to Tyler Granlund and Jamie Baer. The Dallas working session is the week of 5/18 where Jamie populates branding and content.

Before you do anything else, audit the current repo state and align against The Standard framework. The repo is further along than this prompt previously assumed — start from where we actually are, not from zero.

---

## Phase 0 — Required reading (read these BEFORE Phase 1)

This is not a from-scratch tenant build. The DCE tenant is already standing, validated, and partially configured. You are finishing the SharePoint hub layer on top of work that has already shipped.

Read in this order:

1. **The Standard framework** — `~/dev/01-htt-brands/AWS-Setup/identity-theming-bifrost/07-the-standard-framework.md`. Delta Crown is the **operational realization of The Standard** ("firm, fair, friendly — one standard, five brands, every team member"). Everything you build here defines the golden-child pattern that gets cloned to BCC, FN, TLL.

2. **MIDL alignment** — `~/dev/01-htt-brands/freshdesk-oracle/docs/stakeholder-identity-package/`. The Master Identity Decision Layer was schema-locked overnight 2026-05-15. The field-ownership matrix at `FIELD-OWNERSHIP-MATRIX.md` defines per-attribute source-of-truth, confidence gates, and write eligibility — every dynamic group rule you author for DCE must align with that matrix. **DCE is marked Disabled=true in the MIDL canary scope** until its first physical location opens; that means your DC distribution lists are pre-provisioned but membership stays small until then.

3. **Current DCE repo state** — review the last 5 days of commits and the `docs/` folder. Specifically:
   - `docs/production-launch-readiness-report.md` (production-launch go-no-go committed 2026-05-12)
   - `docs/master-dce-audit-findings.md`
   - `docs/delta-crown-{identity,sharepoint,exchange,security-apps-licenses,compliance}-inventory-summary.md`
   - `docs/delta-crown-sharepoint-pnp-inventory-summary.md` — this is the existing PnP inventory; check it before assuming nothing exists
   - `docs/owner-decision-worksheet.md` + the owner decision workbook (`generated/`)
   - `docs/tenant-inventory-access-matrix.md`
   - The May 12 commit `feat(identity): apply validated DCE metadata and create franchise owners DDG` (`abbfd9c`) — **the franchise owners dynamic distribution group is already provisioned**

4. **Sister repos for cross-reference:**
   - **`Cross-Tenant-Utility`** — B1 safe guest cleanup ran across HTT/BCC/FN/TLL/DCE on 2026-05-12 (`reports/B1SafeGuestCleanup_DCE_2026-05-12_172121.json`). Use this as the basis for the Scot Cannon `_fullHTT` drift root-cause work in Phase 4 — that cleanup already resolved part of it.
   - **`Groups-Audit`** — 9-list architecture audit + ADR-0001 accepted (STRIDE co-signed 2026-05-06). Naming convention precedent lives here.
   - **`freshdesk-oracle/docs/state-of-identity.html`** — published portfolio identity status; reference for what canonical identity attributes exist per tenant.

5. **Monday tasks on Tyler's board** (`htt-brands.monday.com/boards/18180357343` — "🎫 Tyler Requests"):
   - `11919714089` **"Delta Crown — Golden Child tenant template + Megan alignment"** — In Progress. Confirms this work IS the golden-child rollout. Merged with the Pitari SharePoint provisioning ask. Update post-delivery.
   - `11964879982` **"Distribution Lists and Groups Architecture — cleanup queue + governance"** — In Progress. The HTT-domain mail flow rule is **live and tested** for the existing 9 lists. The 4 new DC lists you'll create must inherit the same rule. The 61-candidate cleanup queue is the post-canary work, not this delivery.
   - `12004990969` **"GoDaddy account audit"** — In Progress. Domain renewal landscape includes Delta Crown between July–October 2026 — relevant context for the `@deltacrown.com` domain inheritance work.

---

## Phase 1 — Repo discovery and inventory (do this first, output before doing anything else)

This is a **frontend-heavy** repo. Top-level directories are: `assets/`, `css/`, `js/`, `templates/`, `tools/`, `phase2-week1/`, `phase3-week2/`, `phase4-migration/`, `tests/`, `presentation/`, `research/`, `docs/`, `generated/`, `msp.html`, `index.html`, `operations.html`. There is **no `scripts/` directory** — any PnP PowerShell / Graph / Microsoft 365 CLI / Bicep work needs a new home (suggest `scripts/sharepoint/` and `scripts/exchange/`).

Inventory before you write any code. Confirm or correct each of these:

1. **Directory structure** — is the layout above still accurate? Note any new top-level dirs.
2. **Existing SharePoint provisioning artifacts** — search for `*.ps1`, `*PnP*`, `*Graph*` files anywhere in the tree; check `tools/`, `templates/`, `phase2-week1/`, `phase3-week2/`. Report what exists and what its state is.
3. **Existing Entra / dynamic group / distribution group automation** — the franchise owners DDG ships in commit `abbfd9c`. What other Entra-touching code is in the repo? Check `tools/`, `phase4-migration/`.
4. **Existing Teams provisioning** — same search pattern. Note: the prompt previously assumed Teams scripts may exist; they likely don't.
5. **Brand hub assets / templates / themes / nav JSON** — check `templates/`, `assets/`, `css/`. The repo's public-facing pages (`index.html`, `operations.html`, `msp.html`) are NOT the SharePoint hub — they are the public Delta Crown Extensions site that's WCAG 2.2 AAA certified (per `41ff63e docs(a11y): stamp final AAA cert evidence hash`). The SharePoint hub is a separate workstream that lives inside the HTT tenant.
6. **Architecture / runbook docs** — `DEPLOYMENT-RUNBOOK.md`, `DEPLOYMENT-STATUS.md`, `SESSION-HANDOFF.md`, `AGENTS.md`, `README.md`, `MEGAN-CALL-BRIEF-2026-05-06.md`, `MEGAN-DELTASETUP-MSP-BRIEF.md`. Note their current freshness.
7. **AWS-Setup architecture pack** — the prompt previously asked you to confirm presence of `AWS-ARCHITECTURE-OVERVIEW.md`, `CURRENT-STATE-BRIEFING.html`, `reports/HTT-AWS-Architecture-Executive-Guide.docx`, `reports/HTT-AWS-Architecture-Executive-Workbook.xlsx`, `scripts/generate_executive_architecture_docs.py`. These live in **the separate `AWS-Setup` repo**, not in `DeltaSetup`. Confirm they exist there and are current — they're the cross-reference for AWS hosting, not the DCE SharePoint work itself.
8. **Beads issues** — run `bd list` for any open issues. The `DeltaSetup-*` prefix indicates DeltaSetup-scoped items. Closed: DeltaSetup-9gq (AAA cert), DeltaSetup-ta9 (plain-language summary), DeltaSetup-ewq (abbreviations), DeltaSetup-1kp (role=group), DeltaSetup-did (axe-core regression). Open: check `bd list --status open` for the remaining backlog.
9. **WIP branches** — list any non-main branches with Delta Crown SharePoint scaffolding. If found, surface what's in them before authoring fresh code.

**Output a clean inventory report. Compare against the assumptions in this prompt and flag every divergence. Do not proceed to Phase 2 until the inventory is in front of Tyler.**

---

## Phase 2 — Project context (what you're building toward)

The DCE SharePoint hub is the brand-hub proof of concept for HTT Brands' four-brand portfolio (The Lash Lounge ~140 locations, Bishops Cuts/Color ~40, Frenchies Modern Nail Care ~20, Delta Crown Extensions upcoming). Delta Crown is **the golden child** — every pattern you author here gets cloned to the other three brand hubs as their pattern.

The hub serves Crown Extension Studio (CES) franchisees — independent salon owners who pay royalties, operate under the Crown Franchise Agreement, and need a single digital home. The hub is **the navigation layer over canonical source content**, not a re-host.

Source content lives in SharePoint at:
- `/Master DCE/Operations/CROWN - Operations Manual.docx` (definitive)
- `/Master DCE/Operations/DCE_Business Plan Template 2026.pptx`
- `/Master DCE/Operations/Zenoti/Solution Document - Delta Crown.xlsx`
- `/Education/HTT BEAUTY UNIVERSITY.docx` (multi-brand learning context)
- `/Vendors/ACTIVE Vendors TLL/SERVICE/WiseTail/LMS Requirements and Deal Breakers.docx` (LMS pattern reference)

What franchisees need access to via the hub:
- CES Operations Manual V.2.1
- Onboarding materials from Hanna Coldiron (Onboarding & Trainer Manager)
- Training resources for stylists, managers, concierges
- Pricing matrices (Beaded Weft, Fusion/Tape-In, Color, Blowout Bar, Retail)
- Membership documentation (VIP, Maintenance, Hair Replacement, Blowout)
- Forms (Product Submission, Infringement Reporting, Manager Training)
- FBC (Franchise Business Coach) contact + cohort
- Home Office communication channels

---

## Phase 3 — Friday 5/15 delivery scope (TODAY)

Deliver the BASIC SharePoint hub to **Tyler Granlund** and **Jamie Baer** ONLY. Not the broader group. Jamie populates branding (logos, colors, headers, Crown Standard imagery), folder structure refinement, Design & Construction Manual, and content during the Dallas working session week of 5/18 with Erica Upshur and Meg Roberts.

"Basic" means:

- SharePoint site provisioned in the HTT tenant under the Delta Crown brand domain path
- Hub-and-spoke architecture matching Tyler's tenant standard (the golden child pattern)
- Folder skeleton in place (Phase 5 below)
- Navigation structure wired
- Microsoft Teams channels aligned and wired to the hub
- Email domain inheritance + brand-toggle send-as work end to end against the existing HTT-domain mail flow rule (item 11964879982)
- The 3 remaining new Delta Crown distribution lists created and tested (franchise owners DDG is already done — Phase 4)
- Role-based access scopes defined and assigned
- Jamie Baer has Edit access and can populate next week

The pretty/branding layer is Jamie's job. **Do not invent branding assets.** Use neutral placeholders that Jamie can replace.

---

## Phase 4 — Distribution group integration (Kristin's central operational ask)

Kristin captured the 9-list ask in the 5/11 1:1 and explicitly flagged it for Firefly's note-taker — this is a tracked commitment, not a side ask. Status is captured on Monday item `11964879982`.

### 4.1 What's already done

The **franchise owners dynamic distribution group** for Delta Crown was provisioned 2026-05-12 (commit `abbfd9c`, paired with `c9e40b5 feat(exchange): add franchise owners dynamic distribution group target`). Read those commits + the validated DCE metadata work (`362db6c chore(bd): record validated DCE apply values`) before authoring anything new. **Do not re-create the franchise owners DDG.**

### 4.2 What still needs to be created

Three additional Delta Crown lists must be created to complete the 9-list mirror:

| EXISTING (precedent) | NEW (still to create for DCE) |
|---|---|
| `studiomanagers@frenchiesnails.com` / `nationalfranchisemanagers@bishops.co` / `_TLLmanagers@thelashlounge.com` | DC managers list |
| `frenchieslocations@frenchiesnails.com` / `nationalfranchisestores@bishops.co` / `_TLLsalons@thelashlounge.com` | DC stores/salons list |
| `_fullHTT@httbrands.com` (HTT internal, dynamic) | DC owners list (if pattern applies — confirm with Tyler) |

### 4.3 Naming convention — confirm with Tyler before creating

Existing convention is brand-led, not generic `DC*`:
- TLL uses underscore prefix: `_TLLmanagers@thelashlounge.com`
- Frenchies uses no prefix: `studiomanagers@frenchiesnails.com`
- Bishops uses descriptive: `nationalfranchisemanagers@bishops.co`

Proposed candidates for DCE (need Tyler's call):
- `managers@deltacrown.com` (Frenchies-style)
- `_DCmanagers@deltacrown.com` (TLL-style underscore prefix)
- `nationalmanagers@deltacrown.com` (Bishops-style)

**Action:** propose three naming candidates to Tyler with rationale; do not create until he picks one. Use the same answer for the salons list and the owners list so the brand is internally consistent.

### 4.4 Auto-add behavior — attribute-driven per The Standard

Per the field ownership matrix and MIDL design:
- Megan Myrand (Sui Generis) adds attributes during onboarding
- Dynamic groups auto-populate from those attributes (`ext_attr_brand=DCE`, `ext_attr_role_tier=manager|employee`, `ext_attr_location_id`)
- Validation confirms membership

For DCE specifically: **the brand is pre-launch with no operational locations yet.** Dynamic groups can be authored with the right rules now, but membership stays empty until the first physical Delta Crown location opens and onboards staff. This is consistent with the MIDL canary scope marking DCE as read-only.

### 4.5 Mail flow rule

The HTT-domain rule is **live and tested** for the existing 9 lists (per Monday item 11964879982). The new DC lists inherit the same rule:
- Anyone at `@httbrands.com` can send to any list
- External senders are rejected
- Per-person allowed-sender restrictions are NOT used (that was the Profit Mastery failure root cause)

Run a real end-to-end send test against each new list (not just config check) before declaring done.

### 4.6 KNOWN BLOCKER — `_fullHTT` Scot Cannon drift

`_fullHTT@httbrands.com` was showing Scot Cannon as still a member after his departure. **Root-cause this before propagating the dynamic group pattern to DCE.**

Likely related to the B1 safe guest cleanup work that ran on 2026-05-12 across all tenants (`Cross-Tenant-Utility/reports/B1SafeGuestCleanup_DCE_2026-05-12_172121.json`). Check whether the cleanup already addressed this:

1. Re-run `_fullHTT` membership query post-cleanup
2. Compare against the guest inventory in `Cross-Tenant-Utility/reports/Audit_DCE_*/GuestInventory_DCE.json`
3. If Scot is still ghost-member after cleanup, suspect:
   - Mailbox indexing lag on departed user
   - Shared mailbox or alias creating phantom membership
   - Attribute sync delay between Entra ID and the dynamic group rule engine
   - Soft-deleted but not hard-deleted user still matching the rule

If you cannot resolve this in the same session, surface it as a BLOCKER and proceed with manual/static groups for DCE — do not propagate broken dynamic group logic into the golden-child pattern.

---

## Phase 5 — Folder structure to scaffold

Skeleton only. Jamie populates content next week. Map these to the Operations Manual table of contents.

**Naming convention: uniform folder names across brands** (e.g., "Services and Pricing" not "DCE Services") so franchisees of different brands see the same navigation structure with brand-specific content underneath. Brand-specific calls-to-action, links, and content within the uniform skeleton.

```
Welcome and Onboarding
  Hanna Coldiron's salon opener materials
  Franchise Agreement reference (NOT executed agreements themselves)
  Pre-opening consultation guide

The Crown Standard
  Operations Manual link
  Core Values (Kaizen, Teamwork, Positivity)
  Brand identity

Services and Pricing
  Hair Extension Services (Transformation, Push-Up, Reinstall types)
  Installation Methods (Weft, Tape-In, Fusion/K-Tip, Hair Replacement, Mesh)
  Color Services menu
  Add-Ons, Upgrades, Consultation types
  Pricing matrices (Beaded Weft, Fusion/Tape-In, Color, Blowout Bar, Retail)

Membership Program
  VIP Membership
  Maintenance Membership
  Hair Replacement & Integration Membership
  Blowout Membership
  General Membership Policies

Training and Education
  LPE methodology
  Crown Standard Training Program
  Stylist certification paths
  Manager Training registration
  HTT Beauty University (future-state link)

Staffing
  Salon Manager (job description, R&R, compensation)
  Lead Extensionista (job description, R&R, compensation)
  Crown Concierge (job description, remote/hybrid status)
  Extensionista (job description, R&R, compensation)

Marketing
  Local Marketing University
  National vs local strategy reference
  Brand asset request

Financial
  Chart of Accounts (mandatory)
  Proforma templates (new salon, successive salon)
  Qvinci training and access
  Kaizen Growth Tracker
  P&L Submission requirements

Legal and Compliance
  Trademarks reference
  Infringement Reporting Form link
  Franchise Agreement compliance

Forms and Resources
  Product Submission Form
  Infringement Reporting Form
  Manager Training registration
  Help Desk (currently routes to thelashlounge.freshdesk.com until DCE Freshdesk stands up)

FBC Communication
  Cohort assignment
  FBC contact
  Six functions of the FBC role

Home Office Directory
  Executive Team (Meg Roberts, Kristin Kidd, Joe Honkala, Erica Upshur, Noelle Peter, Patti Rother)
  Operations, Marketing, Training, Administrative contacts
```

---

## Phase 6 — Role-based access (six role types from Operations Manual)

| Role | Access scope |
|---|---|
| Franchise Owner / CEO | Full access to all owner content |
| Salon Manager | Operations, Qvinci financial reporting, staff management, inventory, vendor coordination |
| Lead Extensionista | Training resources, mentorship materials, service quality standards |
| Crown Concierge | Guest communication standards, scheduling, CRM, remote/hybrid documentation |
| Extensionista | Service protocols, technical training, certification paths |
| Onboarding/Training | Salon opener materials, pre-opening consultation (Hanna Coldiron's scope) |

**Reference UX pattern:** the FAC Cohort Groups Dev site delivered cleanly on 2026-03-18 — `https://the-lash-lounge.github.io/FAC-Cohort-Dev/` — plain language, password-protected where appropriate, expandable rosters. Match that bar.

Role assignments map to MIDL `role_tier` values once the canary populates Entra extension attributes: `multi_unit_owner`/`single_unit_owner` → Franchise Owner; `manager` → Salon Manager; `employee` → other roles. Per the field-ownership matrix, `role_tier` is HIGH-confidence-required for write — until DCE has staff, role assignments stay manual or operator-confirmed.

---

## Phase 7 — Out of scope for Friday

Do NOT build:
- Public-facing Delta Crown WordPress website (separate marketing workstream, April–June 2026 — see `/Master DCE/DCE Marketing/Website/DCE Website Project Overview.docx`)
- HTT Beauty University / WiseTail LMS integration (separate scope expansion)
- DCE-specific Freshdesk instance (still routing through `thelashlounge.freshdesk.com` per the manual)
- Final branding assets (Jamie's job in Dallas the following week)
- Design & Construction Manual content (Jamie populates next week)
- Member rosters with real owner data (3 Crown franchisees within HTT network per Meg's 4/13 note, but populating their data is post-delivery)

---

## Phase 8 — Validation checklist before declaring done

Output PASS / FAIL / BLOCKED for each item. **Do not declare DONE if any item is FAIL. If BLOCKED, surface the blocker with the workaround in place.**

1. SharePoint site provisions cleanly in HTT tenant at the Delta Crown brand domain path
2. Hub-and-spoke architecture matches the tenant standard, ready to be cloned to other brands
3. Folder skeleton in place for all 11 top-level sections (10 from the Operations Manual + FBC Communication)
4. Microsoft Teams channels wired and visible
5. Email domain inheritance + brand-toggle send-as work end to end against the HTT-domain rule
6. **The 3 remaining new DC distribution lists created and tested** (franchise owners DDG already exists — verify it's still healthy):
   - HTT-domain senders can send to each list (run a real send test, not just config check)
   - External senders correctly rejected
   - Membership reflects current Crown roster (empty/small is OK pre-launch)
7. `_fullHTT` Scot Cannon drift either resolved (likely already handled by 5/12 B1 cleanup) or explicitly documented as BLOCKER with manual fallback in place
8. Role-based access scopes defined for all 6 role types
9. Jamie Baer has Edit access and can begin populating
10. Tyler can demo the structure to Kristin without obvious gaps
11. The franchise owners DDG provisioned 5/12 is still healthy and reachable from the hub
12. Cross-reference to the MIDL field ownership matrix documented in the hub's admin notes (so future SharePoint admins know dynamic groups inherit from MIDL, not from manual edits)

---

## Phase 9 — How to communicate progress

Tyler's COO Kristin Kidd has explicitly asked for plain voice, not AI-flavored copy. When you generate any user-facing text (SharePoint page descriptions, Teams channel descriptions, distribution list display names, email templates for auto-add notifications), follow these rules:

- No "executive-grade," "comprehensive solution," "best-in-class," or similar corporate filler
- No em-dashes used as decorative pause; either use them grammatically or drop them
- Direct, scannable, business-first
- Match the Operations Manual's voice — it calls franchisees "the CEO of your own business"

For repo commits, follow the existing convention: `feat(scope):`, `fix(scope):`, `docs(scope):`, `chore(scope):`. For beads issues, use the existing `DeltaSetup-*` severity/status conventions.

For the post-delivery Monday updates, update items `11919714089` (Delta Crown — Golden Child) and `11964879982` (Distribution Lists Architecture) with completion notes.

---

## Phase 10 — Reporting back

When you have completed Phase 1 (discovery), **STOP** and output:

1. **Repo inventory** — what exists per §1
2. **What exists vs what this prompt assumed** — every divergence flagged
3. **Conflicts between this prompt and the actual repo state** — note any prompt sections that need updating in v2
4. **Proposed execution plan for Phases 2–8** based on what you found — phase by phase, owner per task
5. **Questions for Tyler before proceeding** — naming convention call (§4.3), `_fullHTT` drift status check, any access-scope ambiguity, anything the prompt is silent on

**Do not begin destructive operations** (deletes, force-pushes, group modifications, mail-flow rule changes) without Tyler's explicit go-ahead per each operation. Read-only discovery and additive changes (new files, new groups, new sites) are fine to proceed with after Phase 1.

Reference the standard framework alignment when proposing the plan: every artifact you create should fit the "firm, fair, friendly — one standard, five brands, every team member" pattern that will be reused for BCC, FN, and TLL hubs.

Go.

---

## Reference paths (open these as you work)

| Purpose | Path |
|---|---|
| The Standard framework | `~/dev/01-htt-brands/AWS-Setup/identity-theming-bifrost/07-the-standard-framework.md` |
| MIDL field ownership matrix | `~/dev/01-htt-brands/freshdesk-oracle/docs/stakeholder-identity-package/FIELD-OWNERSHIP-MATRIX.md` |
| MIDL strategic ADR | `~/dev/01-htt-brands/freshdesk-oracle/docs/stakeholder-identity-package/ADR-MASTER-IDENTITY-DECISION-LAYER.md` |
| DCE SharePoint inventory | `~/dev/04-other-orgs/DeltaSetup/docs/delta-crown-sharepoint-pnp-inventory-summary.md` |
| DCE production launch readiness | `~/dev/04-other-orgs/DeltaSetup/docs/production-launch-readiness-report.md` |
| DCE owner decision workbook | `~/dev/04-other-orgs/DeltaSetup/docs/owner-decision-worksheet.md` |
| Franchise owners DDG provisioning | git commit `abbfd9c` (DeltaSetup) |
| B1 safe guest cleanup (DCE) | `~/dev/03-personal/Cross-Tenant-Utility/reports/B1SafeGuestCleanup_DCE_2026-05-12_172121.json` |
| Groups-Audit 9-list precedent | `~/dev/Groups-Audit/scripts/output/` |
| FAC Cohort Groups Dev (UX reference) | `https://the-lash-lounge.github.io/FAC-Cohort-Dev/` |
| Public DCE identity status | `https://htt-brands.github.io/identity-status-report/` |
| Tyler Requests — Golden Child item | `https://htt-brands.monday.com/boards/18180357343/pulses/11919714089` |
| Tyler Requests — Distribution Lists item | `https://htt-brands.monday.com/boards/18180357343/pulses/11964879982` |
