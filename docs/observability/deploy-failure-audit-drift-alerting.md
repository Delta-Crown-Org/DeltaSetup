# Deploy failure and audit-drift alerting

**Tracking bead:** `DeltaSetup-6wf`  
**Status:** Draft — not approval evidence  
**Goal:** no silent failures within a 24-hour SLO

## Problem

DeltaSetup currently relies on humans noticing failed deploys, failed audits, or tenant drift. That is adorable in the same way a raccoon in the server room is adorable.

The required control is simple:

- GitHub Actions deploy failure alerts Tyler.
- Audit-drift non-zero alerts Tyler + Jenna.
- Optional Teams webhook can be added only after approval.
- A second, out-of-tenant alert channel must exist for critical identity/sync drift so the monitor does not depend only on the tenant being monitored.

## Alert classes

### Class 1 — Deploy failure

Trigger:

- GitHub Actions workflow concludes `failure`, `timed_out`, or `cancelled` for deployment/release workflows.

Initial recipients:

- Tyler Granlund

Evidence to retain:

- workflow name;
- run URL;
- commit SHA;
- branch;
- actor;
- failed job/step if available;
- timestamp.

SLO:

- Alert fires within 5 minutes of failure.
- Human-visible signal exists within 24 hours.

### Class 2 — Audit drift

Trigger:

- any scheduled/read-only audit exits non-zero;
- any audit emits a non-empty drift report;
- any critical identity/sync control differs from baseline.

Initial recipients:

- Tyler Granlund
- Jenna Bowden, after recipient approval/confirmation

Evidence to retain:

- audit name;
- run URL;
- drift summary;
- full raw output as private/local artifact or GitHub artifact, depending on sensitivity;
- timestamp.

### Class 3 — DCE SyncFabric bridge drift

Critical controls after the 2026-05-18 incident:

- the HTT source admin account remains directly assigned to the HTT-to-DCE sync application;
- the DCE target admin object exists;
- the DCE target admin object has `deletedDateTime == null`;
- the DCE target admin object is `accountEnabled == true`;
- the DCE target admin object remains a member of `Global Administrator`;
- the HTT-to-DCE synchronization job is not quarantined;
- a DCE-native, cloud-only break-glass Global Administrator exists outside HTT cross-tenant sync.

Concrete IDs/UPNs belong in private environment variables or `.local/` evidence, not in this public contract.

Alert if any control fails.

## Proposed implementation

### Phase 1 — documentation + dry-run only

- Add this alerting contract.
- Add a dry-run alert script that prints/saves the intended notification payload without sending.
- Add a sample GitHub Actions workflow using dry-run only.

### Phase 2 — production alerting after recipient approval

- Enable email delivery using approved GitHub/SMTP/O365 mechanism.
- Add a second out-of-tenant destination for Class 3 identity/sync drift, such as a separate GitHub issue destination, an external monitored mailbox, PagerDuty/Opsgenie, or another approved channel outside the affected tenant.
- Optionally add Teams webhook if approved.
- Run one controlled failure test.

## Dry-run payload shape

```json
{
  "severity": "high",
  "class": "audit-drift",
  "title": "DCE SyncFabric bridge drift detected",
  "summary": "Direct assignment missing for the HTT admin source account",
  "runUrl": "https://github.com/.../actions/runs/...",
  "commit": "<sha>",
  "branch": "gh-pages",
  "timestampUtc": "2026-05-19T00:00:00Z",
  "recommendedAction": "Restore direct assignment or pause the HTT-to-DCE sync job before next scheduled sync."
}
```

## Guardrails

- Do not email broad distribution lists during tests.
- Do not commit raw audit exports with user data.
- Do not rely on Teams-only alerts; email or issue-based signal must exist.
- Do not make the alerting workflow depend on the same deployment path it is meant to monitor.

## Acceptance mapping

`DeltaSetup-6wf` acceptance says:

> kill the cron job in CI and verify alert fires within 5 min.

Planned validation:

1. Create a scheduled dry-run audit workflow.
2. Add a controlled `workflow_dispatch` input such as `force_failure=true`.
3. Run the workflow manually with failure enabled.
4. Verify alert payload is generated immediately.
5. After recipient approval, enable real send and repeat once.
6. Before any `DeltaSetup-b0f` or `DeltaSetup-3vu` production promotion, make Class 3 bridge drift alerting live rather than dry-run.
7. Prove Class 3 alerting by temporarily forcing a synthetic failed check, not by removing real access.

## Open decisions

- Which email mechanism should production alerts use?
- What is the approved out-of-tenant channel for Class 3 critical identity/sync drift?
- Is Jenna the confirmed audit-drift recipient?
- Should Teams webhook be used, and if so which channel?
- What retention policy applies to GitHub artifacts containing drift summaries?
