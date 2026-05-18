# SharePoint Online / SPFx branding limitations — Delta Crown pragmatic plan

## Executive summary

For Delta Crown, use **native SharePoint branding + owner-editable modern pages** as the default, and reserve SPFx for true interactive/custom data experiences. Do **not** plan for full SharePoint chrome control.

Recommended posture:

1. **Tenant suite branding:** set the Microsoft 365 suite/header theme only for high-level polish: logo, logo link, suite-bar background/text/accent colors. Treat it as tenant-wide Microsoft 365 chrome, not page branding.
2. **SharePoint site branding:** use SharePoint themes, Brand Center / organization asset libraries, site logos, hub navigation, modern page templates, News, Lists, Libraries, Quick Links, Hero, Highlighted Content, etc.
3. **SPFx web parts:** use only inside page canvas when native web parts cannot meet the need.
4. **SPFx Application Customizer:** optional later for a thin, supportable top/bottom banner/footer or notification strip. Avoid DOM/CSS hacks, command-bar rewrites, or attempts to replace suite chrome.
5. **Team-owned editable content:** keep content in SharePoint pages, lists, and libraries owned by DCE operations/marketing owners. Avoid hard-coding routine content in SPFx or static site assets.

## Practical implications for Delta Crown

| Area | Can control | Cannot reliably/control fully | Delta implication |
|---|---|---|---|
| Microsoft 365 tenant suite branding | Top suite/header theme logo, logo click URL, nav bar color, text/icon color, accent color, default + up to 4 group themes mapped to Microsoft 365 Groups | Full layout of suite bar, app launcher/me-control behavior, responsive hiding of logo, SharePoint command surfaces, page canvas | Worth doing for light brand polish if Global Admin is comfortable. Do not sell it as a custom intranet shell. |
| SharePoint site theme / Brand Center | Site colors, fonts (via Brand Center/custom font support), images/logos/assets through OAL, page visuals | Full Microsoft-managed shell/command bar behavior; arbitrary CSS overrides are not supportable | Good primary branding layer for DCE Hub and spokes. |
| SPFx web part | Custom interactive/content component **inside** a page section | Suite bar, global header, command bar, navigation chrome, every page automatically unless added/configured | Build only for unique business widgets; not for simple editable text/resources. |
| SPFx Application Customizer | Supported placeholders such as Top/Bottom; scripts across scoped pages; headers/footers/banners; extension surfaces | Must not depend on private SharePoint DOM/CSS; placeholders may not always exist; does not own suite bar | Optional phase-2 polish only. Keep it thin and accessible. |
| Editable owner content | Modern pages, News, Lists, Libraries, organization assets, page templates, permissions, approvals if needed | Versioned code releases for everyday updates | Put owner resources/intake links in lists/pages so team owners can edit without developers. |

## Recommendation

**Decision:** Do **not** pursue a full custom SharePoint chrome. Implement tenant suite branding + native SharePoint site/Brand Center assets. Keep SPFx App Customizer as a backlog option only for a small branded banner/footer if owners explicitly ask after seeing native SharePoint.

**Why:** Microsoft’s supported boundaries are clear: web parts are page-canvas controls; Application Customizers use well-known placeholders; the SharePoint page DOM is not an API. A full chrome replacement would be brittle, higher maintenance, and unnecessary for Delta Crown’s current owner-operated hub/spoke rollout.
