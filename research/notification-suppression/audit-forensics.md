# Audit-Log Forensics for Retrospective Notification Investigation

**Author:** Web-Puppy (`web-puppy-972381`)
**Date:** 2026-05-16
**Incident:** P0 — DCE provisioning commits `834f516`, `1cad240`, `a6dd3f5` (2026-05-12 → 2026-05-15) sent unsolicited welcome / sharing / invitation emails to ~52 HTT corporate users.
**Tenants in scope:** `deltacrown` (provisioning origin) and `httbrands.onmicrosoft.com` (recipient corporate users).
**Automation identity in scope:** app registration `DeltaCrown-PnP-Provisioning` (and, in the SharePoint workload, the legacy `app@sharepoint` actor identity).

> **Read this first — time-criticality:** several of the surfaces below have **very short** retention windows (Get-MessageTrace = 10 days, Entra audit logs = 30 days on P1/P2). The incident window opened **2026-05-12**, so as of **2026-05-16** we are at **day 4** — *every surface is still queryable*, but the Exchange `Get-MessageTrace` window will close around **2026-05-22 (T-1)** and **2026-05-25 (T-1)** for the earliest events. **Kick off `Start-HistoricalSearch` jobs and pull the Unified Audit Log immediately, do not wait.**

---

## TL;DR — surface decision matrix

| Question | Primary surface | Secondary / cross-check | Hard retention deadline for this incident |
|---|---|---|---|
| Which emails physically left the tenant? | **EXO Message Trace** (`Get-MessageTraceV2`) → fall back to **Start-HistoricalSearch** | Purview Audit (`Send` mailbox action — only if mailbox auditing on) | Message Trace: **2026-05-22** for earliest event |
| Which M365 Group adds happened? | **Unified Audit Log** `AddMemberToGroup` | **Entra audit** "Add member to group" | Entra: **2026-06-11** (30d); UAL: 180d+ |
| Which B2B guests were invited (and was an email sent)? | **Entra audit** "Invite external user" → `additionalDetails.sendInvitationMessage` | UAL `UserInvited` | Entra: **2026-06-11**; UAL: 180d+ |
| Which SharePoint shares occurred (and which were emailing)? | **UAL** SharePoint sharing schema (`SharingInvitationCreated`, `SharingSet`, `AddedToSecureLink`, `SecureLinkCreated`, `AnonymousLinkCreated`, `CompanyLinkCreated`) | SP admin audit reports | UAL: 180d+ |
| Which Teams adds (team / channel / member) happened? | **UAL** Teams schema (`TeamCreated`, `ChannelAdded`, `MemberAdded`, `MemberRoleChanged`) | n/a | UAL: 180d+ |
| Who/what is the actor? | UAL `UserId` + `ApplicationId` + `UserType`; Entra `initiatedBy.app.{appId, displayName, servicePrincipalId}` | App registration display name lookup in Entra | Same as above |
| What did the email actually say? | **Purview Content search** (KQL `from:`, `subject:`, `received>=`) against the recipient mailboxes | Recipient forwards a copy | Indefinite (until mailbox deletion) |

---

## 1. "Show me every welcome / sharing / invitation email sent by automation in window T1..T2"

### a. Surface
**Exchange Online Message Trace** — two-tier API:

1. `Get-MessageTrace` / `Get-MessageTraceV2` (real-time, last 10 days).
2. `Start-HistoricalSearch` / `Get-HistoricalSearch` (asynchronous, 1h–90 days).

This is the only authoritative record of *the actual SMTP envelope leaving the tenant*. It is independent of whether mailbox auditing or unified audit was enabled.

### b. Query

```powershell
Connect-ExchangeOnline -UserPrincipalName <admin>@deltacrown.onmicrosoft.com

# Tier 1 — last 10 days (use NOW while in window)
Get-MessageTrace `
    -StartDate "2026-05-12 00:00:00Z" `
    -EndDate   "2026-05-15 23:59:59Z" `
    -SenderAddress @(
        "no-reply@sharepointonline.com",            # SharePoint sharing/share-link mail
        "MicrosoftOffice365@email.microsoftonline.com", # M365 Group welcome
        "no-reply@microsoft.com",                   # B2B invitation
        "invites@microsoft.com",                    # Older B2B invitation sender
        "noreply@email.teams.microsoft.com"         # Teams "you've been added" mail
    ) `
    -PageSize 5000 |
    Where-Object { $_.RecipientAddress -like "*@httbrands.onmicrosoft.com" -or
                   $_.RecipientAddress -like "*@httbrands.com" } |
    Export-Csv ./out/dce-incident-messagetrace.csv -NoTypeInformation

# Filter further by subject substring AFTER you have the MessageTraceId list,
# using Get-MessageTraceDetail on each row (subject is not on Get-MessageTrace).
```

For the **>10-day** path (i.e. if we are still investigating after 2026-05-22):

```powershell
Start-HistoricalSearch `
    -ReportTitle "DCE-Incident-2026-05-12_15" `
    -StartDate   "2026-05-12" `
    -EndDate     "2026-05-15" `
    -ReportType  MessageTraceDetail `
    -SenderAddress "no-reply@sharepointonline.com" `
    -NotifyAddress secops@deltacrown.com
# Repeat for each candidate sender; results arrive as CSV email within ~1–24h.
```

