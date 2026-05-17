# SharePoint Provisioning — Notification Suppression Matrix

> **Project context.** DeltaSetup hub-and-spoke rollout (PnP-based provisioning of communication + spoke sites). P0 follow-up to an incident where ~52 users received surprise sharing emails during a permission-grant step. This document maps every cmdlet/endpoint we touch during provisioning to its exact notification-suppression mechanism, with citations to Microsoft Learn and the official PnP.PowerShell docs (`pnp.github.io/powershell`).
>
> **Researcher.** `web-puppy-7bc185` — 2026-05-16
> **Sources reviewed.** PnP.PowerShell cmdlet reference (Tier 1, primary), Microsoft Graph v1.0 reference (Tier 1, primary), Microsoft Learn SharePoint dev docs (Tier 1), Microsoft 365 Support docs (Tier 2).
> **Last-modified flags captured.** Graph `driveItem: invite` last updated 2025-10-07; SPFx tenant-wide deployment doc last updated 2023-04-17. PnP.PowerShell cmdlet pages do not display a per-page last-modified date — they version with the module release; tested against current `pnp.github.io/powershell/cmdlets/` (the live SiteMap reflects the in-development PnP.PowerShell v3 module).

---

## TL;DR — Default behavior by surface

| # | Surface | Default behavior | Suppression posture |
|---|---|---|---|
| 1 | `Set-PnPWebPermission`, `Set-PnPListItemPermission`, `Set-PnPFolderPermission` | **Silent (no email)** | Safe — no param needed |
| 1 | `Add-PnPSiteCollectionAdmin`, `Set-PnPTenantSite -Owners` | **Silent** | Safe — tenant-admin path is silent |
| 1 | `Grant-PnPHubSiteRights` | **Silent** | Safe |
| 1 | `Add-PnPGroupMember -LoginName` (internal user) | **Silent** | Safe — pick the internal parameter set |
| 1 | `Add-PnPGroupMember -EmailAddress` (external invite path) | **Silent unless `-SendEmail` switch is passed** | Safe — never pass `-SendEmail` |
| 1 | `Set-PnPGroup` | **Silent** | Safe |
| 2 | `Add-PnPFileSharingInvite` / `Add-PnPFolderSharingInvite` | **Silent unless `-SendInvitation` switch is passed** (PnP doc has an inverted prose description — see §2 gotcha) | Safe — never pass `-SendInvitation` |
| 2 | Graph `POST /drives/{id}/items/{id}/invite` | `"sendInvitation": false` is the **schema default in the docs request body** — but you must send the property explicitly in production code to avoid relying on undocumented service defaults | **Always pass `sendInvitation: false` explicitly** |
| 2 | `Add-PnPFileUserSharingLink` / `Add-PnPFolderUserSharingLink` / their `*OrganizationalSharingLink` / `*AnonymousSharingLink` siblings | **Silent — no notification, just returns a link** | Safe — these are link-only cmdlets; you choose if/how to distribute |
| 3 | `Add-PnPHubSiteAssociation` | **Silent** (no user-facing notification anywhere) | Safe; audit via Unified Audit Log (see §3) |
| 4 | `Add-PnPListItem` | Triggers **alerts AND Power Automate flows** — no UpdateType bypass exists on create | **No native suppression**; use `Set-PnPListItem -UpdateType SystemUpdate` on create-then-update pattern, or use a "skip flag" column |
| 4 | `Set-PnPListItem -UpdateType SystemUpdate` | **Skips Power Automate flows**; SharePoint event receivers and alerts may still fire | Use this for any provisioning update |
| 4 | `Set-PnPListItem -UpdateType UpdateOverwriteVersion` | **DOES trigger Power Automate flows** — common footgun | Avoid for silent provisioning |
| 5 | Audience targeting on existing web parts (PnP `Set-PnPPageWebPart`, modern page editor) | **Silent** — audience is metadata for visibility filtering only | Safe |
| 6 | `Add-PnPTenantTheme` / `Set-PnPTenantTheme` | **Silent** — theme just appears in site theme picker; no tenant banner | Safe |
| 7 | `Add-PnPApp` / `Publish-PnPApp` / `Install-PnPApp` / SPFx tenant-wide deployment / `Sync-PnPAppToTeams` | **Silent** — no end-user email/banner; tenant-wide deployed web parts simply appear in the picker | Safe |

**Bottom line for the post-incident root cause.** The most likely culprit for "52 surprise sharing emails" is **one of the three**:

1. A `Add-PnPFileSharingInvite` / `Add-PnPFolderSharingInvite` call where `-SendInvitation` was passed (the inverted-prose doc may have misled an engineer — see §2 gotcha).
2. A direct Graph `POST .../invite` call with `sendInvitation: true` in the body.
3. A `Add-PnPGroupMember -EmailAddress … -SendEmail` call against the External parameter set for guest users.

