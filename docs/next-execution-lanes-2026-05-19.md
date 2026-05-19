# DeltaSetup next execution lanes — 2026-05-19

**Status:** Draft — not approval evidence  
**Source of truth:** `bd` / beads database  
**Coordinator:** `code-puppy-73a4b6`  
**Mode:** parallel, approval-safe execution

## Current stabilized prerequisite

DCE SyncFabric admin deletion incident is stabilized:

- the HTT admin source account is directly assigned to the HTT-to-DCE sync application.
- the DCE target admin object is active.
- the DCE target admin object remains `Global Administrator`.
- the HTT-to-DCE sync application is active again.

Do **not** remove the direct app assignment or refactor DCE sync scope during this work wave.

Bridge survivability requirements:

- Second owner for DCE sync ownership added: Dustin Boyd - Admin, 2026-05-19.
- Maintain a DCE-native, cloud-only break-glass Global Administrator that is not sourced from HTT cross-tenant sync.
- Keep the specific break-glass account details outside public docs.

## Execution rules

1. `bd` wins. If a bead says blocked, approval-gated, or deferred, treat it that way.
2. No owner-facing promotions without explicit owner approval captured in `bd`.
3. No apology/customer email send without business approval captured in `bd`.
4. No production Teams/channel mutation while Teams read-context remains unresolved.
5. Raw tenant exports stay in `.local/reports/`; commit redacted summaries only.
6. Public page changes must pass the three public-page quality gates before push.

## Lane A — P0 incident package

**Issue:** `DeltaSetup-377`  
**Status:** blocked by `DeltaSetup-17i`, but still highest operational risk.

Approval-safe work:

- Gather message trace requirements and evidence schema.
- Draft redacted incident retro.
- Draft apology/mail-merge package only.

Human gate:

- Do not send apology mail until approved.
- Do not bypass the launch-mode workflow dependency.

## Lane B — Friday hub basics handoff

**Issue:** `DeltaSetup-2dq`

Approval-safe work:

- Produce Tyler/Jamie handoff explaining current SharePoint hub state.
- Clarify that DCE tenant already has the live hub/spoke architecture.
- Clarify that HTT has a separate `Delta Crown Operations` Teams-provisioned site requiring disposition.
- Identify decisions still needed before new provisioning.

Human gate:

- Do not provision a new HTT-side hub until target tenant/path decision is captured.
- Do not promote DCE Hub/Crown Connection production content until owner approval.

## Lane C — DCE sync ownership resilience

**Issue:** `DeltaSetup-0gv`

Approval-safe work:

- Verify current owners of the DCE sync ownership group.
- Confirm break-glass admin existence through a private/local evidence record.

Completed:

- Tyler confirmed Dustin Boyd admin as second owner.
- Dustin Boyd admin was restored in DCE because his target object was soft-deleted by the same SyncFabric incident.
- Dustin Boyd admin was directly assigned to the HTT-to-DCE sync application before owner assignment to prevent immediate re-deletion.
- DCE sync ownership group now has Tyler admin and Dustin admin as owners.

Guardrail:

- No group members, dynamic rules, or production content were changed. The only app assignment change was Dustin's direct HTT-to-DCE sync entitlement bridge, needed to make the restored owner durable.

## Lane D — Observability

**Issue:** `DeltaSetup-6wf`

Approval-safe work:

- Design alert contract for GitHub Actions failure and audit drift.
- Scaffold a dry-run alert workflow/script if practical.
- Include DCE SyncFabric bridge checks in the audit-drift control list.
- Make Class 3 bridge drift alerting live before any Lane I production promotion.

Human gate:

- Confirm real alert recipients before sending production alert emails or Teams webhooks.

## Lane E — Teams inventory blocker

**Issue:** `DeltaSetup-4ay`

Approval-safe work:

- Preserve current blocker documentation.
- Run read-only Graph/Teams probes if a licensed Teams-readable context is available.

Human gate:

- Need licensed Teams-readable DCE context or approved app-only Graph path.

Guardrail:

- No Teams/channel creation, rename, deletion, moderation PATCH, tab/app edits, or membership changes.

## Lane F — Cross-brand owner-site audit

**Issue:** `DeltaSetup-rod`

Approval-safe work:

- Start DCE + HTT audit with currently available access.
- Mark TLL/FMNC/BCC as auth-gated if not available.
- Produce comparison matrix and recommendation placeholders.

Human gate:

- Need multi-tenant auth for full completion.
- Owner approval required before cleanup actions.

## Lane G — Notification canaries

**Issues:** `DeltaSetup-j3c`, `DeltaSetup-33c`

Approval-safe work:

- Prepare canary runbooks and evidence paths.
- Keep test isolated to canary accounts/mailboxes.

Human gate:

- Do not execute user-facing or tenant-wide canaries without explicit approval.
- Do not PATCH Teams moderation settings in production.

## Lane H — MTO evaluation

**Issue:** `DeltaSetup-a3d`

Approval-safe work:

- Draft ADR-012 decision matrix for join/defer/never.
- Include notification-quietness factor from ADR-011.
- Include impact of direct SyncFabric bridge and admin-account entitlement.

Human gate:

- Evaluation only. Do not join MTO or alter cross-tenant configuration.

## Lane I — Promotion readiness only

**Issues:** `DeltaSetup-b0f`, `DeltaSetup-3vu`

Approval-safe work:

- Prepare promotion checklists, validation steps, rollback plans, and signoff blocks.

Human gate:

- Do not promote CrownConnection-dev or DCE Hub production content without explicit owner approval.

## Immediate tactical order

1. Finish Friday hub basics handoff (`DeltaSetup-2dq`).
2. Draft observability contract (`DeltaSetup-6wf`).
3. Draft MTO ADR (`DeltaSetup-a3d`).
4. Verify DCE sync ownership state (`DeltaSetup-0gv`) read-only.
5. Make Class 3 bridge drift alerting live before any production promotion.
6. Prepare promotion readiness/checklist artifacts without executing promotions.
7. Return to P0 incident package when `DeltaSetup-17i` launch-mode dependency is ready or owner asks for offline draft package.
