# ADR-003 — Dynamic membership rule for `SG-DCE-Sync-Users`

**Status:** Accepted, Implemented
**Date:** 2026-05-15
**Implementing change:** Graph PATCH on group `6f5cc75e-b2ae-4ed2-992d-e56d4e3ef5f3`

## Context

Tonight we discovered that the HTT→DCE cross-tenant user sync was gated
by a STATIC security group (`SG-DCE-Sync-Users`). HR drift had caused 7 of
52 currently-licensed HTT corporate users to be missing from DCE.

## Decision

Convert `SG-DCE-Sync-Users` to a DYNAMIC group with rule:

```
(user.userPrincipalName -match ".*@httbrands\.com$") and
(user.accountEnabled -eq true)
```

## Alternatives considered

### A. Stay static, document the HR onboarding step

- Pro: zero technical change; just a process improvement.
- Con: relies on HR remembering. The current drift demonstrates this
  doesn't work.
- Rejected.

### B. Dynamic on `companyName` instead of UPN suffix

- Pro: matches the "intent" (HTT Brands company).
- Con: `companyName` is an inconsistent attribute. Not all users have
  it set; HR processes vary.
- Rejected.

### C. Multi-Tenant Organization (MTO) with DCE

- Pro: eliminates the gate group entirely; mutual user discovery.
- Con: significant tenant-policy setup; affects all current B2B flows.
- Deferred. Revisit in Q3 once cross-brand patterns stabilize.

## Consequences

- Every new enabled `@httbrands.com` user appears in DCE within 40 min.
- Disabling an HTT user removes them from the dynamic group → next sync
  cycle disables them in DCE.
- The dynamic rule includes ALL HTT-domain users including admins,
  service accounts named `@httbrands.com`, and contractors. If any
  should be excluded, the rule needs refinement.
- We lose the "scope-out" ability via group membership; need to use
  attribute filters instead.

## Open follow-ups

- Audit: any HTT users who SHOULD NOT be in DCE? List them; refine rule.
- Sync provisioning still has its built-in filter (excludes
  `alternativeSecurityIds != None` and `userState = PendingAcceptance`).
  Those are appropriate; we don't override them.
