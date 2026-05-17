# DeltaSetup repo analysis · 2026-05-16

**Branch:** `gh-pages` (the live `delta-crown-org.github.io/DeltaSetup/` site)
**Top-level entries:** 32
**Total files (excl `.git`, caches):** 854
**Repo size on disk:** 70 MB
**Untracked at session start:** `dce-mockup/`, `docs/sharepoint-research/`

This document is the read-before-cleanup audit. It classifies every
top-level item, surfaces the scaffolding gaps for the SharePoint
hub-and-spoke initiative, and proposes specific actions categorized by
risk level. Tyler signs off before destructive operations.

---

## 1. Top-level inventory — what each thing is and whether it stays

| Entry | Tracked? | What it is | Verdict |
|---|---|---|---|
| `.beads/` | yes | Beads/Dolt project tracker — 2.8 MB embedded DB | **Keep.** Active. |
| `.git/` | n/a | git internals | **Keep.** |
| `.gitattributes` | yes | git config | **Keep.** |
| `.gitignore` | yes | well-curated; already excludes `MEGAN-*.md`, `SESSION-HANDOFF.md`, `.local/`, `phase*-runtime` artifacts | **Keep, no change needed.** |
| `.local/` | gitignored | 10+ MB of screenshots, http-server logs, audit reports — dev artifacts | **Keep (gitignored).** Local only. |
| `.pytest_cache/` | gitignored | stale pytest cache | **Remove safely** (regenerates). |
| `.DS_Store` | gitignored | macOS metadata | **Remove safely.** |
| `AGENTS.md` | yes | agent-runbook for cowork sessions | **Keep.** |
| `DEPLOYMENT-RUNBOOK.md` | yes | DCE live-deploy procedures | **Keep.** |
| `DEPLOYMENT-STATUS.md` | yes | current tenant deployment state | **Keep.** |
| `MEGAN-CALL-BRIEF-2026-05-06.md` | **gitignored** | partner/MSP call prep | **Keep local.** Already excluded from git. |
| `MEGAN-DELTASETUP-MSP-BRIEF.md` | **gitignored** | partner brief | **Keep local.** Already excluded from git. |
| `SESSION-HANDOFF.md` | **gitignored** | session-state for cowork resume | **Keep local.** Already excluded from git. |
| `QA-TEST-PLAN.md` | yes | the master test plan for hub-spoke | **Keep.** |
| `README.md` | yes | repo README | **Update** to add nav to new artifacts. |
| `assets/` | yes | live-site logos & images | **Keep.** Production. |
| `css/` | yes | live-site CSS (144 KB; this is the tokens source of truth) | **Keep.** Production. |
| `dce-mockup/` | **untracked (new)** | this session's hub-spoke mockup + SPFx skeleton + CI/CD | **Add to git.** |
| `docs/` | yes | architecture, ADRs, onboarding, spec pack, research | **Keep.** Update nav. |
| `docs/sharepoint-research/` | **untracked (new)** | Tyler's ChatGPT 5.5 Pro guide (this session) | **Add to git** with renamed subfolder. |
| `generated/` | yes | a single 21 KB owner-decision Excel workbook | **Keep.** |
| `index.html` | yes | **the live site homepage** (92 KB) | **Keep. Do not touch.** |
| `js/` | yes | live-site JS | **Keep.** Production. |
| `msp.html` | yes | live-site MSP page (20 KB) | **Keep.** Production. |
| `operations.html` | yes | live-site Operations page (28 KB) | **Keep.** Production. |
| `phase2-week1/` | yes | security hardening workstream — README, scripts, docs | **Keep.** Active or recent. |
| `phase3-week2/` | yes | Exchange + SharePoint+Teams workstream | **Keep.** Active or recent. |
| `phase4-migration/` | yes | migration workstream | **Keep.** Active or recent. |
| `presentation/` | yes | presentation HTML for stakeholders | **Keep.** |
| `research/` | yes | 22 research subfolders, 1.5 MB | **Keep.** Reference. |
| `templates/` | yes | CSVs and onboarding email templates | **Keep.** |
| `tests/` | yes | repo-level pytest including `tests/architecture/` | **Keep.** Pattern I matched in `dce-mockup/tests/architecture/`. |
| `tools/` | yes | working Python + PowerShell scripts (cross-tenant invite, audit, etc.) | **Keep.** |
| `tools/__pycache__/` | gitignored | stale | **Remove safely** (regenerates). |

