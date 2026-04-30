# Tenant Inventory Access Matrix

## Purpose

This matrix defines the read-only access needed to inventory the Delta Crown Microsoft 365 tenant before the team showcase and before any production cleanup.

The rule is simple: inventory first, change later. If we cannot explain what exists, who owns it, and who has access, we do not touch it.

## Inventory principles

- Prefer read-only commands and scopes.
- Separate user-facing names from technical/internal IDs.
- Do not rename, delete, disable, move, archive, or repermission live resources during inventory.
- Do not commit secrets, tokens, certificate private keys, or raw sensitive exports.
- Record missing permissions as blockers instead of guessing.
- Label each resource as showcase-safe, mention carefully, do not show, or cleanup candidate.

## Output model

Raw exports are local-only by default and should be written under:

```text
.local/reports/tenant-inventory/
```

Commit only reviewed/redacted summaries unless Tyler explicitly approves a raw artifact.

Primary consolidated redacted output, if approved:

```text
reports/delta-crown-tenant-inventory.csv
```

Recommended committed summary:

```text
docs/delta-crown-tenant-inventory-report.md
```

Recommended columns:

| Column | Purpose |
|---|---|
| Resource type | User, group, site, Team, mailbox, policy, app, license, etc. |
| Display name | User-facing name. |
| Technical name / ID | Object ID, URL, app ID, mail nickname, policy ID. |
| Purpose | Why this exists. |
| Owner | Business or technical owner. |
| Access model | Who gets access and how. |
| Provisioning driver | Manual, script, dynamic group, Graph, Exchange, SharePoint, etc. |
| Dependencies | Related groups, sites, apps, policies. |
| Current status | Live, pending verification, deprecated, draft, cleanup candidate. |
| Showcase status | Safe to show, mention carefully, do not show. |
| Follow-up | Remediation, owner decision, or validation needed. |

## Required modules

Install only if needed:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module PnP.PowerShell -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

Check installed modules:

```powershell
Get-Module Microsoft.Graph -ListAvailable | Select-Object Name, Version
Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version
Get-Module MicrosoftTeams -ListAvailable | Select-Object Name, Version
Get-Module ExchangeOnlineManagement -ListAvailable | Select-Object Name, Version
```

## Access matrix

| Area | Module / portal | Preferred read-only scope or role | Outputs | Blocks if missing |
|---|---|---|---|---|
| Users and metadata | Microsoft Graph | `User.Read.All`, `Directory.Read.All` | `.local/reports/tenant-inventory/users.csv` | Cannot verify metadata-driven provisioning. |
| Groups and dynamic rules | Microsoft Graph | `Group.Read.All`, `Directory.Read.All` | `.local/reports/tenant-inventory/groups.csv`, group member exports | Cannot verify AllStaff, Managers, Stylists, Marketing, Leadership. |
| SharePoint tenant/sites | PnP.PowerShell / SharePoint Admin | SharePoint admin only if required for tenant-wide site listing; otherwise site read/site collection visibility | `.local/reports/tenant-inventory/sharepoint-sites.csv` | Cannot verify sites/libraries/sharing/owners. |
| SharePoint permissions | PnP.PowerShell | Site collection admin only if required for permission visibility; otherwise least-privilege permission visibility | `.local/reports/tenant-inventory/sharepoint-permissions.csv` | Cannot validate unique permissions or sensitive access. |
| Teams and channels | MicrosoftTeams / Graph | Teams reader-capable role where available; Teams admin only during supervised read-only inventory | `.local/reports/tenant-inventory/teams.csv`, `.local/reports/tenant-inventory/team-channels.csv` | Cannot verify Operations channel state. |
| Exchange mail resources | ExchangeOnlineManagement | Exchange View-Only Recipients or View-Only Organization Management; Exchange admin only if no reader role works | `.local/reports/tenant-inventory/exchange-mail-resources.csv` | Cannot verify shared mailboxes, distribution lists, aliases. |
| Conditional Access | Microsoft Graph | `Policy.Read.All`, Conditional Access reader/security reader | `.local/reports/tenant-inventory/conditional-access.csv` | Cannot validate access policy posture. |
| DLP / Purview / labels | Purview / compliance cmdlets | Compliance Reader / Purview reader role; Compliance admin only if reader role is insufficient | `.local/reports/tenant-inventory/compliance-policies.csv` | Cannot validate data protection posture. |
| App registrations | Microsoft Graph | `Application.Read.All`, `Directory.Read.All` | `.local/reports/tenant-inventory/app-registrations.csv` | Cannot validate automation/app risk. |
| Enterprise apps | Microsoft Graph | `Application.Read.All`, `Directory.Read.All` | `.local/reports/tenant-inventory/enterprise-apps.csv` | Cannot review service principal exposure. |
| Licenses | Microsoft Graph | `Organization.Read.All`, `Directory.Read.All` | `.local/reports/tenant-inventory/licenses.csv` | Cannot validate feature/license dependencies. |
| Tenant sharing settings | PnP.PowerShell / SharePoint Admin | SharePoint admin/read tenant settings | `.local/reports/tenant-inventory/sharepoint-tenant-sharing.csv` | Cannot validate external sharing baseline. |