`Set-PnPSitePermissions` is a non-existent cmdlet name (see §1 gotcha) — the real cmdlets (`Set-PnPWebPermission`, `Set-PnPListItemPermission`, `Set-PnPFolderPermission`) are **silent by design** and could not have been the trigger.

---

## 1. Site-level sharing & permission grants

### 1.a `Set-PnPSitePermissions` → use `Set-PnPWebPermission` (and friends)

**⚠ Naming gotcha.** No cmdlet named `Set-PnPSitePermissions` exists in PnP.PowerShell. The actual cmdlets for site/web/folder/list-item permission management are:

| Scope | Cmdlet |
|---|---|
| Web (site) | `Set-PnPWebPermission` |
| List item | `Set-PnPListItemPermission` |
| Folder | `Set-PnPFolderPermission` |
| List | `Set-PnPListPermission` |
| Group permissions | `Set-PnPGroupPermissions` |
| Site-collection admin | `Add-PnPSiteCollectionAdmin` |
| Tenant-set site owners | `Set-PnPTenantSite -Owners` |

#### `Set-PnPWebPermission`
- **a. Cmdlet:** `Set-PnPWebPermission -User <upn> -AddRole <role>` (or `-Group`, `-RemoveRole`, `-Identity` for subweb).
- **b. Suppression mechanism:** **NONE NEEDED.** The parameter list is **exhaustively** `-Connection`, `-User` / `-Group`, `-AddRole`, `-RemoveRole`, `-Identity`. There is no `-SendEmail`, `-NotifyUsers`, `-EmailBody`, `-EmailSubject`, or `-ShareByEmail` parameter — this cmdlet wraps CSOM `RoleAssignment` adds, which do not generate user notifications.
- **c. Default:** **Silent (suppress).**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Set-PnPWebPermission.html>
- **e. Gotchas:** None for notifications. Note that `-AddRole` accepts an `String[]` so you can add multiple roles in one call. Operates against the current PnP context (`-Identity` only used to target a subweb).
- **f. Launch-day delivery:** Use `Send-PnPMail` (PnP cmdlet) or your own Graph `/sendMail` job for the curated, branded launch announcement after permissions are seeded silently.

#### `Set-PnPListItemPermission` (also covers Phase 2)
- **a. Cmdlet:** `Set-PnPListItemPermission -List <list> -Identity <id> [-User|-Group] -AddRole <role> [-SystemUpdate]`.
- **b. Suppression mechanism:** **NONE NEEDED for email.** No `-SendEmail` / `-NotifyUsers`. Has `-SystemUpdate` which "Update the item permissions without creating a new version or triggering MS Flow" — useful for permission updates on items that have Flows attached.
- **c. Default:** **Silent (suppress).**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Set-PnPListItemPermission.html>
- **e. Gotchas:** `-ClearSubScopes` defaults to `True` — if you `-ClearExisting` permissions on a parent, child unique scopes are also reset to inheritance. This is a permission-model footgun, not a notification one.
- **f. Launch-day delivery:** Same as above.

#### `Add-PnPSiteCollectionAdmin`
- **a. Cmdlet:** `Add-PnPSiteCollectionAdmin -Owners <upn[]>` or `-PrimarySiteCollectionAdmin <upn>`.
- **b. Suppression mechanism:** **NONE NEEDED.** Parameters: `-Owners`, `-PrimarySiteCollectionAdmin`, `-Connection`. No notification mechanism.
- **c. Default:** **Silent.**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPSiteCollectionAdmin.html>
- **e. Gotchas:**
  - Requires the caller to **already be a site collection admin**; if not, use `Set-PnPTenantSite -Owners` (SharePoint admin path, also silent).
  - "Existing administrators will stay" — additive, not destructive.
- **f. Launch-day delivery:** N/A — site collection admin role is an admin operation, not a user-facing event.

#### `Grant-PnPHubSiteRights`
- **a. Cmdlet:** `Grant-PnPHubSiteRights -Identity <hub-url> -Principals <upn[]>`.
- **b. Suppression mechanism:** **NONE NEEDED.** Parameters: `-Identity`, `-Principals`, `-Connection`. No notification.
- **c. Default:** **Silent.**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Grant-PnPHubSiteRights.html>
- **e. Gotchas:** Granting hub-site rights does **not** add the principal to the hub or any spoke; it only grants the permission to associate *their* sites to this hub. Common misunderstanding.
- **f. Launch-day delivery:** N/A.

