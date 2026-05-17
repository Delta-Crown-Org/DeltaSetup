# Recommendations — Groups + B2B + Cross-tenant Sync + OneDrive cluster

**Cluster owner:** web-puppy-fdde46
**Audience:** Tyler (Solutions Architect), Jenna (Phase-4 operator handoff), Megan (MSP brief), Security Auditor (ADR cosign)
**Project context:** DCE↔HTT SharePoint hub-and-spoke; the HTT-to-DCE-User-Sync Entra xtsync application; DeltaSetup-au3 (DCE-HTT-Corporate-Sync dynamic group); DeltaSetup-a3d (MTO evaluation)

All recommendations are derived from `m365-groups-b2b-xtsync.md` (this directory). Reproduce the citations from there or from `sources-groups-b2b.md`.

---

## P0 — Ship before the next provisioning run

### P0.1 Provisioning-script guardrails (the four levers from the TL;DR)

**Required pattern for every `New-PnPMicrosoft365Group` call in DCE provisioning:**

```powershell
# Step 1: create silently
$group = New-PnPMicrosoft365Group `
  -DisplayName       $displayName `
  -Description       $description `
  -MailNickname      $nickname `
  -Owners            $owners `
  -IsPrivate `
  -HideFromAddressLists `
  -ResourceBehaviorOptions WelcomeEmailDisabled, HideGroupInOutlook, SubscribeMembersToCalendarEventsDisabled `
  # Do NOT pass -Members here yet. Members get added in Step 3.

# Step 2: belt-and-braces — Exchange-side suppression, in case
# resourceBehaviorOptions is silently ignored on a future tenant change
# OR in case anyone re-adds the same members through another path.
Set-UnifiedGroup -Identity $group.Mail -UnifiedGroupWelcomeMessageEnabled:$false

# Step 3: now add members — silent
Add-PnPMicrosoft365GroupMember -Identity $group.Id -Users $memberUpns

# Step 4 (GUEST-USER TRAP MITIGATION):
# AutoSubscribeNewMembers does NOT apply to guest userType.
# Guests are ALWAYS subscribed to conversations on add.
# For every guest member that should NOT receive conversation copies:
foreach ($guestUpn in $guestMembers) {
  Remove-UnifiedGroupLinks -Identity $group.Mail `
    -LinkType Subscribers -Links $guestUpn -Confirm:$false
}
```

Why this exact ordering: `resourceBehaviorOptions` is creation-only (Graph rejects PATCH); `UnifiedGroupWelcomeMessageEnabled` is patchable but **only effective for adds that happen after** the PATCH commits; therefore the create-empty / disable-welcome / add-members order is the only one with zero race window.

**CI gate (recommend adding to `tests/`):** grep-fail any `New-PnPMicrosoft365Group` invocation in `phase*/`, `templates/`, `tools/` that lacks `-ResourceBehaviorOptions.*WelcomeEmailDisabled`. The PR check is two lines:

```bash
grep -rn 'New-PnPMicrosoft365Group' phase* templates tools \
  | grep -v 'WelcomeEmailDisabled' \
  && { echo "FAIL: New-PnPMicrosoft365Group without WelcomeEmailDisabled"; exit 1; } \
  || echo "OK"
```

### P0.2 B2B invitation guardrails

**Required pattern for every `POST /invitations` / `New-MgInvitation` call:**

```powershell
$invite = New-MgInvitation `
  -InvitedUserEmailAddress  $email `
  -InviteRedirectUrl        'https://myapps.microsoft.com' `
  -SendInvitationMessage:$false   # explicit, not implicit, for SDK-drift safety
  -InvitedUserType          'Guest'  # or 'Member' if admin role available and intended
# Capture $invite.InviteRedeemUrl and hand it to your comms pipeline.
```

Even though the documented default is `false`, **pin it explicitly**. The historical AzureAD / AzureADPreview modules and several early Microsoft.Graph preview drops defaulted to `true`; pinning protects against any future regression.

CI gate (grep): any `New-MgInvitation` lacking `SendInvitationMessage` fails.

### P0.3 Cross-tenant sync — leave as-is, document the assertion

The HTT-to-DCE-User-Sync Entra cross-tenant sync app does **not** need any notification-suppression configuration; per Microsoft Learn it is silent by design (citation: `cross-tenant-synchronization-overview#when-is-the-consent-prompt-suppressed`).

**Action required:** add an assertion to `12-implementation-plan.md` (mentioned in DeltaSetup-bnf) saying: "Cross-tenant sync provisioning is silent per Microsoft Learn. Any user-facing email observed during sync indicates a *downstream* trigger (Exchange welcome on M365 Group add, or SharePoint sharing invite) — not the sync itself. Diagnose by correlating timestamps in Unified Audit Log against the synced user's mailbox Message Trace."

This assertion plus the rollback-matrix work in DeltaSetup-bnf gives the operator team a clean diagnostic narrative.

---

## P1 — Schedule for Phase 4 handoff

### P1.1 Pilot canary protocol (operationalise the empirical gap)

Source: `m365-groups-b2b-xtsync.md` §3e.

Add to `phase4-migration/` a one-shot script `canary-xtsync-silence.ps1` that:

