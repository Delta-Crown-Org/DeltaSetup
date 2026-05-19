# Notification-suppression empirical canary runbook

**Status:** Draft — not approval evidence  
**Tracking beads:** `DeltaSetup-j3c`, `DeltaSetup-33c`  
**Mode:** canary-only; no production cohort changes

## Purpose

Verify that Microsoft 365 notification-suppression assumptions still hold in the live tenant environment before tenant-wide use.

This runbook prepares the canary path only. It does not authorize execution.

## Guardrails

- Use a dedicated canary mailbox only.
- Do not add production users to test groups.
- Do not PATCH Teams moderation settings on production Teams.
- Do not send or trigger broad user-facing messages.
- Store raw mail/message-trace exports under `.local/` or approved private evidence storage.
- Commit only redacted summaries.

## Canary 1 — Cross-tenant sync silence

Goal: prove HTT-to-DCE cross-tenant sync itself does not send user-facing mail.

Prerequisites:

- [ ] Canary source user exists in HTT.
- [ ] Canary mailbox is monitored.
- [ ] Canary user is in isolated sync scope or isolated direct app assignment.
- [ ] DCE target group has welcome suppression configured where applicable.
- [ ] Message trace access is available.

Procedure:

1. Capture baseline message trace for canary mailbox.
2. Add canary to isolated sync scope.
3. Run provision-on-demand or wait for one scheduled sync cycle.
4. Confirm DCE target user appears.
5. Query message trace for the canary mailbox.
6. Expected result: zero user-facing sync invitation/welcome mail caused by cross-tenant sync.

Evidence:

- source canary object ID, redacted in committed docs;
- target canary object ID, redacted in committed docs;
- sync run ID/activity ID;
- message trace query timestamp/window;
- redacted pass/fail summary.

## Canary 2 — M365 Group welcome suppression

Goal: prove group creation/member-add suppression works for synced/canary users.

Prerequisites:

- [ ] Test M365 Group is created with `WelcomeEmailDisabled`.
- [ ] Exchange `UnifiedGroupWelcomeMessageEnabled` is false.
- [ ] Canary user is the only non-admin test recipient.

Procedure:

1. Create isolated test group with welcome suppression.
2. Add canary user.
3. Query message trace for canary mailbox.
4. Expected result: zero group welcome mail.
5. Destroy or archive the test group according to cleanup rules.

Negative control, only if explicitly approved:

- Repeat against a separate throwaway group with welcome enabled to prove the trace path can detect mail.

## Canary 3 — B2B invitation suppression

Goal: prove `sendInvitationMessage:false` remains silent.

Procedure:

1. Invite canary with `sendInvitationMessage:false`.
2. Capture returned redemption URL privately.
3. Query message trace for canary mailbox.
4. Expected result: zero invitation mail.

## Canary 4 — SharePoint invite suppression

Goal: prove Graph/PnP sharing invite suppression remains silent.

Procedure:

1. Use isolated test file/folder.
2. Grant canary access with explicit `sendInvitation:false` / no `-SendInvitation`.
3. Query message trace for canary mailbox.
4. Expected result: zero sharing invite mail.

## Canary 5 — Teams moderation notification behavior

Goal: determine whether channel moderation PATCH creates visible user activity.

Execution gate:

- Must use a test Team only.
- Must have licensed Teams-readable context.
- Must not touch production Teams.

Procedure:

1. Create or identify isolated test Team with two test members.
2. Capture baseline activity/feed/mail state for canary.
3. PATCH moderation settings on test channel.
4. Observe canary Teams activity/feed/mail state.
5. Document whether visible notification appeared.
6. Clean up test Team if it was created for the run.

## Quarterly recurrence

For `DeltaSetup-33c`, repeat at least quarterly:

- M365 Group welcome suppression;
- B2B invitation suppression;
- SharePoint invite suppression;
- cross-tenant sync silence if sync scope or MTO status changed.

Retention:

- Keep pass/fail summary for 7 years.
- Keep raw evidence in private storage per retention policy.

## Failure response

If any canary sends unexpected mail:

1. Stop tenant-wide rollout or promotion.
2. File P0 `bd` incident.
3. Pin provisioning workflows to dispatch-only.
4. Preserve message trace and audit evidence.
5. Compare PnP/Graph/Exchange module versions against last-good canary.
6. Require owner/security approval before resuming.
