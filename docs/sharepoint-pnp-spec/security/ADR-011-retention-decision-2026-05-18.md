# ADR-011 audit + launch evidence retention decision — 2026-05-18

**Prepared by:** `code-puppy-73a4b6`  
**Tenant:** Delta Crown Extensions / DCE (`ce62e17d-2feb-4e67-a115-8ea4af68da30`)  
**Scope:** ADR-011 evidence-retention assumptions for quiet provisioning and any
future launch-mode workflow.

## Evidence collected

### DCE Microsoft 365 subscribed SKUs

Read-only Graph query on 2026-05-18:

```bash
az login --tenant ce62e17d-2feb-4e67-a115-8ea4af68da30 --allow-no-subscriptions
az rest --method GET --url "https://graph.microsoft.com/v1.0/subscribedSkus"
```

Observed enabled SKUs:

| SKU | Status | Consumed | Prepaid |
|---|---:|---:|---:|
| `O365_BUSINESS_ESSENTIALS` | Enabled | 6 | 6 |
| `AAD_PREMIUM_P2` | Enabled | 0 | 1 |

No E5 / Purview Audit Premium SKU was visible in `subscribedSkus` at the time
of review.

### GitHub plan/repo evidence

Read-only GitHub CLI query on 2026-05-18:

```bash
gh repo view Delta-Crown-Org/dce-sharepoint --json nameWithOwner,isPrivate,visibility,viewerPermission
gh api orgs/Delta-Crown-Org --jq '{login:.login, plan:.plan}'
```

Observed:

| Field | Value |
|---|---|
| Repo | `Delta-Crown-Org/dce-sharepoint` |
| Visibility | Private |
| Current operator permission | Admin |
| Org plan | `free` |

GitHub environment required-reviewer protection was separately attempted and
failed with HTTP 422 because the current plan does not support that protection
rule. Therefore, GitHub-native environment approval and extended artifact
retention must not be treated as guaranteed launch controls under the current
plan.

## Decision

For ADR-011, DCE will **not** claim 365+ day evidence retention from GitHub
Actions artifacts or Microsoft 365 audit logs under the current licensing/plan.

Until the tenant and GitHub plan are upgraded or explicit retention settings are
verified, launch evidence retention is capped conservatively as follows:

| Evidence | Conservative source of truth | Current decision |
|---|---|---|
| GitHub Actions artifacts (`provisioning-mode.log`, launch manifest, reports) | GitHub Actions artifact retention on current free/private setup | Treat as short-term operational evidence only. Do not rely on it for 365+ day audit. |
| Unified Audit Log / Purview audit | DCE SKU lacks visible E5/Purview Audit Premium in `subscribedSkus` | Treat as standard-retention only until Purview admin center confirms otherwise. |
| Message trace / historical search | Exchange/Purview tenant capability and policy dependent | Use for near-term incident review; do not use as sole 365+ day record. |
| Launch approval evidence | Currently no enforceable GitHub environment reviewers | Must be mirrored outside GitHub before any launch-mode run. |
| Recipient manifests + SHA-256 | Future launch workflow artifact | Must be mirrored outside GitHub before any launch-mode run. |

## Required launch-mode control

Before any production launch-mode workflow sends mail or touches real users, the
workflow must write an immutable or at least admin-controlled off-platform copy
of these artifacts:

1. `provisioning-mode.log`
2. workflow run URL and commit SHA
3. named approvers and approval timestamp
4. recipient manifest
5. SHA-256 of recipient manifest
6. final rendered message body/template version
7. send result summary
8. rollback/corrective-message instructions if applicable

Acceptable near-term mirrors:

- restricted SharePoint document library in the DCE tenant with versioning on,
- Azure Blob Storage container with immutable retention policy, or
- a security-owned ticket/change record system attachment.

Preferred future state:

- Azure Blob immutable storage for launch artifacts,
- GitHub plan/support level that enables required-reviewer environments,
- explicit Purview audit retention review documented by a tenant security owner.

## ADR-011 impact

The ADR-011 Repudiation residual risk cannot be rated “Very low” under the
current evidence posture. It remains **Low/Medium** until off-platform retention
and an enforceable approval gate exist.

## Follow-up

This decision closes the retention fact-finding/control-decision slice, but it
does **not** unblock launch-mode. Launch-mode remains blocked on:

- `DeltaSetup-0pt` — launch approval gate fallback,
- `DeltaSetup-tn4` — credential lifecycle hardening,
- `DeltaSetup-v0i` — dedicated security-auditor or Tier-1 human review,
- empirical canaries and quarterly digest controls.
