# DCE Hub production promotion readiness checklist

**Status:** Draft — not approval evidence  
**Tracking bead:** `DeltaSetup-3vu`  
**Scope:** approve and promote DCE Hub content to production

## Promotion gate

Do not promote until all are true:

- [ ] Approved final copy captured.
- [ ] Approved quick-link destinations captured.
- [ ] Approved library/folder structure captured.
- [ ] Launch/readiness gate passed.
- [ ] Rollback plan documented.
- [ ] Class 3 DCE SyncFabric bridge drift alerting is live, not dry-run.
- [ ] Owner approval captured in `bd`.

## Approval record

| Field | Value |
|---|---|
| Approver | TBD |
| Approval date/time | TBD |
| Approved source artifact/page | TBD |
| Production destination | TBD |
| Promotion operator | TBD |
| Rollback owner | TBD |

## Content readiness

- [ ] Hero/intro section approved.
- [ ] Quick links approved and tested.
- [ ] Department/resource sections approved.
- [ ] Placeholder/FPO text removed or explicitly approved as temporary.
- [ ] Branding assets approved by Jamie/brand owner.
- [ ] Contact/support path approved.

## Information architecture readiness

- [ ] Library names match approved target model.
- [ ] Folder structure matches approved target model.
- [ ] Navigation labels approved.
- [ ] Duplicate/stale DCE group sites are not used as promotion targets.
- [ ] HTT-side `Delta Crown Operations` site disposition is not confused with DCE Hub production promotion.

## Permission readiness

- [ ] Hub owners confirmed.
- [ ] Editors confirmed.
- [ ] Visitors/audience confirmed.
- [ ] Permission inheritance breaks reviewed.
- [ ] No broad exposure beyond intended audience.
- [ ] External sharing posture reviewed.

## Technical validation

- [ ] Source page/apply artifact identified.
- [ ] Production apply plan reviewed.
- [ ] Dry-run or dev apply evidence reviewed.
- [ ] Desktop screenshot captured.
- [ ] Mobile/narrow screenshot captured.
- [ ] Key links tested.
- [ ] No console/apply errors in deployment evidence.

## Rollback plan

1. Export/capture current production page state.
2. Export/capture approved source state.
3. Apply promotion.
4. Validate production.
5. If validation fails, restore prior production page version.
6. Record rollback in `bd`.

## Post-promotion checks

- [ ] Production page renders.
- [ ] Intended users can access.
- [ ] Editors can edit expected areas.
- [ ] Non-intended users cannot access restricted areas.
- [ ] Owner confirms final state.
- [ ] `bd` note includes evidence links/screenshots.

## Explicit non-goals

- Do not use this checklist as approval by itself.
- Do not send launch communications from this checklist.
- Do not change sync scope, app assignments, or Teams/channel settings as part of hub promotion.
