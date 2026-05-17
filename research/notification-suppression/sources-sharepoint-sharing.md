# Sources — SharePoint Sharing Notification Suppression Research

> Companion to `sharepoint-sharing.md`. The sibling file `sources.md`
> covers the Teams-cluster research by agent `web-puppy-df3922`; this
> file covers the SharePoint cluster by agent `web-puppy-7bc185`.
>
> All URLs visited live on **2026-05-16**. Tier 1 = primary/official.

## Tier 1 — Microsoft Learn (Microsoft Graph)

### Graph v1.0 — `driveItem: invite`
- **URL:** <https://learn.microsoft.com/en-us/graph/api/driveitem-invite?view=graph-rest-1.0&tabs=http>
- **Last updated on page:** 2025-10-07
- **Key extracts (verbatim where quoted):**
  - `sendInvitation` (Boolean) — *"If true, a sharing link is sent to the recipient. Otherwise, a permission is granted directly without sending a notification."*
  - Request-body skeleton ships with `"sendInvitation": false` as the documented schema default.
  - Partial-success returns HTTP 207 Multi-Status; notification-failure inner error codes: `accountVerificationRequired`, `hipCheckRequired`, `exchangeInvalidUser`, `exchangeOutOfMailboxQuota`, `exchangeMaxRecipients`.
  - **Permission is granted even if notification delivery fails** (no rollback).
  - "New guests can't be invited using app-only access. Existing guests can be invited using app-only requests."
  - "Permissions can't be created or modified on the root driveItem of drives with a driveType of personal."

## Tier 1 — Microsoft Learn (SharePoint dev)

### SPFx — Tenant-scoped solution deployment
- **URL:** <https://learn.microsoft.com/en-us/sharepoint/dev/spfx/tenant-scoped-deployment>
- **Last updated on page:** 2023-04-17
- **Key extracts:**
  - `skipFeatureDeployment: true` exposes the admin "Enable this app and add it to all sites" checkbox.
  - Centrally deployed web parts are "immediately visible in the web part picker in both classic and modern pages." → No end-user notification path.
  - "Solutions that are configured to be automatically deployed across tenants are not visible in the add-an-app capability at the site level."

## Tier 1 — PnP.PowerShell cmdlet reference (`pnp.github.io/powershell`)

