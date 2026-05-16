# HTT → DCE Cross-Tenant User Provisioning — Deep Dive

**Status:** Investigation complete (2026-05-15). Recommendations pending Tyler / leadership decision.
**Author:** Tyler Granlund / code-puppy-1bc20e
**Tracking bd:** `DeltaSetup-jch`

---

## 1. Why this exists

While launching Crown Connection (DeltaSetup-of8) we discovered that 7 of the 52 currently-licensed `@httbrands.com` users weren't visible in the Delta Crown Extensions (DCE) directory. We initially suspected cross-tenant sync lag. Investigation showed the real story is more nuanced — and once you know the plumbing, the fix is straightforward.

This document is the source of truth on how HTT users come to exist in DCE so future tasks don't have to rediscover it.

## 2. Architecture summary (the actual plumbing)

```
HTT tenant (httbrands.com)
└── Security group: SG-DCE-Sync-Users        ← Membership = sync inclusion
    └── (currently STATIC, 248 members)
        │
        │   Microsoft Entra Cross-Tenant
        │   Synchronization (Azure2Azure template)
        │   App: HTT-to-DCE-User-Sync
        │   Schedule: every 40 minutes
        │   appRoleAssignmentRequired: true
        │       ↓
DCE tenant (deltacrown.com)
└── Provisioned as userType: Member
    └── UPN form: <local>_httbrands.com#EXT#@deltacrown.onmicrosoft.com
```

### Key facts

| Property | Value |
|---|---|
| Sync app (HTT side) | `HTT-to-DCE-User-Sync` (appId `9c8934a1-658d-4bab-b7a1-a1a11593a203`, SP id `1f074621-8bcd-4d9e-b27e-4470afeedba1`) |
| Sync template | `Azure2Azure` (Microsoft official cross-tenant sync) |
| Sync job id | `Azure2Azure.0c0e35dc188a4eb3b8ba61752154b407.9c8934a1-658d-4bab-b7a1-a1a11593a203` |
| Schedule | `PT40M` (every 40 minutes), state `Active` |
| Last steady state | 2026-05-15T23:54:02Z |
| Gate mechanism | `appRoleAssignmentRequired: true` on the sync SP |
| Assigned principal | `SG-DCE-Sync-Users` (group id `6f5cc75e-b2ae-4ed2-992d-e56d4e3ef5f3`, security-enabled, mail-disabled, STATIC) |
| Members in `SG-DCE-Sync-Users` | 248 |
| Users provisioned to DCE via sync | 78 (some 248 members are disabled / excluded by `alternativeSecurityIds`/`userState` schema filter) |
| MTO relationship | None — `isInMultiTenantOrganization: false` on both sides. HTT does have an MTO with Bishops (`b5380912-...`), but not with DCE. |

### Schema filter (built-in)

The sync's user-object mapping has no attribute filter (no department / jobTitle clauses). It does have a built-in input filter:

- `alternativeSecurityIds EQUALS None` — exclude external/B2B users (only sync HTT-native accounts)
- `userState NOT EQUALS PendingAcceptance` — skip users still in invite-pending state

That's it. Everything else is gated by group assignment.

### Parallel sync apps for other brands

HTT has equivalent sync apps for several brands:

| Sync app | Purpose |
|---|---|
| `HTT-to-DCE-User-Sync` | HTT → DCE (this doc) |
| `Sync to FMNC` | HTT → Frenchies Modern Nail Care |
| `Sync to TLL` | HTT → The Lash Lounge |
| `MTO_Sync_b5380912-...` | HTT ↔ Bishops (Multi-Tenant Org) |
| `app-convention-provisioning` | Tenant/event-scoped — unrelated |

Each brand has its own per-tenant security group acting as the gate; the same pattern applies.

## 3. Why the 7 launch-night users weren't synced

| User | In `SG-DCE-Sync-Users`? | Likely cause |
|---|---|---|
| Lindsey Anarumo | NO | Created 2026-04-14, not added to sync group |
| Kennedy Dickie | NO | Created 2026-03-25, not added to sync group |
| Jamie Baer | NO | Created 2026-03-10, not added to sync group |
| Yara Gonzalez Ramirez | NO | Old account (2024-08); somehow missed in the original 2026-03-04 group seeding |
| MaryJo Ramsbacher | NO | Created 2026-02-18, not added to sync group |
| Tracey Tomlinson | NO | Created 2026-03-16, not added to sync group |
| Jill Holderfield | **YES** | In group but did NOT sync — anomaly; possibly transient provisioning error |

Six of seven simply weren't added to the gate group during HR onboarding. Jill is the genuine anomaly that warrants checking provisioning logs.

