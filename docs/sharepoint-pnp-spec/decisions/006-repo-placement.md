# ADR-006 — Repo placement: new `Delta-Crown-Org/dce-sharepoint`

**Status:** Proposed (pending owner + security sign-off)
**Date:** 2026-05-15
**Implements:** `07-ci-cd-pipeline.md`, `12-implementation-plan.md`
**Related controls:** ADR-005, ADR-009, ADR-011

## Context

We need to put PnP templates, GitHub Actions workflows, and SPFx
artifacts somewhere. Three candidates.

## Decision

Create a **new repository** `Delta-Crown-Org/dce-sharepoint`.

## Alternatives considered

### A. This repo (`Delta-Crown-Org/DeltaSetup`)

- Pro: keeps DCE knowledge centralized; gh-pages branch already has
  audit gates.
- Con: gh-pages is the public site; mixing intranet automation in is
  confusing. Also: SP-deploy workflows would trigger on gh-pages
  pushes, which is the wrong trigger surface.
- Rejected.

### B. The HTT-side `Convention-Page-Build` repo

- Pro: leverages the existing SPFx scaffold and audit scripts.
- Con: DCE is its own org with its own GitHub org (`Delta-Crown-Org`).
  Putting DCE SP code in a HTT-side repo creates a cross-org
  dependency that's hard to maintain.
- Rejected.

### C. New repo `Delta-Crown-Org/dce-sharepoint`

- Pro: clean separation, lives in the right GitHub org, can be cloned
  by DCE engineers without HTT credentials.
- Con: one more repo to maintain.
- **Selected pending sign-off.** This is the preferred placement once the owner/security sign-off below is complete.

## Consequences

- Scaffold from `Convention-Page-Build/spfx/` (copy, not fork — we'll
  diverge).
- Reference this spec pack by linking back to the DeltaSetup repo.
- Brand Center configuration also lives in this new repo (Theme JSON,
  Brand Center provisioning template).
- Build and validate against the dev site first:
  `https://deltacrown.sharepoint.com/sites/dce-hub-dev`.
- Production deploys stay behind GitHub Environment approval; the new repo
  must not run prod SharePoint mutations from ordinary branch pushes.
- Notification-capable provisioning must obey ADR-011: default `scaffold`
  mode, explicit `PROVISIONING-MODE:` logs, `WelcomeEmailDisabled` for M365
  Group creation, `sendInvitationMessage:false` for B2B invitations, and
  launch-only communications through the approved launch workflow.
- SPFx dependency choices remain blocked until ADR-010 locks Fluent UI; no
  production SPFx package should be shipped from this decision alone.

## Security sign-off checklist

Before this ADR can move to `Accepted`, the signer must verify:

- [ ] Dev-first invariant is preserved (`dce-hub-dev` before prod).
- [ ] ADR-011 suppression fitness tests pass from a clean checkout.
- [ ] Audience-targeting tests pass, including the membership-vs-ownership
      gotcha and Teams moderation BETA-only endpoint checks.
- [ ] ADR-009 is accepted or accepted in the same commit set.
- [ ] ADR-010 is scheduled before any production SPFx build.
- [ ] Rollback plan below is executable by the owner or delegate.

Latest pre-sign evidence captured by `code-puppy-73a4b6`:

```text
Command: pytest tests/architecture/test_notification_suppression.py dce-mockup/tests/architecture/test_audience_targeting.py -v
Date: 2026-05-18
Git SHA at run time: pending commit
Result: 20 passed in 0.31s
```

## Rollback plan

If the new repository placement is reversed before real content ships:

1. Disable or delete GitHub Actions environments/secrets in
   `Delta-Crown-Org/dce-sharepoint`.
2. Delete the empty/seed repository if appropriate:

   ```bash
   gh repo delete Delta-Crown-Org/dce-sharepoint --yes
   ```

3. If `bootstrap.sh` created an Entra app, delete the app and service
   principal using the IDs printed by the bootstrap output:

   ```bash
   az ad app delete --id <bootstrap-app-id>
   az ad sp delete --id <bootstrap-sp-id>
   ```

4. If only certificate credentials need to be revoked, remove the key:

   ```bash
   az ad app credential delete --id <app-id> --key-id <cert-key-id>
   ```

5. Re-open or keep open the dependent bds:
   `DeltaSetup-jn4`, `DeltaSetup-7bm`, `DeltaSetup-emj`, and
   `DeltaSetup-303`.
6. Revert the accepting commit and document the replacement placement in a
   new ADR.

## Sign-off

**Owner sign-off:** Pending — Tyler Granlund  
**Security review:** Pending — named human security reviewer or dedicated
security-auditor agent evidence bundle  
**Accepted date:** Pending

When signed, change the ADR status above to `Accepted`, paste fresh test
output with the accepting git SHA, and close `DeltaSetup-jn4` with the
accepting commit hash.
