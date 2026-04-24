# Sources and credibility assessment

All primary sources below are **Tier 1 official Microsoft documentation**.

| Source | URL | Last updated on page | Why it matters | Credibility notes |
|---|---|---:|---|---|
| Cross-tenant access overview | https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview | 2025-03-28 | Default behavior, inbound/outbound policy model, automatic redemption, app allowlist caveats | Core Entra source for policy behavior |
| Manage cross-tenant access settings for B2B collaboration | https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration | 2026-02-06 | Exact admin scoping model for users/groups/apps and required object IDs | Strong operational guidance |
| What is cross-tenant synchronization? | https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview | 2026-03-19 | Explains sync creates B2B collaboration users, licensing, limits, M365 implications | Primary source for synced-object reality |
| B2B direct connect overview | https://learn.microsoft.com/en-us/entra/external-id/b2b-direct-connect-overview | 2025-07-07 | Defines B2B Direct Connect scope and no-guest-object model | Primary source for shared-channel-only pattern |
| Shared channels in Microsoft Teams | https://learn.microsoft.com/en-us/microsoftteams/shared-channels | 2026-02-20 | Shared channel behavior, separate SharePoint site, permissions, compliance | Primary Teams behavior source |
| Guest access in Microsoft Teams | https://learn.microsoft.com/en-us/microsoftteams/guest-access | 2025-03-24 | Guest invitation flow, delay, basic support/troubleshooting signals | Important for full-team guest reality |
| B2B collaboration invitation redemption | https://learn.microsoft.com/en-us/entra/external-id/redemption-experience | 2026-04-21 | Consent flow, redemption states, direct-link behavior, configurable redemption | Primary first-run UX source |
| B2B guest user properties | https://learn.microsoft.com/en-us/entra/external-id/user-properties | 2026-03-20 | PendingAcceptance, invitation state, object properties, guest vs external member | Primary object-lifecycle source |
| External sharing in SharePoint and OneDrive | https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview | 2025-12-22 | SharePoint B2B integration behavior and external sharing model | Primary SharePoint sharing source |

## Notes on evidence quality

- The Microsoft Learn pages above are authoritative for **feature scope, admin settings, and documented limitations**.
- Microsoft Learn does **not** fully document every real-world sign-in failure code and edge-case combination. Where this research discusses **AADSTS500213-style pre-redemption/dynamic-group failures**, that point is marked as an **operational inference** rather than a direct Learn quote.
