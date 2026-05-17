# Oracle audit — DCE SharePoint hub-and-spoke initiative

**Auditor:** Richard (code-puppy `code-puppy-1bc20e`)
**Date:** 2026-05-16
**Scope:** Independent verification of the cowork-agent / ChatGPT 5.5 Pro
sprint-1 deliverables on top of the original spec pack (commit `3c4cdfd`).
**Verdict:** ✅ **Ship it.** Cleared for sprint-1 execution.

This document is the Oracle's reaffirmation. It is intentionally short
and citation-dense — it does not duplicate the spec pack, it audits it.

---

## 1. What was verified end-to-end

| Check | Method | Result |
|---|---|---|
| Production website untouched | `git diff HEAD -- index.html operations.html msp.html css/ js/ assets/` | ✅ empty diff |
| Zero secrets/keys in working tree | `find . \( -name '*.pfx' -o -name '*.key' -o -name '*.crt' -o -name '*.pem' -o -name '*.p12' \)` | ✅ no matches |
| Zero hardcoded creds in new code | `grep -rE 'password\|client_secret\|api[_-]?key\|BEGIN.*PRIVATE KEY' dce-mockup/ docs/sharepoint-pnp-spec/decisions/008-* docs/sharepoint-pnp-spec/decisions/009-*` | ✅ no matches |
| Mockup fitness tests | `python3 -m pytest dce-mockup/tests/architecture/ -v` | ✅ **12 / 12 PASSED** in 0.01s |
| JSON validity | `python3 -c 'json.load(...)'` × 2 | ✅ `dce-channels.json`, `dce-tokens.json` parse |
| YAML validity (CI/CD workflows) | `python3 -c 'yaml.safe_load(...)'` × 4 | ✅ all 4 GitHub Actions YAML parse |
| README change is additive only | `git diff README.md` | ✅ +22 lines, 0 modifications, 0 deletions |
| Cleanup of cache/junk (gitignored) | `find -name __pycache__ -o -name .pytest_cache -o -name .DS_Store -o -name '~$*'` | ✅ 11 items deleted, 0 tracked-file changes |

All eight gates green.

---

## 2. Reaffirmation of the cowork-agent's output

The deliverables documented in `CLEANUP-AUDIT-2026-05-16.md` and
`dce-mockup/RATIONALE.md` materially improve on the original spec pack.
The Oracle endorses:

### 2.1 The mockup (`dce-mockup/` — 33 files)

- Three rendered pages with a working role-switcher across the six-persona
  taxonomy (matches `02-identity-audience.md`).
- CSS tokens with **zero hex codes outside `:root` blocks** (enforced by
  fitness test `test_no_raw_hex_outside_tokens`).
- 1:1 mapping from each HTML `data-component` to a planned SPFx web part
  (table in `RATIONALE.md` § 4).
- SPFx skeleton in TypeScript+React with audience-gate component.
- CI/CD scaffold: 4 GitHub Actions workflows, 3 PowerShell/Python scripts,
  Teams channel configuration JSON.
- 12 pytest fitness functions enforcing the contract.

### 2.2 ADR-008 — `DCE-HTT-Corporate-Sync` group naming

Closes a real gap in `02-identity-audience.md` where R6 (HTT Corporate)
was named on the source side (`SG-DCE-Sync-Users`) but not on the DCE
side. The membership rule `(user.userType -eq "Member") and (user.mail -match ".*@httbrands\.com$")`
is correct given the cross-tenant sync produces `userType=Member`
B2B objects (verified in `00-context.md`).

**Oracle endorsement:** Accept once group is created. Promote to
"Accepted" status; no rework needed.

### 2.3 ADR-009 — Teams moderation BETA endpoint

Captures a genuine Microsoft Graph limitation. The `moderationSettings`
property only works under `/beta/teams/{id}/channels/{id}` — v1.0 silently
ignores it. Validation:
- Three fitness tests enforce the BETA-only constraint in CI.
- Migration plan exists for the eventual v1.0 promotion (changelog
  monitor + one-line endpoint swap + ADR status update to "Superseded").
- Fallback documented (Teams admin UI per channel).

**Oracle endorsement:** Accept. The risk section is honest and the
mitigation is concrete.

### 2.4 Sprint-1 entry-point + doc index

`docs/sharepoint-pnp-spec/SPRINT-1-KICKOFF.md` and `docs/README.md`
solve the "where do I start when I resume next week" problem. Both
are correctly cross-linked from the top-level README.

### 2.5 Path hygiene

The rename `docs/sharepoint-research/ChatGPT 5.5 Pro/` →
`chatgpt-5.5-pro/` eliminates spaces in paths. Convention now matches
the rest of the repo. No broken in-repo links (verified via `grep -r
'ChatGPT 5.5 Pro' docs/ dce-mockup/`).

---

## 3. Category D decisions (the audit deferred these to Tyler)

The Oracle decides; Tyler may override. Decisions and reasoning:

