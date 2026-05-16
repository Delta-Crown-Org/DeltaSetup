# 00 — Context (non-negotiable environmental facts)

This is the "do not invent" file. Everything here is verified from a
live Microsoft Graph or SharePoint REST query during the 2026-05-15
session. If you want to disagree with anything here, you must show me
a fresher Graph query.

---

## Tenants

| Tenant | ID | Primary domain | Role |
|---|---|---|---|
| **HTT Brands** | `0c0e35dc-188a-4eb3-b8ba-61752154b407` | `httbrands.com` | Source of corporate users; runs cross-tenant sync apps for each brand. |
| **Delta Crown Extensions (DCE)** | `ce62e17d-2feb-4e67-a115-8ea4af68da30` | `deltacrown.com` | Target tenant for this work. |
| BCC (Bishops) | n/a here | `bishopsbs.com` (approx) | Other brand; out of scope until Phase 5. |
| FMNC (Frenchies) | n/a here | `ftgfrenchiesoutlook.com` (approx) | Other brand; out of scope until Phase 5. |
| TLL (Lash Lounge) | n/a here | `lashloungefranchise.com` (approx) | Other brand; out of scope until Phase 5. |

## Cross-tenant identity plumbing (HTT → DCE)

| Item | Value |
|---|---|
| Sync app (HTT) | `HTT-to-DCE-User-Sync` (appId `9c8934a1-658d-4bab-b7a1-a1a11593a203`) |
| Sync template | `Azure2Azure` (Microsoft cross-tenant sync) |
| Schedule | `PT40M` (every 40 minutes), state: Active |
| Gate group (HTT) | `SG-DCE-Sync-Users` (group id `6f5cc75e-b2ae-4ed2-992d-e56d4e3ef5f3`) |
| Gate-group type | **DYNAMIC** (as of 2026-05-15) |
| Gate-group rule | `(user.userPrincipalName -match ".*@httbrands\.com$") and (user.accountEnabled -eq true)` |
| Target object UPN format | `<local>_httbrands.com#EXT#@deltacrown.onmicrosoft.com` |
| Target object userType | `Member` (not `Guest`) |

**Net effect:** Every enabled `@httbrands.com` user becomes an HTT
corporate user in DCE within ~40 min of being enabled, with no manual
HR step required. **Audience targeting in DCE can rely on this.**

## DCE SharePoint sites (current state)

| Site | URL | State | Members | Theme |
|---|---|---|---|---|
| Root (tenant) | `https://deltacrown.sharepoint.com` | Default "Communication site"; untouched | n/a | Default (Microsoft) |
| **DCE Hub** | `https://deltacrown.sharepoint.com/sites/dce-hub` | Provisioned, EMPTY (no pages, no lists, no theme) | TBD | Default |
| **Crown Connection** | `https://deltacrown.sharepoint.com/sites/CrownConnection` | Provisioned 2026-05-15, group-backed, 1 default Documents library | 57 (5 DCE owners + 52 HTT corp) | Default |
| (planned) DCE Brand Center | TBD | Not yet provisioned | n/a | n/a |
| (planned) DCE Operations | TBD | Not yet provisioned | n/a | n/a |

**Crown Connection group details:**

- Group id: `11e4f2da-c468-4b81-9a18-46d883099a62`
- Site id: `deltacrown.sharepoint.com,9dbd3dcf-01bd-41ca-a499-a135bb0c1ab5,84d82a43-b7f7-4fc5-...`
- Primary SMTP: `CrownConnection@deltacrown.com`
- Aliases: `OwnerConnection@deltacrown.com`, `*.onmicrosoft.com` variants
- Owners (3): Tyler Granlund - Admin, Kristin Kidd, Jenna Bowden
- Visibility: Private

## Stakeholders (people who need to be considered)

### Tier 1 — Decision makers / approvers

- **Tyler Granlund** — DCE Global Admin, primary driver of this work.
  Account: `tyler.granlund@deltacrown.com` (and HTT admin form
  `tyler.granlund-admin@httbrands.com`).
- **Kristin Kidd** — HTT corporate stakeholder, requester of brand
  SharePoint patterns. Group owner for Crown Connection.
- **Jenna Bowden** — DCE marketing/comms stakeholder. Group owner for
  Crown Connection.

