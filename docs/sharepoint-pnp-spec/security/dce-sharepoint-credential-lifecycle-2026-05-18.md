# dce-sharepoint deploy credential lifecycle — 2026-05-18

**Prepared by:** `code-puppy-73a4b6`  
**App registration:** `dce-sharepoint-deploy`  
**Client/App ID:** `4c56417b-46f6-43f4-acfe-8c3e40955232`  
**Tenant:** DCE (`ce62e17d-2feb-4e67-a115-8ea4af68da30`)

## Current credential metadata

Read-only Graph evidence collected 2026-05-18:

| Field | Value |
|---|---|
| Application object ID | `61364d7f-6007-4e22-9c06-bd345382f718` |
| Service principal ID | `c10408a3-bf93-4e71-9a84-05119bda12d3` |
| Service principal enabled | `true` |
| Password credentials | none |
| Key credential type | `AsymmetricX509Cert` |
| Key display name | `CN=dce-sharepoint-deploy-cert` |
| Key ID | `c4660d2e-a48f-4f2a-9015-25881d3299b2` |
| Key start | `2026-05-18T03:22:13Z` |
| Key expiry | `2027-05-18T03:22:11Z` |
| Explicit app owners | none returned by Graph owner query |

Local development files observed in `dce-sharepoint/` are ignored by git:

```text
cert.crt
cert.key
cert.pfx
cert.pfx.password
```

They are useful for bootstrap/dev execution, but they are not acceptable as the
long-term production launch credential model.

## Decision

Production launch-mode must not depend on an unmanaged 1-year local PFX.

Before any production launch-mode workflow is activated, one of these must be
true:

1. **Preferred:** GitHub OIDC / federated identity path exists and launch/deploy
   jobs exchange short-lived tokens without storing a long-lived private key.
2. **Acceptable interim:** certificate-based app-only auth remains, but with a
   documented 90-day rotation ceremony, app ownership, expiry alerting, and
   unusual-use monitoring.

## Minimum interim controls

If the certificate model remains for sprint-1/sprint-2:

1. Add at least two explicit app owners in DCE.
2. Rotate the certificate every 90 days or record a named risk exception.
3. Store the PFX only as a GitHub Actions secret / approved secret manager value,
   never in tracked repo content.
4. Remove local PFX files after the deployment path no longer needs them.
5. Record every rotation in bd with:
   - old key ID,
   - new key ID,
   - start/expiry timestamps,
   - operator,
   - validation run URL,
   - revocation timestamp for the old key.
6. Add an expiry check that fails CI or opens an issue at ≤30 days remaining.
7. Add a periodic read-only app credential inventory check.
8. Alert on app-only activity outside expected windows once logging/monitoring is
   wired:
   - outside 08:00–20:00 Central,
   - outside GitHub-hosted runner or approved admin IP ranges,
   - write operations to `/groups`, `/teams`, SharePoint site permissions, or
     launch notification surfaces.

## Current risk statement

Current posture is acceptable for controlled DEV/scaffold work, but not for
production launch-mode. The key has a 1-year lifetime and no explicit owners were
returned by the app owner query. That violates the ADR-011 cert-lifecycle
hardening target until follow-up controls land.

## Follow-up work

- Add explicit app owners after Tyler confirms delegates.
- Implement a credential expiry inventory/check in `dce-sharepoint` CI or a
  scheduled operator script.
- Implement OIDC/federated identity path (`DeltaSetup-du9`) or document a
  certificate exception.
- Define and test the 90-day rotation ceremony.
