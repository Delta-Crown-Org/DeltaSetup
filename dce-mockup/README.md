# DCE Hub mockup

Interactive Tier-B mockup for the Delta Crown Extensions SharePoint
hub-and-spoke ecosystem. Built against the spec pack at
`../docs/sharepoint-pnp-spec/` and graded against
`../docs/sharepoint-pnp-spec/EVALUATION-RUBRIC.md` (see `RATIONALE.md`).

## What's here

```
dce-mockup/
├── README.md                  ← you are here
├── RATIONALE.md               ← rubric self-score + spec defects + reuse review
├── index.html                 ← DCE Hub home (9 sections, audience-targeted)
├── crown-connection.html      ← Crown Connection spoke (private team site)
├── admin.html                 ← R1/R2 admin page (page-level audience-gated)
├── assets/
│   ├── logo-dce-white.svg
│   ├── logo-dce-white.png
│   └── logo-dce-royal-gold.png
├── css/
│   ├── tokens.css             ← Tier-1/2/3 design tokens (no hex outside :root)
│   ├── components.css         ← .dce-* component classes (1:1 SPFx mapping)
│   └── mockup.css             ← mockup-only chrome (suite bar, role-switcher)
├── js/
│   ├── identity.js            ← 6 personas modeled, 3 surfaced in switcher
│   ├── audience-targeting.js  ← evaluates data-audience attrs against persona
│   └── mockup-controls.js     ← wires up role-switcher + identity badge
├── spfx-skeleton/             ← portability proof (TypeScript + React + Fluent v9)
│   ├── DceHubHomeWebPart.ts
│   ├── components/
│   ├── theme/
│   ├── audience/
│   └── README.md
└── ci-cd/                     ← copy into Delta-Crown-Org/dce-sharepoint
    ├── README.md
    ├── workflows/             ← GitHub Actions (PR validation, deploy-prod,
    │                            permission-audit, provision-teams)
    ├── scripts/               ← bootstrap.sh, deploy-prod.ps1, audit, teams
    └── teams/                 ← channelModerationSettings config (Graph)
```

## How to run

No build step. Open `index.html` directly in a browser, or for full
relative-path correctness:

```bash
cd dce-mockup
python3 -m http.server 8080
# then open http://localhost:8080/index.html
```

## How to use the mockup

1. Land on `index.html` — you're signed in as **Allynn Shepherd**
   (R3 DCE Franchise Owner) by default.
2. The **role-switcher** in the bottom-right lets you swap personas.
   Pick "DCE Manager" or "HTT Corporate" — the page re-renders. Web
   parts hidden from the new persona disappear; the identity badge
   and the cross-tenant context banner update.
3. Check **"Show audience tags + hidden-section placeholders"** at the
   bottom of the role-switcher. Each section's `data-audience` value
   appears next to its heading, and audience-filtered sections show a
   dashed-placeholder explaining what was hidden.
4. Navigate to `crown-connection.html` to see the **spoke page** with
   the moderated Teams channel mock, the audience-gated form, and the
   R3-only Owner library.
5. Navigate to `admin.html` to see the **R1/R2-only page** — try it
   with each persona to see page-level audience gating in action.

## Personas modeled

| Key | Role | Provisioning | In switcher? |
|---|---|---|---|
| r3-owner-allynn | DCE Franchise Owner | Native DCE | ✅ default |
| r4-manager-jamie | DCE Manager | Native DCE | ✅ |
| r6-htt-corp-kristin | HTT Corporate | Cross-tenant sync | ✅ |
| r1-ga-tyler | Global Admin | Dual-tenant | hidden |
| r2-leadership-jenna | Franchisor Leadership | Cross-tenant sync | hidden |
| r5-staff-morgan | DCE Staff | Native DCE | hidden |

Toggle the hidden three to `surfaceInSwitcher: true` in `js/identity.js`
to expose them in the dropdown.

