# Teams Inventory Access Request

## Purpose

The Delta Crown tenant inventory is blocked on Teams/channel evidence.

The current delegated admin/read context can read Microsoft 365 group and SharePoint evidence, but cannot read Teams workload endpoints.

## Current blocker

Graph Teams endpoint checks return:

```text
403 Forbidden
Failed to get license information for the user. Ensure user has a valid Office365 license assigned to them.
```

MicrosoftTeams PowerShell connects. As of the 2026-05-12 probe, member read works but team/channel reads still fail:

```powershell
Connect-MicrosoftTeams -TenantId ce62e17d-2feb-4e67-a115-8ea4af68da30
Get-Team -GroupId 03255d50-a52d-4b1f-a0f6-37379cc13a35        # Forbidden in /v1.0/teams/ endpoint
Get-TeamChannel -GroupId 03255d50-a52d-4b1f-a0f6-37379cc13a35 # Failed to get license information for the user
Get-TeamUser -GroupId 03255d50-a52d-4b1f-a0f6-37379cc13a35    # Succeeds; returns Tyler external admin + six DCE users
```

## Needed access

Provide one of the following:

1. A licensed Delta Crown user/admin context that can run read-only Teams inventory commands; or
2. A delegated/admin account with a valid Teams/Office license in the Delta Crown tenant; or
3. Owner attestation of Teams/channel state if direct access cannot be provided.

## Read-only commands to verify access

```powershell
Connect-MicrosoftTeams -TenantId ce62e17d-2feb-4e67-a115-8ea4af68da30

Get-Team -GroupId 03255d50-a52d-4b1f-a0f6-37379cc13a35
Get-TeamChannel -GroupId 03255d50-a52d-4b1f-a0f6-37379cc13a35
Get-TeamUser -GroupId 03255d50-a52d-4b1f-a0f6-37379cc13a35
```

Equivalent Microsoft Graph reads are also acceptable if they can read:

```text
/teams/{team-id}
/teams/{team-id}/channels
/teams/{team-id}/members
/teams/{team-id}/channels/{channel-id}/members
```

Known DCE Operations team/group ID:

```text
03255d50-a52d-4b1f-a0f6-37379cc13a35
```

## Required inventory once access works

Capture read-only evidence for:

- Teams list;
- DCE Operations team properties;
- standard/private/shared channels;
- owners;
- members — partially available now via `Get-TeamUser`;
- private/shared channel members;
- tabs/apps if readable;
- connected SharePoint sites/folders;
- Leadership private channel state.

## Guardrails

Do **not**:

- create Teams/channels;
- rename Teams/channels;
- archive/delete Teams/channels;
- add/remove owners or members;
- change tabs/apps;
- change SharePoint folders or permissions.

This is inventory only. The goal is to unblock `DeltaSetup-134` and then `DeltaSetup-137`.
