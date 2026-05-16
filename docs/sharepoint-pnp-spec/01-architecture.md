# 01 — Architecture (hub-and-spoke topology)

## Topology overview

```
                    DCE Tenant (deltacrown.sharepoint.com)
                    ──────────────────────────────────────

                          ┌───────────────────┐
                          │   DCE Brand       │
                          │   Center          │
                          │  (asset store +   │
                          │   theme source)   │
                          └────────┬──────────┘
                                   │ theme inherit
                                   ▼
                  ┌────────────────────────────────────┐
                  │         DCE Hub                    │
                  │  /sites/dce-hub                    │
                  │  HUB site (Communication)          │
                  │  Audience: All DCE Staff           │
                  │  Purpose: Operational anchor       │
                  └────┬─────────┬─────────┬───────────┘
                       │         │         │     hub association
            associate  │         │         │  (theme + nav inherit)
                       ▼         ▼         ▼
              ┌──────────┐ ┌──────────┐ ┌──────────────┐
              │  Crown   │ │   Ops    │ │  Training    │
              │Connection│ │ Manuals  │ │  (future)    │
              │ /sites/  │ │ (future) │ │              │
              │CrownConn │ │          │ │              │
              └──────────┘ └──────────┘ └──────────────┘
              Owners +     All staff    All staff
              HTT corp     (private)    (private)
              (private)
```

## Site inventory

| Site | URL (relative) | Type | Audience | Purpose | Owner of decisions |
|---|---|---|---|---|---|
| **DCE Hub** | `/sites/dce-hub` | Communication (Hub) | All DCE staff + HTT corp viewers | Operational anchor; home; news; calendar; people | Tyler / Jamie |
| **Crown Connection** | `/sites/CrownConnection` | M365-Group team site (Hub spoke) | DCE Owners + HTT Corp + Franchisor leadership | Owner ↔ franchisor collab; peer support; resources | Kristin / Jenna |
| **DCE Brand Center** | `/sites/DCEBrandCenter` (proposed) | Communication | Asset editors (Tyler, Jenna, designers) | Logos, themes, image library, brand guidelines | Tyler / Jenna |
| **DCE Operations Manuals** | TBD | Document Center or Team | Managers + Owners | SOP storage, version-controlled | Jamie |
| **DCE Training** | TBD | Team / Learning Pathways | All staff | Learning paths, certifications, onboarding | TBD |

Three of the five exist today (Hub, Crown Connection are provisioned;
Brand Center is the next logical add). Operations and Training are
deferred until Phase-2+.

## Hub-and-spoke mechanics

### What "hub association" gives us

When a SharePoint site is **associated** to a hub:

1. **Theme inheritance.** The site picks up the hub's theme (colors +
   fonts). One theme change at the hub propagates to all spokes.
2. **Global navigation inheritance.** The hub's mega-menu appears as
   the top nav on every spoke.
3. **Hub search.** Search results aggregate across all associated
   sites by default.
4. **News aggregation.** "News from sites" web part on the hub pulls
   from all spokes.

This is exactly what we need. Crown Connection should associate to
DCE Hub immediately.

### What hub association does NOT give us

- Permission inheritance — each site retains its own permission set
  (this is good; see `05-permissions-model.md`).
- Content sharing — files in one spoke don't appear in another.
- Audience-targeting unification — each site/page targets audiences
  independently.

### Brand Center pattern

The **SharePoint Brand Center** (rolled out by Microsoft in 2024) is
the tenant-wide source of truth for fonts, logos, color themes, and
images. It's not a site association — it's a special tenant-level
service. Configuring it:

1. Provision a Brand Center site (one per tenant; Microsoft's
   recommended path).
2. Upload approved DCE logos (PNG + SVG, dark + light variants).
3. Upload Montserrat-equivalent (we use Playfair Display + Tenor Sans;
   SharePoint supports custom fonts via Brand Center as of late 2024).
4. Configure the DCE color theme (generated from
   `reference/dce-tokens.json`).
5. Set Brand Center to "Tenant Brand" so it's the default suggestion
   when new sites are provisioned.

This is the closest thing to "global design tokens" SharePoint
natively offers without SPFx. We use it for **all non-token-aware**
SharePoint surfaces (default site chrome, OneDrive, Teams) and
override with SPFx for the parts we directly control.

## Site provisioning rules

Each new site we provision must:

1. Be created from a **PnP provisioning template** (XML or JSON,
   versioned in the new `dce-sharepoint` repo).
2. Apply the DCE theme via Brand Center reference.
3. Associate to DCE Hub (unless intentionally standalone — must be
   documented in an ADR).
4. Have its M365 group ownership configured per
   `05-permissions-model.md`.
5. Inherit permissions by default; breaks must be documented.

## Topology decisions deferred to Tyler

- **Communication vs Team site for DCE Hub.** Currently provisioned as
  Communication (correct for hub). Confirm.
- **Does Crown Connection associate to DCE Hub?** Recommendation: YES,
  so it picks up the hub theme and nav. Open question: is the audience
  enough overlap that hub navigation makes sense?
- **Brand Center placement.** Proposed `/sites/DCEBrandCenter`. Could
  alternatively use `/sites/BrandCenter` or live in the root.

See `12-implementation-plan.md` for the sequence in which these are
resolved.

## Diagrams to produce

The AI building the implementation should produce, in
`reference/diagrams/`:

1. **topology.png / .svg** — the diagram at the top of this file,
   rendered properly.
2. **theme-inheritance-flow.png** — how the DCE token JSON flows from
   Style Dictionary → Brand Center → individual sites → SPFx
   components.
3. **audience-targeting-flow.png** — how a user lands on a page and
   the audience-targeted web parts render based on group membership.
4. **ci-cd-flow.png** — how a push to main reaches the live site.

These are Tier-A deliverables — a hi-fi mockup needs all four.
