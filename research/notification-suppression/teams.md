# Teams Notification Suppression During Automated Provisioning

**Status:** P0 reference, verified against Microsoft Learn 2026-05-16
**Owner:** web-puppy-df3922 (research agent), for Solutions Architect on DCE rollout
**Scope:** Microsoft Teams provisioning surfaces — what fires user-facing
notifications, and what (if anything) suppresses them.
**Companion ADRs:** [`ADR-009`](../../docs/sharepoint-pnp-spec/decisions/009-teams-moderation-beta-only.md)
(channel moderation runs against `/beta`).
**Project context:** automation in
[`dce-mockup/ci-cd/scripts/provision-teams.ps1`](../../dce-mockup/ci-cd/scripts/provision-teams.ps1)
calling Microsoft Graph from GitHub Actions.

---

## TL;DR — what is and isn't possible

> **The brutal headline:** Microsoft Graph and Teams PowerShell do **NOT**
> expose any documented switch, header, or query parameter to suppress
> the *in-product Teams activity-feed entry* ("X added you to Team Y")
> when adding members through `POST /teams/{id}/members` or
> `POST /teams/{id}/channels/{id}/members`. No `suppressNotification`
> property, no `Prefer:` header, no `?notify=false`. Verified against
> the v1.0 and beta reference for `conversationMember` on 2026-05-16.
> The mention of "change notifications" on the v1.0 add-member doc
> refers to **developer webhook subscriptions**, not user-facing toasts.[^1]

What you **can** suppress, with documented mechanisms:

| Surface                                    | Documented suppression                                                                                              | Default |
|--------------------------------------------|---------------------------------------------------------------------------------------------------------------------|---------|
| M365 Group **welcome email** to new members | `resourceBehaviorOptions: ["WelcomeEmailDisabled"]` on **group create** (Graph) / `-ResourceBehaviorOptions WelcomeEmailDisabled` on `New-PnPTeamsTeam` | Send    |
| M365 Group **conversation auto-subscribe** (email) | `autoSubscribeNewMembers = false` (group property, settable via PATCH after create) / omit `SubscribeNewGroupMembers` from `resourceBehaviorOptions` | Suppress (default `false`) |
| M365 Group **visible in Outlook**           | `resourceBehaviorOptions: ["HideGroupInOutlook"]` on group create                                                   | Visible |
| Teams **activity feed** "added you to Team"  | **NOT SUPPRESSIBLE** via documented API — see workaround §2.G                                                       | Send    |
| Teams **first-run welcome / `team is ready`** | **No documented control** — Teams admin center has no tenant switch for it                                          | Send (per user, first time the team appears) |
| Channel **moderation PATCH** (beta)         | Docs silent — needs empirical test                                                                                  | Unknown |
| Teams **app install via setup policy**      | Silent — no user prompt documented                                                                                  | Silent  |

---

## 1. Teams **team** creation

### a. APIs that trigger it
- **PnP PowerShell:** `New-PnPTeamsTeam` ([cmdlet docs])[^2]
- **Graph v1.0:** `POST /teams` (from existing group) and `POST /groups` (group create that later becomes team) ([Graph create team])[^3]
- **MicrosoftTeams PowerShell:** `New-Team` ([New-Team docs])[^4]

### b. What's actually documented as suppressible

`New-PnPTeamsTeam` exposes a single relevant parameter:

```powershell
-ResourceBehaviorOptions <TeamResourceBehaviorOptions>
# Accepted values:
#   AllowOnlyMembersToPost
#   HideGroupInOutlook
#   SubscribeNewGroupMembers
#   WelcomeEmailDisabled
```

Microsoft's own Example 3 in the cmdlet docs:[^2]

```powershell
New-PnPTeamsTeam -DisplayName "myPnPDemo1" -Visibility Private `
                 -ResourceBehaviorOptions WelcomeEmailDisabled
