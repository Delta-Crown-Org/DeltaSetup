# Sources — Teams Notification Suppression Research

All sources verified live on **2026-05-16** by `web-puppy-df3922`.
All are **Tier 1** (official Microsoft documentation or canonical PnP
reference). No community blog posts or Stack Overflow answers were
relied on for behavioral claims.

| # | Source | Type | Last updated (per page) | Used for |
|---|--------|------|-------------------------|----------|
| 1 | [Add member to team (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/team-post-members?view=graph-rest-1.0) | Graph reference | 12/03/2025 | §2 — confirms no suppression flag; clarifies "change notifications" = webhooks |
| 2 | [Add member to channel (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/channel-post-members?view=graph-rest-1.0) | Graph reference | 04/22/2025 | §3 — confirms no suppression flag for private/shared channel member add |
| 3 | [conversationMember resource type (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/resources/conversationmember?view=graph-rest-1.0) | Graph schema | (page does not surface a date) | §2 — `visibleHistoryStartDateTime` defined as history-visibility, NOT notification |
| 4 | [Create team (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/team-post?view=graph-rest-1.0) | Graph reference | (recent) | §1 — confirms no notification flag on POST /teams |
| 5 | [Create channel (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/channel-post?view=graph-rest-1.0) | Graph reference | (recent) | §3 — confirms no notification flag |
| 6 | [Update channel (Graph beta)](https://learn.microsoft.com/en-us/graph/api/channel-patch?view=graph-rest-beta) | Graph reference (beta) | (recent) | §4 — moderationSettings PATCH; doc silent on notification behavior |
| 7 | [Microsoft 365 Group behaviors and provisioning options](https://learn.microsoft.com/en-us/graph/group-set-options) | Graph concept page | 10/09/2025 | §1/§2 — canonical `resourceBehaviorOptions` list (`WelcomeEmailDisabled` et al.) |
| 8 | [group resource type (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-1.0) | Graph schema | (recent) | §1 — `autoSubscribeNewMembers` default = `false` |
| 9 | [New-PnPTeamsTeam](https://pnp.github.io/powershell/cmdlets/New-PnPTeamsTeam.html) | PnP cmdlet reference | (rolling, DocFX-generated) | §1 — full parameter list incl. `-ResourceBehaviorOptions` |
| 10 | [Add-PnPTeamsUser](https://pnp.github.io/powershell/cmdlets/Add-PnPTeamsUser.html) | PnP cmdlet reference | (rolling) | §2 — full parameter list: no suppression flag exists |
| 11 | [Add-PnPTeamsChannel](https://pnp.github.io/powershell/cmdlets/Add-PnPTeamsChannel.html) | PnP cmdlet reference | (rolling) | §3 — full parameter list: no suppression flag |
| 12 | [Add-PnPTeamsChannelUser](https://pnp.github.io/powershell/cmdlets/Add-PnpTeamsChannelUser.html) | PnP cmdlet reference | (rolling) | §3 — full parameter list: no suppression flag |
| 13 | [New-Team (MicrosoftTeams PS)](https://learn.microsoft.com/en-us/powershell/module/microsoftteams/new-team) | PowerShell module ref | (recent) | §1 — confirms NO `-ResourceBehaviorOptions` parity (divergence from PnP) |
| 14 | [Manage agents and app setup policies](https://learn.microsoft.com/en-us/microsoftteams/teams-app-setup-policies) | Teams admin docs | (recent) | §5 — app setup policy is silent install |
| 15 | [Install app for user (Graph v1.0)](https://learn.microsoft.com/en-us/graph/api/userteamwork-post-installedapps?view=graph-rest-1.0) | Graph reference | (recent) | §5 — per-user install: no notification surface documented |

## Credibility assessment

**Authority — Tier 1 across the board.** All sources are first-party
Microsoft Learn or pnp.github.io (the latter is the officially-endorsed
PnP community project whose docs are generated from the same source
that ships with the PnP.PowerShell module on the PowerShell Gallery).

**Currency.** Of the surfaces touched:

- Group-behaviors page **last updated 2025-10-09** — recent.
- Add member to team page **last updated 2025-12-03** — current.
- Add member to channel page **last updated 2025-04-22** — older but
  the API itself has been stable.
- All other Graph pages do not surface a "last updated" timestamp in
  the rendered HTML but are tied to the corresponding `/v1.0` or
  `/beta` schema commit on the public Graph metadata.

**Validation.** Three independent surfaces were checked for each claim:
PnP cmdlet docs, Microsoft Graph reference, and the underlying
resource-type schema. Claims that could not be cross-validated (notably
§4 channel moderation PATCH notification behavior, and §6 owner-vs-
member differential) are flagged in the report as docs-silent and
recommended for empirical test.

**Bias.** No commercial-motivation bias — Microsoft has documented
incentive to surface a suppression API and has chosen not to (this is
the canonical "missing feature" rather than a security-driven
omission).

**Primary vs secondary.** All references are primary Microsoft sources.
Zero third-party blog posts, tutorial sites, or Stack Overflow answers
were used.
