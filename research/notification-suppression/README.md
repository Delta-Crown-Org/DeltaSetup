# Notification Suppression Research — Index

**Status:** P0 reference, current as of 2026-05-16
**Researchers:**
- `web-puppy-df3922` — Teams cluster (prevention)
- `web-puppy-7bc185` — SharePoint sharing / hub-and-spoke cluster (prevention)
- `web-puppy-972381` — Audit-log forensics cluster (retrospective investigation of the 52-user incident)
- `web-puppy-fdde46` — M365 Groups + B2B + Cross-tenant sync + OneDrive cluster (prevention; cross-tenant ↔ guest-userType interaction)

**Scope:** Microsoft 365 / Teams / SharePoint automated provisioning —
which surfaces fire user-visible notifications and how (or whether) to
suppress them.
**Triggers:** real notification-storm incident during DCE Teams rollout
**and** the SharePoint hub-and-spoke incident where ~52 users got
surprise sharing emails.

---

## Files in this directory

| File | Purpose |
|------|---------|
| [`teams.md`](./teams.md) | **Primary deliverable for the Teams cluster.** Full surface-by-surface analysis covering all 7 Teams surfaces the SA asked about. Inline Microsoft Learn citations. |
| [`sources.md`](./sources.md) | All Teams sources cited, with credibility assessments, last-updated timestamps, and which section each source backs. |
| [`recommendations.md`](./recommendations.md) | Teams-specific, prioritized P0 / P1 / P2 action items mapped to the DCE codebase (`provision-teams.ps1`, `dce-channels.json`, ADR-009). |
| [`sharepoint-sharing.md`](./sharepoint-sharing.md) | **SharePoint-cluster primary deliverable** (owner: 7bc185). All 7 SharePoint surfaces: permission grants, library/folder/item sharing + Graph `/invite`, hub-site association + audit-log proof, list-item alerts + Power Automate side-effects (`SystemUpdate` vs `UpdateOverwriteVersion`), audience targeting, Brand Center/themes, SPFx app catalog + tenant-wide deployment. |
| [`sources-sharepoint-sharing.md`](./sources-sharepoint-sharing.md) | SharePoint-cluster sources + credibility (owner: 7bc185). Includes the flagged PnP doc defect on `-SendInvitation`. |
| `raw-findings/` | Reserved for raw extracted content from Microsoft Learn pages (populated on demand for archival). |
| [`audit-forensics.md`](./audit-forensics.md) | **Forensics cluster (web-puppy-972381, 2026-05-16).** Audit-log forensics for the *retrospective* investigation of the 52-user notification storm (commits `834f516`, `1cad240`, `a6dd3f5`). Eight surfaces: Message Trace, Unified Audit Log (SP / Groups / Teams), Entra audit, B2B invite, app-only identity attribution, Purview Content search, and the blast-radius CSV/JSON schema. All Tier-1 Microsoft Learn citations. |
| [`incident-blast-radius.schema.json`](./incident-blast-radius.schema.json) | JSON Schema (Draft 2020-12) for the per-recipient evidence artefact produced by the forensics workflow. Validates both the mail-merge CSV (one row per `events[*]`) and the permanent JSON evidence envelope. |
| [`m365-groups-b2b-xtsync.md`](./m365-groups-b2b-xtsync.md) | **Groups+B2B+xtsync+OneDrive cluster primary deliverable** (owner: fdde46). All four surfaces: `New-PnPMicrosoft365Group` + `Add-PnPMicrosoft365GroupMember` + Graph `/groups` (incl. `resourceBehaviorOptions` and the create-only constraint), `POST /invitations` (`sendInvitationMessage` default + `invitedUserMessageInfo` schema), Entra cross-tenant sync (silent-by-design quote) + MTO impact on user-type segmentation, OneDrive provisioning + the correction that the OneDrive admin-center "Notifications" toggle is sharing-events not onboarding. Includes the **guest-user autosubscribe trap** that is almost certainly the HTT-52 root cause. |
| [`sources-groups-b2b.md`](./sources-groups-b2b.md) | Sources + credibility table for the Groups/B2B/xtsync/OneDrive cluster (owner: fdde46). |
| [`recommendations-groups-b2b.md`](./recommendations-groups-b2b.md) | Project-contextualised P0/P1/P2 actions for DCE↔HTT provisioning (owner: fdde46). Includes MTO-evaluation impact for DeltaSetup-a3d and a pilot canary protocol for cross-tenant sync. |

## Executive summary

1. **Welcome emails** to new M365 Group members ARE suppressible at
   group create time via `resourceBehaviorOptions: ["WelcomeEmailDisabled"]`
   (Graph) / `-ResourceBehaviorOptions WelcomeEmailDisabled` (PnP).