## OAuth consent safety check

During every auth window, inspect the signed-in tenant, account, and requested scopes/roles before running exports. Continue only if the prompt aligns with read-only inventory access. Cancel and stop if a prompt requests write-capable scopes or broad admin consent not explicitly approved for that auth window.

Do not approve prompts requesting permissions such as:

- `Directory.ReadWrite.All`
- `Group.ReadWrite.All`
- `User.ReadWrite.All`
- `Sites.ReadWrite.All`
- `Sites.FullControl.All`
- `Application.ReadWrite.All`
- `Policy.ReadWrite.*`
- Exchange, Teams, SharePoint, or Purview mutation roles for inventory-only work

Verify Graph context after login:

```powershell
Get-MgContext | Select-Object TenantId, Account, Scopes
```

For Auth Window 1, confirm the context/account is for HTT Brands source access. For Auth Window 2, confirm the context/account is for the Delta Crown tenant. If the tenant is wrong, disconnect and stop.

## Command allowlist and denylist

Allowed during inventory windows:

- `Get-*` read commands;
- `Select-Object`, `Where-Object`, `Export-Csv`, `ConvertTo-Json`;
- `Connect-*` and `Disconnect-*`;
- the approved read-only audit script.

Denied unless a separate approved change ticket exists:

- `Set-*`, `New-*`, `Remove-*`, `Add-*`, `Update-*`, `Grant-*`, `Revoke-*`, `Disable-*`, `Enable-*`;
- `Start-*Migration*`;
- Graph `POST`, `PATCH`, `PUT`, or `DELETE`;
- PnP `Set-PnP*`, `Add-PnP*`, `Remove-PnP*`, `New-PnP*`;
- Teams, Exchange, SharePoint, Entra, Purview, or Graph commands that mutate objects.

## Client data prohibition

Client records and client PII are out of Microsoft 365 scope for this readiness effort. Do not search for, open, sample, export, screenshot, or commit client records. If old demo/client-record lists appear during inventory, classify them as legacy cleanup artifacts and move on.

## Auth windows

### Auth Window 1: Master DCE source audit

Purpose:

- Run only the HTTHQ Master DCE audit.

Allowed:

- `phase4-migration/scripts/audit-master-dce.ps1`
- read-only folder and permission inventory

Prohibited:

- file copy/move/delete;
- permission changes;
- site/list/library creation;
- shortcut creation.

### Auth Window 2: Delta Crown tenant inventory

Purpose:

- Run read-only inventory commands across Microsoft 365 workloads.

Allowed:

- Graph read inventory;
- SharePoint site/list/permission inventory;
- Teams/channel inventory;
- Exchange recipient/mailbox permission inventory;
- Conditional Access/app/license read inventory.

Prohibited:

- policy edits;
- group edits;
- site edits;
- mailbox permission changes;
- app deletion;
- license assignment/removal;
- Teams/channel creation, rename, archive, or deletion.

## Read-only command starters

These are starter commands, not final automation. Run during a supervised auth window and review outputs before committing.

### Users

```powershell
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","Directory.Read.All"

Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,Department,CompanyName,JobTitle,OfficeLocation,AccountEnabled |
  Select-Object Id,DisplayName,UserPrincipalName,Department,CompanyName,JobTitle,OfficeLocation,AccountEnabled |
  Export-Csv ./.local/reports/tenant-inventory/users.csv -NoTypeInformation
```

### Groups

```powershell
Get-MgGroup -All -Property Id,DisplayName,Mail,MailEnabled,SecurityEnabled,GroupTypes,MembershipRule,MembershipRuleProcessingState |
  Select-Object Id,DisplayName,Mail,MailEnabled,SecurityEnabled,GroupTypes,MembershipRule,MembershipRuleProcessingState |
  Export-Csv ./.local/reports/tenant-inventory/groups.csv -NoTypeInformation
```

