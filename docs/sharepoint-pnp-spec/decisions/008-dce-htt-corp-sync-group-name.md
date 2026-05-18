# ADR-008 — Name the DCE-side group representing the HTT corporate synced cohort

**Status:** Accepted (2026-05-18)
**Author:** Surfaced from `dce-mockup/RATIONALE.md` § 3 during the bake-off implementation
**Supersedes:** none
**Superseded by:** none

---

## Context

`02-identity-audience.md` § "The role taxonomy" defines six roles. R6 —
HTT Corporate — is described as "Existing dynamic group via cross-tenant
sync" with membership "Auto: `SG-DCE-Sync-Users` rule (HTT side) →
cross-tenant sync → DCE."

That sentence names the **HTT-side gate group** (`SG-DCE-Sync-Users`)
but never names the **DCE-side group** that represents the corresponding
synced cohort once those users land in DCE.

This breaks group-based audience targeting. Web parts configured to
"show to HTT corp only" need a group display name to put in the
audience picker. The spec's role taxonomy table for R6 has no value in
the "Primary group (current name)" column — it just says
"Existing dynamic group via cross-tenant sync."

`02-identity-audience.md` § "Audience proliferation guardrails" requires
that any group used for audience targeting be part of the role taxonomy.
Without a name, we are forced into one of three bad options:

1. Target by attribute (e.g., `mail endsWith "@httbrands.com"`) —
   explicitly warned against in the spec.
2. Create a group on the fly per web part — proliferates groups,
   violates guardrail 1 (no new group without an ADR).
3. Skip audience targeting for HTT corp content and rely on permissions —
   forces permission breaks where audience targeting would suffice.

## Decision

Create a DCE-side dynamic group named:

```
DCE-HTT-Corporate-Sync
```

with the membership rule:

```
(user.userType -eq "Member") and (user.mail -match ".*@httbrands\.com$")
```

This group is the canonical DCE-side R6 audience for all SharePoint
audience targeting that needs to address "all HTT corp users."

Created in the DCE tenant on 2026-05-18:

| Field | Value |
|---|---|
| Group id | `ebbd0644-edd3-441f-9857-88864c24dc5f` |
| Primary SMTP | `DCEHTTCorporateSync@deltacrown.onmicrosoft.com` |
| Group types | `Unified`, `DynamicMembership` |
| Processing state | `On` |
| Resource behavior | `WelcomeEmailDisabled` |
| Initial owner | Tyler Granlund - Admin (`tyler.granlund-admin_httbrands.com#EXT#@deltacrown.onmicrosoft.com`) |

Naming rationale:

- **`DCE-`** prefix matches the DCE-side role-group naming convention
  in 02-identity-audience.md § "Group naming convention."
- **`-HTT-Corporate-`** identifies the source population unambiguously.
- **`-Sync`** suffix communicates that membership is auto-managed by
  cross-tenant sync, not hand-curated. This matters operationally: an
  admin adding a user to this group manually is a smell.

## Membership semantics

Per the GOTCHA verified by solutions-architect-e9372f (2026-05-16) and
captured in `RESEARCH-DELTAS.md` § 1.2: SharePoint audience targeting
evaluates group **membership**, not ownership. The dynamic rule above
ensures every synced HTT user becomes a member automatically. No manual
"add as member" step is required.

Tyler Granlund is the initial owner. A second DCE-side delegate should be
added after owner confirmation. Dynamic groups do not support hand-adding
static members; owner visibility for SharePoint audience-targeted content
comes from matching the dynamic rule or from separate admin/audit groups.

## Alternatives considered

### 1. Reuse `Crown Connection` as the R6 audience

Rejected. Crown Connection is a Microsoft 365 Group whose membership is
curated for the Crown Connection site specifically. It currently contains
57 members (5 DCE owners + 52 HTT corp). Using it as an audience-targeting
group would entangle two concerns: site membership and audience targeting.

### 2. Reuse the HTT-side `SG-DCE-Sync-Users` group

Rejected. The HTT-side group is the SOURCE of the sync. Its members
exist in the HTT tenant. SharePoint in the DCE tenant cannot audience-
target against an HTT-tenant group — it can only see DCE-resident
principals. The synced users have B2B Member objects in DCE; those are
what need to be group-membered locally.

### 3. Attribute-only targeting (no group)

Rejected. Spec § "Audience proliferation guardrails" warns against
attribute-only filters because they bypass the group audit mechanism.

## Consequences

**Operational:**
- Tyler creates the group in DCE (PnP or Entra portal).
- The mockup at `dce-mockup/js/identity.js` already references this
  group name (`GROUPS.HTT_CORP_VIA_SYNC = 'DCE-HTT-Corporate-Sync'`).
- The SPFx skeleton at `dce-mockup/spfx-skeleton/audience/useAudience.ts`
  resolves it via Graph `/me/transitiveMemberOf` — no code changes.

**Auditing:**
- Add to `reference/permission-breaks.csv` if any spoke ever breaks
  inheritance on the basis of this group (currently none planned).
- The weekly permission-audit workflow already covers this group
  implicitly (it audits any group used in SP role assignments).

**Risk:**
- 24-hour propagation latency for dynamic group membership (Entra default
  for large tenants). New HTT users joining can wait up to a day before
  seeing audience-targeted content. Documented in
  `RATIONALE.md` § 1.3 as a known edge case.
- Requires Entra ID P1 license for any user that becomes a member.
  Already in place per tenant license posture.

## Implementation order

1. Create the group via Microsoft Graph in the DCE tenant. ✅
2. Add the dynamic rule. ✅
3. Update 02-identity-audience.md role taxonomy table to populate the
   R6 "Primary group" column with `DCE-HTT-Corporate-Sync`. ✅
4. Wait for first sync evaluation (≤24 h). ⏳
5. Verify membership matches expected count (52 today). ⏳
6. Add a second owner/delegate after Tyler confirms the person. ⏳
