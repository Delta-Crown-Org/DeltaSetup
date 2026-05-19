# Crown Connection promotion readiness checklist

**Status:** Draft — not approval evidence  
**Tracking bead:** `DeltaSetup-b0f`  
**Scope:** prepare promotion from CrownConnection-dev editable page to live Crown Connection  
**Rule:** live Crown Connection must not be used as sandbox

## Promotion gate

Do not promote until all are true:

- [ ] Owner/content approval captured in `bd`.
- [ ] Approver name/date recorded below.
- [ ] Source page identified and locked for promotion.
- [ ] Live destination identified.
- [ ] Rollback copy/export captured.
- [ ] Screenshot validation completed.
- [ ] Link validation completed.
- [ ] Permission/audience validation completed.
- [ ] Class 3 DCE SyncFabric bridge drift alerting is live, not dry-run.

## Approval record

| Field | Value |
|---|---|
| Approver | TBD |
| Approval date/time | TBD |
| Approved source page/version | TBD |
| Promotion operator | TBD |
| Rollback owner | TBD |

## Pre-promotion checks

### Content

- [ ] Page title matches approved language.
- [ ] Hero/intro copy approved.
- [ ] Owner-facing links approved.
- [ ] Contact/support path approved.
- [ ] No placeholder content remains.

### Permissions and audiences

- [ ] Owners-only audience confirmed.
- [ ] Visitors/members/owners permission groups reviewed.
- [ ] No broad `Everyone except external users` exposure unless explicitly approved.
- [ ] External sharing posture reviewed.

### Technical smoke

- [ ] Desktop view screenshot captured.
- [ ] Mobile/narrow view screenshot captured.
- [ ] Navigation links resolve.
- [ ] Document/library links resolve.
- [ ] No unauthorized prompt or access denied for intended audience.

## Rollback plan

Rollback must be available before promotion:

1. Capture current live page/export.
2. Capture promoted source page/export.
3. If post-promotion validation fails, restore prior live page or revert to documented previous version.
4. Record rollback action in `bd`.

## Post-promotion checks

- [ ] Live page renders.
- [ ] Intended audience can access.
- [ ] Non-intended audience cannot access, if applicable.
- [ ] Navigation remains intact.
- [ ] Owner confirms final state.
- [ ] `bd` note includes evidence links/screenshots.

## Explicit non-goals

- Do not send launch communications from this checklist.
- Do not add or remove owners/members as part of promotion unless separately approved.
- Do not edit live page as a sandbox.