**Net:** zero top-level entries are misplaced. The repo's architecture is
intentional. Cleanup is at the noise level (cache directories), not the
structural level.

---

## 2. SharePoint hub-spoke initiative — what exists, what's missing

### 2.1 What exists

| Layer | Location | State |
|---|---|---|
| Spec pack (26 files, ~20k words) | `docs/sharepoint-pnp-spec/` | ✅ Complete (committed 3c4cdfd) |
| ADRs (initiative-scope) | `docs/sharepoint-pnp-spec/decisions/` (7 ADRs) | ✅ |
| ADRs (cross-tenant / hub-spoke broader) | `docs/architecture/decisions/` (4 ADRs) | ✅ |
| Cross-tenant + design roadmap docs | `docs/architecture/` (4 docs) | ✅ |
| Onboarding playbooks | `docs/onboarding/` (7 docs) | ✅ |
| Naming conventions | `docs/naming-conventions/` (1 doc) | ✅ |
| Tier-B HTML mockup (this session) | `dce-mockup/` | ⏳ Untracked |
| Cross-research (ChatGPT 5.5 Pro guide) | `docs/sharepoint-research/ChatGPT 5.5 Pro/` | ⏳ Untracked |
| Research raw findings | `research/sharepoint-*/`, `research/m365-*/`, `research/franchise-*/` | ✅ Pre-existing |
| Working tools (cross-tenant ops) | `tools/` (11 scripts) | ✅ |
| Test scaffolding | `tests/architecture/` + `dce-mockup/tests/architecture/` | ✅ |
| QA test plan | `QA-TEST-PLAN.md` | ✅ |

### 2.2 What is NOT in DeltaSetup by design

The spec pack describes a separate future repo `Delta-Crown-Org/dce-sharepoint`
that will host:

- PnP provisioning templates (`templates/hub/`, `templates/crown-connection/`, etc.)
- Page JSON definitions (`pages/`)
- SPFx web parts (`webparts/`)
- GitHub Actions workflows (`.github/workflows/`)
- Style Dictionary build (`tokens/`, `style-dictionary.config.js`)
- Permission-break register (`reference/permission-breaks.csv`)

That repo doesn't exist yet. The `dce-mockup/ci-cd/` folder is the
ready-to-copy scaffold for when it's stood up. **DeltaSetup must NOT
become the SharePoint code repo** — keep the gh-pages site separation.

### 2.3 Scaffolding gaps to fill in DeltaSetup itself

| Gap | Recommended fix |
|---|---|
| README has no nav to the new `dce-mockup/` or `docs/sharepoint-research/` | Update README with a "Latest deliverables" section |
| `docs/INDEX.md` doesn't exist; navigating 854 files is painful for newcomers | Add a `docs/README.md` that indexes the doc hierarchy |
| ADR-008 (DCE-side group name for HTT corp synced cohort) flagged in RATIONALE.md but not yet written | Add `docs/sharepoint-pnp-spec/decisions/008-dce-htt-corp-sync-group-name.md` |
| Folder name `docs/sharepoint-research/ChatGPT 5.5 Pro/` has spaces (URL-unfriendly, shell-awkward) | Rename to `docs/sharepoint-research/chatgpt-5.5-pro/` |
| Mockup tracked file count of zero in git | `git add dce-mockup/` after sign-off |

---

## 3. Noise/junk to remove (Category A — safe, all gitignored)

These files are all already excluded from git. Removing them does not
change any tracked content; they regenerate as needed.

