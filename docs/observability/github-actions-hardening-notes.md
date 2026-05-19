# GitHub Actions hardening notes

**Status:** Draft  
**Tracking bead:** `DeltaSetup-iqp`  
**Scope:** observability workflow hardening follow-up

## Current dry-run workflow

Workflow:

```text
.github/workflows/dce-syncfabric-bridge-drift-dry-run.yml
```

Current posture:

- dry-run only;
- no tenant mutation;
- no secrets;
- `contents: read` only;
- weekly schedule plus manual dispatch;
- artifact upload retains dry-run JSON evidence;
- explicit concurrency group added.

## Missing-artifact behavior

The upload step uses:

```yaml
if-no-files-found: error
```

This is intentional.

If `tools/check-dce-syncfabric-bridge.py` crashes before writing JSON, the artifact upload should fail loudly instead of silently passing with no evidence. Operators should treat missing artifact as a workflow/tooling failure, not as a clean bridge-drift result.

## Remaining hardening

### Pin external GitHub Actions by immutable SHA

Current workflow uses major-version pins:

```yaml
uses: actions/checkout@v4
uses: actions/upload-artifact@v4
```

This is acceptable for dry-run scaffolding with `contents: read`, no secrets, and no tenant mutation, but it is not the desired final posture for production governance workflows.

Before enabling live alerting or secret-backed checks, pin external actions to immutable commit SHAs and document the update cadence.

### Protect workflow changes

CODEOWNERS already includes `.github/workflows/`, but the security team placeholder must be backed by a real GitHub team/user with write access before two-reviewer enforcement is real.

## Acceptance status

| Control | Status |
|---|---|
| Workflow parses | Done |
| Dry-run only | Done |
| No secrets | Done |
| Least-privilege permissions | Done |
| Explicit concurrency | Done |
| Missing-artifact behavior documented | Done |
| SHA pinning | Remaining |
| Real two-reviewer CODEOWNERS enforcement | Remaining |