### Tier 2 — Active contributors

- **Jamie Baer** — Collaborator on the DCE operational hub design
  (Jamie's working session week of 5/18).
- **Karen Meek** — HTT content manager (precedent: she edits HTT
  Homecoming SharePoint content directly without IT involvement —
  we want to preserve that property for DCE).
- **Megan Myrand** — DCE-native Global Admin (used when Tyler's
  cross-tenant admin path doesn't work).

### Tier 3 — Affected audiences

- **DCE Franchise Owners** (5 currently: Allynn Shepherd, Amit Shah,
  Jay Miller, Sarah Miller, Toni Careccia).
- **DCE Future Staff** (Managers, Lead Extensionistas, Extensionistas,
  Concierges — not yet hired in volume).
- **HTT Corporate** (52 licensed users, growing).

## Existing prior art on disk

| Path | Contents | Value |
|---|---|---|
| `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/spfx/` | SPFx 1.22.2 scaffold, Fluent UI, PnP.js, Style Dictionary 5.3.3, deploy script | ★★★★★ — the starting point |
| `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/` | DCE-focused worktree with mega brief, architecture doc, all-brand logos, audit | ★★★★★ — primary reference |
| `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/logos/DeltaCrown/` | DCE primary horizontal logo (SVG + PNG, royal-gold + white) | ★★★★★ — use these |
| `/Users/tygranlund/dev/01-htt-brands/sharepointagent/` | Python SharePoint REST wrappers, audit scripts, sample page JSON | ★★★★☆ — for audits |
| `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/css/tokens.css` | THIS repo — canonical DCE design tokens, WCAG-audited | ★★★★★ — source of truth |
| `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/docs/architecture/` | The two architecture docs created tonight | ★★★★★ — read both |

## Existing tools / cmdlets that work for this environment

| Tool | Verified | Notes |
|---|---|---|
| `az account get-access-token --tenant <id>` | ✅ 2026-05-15 | Used for Graph API in both tenants. |
| `Connect-ExchangeOnline -DelegatedOrganization <tenant>.onmicrosoft.com -Device` | ✅ 2026-05-15 | Cross-tenant EXO ops. `-Organization` does NOT work for guest GAs. |
| `Microsoft.Graph` PowerShell module | not used tonight | Should work; preferred over direct curl for PnP work. |
| `PnP.PowerShell` | not used tonight | Required for site provisioning. Use latest. |
| `@pnp/sp` (JS) | not used tonight | For SPFx custom web parts. |

## Reserved / system identifiers (don't reuse)

| Name | Reason |
|---|---|
| `DeltaCrownAllStaff` | Tenant-wide group; do not delete or rename. |
| `SG-DCE-Sync-Users` (HTT side) | Cross-tenant sync gate; do not delete. |
| `Microsoft 365 Group: Crown Connection` | Just provisioned; central to owner comms. |
| `tyler.granlund@deltacrown.com` | DCE Global Admin native account. |
| `tyler.granlund-admin@httbrands.com` | HTT admin account; B2B-Guest-then-Member in DCE. |

## Decisions already made (do not re-litigate)

These are LOCKED unless you build a compelling case to change them.

1. **Crown Connection is private + group-driven.** Tyler chose this on
   2026-05-15 over "all-DCE-public." Tracked: `DeltaSetup-of8`.
2. **Audience for Crown Connection is owners + HTT corp.** Not all
   staff. Tracked: `DeltaSetup-of8` follow-on.
3. **HTT→DCE sync is now via dynamic group rule.** Tracked:
   `DeltaSetup-jch`.
4. **CI/CD ambition: Medium (PnP + GitHub Actions).** Tracked: ADR-002.
5. **DCE design tokens come from `deltacrown.com`, not invented.**
6. **No new SPFx scaffold; reuse `Convention-Page-Build/spfx/`.**

## Open decisions (need Tyler input — see `12-implementation-plan.md`)

1. DCE Hub audience scope (all-staff vs sub-segmented).
2. Hub-spoke association (does Crown Connection associate to DCE Hub?).
3. Repo placement for SP code (new repo recommended; awaiting Tyler).
4. Any HTT users to deliberately exclude from DCE.
5. AAA aspirations: which surfaces require AAA, which AA is enough.