| Path | Reason |
|---|---|
| `.pytest_cache/` (repo root) | regenerates on next pytest run |
| `tools/__pycache__/` | regenerates on next Python import |
| `tests/__pycache__/` | regenerates on next pytest run |
| `tests/architecture/__pycache__/` | regenerates |
| `phase4-migration/scripts/__pycache__/` | regenerates |
| `dce-mockup/tests/architecture/__pycache__/` | regenerates |
| `dce-mockup/.pytest_cache/` (if created) | regenerates |
| `.DS_Store` (repo root) | macOS Finder metadata |
| `.local/reports/tenant-inventory/.DS_Store` | macOS Finder metadata |
| `docs/sharepoint-research/.DS_Store` | macOS Finder metadata |
| `docs/sharepoint-research/ChatGPT 5.5 Pro/~$t-sharepoint-infrastructure-development-guide.docx` | Microsoft Word lock file from open doc; can recreate |

---

## 4. Light organization (Category B — improves discoverability)

These are small structural touches with low risk.

| Change | Rationale |
|---|---|
| `docs/sharepoint-research/ChatGPT 5.5 Pro/` → `docs/sharepoint-research/chatgpt-5.5-pro/` | Eliminates spaces in path; mirrors `docs/sharepoint-pnp-spec/` naming style |
| Update `README.md` with a "Sprint-1 deliverables" section linking the spec pack, mockup, ChatGPT research, and SPFx skeleton | Newcomer onboarding |
| Add `docs/README.md` (doc index) | 22 doc files in `docs/`; need a TOC |

---

## 5. Scaffolding additions (Category C — supports sprint-1 kickoff)

| Addition | Rationale |
|---|---|
| `docs/sharepoint-pnp-spec/decisions/008-dce-htt-corp-sync-group-name.md` | Defect flagged in `dce-mockup/RATIONALE.md` § 3 — proposes the missing DCE-side group name `DCE-HTT-Corporate-Sync` and the rationale |
| `docs/sharepoint-pnp-spec/decisions/009-teams-moderation-beta-only.md` | Captures the BETA-only finding from `dce-mockup/RESEARCH-DELTAS.md` so it's discoverable in the ADR index |
| `docs/sharepoint-pnp-spec/SPRINT-1-KICKOFF.md` | Single-page "next steps" linking spec pack → mockup → future `dce-sharepoint` repo |

---

## 6. Items NOT proposed (Category D — explicit approval required)

These look like cleanup opportunities but I'm flagging-not-doing them
because they touch active or sensitive work:

| Item | Why I'm not touching it without sign-off |
|---|---|
| Archive `phase2-week1/`, `phase3-week2/`, `phase4-migration/` to `docs/archive/` | These have READMEs that suggest they may still be active. Moving them silently breaks any external links. |
| Consolidate `docs/architecture/decisions/` + `docs/sharepoint-pnp-spec/decisions/` | Two intentional ADR scopes (broader vs. spec-pack-scoped). Forcing them together loses semantics. |
| Remove `MEGAN-*.md` / `SESSION-HANDOFF.md` from local filesystem | They're already gitignored. Tyler may still be using them as personal scratch. |
| Remove the `.beads/embeddeddolt/` 2.8 MB DB | This is Beads' working data; deleting breaks the issue tracker. |
| Touch `index.html`, `msp.html`, `operations.html`, `css/`, `js/`, `assets/` | Live production website. Out of scope. |

---

## 7. Recommended execution order

1. **Execute Category A** (cache cleanup) — silent, regenerable.
2. **Execute Category B** (renames, README updates) — discoverable, no breakage.
3. **Execute Category C** (additions) — purely additive.
4. **Stage Categories A-C as untracked changes for Tyler's review**, do NOT auto-commit.
5. **Write CLEANUP-AUDIT.md** with every action and a rollback path.
6. Tyler reviews, decides whether to also approve any Category D items.
7. Tyler commits.

---

## 8. Estimated impact

- **Files deleted (Category A):** ~10 cache/junk files, 0 KB of tracked content.
- **Files renamed (Category B):** 4 files (the ChatGPT folder).
- **Files added (Category B + C):** 4 docs.
- **Files modified (Category B):** 1 (README.md).
- **Git diff size:** under 1 KB of meaningful changes outside the new additions.
- **Risk of breaking the live site:** zero (no production HTML/CSS/JS touched).
