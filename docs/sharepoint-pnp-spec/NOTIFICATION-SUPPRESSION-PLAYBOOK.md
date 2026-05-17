# Notification Suppression Playbook — M365 Provisioning at Scale

**Status:** Living reference (v1.0, 2026-05-16)
**Owner:** Solutions Architect (via `solutions-architect` agent research, 2026-05-16)
**Companion ADR:** [`decisions/011-notification-suppression-by-default.md`](./decisions/011-notification-suppression-by-default.md)
**Triggering incident:** ~5 owners + up to ~52 HTT corporate users received unsolicited welcome/sharing emails from commits `834f516` (2026-05-12), `1cad240` (2026-05-14), `a6dd3f5` (2026-05-15). See §8 for the forensic audit playbook.

---

## 1. Executive summary

**The architectural rule.** Every provisioning action that *could* generate a user-facing notification MUST be suppressed by default. Notifications are an explicit, separate, audited step — never a side-effect of provisioning. This is the **scaffold-quietly, launch-loudly** pattern.

**The five highest-risk surfaces** (rank-ordered by likelihood of repeating the HTT-52 incident):

| Rank | Surface | Default behavior | Why it's high-risk |
|------|---------|------------------|--------------------|
| 1 | M365 Group member-add (Exchange "Welcome to group") | **Sends** | Default-on; multiple suppression layers required; **guest-user trap** forces autosubscribe regardless of group settings |
| 2 | SharePoint `Add-PnPFileSharingInvite -SendInvitation` | Suppress | PnP **documentation defect**: `-SendInvitation` prose is *inverted* relative to the parameter name (see §4.4) |
| 3 | Graph `POST /drives/{id}/items/{id}/invite` | `sendInvitation: false` | Schema default is correct, but service treats omission as `false` — set explicitly to defend against SDK drift |
| 4 | Teams team/channel member-add activity-feed entry | **Sends, unsuppressible** | Microsoft has no documented control surface; only architectural workaround is off-hours + prebrief |
| 5 | Entra B2B invitation (`POST /invitations`) | `sendInvitationMessage: false` | Safe by default, but legacy SDKs have historically flipped the default; pin explicitly |

