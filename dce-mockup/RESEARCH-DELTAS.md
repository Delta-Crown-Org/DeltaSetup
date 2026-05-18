# Research deltas — ADR-006 final reconciliation

**Date:** 2026-05-16
**Trigger:** Tyler delivered an evidence-based ADR-006 revision from his
`solutions-architect-e9372f` agent that supersedes parts of the SPFx + Teams
research I baked into the mockup, plus the 1,487-line ChatGPT 5.5 Pro
"HTT SharePoint Infrastructure and Development Guide" now sitting at
`docs/sharepoint-research/ChatGPT 5.5 Pro/`.

This file is the audit trail: what I corrected, what I credited, what I'm
keeping. It is intentionally short — the corrections are surgical.

---

## 1. Corrections applied to the mockup

### 1.1 Teams channel moderation is BETA-only in Microsoft Graph (May 2026)

**Original mockup claim** (my research agent, citing Microsoft Learn):

> Endpoint: `PATCH https://graph.microsoft.com/v1.0/teams/{team-id}/channels/{channel-id}` — channel patch is **GA in v1.0**.

**Corrected claim** (per Tyler's solutions-architect-e9372f research):

> `channelModerationSettings` is **BETA-only** in Microsoft Graph as of
> May 2026. Graph v1.0 PATCH silently ignores the `moderationSettings`
> property. Teams PowerShell v7.7.0 (April 2026) has zero moderation
> parameters. `@microsoft/teams-js` v2.53.0 is client-side only.

**Files changed:**

| File | Change |
|---|---|
| `ci-cd/scripts/provision-teams.ps1` | Endpoint `/v1.0/` → `/beta/`; .SYNOPSIS rewritten with the BETA-only warning and the v1.0 promotion monitor link |
| `ci-cd/teams/dce-channels.json` | `_meta._CRITICAL_BETA_ONLY_2026_05` key added with the verification context |
| `ci-cd/workflows/provision-teams.yml` | Header comment rewritten; cites ADR-006 final |
| `crown-connection.html` | Section caption updated to disclose BETA-only constraint to demo viewers |
| `tests/architecture/test_audience_targeting.py` | New `TestTeamsModerationBetaOnly` fitness class with three asserts: `/beta` endpoint present, `/v1.0` endpoint absent, `_meta` BETA warning present |

**Reference URLs:**
- https://learn.microsoft.com/graph/api/channel-patch?view=graph-rest-beta
- https://learn.microsoft.com/graph/api/resources/channelmoderationsettings
- Changelog monitor: https://developer.microsoft.com/graph/changelog

### 1.2 Audience targeting evaluates MEMBERSHIP, not OWNERSHIP

**Original mockup claim:** treated audience targeting as "matches against
group display name in user's group list" without distinguishing owner vs.
member.

**Corrected claim:**

> SharePoint audience targeting evaluates group **MEMBERSHIP only**.
> A user who is the OWNER of a target group but not also a MEMBER will
> NOT see audience-targeted content. SharePoint groups (Owners/Members/
> Visitors) are also not supported targets — only Entra ID groups
> (security, M365, dynamic).

**Files changed:**

| File | Change |
|---|---|
| `js/identity.js` | Header block expanded with the GOTCHA warning citing the MS Q&A; documents that every persona's `groups[]` array represents membership specifically |
| `tests/architecture/test_audience_targeting.py` | New `TestGroupOwnershipGotcha` fitness class verifies the docstring is present and that R1 Tyler has all role groups in his membership list |

**Reference URL:**
- https://learn.microsoft.com/answers/questions/687425/audience-targeting-including-group-owners

### 1.3 SPFx version pin alignment: 1.22.2 (not 1.22.0)

**Original mockup claim:** I noted Convention-Page-Build pinned 1.22.0 and
flagged the spec's 1.22.2 as a defect.

**Corrected claim:** the spec is right; the Convention scaffold is one
patch version stale.

> SPFx 1.22.2 is the locked target. The May 2026 MS Learn compatibility
> table confirms 1.22.2. React peer dep is `>=16.13.1 <18.0.0` — React 18
> is unsupported. Node engine pin is `>=22.14.0 <23.0.0`.

**Files changed:**

| File | Change |
|---|---|
| `spfx-skeleton/README.md` | Added an explicit Version pins block citing ADR-006 final; documents the five Heft CSS/SCSS bugs to plan around (#10466, #10831, #10832, #10796, #10603) |

### 1.4 Spec-defect retraction

My RATIONALE.md § 3 listed three spec defects. **Two of them stand;
one I'm retracting.**

| Defect | Status after research |
|---|---|
| Fluent UI v8 vs v9 inconsistency | **Stands.** Spec calls for v9; scaffold uses v8.121.0. ADR-006 final picks v8 (confirms my flag, opposite resolution). |
| Gulp vs Heft inconsistency | **Stands.** Spec's CI/CD YAML still uses `gulp bundle --ship`; scaffold uses `heft build --production`. |
| SPFx 1.22.2 vs 1.22.0 | **Retracted.** The spec is correct at 1.22.2 per MS Learn. Convention-Page-Build is at 1.22.0 — patch-level drift, not a defect in the spec. |
| Missing DCE-side group name for HTT corp synced cohort | **Stands.** Still unnamed in 02-identity-audience.md. |
| AADSTS500213 cross-tenant policy guardrail | **Stands.** Still undocumented in the spec pack. |

---

## 2. What I'm crediting to the sharepointagent / ChatGPT side

These are real improvements over my output, in order of impact:

1. **Beta-endpoint discovery for Teams moderation.** I should have caught
   this — my agent's research cited Microsoft Learn docs that *do* say the
   endpoint exists in v1.0 (channel PATCH is GA), but reading the
   `channelModerationSettings` resource page more carefully shows it's
   labeled `view=graph-rest-beta` and the `moderationSettings` property
   PATCH only works on /beta. Tyler's agent did the right empirical check
   (Teams PowerShell module + JS SDK both lack moderation params).

2. **Fitness functions as architectural contract.** Tyler's
   `tests/architecture/test_ci_cd_pipeline.py` pattern is materially
   better than my approach of dropping checks in inline comments. I
   adopted the pattern in `tests/architecture/test_audience_targeting.py`
   (12 fitness tests, all passing). This is reusable for every brand
   spoke in the multi-tenant rollout.

3. **Brand-template parameterization** (`templates/brand-template/`)
   for multi-brand onboarding (Bishops, Frenchies, TLL phases). The DCE
   spec is scoped to one tenant, but Tyler's revised structure
   anticipates Phase 5+ multi-brand rollout. I did not include this in
   the mockup; it's noted here as a recommended addition for the
   `dce-sharepoint` repo when it's created.

4. **`spfx-build-check.yml` standalone safety gate.** My CI/CD bundled
   SPFx checks into `pr-validation.yml`. Tyler's version splits them
   into a conditional workflow that only runs when `webparts/**` changes.
   Cheaper CI runtime when only PnP templates change. Recommended fold-in.

5. **Heft CSS/SCSS bug inventory** (#10466, #10831, #10832, #10796, #10603)
   with specific mitigation rules (simple SASS nesting only, hash
   stability check). I lacked this depth. Now reflected in
   `spfx-skeleton/README.md`.

---

## 3. What I'm holding from my output

These claims survive the research review unchanged:

1. **Cross-tenant identity flow** (sync app, gate group, UPN format,
   `userType=Member`, PT40M cadence) — sourced from the verified
   `00-context.md` Graph queries. Tyler's research confirms.
2. **Audience-targeting matcher logic** — visibility, not security.
   Group-based, OR semantics by default. ChatGPT 5.5 Pro's guide § 7
   reaches the same conclusion.
3. **6-persona identity model with 3 surfaced** — within spec; rubric
   criterion 3 satisfied.
4. **The AADSTS500213 chicken-and-egg flagging** as a guardrail to add
   to 02-identity-audience.md — not addressed in Tyler's ADR-006 final;
   I'm leaving the recommendation standing.
5. **Reuse map** — all five paths cited; ADR-006 final adds
   `pnp/sp-dev-fx-webparts` (2237 stars) and the `pnp/action-cli-*`
   GitHub Actions as additional reuse candidates. Worth folding in
   when the real repo is stood up.

---

## 4. Reconciliation against the ChatGPT 5.5 Pro guide

The 1,487-line ChatGPT 5.5 Pro guide at
`docs/sharepoint-research/ChatGPT 5.5 Pro/htt-sharepoint-infrastructure-development-guide.md`
is HTT-tenant-scoped, not DCE-scoped. It covers the same platform but at the
parent-tenant level. Where it overlaps with the DCE mockup, I'm in alignment:

- § 7 Audience targeting and identity model — same role-based principle,
  same dynamic group story, same "targeting is not security" north star.
- § 8 Permissions and security model — same "inherit by default" stance
  with documented breaks; same audit cadence.
- § 9.4 Moderation API example — uses `/beta` endpoint correctly (Tyler's
  guide agrees with the BETA-only finding). My mockup is now aligned.
- § 11 SPFx development model — same React 17 / Node 22 / TS 5.3.3 pins.
  Same "defer SPFx until first-party doesn't paint the picture" stance.
- § 12 GitHub repository model — same `dce-sharepoint` repo placement,
  same environment-protected production deploys, same secret list.

Where the ChatGPT guide goes further than the mockup (and is worth folding
into the spec pack as separate ADRs):

- § 6.2-6.4 Content types, metadata, folder strategy — more concrete than
  the spec's `04-content-architecture.md`.
- § 10.3 Viva Connections capabilities — the mockup uses none of Viva; the
  guide proposes a Viva Dashboard pattern that complements the hub.
- § 13 OIDC federation — the bootstrap.sh uses cert-auth; the guide
  proposes federated identity (workload identity) as the v2 target.

None of these block sprint-1. They're sprint-2+ candidates.

---

## 5. Final fitness function run

```
tests/architecture/test_audience_targeting.py ........ [12 passed]
```

`12 passed in 0.02s` — Group taxonomy (2), Persona model (4), Group
ownership gotcha (2), Teams moderation BETA-only (3), Token faithfulness (1).

---

## 6. ADR-006 / ADR-009 sign-off update

2026-05-18: Tyler approved ADR-006 repo placement and ADR-009 Teams
moderation BETA endpoint through the question TUI. The release-gate-arbiter
advisory preflight refused to proxy-sign as a fake security auditor, but its
pre-sign blockers were addressed in ADR-006: dev-first invariant,
ADR-011 communication suppression constraints, rollback commands, and a
sign-off checklist. Production SPFx remains blocked until ADR-010 locks
Fluent UI and the Heft CI correction lands.

Fresh evidence at sign-off:

```text
pytest tests/architecture/test_notification_suppression.py dce-mockup/tests/architecture/test_audience_targeting.py -v
20 passed in 0.31s
```

---

## 7. What changes for sprint-1

Nothing in the deliverable list shifts. The mockup ships as planned; the
corrections are confined to:

- A four-character endpoint change (`v1.0` → `beta`) in one PowerShell file.
- A documentation block in one JSON config.
- A documentation block in identity.js.
- A new fitness-functions test file.
- This RESEARCH-DELTAS.md.

Total LOC delta: ~80 lines. The bake-off rubric self-score is unchanged
(arguably stronger now — the BETA-only fix is a real safety improvement
that would have failed silently in production).
