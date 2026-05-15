# Friday 2026-05-15 audit findings — Delta Crown SharePoint hub re-audit

**Audit date:** 2026-05-15 (Friday)
**Auditor:** Richard / `code-puppy-1bc20e`
**Tracking beads:** `DeltaSetup-2dq` (Friday hub umbrella), `DeltaSetup-9av` (_fullHTT Scot)
**Evidence root:** `.local/reports/friday-sharepoint-hub-audit/` (local-only; contains user roster data)

## Why this audit

The first Friday audit (`code-puppy-1ead81`, 2026-05-15 17:09Z) ran read-only Graph
queries that returned zero rows for the sites collection in both HTT and DCE
tenants. Root cause: the audit token lacked the `Sites.Read.All` Graph scope, not
that the sites were missing.

This follow-up (`code-puppy-1bc20e`, 2026-05-15 20:58Z) re-ran the audit with the
correct scope using a public-client device-code flow, plus an Exchange Online
probe to capture the actual state of `_fullHTT@httbrands.com` and the user
Scot Cannon.

## Method

- OAuth 2.0 device authorization flow against `login.microsoftonline.com`
- Public client: Microsoft Graph PowerShell (`14d82eec-204b-4c2f-b7e8-296a70dab67e`)
- Scopes: `Sites.Read.All`, `Group.Read.All`, `User.Read.All`, `Directory.Read.All`, `Organization.Read.All`
- Exchange Online: `Connect-ExchangeOnline -Device -DelegatedOrganization httbrands.onmicrosoft.com`
- Script: `tools/friday-re-audit.ps1`

All queries are read-only `GET` / `Get-*`. No tenant state was modified.

## Finding 1 — HTT SharePoint inventory (13 sites)

The HTT tenant's site inventory was previously empty in our docs. With the
correct scope it returns 13 sites:

| Site | URL | Notes |
|---|---|---|
| HTT Brands Directory | `https://httbrands.sharepoint.com` | Root |
| HTT Brands Homecoming 2026 | `/sites/Homecoming2026` | Event site |
| Delta Crown Operations | `/sites/msteams_7f6ca9` | **Teams-provisioned. See Finding 5.** |
| HTT Marketing | `/sites/HTTMarketing` | |
| HTT Marketing-Domain Intelligence | `/sites/HTTMarketing-DomainIntelligence` | |
| Fabric Reporting | `/sites/fabric-reporting` | |
| Product Dev Lifecycle | `/sites/ProductDevLifecycle` | |
| Microsoft Admin Center | `/sites/ms-admin-center` | |
| The HTT Hub | `/sites/TheHTTHub` | **Presumed HTT-side hub site; golden-child reference for DC hub structure.** |
| Brand Guide | `/sites/BrandGuide` | |
| UAT-UserGroups-1770682559 | `/sites/uatusergroups1770682559` | Stale UAT artifact? |
| Team Site (Content Type Hub) | `/sites/contentTypeHub` | Tenant content type hub |
| Apps | `/sites/appcatalog` | App catalog |

Evidence: `20260515T205804Z-HTT-sites-full.json`, `20260515T205804Z-HTT-sites-summary.json`.

## Finding 2 — DCE SharePoint inventory (15 sites)

Confirms the README + production-launch-readiness report inventory:

| Site | URL |
|---|---|
| Communication site (root) | `https://deltacrown.sharepoint.com` |
| DCE Document Center | `/sites/dce-docs` |
| DCE Marketing | `/sites/dce-marketing` |
| DCE Operations | `/sites/dce-operations` |
| DCE Client Services | `/sites/dce-clientservices` *(legacy)* |
| Delta Crown Extensions Hub | `/sites/dce-hub` |
| Corporate Shared Services | `/sites/corp-hub` |
| Corporate HR | `/sites/corp-hr` |
| Corporate IT | `/sites/corp-it` |
| Corporate Finance | `/sites/corp-finance` |
| Corporate Training | `/sites/corp-training` |
| All Company | `/sites/allcompany` |
| Delta Crown Extensions | `/sites/DeltaCrownExtensions` |
| Delta Crown Extensions | `/sites/DeltaCrownExtensions379` |
| Team Site (Content Type Hub) | `/sites/contentTypeHub` |

The two duplicate `DeltaCrownExtensions` group sites match the known finding in
`docs/duplicate-delta-crown-extensions-groups-review.md` and remain unresolved.

Evidence: `20260515T205835Z-DCE-sites-full.json`, `20260515T205835Z-DCE-sites-summary.json`.

## Finding 3 — `_fullHTT` group structure (definitive)

`_fullHTT@httbrands.com` is unambiguously a **static distribution list**, not a
dynamic distribution group:

```json
{
  "Name": "_FullHTT20240913183055",
  "DisplayName": "_All-Corporate Team",
  "GroupType": "Universal",
  "RecipientTypeDetails": "MailUniversalDistributionGroup",
  "MemberJoinRestriction": "Closed",
  "MemberDepartRestriction": "Closed",
  "ManagedBy": ["f3a37536-...", "a1553313-..."],
  "WhenCreated": "2024-09-13",
  "WhenChanged": "2026-05-05"
}
```