For Crown Connection launch we sidestepped this by directly inviting them via Graph `/invitations` and flipping to `userType: Member`. Those manually-created records exist in DCE but are NOT under sync management (the sync uses a different correlation key and won't take them over).

## 4. Operational recommendations

In order of strategic value, lowest-effort first:

### 4.1 Make `SG-DCE-Sync-Users` a DYNAMIC group (RECOMMENDED)

Replace the static membership with a dynamic membership rule like:

```
(user.userPrincipalName -match ".*@httbrands\.com$") -and
(user.accountEnabled -eq true)
```

Or, more conservative (only licensed users):

```
(user.userPrincipalName -match ".*@httbrands\.com$") -and
(user.accountEnabled -eq true) -and
(user.assignedPlans -any (p:p.servicePlanId -ne null))
```

**Pros:**
- Zero ongoing maintenance — new HTT hires auto-flow within 40 minutes.
- Removes the "did HR remember to add this person?" failure mode that bit us tonight.
- Consistent and audit-friendly.

**Cons:**
- Requires Entra ID P1 license in HTT (almost certainly already in place — DCE has them, HTT presumably too).
- Loses the ability to *exclude* specific users from sync (we'd need to add explicit exception logic if any user should be HTT-only).

**Decision needed:** Does HTT have any users that are deliberately NOT supposed to sync to DCE? If yes, we either keep the static model or build in an exception attribute.

### 4.2 Backfill the 6 missing users into `SG-DCE-Sync-Users`

For each of:

- Lindsey Anarumo, Kennedy Dickie, Jamie Baer, Yara Gonzalez Ramirez, MaryJo Ramsbacher, Tracey Tomlinson

Add them to `SG-DCE-Sync-Users` so they come under sync management going forward. Note: they already exist in DCE as manually-invited Members — the sync may or may not adopt those records. Either way, they get reconciled.

**Caveat:** if 4.1 (dynamic group) is adopted, this is unnecessary — they'll auto-flow.

### 4.3 Investigate Jill Holderfield's anomaly

She's in `SG-DCE-Sync-Users` (so she should sync) but doesn't appear in DCE. Check provisioning logs:

```
Entra admin center > Identity > Monitoring > Audit logs (or Provisioning)
Filter: ServicePrincipal = HTT-to-DCE-User-Sync, Status = Failure or Skipped
Search by sourceId = jill.holderfield@httbrands.com
```

Most likely cause: she's missing some required attribute the sync uses for correlation (e.g., `mail` blank, or `proxyAddresses` empty). Could also be a one-time provisioning failure that hasn't retried.

### 4.4 Document the new-hire process

Regardless of 4.1 vs 4.2, write down:

> When a new HTT corporate user is provisioned in the HTT tenant:
> 1. Assign them an M365 license.
> 2. Set `companyName` and `department` attributes (if applicable).
> 3. Add them to `SG-DCE-Sync-Users` for HTT→DCE cross-tenant sync.
>    *(Skipped if SG-DCE-Sync-Users is dynamic per recommendation 4.1.)*
> 4. Add them to the equivalent FMNC, TLL, etc. sync groups if they need access to those brands.
> 5. Within 40 minutes they'll appear in the target tenant directories.
> 6. They'll be picked up automatically by any dynamic / group-membership-driven access on the target side. For Crown Connection specifically, re-run `tools/expand-crown-connection-htt-corp.py` after the sync cycle.

This should live wherever HR / IT onboarding runbooks already live (or at least in this repo under `docs/onboarding/`).

### 4.5 Consider Multi-Tenant Organization (MTO) for full federation (LONG-TERM)

HTT already has an MTO with Bishops. The same construct could be extended to DCE (and FMNC, TLL). MTO gives:

- Mutual user discovery (HTT users see DCE users in search and vice versa)
- Easier Teams shared channels across tenants
- Single sign-on continuity across tenants
- One-time setup instead of per-user/group provisioning

**Pros:** the cleanest long-term posture if the brands operate increasingly together.
**Cons:** more setup, more governance overhead, requires alignment on a multi-tenant policy.
**Recommendation:** out of scope tonight; revisit in 2-3 months once the immediate franchise growth posture is clearer.

## 5. Decision matrix

| Option | Effort | Maintenance | Risk | Cost |
|---|---|---|---|---|
| Status quo (manual add to `SG-DCE-Sync-Users`) | Zero up-front | Recurring per-hire | High — drift is what bit us tonight | $0 |
| **4.1 Dynamic group** | ~15 min config | Zero | Low — only if intentional exclusions exist | $0 (needs P1 already in place) |
| 4.2 One-off backfill 6 users | ~5 min | None | None | $0 |
| 4.5 MTO with DCE | Multi-week project | Low | Medium (governance/auth ripple effects) | $0 directly |

## 6. Recommended path

1. **Tonight (no action required):** Crown Connection is fully populated — Tyler's team can launch. The 7 stragglers are in via manual invite.
2. **This week:** Implement 4.1 (dynamic `SG-DCE-Sync-Users`) + 4.4 (document). This is the right structural fix and is low-risk.
3. **As discovered:** 4.3 (Jill anomaly) — diagnose when convenient.
4. **Q3-ish:** Evaluate 4.5 (MTO) once the cross-brand SharePoint cleanup decision lands.

## 7. Evidence

Live state snapshots from 2026-05-15:

- `/tmp/sync-jobs.json` — synchronization job state
- `/tmp/sync-schema-full.json` — sync rules + input filter
- `/tmp/app-assignments.json` — app role assignments on the sync SP
- `/tmp/sg-members.json` — current `SG-DCE-Sync-Users` membership

(Live `/tmp/` not committed; reproducible from the curl invocations in this document or via `tools/audit-htt-dce-sync.sh` if/when that's written.)

## 8. Related work

- `DeltaSetup-of8` — Crown Connection launch (closed); root context for this investigation.
- `DeltaSetup-cwn` — 7-user backfill (closed); resolved by manual B2B invites.
- `DeltaSetup-jch` — this work item; tracks adoption of 4.1+4.4 (and optionally 4.3, 4.5).
- `tools/invite-htt-users-to-dce.py` — manual fallback for emergency invites.
- `tools/expand-crown-connection-htt-corp.py` — Crown Connection membership reconciliation (run after sync cycle).
- `tools/connect-exo-cross-tenant.md` — separately discovered tonight: how to do Exchange Online ops across tenants as a guest GA.