## Quick test of the audience-targeting model

Pages have web parts targeted to specific groups. Here's what each
persona should see:

| Section | r3-owner | r4-manager | r6-htt-corp |
|---|:---:|:---:|:---:|
| Hero | ✅ | ✅ | ✅ |
| Quick links | ✅ | ✅ | ✅ |
| **KPI tiles** | ✅ | ✅ | ❌ |
| News | ✅ | ✅ | ✅ |
| Owner spotlight | ✅ | ✅ | ✅ |
| Events | ✅ | ✅ | ✅ |
| **Operations alerts** | ❌ | ✅ | ❌ |
| Brand resources | ✅ | ✅ | ✅ |

On `crown-connection.html`:

| Section | r3-owner | r4-manager | r6-htt-corp |
|---|:---:|:---:|:---:|
| Hero | ✅ | ❌ | ✅ |
| Pinned announcement | ✅ | ❌ | ✅ |
| Document hub | ✅ | ❌ | ✅ |
| **Ask the Franchisor (editable form)** | ✅ | ❌ | ❌ (read-only banner) |
| Teams embed | ✅ | ❌ | ✅ |
| HTT corp collateral | ✅ | ❌ | ✅ |
| **Owner-only library** | ✅ | ❌ | ❌ |

Manager (R4) shouldn't be on Crown Connection at all — the underlying
M365 Group doesn't include them. The page still renders (this is a
mockup, not real ACLs), but every section either hides or shows
only what's audience-permitted.

## Cross-tenant context

The mockup demonstrates the actual production cross-tenant flow:

- **HTT Brands tenant** (`0c0e35dc-188a-4eb3-b8ba-61752154b407`)
  is the home tenant of HTT corporate staff (Kristin, Jenna, Tyler).
- **DCE tenant** (`ce62e17d-2feb-4e67-a115-8ea4af68da30`)
  is the resource tenant.
- A cross-tenant sync app `HTT-to-DCE-User-Sync` runs every **40 minutes**.
  The gate is a **dynamic group** `SG-DCE-Sync-Users` on the HTT side
  with rule `user.userPrincipalName -match ".*@httbrands\.com$" and user.accountEnabled -eq true`.
- HTT users arrive in DCE as `userType=Member` (NOT Guest) with UPN
  `<local>_httbrands.com#EXT#@deltacrown.onmicrosoft.com`.

The role-switcher's "HTT Corporate" persona shows this UPN form in the
identity badge tooltip and the cross-tenant context banner at the top
of each page.

## What you'd change to deploy this for real

See `ci-cd/README.md` for the full path. Short version:

1. Stand up `Delta-Crown-Org/dce-sharepoint` from `ci-cd/`.
2. Run `ci-cd/scripts/bootstrap.sh` (one-shot, idempotent).
3. Paste the printed secrets into GitHub repo settings.
4. Open a PR to add a PnP provisioning template to `templates/hub/`.
5. Watch `pr-validation.yml` pass; merge; `deploy-prod.yml` runs.

The mockup is the **visual + audience-model target** for sprint-1.
The `spfx-skeleton/` is the **structural starting point** for the
custom web parts (deferred per ADR-005 — most v1 content uses
first-party web parts).

## Verification

```bash
# 1. Check no hex outside :root token blocks
grep -rE '#[0-9A-Fa-f]{3,8}' css/ | grep -v 'tokens.css' | grep -v '/\*'
# expected: empty output (all colors via CSS variables)

# 2. axe-core a11y check (requires npx)
npx @axe-core/cli ./index.html
npx @axe-core/cli ./crown-connection.html
npx @axe-core/cli ./admin.html

# 3. Responsive smoke
# Open in browser, resize 375 / 768 / 1440. No horizontal scroll, no overlap.
```

## Sources

All claims and patterns in the mockup are cited inline in the source
files. The full reuse review is in `RATIONALE.md` § 1.1.
