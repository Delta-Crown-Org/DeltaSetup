# 02 — Identity & Audience Targeting Model

## Principle

> **Group membership is the primary audience-targeting mechanism. Attribute
> filters are a secondary refinement, not a substitute.**

Why: SharePoint's audience-targeting machinery is fundamentally
group-aware. Web parts, pages, navigation links, and document libraries
can all be targeted "to a group" via the OOTB audience picker. We
exploit this for the entire DCE design.

## The role taxonomy

Six top-level roles. Each maps to a primary M365 group; each group is
either pre-existing in the tenant or to be created. The agent must
NOT invent new roles; if a use-case doesn't fit one of these, add an
ADR.

| Role | Description | Primary group (current name) | Source of membership |
|---|---|---|---|
| **R1 — Global Admin** | Site-collection admins; emergency access; root-cause investigators | `Tenant Global Admins` (Entra role assignment, not an M365 group) | Manual + JIT via PIM |
| **R2 — Franchisor Leadership** | HTT corp leaders who set strategy / make brand decisions for DCE | (new) `DCE-Franchisor-Leadership` | Hand-picked from HTT corp synced users (manual add) |
| **R3 — DCE Franchise Owner** | DCE-native franchise owners (5 today) | Existing: members of `Crown Connection` minus HTT corp + leadership | Currently manual; future: dynamic filter by `companyName == "Delta Crown Extensions"` |
| **R4 — DCE Manager / Lead Extensionista** | Mid-tier staff with edit rights to operational content | (future) `DCE-Managers` | Hand-curated; eventually dynamic on `jobTitle` |
| **R5 — DCE Staff (Extensionista / Concierge)** | Front-line staff; primarily content consumers | (future) `DCE-AllStaff` | Existing `DeltaCrownAllStaff` once cleaned up |
| **R6 — HTT Corporate** | All synced HTT corp users (the 52 we discovered tonight) | Existing dynamic group via cross-tenant sync | Auto: `SG-DCE-Sync-Users` rule (HTT side) → cross-tenant sync → DCE |

## Group naming convention

- **`SG-*`** — Security group (HTT side, for sync gating).
- **`DCE-*`** — DCE-side M365 groups for audience targeting.
- **`{SiteName}`** — M365 group backing a SharePoint site (e.g.
  `CrownConnection`).

Avoid:

- Hyphen-less or inconsistent casing (`dceManagers` vs `DCE-Managers`).
- Mixing semantic and technical names (no `DCE-Members-Sync-Group`).

## Where each role appears

This is the master matrix. A "✓" means the role sees content; "—"
means content is hidden via audience targeting.

| Surface / Section | R1 GA | R2 Leadership | R3 Owners | R4 Managers | R5 Staff | R6 HTT Corp |
|---|---|---|---|---|---|---|
| DCE Hub — Home: announcements | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| DCE Hub — Home: owner spotlight | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| DCE Hub — Home: KPI tiles | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| DCE Hub — Home: operations alerts | ✓ | ✓ | — | ✓ | ✓ | — |
| DCE Hub — Resources: SOP library | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| DCE Hub — Resources: brand assets | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| DCE Hub — People directory | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| DCE Hub — Admin tools (audit, reports) | ✓ | ✓ | — | — | — | — |
| Crown Connection — Home: pinned ann. | ✓ | ✓ | ✓ | — | — | ✓ |
| Crown Connection — Documents | ✓ | ✓ | ✓ | — | — | ✓ |
| Crown Connection — Ask Franchisor form | ✓ | ✓ | ✓ | — | — | — |
| Crown Connection — Owner-only library | ✓ | — | ✓ | — | — | — |
| Crown Connection — HTT collateral | ✓ | ✓ | ✓ | — | — | ✓ |

## Mechanics: how audience targeting actually works

### Mechanism 1 — Web-part-level targeting

Modern SharePoint pages allow each web part to be set "Show to specific
audiences." The picker accepts security groups, M365 groups, and Entra
ID groups. We use this for **every web part on every page**.

Configuration sketch:

```json
{
  "webpartId": "owner-spotlight",
  "audiences": ["DCE-Franchise-Owners", "DCE-Franchisor-Leadership"]
}
```

When a user with no membership in the listed groups loads the page,
the web part is server-side-hidden — they can't view-source to it.

### Mechanism 2 — Page-level targeting

Pages themselves can have an audience targeting attribute (`PromotedState`
+ "Audience"). When a user loads the parent site, only pages they're in
the audience for show up in the "Pages" list / search results.

We use this primarily for **R1 admin pages** (audit logs, permission
diagnostics) so they're invisible to everyone else.

### Mechanism 3 — Navigation targeting

Hub mega-menu links and quicklinks support audience targeting on each
node. We use this for **R4-only operational links** like "Submit a
shift swap" — invisible to owners and corp.

### Mechanism 4 — Library / list permissioning (last resort)

Permission breaks at the library or list level are the
"sledgehammer" — they hide content but **also disrupt search,
governance, and admin auditing**. We minimize this.

> **Rule:** If a library can be hidden by audience targeting, use that
> instead of breaking inheritance. Reserve permission breaks for
> genuinely confidential content (executive comp, HR investigations).

See `05-permissions-model.md` for the inheritance philosophy.

## Cross-tenant identity nuance

HTT corporate users appear in DCE with:

- `userType: Member` (not Guest — important; they're full participants).
- UPN form: `<local>_httbrands.com#EXT#@deltacrown.onmicrosoft.com`.
- `mail` attribute: the original `@httbrands.com` address.
- `companyName: "HTT Brands"` (verify after sync; some users may have
  the field unset).
- `department`: variable (`HTT Brands Corporate`, `Marketing`, `IT`,
  etc.). NOT a reliable filter on its own.

**Implication for attribute filters:** You can filter on
`endsWith(mail, "@httbrands.com")` reliably. You can NOT rely on
`companyName` or `department` until we audit completeness. If the agent
needs an attribute filter, default to `mail` suffix.

## Audience proliferation guardrails

To avoid the HTT Headquarters cluster pattern:

1. **No new M365 group without an audit entry.** Adding a group must
   come with an ADR-style entry in `decisions/` describing what
   audience it represents and why an existing group doesn't suffice.
2. **No web-part audience picker referencing a group that isn't in the
   role taxonomy.** If the picker shows `Special-Project-Q3`, that
   group needs to be promoted to an "R7" role or merged into an
   existing one.
3. **Quarterly audit.** A scheduled job (recommended monthly until we
   trust it, then quarterly) lists all groups + their audience usage.
   Orphans are flagged for archive. Owner: Tyler.

## Audience targeting examples (worked)

### Example 1: "Owner spotlight" on the Hub

- **Goal:** Highlight a different owner each month, only to
  R1/R2/R3/R4/R5/R6 (everyone with DCE context — basically everyone
  with site access).
- **Implementation:** Single web part, no targeting (default is "show
  to all"). Content authored monthly by Jenna.

### Example 2: "Operations alerts" on the Hub

- **Goal:** Show shift-related alerts only to managers and staff
  (R4, R5), not to owners (R3) or HTT corp (R6).
- **Implementation:** Web part with audience = `[DCE-Managers,
  DCE-AllStaff]`. Owners + corp see a gap in the layout (acceptable
  per design).

### Example 3: "Ask the Franchisor" form on Crown Connection

- **Goal:** Form available to owners + leadership; HTT corp can SEE
  the form exists (they may want to know what owners are asking) but
  cannot submit.
- **Implementation:** Form web part visible to R2 + R3 + R6, but the
  underlying list has Add permissions only for R2 + R3.

The implementation agent should model these three examples in the
mockup explicitly to prove the audience model works.

## Anti-patterns to avoid

1. **Targeting individual users.** Always target a group. If only one
   person should see something, create a single-person group or
   reconsider the requirement.
2. **Targeting "all members" of a group that contains everyone.** Just
   don't target — it's noise.
3. **Audience targeting + permission break on the same item.** Pick
   one. Audience targeting if it's about visibility, permission break
   if it's about confidentiality.