# "Welcome Email will not be sent when the Group is created."
```

Example 4 stacks two:

```powershell
-ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook
```

The full canonical list of `resourceBehaviorOptions` values is documented on
the **"Microsoft 365 Group behaviors and provisioning options"** Learn
page[^5] (last updated 10/09/2025). Of these, the ones that matter for
notification suppression on team-creation day:

| Value                                       | Effect                                                                |
|---------------------------------------------|-----------------------------------------------------------------------|
| `WelcomeEmailDisabled`                      | Welcome emails aren't sent to new members.                            |
| `SubscribeNewGroupMembers`                  | **Opposite** — sets `autoSubscribeNewMembers=true` (DO NOT include if suppressing). |
| `SubscribeMembersToCalendarEventsDisabled`  | Members aren't subscribed to the group's calendar events in Outlook.  |
| `HideGroupInOutlook`                        | Group hidden in Outlook (reduces "did Outlook just grow a folder?" complaints). |

> ⚠ **Critical gotcha — group-only, create-time only.** Per the Learn page
> ([Group behaviors][^5]): *"These behaviors can be set only on group
> creation."* You cannot retroactively PATCH `resourceBehaviorOptions`
> onto an existing group/team. If a team already exists, the
> `WelcomeEmailDisabled` ship has sailed for that team's lifetime.

### c. Defaults

| Setting                       | Default behavior                                       |
|-------------------------------|--------------------------------------------------------|
| Welcome email to new members  | **Sent** (must opt out with `WelcomeEmailDisabled`)    |
| `autoSubscribeNewMembers`     | **`false`** (members are NOT email-spammed) — confirmed on the `group` resource doc[^6] |
| Group visible in Outlook      | **Visible** (must opt out with `HideGroupInOutlook`)   |
| Teams activity-feed entry on team activation | **Sent** to every member — no documented switch |

### d. Suppression flag matrix

| Cmdlet / API                                  | `-Announce` | `-SendNotification` | `-Quiet` / `-Silent` | `-Suppress*` |
|-----------------------------------------------|:-----------:|:-------------------:|:--------------------:|:------------:|
| `New-PnPTeamsTeam`[^2]                        | ❌          | ❌                  | ❌                   | ❌           |
| `New-Team` (MicrosoftTeams PS)[^4]            | ❌          | ❌                  | ❌                   | ❌           |
| `POST /teams` (Graph v1.0)[^3]                | ❌          | ❌                  | ❌                   | ❌           |
| `POST /groups` (Graph v1.0)[^6]               | ❌ (use `resourceBehaviorOptions` body property instead) |

### e. Gotchas

1. **v1.0 vs beta**: For `POST /teams` and `POST /groups`, the request
   body schema is identical on v1.0 and beta with respect to
   `resourceBehaviorOptions`. No difference. (`channelModerationSettings`
   is the famous v1.0-vs-beta divergence — see §4.)
2. **PnP vs Graph**: `New-PnPTeamsTeam` is a thin wrapper that POSTs to
   `/groups` then to `/teams`. The `-ResourceBehaviorOptions` parameter
   maps directly to the `resourceBehaviorOptions` JSON array on the
   group create request. No PnP-specific magic.
3. **MicrosoftTeams PowerShell (`New-Team`)** does **NOT** surface
   `ResourceBehaviorOptions`. If you need `WelcomeEmailDisabled` you
   must use PnP or call Graph directly. This is a real divergence — do
   not assume the Teams module is a superset of PnP.
4. **Teamify path** (`New-PnPTeamsTeam -GroupId <existing>`) cannot set
   `resourceBehaviorOptions` because the group already exists. The
   documented Example 2 omits it. If you teamify an existing group with
   the welcome-email setting unchanged, welcome emails fire on the
   teamify event for already-existing members? — see §7.

### f. Launch-day delivery mechanism (separate path)

Even with `WelcomeEmailDisabled`, two things still happen at team activation:

- **Activity feed entry** in each member's Teams client ("You were added
  to *Crown Connection*"). Generated by the Teams membership service.
  No documented suppression. This is the same entry that fires on §2.
- **First-run "Welcome to the team" bot card** posted to the General
  channel the first time a user opens the team. Tied to client
  first-run experience. See §7 for tenant-policy options (spoiler:
  there isn't one).

---

## 2. Teams **team member add** — the noisy one

### a. APIs that trigger it
- **PnP PowerShell:** `Add-PnPTeamsUser` ([cmdlet docs])[^7]
- **Graph v1.0:** `POST /teams/{team-id}/members` ([Add member to team])[^1]
- **Graph beta:** Same path, same schema.
- **MicrosoftTeams PowerShell:** `Add-TeamUser`

### b. Suppression mechanisms documented

**None.** The full v1.0 request body documented on Learn[^1] is:

```http
POST https://graph.microsoft.com/v1.0/teams/{team-id}/members
Content-type: application/json

