# Sprint-1 kickoff — SharePoint hub-and-spoke

**Date:** 2026-05-16
**Spec pack:** `docs/sharepoint-pnp-spec/`
**Tier-B mockup:** `dce-mockup/` (in this repo)
**Future SharePoint code repo:** `Delta-Crown-Org/dce-sharepoint` (not yet created)

This is the one-page entry point for anyone resuming the SharePoint
initiative. It links the artifacts in execution order.

---

## 1. Read these in order

1. **`docs/sharepoint-pnp-spec/README.md`** — what the spec pack is.
2. **`docs/sharepoint-pnp-spec/PROMPT-PACK-FOR-AI.md`** — orientation for AI agents.
3. **`docs/sharepoint-pnp-spec/EVALUATION-RUBRIC.md`** — how outputs are graded.
4. **`docs/sharepoint-pnp-spec/00-context.md`** — non-negotiable tenant facts.
5. **`docs/sharepoint-pnp-spec/01-architecture.md`** through **`12-implementation-plan.md`** — the spec itself.
6. **`docs/sharepoint-pnp-spec/decisions/`** — 9 ADRs (001–007 original; 008–009 added 2026-05-16).
7. **`docs/sharepoint-pnp-spec/reference/dce-tokens.json`** — canonical design tokens.
8. **`docs/sharepoint-pnp-spec/reference/existing-assets-inventory.md`** — reuse-first map.

## 2. See the mockup

```bash
cd dce-mockup
python3 -m http.server 8080
# open http://localhost:8080/
```

Read in this order:
1. `dce-mockup/README.md` — how to use the role-switcher.
2. `dce-mockup/index.html` (and the other two pages) in your browser.
3. `dce-mockup/RATIONALE.md` — rubric self-score + spec defects identified.
4. `dce-mockup/RESEARCH-DELTAS.md` — corrections from the ADR-006 final review (2026-05-16).
5. `dce-mockup/spfx-skeleton/README.md` — how the mockup maps 1:1 to SPFx web parts.
6. `dce-mockup/ci-cd/README.md` — the GitHub Actions + bootstrap that copies into the new repo.

## 3. Compare alternative views

- **Perplexity blueprint** — Tyler's earlier outline (referenced inline in `dce-mockup/RATIONALE.md` § 5).
- **ChatGPT 5.5 Pro HTT guide** — at `docs/sharepoint-research/chatgpt-5.5-pro/htt-sharepoint-infrastructure-development-guide.md`.
- **My output** — `dce-mockup/` (Tier-B HTML + SPFx skeleton + CI/CD).

`dce-mockup/RATIONALE.md` § 5 has the head-to-head against Perplexity.
`dce-mockup/RESEARCH-DELTAS.md` § 4 has the alignment check against the
ChatGPT 5.5 Pro guide.

## 4. Sprint-1 execution checklist

- [ ] Tyler creates `Delta-Crown-Org/dce-sharepoint` repo (per ADR-006).
- [ ] Copy `dce-mockup/ci-cd/` into the new repo as the seed.
- [ ] Run `ci-cd/scripts/bootstrap.sh` (idempotent; creates Entra app + cert + secrets).
- [ ] Paste printed secrets into GitHub repo → Settings → Secrets.
- [ ] Open a PR that adds `templates/hub/001-initial-provisioning.xml`.
- [ ] PR validation runs green.
- [ ] Merge → `deploy-prod.yml` runs (gated on `prod` environment approval).
- [ ] Verify dev hub at `https://deltacrown.sharepoint.com/sites/dce-hub-dev`.
- [ ] Associate Crown Connection to the hub.
- [ ] Run the permission-audit workflow once manually; baseline = 0 drift.
- [ ] Apply Teams moderation via `ci-cd/scripts/provision-teams.ps1` (BETA endpoint per ADR-009).

## 5. Decisions still open

- **ADR-006 final** — pending Security Auditor co-sign per solutions-architect-e9372f.
- **ADR-008** — proposed; needs Tyler accept after group creation.
- **ADR-009** — proposed; will be superseded when Graph promotes moderation to v1.0.
- Whether DCE joins the Microsoft 365 MTO (currently not a member per
  `Cross-Tenant-Utility/HTT-CROSS-TENANT-IDENTITY-ANALYSIS.md` § Tenant
  Landscape). The mockup works without MTO; joining would simplify several
  edge cases.

## 6. Sprint-2 candidates (do not pull into sprint-1)

- Viva Connections Dashboard cards (per ChatGPT 5.5 Pro guide § 10.3).
- Region- and store-level group decomposition (per Perplexity blueprint).
- OIDC federated identity for the deploy app (replaces cert-auth from bootstrap.sh).
- Brand template parameterization for Bishops, Frenchies, TLL (Phase 5+).
- Remaining post-ADR-010 follow-ups from `dce-mockup/RATIONALE.md` § 3:
  - Define `DCE-HTT-Corporate-Sync` group (ADR-008 above; pending creation).
  - Monitor Heft/SPFx build behavior when the real repo is scaffolded.
  - Revisit Fluent UI only through a superseding ADR if Microsoft/SPFx guidance changes.