`MailUniversalDistributionGroup` = manually-managed static membership. The two
ManagedBy GUIDs are the group owners with authority to add/remove members.

Implication: the prompt §4.6 framing of "Scot Cannon drift" as a dynamic-group
attribute-sync issue is wrong. There is no recipient filter to debug; there is
no MIDL attribute to update. This is a manual-membership bookkeeping issue.

Evidence: `20260515T205855Z-HTT-fullHTT-group-detail.json`, `20260515T205855Z-HTT-fullHTT-members-detail.csv`.

## Finding 4 — Scot Cannon is not offboarded

Live state from HTT tenant (read-only):

```json
{
  "Recipient": {
    "RecipientType": "UserMailbox",
    "WhenCreated": "2024-08-15",
    "WhenChanged": "2026-04-04",
    "HiddenFromAddressListsEnabled": false
  },
  "Mailbox": {
    "WhenSoftDeleted": null,
    "ForwardingSmtpAddress": null
  },
  "User": {
    "AccountDisabled": false,
    "RemotePowerShellEnabled": true,
    "Department": "HTT Brands Corporate",
    "Title": "Vice President of Field Support"
  }
}
```

Scot's HTT account is **fully active**. He's still listed as VP of Field Support,
mailbox is live, RemotePowerShell enabled, not hidden from the GAL. There is no
offboarding state to repair — there is no offboarding that has occurred.

Implication: this is not a DeltaSetup or Cross-Tenant-Utility issue. The "Scot
Cannon `_fullHTT` drift" narrative in the Friday SharePoint hub prompt was
based on a faulty premise. Either:

1. Scot actually hasn't departed yet (premise was wrong)
2. Scot has departed and his HTT account was never offboarded (HR/IT gap)

Either way, **the DCE dynamic distribution groups are unaffected** — they are
real `DynamicDistributionGroup` objects keyed on Company/Department/Title
filters and operate independently of `_fullHTT`. Friday SharePoint hub work is
not blocked by this finding.

Evidence: `20260515T205855Z-HTT-scot-cannon-state.json`.

## Finding 5 — "Delta Crown Operations" exists in HTT tenant

`httbrands.sharepoint.com/sites/msteams_7f6ca9` is a Teams-provisioned
SharePoint site named "Delta Crown Operations" living in the HTT tenant — not
the DCE tenant. This was not previously documented in the DeltaSetup repo.

Possible explanations:
- Cross-tenant collaboration landing for HTT-side users supporting DC
- Stale artifact from before the DCE tenant existed
- Sandbox / test artifact

This needs disposition before any HTT-tenant DC hub provisioning happens (Friday
prompt §3) because we may already have what we need, or we may need to clean
this up first.

Evidence: `20260515T205804Z-HTT-sites-full.json` (search for `msteams_7f6ca9`).

## Finding 6 — Friday prompt §3 target may be miswritten

The prompt says the Friday hub goes "in the HTT tenant under the Delta Crown
brand domain path." But:

- DCE is a fully separate tenant (`ce62e17d-...`)
- `dce-hub` already exists at `https://deltacrown.sharepoint.com/sites/dce-hub`
- Full hub-and-spoke architecture (4 brand sites + 4 corp service sites) is live in DCE
- The HTT tenant's only DC-named asset is the `msteams_7f6ca9` Teams site above

Three possible reconciliations:

1. **DCE tenant is the real target.** Friday work is folder skeleton + nav on the
   existing `dce-hub` site, not new site provisioning.
2. **HTT tenant is the real target.** A new DC hub gets provisioned in HTT so HTT
   corporate users can access without cross-tenant guest. This duplicates effort.
3. **Hybrid.** DCE tenant remains primary; HTT gets a thin landing/redirect.

This is a decision for Tyler before any provisioning work starts.

## Recommended next actions

In priority order, based on this audit:

1. **Tyler decision: Friday prompt §3 target tenant.** Options 1-3 above.
2. **DeltaSetup-9av:** flip to closed-as-handed-off. Drop Scot's HTT user/mailbox
   state into the bead notes and hand off to HTT HR/IT offboarding workflow.
   Not a DeltaSetup engineering problem.
3. **DeltaSetup-gf9 owner-decision worksheet closeout** with Tyler — OD-001..006.
   OD-002 (Brand Resources vs Brand Assets) directly governs whether Friday work
   is folder structure or schema-change.
4. **Disposition `msteams_7f6ca9`** (Finding 5) before propagating any HTT-side
   DC content.
5. **DeltaSetup-2dq:** once decisions above are captured, scope the actual Phase
   5 folder-skeleton work against the right target tenant + site.

## Decisions captured in this audit (no Tyler input needed)

- `_fullHTT` is static, not dynamic. The Friday prompt §4.6 dynamic-group
  blocker narrative is invalidated. Treat as documentation issue, not
  engineering issue, going forward.
- DCE dynamic distribution groups (`allstaff@`, `managers@`, `stylists@`,
  `franchise_owners@`) are unaffected by `_fullHTT` state and remain healthy.
- The 2026-05-12 production-launch-readiness baseline is re-confirmed for
  identity, SharePoint, and Exchange.
