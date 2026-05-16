# Cross-Tenant Exchange Online from a Guest Global Admin

**Problem we solved 2026-05-15:** Connecting Exchange Online to a tenant
where your account is a Global Admin **as a cross-tenant B2B user** (not a
native member of that tenant).

## TL;DR

Use **`-DelegatedOrganization`** — NOT `-Organization`.

```powershell
Connect-ExchangeOnline `
    -DelegatedOrganization 'deltacrown.onmicrosoft.com' `
    -Device `
    -ShowBanner:$false
```

Sign in with your **home-tenant credentials** (e.g.
`tyler.granlund-admin@httbrands.com`), not the `_httbrands.com#EXT#` form.
EXO will detect your cross-tenant Global Admin grant and route the session
to the target tenant.

## Why the other flags don't work

| Flag | Behavior | Why it fails for cross-tenant GA |
|---|---|---|
| (none) | Auth to your home tenant. | Lands in HTT, not the target tenant. |
| `-Organization deltacrown.onmicrosoft.com` | Auth to your home tenant. | Silently ignored if you don't have a *native* account in the target tenant; lands in HTT anyway. |
| `-UserPrincipalName <DCE-guest-UPN>` `-Organization deltacrown...` | Errors `Admin account chosen for authentication is different from the one provided`. | The `#EXT#` UPN is a directory representation, not a sign-in identity. You can't sign in *as* that UPN. |
| `-DelegatedOrganization deltacrown.onmicrosoft.com` | Routes session to target tenant using your home-tenant identity, validated against your cross-tenant admin role. | ✓ Works. |

## Diagnostic

After connecting, always confirm tenant landing:

```powershell
(Get-OrganizationConfig).Identity
# Expect: deltacrown.onmicrosoft.com
# NOT:    httbrands.onmicrosoft.com  (would mean you connected to home)
```

If the wrong tenant comes back, disconnect and retry with
`-DelegatedOrganization`.

## Where this matters

Any time we need to write Exchange-only properties on a target tenant
where Graph won't suffice:

- M365 group `EmailAddresses` (proxyAddresses for Unified groups)
- Mailbox conversion (`Set-Mailbox -Type Shared`)
- Distribution list membership / send restrictions
- Transport rules
- Mail flow diagnostics (`Get-MessageTrace`)

## Reference

- Microsoft docs: <https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell>
- Discovered while adding `OwnerConnection@deltacrown.com` alias to the
  Crown Connection M365 group (`DeltaSetup-yz2`, 2026-05-15).