### SharePoint sites

```powershell
Connect-PnPOnline -Url "https://deltacrown-admin.sharepoint.com" -Interactive

Get-PnPTenantSite -Detailed |
  Select-Object Url,Title,Template,Owner,StorageUsageCurrent,SharingCapability,HubSiteId,LockState |
  Export-Csv ./.local/reports/tenant-inventory/sharepoint-sites.csv -NoTypeInformation
```

### Teams

```powershell
Connect-MicrosoftTeams

Get-Team |
  Select-Object GroupId,DisplayName,Description,Visibility,MailNickName,Archived |
  Export-Csv ./.local/reports/tenant-inventory/teams.csv -NoTypeInformation
```

### Exchange

```powershell
Connect-ExchangeOnline

Get-Mailbox -RecipientTypeDetails SharedMailbox |
  Select-Object DisplayName,PrimarySmtpAddress,Alias,GrantSendOnBehalfTo |
  Export-Csv ./.local/reports/tenant-inventory/shared-mailboxes.csv -NoTypeInformation

Get-DistributionGroup |
  Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails,ManagedBy |
  Export-Csv ./.local/reports/tenant-inventory/distribution-groups.csv -NoTypeInformation
```

### Conditional Access

```powershell
Connect-MgGraph -Scopes "Policy.Read.All","Directory.Read.All"

Get-MgIdentityConditionalAccessPolicy -All |
  Select-Object Id,DisplayName,State,CreatedDateTime,ModifiedDateTime |
  Export-Csv ./.local/reports/tenant-inventory/conditional-access.csv -NoTypeInformation
```

### App registrations

```powershell
Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All"

Get-MgApplication -All |
  Select-Object Id,AppId,DisplayName,SignInAudience,CreatedDateTime |
  Export-Csv ./.local/reports/tenant-inventory/app-registrations.csv -NoTypeInformation
```

### Enterprise apps

```powershell
Get-MgServicePrincipal -All |
  Select-Object Id,AppId,DisplayName,ServicePrincipalType,AccountEnabled |
  Export-Csv ./.local/reports/tenant-inventory/enterprise-apps.csv -NoTypeInformation
```

### Licenses

```powershell
Connect-MgGraph -Scopes "Organization.Read.All","Directory.Read.All"

Get-MgSubscribedSku |
  Select-Object SkuPartNumber,ConsumedUnits,PrepaidUnits |
  Export-Csv ./.local/reports/tenant-inventory/licenses.csv -NoTypeInformation
```

## Sensitive output handling

Before committing inventory outputs, inspect for:

- secrets;
- tokens;
- private keys;
- certificate material;
- unnecessary personal data;
- sensitive user lists;
- finance/strategy filenames;
- external emails that should be summarized;
- app credentials or credential hints.

If raw output is too sensitive:

- keep raw files local;
- commit a redacted summary;
- document what was withheld and why;
- mark the related issue as partially complete or blocked on redaction approval.

## Per-area success criteria

### Identity and groups

Complete when:

- users are exported or access blocker is documented;
- user metadata completeness is visible;
- groups and dynamic rules are exported;
- AllStaff, Managers, Stylists, Marketing, and Leadership can be verified or flagged.

### SharePoint

Complete when:

- sites, display titles, URLs, owners, sharing settings, libraries/lists, and key permissions are inventoried;
- legacy ClientServices/Brand Resources state is classified;
- no site URL changes are made.

### Teams

Complete when:

- Teams and channels are inventoried;
- Operations team/channel state is verified or blocked;
- private/shared channels are identified;
- no channels are changed.

### Exchange

Complete when:

- shared mailboxes, distribution lists, aliases, mailbox permissions, and mail flow notes are captured;
- no mailbox permissions are changed.

### Security/apps/licenses

Complete when:

- Conditional Access, app registrations, enterprise apps, licenses, tenant sharing, and compliance policy state are inventoried or explicitly blocked;
- no policies/apps/licenses are changed.

## Handoff

After inventory auth windows:

1. Review outputs for sensitivity.
2. Commit safe reports or redacted summaries.
3. Update `DeltaSetup-132` through `DeltaSetup-136`.
4. Create consolidated output for `DeltaSetup-137`.
5. Feed the showcase gap analysis in `DeltaSetup-138`.

Do not start cleanup from raw inventory. Cleanup gets its own roadmap, owner approval, and rollback/validation plan. We are not feral.