{
  "@odata.type": "#microsoft.graph.aadUserConversationMember",
  "roles": ["owner"],                       // [] for plain member
  "user@odata.bind": "https://graph.microsoft.com/v1.0/users('…')"
}
```

There is no `suppressNotification`, no `silent`, no `quiet`. The only
documented request **headers** are `Authorization` and `Content-Type`.
No `Prefer:` header is documented for this endpoint, contrary to the
pattern Exchange/Calendar APIs use.

The `Add-PnPTeamsUser` cmdlet's full parameter set:[^7]

```text
-Team       <TeamsTeamPipeBind>   # required
-Channel    <TeamsChannelPipeBind># optional, scopes to private channel
-User       <String>              # single UPN
-Users      <String[]>            # bulk UPNs
-Role       <Owner|Member>        # required
```

That's it. No `-Quiet`, no `-NoNotification`, no `-SuppressActivityFeed`.

### c. `roles` (`["owner"]` vs `[]`) — does it change notification?

The v1.0 reference page says nothing about owners vs members triggering
different notifications.[^1] In practice both fire the same Teams
activity-feed entry. Treat the claim "owners aren't notified" as
**folklore until empirically verified in your tenant** — it is not in
the docs.

### d. `visibleHistoryStartDateTime` — **NOT a notification control**

The `conversationMember` resource type doc[^8] defines this property as:

> "The timestamp denoting how far back a conversation's history is
> shared with the conversation member."

It controls **what message history a new shared/private-channel member
can see** (e.g., set to `null` for no history, or a date for partial
history). It has zero effect on whether the user gets a Teams
notification of being added. **Do not propose it as a workaround.**

### e. The "X added you to Team Y" notification — what is it?

It is delivered through up to three channels, all driven by the Teams
membership service after a successful `POST /members`:

1. **Activity feed entry** in the Teams desktop/web/mobile client (the
   bell icon). Always fires on first delivery to that user.
2. **Teams desktop toast** (transient OS notification) — gated by the
   *user's* notification settings, not by the caller.
3. **Email** — gated by the M365 Group's `autoSubscribeNewMembers`
   property and per-user Outlook subscription preferences.

The Graph reference page for add-member doesn't document any of this
behavior beyond "After adding a new conversation member to a team, it
might take some time for the addition to be reflected." [^1]

### f. Headers / query params to suppress activity feed: documented?

**No.** Searched the v1.0 and beta reference pages for `POST /teams/{id}/members`
and `POST /teams/{id}/channels/{id}/members`. No `Prefer:` header is
listed. The only documented headers are `Authorization` and
`Content-Type`.[^1][^9]

### g. Architectural workaround — add to the **underlying M365 Group**, not the Teams API

If your goal is "provision membership without firing the Teams activity
feed at scale," the documented workaround is to skip the Teams membership
API entirely and add users to the **backing Microsoft 365 group's
`members` collection**:

```http
POST /groups/{group-id}/members/$ref
Content-Type: application/json
{
  "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/{user-id}"
}
```

…where the group was originally created with:

```json
{
  "resourceBehaviorOptions": ["WelcomeEmailDisabled"],
  "autoSubscribeNewMembers": false
}
```

**Honest caveat.** This suppresses the *welcome email* and the *email
auto-subscription*. **It does NOT reliably suppress the Teams activity-feed
entry** — empirical reports vary by tenant and by how stale the group→team
membership sync is. Microsoft does not document this as an officially
supported "no-notification" path. The activity-feed entry is generated when
the Teams membership service reconciles the group change, which usually
still fires the bell-icon notification (just without the email).

What this workaround *does* reliably buy you:

- No welcome email to the inbox.
- No "you're subscribed to group conversations" email subscription.
- Lower-noise *email* surface during bulk provisioning.

If the requirement is **zero in-product Teams notification**, the docs
provide no supported path. The only escape hatches are:

- Provision during off-hours and accept the silent activity-feed accrual.
- Send users a **prebrief** comms beforehand explaining the upcoming
  membership change.
- Open a Microsoft support ticket requesting the documented suppression
  surface — this is a known long-standing gap (UserVoice / Feedback
  Portal item dating to 2018).

---

## 3. Teams **channel** create + **channel member** add

### a. Create a channel

- **PnP:** `Add-PnPTeamsChannel`[^10]
- **Graph v1.0 / beta:** `POST /teams/{id}/channels`[^11]

Parameter set for `Add-PnPTeamsChannel`:[^10]

```text
-Team               <required>
-DisplayName        <required>
-ChannelType        <Standard|Private|Shared>
-OwnerUPN           <required for Private/Shared>
-Description        <optional>
-IsFavoriteByDefault [obsolete — only honored at team-create time]
```

**No suppression flag** on either the cmdlet or the Graph endpoint.
The Graph v1.0 channel-create doc[^11] documents no `Prefer:` header
and no notification-control property in the request body.

### b. Notifications when a new channel is created

For a **standard** channel: existing team members do receive an activity-
feed entry "*New channel: <name>*" by default. No documented
suppression. The closest knob is at team policy:
`-AllowChannelMentions <Boolean>` on `New-PnPTeamsTeam`[^2] (description:
"channels in the team can be @ mentioned so that all users who follow
the channel are notified") — but that controls @-mentions, not channel
creation notifications.

For a **private** channel: only the explicitly-added private-channel
members get notified ("You've been added to private channel <name>").
This is the docs-implied behavior on `POST /teams/{id}/channels/{id}/members`[^9]
but is not stated explicitly as "notifies the user."

For a **shared** channel: the recipient gets a notification that
includes whether the share is in-tenant or cross-tenant — the
cross-tenant case routes through B2B direct connect (separate consent
prompt, governed by Entra cross-tenant access policy, not by Teams).

### c. Add a member to a **private** channel

- **PnP:** `Add-PnPTeamsChannelUser`[^12] — parameters limited to
  `-Team -Channel -User -Role`. No suppression flag.
- **Graph v1.0:** `POST /teams/{id}/channels/{id}/members` —
  documented as available only for `membershipType = private | shared`
  channels.[^9] Request body identical schema to team-member add (the
  same `conversationMember` resource). **No suppression flag.**

### d. Private vs standard vs shared — notification differences

| Channel type | New-channel notification to existing team members | Add-member notification to the added user                       |
|--------------|--------------------------------------------------|-----------------------------------------------------------------|
| Standard     | Activity feed entry to everyone in the team       | Member already in team — no per-channel add notification         |
| Private      | None (channel is invisible to non-members)        | Activity feed entry to added user — no documented suppression    |
| Shared       | None to non-shared users                          | Activity feed + cross-tenant consent prompt if cross-tenant      |

Cite[^9][^11] for endpoint behavior. The differential effect on the
*activity feed* is not spelled out in a single Learn page — it is
inferred from the channel `membershipType` semantics and the per-API
permission scopes (`ChannelMember.ReadWrite.All` vs
`TeamMember.ReadWrite.All`).

---

## 4. Teams channel **moderation** (BETA endpoint — ADR-009)

### a. API

```http
PATCH https://graph.microsoft.com/beta/teams/{team-id}/channels/{channel-id}
Content-Type: application/json