| Item | Decision | Reason |
|---|---|---|
| Move `phase2-week1/`, `phase3-week2/`, `phase4-migration/` into `docs/archive/` | **NO** | They contain READMEs and active scripts. Silent move breaks `git log` discoverability and any external links. If archived, do so deliberately later with `git mv` to preserve history. |
| Consolidate the two ADR scopes (`docs/architecture/decisions/` and `docs/sharepoint-pnp-spec/decisions/`) | **NO — keep separate** | The two scopes are intentional: broader project decisions (4 ADRs) vs spec-pack-specific decisions (9 ADRs). Consolidation loses semantic boundary. Cross-link instead (already done in `11-decisions-readme.md`). |
| Delete `MEGAN-*.md` / `SESSION-HANDOFF.md` from local filesystem | **NO — Tyler's call** | These are gitignored partner-briefing scratch files. Not the Oracle's call to delete from Tyler's machine. Action: keep as-is, Tyler removes if/when no longer useful. |
| Truncate `.beads/embeddeddolt/` (2.8 MB) | **NEVER** | Active beads issue tracker DB. Deletion breaks `bd` immediately. |
| Touch live website files (`index.html`, `operations.html`, `msp.html`, `css/`, `js/`, `assets/`) | **NEVER WITHOUT REQUEST** | Production site at `https://delta-crown-org.github.io/DeltaSetup/`. Per AGENTS.md gates: requires accessibility + browser-smoke + axe-core passes. Out of scope tonight. |

---

## 4. Gaps the Oracle still sees (filed as bds, not blockers)

These do not prevent ship. Each becomes a tracked issue.

1. **Spec defect — Fluent UI v8 vs v9.** `03-design-system.md` says v9;
   `Convention-Page-Build/spfx/package.json` uses v8.121.0; `RESEARCH-DELTAS.md`
   notes ADR-006 final picked v8 but the spec wasn't updated. **Pick one,
   update spec, write ADR (likely 010).**
2. **Spec defect — Gulp vs Heft.** `07-ci-cd-pipeline.md` YAML samples
   call `gulp bundle --ship`; the SPFx scaffold uses Heft
   (`heft build --production`). **Update spec YAML.**
3. **Explicit rollback matrix.** The runbooks (`10-runbooks.md`) cover
   permission rollback well; PnP template rollback and SPFx solution
   rollback are implicit. Tyler explicitly called out "clear rollback
   procedures" as a confidence pillar. **Add an explicit rollback section
   to `12-implementation-plan.md`** (one matrix: change type → rollback
   command → expected MTTR).
4. **ADR-006 final cosign pending** (Security Auditor) per
   `SPRINT-1-KICKOFF.md` § 5. Until cosigned, ADR-006 stays Proposed and
   the spec defects above are blocked on its outcome.
5. **DCE not currently a Microsoft 365 MTO member.** Mockup works without
   it; joining simplifies a handful of edge cases. Worth a v2 ADR.
6. **Spec doesn't document AADSTS500213 cross-tenant policy guardrail.**
   Current DCE B2B policy is `AllUsers` per
   `Convention-Page-Build/AADSTS500213-ROOT-CAUSE-AND-FIX.md`. Operationally
   fragile if scoped to a group without first inviting every user.
   **Add a § "Cross-tenant policy guardrail" to `02-identity-audience.md`.**

---

## 5. Tyler's four confidence pillars — Oracle's mapping to artifacts

| Pillar | Where it lives in the artifacts today | Score |
|---|---|---|
| **Security** | App-only cert auth (ADR-007), weekly permission audit workflow (`ci-cd/workflows/permission-audit.yml`), zero secrets in code (verified), bootstrap.sh prints secrets for GitHub-Secrets injection only, BETA endpoint flagged for revisit (ADR-009) | 4 / 5 — gap = no formal threat model doc |
| **Stability** | PR validation pipeline (`pr-validation.yml`), environment-gated prod deploys (`environment: prod` in `deploy-prod.yml`), dev/prod tier split (per ADR-002), 12 fitness functions as architectural contract | 5 / 5 |
| **Scalability** | Hub-and-spoke topology (ADR-001), parameterizable PnP templates per spoke, role taxonomy supports adding brands (Bishops, Frenchies, TLL) without restructuring identity, group-driven audience targeting | 4 / 5 — gap = region/store decomposition deferred (Perplexity note) |
| **Adaptation** | 9 ADRs each with "Alternatives considered" + "Consequences", explicit BETA→v1.0 migration plan (ADR-009), spec defects logged in RATIONALE not silently fixed, evaluation rubric reusable for future bake-offs | 5 / 5 |

**Aggregate:** 18 / 20 — strong. The two gaps are documentation, not
architecture.

---

## 6. What ships next (post-Oracle, pre-sprint-1)

In execution order:

1. **(this commit)** Land the cowork-agent's six deliverables + this audit
   to git. Push.
2. Tyler creates `Delta-Crown-Org/dce-sharepoint` (per ADR-006).
3. Copy `dce-mockup/ci-cd/` into the new repo as seed.
4. Tyler runs `ci-cd/scripts/bootstrap.sh` interactively.
5. Tyler pastes printed secrets into GitHub repo Settings → Secrets.
6. ADR-006 final → Accepted (Security Auditor cosign).
7. Spec defects from § 4 above resolved (Fluent UI lock, Heft alignment,
   rollback matrix, cross-tenant guardrail).
8. ADR-008 → Accepted after `DCE-HTT-Corporate-Sync` group created.
9. First PR adds `templates/hub/001-initial-provisioning.xml`.

---

## 7. Sign-off

The DeltaSetup repo is **scaffolded, audited, and ready for sprint-1**.
The pre-existing structure was sound; the cowork-agent's additions are
high quality and pass all eight Oracle verification gates; the cleanup
ChatGPT was sandbox-blocked on has been executed; the Category D items
are decided.

**Authoritative reading order for any future agent:**

1. `docs/README.md`
2. `docs/sharepoint-pnp-spec/SPRINT-1-KICKOFF.md`
3. This file (`ORACLE-AUDIT-2026-05-16.md`)
4. `docs/sharepoint-pnp-spec/PROMPT-PACK-FOR-AI.md`
5. The numbered chapters and ADRs in `docs/sharepoint-pnp-spec/`

— Richard 🐶, oracle of SharePoint hub-and-spoke ecosystems
