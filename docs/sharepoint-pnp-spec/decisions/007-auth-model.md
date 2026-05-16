# ADR-007 — Authentication: cert-based app-only auth for CI

**Status:** Accepted
**Date:** 2026-05-15
**Implements:** `06-tooling-pnp.md`, `09-deployment.md`

## Context

CI needs to authenticate to SharePoint without interactive auth.
Options range from secrets to certs to managed identity.

## Decision

**Cert-based app-only authentication** via an Entra app registration
named `dce-sharepoint-deploy`.

Cert lives as a base64-encoded PFX in GitHub repo secrets. Public
cert is uploaded to the Entra app registration. Rotated annually.

## Alternatives considered

### A. Client secret

- Pro: simplest to configure.
- Con: secret in repo secrets is a single string — easy to compromise
  via screen-share or accidental log emission.
- Rejected.

### B. Federated credentials (OIDC) from GitHub Actions

- Pro: no long-lived secrets to manage.
- Con: requires more Entra app config + understanding of OIDC trust;
  not all PnP cmdlets accept OIDC tokens directly yet (as of mid-2025).
  Worth revisiting in 6 months.
- Deferred.

### C. Managed identity

- Pro: ideal long-term.
- Con: requires Azure-hosted runner (Azure DevOps pipelines or
  self-hosted GitHub runner on an Azure VM with MI).
- Deferred.

## Consequences

- One Entra app `dce-sharepoint-deploy` in DCE tenant.
- Cert lives in GitHub secrets; public cert in the Entra app.
- Annual rotation needed (calendar reminder; GitHub workflow warning at
  30-day mark).
- Tyler grants admin consent once at app creation.

## Permissions granted

See `09-deployment.md` § "Step 1". Summary:

- Graph: `Sites.ReadWrite.All`, `User.Read.All`, `Group.Read.All`,
  `Directory.Read.All` (all Application).
- SharePoint: `Sites.FullControl.All` (Application).

## Open follow-ups

- Federated credentials are the right long-term move. Re-evaluate in
  Q3 2026 once PnP.PowerShell 4.x supports OIDC natively.
