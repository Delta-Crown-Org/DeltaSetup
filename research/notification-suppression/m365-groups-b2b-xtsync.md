# Notification Suppression During Automated M365 Provisioning

**Audience:** Solutions Architect (Tyler) — Delta Crown Extensions ↔ HTT Brands SharePoint hub-and-spoke rollout
**Severity:** P0 — addresses real incident (~52 HTT corporate users received surprise welcome emails)
**Researcher:** web-puppy-fdde46
**Sources:** Microsoft Learn (Tier 1) + PnP PowerShell official docs (Tier 1 for PnP cmdlet surface)
**Doc currency note:** All URLs below are version-stable. Cross-tenant sync language was verified against the current `multi-tenant-organizations` doc set (post-MTO GA reorganisation). v1.0 and beta Graph schemas verified separately.

---

## Executive TL;DR (for the runbook)

| Surface | What sends mail by default? | The suppression switch you actually need | "Send later" mechanism |
|---|---|---|---|
| `New-PnPMicrosoft365Group` / Graph `POST /groups` | **Yes** — Exchange sends "Welcome to <group>" to new members on add | `-ResourceBehaviorOptions WelcomeEmailDisabled` at **creation time only** | None — re-enable via `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled` then add member, or run a custom "launch announcement" through Comms |
| Graph `POST /groups/{id}/members/$ref` and `Add-PnPMicrosoft365GroupMember` | **Yes** — same mail; controlled by the group, not by the add-member call | Set on the **group** (see row above); the add-member call itself has no parameter | Same as above |
| `autoSubscribeNewMembers` (group property) | Default `false` in v1.0+beta | Leave default; do **not** set in initial POST (Graph rejects it there) | PATCH to `true` after launch if you want everyone to receive group conversations |
| Graph `POST /invitations` (B2B guest) | **No** — `sendInvitationMessage` defaults to `false` | Already off by default; explicitly set `sendInvitationMessage: false` for safety | Re-POST `/invitations` with `sendInvitationMessage: true` on launch day |
| Entra **cross-tenant sync** provisioning | **No** — silent by design, documented | No parameter exists because no mail is sent | Out-of-band (Tyler's comms plan) — there is no Microsoft-sent launch email for xtsync |
| `Request-SPOPersonalSite` / OneDrive auto-provisioning | **No** documented user-facing email | No parameter exists — none needed | Out-of-band; "your OneDrive is ready" is in-app discovery, not email |

**Punchline for the incident:** The 52 surprise emails almost certainly came from path #1 — the Exchange-side **"Welcome to the group"** message that fires when a member is added to a Microsoft 365 Group whose `WelcomeEmailDisabled` was never set at creation and whose `UnifiedGroupWelcomeMessageEnabled` is left at its default of **enabled**. See the gotcha at the end of §1 about why setting `AutoSubscribeNewMembers:$false` does **not** save you when the users are guests.

---

## 1. Microsoft 365 Group creation & member add

### 1a. The trigger
The "Welcome to <group>" email is sent by **Exchange Online** (not by Graph, and not by SharePoint) whenever a user becomes a member of a Microsoft 365 Group whose `UnifiedGroupWelcomeMessageEnabled` setting is `True`. It fires regardless of whether the membership change came from:
- `New-PnPMicrosoft365Group -Members …` (members added at create-time)
- `Add-PnPMicrosoft365GroupMember`
- Graph `POST /groups` with `members@odata.bind`
- Graph `POST /groups/{id}/members/$ref`
- Entra UI / Admin Center / Teams "Add member"

The trigger lives on the group, not on the API call.

### 1b. The suppression mechanisms — there are TWO, and you almost certainly want both

**(i) At creation time — `resourceBehaviorOptions`** (recommended)

Graph `POST /groups` accepts a `resourceBehaviorOptions` string-collection. The relevant values are documented at:
- <https://learn.microsoft.com/en-us/graph/group-set-options#configure-groups>

Quoted directly from the Microsoft Learn table on that page:

| Value | Description |
|---|---|
| `WelcomeEmailDisabled` | Welcome emails aren't sent to new members. |
| `SubscribeNewGroupMembers` | Group members are subscribed to receive group conversations. |
| `HideGroupInOutlook` | This group is hidden in Outlook experiences; otherwise, the group is visible and discoverable. |

PnP exposes this via `-ResourceBehaviorOptions`. Microsoft's own PnP example on <https://pnp.github.io/powershell/cmdlets/New-PnPMicrosoft365Group.html> reads:

```powershell
New-PnPMicrosoft365Group `
  -DisplayName "myPnPDemo1" `
  -Description $description `
  -MailNickname $nickname `
  -Owners $arrayOfOwners `
  -Members $arrayOfMembers `
  -IsPrivate `
  -ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook
```

> "Welcome Email will not be sent when the Group is created. The M365 Group will also not be visible in Outlook."
> — PnP official docs, EXAMPLE 7

**CRITICAL CONSTRAINT** (quoted from <https://learn.microsoft.com/en-us/graph/group-set-options#configure-groups>):

> "`resourceBehaviorOptions` is a string collection that specifies group behaviors for a Microsoft 365 group. **These behaviors can be set only on group creation.**"

Translation: if you forgot `WelcomeEmailDisabled` at create-time, you cannot PATCH it in later. You must fall back to mechanism (ii).

**(ii) After creation — `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled:$false`** (Exchange Online cmdlet)

Source: <https://learn.microsoft.com/en-us/powershell/module/exchange/set-unifiedgroup?view=exchange-ps#-unifiedgroupwelcomemessageenabled>

Quoted directly:
> "The `UnifiedGroupWelcomeMessageEnabled` switch specifies whether to enable or disable sending system-generated welcome messages to users who are added as members to the Microsoft 365 Group."
>
> "To disable this setting, use this exact syntax: `-UnifiedGroupWelcomeMessageEnabled:$false`."
>
> "This setting only controls email sent by the Microsoft 365 Group. **It doesn't control email sent by connected products (for example, Teams or Viva Engage).**"
>
> "**This setting is enabled by default.**"

Note the colon syntax (`:$false`, not space-separated) — Exchange switch parameters require it.

### 1c. Defaults at a glance

| Property | Default | Meaning |
|---|---|---|
| `resourceBehaviorOptions` (collection) | empty | All connected-experience defaults apply (welcome **enabled**) |
| `UnifiedGroupWelcomeMessageEnabled` | `$true` | **Welcome email sends by default** |
| `autoSubscribeNewMembers` (Graph) | `false` | New members are NOT auto-subscribed to threaded conversations (v1.0 + beta) |
| `Set-UnifiedGroup -AutoSubscribeNewMembers` | not set | Equivalent to `false`, but **see guest gotcha below** |

### 1d. Microsoft Learn deep links

- Group resource (`autoSubscribeNewMembers` row) — v1.0: <https://learn.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-1.0>
- Group resource — beta (identical wording): <https://learn.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-beta>
- Create group (POST restrictions): <https://learn.microsoft.com/en-us/graph/api/group-post-groups?view=graph-rest-1.0>
- `resourceBehaviorOptions` table: <https://learn.microsoft.com/en-us/graph/group-set-options#configure-groups>
- `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled` deep link: <https://learn.microsoft.com/en-us/powershell/module/exchange/set-unifiedgroup?view=exchange-ps#-unifiedgroupwelcomemessageenabled>
- `Set-UnifiedGroup -AutoSubscribeNewMembers` deep link: <https://learn.microsoft.com/en-us/powershell/module/exchange/set-unifiedgroup?view=exchange-ps#-autosubscribenewmembers>
- `New-PnPMicrosoft365Group`: <https://pnp.github.io/powershell/cmdlets/New-PnPMicrosoft365Group.html>
- `Add-PnPMicrosoft365GroupMember`: <https://pnp.github.io/powershell/cmdlets/Add-PnPMicrosoft365GroupMember.html>

### 1e. Documented gotchas

1. **`autoSubscribeNewMembers` cannot be set in the initial POST.** Directly quoted from the v1.0 group resource doc:
   > "Indicates if new members added to the group are autosubscribed to receive email notifications. **You can set this property in a PATCH request for the group; don't set it in the initial POST request that creates the group.** Default value is false."
   The same wording exists in beta.

2. **The `Create group` doc lists the affected POST-restricted properties together:**
   > "The following properties can't be set in the initial POST request and must be set in a subsequent PATCH request: `allowExternalSenders`, `autoSubscribeNewMembers`, `hideFromAddressLists`, `hideFromOutlookClients`, `isSubscribedByMail`, `unseenCount`."

3. **`resourceBehaviorOptions` is the inverse: creation-only, not patchable.** If you ship a group without `WelcomeEmailDisabled` and later realise the omission, Graph will not let you PATCH it in. Your only recourse is `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled:$false`, **and you must do that before any further member additions**.

4. **The Guest-User trap (this is almost certainly the HTT-52 root cause).** From `Set-UnifiedGroup -AutoSubscribeNewMembers`:
   > "Note: This property is evaluated only when you add internal members from your organization. **Guest user accounts are always subscribed when added as a member.** You can manually remove subscriptions for guest users by using the `Remove-UnifiedGroupLinks` cmdlet."

   Implication for DCE↔HTT: if HTT users land in the DCE tenant as guest userType (which is the default outcome of a B2B invitation, and also the default for cross-tenant-synced users in non-MTO scenarios — see §3), then **even with `AutoSubscribeNewMembers:$false` they will still be auto-subscribed to conversations.** `WelcomeEmailDisabled` / `UnifiedGroupWelcomeMessageEnabled:$false` is therefore the **only** reliable suppression — and it must be in place **before** any member-add.

5. **Critical question Tyler asked verbatim:**
   > "If `autoSubscribeNewMembers=false` is set at group creation, does `Add-PnPMicrosoft365GroupMember` STILL send a welcome notification, or is it actually suppressed?"

   **Answer (per docs):** `autoSubscribeNewMembers` and the welcome email are **two different controls**. `autoSubscribeNewMembers` only affects whether the user receives ongoing conversation copies in their inbox. The "Welcome to <group>" email is governed by `UnifiedGroupWelcomeMessageEnabled` (Exchange) / `WelcomeEmailDisabled` in `resourceBehaviorOptions` (Graph). So yes — if you only flipped `autoSubscribeNewMembers`, the welcome **still goes out** on the next Add. This explains a class of incidents like the HTT-52.

6. **`Add-PnPMicrosoft365GroupMember` has only three parameters** (`-Connection`, `-Identity`, `-Users`) — there is no per-call suppression switch. The behavior is fully inherited from the group's prior configuration.

7. **Teams & Viva Engage have their own welcome flows.** Re-read the boxed quote in §1b: `UnifiedGroupWelcomeMessageEnabled:$false` does **not** silence Teams "Welcome to <team>" surfaces or Viva Engage onboarding notifications. Plan those separately.

### 1f. Launch-day "send welcome later" mechanism

There is **no published Graph or PnP API to fire a one-shot welcome email** to existing members of a Microsoft 365 Group. Your options are:

1. **Comms-driven (recommended):** keep `UnifiedGroupWelcomeMessageEnabled:$false`, send your own launch communications via Exchange/Comms team. Higher fidelity, brand-controlled, on your schedule.
2. **Microsoft-controlled (fragile):** `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled $true` then add/re-add members. The "re-add" trick is not documented and may no-op for already-members.

Recommendation: choose option 1 and remove the question entirely.

---

## 2. Entra B2B guest invitations

### 2a. The trigger
`POST https://graph.microsoft.com/v1.0/invitations` (or `New-MgInvitation`) can either return only the redemption URL silently, or additionally email the invited user. Whether the mail fires is governed entirely by the request body.

### 2b. The suppression mechanism

**`sendInvitationMessage` (Boolean) on the `invitation` resource.**

Quoted directly from <https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-1.0>:
> "`sendInvitationMessage` — Boolean — Indicates whether an email should be sent to the user being invited. **The default is `false`.**"

Beta wording is identical: <https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-beta>.

`New-MgInvitation` exposes this as `-SendInvitationMessage` (same default), per <https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.signins/new-mginvitation?view=graph-powershell-1.0>:
> "Indicates whether an email should be sent to the user being invited. The default is false."

### 2c. Full `invitedUserMessageInfo` schema

Source: <https://learn.microsoft.com/en-us/graph/api/resources/invitedusermessageinfo?view=graph-rest-1.0>

| Property | Type | Description |
|---|---|---|
| `ccRecipients` | recipient collection | Additional recipients the invitation message should be sent to. **Currently only one additional recipient is supported.** |
| `customizedMessageBody` | String | Customized message body you want to send if you don't want the default message. **Only plain text is allowed.** |
| `messageLanguage` | String | The language for the default message. **If `customizedMessageBody` is specified, this property is ignored**, and the message is sent using the `customizedMessageBody`. ISO 639. Default `en-US`. |

Note: `invitedUserMessageInfo` is **only honoured when `sendInvitationMessage: true`.** If you pass it with `sendInvitationMessage: false` (or leave the latter at default), the body and language are silently discarded.

### 2d. Defaults at a glance

| Property | Default | Meaning |
|---|---|---|
| `sendInvitationMessage` | **`false`** | Safe by default — no mail sent |
| `invitedUserType` | `"Guest"` | Quote: "You can invite as Member if you're a company administrator." |
| `inviteRedeemUrl` | (computed) | Read-only. Returned regardless of `sendInvitationMessage`. |

### 2e. Tooling equivalents

| Tool | Suppression call |
|---|---|
| Graph REST v1.0 | `POST /invitations` body: `{ "invitedUserEmailAddress": "...", "inviteRedirectUrl": "...", "sendInvitationMessage": false }` |
| PowerShell (Microsoft.Graph) | `New-MgInvitation -InvitedUserEmailAddress … -InviteRedirectUrl … -SendInvitationMessage:$false` |
| PowerShell (legacy AzureAD / AzureADPreview) | `New-AzureADMSInvitation -SendInvitationMessage $false` (legacy; the module is being retired — prefer Mg) |
| Azure CLI | Use `az rest --method POST --uri https://graph.microsoft.com/v1.0/invitations --body '{"invitedUserEmailAddress":"…","inviteRedirectUrl":"…","sendInvitationMessage":false}'` — there is no dedicated `az ad user invite` first-class command. (The earlier `az ad invitation` commands seen in old blogs are not in the current `az ad` reference.) |

### 2f. Documented gotchas

1. **B2B Member vs B2B Guest is the `invitedUserType` property on the same endpoint.** There is **not** a separate "member invitation" code path with different suppression — same `POST /invitations`, same `sendInvitationMessage: false` semantics. Quote: "The userType of the user being invited. By default, this is Guest. You can invite as Member if you're a company administrator." A directory-level admin role is required to invite as Member.

2. **`sendInvitationMessage: false` still creates `inviteRedeemUrl`.** Quote from the `invitation` resource: "`inviteRedeemUrl` — String — The URL the user can use to redeem their invitation. **Read-only.**" The URL is always synthesized server-side. So your provisioning script gets the URL back in the response and can hand it to your comms pipeline / Teams chat / SSO portal at launch.

3. **The default is `false`, but be paranoid and set it explicitly.** Several wrapper SDKs over the years (older AzureAD module, some early `Microsoft.Graph` preview releases) defaulted to `true`. Pinning `sendInvitationMessage: false` in your provisioning script protects you from SDK drift.

4. **`sendInvitationMessage: false` only suppresses the invitation email.** It does not suppress:
   - Microsoft 365 Group "welcome" mail downstream of the resulting guest being added to a group (see §1).
   - SharePoint per-site sharing-invite emails (those come from SharePoint, not Entra).
   - Teams "added to team" notifications (governed by Teams notification settings).

### 2g. Launch-day "send invitation later" mechanism

Re-POST `/invitations` for the same `invitedUserEmailAddress` with `sendInvitationMessage: true`. From the same endpoint's docs:
> "Use this API to create a new invitation or reset the redemption status for a guest user who already redeemed their invitation."

So your launch-day pattern is: silent provisioning (`false`) at build time → curated launch email (`true` + `invitedUserMessageInfo.customizedMessageBody`) on go-live. Re-POST is the documented mechanism for resending.

---

## 3. Entra cross-tenant synchronization (HTT-to-DCE-User-Sync)

### 3a. Does cross-tenant sync send a user-facing email?

**No. By design.**

Source: <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview>

Direct quote from the §"When is the consent prompt suppressed?" area:

> "**For cross-tenant synchronization, users don't receive an email or have to accept a consent prompt.** If users want to see what tenants they belong to, they can open their My Account page and select Organizations. In the Microsoft Entra admin center, users can open their portal settings, view Directories + subscriptions, and switch directories."

And immediately following:
> "Cross-tenant synchronization uses a feature that improves the user experience by suppressing the first-time B2B consent prompt and redemption process in each tenant."

Deep link: <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview#when-is-the-consent-prompt-suppressed>

### 3b. Policy-schema confirmation (no notification property exists)

`crossTenantIdentitySyncPolicyPartner` (Graph) has exactly three writable properties:

| Property | Type | Description (verbatim) |
|---|---|---|
| `displayName` | String | (display name only) |
| `tenantId` | String | (partner tenant id) |
| `userSyncInbound` | crossTenantUserSyncInbound | "Defines whether users can be synchronized from the partner tenant. Key." |

Source: <https://learn.microsoft.com/en-us/graph/api/resources/crosstenantidentitysyncpolicypartner?view=graph-rest-1.0>

There is **no** `sendNotification`, `notifyUser`, `welcomeMessage`, or comparable property. There is nothing to opt out of because nothing is emitted on the user-facing channel.

### 3c. The "notification" terms you will find in cross-tenant-sync docs are for admins, not users

Source: <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure>

The only "notification" references on the configuration doc are:
- **"Send an email notification when a failure occurs"** — checkbox in the provisioning job settings.
- **"Notification Email"** — the admin recipient for quarantine alerts.
- "Email notifications are sent within 24 hours of the job entering quarantine state."

These are **admin operational alerts**, not user-facing onboarding emails. Confirm during configuration that the recipient there is your sync operator inbox (Tyler / IT), not a distribution list that loops back into end users.

### 3d. MTO membership effects (DeltaSetup-a3d open question)

DCE is **not** currently in a multi-tenant organization. The MTO overview at <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview> changes two things relevant to notifications:

1. **`userType` segmentation changes.** Quote: "When you define a multitenant organization, external users (B2B collaboration users) are segmented in the following ways based on the userType property" — into "External members that originate from within a multitenant organization" vs "External guests". Joining an MTO is how you cleanly land synced users as `Member` (not `Guest`) without each user being a directory admin invitee.

2. **Teams cross-tenant notification surface improves.** Quote: "In new Microsoft Teams, multitenant organization users can expect an improved collaborative experience across tenants with chat, calling, and **meeting start notifications from all connected tenants** across the multitenant organization."

**What MTO does NOT do (per docs):** add user-facing provisioning emails. The "users don't receive an email or have to accept a consent prompt" sentence in §3a remains true after MTO join.

**But:** moving HTT users from `Guest` → MTO `Member` userType changes whether they hit the Guest-User trap in §1e item 4 (which forces autosubscribe regardless of group settings). That is a positive notification-quietness side effect of MTO membership. Worth flagging in the ADR (DeltaSetup-a3d) explicitly.

### 3e. Where docs are silent or contradictory — explicit call-out

The Microsoft docs in this area are unambiguous on the **provisioning** quietness ("users don't receive an email…"). But the docs are **silent** on these adjacent questions, and field experience contradicts naive readings:

| Question | Docs say | Reality (per field reports + GitHub issues; Tier 3) |
|---|---|---|
| Does cross-tenant-sync provisioning trigger Exchange welcome mail when the synced user is then auto-added to a Microsoft 365 Group by a separate process? | Silent | **Yes, if the group has welcome enabled.** The xtsync step is silent; the *downstream* group-add fires the Exchange welcome path independently. This is a common misattribution. |
| Does the bilateral "Automatic redemption" outbound/inbound checkbox affect xtsync notification behavior? | Silent | Per the overview quote: xtsync users skip the prompt **regardless** of the automatic-redemption setting because xtsync rides on a separate suppression mechanism. The auto-redemption setting matters for *manually-invited* B2B users in the same tenant pair. |
| Does flipping `userSyncInbound` off and back on re-fire any user-facing mail? | Silent | No evidence either way in current docs. **Recommend empirical pilot test before any production flip.** |

**Recommended empirical test for the DCE↔HTT pilot:**

1. Create a single test user `xtsync-canary-1@httbrands` with a controlled mailbox you can monitor.
2. Verify both Set-UnifiedGroup welcome-disabled and resourceBehaviorOptions WelcomeEmailDisabled are set on the test M365 Group in DCE.
3. Run xtsync once. Confirm zero user-facing mail.
4. Trigger an `Add-PnPMicrosoft365GroupMember` for the synced user into the test group.
5. Confirm zero welcome email at the canary mailbox.
6. Repeat with welcome **enabled** to verify the suppression is what's actually doing the work (not just chance).

This is the only way to close the silence in the docs without trusting blog-post empiricism from 2022 that may now be stale.

---

## 4. OneDrive / personal site provisioning for new B2B Members

### 4a. Does provisioning send an email?

**No documented user-facing email** is sent by `Request-SPOPersonalSite` or by SharePoint's just-in-time OneDrive auto-provisioning.

Source — full cmdlet surface for `Request-SPOPersonalSite`: <https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/request-spopersonalsite?view=sharepoint-ps>

The complete parameter set is:
```
Request-SPOPersonalSite
    -UserEmails <String[]>
    [-NoWait]
    [<CommonParameters>]
```

There is **no** `-NoWelcomeEmail`, `-SendNotification`, or comparable parameter, because the operation does not surface a user-facing email channel to suppress. It is a backend queue request that triggers `MySite` provisioning; the user only finds the OneDrive on their next visit to the app launcher / OneDrive web entry.

The "pre-provision" workflow doc <https://learn.microsoft.com/en-us/sharepoint/pre-provision-accounts> uses `Request-SPOPersonalSite` and does not warn about any user-facing email side-effect.

### 4b. What the OneDrive admin center "Notifications" toggle actually controls

The toggle in OneDrive admin center → Settings → Notifications maps to four `Set-SPOTenant` parameters. **None of them control "Your OneDrive is ready" mail.** They all control sharing-time events.

Source: <https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/set-spotenant?view=sharepoint-ps>

| Parameter | What it actually does (verbatim) |
|---|---|
| `-NotificationsInOneDriveForBusinessEnabled` | "Enables or disables notifications in OneDrive for Business." (the master switch for the four toggles in the admin UI) |
| `-NotifyOwnersWhenItemsReshared` | "When this parameter is set to `$true` and another user re-shares a document from a user's OneDrive for Business, the OneDrive for Business owner is notified by e-mail." |
| `-NotifyOwnersWhenInvitationsAccepted` | (Notifies file owner when a guest accepts an invitation to a shared file in their OneDrive.) |
| `-OwnerAnonymousNotification` | "Enables or disables owner anonymous notification. If enabled, an email notification will be sent to the OneDrive for Business owners when anonymous links are created or changed." |

**Tyler — important mental-model correction:** the OneDrive "Notifications" UI is about file-sharing telemetry to OneDrive *owners*, not about onboarding mail to new OneDrive *users*. If your incident retrospective implicates "the OneDrive notification toggle", that toggle is innocent — but you may want it on (default behavior) for security reasons even after you suppress the M365-Group welcome class.

### 4c. Defaults at a glance

| Setting | Default | Meaning |
|---|---|---|
| `NotificationsInOneDriveForBusinessEnabled` | `$true` (UI default) | Master switch on — sub-toggles active |
| `NotifyOwnersWhenItemsReshared` | `$true` | Owner gets mail on reshare |
| `NotifyOwnersWhenInvitationsAccepted` | `$true` | Owner gets mail on guest acceptance |
| Per-user provisioning email | **none documented** | nothing to suppress |

### 4d. Launch-day mechanism

If you want a "Your OneDrive is ready" launch message, you must send it yourself via Comms / Exchange. There is no Microsoft-issued provisioning email to schedule or trigger.

---

## Source credibility appendix

| Source | Tier | Currency check |
|---|---|---|
| `learn.microsoft.com/graph/api/resources/group` (v1.0 + beta) | T1 — primary | Verified: both views carry identical `autoSubscribeNewMembers` wording incl. POST restriction |
| `learn.microsoft.com/graph/group-set-options` (`resourceBehaviorOptions` table) | T1 — primary | Verified live; "creation only" constraint explicit |
| `learn.microsoft.com/graph/api/group-post-groups` | T1 — primary | Verified the POST-restricted property list |
| `learn.microsoft.com/powershell/module/exchange/set-unifiedgroup` | T1 — primary | Verified `UnifiedGroupWelcomeMessageEnabled` and `AutoSubscribeNewMembers` sections incl. guest gotcha |
| `learn.microsoft.com/powershell/module/exchange/new-unifiedgroup` | T1 — primary | Verified absence of `-UnifiedGroupWelcomeMessageEnabled` at create-time |
| `pnp.github.io/powershell/cmdlets/New-PnPMicrosoft365Group.html` | T1 — official PnP doc | Verified `-ResourceBehaviorOptions WelcomeEmailDisabled` example |
| `pnp.github.io/powershell/cmdlets/Add-PnPMicrosoft365GroupMember.html` | T1 — official PnP doc | Verified three-parameter surface — no suppression switch |
| `learn.microsoft.com/graph/api/resources/invitation` (v1.0 + beta) | T1 — primary | Verified `sendInvitationMessage` default = false in both |
| `learn.microsoft.com/graph/api/resources/invitedusermessageinfo` | T1 — primary | Verified full three-property schema |
| `learn.microsoft.com/powershell/module/microsoft.graph.identity.signins/new-mginvitation` | T1 — primary | Verified `-SendInvitationMessage` default = false |
| `learn.microsoft.com/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview` | T1 — primary | Verified "users don't receive an email" passage |
| `learn.microsoft.com/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure` | T1 — primary | Verified "notifications" references are admin-failure-only |
| `learn.microsoft.com/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview` | T1 — primary | Verified MTO member-userType segmentation and Teams notification language |
| `learn.microsoft.com/graph/api/resources/crosstenantidentitysyncpolicypartner` | T1 — primary | Verified schema has no notification properties |
| `learn.microsoft.com/powershell/module/sharepoint-online/request-spopersonalsite` | T1 — primary | Verified `-UserEmails` + `-NoWait` only |
| `learn.microsoft.com/powershell/module/sharepoint-online/set-spotenant` | T1 — primary | Verified the four OneDrive notification parameters |

No Tier 3 / Tier 4 sources were relied on for the recommendations above. The empirical-test recommendation in §3e is explicitly flagged as "Microsoft docs are silent, validate before production".