2. **In-product Teams activity-feed notifications** on member add are
   **NOT suppressible** through any documented Microsoft API. The
   docs do not provide a `suppressNotification` property, `Prefer:`
   header, or query parameter on `POST /teams/{id}/members` or
   `POST /teams/{id}/channels/{id}/members`.
3. **`visibleHistoryStartDateTime`** is a HISTORY VISIBILITY control,
   not a notification control — do not mistake it for one.
4. **Channel moderation PATCH** (the ADR-009 beta endpoint) — docs
   are silent on notification behavior. Empirical canary required.
5. **Teams app install via setup policy** is silent (no user prompt
   documented).
6. **Owner vs member** add: docs do **NOT** document any difference in
   notification behavior. Treat "owners aren't notified" as folklore
   until empirically verified.
7. **"Welcome to the team" first-run card**: no tenant control exists.
   This is a documented Microsoft product gap.

## SharePoint cluster — executive summary (added by 7bc185)

1. **`Set-PnPSitePermissions` does not exist** as a cmdlet — the real
   cmdlets (`Set-PnPWebPermission`, `Set-PnPListItemPermission`,
   `Set-PnPFolderPermission`) are **silent by design** and could not
   have caused the 52-email incident.
2. **Most-likely culprits** for the incident, in priority order:
   (a) `Add-PnPFile*SharingInvite` / `Add-PnPFolder*SharingInvite`
   called with `-SendInvitation`; (b) a direct Graph `POST .../invite`
   with `sendInvitation: true`; (c) `Add-PnPGroupMember -EmailAddress …
   -SendEmail` against the External param set.
3. **PnP doc defect.** The PnP cmdlet page for `-SendInvitation`
   describes the boolean with inverted semantics; the parameter name
   and the Graph contract are correct (`sendInvitation: true` = email
   sent). File at `pnp/powershell` after the incident debrief.
4. **`Set-PnPListItem -UpdateType SystemUpdate`** is the only update
   mode that bypasses Power Automate flows. `UpdateOverwriteVersion`
   DOES trigger flows despite the name suggesting otherwise.
5. **`Add-PnPListItem` has no flow-bypass mechanism** — there is no
   `SystemAdd` in CSOM. Use the skip-flag column pattern (documented
   in `sharepoint-sharing.md` §4) for create-time silencing.
6. **Hub-site association is silent** and can be CI-asserted via
   `Get-PnPHubSiteChild` (read-back) or the Unified Audit Log
   (`HubSiteJoined` operation) for compliance.
7. **Themes, Brand Center, SPFx app catalog, and tenant-wide app
   deployment are all silent** to end users — no email or banner;
   users discover new web parts in the picker organically.

## Most-cited Microsoft Learn pages