**Three things that are SAFER than commonly assumed** (don't add unnecessary controls for these):

- **Entra cross-tenant sync** is silent by design — verbatim Microsoft Learn: *"For cross-tenant synchronization, users don't receive an email or have to accept a consent prompt."* MTO membership does not change this.
- **`Set-PnPWebPermission` / `Set-PnPListItemPermission` / `Add-PnPSiteCollectionAdmin` / `Grant-PnPHubSiteRights` / `Add-PnPHubSiteAssociation`** have **no notification surface** at all. They cannot have caused the HTT-52 incident.
- **Theme/Brand Center, SPFx app catalog publish/install, audience targeting** are all silent to end users.

**HTT-52 root cause confirmed.** The forensic scan of `tools/provision-crown-connection.sh` and `tools/expand-crown-connection-htt-corp.py` shows both scripts use `POST /groups` and `PATCH /groups/{id}` with `members@odata.bind` but **never set `resourceBehaviorOptions: WelcomeEmailDisabled`**. Per Microsoft Learn this flag is **creation-only** — it cannot be added later. Combined with HTT users landing as `Guest` userType (which forces autosubscribe regardless of `autoSubscribeNewMembers:$false`), every member-add fired the Exchange welcome path.

---

## 2. The scaffold-mode vs launch-mode pattern

### 2.1 Mode signaling

Every provisioning script MUST accept a `-Mode` parameter with two values:

```powershell
param(
  [ValidateSet('scaffold', 'launch')]
  [string]$Mode = 'scaffold'   # safe default — never sends mail
)
```

- **`scaffold`** (default) — all notification-capable parameters are forced off; the script is allowed to create permissions, group memberships, sharing records, and audit-loggable state. No user-facing artifact may leave the tenant.
- **`launch`** — explicit, audited, opt-in. The script is permitted to send the prepared notifications. **Requires a human approver via GitHub Environment protection** (mirrors the existing `prod` environment gate in `.github/workflows/deploy-prod.yml`).

The default is `scaffold` so that a forgetful or hostile invocation cannot send mail. There is no way to scaffold accidentally with launch settings.

For Python provisioning scripts (e.g., the `tools/expand-crown-connection-htt-corp.py` pattern), use argparse with the same semantics:

```python
parser.add_argument(
    "--mode",
    choices=["scaffold", "launch"],
    default="scaffold",
    help="scaffold (default) suppresses all notifications; launch requires "
         "explicit human approval via GitHub Environment.",
)
```

### 2.2 Audit-logging the choice

Every script writes a single canonical line at startup, BEFORE any provisioning call:

```powershell
Write-Host "PROVISIONING-MODE: $Mode" -ForegroundColor Cyan
"$(Get-Date -Format o) PROVISIONING-MODE=$Mode COMMIT=$env:GITHUB_SHA RUN=$env:GITHUB_RUN_ID" |
  Out-File -Append -FilePath "./out/provisioning-mode.log"
```

This artifact is uploaded as a CI artifact with 365-day retention (matches the SOX retention on the permission audit at `dce-mockup/ci-cd/workflows/permission-audit.yml`). The CI fitness function in §5 asserts this line is present in every workflow run.

### 2.3 Launch-day delivery — the separate, audited step

There is **no single Microsoft cmdlet** that "sends the welcome later." Launch-day delivery is *always* a separate, branded, comms-team-curated step:

- **For M365 Group welcomes** → `Send-PnPMail` or a Comms-curated HTML mailer; do **not** rely on flipping `UnifiedGroupWelcomeMessageEnabled` back on.
- **For B2B invitations** → re-`POST /invitations` for the same `invitedUserEmailAddress` with `sendInvitationMessage: true` and a curated `invitedUserMessageInfo.customizedMessageBody`. Microsoft documents this re-POST pattern explicitly.
- **For SharePoint shares** → re-run `Add-PnPFileSharingInvite -SendInvitation -Message "<curated>"` once at launch, OR (preferred) send a branded email referencing the already-granted permission.
- **For Teams activity feed** → no API to "send the launch ping later." Architectural workaround: announcement post in the General channel after provisioning, sent by a human owner.

The launch-day script MUST be a *separate file* from the scaffold script, MUST require a human GitHub-environment approval, and MUST emit a manifest of recipients before sending.

---

## 3. The notification surface matrix

> Behaviors marked **"silent"** mean no user-facing artifact is generated. All claims are from Microsoft Learn or `pnp.github.io/powershell` as of 2026-05-16.

| # | Surface | Trigger API/Cmdlet | Default | Suppression mechanism | Audit signal (UAL / Entra) | Launch-day delivery |
|---|---------|--------------------|---------|------------------------|----------------------------|---------------------|
| 1 | M365 Group creation | `New-PnPMicrosoft365Group`, Graph `POST /groups` | **Sends** welcome to members | `-ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook` at **create-time only** (cannot PATCH later) | `Add group` (Entra), `AddGroup` (UAL) | Curated Comms email; no Microsoft-provided re-send |
| 2 | M365 Group member add | `Add-PnPMicrosoft365GroupMember`, Graph `POST /groups/{id}/members/$ref` | **Sends** (controlled by group, not call) | Set on the group at create-time (above) + `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled:$false` post-hoc | `AddMemberToGroup` (UAL), `Add member to group` (Entra) | Same as #1 |
| 3 | Group auto-subscribe to conversations | `autoSubscribeNewMembers` group property | `false` (v1.0 + beta) | Leave default; do not set in initial POST (Graph rejects); PATCH later if needed | `Update group` (Entra) | PATCH to `true` on launch day if desired |
| 4 | Group guest-user autosubscribe | (Implicit) | **Forced on for guests** regardless of `autoSubscribeNewMembers` | Use `Remove-UnifiedGroupLinks` post-add OR ensure `WelcomeEmailDisabled` is set | n/a | Comms email |
| 5 | Entra B2B guest invitation | Graph `POST /invitations`, `New-MgInvitation` | `sendInvitationMessage: false` | Set `sendInvitationMessage: false` explicitly (defend against SDK drift) | `Invite external user` (Entra), `UserInvited` (UAL) | Re-POST `/invitations` with `sendInvitationMessage: true` + `invitedUserMessageInfo.customizedMessageBody` |
| 6 | Entra B2B Member conversion | Same `POST /invitations`, `invitedUserType: "Member"` | Same as #5 | Same as #5 | Same as #5 | Same as #5 |
| 7 | Entra cross-tenant sync (HTT→DCE) | Provisioning job in `crossTenantIdentitySyncPolicyPartner` | **Silent by design** (Microsoft Learn verbatim) | No suppression needed — schema has no notification property | No user-visible event; quarantine alerts go to admin email only | Out-of-band comms only |
| 8 | OneDrive personal-site provisioning | `Request-SPOPersonalSite`, JIT auto-provisioning | **Silent** | No suppression needed | `OneDriveProvisioned` (rare) | Out-of-band comms only |
| 9 | SharePoint site permission grant | `Set-PnPWebPermission`, `Add-PnPSiteCollectionAdmin`, `Grant-PnPHubSiteRights`, `Set-PnPTenantSite -Owners` | **Silent** (no `-SendEmail` parameter exists on any of these) | No suppression needed | `SiteCollectionAdminAdded`, `RoleAssignmentAdded` (UAL) | Out-of-band comms only |
| 10 | SharePoint group member add | `Add-PnPGroupMember -LoginName` (internal set) | **Silent** | Use `-LoginName`, not `-EmailAddress`; never pass `-SendEmail` | `AddedToGroup` (UAL) | n/a |
| 11 | SharePoint group member add (external) | `Add-PnPGroupMember -EmailAddress -SendEmail` | Silent unless `-SendEmail` passed | Omit `-SendEmail` | Same as #10 + `SharingInvitationCreated` | Re-run with `-SendEmail` + curated body |
| 12 | SharePoint file/folder sharing invite (PnP) | `Add-PnPFileSharingInvite`, `Add-PnPFolderSharingInvite` | Silent unless `-SendInvitation` passed | Omit `-SendInvitation`. **⚠ PnP doc bug**: prose is inverted; trust the parameter name and Graph contract | `SharingInvitationCreated` (UAL — **always implies mail was sent**) | Re-run with `-SendInvitation -Message "<curated>"` |
| 13 | SharePoint sharing via Graph | `POST /drives/{id}/items/{id}/invite` | `sendInvitation: false` (schema default) | Always set `sendInvitation: false` explicitly | `SharingSet` (UAL — conditional; cross-check Message Trace) | Re-POST with `sendInvitation: true` |
| 14 | SharePoint sharing-link mint | `Add-PnPFile*SharingLink`, `Add-PnPFolder*SharingLink` (User/Org/Anonymous) | **Silent** — link-only, no email path | No suppression needed — caller chooses distribution | `SecureLinkCreated`, `AnonymousLinkCreated`, `CompanyLinkCreated` | Hand link to user via curated comms |
| 15 | Legacy `SP.Web.ShareObject` REST | `POST _api/SP.Web.ShareObject` | **`sendEmail: true`** (legacy footgun, opposite of every modern API) | Always set `sendEmail: false` explicitly — or AVOID this endpoint | Same as #12 | Avoid; use Graph `/invite` |
| 16 | SharePoint list-item create | `Add-PnPListItem` | **Triggers** alerts + Power Automate flows | No cmdlet-level suppression. Use skip-flag column pattern + `Set-PnPListItem -UpdateType SystemUpdate` for subsequent edits | `ListItemAdded` (UAL) | Toggle skip-flag off + run kickoff item add |
| 17 | SharePoint list-item update | `Set-PnPListItem -UpdateType SystemUpdate` | Bypasses Power Automate flows | Always use `-UpdateType SystemUpdate` | `ListItemUpdated` (UAL) | n/a |
| 18 | SharePoint list-item update (footgun) | `Set-PnPListItem -UpdateType UpdateOverwriteVersion` | **Triggers Power Automate flows despite name** | NEVER use this mode for silent provisioning | Same as #17 | n/a |
| 19 | Teams team creation | `New-PnPTeamsTeam`, Graph `POST /teams` | **Sends** welcome + first-run card | `-ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook` (PnP only; `New-Team` lacks this) | `TeamCreated` (UAL) | Comms email + owner-pinned welcome post |
| 20 | Teams team member add | `Add-PnPTeamsUser`, Graph `POST /teams/{id}/members` | **Sends** activity-feed entry | **Not suppressible** via any documented API. Workaround: add via M365 Group + off-hours + prebrief | `MemberAdded` (UAL) | n/a |
| 21 | Teams channel create (standard) | `Add-PnPTeamsChannel`, Graph `POST /teams/{id}/channels` | **Sends** activity-feed entry to all team members | Not suppressible (docs silent; no param) | `ChannelAdded` (UAL) | n/a |
| 22 | Teams private channel member add | Graph `POST /teams/{id}/channels/{id}/members` | **Sends** activity-feed entry to added user | Not suppressible | Same as #20 | n/a |
| 23 | Teams channel moderation PATCH (BETA per ADR-009) | `PATCH /beta/teams/{id}/channels/{id}` `moderationSettings` | **Docs silent** on notification behavior | Empirical canary required (see §4.5) | `ChannelSettingChanged` (UAL) | n/a |
| 24 | Teams app install via setup policy | Teams admin center, `POST /users/{id}/teamwork/installedApps` | **Silent** | No suppression needed | `TeamsAppInstalled` (UAL) | n/a |
| 25 | "Welcome to Teams" first-run card | First-time-in-team experience | **Sends, unsuppressible** | No tenant control documented; Microsoft product gap | n/a | n/a — accept the artifact |
| 26 | Audience targeting on web part | `Set-PnPPageWebPart`, modern page editor | **Silent** — visibility metadata only | No suppression needed | n/a | n/a |
| 27 | Hub-site association | `Add-PnPHubSiteAssociation` | **Silent** | No suppression needed | `HubSiteJoined` (UAL) | n/a |
| 28 | Theme deployment | `Add-PnPTenantTheme`, `Set-PnPTenantTheme`, `Set-PnPWebTheme` | **Silent** — theme just appears in picker | No suppression needed | `ThemeUpdated` (UAL) | n/a |
| 29 | Brand Center font deployment | `Add-PnPBrandCenterFont(Package)`, `Use-PnPBrandCenterFontPackage` | **Silent** | No suppression needed | n/a | n/a |
| 30 | SPFx app catalog upload + publish | `Add-PnPApp`, `Publish-PnPApp`, `Install-PnPApp`, `Sync-PnPAppToTeams` | **Silent to users** (admin-side modal only on `-SkipFeatureDeployment`) | No suppression needed | `AppCatalogAppAdded` (UAL) | n/a |

---

## 4. Per-surface deep dives (top 5 highest risk)

### 4.1 Microsoft 365 Group creation + member add (the HTT-52 root cause)

**Trigger.** The "Welcome to `<group>`" email is sent by **Exchange Online** — not by Graph, not by SharePoint — whenever a user becomes a member of a group whose `UnifiedGroupWelcomeMessageEnabled` is `$true`. It fires on every member-add path: `New-PnPMicrosoft365Group -Members`, `Add-PnPMicrosoft365GroupMember`, Graph `POST /groups` with `members@odata.bind`, Graph `POST /groups/{id}/members/$ref`, and the Entra UI.

**The two suppression layers (you need BOTH for guests).**

1. **At creation only** — `resourceBehaviorOptions: ["WelcomeEmailDisabled", "HideGroupInOutlook"]`. Microsoft Learn quote: *"These behaviors can be set only on group creation."* You cannot PATCH this in later.
   - Source: <https://learn.microsoft.com/en-us/graph/group-set-options#configure-groups>
2. **Post-hoc** — `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled:$false` (Exchange cmdlet, default is `$true`).
   - Source: <https://learn.microsoft.com/en-us/powershell/module/exchange/set-unifiedgroup?view=exchange-ps#-unifiedgroupwelcomemessageenabled>

**The guest-user trap** (critical for DCE↔HTT). Verbatim from the Exchange docs:
> *"Guest user accounts are always subscribed when added as a member. You can manually remove subscriptions for guest users by using the Remove-UnifiedGroupLinks cmdlet."*

This is almost certainly why HTT users hit the welcome path even if `autoSubscribeNewMembers:$false` was set: HTT users land in DCE as `Guest` userType (until MTO join — see bd `DeltaSetup-a3d`), which **overrides** the autosubscribe setting. The only reliable suppression is `WelcomeEmailDisabled` at creation time.

**Canonical safe creation pattern (Graph).**

```http
POST /v1.0/groups
{
  "displayName": "Crown Connection",
  "mailNickname": "CrownConnection",
  "description": "...",
  "groupTypes": ["Unified"],
  "mailEnabled": true,
  "securityEnabled": false,
  "visibility": "Private",
  "resourceBehaviorOptions": ["WelcomeEmailDisabled", "HideGroupInOutlook"],
  "owners@odata.bind": ["..."],
  "members@odata.bind": ["..."]
}
```

**Canonical safe creation pattern (PnP).**

```powershell
New-PnPMicrosoft365Group `
  -DisplayName "Crown Connection" `
  -Description "..." `
  -MailNickname "crown-connection" `
  -Owners $owners `
  -Members $members `
  -IsPrivate `
  -ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook
```

For groups that already exist without `WelcomeEmailDisabled`, run immediately before any member-add:

```powershell
Set-UnifiedGroup -Identity "Crown Connection" -UnifiedGroupWelcomeMessageEnabled:$false
```

**Order matters.** Suppression must precede the add.

**Launch-day mechanism.** No Microsoft API "fires welcome later." Send a curated email via `Send-PnPMail` / Comms.

### 4.2 Entra B2B guest invitations

**Trigger.** `POST /invitations` (or `New-MgInvitation`). The `sendInvitationMessage` Boolean controls whether the email goes out. Default = **`false`** in v1.0 and beta. Source: <https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-1.0>

**Why we still set it explicitly.** Several legacy SDKs (old AzureAD module, some preview `Microsoft.Graph` releases) defaulted to `true`. Pinning `sendInvitationMessage: false` in every call defends against SDK drift.

**The `inviteRedeemUrl` is always returned**, even when `sendInvitationMessage: false`. So scaffold-mode provisioning still gets the URL back and can hand it to launch-day comms.

**Member vs Guest.** Same endpoint, just set `invitedUserType: "Member"` (requires directory-admin role). Same suppression semantics.

**Canonical safe pattern (existing DCE pattern — already compliant).** The existing `tools/invite-htt-users-to-dce.py` is **already correct**:

```python
{
    "invitedUserEmailAddress": email,
    "inviteRedirectUrl": "https://...",
    "sendInvitationMessage": False,   # ← already correct
    "invitedUserType": "Guest",
}
```

**Launch-day mechanism.** Re-POST `/invitations` for the same email with `sendInvitationMessage: true` and a curated `invitedUserMessageInfo.customizedMessageBody`. Microsoft documents the re-POST/reset pattern explicitly.

### 4.3 Entra cross-tenant synchronization (HTT-to-DCE-User-Sync)

**Is cross-tenant sync noisy?** No. **Silent by design.** Verbatim from <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview#when-is-the-consent-prompt-suppressed>:

> *"For cross-tenant synchronization, users don't receive an email or have to accept a consent prompt. […] Cross-tenant synchronization uses a feature that improves the user experience by suppressing the first-time B2B consent prompt and redemption process in each tenant."*

**Policy schema has no notification property.** `crossTenantIdentitySyncPolicyPartner` exposes exactly three writable properties: `displayName`, `tenantId`, `userSyncInbound`. No `sendNotification`, no `notifyUser`, no `welcomeMessage`. Confirmed against v1.0 schema.

**The "notification" terms you'll find in cross-tenant-sync docs refer to ADMIN failure alerts**, not user-facing emails. The "Notification Email" field in the provisioning job config is for sync-quarantine alerts to operators. Verify the recipient there is your sync operator inbox (Tyler / IT), not a distribution list that loops back.

**MTO membership effect (DeltaSetup-a3d open question).** Joining an MTO does **NOT** add user-facing provisioning emails. What it does:

- Promotes synced HTT users from `Guest` → `Member` userType, which **removes the guest-user autosubscribe trap** (§4.1). This is a positive notification-quietness side effect of MTO membership and should be a pro factor in DeltaSetup-a3d.
- Improves cross-tenant Teams notifications (meeting start, chat) — these are *operational improvements*, not provisioning-noise additions.

**Where docs are silent** (called out for transparency):

- Does flipping `userSyncInbound` off-and-on re-fire any mail? Docs silent. Recommend empirical pilot test before any production flip.
- Does a downstream group-add fire welcome mail on a freshly-synced user? **Yes**, if the group has welcome enabled — but the mail is from the *group-add*, not from xtsync. This is the misattribution pattern.

**Recommended empirical canary** before any large HTT cohort sync:

1. Create test user `xtsync-canary-1@httbrands` with a monitored mailbox.
2. Verify DCE-side target group has `WelcomeEmailDisabled` + `UnifiedGroupWelcomeMessageEnabled:$false`.
3. Run xtsync. Confirm zero user-facing mail at canary.
4. Trigger `Add-PnPMicrosoft365GroupMember` for the synced user. Confirm zero welcome.
5. Re-run with welcome enabled to verify the suppression is what's actually doing the work.

### 4.4 SharePoint site/file/library sharing

**The most important finding.** The cmdlets you may have suspected of causing HTT-52 **could not have caused it**:

- `Set-PnPSitePermissions` — **doesn't exist** as a cmdlet name. The real cmdlets (`Set-PnPWebPermission`, `Set-PnPListItemPermission`, `Set-PnPFolderPermission`) have **no `-SendEmail` parameter at all**. They are silent by design.
- `Add-PnPSiteCollectionAdmin`, `Grant-PnPHubSiteRights`, `Set-PnPTenantSite -Owners` — all silent.

**The actual culprits** (in priority order):

1. **`Add-PnPFileSharingInvite -SendInvitation`** / **`Add-PnPFolderSharingInvite -SendInvitation`** with the switch explicitly passed. **⚠ PnP documentation defect**: the prose description on `pnp.github.io` reads *"Specifies if an email or post is generated (false) or if the permission is just created (true)"* — this is **inverted** relative to the parameter name, Example 2 in the same doc, and the underlying Graph `sendInvitation` semantics. **Trust the parameter name and the Graph contract**: `-SendInvitation` present ⇒ email is sent.
2. **Direct Graph `POST /drives/{id}/items/{id}/invite` with `sendInvitation: true`** in the body.
3. **`Add-PnPGroupMember -EmailAddress … -SendEmail`** on the External parameter set.

**Defensive contract.** In every provisioning script, set the Graph body explicitly even though the schema default is correct:

```json
{
  "recipients": [{ "email": "user@httbrands.com" }],
  "requireSignIn": true,
  "sendInvitation": false,
  "roles": ["read"],
  "retainInheritedPermissions": true
}
```

**The legacy footgun.** `_api/SP.Web.ShareObject` defaults `sendEmail` to `true` (opposite of every modern API). **Avoid this endpoint entirely**; lint for it in CI (§5).

**Partial-success gotcha.** When `/invite` is called with multiple recipients and email delivery fails for some, Graph returns HTTP 207 with per-recipient errors. **The permission is still granted even when email fails — no rollback.** So a failed email does not save you from a botched scaffold operation.

**App-only auth limitation.** New guests **cannot** be invited via app-only `/invite` (existing guests OK). Our `dce-sharepoint-deploy` app cannot brand-new-invite guests; we must pre-provision the guest object via `/invitations` first or use a different identity for that path.

**Launch-day mechanism.** Re-call `Add-PnPFileSharingInvite -SendInvitation -Message "<curated>"` OR (preferred) send a branded mail via `Send-PnPMail` / Power Automate that references the already-granted permission.

### 4.5 Teams team + channel + member add

**The brutal headline.** Microsoft Graph and Teams PowerShell do **NOT** expose any documented switch, header, or query parameter to suppress the in-product **Teams activity-feed entry** ("X added you to Team Y") when adding members through `POST /teams/{id}/members` or `POST /teams/{id}/channels/{id}/members`. Verified across v1.0 and beta on 2026-05-16. The "change notifications" wording on the Graph reference page is the developer-webhook subscription API, **not** user-facing toasts.

**What CAN be suppressed:**

| Surface | Suppression | Where |
|---------|-------------|-------|
| M365 Group welcome email to new Teams members | `resourceBehaviorOptions: ["WelcomeEmailDisabled"]` on **group create** | Graph `POST /groups` body, or `New-PnPTeamsTeam -ResourceBehaviorOptions WelcomeEmailDisabled` |
| M365 Group conversation auto-subscribe (email) | `autoSubscribeNewMembers: false` (default) | Set via PATCH after create |
| Group visible in Outlook | `resourceBehaviorOptions: ["HideGroupInOutlook"]` | Same as welcome-email row |

**What CANNOT be suppressed (be honest in the ADR):**

- The in-product Teams activity-feed entry on member add.
- The Teams desktop toast on member add (gated by per-user settings, not by caller).
- The first-run "Welcome to the team" card on first open. No tenant policy exists.

**`visibleHistoryStartDateTime` is NOT a notification control.** It controls how much *channel history* a new member can see. Do not propose it as a workaround — that is folklore.

**Owner-vs-Member notification differential.** Microsoft docs **do not document** any difference. Treat any internal runbook that says "owners aren't notified" as folklore until empirically re-tested each Teams release. The only documented difference is the `roles` array value (`["owner"]` vs `[]`) and the required permission scope (`TeamMember.ReadWrite.All` for owners).

**Architectural workaround for at-scale silent provisioning** (the only path the docs actually support):

1. Pre-create the underlying M365 Group with `resourceBehaviorOptions: ["WelcomeEmailDisabled", "HideGroupInOutlook"]` and `autoSubscribeNewMembers: false`.
2. Add members to the **group's** members collection, not via the Teams membership API:

   ```http
   POST /groups/{group-id}/members/$ref
   { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/{user-id}" }
   ```

3. Schedule the team enablement (`POST /teams` from the group) for **off-hours** with a pre-briefed user cohort.

**Honest caveat.** This suppresses the *welcome email* and the *email auto-subscription*. It does **NOT** reliably suppress the Teams activity-feed entry once the Teams membership service reconciles the group change. There is no documented zero-notification path. Accept the activity-feed entry, mitigate the email/Outlook noise, and prebrief the affected cohort.

**Channel moderation PATCH (ADR-009).** Microsoft Learn is **silent** on whether `PATCH /beta/teams/{id}/channels/{id}` `moderationSettings` fires a member-visible activity-feed entry. **Empirical canary required** before flipping moderation tenant-wide for Crown Connection / Phase 5 brand teams. Document the empirical result as an addendum to ADR-009.

---

## 5. Fitness function patterns (pytest, in `tests/architecture/`)

A new test module `tests/architecture/test_notification_suppression.py` enforces all ADR-011 invariants at static-analysis time. Full source persisted in this repo. The tests are pure regex / AST scanning — no live tenant calls — so they run in <1s and slot into the existing `pr-validation.yml` workflow next to the existing ADR-001/002/004 fitness tests.

Four test groups:

1. **TestSuppressByDefault** — no provisioning file may contain `-SendInvitation`, `-SendEmail`, `"sendInvitation":true`, `"sendEmail":true`, `sendInvitationMessage = $true`, `-UnifiedGroupWelcomeMessageEnabled:$true`, or `-UpdateType UpdateOverwriteVersion` in non-comment lines.
2. **TestSuppressionMechanismsPresent** — every `New-PnPMicrosoft365Group` / `New-PnPTeamsTeam` / Graph `POST /groups` includes `WelcomeEmailDisabled` in `resourceBehaviorOptions`; every `New-MgInvitation` includes `-SendInvitationMessage:$false`; every Python `/invitations` POST sets `sendInvitationMessage: False`.
3. **TestModeSignal** — every PowerShell/Python provisioning script declares a `-Mode {scaffold|launch}` parameter and logs `PROVISIONING-MODE:` at startup.
4. **TestLaunchScriptsAreSeparate** — files matching `**/*launch*.{ps1,py,sh}` carry the `# DCE-LAUNCH-MODE: APPROVED` marker in their first 20 lines.

See [`tests/architecture/test_notification_suppression.py`](../../tests/architecture/test_notification_suppression.py) for the full implementation.

---

## 6. ADR-011 (separate file)

See [`decisions/011-notification-suppression-by-default.md`](./decisions/011-notification-suppression-by-default.md).

---

## 7. `bootstrap.sh` + workflow refactor proposal

The current `dce-mockup/ci-cd/scripts/bootstrap.sh` provisions the Entra app, grants Graph + SharePoint permissions, and prints GitHub secrets. It does NOT install or verify any of the suppression invariants. The refactor below bakes the suppression-by-default rule into the pipeline so that *a forgetful or malicious operator cannot skip it*.

Detailed YAML/PowerShell patches are tracked in bd `DeltaSetup-<TBD-suppression-rollout>` and will be applied as part of the ADR-011 rollout commit. Summary:

- **`bootstrap.sh`** gains a **Step 9** that verifies tenant-wide suppression posture (SharePoint sharing capability, M365 Group welcome flags) and warns on any group still hot.
- **`dce-mockup/ci-cd/scripts/remediate-group-welcome.ps1`** — new idempotent script that disables `UnifiedGroupWelcomeMessageEnabled` on every existing M365 Group. Required because `resourceBehaviorOptions` is creation-only.
- **`dce-mockup/ci-cd/workflows/pr-validation.yml`** gains a step running `pytest tests/architecture/test_notification_suppression.py` after schema validation.
- **`dce-mockup/ci-cd/workflows/deploy-prod.yml`** gains the same pytest step as a pre-deploy gate.
- **`dce-mockup/ci-cd/workflows/provision-teams.yml`** passes `-Mode scaffold` explicitly and uploads `provisioning-mode.log` as a CI artifact with 365-day retention.
- **`dce-mockup/ci-cd/workflows/launch-notifications.yml`** — NEW separate workflow, `workflow_dispatch`-only, gated by a `launch` GitHub Environment with required reviewers. This is the ONLY place where `-Mode launch` may run.

---

## 8. Retro / audit playbook for the historical HTT-52 incident

**🔴 Time-critical: `Get-MessageTrace` retention is 10 days.** Incident window opened 2026-05-12. Hard forensic deadline = **2026-05-22**. Run §8.1 today.

### 8.0 Tenant SKU and retention budgets (READ FIRST)

Per release-gate-arbiter STRIDE co-sign of ADR-011 (Repudiation row addendum, 2026-05-16): every retention claim in this playbook MUST be pinned to the actual tenant SKU rather than asserted in the abstract. The §8.1–§8.5 queries below depend on these budgets being accurate.

**Tenant of record:** `deltacrown` — **Microsoft 365 Business Premium**.

_Authoritative source: `README.md` line 4, `DEPLOYMENT-RUNBOOK.md` line 189, and the public marketing page (`index.html`). The license-inventory document (`docs/delta-crown-security-apps-licenses-inventory-summary.md`) notes the seat-count detail (6 consumed Business Basic-style licenses on top of the Business Premium subscription); for retention budgets, the relevant fact is that the tenant is non-E5._

**Retention budget table:**

| Surface | Retention on Business Premium | Source / how to verify |
|---|---|---|
| `Get-MessageTrace` (Exchange Online) | **10 days** synchronous; **90 days** async via `Start-HistoricalSearch` | Microsoft Purview / EXO docs — universal across all SKUs |
| Unified Audit Log (UAL) | **180 days** default | Non-E5 SKUs (Business Premium, Business Standard, E3) get 180d; E5 gets 365d; E5 + Audit Premium add-on gets 10 years. Verify in Purview portal → Audit → Search audit log retention policies |
| Entra ID sign-in / audit logs | **30 days** (Free / P1); **30 days** also on P2 unless exported | Business Premium includes Entra ID P1 by default; one P2 license is provisioned and available |
| Microsoft Purview Content Search | **No expiry** while the search exists; exports retained until manually deleted | HTT-tenant-owned in this incident |
| GitHub Actions workflow artifacts | **90 days** (Team plan); **400 days** (Enterprise) — set per artifact via `retention-days:` | GitHub plan-dependent; verify org plan tier in `Settings → Billing` |
| `provisioning-mode.log` artifact retention | **90 days** in CI; **off-platform mirror to S3/Blob required** for the ADR-011 long-term audit retention claim | See ADR-011 §STRIDE Repudiation addendum |

**What this means for the §8.1–§8.5 queries:**

- **§8.1 (Message Trace) is hard-bounded at 10 days from incident date.** Incident opened 2026-05-12, so the synchronous-query deadline is 2026-05-22. After that, the **same data is still recoverable** via `Start-HistoricalSearch` (90-day window, results delivered async as a CSV) — meaning the absolute hard deadline for any Message Trace recovery is **2026-08-12**.
- **§8.2 (UAL) gives us until 2026-11-12** (180 days from 2026-05-15, the last UAL-visible day of the incident). After that, this incident's UAL evidence is permanently lost.
- **§8.3 (Purview Content Search) has no time pressure on its own** — but it depends on the recipient mailboxes still being licensed and intact in the HTT tenant. If an HTT user is offboarded and their mailbox purged before the search runs, the bodies are gone regardless of Purview retention.
- **`provisioning-mode.log` artifacts** uploaded by `provision-teams.yml` and `deploy-prod.yml` runs from the incident window age out of GitHub at **2026-08-10** (90 days from the 2026-05-12 run date). If you need them after that, retrieve and mirror them off-platform before the 90-day mark.

**Action items derived from this section** (filed as ADR-011 Acceptance Criteria under bd `DeltaSetup-17i`):

- [ ] Decide whether the ADR-011 365-day retention claim for `provisioning-mode.log` is satisfied by 90-day artifact + permanent off-platform mirror, or whether the GitHub org plan must be upgraded to Enterprise (400-day artifact retention).
- [ ] Schedule a Q3 2026 sweep to export and mirror any 2026-05 UAL evidence before the 180-day mark expires (≈2026-11-12).
- [ ] If DCE ever holds PII/PHI/PCI, this section is revisited and the SKU may need to move to E5 + Audit Premium for the 10-year audit retention.

### 8.1 Pull the smoking gun (Message Trace) — TODAY

```powershell
Connect-ExchangeOnline -UserPrincipalName tyler.granlund@httbrands.com

Get-MessageTrace `
    -StartDate "2026-05-12 00:00:00Z" `
    -EndDate   "2026-05-15 23:59:59Z" `
    -SenderAddress @(
        "no-reply@sharepointonline.com",                # SharePoint sharing
        "MicrosoftOffice365@email.microsoftonline.com", # M365 Group welcome
        "no-reply@microsoft.com",                       # B2B invite
        "invites@microsoft.com",                        # legacy B2B invite
        "noreply@email.teams.microsoft.com"             # Teams add
    ) `
    -PageSize 5000 |
    Where-Object { $_.RecipientAddress -like "*@httbrands.com" -or
                   $_.RecipientAddress -like "*@httbrands.onmicrosoft.com" } |
    Export-Csv ./out/dce-incident-messagetrace.csv -NoTypeInformation
```

For any event after 2026-05-22, fall back to async `Start-HistoricalSearch` (90-day window, results delivered as CSV email in 1–24h).

### 8.2 Pull the audit-log trail (Unified Audit Log — 180-day retention)

Run all four queries in parallel:

| Surface | Operations to filter |
|---------|---------------------|
| M365 Group adds | `Add member to group`, `AddMemberToGroup` |
| B2B invitations | `Invite external user`, `UserInvited` (also pull `additionalDetails.sendInvitationMessage`) |
| SharePoint shares | `SharingInvitationCreated` (always emails), `SharingSet`, `AddedToSecureLink`, `SecureLinkCreated`, `AnonymousLinkCreated`, `CompanyLinkCreated` |
| Teams adds | `TeamCreated`, `ChannelAdded`, `MemberAdded`, `MemberRoleChanged` |

**Actor correlation** — for app-only flows, `UserId` in the SharePoint workload is the literal string `app@sharepoint` (NOT unique per app). The only reliable disambiguator is `ApplicationId` (the appId GUID).

For the HTT-52 incident, the actor was `tyler.granlund@httbrands.com` running `tools/provision-crown-connection.sh` (delegated `az` CLI session, not app-only) and `tools/expand-crown-connection-htt-corp.py` (Graph user-token auth). Filter the UAL by `UserId in ('tyler.granlund@httbrands.com', 'tyler.granlund@httbrands.onmicrosoft.com')`.

### 8.3 Retrieve email bodies (Purview Content Search)

Must run in the **HTT tenant**, not DCE — recipient mailboxes live there. Run by the HTT compliance officer with `eDiscovery Manager` role.

```powershell
Connect-IPPSSession
New-ComplianceSearch `
    -Name "DCE-Incident-2026-05-Welcome-Mails" `
    -ExchangeLocation (Get-Content ./affected-users.txt) `
    -ContentMatchQuery @'
(from:no-reply@sharepointonline.com OR
 from:MicrosoftOffice365@email.microsoftonline.com OR
 from:invites@microsoft.com OR
 from:noreply@email.teams.microsoft.com)
AND received>=2026-05-12 AND received<=2026-05-15
'@
Start-ComplianceSearch -Identity "DCE-Incident-2026-05-Welcome-Mails"
New-ComplianceSearchAction -SearchName "DCE-Incident-2026-05-Welcome-Mails" -Export -Format Fxstream
```

### 8.4 Blast-radius artifact schema

Produce a CSV `out/incident-blast-radius.csv` with one row per (recipient × email):

| Column | Type | Description |
|---|---|---|
| `recipient_upn` | string | The HTT user who received mail |
| `recipient_displayname` | string | For human reading |
| `email_subject` | string | The mail subject line |
| `email_sender` | string | One of the senders from §8.1 |
| `received_utc` | ISO8601 | From Message Trace |
| `provisioning_action` | string | The UAL operation that caused it |
| `provisioning_commit` | string | The git SHA (one of 834f516 / 1cad240 / a6dd3f5) |
| `apology_sent_utc` | ISO8601 | Filled in during §8.5 |

Retain 7 years (SOX-aligned) under `research/notification-suppression/raw-findings/` (directory to be created at audit time).

### 8.5 Apology + remediation

1. **Pause all provisioning runs** — pin `provision-teams.yml`, `deploy-prod.yml` to `workflow_dispatch` only until ADR-011 is accepted and fitness functions are green.
2. **Apologize via curated email**, sent from a recognizable sender (Tyler's mailbox or a branded `it-comms@deltacrown.com`), per the blast-radius CSV mail-merge.
3. **Run `scripts/remediate-group-welcome.ps1 -Mode scaffold`** to disable `UnifiedGroupWelcomeMessageEnabled` on every existing M365 Group (post-hoc fix for groups that were created without `WelcomeEmailDisabled`).
4. **Already filed as bd issues:**
   - HTT-52 incident retro + apology mail-merge (`DeltaSetup-<TBD>`)
   - ADR-011 acceptance gate (`DeltaSetup-<TBD>`)
   - PnP upstream doc-defect (`DeltaSetup-<TBD>`)
   - Empirical canaries: xtsync + channel-moderation (`DeltaSetup-<TBD>`)
   - Quarterly "your access" digest (compensating control for STRIDE EoP residual) (`DeltaSetup-<TBD>`)

---

## Appendix A — Cross-references

- ADR-007 — Cert-based auth (the identity that performs all of the above)
- ADR-008 — DCE↔HTT corporate sync group naming
- ADR-009 — Teams moderation BETA endpoint (channel-moderation notification behavior is still TBD — empirical canary required)
- ADR-011 — Notification suppression by default (this playbook's companion ADR)
- `02-identity-audience.md` — DCE↔HTT identity model (note the Guest userType implication for §4.1's guest-user trap)
- `05-permissions-model.md` — Permission grant flow (now extended with the scaffold-vs-launch mode signal)
- `09-deployment.md` — Deployment flow (now extended with the launch-notifications workflow)