Auto-generated from cmdlet attributes in the [PnP.PowerShell repo](https://github.com/pnp/powershell); ships with each module release. Primary reference for parameter sets and defaults.

| Cmdlet | URL | Notification-relevant parameter (if any) |
|---|---|---|
| `Set-PnPWebPermission` | <https://pnp.github.io/powershell/cmdlets/Set-PnPWebPermission.html> | none — silent |
| `Set-PnPListItemPermission` | <https://pnp.github.io/powershell/cmdlets/Set-PnPListItemPermission.html> | none for email; has `-SystemUpdate` for flow-skip |
| `Set-PnPFolderPermission` | <https://pnp.github.io/powershell/cmdlets/Set-PnPFolderPermission.html> | none — silent |
| `Set-PnPListPermission` | <https://pnp.github.io/powershell/cmdlets/Set-PnPListPermission.html> | none — silent |
| `Add-PnPSiteCollectionAdmin` | <https://pnp.github.io/powershell/cmdlets/Add-PnPSiteCollectionAdmin.html> | none — silent |
| `Set-PnPTenantSite` | <https://pnp.github.io/powershell/cmdlets/Set-PnPTenantSite.html> | none affecting owner-add notification |
| `Grant-PnPHubSiteRights` | <https://pnp.github.io/powershell/cmdlets/Grant-PnPHubSiteRights.html> | none — silent |
| `Add-PnPHubSiteAssociation` | <https://pnp.github.io/powershell/cmdlets/Add-PnPHubSiteAssociation.html> | none — silent |
| `Set-PnPGroup` | <https://pnp.github.io/powershell/cmdlets/Set-PnPGroup.html> | none — `-RequestToJoinEmail` is inbound, not outbound |
| `Add-PnPGroupMember` | <https://pnp.github.io/powershell/cmdlets/Add-PnPGroupMember.html> | `-SendEmail` (default off) on the External param set |
| `Add-PnPFileSharingInvite` | <https://pnp.github.io/powershell/cmdlets/Add-PnPFileSharingInvite.html> | `-SendInvitation` (default off) — **prose description is inverted** |
| `Add-PnPFolderSharingInvite` | <https://pnp.github.io/powershell/cmdlets/Add-PnPFolderSharingInvite.html> | same as file variant |
| `Add-PnPFileUserSharingLink` | <https://pnp.github.io/powershell/cmdlets/Add-PnPFileUserSharingLink.html> | none — link-only, silent |
| `Add-PnPFolderUserSharingLink` | <https://pnp.github.io/powershell/cmdlets/Add-PnPFolderUserSharingLink.html> | same |
| `Add-PnPFileOrganizationalSharingLink` / `Add-PnPFolderOrganizationalSharingLink` | (same cmdlet folder) | none — silent |
| `Add-PnPFileAnonymousSharingLink` / `Add-PnPFolderAnonymousSharingLink` | (same cmdlet folder) | none — silent |
| `Add-PnPListItem` | <https://pnp.github.io/powershell/cmdlets/Add-PnPListItem.html> | **no suppression mechanism exists on create** |
| `Set-PnPListItem` | <https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html> | `-UpdateType SystemUpdate` (skips Flows); `UpdateOverwriteVersion` (still fires Flows) |
| `Add-PnPTenantTheme` | <https://pnp.github.io/powershell/cmdlets/Add-PnPTenantTheme.html> | none — silent |
| `Add-PnPApp` | <https://pnp.github.io/powershell/cmdlets/Add-PnPApp.html> | none — silent |
| `Publish-PnPApp` | <https://pnp.github.io/powershell/cmdlets/Publish-PnPApp.html> | none — silent (admin prompt only) |
| `Install-PnPApp` | <https://pnp.github.io/powershell/cmdlets/Install-PnPApp.html> | none — silent |
| `Sync-PnPAppToTeams` | <https://pnp.github.io/powershell/cmdlets/Sync-PnPAppToTeams.html> | none — silent |
| `Get-PnPUnifiedAuditLog` (CI evidence path) | <https://pnp.github.io/powershell/cmdlets/Get-PnPUnifiedAuditLog.html> | n/a — read-side cmdlet for auditing |

## Tier 1 — Microsoft Learn (Purview / audit)
- **Audit search reference:** <https://learn.microsoft.com/en-us/purview/audit-search>
  - Unified Audit Log is system-of-record. Relevant SharePoint operations referenced in the report: `SharingSet`, `SharingInvitationCreated`, `SharingInvitationAccepted`, `AnonymousLinkCreated`, `HubSiteJoined`, `HubSiteRegistered`, `HubSiteUnjoined`.

## Tier 2 — Microsoft Support (user-facing docs)
- **Audience targeting:** <https://support.microsoft.com/en-us/office/target-content-to-a-specific-audience-on-a-sharepoint-site-68113d1b-be99-4d4c-a61c-73b087f48a81>
  - Confirms audience targeting is *visibility* metadata only; no notification semantics anywhere in the page.

## Tier 1 — Power Automate (skip-flag pattern basis)
- **Trigger conditions reference:** <https://learn.microsoft.com/en-us/power-automate/triggers-introduction#trigger-conditions>
- **SharePoint connector triggers:** <https://learn.microsoft.com/en-us/connectors/sharepointonline/#triggers>
  - Confirms "When an item is created" fires on every `ItemAdded` event including those originated by PnP cmdlets, validating the need for the skip-flag pattern in §4.

## Credibility assessment

**Authority.** Tier 1 across the board. PnP.PowerShell docs are auto-generated from the same C# cmdlet attributes that ship in the binary on the PowerShell Gallery; Graph references are the canonical REST contract.

**Currency.** Graph `/invite` reference updated 2025-10-07 (very recent). SPFx tenant-deploy doc dates to 2023-04-17 but the behavior described has not changed in subsequent releases (validated against the cmdlet-level `-SkipFeatureDeployment` switch which still exists). PnP cmdlet pages have no per-page last-modified surface; they version with the module release and were re-fetched in this session against `pnp.github.io` live.

**Validation.** All notification-behavior claims were cross-validated across two surfaces (PnP cmdlet doc + Graph REST doc, or PnP cmdlet doc + CSOM behavior described in the cmdlet doc itself). The one **documented divergence** is the inverted prose of `-SendInvitation` on the PnP file/folder sharing-invite cmdlets — flagged in both `sharepoint-sharing.md` (§2 gotcha) and at the bottom of this file under "Filed for follow-up".

**Bias.** None observed. Microsoft has commercial incentive to surface "share with notification" UI for engagement metrics, but the API contract favors explicit-opt-in (`sendInvitation: false` default), which is the correct safety posture.

**Primary vs secondary.** All references are primary Microsoft sources. Zero third-party blog content used.

## Filed for follow-up
- **Doc defect:** Inverted description of `-SendInvitation` on `Add-PnPFileSharingInvite` / `Add-PnPFolderSharingInvite` at `pnp.github.io`. The parameter name and the underlying Graph contract (`sendInvitation: true` = email is sent) are correct; the rendered prose on the PnP doc page has the boolean semantics reversed. Open an issue at <https://github.com/pnp/powershell/issues> after the incident debrief.