- [Microsoft 365 Group behaviors and provisioning options](https://learn.microsoft.com/en-us/graph/group-set-options)
- [Add member to team (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/team-post-members?view=graph-rest-1.0)
- [Add member to channel (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/channel-post-members?view=graph-rest-1.0)
- [conversationMember resource type](https://learn.microsoft.com/en-us/graph/api/resources/conversationmember?view=graph-rest-1.0)
- [Update channel (Graph beta)](https://learn.microsoft.com/en-us/graph/api/channel-patch?view=graph-rest-beta) (ADR-009)
- [New-PnPTeamsTeam](https://pnp.github.io/powershell/cmdlets/New-PnPTeamsTeam.html)

## Most-cited Microsoft Learn pages (Groups + B2B + xtsync + OneDrive cluster)

- [group resource type (v1.0)](https://learn.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-1.0) — `autoSubscribeNewMembers` default = false; POST-restricted property
- [Microsoft 365 Group behaviors and provisioning options](https://learn.microsoft.com/en-us/graph/group-set-options#configure-groups) — `resourceBehaviorOptions` table incl. `WelcomeEmailDisabled` (creation-only)
- [`Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled`](https://learn.microsoft.com/en-us/powershell/module/exchange/set-unifiedgroup?view=exchange-ps#-unifiedgroupwelcomemessageenabled) — Exchange-side welcome suppression; **enabled by default**
- [`Set-UnifiedGroup -AutoSubscribeNewMembers`](https://learn.microsoft.com/en-us/powershell/module/exchange/set-unifiedgroup?view=exchange-ps#-autosubscribenewmembers) — the **guest-user always-subscribe** gotcha
- [invitation resource (v1.0)](https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-1.0) — `sendInvitationMessage` default = **false**
- [invitedUserMessageInfo resource (v1.0)](https://learn.microsoft.com/en-us/graph/api/resources/invitedusermessageinfo?view=graph-rest-1.0) — schema for the launch-day customised mail
- [Cross-tenant sync overview](https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview#when-is-the-consent-prompt-suppressed) — "users don't receive an email" canonical quote
- [MTO overview — userType segmentation](https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview#who-are-multitenant-organization-member-users) — input to DeltaSetup-a3d
- [`Request-SPOPersonalSite`](https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/request-spopersonalsite?view=sharepoint-ps) — confirms no notification parameter exists

## Most-cited Microsoft Learn pages (SharePoint cluster)

- [driveItem: invite (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/driveitem-invite?view=graph-rest-1.0) — updated 2025-10-07
- [SPFx tenant-scoped deployment](https://learn.microsoft.com/en-us/sharepoint/dev/spfx/tenant-scoped-deployment) — updated 2023-04-17
- [`Add-PnPFileSharingInvite`](https://pnp.github.io/powershell/cmdlets/Add-PnPFileSharingInvite.html)
- [`Set-PnPListItem`](https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html) — canonical `-UpdateType` matrix
- [`Add-PnPGroupMember`](https://pnp.github.io/powershell/cmdlets/Add-PnPGroupMember.html)
- [`Add-PnPHubSiteAssociation`](https://pnp.github.io/powershell/cmdlets/Add-PnPHubSiteAssociation.html)
- [Purview audit search](https://learn.microsoft.com/en-us/purview/audit-search) — for the CI evidence harness

## Groups + B2B + xtsync + OneDrive cluster — executive summary (added by fdde46)

1. **`autoSubscribeNewMembers` cannot be set in the initial `POST /groups`** — Graph only accepts it on PATCH. Default in both v1.0 and beta is `false`. Use `resourceBehaviorOptions: ["WelcomeEmailDisabled"]` for create-time welcome suppression instead.
2. **`resourceBehaviorOptions` is creation-only** per Microsoft Learn — if missed at create-time, fall back to `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled:$false` (Exchange Online) and apply **before** any further member-add.
3. **The Guest-User trap (likely HTT-52 root cause):** `Set-UnifiedGroup -AutoSubscribeNewMembers` explicitly does **not** apply to guest users. Quote: "Guest user accounts are always subscribed when added as a member. You can manually remove subscriptions for guest users by using the `Remove-UnifiedGroupLinks` cmdlet." In cross-tenant scenarios where HTT users land in DCE as guest userType, the welcome-message switch is the **only** reliable suppression — `AutoSubscribeNewMembers:$false` is bypassed.
4. **B2B `sendInvitationMessage` defaults to `false`** in both v1.0 and beta — pleasantly safe. Pin it explicitly anyway for SDK-drift safety. `inviteRedeemUrl` is always returned regardless, so silent-then-comms is fully supported.
5. **Cross-tenant sync is silent by design** — verbatim Microsoft Learn quote: "For cross-tenant synchronization, users don't receive an email or have to accept a consent prompt." The `crossTenantIdentitySyncPolicyPartner` schema confirms this: there are zero notification-related properties.
6. **MTO membership does NOT add user-facing provisioning emails** (DeltaSetup-a3d input). It does change `userType` segmentation (synced users become `Member` instead of `Guest`), which is a **positive notification-quietness side effect** because it removes the guest-autosubscribe trap from §3.
7. **The OneDrive admin-center "Notifications" toggle is innocent** — it controls sharing-event notifications to file owners (`NotifyOwnersWhenItemsReshared`, etc.), NOT onboarding mail. `Request-SPOPersonalSite` does not surface a user-facing email channel.
8. **Docs are silent on:** xtsync ↔ downstream group-add interaction; whether toggling `userSyncInbound` re-fires anything. Pilot-canary protocol prescribed in `m365-groups-b2b-xtsync.md` §3e.

## Next steps for the SA

Read in order:
1. `teams.md` §1 and §2 — the two highest-impact Teams surfaces.
2. `sharepoint-sharing.md` TL;DR table + §2 — the SharePoint surfaces
   that most likely caused the 52-email incident.
3. `m365-groups-b2b-xtsync.md` §1e (gotchas) + TL;DR table — the
   Group-cluster path that is the **other** likely HTT-52 culprit
   (Exchange welcome on guest add) and the four levers to set.
4. `recommendations.md` P0 section — what to ship before the next
   Teams provisioning run.
5. `recommendations-groups-b2b.md` P0 section — the provisioning-script
   guardrails for any future `New-PnPMicrosoft365Group` /
   `New-MgInvitation` work.
6. `sharepoint-sharing.md` "Cross-cutting recommendations for
   DeltaSetup" — code-review checklist, CI grep gate, and audit-log
   proof harness for the SharePoint cluster.
7. `teams.md` §4 + `recommendations.md` P1.2 — empirical test plan
   for the ADR-009 BETA moderation endpoint.
8. `m365-groups-b2b-xtsync.md` §3e — pilot-canary protocol for
   cross-tenant sync silence verification.