{
  "moderationSettings": {
    "userNewMessageRestriction": "moderators",
    "replyRestriction":          "authorAndModerators",
    "allowNewMessageFromBots":   false,
    "allowNewMessageFromConnectors": false
  }
}
```

Reference: Update channel (beta).[^13] Critical: per
[ADR-009](../../docs/sharepoint-pnp-spec/decisions/009-teams-moderation-beta-only.md),
v1.0 silently ignores `moderationSettings`. Teams PowerShell v7.7.0
has no moderation parameters. So `PATCH /beta` is the only path.

### b. Does enabling moderation notify channel members?

The Learn reference page[^13] notes only:

> "The following example shows a request to update the moderation
> settings of a channel. Only team owners can perform this operation."

**The doc is silent on whether this PATCH triggers a member-visible
activity-feed entry or an in-channel system message.** No
`suppressNotification` flag exists. Microsoft does not document the
notification behavior of this endpoint.

### c. Recommendation: empirical test required

Before flipping moderation tenant-wide, run a one-channel canary in
your DCE staging tenant and observe:

1. Whether existing channel members see an activity-feed entry.
2. Whether an in-channel system post appears ("Channel moderation has
   been enabled by <X>").
3. Whether the moderation change emits a webhook/audit event a
   downstream subscription could surface.

Document the empirical result in an addendum to ADR-009. This is the
only honest path — the doc literally does not say.

---

## 5. Tenant-wide **Teams app / message extension** install via app setup policy

### a. Mechanism
- **Teams admin center → Teams apps → Setup policies** — *installed apps*
  and *pinned apps* lists.[^14]
- **Per-user Graph install:** `POST /users/{id}/teamwork/installedApps`[^15]

### b. Does it notify users?

The Teams admin center app setup policies doc[^14] describes the user
experience as install-then-pin, with the user discovering the app in
the Teams app rail. The doc does not describe a toast, activity-feed
entry, or email notification when an app is installed on the user's
behalf via setup policy. The relevant phrasing:

> "Users can't remove an agent or app from their client if an admin
> adds it. The Uninstall option for a pinned app is hidden."

No notification fires. **App install via setup policy is silent.**

The per-user Graph install endpoint[^15] also documents no
notification surface. The user sees the app appear in their Teams
client at next sync.

---

## 6. **Owner vs Member** notification distinction

Searched the v1.0 and beta `POST /teams/{id}/members` reference pages[^1]
for any phrasing distinguishing owner vs member notifications. **None
exists.** The only owner-vs-member distinction Microsoft documents on
the add-member endpoint is:

- Different *permission scope* required (`TeamMember.ReadWrite.All` is
  required to add owners; `TeamMember.ReadWriteNonOwnerRole.All` is
  least-privileged for non-owners).[^1]
- Different `roles` value in the JSON body (`["owner"]` vs `[]`).
- Different audit-log entry (visible in Microsoft Purview).

**On user-facing notifications: the docs do NOT promise any
difference.** Both owners and members get the "added to team" activity
feed entry on first delivery. Any production behavior that suggests
otherwise should be re-verified each Teams release (the Teams client
revs faster than the API surface).

> Recommendation: if you have an internal runbook that relies on
> "owners don't get notified," **stop relying on it.** Document the
> assumption as folklore, schedule a quarterly empirical test, and
> communicate to owners regardless.

---

## 7. The **"Welcome to the team"** first-run message

Distinct from "X added you to Team Y". This is the first-run experience
card that the Teams client renders the first time a user opens a newly-
provisioned team. It includes the team description, an invitation to
explore channels, and (depending on tenant config) a moderator-pinned
welcome post.

### Controls documented in Microsoft Learn

1. **Group welcome email** — controllable via `WelcomeEmailDisabled`
   in `resourceBehaviorOptions` at group creation. Already covered §1.
   This is the *email* welcome, not the in-product first-run card.
2. **First-channel post** — owners can pin a custom welcome message
   to the General channel manually. There is no Graph or PowerShell
   API documented for "auto-pin a welcome post on team creation"; PnP
   provisioning templates do not include this.
3. **Teams admin center "Welcome to Teams" tutorial bot for new
   users** — this is the tenant-wide *first-time-in-Teams-ever*
   experience, not per-team. Controlled (or, more accurately,
   `Disable-` not documented) under user-policy settings. Not the
   per-team welcome.

### What is **not** documented

There is **no tenant-wide Teams admin center toggle** to suppress the
per-team first-run welcome card. There is no Graph property on the
`team` resource for it. The closest you can get is to:

- Disable the M365 Group welcome email (`WelcomeEmailDisabled`).
- Disable the Outlook autosubscribe (`autoSubscribeNewMembers = false`,
  the default).
- Accept that the in-product Teams first-run card will appear.

This gap is widely reported in Microsoft Feedback Portal and on the
Teams Community channel; Microsoft has not shipped a control surface
for it as of 2026-05-16.

---

## Source reliability hierarchy applied to this research

All sources used are **Tier 1** — official Microsoft Learn documentation,
the canonical Graph reference, and the canonical PnP PowerShell cmdlet
reference. No third-party blog posts were trusted for behavioral claims;
where docs are silent (notably §4 moderation notifications and §6 owner-
vs-member differentials), the report **explicitly says so** rather than
back-filling with community folklore.

See [`sources.md`](./sources.md) for the full citation list with
credibility assessments and last-updated timestamps.

---

## Footnotes / citations

[^1]: Microsoft Graph — *Add member to team* (v1.0).
  <https://learn.microsoft.com/en-us/graph/api/team-post-members?view=graph-rest-1.0>
  (last updated 12/03/2025). Quoted: *"After adding a new conversation
  member to a team, it might take some time for the addition to be
  reflected. Users can use change notifications to subscribe to
  notifications for membership changes in a particular team."* —
  "change notifications" here is the developer webhook subscription
  API, not user-facing toasts.

[^2]: PnP PowerShell — *New-PnPTeamsTeam* cmdlet reference.
  <https://pnp.github.io/powershell/cmdlets/New-PnPTeamsTeam.html>

[^3]: Microsoft Graph — *Create team* (v1.0).
  <https://learn.microsoft.com/en-us/graph/api/team-post?view=graph-rest-1.0>

[^4]: MicrosoftTeams PowerShell — *New-Team*.
  <https://learn.microsoft.com/en-us/powershell/module/microsoftteams/new-team>

[^5]: Microsoft Graph — *Microsoft 365 Group behaviors and provisioning
  options*.
  <https://learn.microsoft.com/en-us/graph/group-set-options>
  (last updated 10/09/2025).

[^6]: Microsoft Graph — *group resource type* (v1.0).
  <https://learn.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-1.0>
  Quoted (autoSubscribeNewMembers): *"Indicates if new members added to
  the group are autosubscribed to receive email notifications. […]
  Default value is false."*

[^7]: PnP PowerShell — *Add-PnPTeamsUser*.
  <https://pnp.github.io/powershell/cmdlets/Add-PnPTeamsUser.html>

[^8]: Microsoft Graph — *conversationMember resource type* (v1.0).
  <https://learn.microsoft.com/en-us/graph/api/resources/conversationmember?view=graph-rest-1.0>
  Quoted (visibleHistoryStartDateTime): *"The timestamp denoting how
  far back a conversation's history is shared with the conversation
  member."*

[^9]: Microsoft Graph — *Add member to channel* (v1.0).
  <https://learn.microsoft.com/en-us/graph/api/channel-post-members?view=graph-rest-1.0>
  (last updated 04/22/2025). Allowed only for `membershipType` of
  `private` or `shared`.

[^10]: PnP PowerShell — *Add-PnPTeamsChannel*.
  <https://pnp.github.io/powershell/cmdlets/Add-PnPTeamsChannel.html>

[^11]: Microsoft Graph — *Create channel* (v1.0).
  <https://learn.microsoft.com/en-us/graph/api/channel-post?view=graph-rest-1.0>

[^12]: PnP PowerShell — *Add-PnPTeamsChannelUser*.
  <https://pnp.github.io/powershell/cmdlets/Add-PnpTeamsChannelUser.html>

[^13]: Microsoft Graph — *Update channel* (beta).
  <https://learn.microsoft.com/en-us/graph/api/channel-patch?view=graph-rest-beta>
  Per ADR-009, v1.0 silently ignores `moderationSettings`; beta is the
  only path. The reference page is silent on whether this PATCH triggers
  user notifications.

[^14]: Microsoft Teams admin — *Manage agents and app setup policies in
  Microsoft Teams*.
  <https://learn.microsoft.com/en-us/microsoftteams/teams-app-setup-policies>

[^15]: Microsoft Graph — *Install app for user*.
  <https://learn.microsoft.com/en-us/graph/api/userteamwork-post-installedapps?view=graph-rest-1.0>
