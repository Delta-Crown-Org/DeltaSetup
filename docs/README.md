# DeltaSetup docs — index

This folder is the documentation hub for the Delta Crown Extensions
project. The folders below are grouped by purpose. Start with the
sharepoint-pnp-spec if you're new — it's the master reference for the
SharePoint hub-and-spoke initiative.

## Quick links

- 🎯 **[Sprint-1 kickoff](sharepoint-pnp-spec/SPRINT-1-KICKOFF.md)** — single-page entry point for resuming the initiative.
- 📋 **[Spec pack README](sharepoint-pnp-spec/README.md)** — the 26-file SharePoint hub-and-spoke spec.
- 🧪 **[Evaluation rubric](sharepoint-pnp-spec/EVALUATION-RUBRIC.md)** — how we score implementations.
- 🏗️ **[Tier-B mockup](../dce-mockup/README.md)** — interactive HTML mockup at `/dce-mockup/`.
- 🎨 **[DCE visual system](dce-visual-system.md)** — canonical palette, asset provenance, and logo/Crown Society rules.
- 🔬 **[Research deltas](../dce-mockup/RESEARCH-DELTAS.md)** — corrections from the ADR-006 final review (2026-05-16).

## Folder map

### `sharepoint-pnp-spec/`

The canonical specification for the DCE SharePoint hub-and-spoke
architecture. 16 numbered/named files + 9 ADRs + reference data +
prompt pack.

| Sub-folder | Contents |
|---|---|
| (root) | 13 numbered chapters + README + PROMPT-PACK-FOR-AI + EVALUATION-RUBRIC + SPRINT-1-KICKOFF |
| `decisions/` | 9 ADRs (001–007 original; 008–009 added 2026-05-16) |
| `prompts/` | Re-usable agent prompts (e.g., `build-the-mockup.md`) |
| `reference/` | `dce-tokens.json` + `existing-assets-inventory.md` |

### `sharepoint-research/`

Comparative research from other AI agents and consultants. Use these
as sounding boards, NOT as canonical guidance — they don't always
reflect the verified tenant state in `00-context.md`.

| Sub-folder | Contents |
|---|---|
| `chatgpt-5.5-pro/` | 1,487-line HTT-tenant-scoped infrastructure guide |

### `architecture/`

Cross-tenant and high-level architecture documents (broader than the
SharePoint-only spec pack).

| File | Purpose |
|---|---|
| `dce-sharepoint-design-roadmap.md` | Original design roadmap |
| `htt-dce-cross-tenant-sync-deep-dive.md` | Cross-tenant sync architecture |
| `NEXT-STEPS-CROSS-TENANT-2025-08.md` | Historic next-steps doc |
| `prompt-deltasetup-sharepoint-hub-friday-2026-05-15.md` | Friday session prompt |
| `decisions/` | 4 broader ADRs (hub-spoke, phase3, htthq migration, cross-tenant access) |

### `onboarding/`

Operational playbooks for joiner/mover/leaver and per-role checklists.

| File | Purpose |
|---|---|
| `crown-connection-launch-handoff-jenna-bowden.md` | Launch handoff |
| `crown-connection-team-status-update-2026-05-15.md` | Status |
| `dce-attribute-group-resource-matrix.md` | The role × group × resource matrix |
| `dce-offboarding-deprovisioning-checklist.md` | Leaver flow |
| `dce-pilot-bootstrap-notes.md` | Pilot setup |
| `dce-role-location-onboarding-model.md` | Joiner flow |
| `tyler-cross-tenant-pilot-checklist.md` | Cross-tenant pilot |

### `naming-conventions/`

| File | Purpose |
|---|---|
| `owners-connect-cross-brand.md` | Naming for cross-brand owner-connect resources |

## Loose top-level docs in `docs/`

| File | Purpose |
|---|---|
| `brand-resources-target-model.md` | Brand asset organization |
| `dce-visual-system.md` | Canonical DCE palette, asset provenance, logo usage, and Crown Society rules |
| `clientservices-to-brand-resources-transition-plan.md` | Migration plan |
| `dce-user-metadata-and-teams-state-verification.md` | Verification procedures |
| `delta-crown-compliance-inventory-summary.md` | Compliance audit |
| `delta-crown-exchange-inventory-summary.md` | Exchange Online audit |
| `delta-crown-identity-inventory-summary.md` | Identity audit |
| `delta-crown-security-apps-licenses-inventory-summary.md` | Security/license audit |
| `delta-crown-security-policy-confirmation.md` | Security policy confirmation |
| `delta-crown-sharepoint-inventory-summary.md` | SharePoint audit |
| `delta-crown-sharepoint-pnp-inventory-summary.md` | PnP inventory |
| `delta-crown-tenant-inventory-plan.md` | Tenant inventory plan |
| `delta-crown-tenant-inventory-status.md` | Tenant inventory status |
| `duplicate-delta-crown-extensions-groups-review.md` | Group dedupe |
| `friday-2026-05-15-audit-findings.md` | Friday session findings |
| `legacy-clientservices-cleanup-register.md` | Legacy cleanup |
| `master-dce-audit-findings.md` | Master audit findings |
| `master-dce-audit-runbook.md` | Master audit runbook |
| `master-dce-resource-audit-plan.md` | Resource audit plan |
| `master-dce-resource-map.md` | Resource map |
| `owner-decision-worksheet.md` | Owner decision worksheet |
| `production-launch-readiness-report.md` | Launch readiness |
| `team-showcase-readiness-checklist.md` | Showcase readiness |
| `teams-inventory-access-request.md` | Access request |
| `tenant-inventory-access-matrix.md` | Tenant access matrix |

## How to add a new doc

1. **Spec-pack scope** (binding architectural decisions, identity model,
   provisioning, CI/CD): add to `sharepoint-pnp-spec/`. New ADR if you're
   making a decision.
2. **Operational playbook** (run-once or recurring procedures): add to
   `onboarding/` if joiner/mover/leaver-related, otherwise `docs/` root.
3. **Comparative research** (output from another AI agent, consultant
   deck, vendor pitch): add to `sharepoint-research/` under a
   model-or-vendor-named subfolder (lowercase hyphenated, no spaces).
4. **Audit findings**: top-level `docs/` with the date in the filename.
