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
| Explicit app owners | Initially none returned by Graph owner query; Tyler Granlund - Admin added by TUI approval on 2026-05-18; Dustin Boyd - Admin added by Tyler request on 2026-05-18. |

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

Before any production launch-mode workflow is activated, GitHub OIDC / federated
identity must exist so launch/deploy jobs exchange short-lived tokens without
storing a long-lived private key.

Tyler selected **Require OIDC first** via questionnaire TUI on 2026-05-18.
Certificate-based app-only auth remains acceptable only for controlled DEV and
scaffold work unless a later named risk decision supersedes this posture.

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
production launch-mode. The key has a 1-year lifetime and two explicit app
owners now exist: Tyler Granlund - Admin and Dustin Boyd - Admin. Production
launch-mode requires OIDC/federated identity first, plus monitoring controls for
any remaining certificate-based DEV/scaffold use.

## Follow-up work

- Activate the credential monitoring workflow template after secrets approval:
  `ci-cd/workflows/credential-monitoring.yml`.
- Implement OIDC/federated identity path (`DeltaSetup-du9`) before production
  launch-mode.
- Define the first 90-day rotation target date or record a named risk acceptance
  for any continued certificate-based DEV/scaffold use.

## 2026-05-18 update

Read-only live verification re-run by `code-puppy-73a4b6`:

- Owners: Tyler Granlund - Admin; Dustin Boyd - Admin.
- Password credentials: zero.
- Active key: `c4660d2e-a48f-4f2a-9015-25881d3299b2`.
- Expiry: `2027-05-18T03:22:11Z` (~365 days remaining).
- `check-app-credential-expiry.ps1 -WarnWithinDays 90` passed.
- Added `docs/certificate-exception-2026-05-18.md` and inactive monitoring
  template `ci-cd/workflows/credential-monitoring.yml` in `dce-sharepoint`.