### c. Retention
- `Get-MessageTrace`: **last 10 days only**, default 48 h if no `-StartDate`. ([Microsoft Learn — `Get-MessageTrace`](https://learn.microsoft.com/en-us/powershell/module/exchange/get-messagetrace?view=exchange-ps))
- `Start-HistoricalSearch`: **1–4 h to 90 days**, max **250 searches / 24 h**, **100 000 rows per CSV**. ([Microsoft Learn — `Start-HistoricalSearch`](https://learn.microsoft.com/en-us/powershell/module/exchange/start-historicalsearch?view=exchange-ps))

### d. License
Both cmdlets are included with **any Exchange Online plan** (EXO Plan 1, EXO Plan 2, M365 Business Basic/Standard/Premium, E1/E3/E5). No add-on required. Caller must have **View-Only Recipients** + **Message Tracking** role (granted to Exchange admin / Compliance admin / Global Reader).

### e. URL
- https://learn.microsoft.com/en-us/powershell/module/exchange/get-messagetrace?view=exchange-ps
- https://learn.microsoft.com/en-us/powershell/module/exchange/start-historicalsearch?view=exchange-ps
- https://learn.microsoft.com/en-us/powershell/module/exchange/get-historicalsearch?view=exchange-ps

### f. Gotchas
- **The classic `Get-MessageTrace` is being deprecated** in favour of `Get-MessageTraceV2`. The docs page itself carries the banner *"This cmdlet is replaced by the Get-MessageTraceV2 cmdlet and will eventually be deprecated."* — prefer `Get-MessageTraceV2` in new scripts. ([source above](https://learn.microsoft.com/en-us/powershell/module/exchange/get-messagetrace?view=exchange-ps))
- **Subject is *not* returned** by `Get-MessageTrace`. You must `Get-MessageTraceDetail -MessageTraceId <guid> -Recipient <addr>` per row to read the subject / event-level events, or use `Start-HistoricalSearch -ReportType MessageTraceDetail`.
- **Page limits:** 1000 rows default, 5000 max per page; the docs warn "consider splitting it up using smaller StartDate and EndDate intervals" for large queries.
- **Timestamps are UTC** in the output regardless of the locale you supplied to `-StartDate`.
- **Internal-only messages may not have a public IP** in `FromIP` / `ToIP`.
- **`Get-MessageTrace` is NOT a content store** — it shows envelope + status, *not* the body. For body → Purview Content search (§ 7).
- **Recipient addresses are not redacted** in message trace, but the sender may appear as the *envelope sender* (e.g. `no-reply@sharepointonline.com`) and *not* the visible "From" header.

---

## 2. "Show every M365 Group member-add operation in window T1..T2"

### a. Surface
Two surfaces, **both should be pulled and cross-checked**:

1. **Microsoft Purview Unified Audit Log** — operation name `Add member to group` (friendly) / **`AddMemberToGroup.`** (raw — note trailing dot in the docs table). ([Microsoft Learn — Audit log activities, *Microsoft Entra group administration activities*](https://learn.microsoft.com/en-us/purview/audit-log-activities#microsoft-entra-group-administration-activities))
2. **Microsoft Entra audit log** — activity display name `"Add member to group"`. ([Microsoft Learn — Microsoft Entra audit log activity reference](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-audit-activities))

### b. Query

**UAL (preferred — longer retention, single store for all 6 surfaces in this report):**

```powershell
Connect-ExchangeOnline   # UAL is queried via the EXO connection

$sessionId = "dce-incident-grp-$(New-Guid)"
$results = @()
do {
    $page = Search-UnifiedAuditLog `
        -StartDate "2026-05-12T00:00:00Z" `
        -EndDate   "2026-05-15T23:59:59Z" `
        -Operations "Add member to group","AddMemberToGroup" `
        -ResultSize 5000 `
        -SessionId $sessionId `
        -SessionCommand ReturnLargeSet
    $results += $page
} while ($page.Count -gt 0)

$results |
    Select-Object CreationDate, UserIds, Operations,
        @{n="AppId";e={ ($_.AuditData | ConvertFrom-Json).ApplicationId }},
        @{n="GroupId";e={ ($_.AuditData | ConvertFrom-Json).ObjectId }},
        @{n="MemberAdded";e={
            (($_.AuditData | ConvertFrom-Json).ModifiedProperties |
             Where-Object Name -eq 'Member').NewValue
        }} |
    Export-Csv ./out/dce-incident-groupadds.csv -NoTypeInformation
```

**Entra audit log via Microsoft Graph PowerShell (cross-check):**

```powershell
Connect-MgGraph -Scopes AuditLog.Read.All,Directory.Read.All

Get-MgAuditLogDirectoryAudit `
    -Filter "activityDisplayName eq 'Add member to group' and
             activityDateTime ge 2026-05-12T00:00:00Z and
             activityDateTime le 2026-05-15T23:59:59Z" `
    -All |
    Select-Object activityDateTime,
        @{n="Actor";e={ $_.InitiatedBy.App.DisplayName ?? $_.InitiatedBy.User.UserPrincipalName }},
        @{n="ActorAppId";e={ $_.InitiatedBy.App.AppId }},
        @{n="TargetGroup";e={ ($_.TargetResources | Where-Object Type -eq 'Group').DisplayName }},
        @{n="MemberAdded";e={ ($_.TargetResources | Where-Object Type -eq 'User').UserPrincipalName }} |
    Export-Csv ./out/dce-incident-groupadds-entra.csv -NoTypeInformation
```

### c. Retention
- **UAL — Audit (Standard)**: **180 days** (since 2023-10-17; was 90 days before). ([Microsoft Learn — Manage audit log retention policies](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies))
- **UAL — Audit (Premium)**: **365 days** by default for Microsoft Entra / Exchange / SharePoint / OneDrive workloads. Requires E5 / Purview Suite / E5 eDiscovery & Audit add-on **on the user who generated the event**. ([same page](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies))
- **Entra audit log**: **7 days (Entra ID Free) / 30 days (Entra ID P1) / 30 days (Entra ID P2)**. ([Microsoft Learn — Microsoft Entra data retention](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-reports-data-retention))

### d. License
- UAL: any E3 / Business Premium / EXO Plan 1 (Standard). E5 / Purview audit add-on for 365-day retention and Premium features.
- Entra audit log: Entra ID Free is enough to *see* the data for 7 days; P1/P2 extends to 30 days.

### e. URL
- https://learn.microsoft.com/en-us/purview/audit-log-activities#microsoft-entra-group-administration-activities
- https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-audit-activities
- https://learn.microsoft.com/en-us/powershell/module/exchange/search-unifiedauditlog?view=exchange-ps
- https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.reports/get-mgauditlogdirectoryaudit?view=graph-powershell-1.0

### f. Gotchas
- **`Add member to group` triggers the M365 Group welcome email** *only* when the group's `UnifiedGroupWelcomeMessageEnabled` was `$true` at the time of the add. The audit log records the add but does **not** record whether the welcome email was sent — you must cross-reference Message Trace for `MicrosoftOffice365@email.microsoftonline.com` → recipient.
- **Operation-name typo in the docs table** — the *raw* operation name listed by Microsoft is **`AddMemberToGroup.`** (with a trailing period). In practice the UAL records it as `Add member to group` (friendly) — query for both to be safe.
- **`Search-UnifiedAuditLog` paging caveat:** `ReturnLargeSet` returns *unsorted* data, paged to 50 000 max; `ReturnNextPreviewPage` (the default) is sorted but caps at 5 000. For an incident investigation use `ReturnLargeSet` + a single `SessionId` and dedupe in post. ([Microsoft Learn — `Search-UnifiedAuditLog`](https://learn.microsoft.com/en-us/powershell/module/exchange/search-unifiedauditlog?view=exchange-ps))
- **Ingestion latency:** UAL events can take **30 min – 24 h** to appear (longer for some Teams events). Re-run the query the next day for any near-end-of-window events.
- **Entra audit log is the wrong surface for forensics older than ~25 days** on P1/P2 — go to UAL.

---

## 3. "Show every B2B invitation sent in window T1..T2"

### a. Surface
- **Entra audit log** activity `"Invite external user"` (and `"Invite external user with reset invitation status"`). ([Microsoft Learn — Entra audit activity reference](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-audit-activities))
- **UAL** equivalent: friendly **"User invited"**, raw **`UserInvited`**. ([Microsoft Learn — Audit log activities](https://learn.microsoft.com/en-us/purview/audit-log-activities))

### b. Query

```powershell
# Entra (richest detail — has sendInvitationMessage in additionalDetails)
Get-MgAuditLogDirectoryAudit `
    -Filter "activityDisplayName eq 'Invite external user' and
             activityDateTime ge 2026-05-12T00:00:00Z and
             activityDateTime le 2026-05-15T23:59:59Z" `
    -All |
    ForEach-Object {
        $inv = $_.AdditionalDetails | Where-Object Key -in 'invitedUserEmailAddress','sendInvitationMessage','invitationMessage'
        [pscustomobject]@{
            When                  = $_.ActivityDateTime
            ActorApp              = $_.InitiatedBy.App.DisplayName
            ActorAppId            = $_.InitiatedBy.App.AppId
            ActorSpId             = $_.InitiatedBy.App.ServicePrincipalId
            InvitedUserEmail      = ($_.TargetResources | Where-Object Type -eq 'User').UserPrincipalName
            SendInvitationMessage = ($inv | Where-Object Key -eq 'sendInvitationMessage').Value
            InvitationRedirectUrl = ($inv | Where-Object Key -eq 'invitationRedirectUrl').Value
        }
    } |
    Export-Csv ./out/dce-incident-b2b-invites.csv -NoTypeInformation
```

### c. Retention
- Entra audit: 30 d (P1/P2), 7 d (Free). ([Entra data retention](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-reports-data-retention))
- UAL: 180 d Standard / 365 d Premium-E5. ([Audit log retention policies](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies))

### d. License
- Reading the audit: Entra ID Free is enough (within 7 days); P1 for 30 days.
- Creating B2B invites with `User.Invite.All` requires no extra license; *consuming* a guest costs an Entra External ID MAU after 50 K free.

### e. URL
- https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-audit-activities
- https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-1.0 — the `sendInvitationMessage: Boolean` property: *"Indicates whether an email should be sent to the user being invited. The default is false."*
- https://learn.microsoft.com/en-us/graph/api/resources/directoryaudit?view=graph-rest-1.0
- https://learn.microsoft.com/en-us/graph/api/resources/auditactivityinitiator?view=graph-rest-1.0

### f. Gotchas
- **`sendInvitationMessage` defaults to `false`** per the Graph `invitation` resource docs. If your script reads `True`, *someone explicitly opted in to mail* in the provisioning code — this is your smoking gun. Grep the repo for `sendInvitationMessage` / `-SendInvitationMessage` / `SendMail = $true`.
- The actual outbound email is recorded in **Message Trace** as a separate event, sender typically `invites@microsoft.com` or `no-reply@microsoft.com` — correlate by recipient + ±30 s.
- The `invitationMessage` value (the custom body) **may be redacted in `AdditionalDetails`** — only the Boolean `sendInvitationMessage` is reliably present. To get the body you used, recover it from your source code (the script that called `New-MgInvitation`).
- Entra audit log's `TargetResources[?Type=='User'].UserPrincipalName` for B2B invitees often holds the **`#EXT#`-style UPN as resolved**, not the raw email address used in the invite — use `AdditionalDetails.invitedUserEmailAddress` for the original address.

---

## 4. "Show every SharePoint sharing event (with email send = true) in window T1..T2"

### a. Surface
**UAL — SharePoint sharing schema**. Operation list (friendly → raw):

| Friendly name | Raw `Operation` | Sends mail? |
|---|---|---|
| Created sharing invitation | `SharingInvitationCreated` | **Yes** (always — sends "X shared *Y* with you") |
| Accepted sharing invitation | `SharingInvitationAccepted` | No — recipient action |
| Updated sharing invitation | `SharingInvitationUpdated` | Maybe (re-sends if it was an email invite) |
| Blocked sharing invitation | `SharingInvitationBlocked` | No |
| Shared file, folder, or site | `SharingSet` | **Conditional** — fires whenever a permission entry is created; email goes only if the share UI / API was told to notify |
| Created secure link | `SecureLinkCreated` | No on its own; **`AddedToSecureLink` + email param** is the mailing surface |
| Added user to secure link | `AddedToSecureLink` | **Conditional** — depends on `sendEmail` parameter at link-grant time |
| Created an anonymous link | `AnonymousLinkCreated` | No, but the *act of sending* the link by email shows up as a separate sharing event |
| Created a company shareable link | `CompanyLinkCreated` | No (org-wide link) |

Full table: ([Microsoft Learn — Audit log activities, *Sharing and access request activities*](https://learn.microsoft.com/en-us/purview/audit-log-activities#sharing-and-access-request-activities)).

Field schema lives in the Office 365 Management Activity API: ([Microsoft Learn — Office 365 Management Activity API schema, *SharePoint Sharing schema*](https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#sharepoint-sharing-schema)). Key fields:
- `TargetUserOrGroupName` — who got the share.
- `TargetUserOrGroupType` — `Member`, `Guest`, `SharePointGroup`, `SecurityGroup`.
- `SharingType` — `View`, `Edit`, `Owner`, `Review`, …
- `EventData` — XML/JSON blob with link metadata.
- `UserSharedWith` — populated on `SharingSet` rows.

### b. Query

```powershell
$ops = @(
    "SharingInvitationCreated",   # always emails
    "SharingSet",                 # may email
    "AddedToSecureLink",          # may email
    "SecureLinkCreated",
    "AnonymousLinkCreated",
    "CompanyLinkCreated",
    "SharingInvitationUpdated"
)

$sessionId = "dce-sp-share-$(New-Guid)"
$all = @()
do {
    $batch = Search-UnifiedAuditLog `
        -StartDate "2026-05-12T00:00:00Z" -EndDate "2026-05-15T23:59:59Z" `
        -Operations $ops `
        -RecordType SharePointSharingOperation `
        -ResultSize 5000 -SessionId $sessionId -SessionCommand ReturnLargeSet
    $all += $batch
} while ($batch.Count)

$all | ForEach-Object {
    $d = $_.AuditData | ConvertFrom-Json
    [pscustomobject]@{
        When            = $_.CreationDate
        Op              = $d.Operation
        ActorUPN        = $d.UserId            # app@sharepoint when app-only
        ActorAppId      = $d.ApplicationId
        Site            = $d.SiteUrl
        Object          = $d.ObjectId
        SharedWithUPN   = $d.TargetUserOrGroupName
        SharedWithType  = $d.TargetUserOrGroupType
        SharingType     = $d.SharingType
        EventData       = $d.EventData         # link metadata blob
    }
} | Export-Csv ./out/dce-incident-sp-sharing.csv -NoTypeInformation
```

### c. Retention
UAL retention as in §2. `SharePoint` is one of the four "long" workloads that gets **365 days by default** under Audit (Premium) for E5 users.

### d. License
- Reading the events: any plan that includes UAL (E3, Business Premium, etc.).
- 365-day retention requires **E5 / Purview Suite / E5 eDiscovery & Audit add-on** on the user (or app) that generated the event.

### e. URL
- https://learn.microsoft.com/en-us/purview/audit-log-activities#sharing-and-access-request-activities
- https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#sharepoint-sharing-schema

### f. Gotchas
- **An email is sent only when the sharing API was called with the `sendEmail`/`notify` flag.** The audit row records the *grant*, not the mail. You cannot tell from the UAL row alone whether mail was sent — **always join to Message Trace** on `RecipientAddress = TargetUserOrGroupName`, `Sender = no-reply@sharepointonline.com`, ±60 s.
- **`SharingInvitationCreated` is the one operation that always emails** the invitee (the invitation *is* a mail). Other ops are conditional.
- **`UserId` is `app@sharepoint` for app-only flows** — this is documented: *"In SharePoint, another value display in the UserId property is `app@sharepoint`. This value indicates the 'user' who performed the activity was an application that has the necessary permissions in SharePoint to perform organization-wide actions."* ([Office 365 Management Activity API schema, *Common schema, UserId field*](https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#common-schema)). The **real app GUID is in `ApplicationId`** (always populated for app-only).
- **`EventData` is a serialised string** (XML on older events, JSON on newer); parse defensively.
- **`SharingSet` fires on every permission change**, including programmatic re-grants by your provisioning script even when no human-visible "share" UI happened — expect noise and dedupe by `(Object, SharedWithUPN, SharingType)`.

---

## 5. "Show every Teams team / channel / member add in window T1..T2"

### a. Surface
**UAL — Teams schema**. Operations (friendly → raw): ([Microsoft Learn — Audit log activities, *Teams activities*](https://learn.microsoft.com/en-us/purview/audit-log-activities#teams-activities))

| Friendly | Raw `Operation` |
|---|---|
| Created team | `TeamCreated` |
| Added channel | `ChannelAdded` |
| Added members | `MemberAdded` |
| Changed role of members in team | `MemberRoleChanged` |
| User signed in to Teams | `TeamsSessionStarted` |

### b. Query

```powershell
$tops = @("TeamCreated","ChannelAdded","MemberAdded","MemberRoleChanged")
$sessionId = "dce-teams-$(New-Guid)"
$all = @()
do {
    $b = Search-UnifiedAuditLog `
        -StartDate "2026-05-12T00:00:00Z" -EndDate "2026-05-15T23:59:59Z" `
        -Operations $tops `
        -RecordType MicrosoftTeams `
        -ResultSize 5000 -SessionId $sessionId -SessionCommand ReturnLargeSet
    $all += $b
} while ($b.Count)

$all | ForEach-Object {
    $d = $_.AuditData | ConvertFrom-Json
    [pscustomobject]@{
        When        = $_.CreationDate
        Op          = $d.Operation
        ActorUPN    = $d.UserId
        ActorAppId  = $d.ApplicationId
        TeamName    = $d.TeamName
        TeamId      = $d.AADGroupId
        ChannelName = $d.ChannelName
        Members     = ($d.Members | ForEach-Object UPN) -join ';'
    }
} | Export-Csv ./out/dce-incident-teams.csv -NoTypeInformation
```

### c. Retention
UAL retention (180 d Standard / 365 d Premium-E5). Teams audit data is NOT in the "long" workloads list (which is AAD/Exchange/SP/OneDrive), so **Teams records are 180 d Standard** unless covered by a custom 365 d retention policy. ([Audit log retention policies](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies))

### d. License
E3 / Business Premium covers it. Custom 365-d policy for Teams requires Audit (Premium) / E5.

### e. URL
- https://learn.microsoft.com/en-us/purview/audit-log-activities#teams-activities
- https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schemas (Teams workload schema is in the same family; the per-workload Teams schema is documented under *Microsoft Teams schema* on the same API page)

### f. Gotchas
- **Teams ingestion latency is the worst of the bunch** — Microsoft does not publish an SLA but field reports of **2–24 h, occasionally 48 h**, are common. Re-pull the query.
- **`MemberAdded` does not by itself send a Teams email**, but the corresponding M365 Group `AddMemberToGroup` event (which always fires alongside) **does** trigger the group welcome mail when enabled. The "you've been added to Team X" Activity-feed notification is in-app, not email.
- **Team creation auto-creates the backing M365 Group** — so a single `TeamCreated` will typically generate one `TeamCreated` + one `AddGroup` + one `AddMemberToGroup` per owner in the UAL. Expect 3× row volume.
- **`AADGroupId` is the join key** to §2 group adds and to §1 message trace (group SMTP address resolves from this).

---

## 6. "Correlate the audit events back to the specific automated identity"

### a. Where the actor identity lives in each schema

| Surface | Field for app-only actor | What the value looks like for `DeltaCrown-PnP-Provisioning` |
|---|---|---|
| UAL (SharePoint workload) | `UserId` | Literal string **`app@sharepoint`** — *not* the app name or GUID. ([source — common schema, UserId](https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#common-schema)) |
| UAL (any workload) | `ApplicationId` | **The Microsoft Entra appId GUID** — *"The ID of the application performing the operation."* ([source — common schema, ApplicationId](https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#common-schema)) |
| UAL (any workload) | `UserType` | **`6` = ServicePrincipal** or **`5` = Application**. ([source — common schema, UserType / FormsUserTypes enum](https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#common-schema)) |
| UAL (Entra/AAD workload) | `Actor` collection (`IdentityTypeValuePair`) | Contains the appId GUID, the SPN object ID, and the UPN-style claim. ([source — Azure Active Directory schema](https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#azure-active-directory-schema)) |
| Entra audit log (Graph) | `initiatedBy.app` (an `appIdentity`) with **`appId`**, **`displayName`**, **`servicePrincipalId`**, **`servicePrincipalName`**. ([source — appIdentity](https://learn.microsoft.com/en-us/graph/api/resources/appidentity?view=graph-rest-1.0)) | `displayName = "DeltaCrown-PnP-Provisioning"`, `appId = <GUID>`, `servicePrincipalId = <SP object id>` |
| Entra audit log (Graph) | `initiatedBy.user` | **`null`** for app-only — the presence of `.app` and absence of `.user` is the canonical "this was app-only" signal. ([source — auditActivityInitiator](https://learn.microsoft.com/en-us/graph/api/resources/auditactivityinitiator?view=graph-rest-1.0)) |

### b. Canonical correlation query (cross-surface)

```powershell
# 1. Resolve our app
$app  = Get-MgApplication -Filter "displayName eq 'DeltaCrown-PnP-Provisioning'"
$sp   = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"

"AppId        = $($app.AppId)"
"SPObjectId   = $($sp.Id)"
"AppDisplay   = $($app.DisplayName)"

# 2. UAL — filter by ApplicationId
Search-UnifiedAuditLog `
    -StartDate 2026-05-12 -EndDate 2026-05-15 `
    -FreeText  $app.AppId `
    -ResultSize 5000

# 3. Entra audit — filter by initiator
Get-MgAuditLogDirectoryAudit `
    -Filter "initiatedBy/app/appId eq '$($app.AppId)' and
             activityDateTime ge 2026-05-12T00:00:00Z and
             activityDateTime le 2026-05-15T23:59:59Z" -All
```

### c. Gotchas
- **In the SharePoint workload `UserId` will read `app@sharepoint` for ALL apps** — it is *not* unique to your app. The only reliable disambiguator inside SP rows is **`ApplicationId` (the GUID)**. If you only had `UserId`, you would falsely lump together every app that touched SP.
- **For delegated (user-context) flows the `UserId` is the user UPN and `ApplicationId` is the client app GUID** — *both are present*; an event with both populated and `UserType ≠ 5/6` is delegated, not app-only.
- **Entra audit `initiatedBy.user` can be non-null even for managed identities / system-assigned identities** in unusual cases (e.g. on-behalf-of). Use the presence of `.app.appId` as positive evidence rather than the absence of `.user`.
- **Cross-tenant calls:** when `dce-sharepoint-deploy` runs against `httbrands` resources via cross-tenant access, the **`ActorContextId` (Entra workload) / `OrganizationId` (UAL)** identifies which tenant *recorded* the event — pull from BOTH tenants and dedupe by `IntraSystemsId` / correlation ID.

### d/e. URL
- https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#common-schema
- https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#azure-active-directory-schema
- https://learn.microsoft.com/en-us/graph/api/resources/auditactivityinitiator?view=graph-rest-1.0
- https://learn.microsoft.com/en-us/graph/api/resources/appidentity?view=graph-rest-1.0

---

## 7. Retrieving the actual email bodies — Purview Content search

### a. Surface
**Microsoft Purview portal → Solutions → eDiscovery → Content search** (the standalone "Content search" tool inside the new unified eDiscovery experience). Classic standalone Content Search was **retired on 2025-08-31**; today the equivalent lives inside eDiscovery (Standard). ([Microsoft Learn — Get started with Content search](https://learn.microsoft.com/en-us/purview/ediscovery-content-search))

PowerShell equivalent: **`New-ComplianceSearch`** / **`Start-ComplianceSearch`** / **`New-ComplianceSearchAction`** in the **Security & Compliance PowerShell** (`Connect-IPPSSession`). These remain supported.

### b. Query

UI / KQL (Keyword Query Language for eDiscovery): ([Microsoft Learn — Keyword queries and search conditions for eDiscovery](https://learn.microsoft.com/en-us/purview/ediscovery-keyword-queries-and-search-conditions))

```text
(from:no-reply@sharepointonline.com OR
 from:MicrosoftOffice365@email.microsoftonline.com OR
 from:invites@microsoft.com OR
 from:no-reply@microsoft.com OR
 from:noreply@email.teams.microsoft.com)
AND received>=2026-05-12 AND received<=2026-05-15
AND (subject:"shared" OR subject:"invited you" OR subject:"Welcome to" OR
     subject:"added you" OR subject:"You've joined")
```

PowerShell:

```powershell
Connect-IPPSSession

# 1. Identify the recipient population (the ~52 HTT users) — keep this list in a file.
$recipients = Get-Content ./affected-users.txt   # one UPN per line

# 2. Create the search scoped to those mailboxes
New-ComplianceSearch `
    -Name "DCE-Incident-2026-05-Welcome-Mails" `
    -ExchangeLocation $recipients `
    -ContentMatchQuery @'
(from:no-reply@sharepointonline.com OR from:MicrosoftOffice365@email.microsoftonline.com OR from:invites@microsoft.com OR from:noreply@email.teams.microsoft.com)
AND received>=2026-05-12 AND received<=2026-05-15
'@

Start-ComplianceSearch -Identity "DCE-Incident-2026-05-Welcome-Mails"

# 3. Preview / export results (export requires eDiscovery Manager role)
New-ComplianceSearchAction `
    -SearchName "DCE-Incident-2026-05-Welcome-Mails" `
    -Export `
    -Format Fxstream    # PST / individual messages
```

### c. Retention
Content search does not have its own retention — it searches *live mailbox content*. As long as the recipient hasn't deleted the messages (or they aren't past the recoverable-items window of 14 d default / 30 d max), they are recoverable.

### d. License
- **eDiscovery (Standard)** / Content search: included with **E3 / G3 / A3** and equivalents.
- **eDiscovery (Premium)** (advanced review, custodian holds, analytics): **E5 / G5 / A5** or Microsoft 365 E5 eDiscovery & Audit add-on.
- Caller must be a member of the **eDiscovery Manager** role group in Purview.

### e. URL
- https://learn.microsoft.com/en-us/purview/ediscovery-content-search
- https://learn.microsoft.com/en-us/purview/ediscovery-keyword-queries-and-search-conditions
- https://learn.microsoft.com/en-us/powershell/module/exchange/new-compliancesearch?view=exchange-ps
- https://learn.microsoft.com/en-us/powershell/module/exchange/new-compliancesearchaction?view=exchange-ps

### f. Gotchas
- **The recipients are in `httbrands.onmicrosoft.com`, not in `deltacrown`.** You must run Content search **in the HTT tenant** (or use a cross-tenant eDiscovery setup, which requires both tenants to be linked) — your deploy app's appId is **not** what you want to search by here; you want the *recipient* mailboxes.
- **You need explicit eDiscovery Manager rights in the HTT tenant** — almost certainly *not* what `dce-sharepoint-deploy` has. Escalate to the HTT global admin / compliance officer to run the search, *do not provision your dev app for it*.
- **Classic Content Search retirement (2025-08-31)** — old docs/scripts referencing `https://compliance.microsoft.com → Content search` blade will 404. Use the new unified eDiscovery experience.
- **Subject-line redaction:** none, but be aware **the message body may contain the recipient's name, the shared resource URL, and a custom invitation message** — treat the export as **personal data** and store it inside a restricted, retention-labelled location.
- **Preview vs Export:** `Preview` shows up to 100 items per mailbox in-browser; full export is via `New-ComplianceSearchAction -Export` and may take hours.

---

## 8. Blast-radius report — schema for the runbook artefact

Recommend **two co-located artefacts** for the runbook:

1. **`incident-blast-radius.csv`** — flat row per *(recipient × email)*, suitable for the apology mail-merge.
2. **`incident-blast-radius.json`** — structured envelope describing the incident, the commits, the queries used, and the rows above, suitable for permanent retention as evidence.

### CSV schema (`incident-blast-radius.csv`)

| Column | Source | Notes |
|---|---|---|
| `incident_id` | constant | e.g. `INC-2026-05-12-DCE-WELCOME-SPAM` |
| `recipient_upn` | Message Trace `RecipientAddress` | The HTT user who received an email |
| `recipient_display_name` | Graph `GET /users/{upn}` lookup | For the apology mail-merge |
| `email_sent_at_utc` | Message Trace `Received` | ISO 8601 UTC |
| `envelope_sender` | Message Trace `SenderAddress` | e.g. `no-reply@sharepointonline.com` |
| `subject` | Message Trace Detail | from `Get-MessageTraceDetail` |
| `message_trace_id` | Message Trace `MessageTraceId` | join key |
| `email_class` | derived | one of `sp_sharing`, `m365_group_welcome`, `b2b_invite`, `teams_add`, `other` |
| `trigger_audit_event_id` | UAL `Id` / Entra `id` | the audit row that caused the mail |
| `trigger_audit_operation` | UAL `Operation` | e.g. `SharingInvitationCreated` |
| `trigger_audit_workload` | UAL `Workload` | `SharePoint`, `AzureActiveDirectory`, `MicrosoftTeams`, … |
| `trigger_object_id` | UAL `ObjectId` / `AADGroupId` / `SiteUrl` | what was provisioned |
| `actor_app_id` | UAL `ApplicationId` / Entra `initiatedBy.app.appId` | should be the DeltaCrown-PnP-Provisioning GUID |
| `actor_app_display_name` | Entra `initiatedBy.app.displayName` | sanity-check |
| `actor_sp_object_id` | Entra `initiatedBy.app.servicePrincipalId` | for IAM follow-up |
| `provisioning_commit_sha` | git correlate by timestamp | one of `834f516`, `1cad240`, `a6dd3f5` |
| `provisioning_run_id` | CI/CD log correlate by timestamp | optional |
| `apology_sent_at_utc` | filled by remediation script | populated after the apology mail-merge runs |
| `apology_message_id` | filled by remediation script | for audit trail of the apology itself |

### JSON envelope (`incident-blast-radius.json`)

```jsonc
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "incident": {
    "id": "INC-2026-05-12-DCE-WELCOME-SPAM",
    "severity": "P0",
    "opened_utc": "2026-05-12T00:00:00Z",
    "discovered_utc": "2026-05-16T00:00:00Z",
    "closed_utc": null,
    "summary": "DCE provisioning automation sent unsolicited welcome / sharing / invitation emails to ~52 HTT corporate users.",
    "tenants_affected": ["httbrands.onmicrosoft.com"],
    "tenants_origin":   ["deltacrown.onmicrosoft.com"],
    "estimated_recipient_count": 52
  },
  "automation_identity": {
    "tenant": "deltacrown.onmicrosoft.com",
    "app_display_name": "DeltaCrown-PnP-Provisioning",
    "app_id": "<GUID>",
    "service_principal_object_id": "<GUID>",
    "auth_mode": "app-only (certificate)",
    "expected_actor_in_audit": {
      "sharepoint_workload_UserId": "app@sharepoint",
      "all_workloads_ApplicationId": "<GUID>",
      "all_workloads_UserType_enum": 6,
      "entra_initiatedBy_app_appId": "<GUID>"
    }
  },
  "triggering_changes": [
    { "commit": "834f516", "timestamp_utc": "2026-05-12T??:??:??Z", "scripts": ["phase2-week1/scripts/2.0-Master-Provisioning.ps1"] },
    { "commit": "1cad240", "timestamp_utc": "2026-05-14T??:??:??Z", "scripts": ["phase3-week2/scripts/..."]              },
    { "commit": "a6dd3f5", "timestamp_utc": "2026-05-15T??:??:??Z", "scripts": ["phase3-week2/scripts/..."]              }
  ],
  "queries_run": [
    { "surface": "EXO MessageTrace",  "cmd": "Get-MessageTrace ...", "ran_utc": "2026-05-16T??Z", "rows_returned": 0 },
    { "surface": "Purview UAL (SP)",   "cmd": "Search-UnifiedAuditLog -Operations SharingInvitationCreated,SharingSet,...", "ran_utc": "...", "rows_returned": 0 },
    { "surface": "Purview UAL (Group)","cmd": "Search-UnifiedAuditLog -Operations 'Add member to group',AddMemberToGroup", "ran_utc": "...", "rows_returned": 0 },
    { "surface": "Purview UAL (Teams)","cmd": "Search-UnifiedAuditLog -Operations TeamCreated,ChannelAdded,MemberAdded,MemberRoleChanged", "ran_utc": "...", "rows_returned": 0 },
    { "surface": "Entra audit (B2B)",  "cmd": "Get-MgAuditLogDirectoryAudit -Filter \"activityDisplayName eq 'Invite external user'\"", "ran_utc": "...", "rows_returned": 0 },
    { "surface": "Purview Content search", "cmd": "New-ComplianceSearch ...", "ran_utc": "...", "items_previewed": 0, "items_exported": 0 }
  ],
  "events": [
    {
      "recipient_upn": "user@httbrands.com",
      "recipient_display_name": "Jane Doe",
      "email_sent_at_utc": "2026-05-12T14:32:11Z",
      "envelope_sender": "no-reply@sharepointonline.com",
      "subject": "Tyler shared 'DCE Hub' with you",
      "message_trace_id": "c20e0f7a-f06b-41df-fe33-08d9da155ac1",
      "email_class": "sp_sharing",
      "trigger_audit_event_id": "<UAL Id>",
      "trigger_audit_operation": "SharingInvitationCreated",
      "trigger_audit_workload": "SharePoint",
      "trigger_object_id": "https://deltacrown.sharepoint.com/sites/dce-hub",
      "actor_app_id": "<GUID>",
      "actor_app_display_name": "DeltaCrown-PnP-Provisioning",
      "actor_sp_object_id": "<GUID>",
      "provisioning_commit_sha": "834f516",
      "provisioning_run_id": "gh-actions-run-...",
      "apology_sent_at_utc": null,
      "apology_message_id": null
    }
  ]
}
```

### Recommended file layout

```
research/notification-suppression/
  audit-forensics.md                    ← this document
  raw-findings/
    dce-incident-messagetrace.csv       ← § 1 output
    dce-incident-sp-sharing.csv         ← § 4 output
    dce-incident-groupadds.csv          ← § 2 output (UAL)
    dce-incident-groupadds-entra.csv    ← § 2 output (Entra cross-check)
    dce-incident-teams.csv              ← § 5 output
    dce-incident-b2b-invites.csv        ← § 3 output
  incident-blast-radius.csv             ← § 8 mail-merge feed
  incident-blast-radius.json            ← § 8 evidence envelope
  affected-users.txt                    ← curated recipient UPN list
```

---

## Project-specific recommendations

> Tailored to **DeltaSetup** repo: `phase2-week1/`, `phase3-week2/`, `phase4-migration/` provisioning scripts; PnP.PowerShell ≥ 2.0 + Microsoft.Graph ≥ 2.0 + ExchangeOnlineManagement ≥ 3.0; two-tenant model (`deltacrown` origin, `httbrands` recipients).

1. **Run Message Trace TODAY** (within the 10-day window) for sender list = the five candidates in §1; export to `raw-findings/dce-incident-messagetrace.csv`. This is the only surface with a hard short-window deadline.
2. **Run the UAL `Search-UnifiedAuditLog` queries from §2/§4/§5 in parallel** — these have 180 d retention so are not on the critical clock, but starting them now lets the messages appear before you build the blast-radius CSV.
3. **In the `httbrands` tenant**, the HTT compliance officer (not us, not `DeltaCrown-PnP-Provisioning`) must run the Content search from §7 against the affected mailboxes. Coordinate this via the existing MEGAN brief channel (`MEGAN-CALL-BRIEF-2026-05-06.md`).
4. **Cross-correlate `ApplicationId` GUID to the commits** — pull `git log --since=2026-05-11 --until=2026-05-16 --pretty='%h %ci %s'` and align timestamps with the audit `CreationDate`. Add the `provisioning_commit_sha` column on the CSV.
5. **Add a permanent CI gate**: before any future `New-MgInvitation` / `Set-PnPListItemPermission` / `Add-UnifiedGroupLinks` call, the wrapping script must:
   - Set `sendInvitationMessage = $false` by default.
   - Set `Set-UnifiedGroup -UnifiedGroupWelcomeMessageEnabled $false` immediately after `New-UnifiedGroup`.
   - Use the `-SendEmail:$false` form on every PnP sharing cmdlet.
   - Open a separate `bd` issue if any of those flags is overridden.
6. **File a follow-up bd issue** to enable **Purview Audit (Premium)** on the `deltacrown` tenant if not already on (this gives you 365-day retention and faster search); current evidence (`docs/delta-crown-security-apps-licenses-inventory-summary.md`) does not confirm tier.

---

## Sources & credibility (Tier 1 = official Microsoft Learn primary docs)

| # | URL | Tier | Last updated visible? | Used for |
|---|---|---|---|---|
| S1 | https://learn.microsoft.com/en-us/powershell/module/exchange/get-messagetrace?view=exchange-ps | 1 | Yes (Microsoft maintained) | § 1 — 10-day window, V2 successor, output fields |
| S2 | https://learn.microsoft.com/en-us/powershell/module/exchange/start-historicalsearch?view=exchange-ps | 1 | Yes | § 1 — 90-day window, 250/24h quota |
| S3 | https://learn.microsoft.com/en-us/powershell/module/exchange/search-unifiedauditlog?view=exchange-ps | 1 | Yes | § 2/4/5 — UAL cmdlet, paging, latency note |
| S4 | https://learn.microsoft.com/en-us/purview/audit-log-activities | 1 | Yes | § 2/4/5 — operation name tables (SP sharing, Teams, Entra groups) |
| S5 | https://learn.microsoft.com/en-us/purview/audit-log-retention-policies | 1 | Yes | § 2/4/5 — 180 d Standard / 365 d Premium retention |
| S6 | https://learn.microsoft.com/en-us/purview/audit-solutions-overview | 1 | Yes | License tiers, E5 bandwidth quotas |
| S7 | https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-audit-activities | 1 | Yes | § 2/3 — "Invite external user" / "Add member to group" activity names |
| S8 | https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-reports-data-retention | 1 | Yes | § 2/3 — Entra audit 30-day retention on P1/P2 |
| S9 | https://learn.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema | 1 | Yes | § 4/6 — UAL field schema, SP sharing fields, `app@sharepoint`, `ApplicationId`, `UserType` enum |
| S10 | https://learn.microsoft.com/en-us/graph/api/resources/directoryaudit?view=graph-rest-1.0 | 1 | Yes | § 3/6 — directoryAudit resource + initiatedBy |
| S11 | https://learn.microsoft.com/en-us/graph/api/resources/auditactivityinitiator?view=graph-rest-1.0 | 1 | Yes | § 3/6 — app vs user initiator |
| S12 | https://learn.microsoft.com/en-us/graph/api/resources/appidentity?view=graph-rest-1.0 | 1 | Yes (last updated 2025-05-30) | § 6 — appId, displayName, servicePrincipalId fields |
| S13 | https://learn.microsoft.com/en-us/graph/api/resources/invitation?view=graph-rest-1.0 | 1 | Yes | § 3 — `sendInvitationMessage: Boolean, default false` |
| S14 | https://learn.microsoft.com/en-us/graph/api/directoryaudit-list?view=graph-rest-1.0 | 1 | Yes | § 3 — Graph List directoryAudits |
| S15 | https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.reports/get-mgauditlogdirectoryaudit?view=graph-powershell-1.0 | 1 | Yes | § 3 — Graph PowerShell cmdlet |
| S16 | https://learn.microsoft.com/en-us/purview/ediscovery-content-search | 1 | Yes — notes classic retirement 2025-08-31 | § 7 — modern Content search location |
| S17 | https://learn.microsoft.com/en-us/purview/ediscovery-keyword-queries-and-search-conditions | 1 | Yes | § 7 — KQL `from:`, `subject:`, date filters |

All cited sources are **Tier 1** primary Microsoft Learn documentation maintained by Microsoft (vendor of record). Cross-checks performed:
- `Get-MessageTrace` 10-day window cross-checked against `Start-HistoricalSearch` "1–4 h to 90 days" wording — consistent.
- Entra retention (30 d on P1/P2) cross-checked against UAL retention (180 d Standard / 365 d Premium) — explains why UAL is the correct surface for any investigation > 25 days.
- `app@sharepoint` literal value cross-checked between the common-schema `UserId` definition and the `ApplicationId` GUID semantics — both pages confirm app-only attribution must come from `ApplicationId`, not `UserId`.

No Tier 2/3 sources were used.