1. Creates `xtsync-canary-1@httbrands.com` as a controlled mailbox.
2. Asserts the destination DCE test M365 Group has `WelcomeEmailDisabled` in `resourceBehaviorOptions` and `UnifiedGroupWelcomeMessageEnabled=$false`.
3. Triggers a single xtsync provisioning cycle.
4. Polls the canary mailbox via Graph for 15 minutes.
5. Calls `Add-PnPMicrosoft365GroupMember` to add the synced user to the test group.
6. Polls again for 15 minutes.
7. Repeats step 5 with `UnifiedGroupWelcomeMessageEnabled=$true` to confirm the negative-control: if **that** add produces a welcome and the suppressed adds do not, the suppression is doing its job.
8. Reports the matrix to the SA.

Recommended as a pre-flight before any large HTT batch.

### P1.2 MTO evaluation — feed into DeltaSetup-a3d

The DeltaSetup-a3d MTO-membership ADR should incorporate this from §3d of the main report:

**Pro:** Joining an MTO promotes synced HTT users from `Guest` to `Member` userType. This removes the guest-autosubscribe trap (§1e item 4 of the main report) — `AutoSubscribeNewMembers:$false` would then actually work for HTT users in DCE M365 Groups. That's a meaningful reduction in notification-suppression complexity (one less fallback path).

**Con:** Notification-related changes from MTO are limited to Teams cross-tenant chat/call/meeting surfaces (richer notifications), per <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview>. There is no doc evidence that MTO adds *new* user-facing provisioning emails — i.e., MTO does not undo the cross-tenant-sync silence.

**Net:** notification-quietness is a **pro** for MTO membership, with no offsetting con on the provisioning-email axis. Other axes (licensing, identity-blast-radius, sensitivity-label tenant boundaries) are out of scope for this research and should be evaluated separately in the ADR.

### P1.3 Mental-model correction in operator runbook (Jenna handoff, DeltaSetup-x11)

In the runbook, the OneDrive admin-center "Notifications" toggle MUST be described accurately, not by folklore. Use this exact framing:

> **The OneDrive admin-center "Notifications" toggle is sharing-event telemetry to OneDrive owners — not user onboarding.**
> The four sub-toggles map to `Set-SPOTenant`:
> - `-NotificationsInOneDriveForBusinessEnabled` (master)
> - `-NotifyOwnersWhenItemsReshared`
> - `-NotifyOwnersWhenInvitationsAccepted`
> - `-OwnerAnonymousNotification`
> None of these affect provisioning emails for newly-created OneDrive personal sites. There is **no user-facing email** documented for `Request-SPOPersonalSite` or for SharePoint just-in-time OneDrive provisioning. The "Your OneDrive is ready" experience is in-app discovery on the user's next visit, not a Microsoft-sent email.

For security posture, keep `NotifyOwnersWhenInvitationsAccepted=$true` and `OwnerAnonymousNotification=$true` — these are valuable signals to file owners and should not be disabled in pursuit of "quietness".

---

## P2 — Defer / file for later

### P2.1 Bilateral auto-redemption posture review

Per the cross-tenant-collaboration lessons file (`research/cross-tenant-collaboration-m365/lessons-from-htt-projects.md` Lesson 4), bilateral inbound+outbound automatic-redemption is required for a smooth first-run. This is **not** the same suppression mechanism as cross-tenant sync's built-in silence (per §3a of main report), but it does affect the *manual B2B* fallback path that Tyler may use for one-off external partners outside the HTT scope.

Open ADR-006 cosign (DeltaSetup-jn4) should explicitly note that cross-tenant sync and bilateral auto-redemption are **independent** suppression mechanisms with overlapping outcomes — neither subsumes the other.

### P2.2 File: "Connected products are not covered by `UnifiedGroupWelcomeMessageEnabled`"

The Exchange doc explicitly carves out Teams and Viva Engage. If DCE plans Viva Engage / Yammer onboarding for HTT users, file a follow-up `bd` issue scoped to those surfaces. The Teams surface is already owned by `web-puppy-df3922` cluster (`teams.md`).

---

## Direct mapping to existing `bd` issues

| `bd` ID | What this research changes for it |
|---|---|
| DeltaSetup-au3 | `Create DCE-HTT-Corporate-Sync dynamic group` — apply the P0.1 pattern; dynamic groups still hit the Exchange welcome on member evaluation, so `WelcomeEmailDisabled` and Exchange-side switch both required |
| DeltaSetup-a3d | `MTO membership evaluation` — incorporate §3d of main report as a positive notification-quietness factor in the decision matrix |
| DeltaSetup-bnf | `Spec enhancement: rollback matrix` — add the cross-tenant-sync silence assertion + the diagnostic narrative from P0.3 |
| DeltaSetup-x11 | `Jenna operator runbook` — incorporate the P1.3 mental-model correction verbatim |
| DeltaSetup-a6a | `AADSTS500213 in 02-identity-audience.md` — separate concern (admission, not notifications) but cross-reference: cross-tenant sync silence is a property of the *provisioning* path, AADSTS500213 is a property of the *admission* path; both must succeed for a working flow |

---

## Out-of-scope cross-references

For the *other* clusters' findings (which round out the full notification picture for DeltaSetup):

- **Teams notification surfaces** → see `teams.md` and `recommendations.md` (cluster owner df3922). Especially relevant: §1 (welcome card) and §2 (member-add activity feed).
- **SharePoint sharing notifications** → see `sharepoint-sharing.md` and `recommendations.md` (cluster owner 7bc185). Especially relevant: the `-SendInvitation` PnP doc defect and the `SystemUpdate` vs `UpdateOverwriteVersion` flow-bypass matrix.
- **Forensic audit of past incident** → see `audit-forensics.md` (cluster owner 972381). Cross-validate the HTT-52 incident against this cluster's "guest-autosubscribe-trap × Exchange welcome enabled" hypothesis.
