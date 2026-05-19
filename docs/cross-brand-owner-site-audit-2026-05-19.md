# Cross-brand owner-site audit — draft matrix

**Status:** Draft — read-only evidence matrix, not cleanup approval  
**Tracking bead:** `DeltaSetup-rod`  
**Scope:** DCE + known HTT evidence now; TLL/Frenchies/Bishops require tenant/auth verification for full audit

## Purpose

Compare owner/community SharePoint surfaces across brands so future cleanup and template productization are evidence-led instead of “vibes with admin rights.”

## Known owner/community patterns

| Brand | Surface | Known site/group | Current known state | Open question |
|---|---|---|---|---|
| DCE | Crown Connection | `/sites/CrownConnection` | Private owner/franchisor surface launched as DCE pattern | Promote dev content only after approval |
| HTT | Delta Crown Operations | `/sites/msteams_7f6ca9` | Teams-provisioned SharePoint site in HTT tenant | Active collaboration site, stale artifact, or landing candidate? |
| Frenchies | Studio Connection | `/sites/StudioConnection` | Existing owner/community surface per naming convention doc | Owner-only or broader studio/franchisee scope? |
| Bishops | Connect | `/sites/ConnectNow` | Existing owner/community surface; public visibility noted in naming doc | Should it become private or remain broad/social? |
| TLL | TLL Owners Group | `/sites/TLLOwnersGroup` | Existing owner-only surface per naming doc | Rename/add alias or leave legacy naming? |

## DCE — Crown Connection

Known facts:

- Intended owner/franchisor collaboration surface.
- Private owner-facing model.
- Naming aligns with the proposed `<Brand Word> Connection` convention.
- Promotion from dev/editable content remains approval-gated.

Current recommendation:

- Treat as the DCE owner-connect pattern.
- Do not promote live content until owner approval and Class 3 bridge alerting are live.
- Do not use live site as sandbox.

## HTT — Delta Crown Operations

Known facts from Friday audit:

- HTT tenant has a Teams-provisioned SharePoint site named `Delta Crown Operations`.
- Path: `/sites/msteams_7f6ca9`.
- Purpose is not yet confirmed from repo evidence.

Current recommendation:

- Do not create a duplicate HTT-side DCE hub until this site is understood.
- Leave untouched until Teams inventory or owner confirmation identifies purpose.
- If needed, use as thin HTT landing/collaboration surface rather than duplicating DCE Hub.

## Frenchies — Studio Connection

Known facts from naming convention doc:

- Display: Studio Connection.
- Mail nickname historically differs from display/primary naming pattern.
- Private visibility noted.
- Membership appears broader than strict owners-only in historic summary.

Current recommendation placeholder:

- Verify current state with tenant/auth before cleanup.
- Decide whether Frenchies is a deliberate naming exception or should align to `OwnerConnection@` alias pattern.
- Do not rename without owner/comms approval because bookmarks and user recognition may depend on existing name.

## Bishops — Connect

Known facts from naming convention doc:

- Display: Connect.
- Site path noted as `/sites/ConnectNow`.
- Public visibility noted as legacy outlier.

Current recommendation placeholder:

- Verify current visibility and membership.
- Review whether public visibility is intentional.
- Consider alias alignment before site URL rename; URL rename is high-friction and bookmark-breaking.

## TLL — TLL Owners Group

Known facts from naming convention doc:

- Owner-only surface.
- Private team/site pattern.
- Naming differs from `<Brand Word> Connection` convention but is recognizable.

Current recommendation placeholder:

- Verify current site, membership, and Teams status.
- Add `OwnerConnection@` alias if cross-brand routing/template parity is desired.
- Avoid cosmetic rename unless leadership wants visible naming parity.

## Evidence needed for full audit

For each brand:

- site URL;
- group ID/display/mail/visibility;
- owners;
- members count and membership scope;
- Team-enabled state;
- libraries and major page structure;
- permission inheritance breaks;
- external sharing posture;
- recent activity metrics if available;
- known business owner;
- cleanup recommendation.

## Cleanup action rules

No cleanup is approved by this draft.

Before cleanup:

- read-only audit evidence captured;
- owner/business approval captured;
- rollback/redirect plan documented;
- communications plan approved if names/URLs change;
- production impact reviewed.

## Recommendation summary

| Brand | Near-term recommendation |
|---|---|
| DCE | Continue DCE/Crown readiness; no live promotion yet |
| HTT | Confirm purpose of Delta Crown Operations before new HTT hub work |
| Frenchies | Verify current state; decide spec exception vs alias cleanup |
| Bishops | Verify public/private intent before changes |
| TLL | Verify current state; consider alias-only parity |

## Open questions

1. Does leadership want retroactive naming parity, or only forward-looking standardization?
2. Should `OwnerConnection@<brand-domain>` be mandatory across all brand tenants?
3. Are managers included in owner-connect surfaces, or do they need their own manager-connect pattern?
4. Which brand should be audited next once auth is available?