#### `Set-PnPGroup` (SharePoint group, not M365 group)
- **a. Cmdlet:** `Set-PnPGroup -Identity <group> [-Title|-Owner|-Description|-AddRole|-RemoveRole|-RequestToJoinEmail …]`.
- **b. Suppression mechanism:** **NONE NEEDED.** No `-SendEmail`/`-EmailBody`. `-RequestToJoinEmail` is the **inbox address that receives join-requests** (recipient configuration), **not** an outbound notification toggle. Group setting changes never notify members.
- **c. Default:** **Silent.**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Set-PnPGroup.html>
- **e. Gotchas:** Don't confuse with `Set-PnPMicrosoft365Group` (M365 group, has separate behavior).
- **f. Launch-day delivery:** N/A.

#### `Add-PnPGroupMember` (the most-notification-relevant SharePoint-group cmdlet)
- **a. Cmdlet:** Three parameter sets:
  - **Internal:** `Add-PnPGroupMember -LoginName <upn> -Group <group>` → no email params, silent.
  - **External:** `Add-PnPGroupMember -EmailAddress <addr> -Group <group> [-SendEmail] [-EmailBody <text>]` → email only if `-SendEmail` switch is passed.
  - **Batched:** internal-only syntax + `-Batch`.
- **b. Suppression mechanism:** The `-SendEmail` switch is a `SwitchParameter` with no default value (i.e., **`$false` unless present** in the invocation). `-EmailBody` is only honored when `-SendEmail` is on. **Use the `-LoginName` (Internal) parameter set for tenant users** to remove any chance of an email path.
- **c. Default:** **Silent (suppress).** You must explicitly opt in to email.
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPGroupMember.html>
- **e. Gotchas:**
  - The "External" parameter set is **only for external/guest invitations**. If your provisioning script picks `-EmailAddress` for internal users (it shouldn't), it would still route through the external code path. Always prefer `-LoginName`.
  - There is no `Set-PnPGroupMember` — membership changes are add/remove only.
- **f. Launch-day delivery:** `Send-PnPMail` (manual control) or schedule a Power Automate "Send an HTTP request to Office 365" approval flow that fires the announcement *after* membership is seeded.

#### `Set-PnPTenantSite -Owners`
- **a. Cmdlet:** `Set-PnPTenantSite -Identity <site-url> -Owners <upn[]>` (also `-PrimarySiteCollectionAdmin <upn>`).
- **b. Suppression mechanism:** **NONE NEEDED.** No notification parameters; this is the tenant-admin path equivalent to `Add-PnPSiteCollectionAdmin` but runnable from outside the site context. The cmdlet has 60+ parameters; **none of them control user-facing notification** for the `-Owners` action.
- **c. Default:** **Silent.**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Set-PnPTenantSite.html>
- **e. Gotchas:**
  - `-DisableSharingForNonOwners` also disables "Access Request Emails" — useful tenant-side hardening if you want to suppress *organic* access-request emails during the rollout window.
- **f. Launch-day delivery:** N/A.

---

## 2. Library / folder / list-item sharing

### 2.a Sharing **invitations** (the high-risk path — this is what fired the 52 emails)

#### `Add-PnPFileSharingInvite` / `Add-PnPFolderSharingInvite`
- **a. Cmdlet:** `Add-PnPFileSharingInvite -FileUrl <url> -Users <upn[]> [-Message <text>] [-RequireSignIn] [-SendInvitation] [-Role <Read|Write|Owner>] [-ExpirationDateTime <dt>]`.
- **b. Suppression mechanism:** **Do NOT pass the `-SendInvitation` switch.** With `-SendInvitation` omitted, the underlying Graph `/invite` call is issued with `sendInvitation: false` and only the permission record is created — no email.
- **c. Default:** **Silent (suppress)** when `-SendInvitation` is omitted. Example 1 in the PnP docs explicitly demonstrates the silent path; Example 2 adds `-SendInvitation` to fire the email.
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPFileSharingInvite.html> and <https://pnp.github.io/powershell/cmdlets/Add-PnPFolderSharingInvite.html>
- **e. Gotchas — IMPORTANT:**
  - **DOCUMENTATION DEFECT.** The PnP page describes `-SendInvitation` as: *"Specifies if an email or post is generated (false) or if the permission is just created (true)."* This is **inverted** relative to (a) the parameter's name, (b) Example 2 ("The invitation will be sent and the user will have Owner permissions"), and (c) the underlying Graph `sendInvitation` semantics. Treat the parameter name + Graph contract as ground truth: **`-SendInvitation` present ⇒ email is sent**.
  - `-Users` is documented as "Currently, only one user at a time is supported. We are planning to add support for multiple users a bit later." — plan loops, but each loop iteration is still a separate `/invite` POST.
  - **App-only auth limitation (from Graph docs):** "New guests can't be invited using app-only access. Existing guests can be invited using app-only requests." Your unattended provisioning identity cannot invite brand-new external guests via `/invite`; you must use the B2B Invitation Manager API or pre-provision the guest object first.
- **f. Launch-day delivery:** Re-run the same cmdlet **with `-SendInvitation` and a curated `-Message`** when you want to issue the official launch email, or send a templated email via `Send-PnPMail` / Power Automate with branded HTML.

#### Microsoft Graph `POST /drives/{id}/items/{id}/invite` (v1.0)
- **a. Endpoint:** `POST /drives/{drive-id}/items/{item-id}/invite` (or `/me/drive/...`, `/sites/{siteId}/drive/...`, `/users/{userId}/drive/...`, `/groups/{group-id}/drive/...`).
- **b. Suppression mechanism (body property):**
  ```json
  {
    "recipients": [ { "email": "user@contoso.com" } ],
    "requireSignIn": true,
    "sendInvitation": false,    // ← suppression flag
    "roles": [ "write" ],
    "retainInheritedPermissions": true
  }
  ```
  - `sendInvitation` (Boolean) — Microsoft Learn definition: *"If true, a sharing link is sent to the recipient. Otherwise, a permission is granted directly without sending a notification."*
  - `message` (String) — only used when `sendInvitation: true`; 2000-char max.
  - `retainInheritedPermissions` (Boolean) — defaults to `true`; set `false` to wipe inherited perms when first sharing.
- **c. Default:** The documented request-body schema shows `"sendInvitation": false`. The service treats omitted `sendInvitation` as `false`. **Treat omission as "suppress" — but always send the property explicitly in production for safety.**
- **d. Docs:** <https://learn.microsoft.com/en-us/graph/api/driveitem-invite?view=graph-rest-1.0> (last updated 2025-10-07).
- **e. Gotchas:**
  - **v1.0 vs beta** — schema for `sendInvitation` is identical in v1.0 and beta; the v1.0 surface is GA and recommended for provisioning. Stick to v1.0 unless you need beta-only roles.
  - **Partial-success response.** When you `sendInvitation: true` for multiple recipients and email delivery fails for some, you get **HTTP 207 Multi-Status** with per-recipient `error` objects. Possible error codes inside `innererror`:
    - `accountVerificationRequired`
    - `hipCheckRequired`
    - `exchangeInvalidUser` (mailbox missing)
    - `exchangeOutOfMailboxQuota`
    - `exchangeMaxRecipients`
    Even when delivery fails, the **permission is still granted** — important: a failed email does NOT roll back the share.
  - **Personal-OneDrive caveat:** "Permissions can't be created or modified on the root driveItem of drives with a driveType of personal."
  - **App-only limitation:** New guests cannot be invited via app-only; existing guests can.
- **f. Launch-day delivery:** Re-POST `/invite` with `sendInvitation: true` and a `message`, OR (preferred) send a branded email from your tenant via `POST /users/{id}/sendMail` so users get a recognizable sender + DLP-tracked message.

### 2.b Legacy SharePoint `ShareDocument` / `SP.Web.ShareObject` REST endpoint
- **a. Endpoint:** `POST _api/SP.Web.ShareObject` (and `SP.Web.ShareDocument`, `SP.Sharing.DocumentSharingManager.UpdateDocumentSharingInfo`).
- **b. Suppression mechanism (body parameter):** `sendEmail` (Boolean) — set to `false` to grant the permission without sending the sharing email. Companion params: `emailSubject`, `emailBody`, `propagateAcl`, `includeAnonymousLinkInEmail`.
- **c. Default:** When the parameter is omitted or null, the underlying `Microsoft.SharePoint.Client.Web.ShareObject` defaults to **`sendEmail = true`** — this is the opposite of the Graph default and is a long-standing **legacy footgun** worth flagging in code review. Always set `sendEmail: false` explicitly on this legacy endpoint.
- **d. Docs:** This endpoint is **deprecated for new development**; Microsoft recommends Graph `/invite` instead. Authoritative reference is in the SharePoint CSOM SDK (`Microsoft.SharePoint.Client.Web.ShareObject` method, `sendEmail` parameter). Avoid in DeltaSetup provisioning — pin to Graph `/invite` or `Add-PnPFileSharingInvite`.
- **e. Gotchas:** The PnP framework wrapper (`Web.ShareDocument`) **also defaults `sendEmail` to true in some overloads** — explicit booleans only.
- **f. Launch-day delivery:** N/A — avoid the endpoint; use Graph or PnP equivalents.

### 2.c Sharing-link cmdlets (`Add-PnPFile*SharingLink`, `Add-PnPFolder*SharingLink`)
PnP exposes six dedicated link-creation cmdlets, all of which are **link-only and silent**:

| Cmdlet | Behavior |
|---|---|
| `Add-PnPFileUserSharingLink` / `Add-PnPFolderUserSharingLink` | Creates a "Specific people" link for the listed `-Users`. **No email sent — just returns the link URL.** |
| `Add-PnPFileOrganizationalSharingLink` / `Add-PnPFolderOrganizationalSharingLink` | Creates a "People in your organization" link. Silent. |
| `Add-PnPFileAnonymousSharingLink` / `Add-PnPFolderAnonymousSharingLink` | Creates an "Anyone" link. Silent. |

- **a. Cmdlet (representative):** `Add-PnPFileUserSharingLink -FileUrl <url> -Users <upn[]> [-Type <View|Edit>]`.
- **b. Suppression mechanism:** No `-SendEmail` / `-SendInvitation` parameter exists — these cmdlets *only* mint the link, they never trigger email delivery. Distribution is the caller's responsibility.
- **c. Default:** **Silent.**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPFileUserSharingLink.html> (and the matching folder/anonymous/organizational pages).
- **e. Gotchas:** "Specific people" links grant `viewableByEmail = false` semantics; you must hand the link to the user yourself. This is the **safest provisioning primitive** for libraries.
- **f. Launch-day delivery:** Capture the link URLs from the cmdlet output and include them in your branded launch email.

---

## 3. Hub-site association

### `Add-PnPHubSiteAssociation`
- **a. Cmdlet:** `Add-PnPHubSiteAssociation -Site <spoke-url> -HubSite <hub-url>`.
- **b. Suppression mechanism:** **NONE NEEDED.** Parameters: `-Site`, `-HubSite`, `-Connection`. No notification surface.
- **c. Default:** **Silent.** No notification fires to hub admins, spoke owners, or spoke members. The spoke takes on the hub's theme/navigation on next page load; users see the change visually but receive no email or in-product banner.
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPHubSiteAssociation.html> · Concept: <https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/hubsites-overview>
- **e. Gotchas:**
  - Underlying call is the tenant-admin `Site.HubSiteId` setter (CSOM `Site.JoinHubSite(hubSiteId)`); it requires tenant-admin token, not site-admin.
  - If the hub has **hub permissions restricted via `Grant-PnPHubSiteRights`**, the calling identity must be on that allow-list.
- **f. Launch-day delivery:** N/A — hub joins are configuration, not events. For your launch comms, use a curated email or Viva Connections card.

### Audit-log proof for CI

You **can** prove in CI that the association ran. Two evidence paths:

1. **Read-back (cheap, immediate):** `Get-PnPHubSiteChild -Identity <hub-url>` → returns the list of associated spokes. Assert your spoke URL is present. Alternatively `Get-PnPSite -Includes HubSiteId` on the spoke → assert `HubSiteId` matches the hub's `SiteId`.
2. **Unified Audit Log (authoritative tenant-wide):** `Get-PnPUnifiedAuditLog -ContentType SharePoint -StartTime (Get-Date).AddMinutes(-10)` → filter for `Operation` values such as `HubSiteJoined`, `HubSiteRegistered`, `HubSiteUnjoined`. The Unified Audit Log is the system-of-record for tenant audit and is admissible for compliance. Reference: <https://pnp.github.io/powershell/cmdlets/Get-PnPUnifiedAuditLog.html> and <https://learn.microsoft.com/en-us/purview/audit-search>.

Recommended CI pattern: **read-back assertion first (fast, deterministic), Unified Audit Log as nightly compliance check** (the audit pipeline can lag 5–30 minutes).

---

## 4. List items, alerts, and Power Automate side-effects

### `Add-PnPListItem`
- **a. Cmdlet:** `Add-PnPListItem -List <list> -Values @{...}` (Single or Batched).
- **b. Suppression mechanism:** **NONE EXISTS on this cmdlet.** `Add-PnPListItem` has no `-UpdateType`, no `-SystemUpdate`, no `-NoTriggers`. Creating an item via this cmdlet **always fires** `ItemAdded` event receivers, **always fires** matching alert subscriptions ("Alert me when items are added"), and **always fires** Power Automate flows triggered by "When an item is created".
- **c. Default:** **Notify (cannot be suppressed at the cmdlet level).**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPListItem.html>
- **e. Gotchas / workarounds:**
  - **CSOM truth.** The cmdlet calls `List.AddItem(...)` + `ListItem.Update()`. There is no `SystemAdd` equivalent in CSOM — `SystemUpdate()` and `UpdateOverwriteVersion()` are only defined for the *update* path, not for adds. This is a SharePoint-platform limitation, not a PnP omission.
  - **Skip-flag pattern (recommended).** Add a hidden boolean column (e.g., `ProvisioningSkip`) to every provisioned list. In your Power Automate flow trigger condition, add `@equals(triggerOutputs()?['body/ProvisioningSkip'], false)` — flows that opt in to this contract will then ignore provisioning rows.
  - **Disable alerts at provisioning window.** Tenant alert delivery can be paused by setting the site's email feature off, but a less invasive option is to **enumerate and disable alerts** before the run: `Get-PnPAlert -List <list> | Remove-PnPAlert` and re-create afterward. This is the only way to avoid alert emails on adds; document it as the kill-switch.
  - **`-Batch` does not affect notification behavior** — each item in the batch still fires its triggers.
- **f. Launch-day delivery:** Toggle the skip-flag off after provisioning + run a deliberate "kick-off" item add, OR re-enable alerts via `Add-PnPAlert` after seeding.

### `Set-PnPListItem -UpdateType` (CSOM ground truth)
The PnP cmdlet docs lay out the **exact** event/flow behavior for each update mode:

| `-UpdateType` value | New version? | "Modified" updated? | SP event receivers fire? | Power Automate flows fire? |
|---|---|---|---|---|
| `Update` (default) | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| `SystemUpdate` | ❌ No | ❌ No (uneditable) | ✅ "Any events on the list will trigger" | **❌ No — "Power Automate Flows are not triggered"** |
| `UpdateOverwriteVersion` | ❌ No | ❌ No (editable via `Editor` field) | ✅ Yes | **✅ Yes — "Power Automate Flows ARE triggered"** (common footgun) |

- **Docs (quoted verbatim above):** <https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html> (see `-UpdateType` parameter).
- **Practical guidance for DeltaSetup:**
  - During provisioning, **use `Set-PnPListItem -UpdateType SystemUpdate`** for any update to seeded items. This is the *only* combination that bypasses Power Automate flows.
  - Be aware: alerts and item-level event receivers may still fire under `SystemUpdate`. If a customer flow uses an event receiver instead of a Power Automate trigger, `SystemUpdate` will not silence it. Couple with the skip-flag pattern for belt-and-braces.
  - **NEVER use `UpdateOverwriteVersion` if your goal is to suppress flows** — its name suggests "in-place" / "silent" but it **does** trigger flows.

### Power Automate "skip-flag" pattern (canonical)
1. Add a hidden Yes/No column `Provisioning` (default `No`).
2. All provisioning writes set `Provisioning = Yes`.
3. Every business flow uses **Trigger Conditions**: `@equals(triggerOutputs()?['body/Provisioning'], false)`.
4. After cut-over, an operator runs a one-shot `Set-PnPListItem -UpdateType SystemUpdate -Values @{Provisioning=$false}` to clear the flag (silently). The flag clear itself does not trigger flows because `SystemUpdate` is being used.

Microsoft Learn references:
- Trigger conditions: <https://learn.microsoft.com/en-us/power-automate/triggers-introduction#trigger-conditions>
- SharePoint trigger reference: <https://learn.microsoft.com/en-us/connectors/sharepointonline/#triggers>

---

## 5. Audience targeting on an existing web part

- **a. Cmdlet/API:** `Set-PnPPageWebPart -Page <page> -Identity <webpart-id> -PropertiesJson <json>` or modern page editor → web part settings → Audience targeting.
- **b. Suppression mechanism:** **NONE NEEDED.** Audiences are *visibility metadata only*. Adding a group as an audience never triggers any user-facing event. The included users will simply *start seeing* the web part on their next page load; the excluded users will stop seeing it. No email, no banner, no Teams ping.
- **c. Default:** **Silent.**
- **d. Docs:** <https://support.microsoft.com/en-us/office/target-content-to-a-specific-audience-on-a-sharepoint-site-68113d1b-be99-4d4c-a61c-73b087f48a81>
- **e. Gotchas:**
  - Audience targeting must be **enabled on the site/library** (or on the page) before it takes effect — see the per-list "Audience targeting" toggle. Adding an audience to a web part on a list that does not have targeting enabled is a no-op silently.
  - Targeting evaluates against the user's **direct + transitive** Entra group membership. Cross-tenant guest users may not resolve correctly — test with a guest before launch.
  - News audiences (separate feature) follow the same silent semantics.
- **f. Launch-day delivery:** N/A. If you want to signal launch to the audience, send a curated Viva Connections card or email — the targeting change itself doesn't.

---

## 6. Brand Center / theme deployment

### `Add-PnPTenantTheme` / `Set-PnPTenantTheme`
- **a. Cmdlet:** `Add-PnPTenantTheme -Identity <name> -Palette <hashtable> -IsInverted <bool> [-Overwrite]`; `Set-PnPTenantTheme` mirrors for updates.
- **b. Suppression mechanism:** **NONE NEEDED.** Parameters: `-Identity`, `-Palette`, `-IsInverted`, `-Overwrite`, `-Connection`. No notification surface.
- **c. Default:** **Silent.** The theme simply becomes available in the per-site theme picker (Site information → Change the look → Theme). No tenant banner, no admin email, no end-user message.
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPTenantTheme.html>
- **e. Gotchas:**
  - **Themes are only made available, not applied.** To apply: `Set-PnPWebTheme -Theme <name>` (also silent) or `Set-PnPTheme`. Applying a theme to a site does not notify members either; users see the new colors on next load.
  - `-Overwrite` mutates an existing theme without warning; live sites already using it will refresh colors on next render.
- **f. Launch-day delivery:** N/A — themes are a visual change, not an event.

### Brand Center (2024/2025 feature)
The newer **Brand Center** experience (Microsoft 365 admin → SharePoint admin center → Brand Center) is exposed via these PnP cmdlets:

- `Get-PnPBrandCenterConfig`
- `Add-PnPBrandCenterFont` / `Add-PnPBrandCenterFontPackage` / `Get-PnPBrandCenterFont` / `Get-PnPBrandCenterFontPackage` / `Use-PnPBrandCenterFontPackage`

All of these are **silent**: they only add fonts/font-packages to the central brand store; they do not notify users or admins. There is no `-SendEmail` / `-Notify` parameter on any of them. Behavior parallels `Add-PnPTenantTheme`: assets become available in pickers; nothing pushes to users.

- **Docs:** <https://pnp.github.io/powershell/cmdlets/Get-PnPBrandCenterConfig.html> and the related Brand-Center pages on `pnp.github.io/powershell/cmdlets/`.
- **Gotcha:** Brand Center is **tenant-scoped**; using `Use-PnPBrandCenterFontPackage` on a site silently swaps the available fonts in that site's font picker. End users see fonts change on next page load.

---

## 7. SPFx solution deployment + app catalog install

### `Add-PnPApp`
- **a. Cmdlet:** `Add-PnPApp -Path <sppkg> [-Scope <Tenant|Site>] [-Overwrite] [-Publish] [-SkipFeatureDeployment]`.
- **b. Suppression mechanism:** **NONE NEEDED.** Uploading an `.sppkg` to the app catalog is a file upload to a SharePoint library — no notification.
- **c. Default:** **Silent.**
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Add-PnPApp.html>
- **e. Gotchas:** `-Publish` chains a `Publish-PnPApp` call (also silent). `-SkipFeatureDeployment` here mirrors the package's manifest setting.
- **f. Launch-day delivery:** N/A.

### `Publish-PnPApp`
- **a. Cmdlet:** `Publish-PnPApp -Identity <id> [-Scope <Tenant|Site>] [-SkipFeatureDeployment] [-Force]`.
- **b. Suppression mechanism:** **NONE NEEDED.** No notification parameters.
- **c. Default:** **Silent** to end users. **However**, in the SharePoint admin → "More features" → Apps UI, a tenant admin sees a *modal* asking whether to enable across all sites when the package has `skipFeatureDeployment: true`. That modal is admin-only — not user-facing.
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Publish-PnPApp.html> · SPFx tenant-wide deployment concept: <https://learn.microsoft.com/en-us/sharepoint/dev/spfx/tenant-scoped-deployment> (last updated 2023-04-17).
- **e. Gotchas:**
  - **Critical distinction.** `-SkipFeatureDeployment` controls whether the SPFx solution is *automatically* deployed to all sites in the tenant; it does **not** control notifications. Name is confusing.
  - When tenant-wide deployment is enabled, "Web parts included in solutions that have been centrally deployed are immediately visible in the web part picker in both classic and modern pages." — users discover the new web part organically in the picker; **no email or banner is sent.**
  - "Solutions that are configured to be automatically deployed across tenants are not visible in the add-an-app capability at the site level." — users cannot trigger an install themselves; nothing for them to notice in their app launcher.
- **f. Launch-day delivery:** Send a curated email or Viva Connections card pointing users to the page that exposes the new web part.

### `Install-PnPApp`
- **a. Cmdlet:** `Install-PnPApp -Identity <id> [-Scope <Tenant|Site>] [-Wait]`.
- **b. Suppression mechanism:** **NONE NEEDED.** No notification.
- **c. Default:** **Silent.** Installs the app to the current site context. No user email; if the app contributes a web part the user discovers it next time they edit a page.
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Install-PnPApp.html>
- **e. Gotchas:** `-Scope` defaults to `Tenant` (the app must already be published in the tenant app catalog). Use `-Wait` in CI so subsequent `Set-PnPPageWebPart` calls don't race the install.
- **f. Launch-day delivery:** N/A.

### `Sync-PnPAppToTeams`
- **a. Cmdlet:** `Sync-PnPAppToTeams -Identity <id>`.
- **b. Suppression mechanism:** **NONE NEEDED.** No notification.
- **c. Default:** **Silent.** Pushes a Teams-app-manifest copy of the SPFx package into the Microsoft Teams app catalog so the same web part is consumable as a Teams personal/channel app.
- **d. Docs:** <https://pnp.github.io/powershell/cmdlets/Sync-PnPAppToTeams.html>
- **e. Gotchas:**
  - The synced app appears under **Apps → Built for your org** in Teams for users — they discover it organically; **no notification.**
  - If Teams admin policies allow side-loading, the app may also surface via Teams admin app-policy UI to admins; still no user email.
- **f. Launch-day delivery:** Pin the app to a Teams app setup policy (Teams admin center) for prominent placement; combine with a curated email for the rollout window.

---

## Cross-cutting recommendations for DeltaSetup

### Code-review checklist (apply to every provisioning PR)
- [ ] No PR contains `-SendInvitation` on `Add-PnPFile*SharingInvite` / `Add-PnPFolder*SharingInvite`.
- [ ] No PR contains `-SendEmail` on `Add-PnPGroupMember`.
- [ ] No PR posts to Graph `/invite` with `sendInvitation: true` (lint the JSON bodies).
- [ ] No PR uses the legacy `SP.Web.ShareObject` REST endpoint (`sendEmail` defaults to `true` — opposite of every modern API).
- [ ] Every `Set-PnPListItem` call uses `-UpdateType SystemUpdate` unless versioning + flow-firing is explicitly desired.
- [ ] `Add-PnPListItem` calls are wrapped to set the `Provisioning = Yes` skip-flag, and every customer flow checks that flag in its trigger condition.
- [ ] Hub-association steps include a read-back assertion (`Get-PnPHubSiteChild` or `Get-PnPSite -Includes HubSiteId`) for CI proof.

### CI quality-gate additions (file under the existing `tests/` directory)
Add a static-analysis step that greps the provisioning scripts:
```bash
# fail if any provisioning script enables a notification
! grep -rEn '\-SendInvitation\b|\-SendEmail\b|"sendInvitation"\s*:\s*true|"sendEmail"\s*:\s*true' phase4-migration/ tools/ scripts/ 2>/dev/null
```
This is the same defensive pattern used by the existing `tests/accessibility_static_audit.py`-style audits in this repo (see `AGENTS.md` quality-gate section) and can be invoked from the same hook surface.

### Audit-log proof harness
Add a CI job that, after provisioning, polls the Unified Audit Log for the operations that *should* have fired (`HubSiteJoined`, `SiteCollectionAdminAdded`, `AppCatalogAppAdded`) and asserts the count of `SharingSet` / `SharingInvitationCreated` / `AnonymousLinkCreated` events for the provisioning window is **zero** (or strictly equal to the count of intended sharing actions). The Unified Audit Log is the only authoritative source of "did SharePoint actually send anything?".

---

## Source credibility table

| Source | Tier | Authority | Currency | Why trusted |
|---|---|---|---|---|
| `pnp.github.io/powershell/cmdlets/` (PnP.PowerShell ref) | 1 | Microsoft 365 PnP community + Microsoft engineering | Live; tracks current module | Primary, machine-generated from cmdlet attributes |
| `learn.microsoft.com` — Microsoft Graph v1.0 `driveItem: invite` | 1 | Microsoft | Updated 2025-10-07 | Primary REST contract; ground truth for `sendInvitation` semantics |
| `learn.microsoft.com` — SPFx tenant-scoped deployment | 1 | Microsoft | Updated 2023-04-17 | Primary concept doc; behavior unchanged in 2024/2025 releases |
| `support.microsoft.com` — Audience targeting | 2 | Microsoft Support | Living doc | End-user-oriented but authoritative on user-visible behavior |
| Microsoft Learn — Unified Audit Log / Purview audit search | 1 | Microsoft | Living doc | Authoritative for audit-log schema and search semantics |

**Known doc defect logged:** `Add-PnPFileSharingInvite -SendInvitation` parameter description on `pnp.github.io` is inverted relative to the parameter name and the underlying Graph contract. Recommend filing an issue at <https://github.com/pnp/powershell/issues> after the incident debrief.
