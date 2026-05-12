# Delta Crown Exchange Inventory Summary

## Audit status

Completed a read-only Exchange Online inventory for the Delta Crown tenant.

Tenant/domain:

```text
deltacrown.com
```

Method:

```powershell
pwsh -NoProfile -File phase4-migration/scripts/inventory-delta-crown-exchange.ps1 \
  -Organization deltacrown.com \
  -UserPrincipalName tyler.granlund-admin@httbrands.com \
  -UseDelegatedOrganization
```

Authentication:

- ExchangeOnlineManagement PowerShell module
- delegated Exchange Online organization connection
- read-only `Get-*` cmdlets only

Raw local outputs:

```text
.local/reports/tenant-inventory/exchange/exchange-accepted-domains.csv
.local/reports/tenant-inventory/exchange/exchange-mailboxes.csv
.local/reports/tenant-inventory/exchange/exchange-recipients.csv
.local/reports/tenant-inventory/exchange/exchange-distribution-groups.csv
.local/reports/tenant-inventory/exchange/exchange-distribution-group-members.csv
.local/reports/tenant-inventory/exchange/exchange-dynamic-distribution-groups.csv
.local/reports/tenant-inventory/exchange/exchange-transport-rules.csv
.local/reports/tenant-inventory/exchange/exchange-inbound-connectors.csv
.local/reports/tenant-inventory/exchange/exchange-outbound-connectors.csv
.local/reports/tenant-inventory/exchange/exchange-shared-mailbox-permissions.csv
.local/reports/tenant-inventory/exchange/exchange-shared-recipient-permissions.csv
.local/reports/tenant-inventory/exchange/exchange-shared-mailbox-auto-replies.csv
.local/reports/tenant-inventory/exchange/exchange-summary.json
```

Raw outputs are local-only because they contain recipient addresses, aliases, mailbox permissions, and role-style delegation details.

No Exchange objects, mailboxes, permissions, transport rules, connectors, or tenant settings were changed.

## Safety note: delegated organization required

A first attempted Exchange connection using `-Organization deltacrown.com` returned an HTT Brands Exchange context. Partial raw output from that run was deleted immediately.

The script now fails closed unless accepted domains include `deltacrown.com`, and the successful inventory used `-UseDelegatedOrganization`.

This guardrail exists because cross-tenant Exchange context mistakes are extremely easy to make and deeply annoying. Ask me how I know. Actually don't, it's in the shell history.

## Totals

| Area | Count |
|---|---:|
| Accepted domains | 2 |
| Mailboxes | 10 |
| User mailboxes | 6 |
| Shared mailboxes | 3 |
| Discovery mailboxes | 1 |
| Recipients | 93 |
| Distribution groups | 0 |
| Dynamic distribution groups | 3 live; 4 targeted after script rerun |
| Transport rules | 0 |
| Inbound connectors | 0 |
| Outbound connectors | 0 |
| Shared mailbox Full Access permission rows | 9 |
| Shared mailbox Send As / recipient permission rows | 6 |

## Accepted domains

| Domain | Type | Default |
|---|---|---|
| `deltacrown.com` | Authoritative | Yes |
| `deltacrown.onmicrosoft.com` | Authoritative | No |

## Shared mailboxes

The three expected shared mailboxes exist and are shared mailboxes:

| Mailbox | Present | Type | Hidden from address lists | Auto-reply |
|---|---|---|---|---|
| `operations@deltacrown.com` | Yes | SharedMailbox | No | Disabled |
| `bookings@deltacrown.com` | Yes | SharedMailbox | No | Enabled |
| `info@deltacrown.com` | Yes | SharedMailbox | No | Enabled |

Permission rows were captured locally only:

- Full Access-style mailbox permission rows: 9
- Send As-style recipient permission rows: 6

The committed summary intentionally does not list trustees/users.

## Dynamic distribution groups

| Group | Address | Recipient filter summary |
|---|---|---|
| DCE All Staff | `allstaff@deltacrown.com` | User mailboxes where `Company` equals `Delta Crown Extensions` |
| DCE Managers | `managers@deltacrown.com` | User mailboxes where `Company` equals `Delta Crown Extensions` and `Title` starts with `Manager` |
| DCE Stylists | `stylists@deltacrown.com` | User mailboxes where `Company` equals `Delta Crown Extensions` and `Title` starts with `Stylist` |
| DCE Franchise Owners | `franchise_owners@deltacrown.com` | **Pending script rerun**: user mailboxes where `Company` equals `Delta Crown Extensions`, `Department` equals `Franchisee`, and `Title` equals `Owner` |

These filters depend on the same metadata completeness issues found in `docs/delta-crown-identity-inventory-summary.md`. The inventory captured 3 live DDGs before the `franchise_owners@deltacrown.com` target was added to `phase3-week2/scripts/5.1-Exchange-Setup.ps1`; rerun Exchange setup to create the fourth group.

Important difference from Entra dynamic groups:

- Exchange dynamic distribution group filters use Exchange recipient attributes.
- Entra dynamic security groups use Entra user attributes.
- The intended model is similar, but the actual evaluators and syntax are separate.

## Distribution groups, mail flow rules, and connectors

| Resource type | Finding |
|---|---|
| Static distribution groups | None found |
| Transport/mail flow rules | None found |
| Inbound connectors | None found |
| Outbound connectors | None found |

## Readiness implications

1. Exchange Online is active for the Delta Crown tenant.
2. The expected shared mailboxes exist.
3. `bookings@` and `info@` auto-replies are enabled; `operations@` is disabled.
4. Shared mailbox permission rows exist, but trustee details are local-only and should be reviewed before public/team-showcase claims.
5. Dynamic distribution groups exist, but their usefulness depends on user metadata quality.
6. No mail flow rules or connectors were found, so there is no obvious custom routing layer in this inventory.

## Follow-up needed

| Follow-up | Reason |
|---|---|
| Review shared mailbox trustees locally before showcase claims. | Raw permission rows are intentionally not committed. |
| Re-check DDG membership after identity metadata cleanup. | `companyName` and title metadata gaps can cause incomplete recipient sets. |
| Confirm auto-reply text with business owner. | This inventory captured state, not content review or copy approval. |
| Include Exchange findings in consolidated tenant inventory. | Required for `DeltaSetup-137`. |

## Safety notes

Do not perform any of these from this inventory alone:

- change mailbox permissions;
- change Send As trustees;
- create or remove mailboxes;
- edit auto-replies;
- change dynamic distribution group filters;
- add mail flow rules or connectors;
- make public readiness claims about who can send as which mailbox without reviewing local raw permission evidence.

This inventory is evidence. Evidence is not a permission slip with a fake mustache.
