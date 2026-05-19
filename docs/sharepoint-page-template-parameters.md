# SharePoint page template parameters

**Status:** Draft — design/spec only  
**Tracking bead:** `DeltaSetup-9bo`  
**Source references:** `dce-mockup/index.html`, `dce-mockup/crown-connection.html`, `dce-mockup/css/tokens.css`, `docs/naming-conventions/owners-connect-cross-brand.md`

## Purpose

Define reusable parameters so DCE SharePoint patterns can become future TLL/BCC/Frenchies/Bishops spoke templates without copy-paste drift.

Copy-paste is not a deployment strategy. It is entropy with a clipboard.

## Brand-level parameters

| Parameter | DCE value | Notes |
|---|---|---|
| `brand.displayName` | Delta Crown Extensions | Human-facing brand name |
| `brand.shortName` | DCE | Short label |
| `brand.ownerConnectionName` | Crown Connection | Owner/community site name |
| `brand.primaryDomain` | deltacrown.com | Keep concrete value private in automation if needed |
| `brand.sharePointHost` | deltacrown.sharepoint.com | Environment-specific |
| `brand.primaryHubPath` | /sites/dce-hub | DCE primary hub |
| `brand.ownerSitePath` | /sites/CrownConnection | Owner/community site |
| `brand.logoLight` | dce logo light/white | Asset parameter |
| `brand.logoDefault` | dce logo color | Asset parameter |

## Design token parameters

DCE token source: `dce-mockup/css/tokens.css`

| Token | DCE value/use | Template use |
|---|---|---|
| `color.brand.primary` | emerald/teal | Primary buttons, headings, accents |
| `color.brand.secondary` | royal gold | Accent, focus, hero eyebrow |
| `color.surface.hero` | deep emerald | Hero background |
| `font.heading` | Playfair Display | Heading style |
| `font.body` | Tenor Sans / system fallback | Body style |
| `logo.hero` | white DCE logo | Hero logo |

Future brands should supply equivalent tokens rather than hardcoding colors inside page sections.

## Page template: Brand Hub Home

| Parameter | Description | Required? |
|---|---|---:|
| `hub.hero.eyebrow` | Brand/context eyebrow | Yes |
| `hub.hero.title` | Main headline | Yes |
| `hub.hero.subtitle` | Short explanation | Yes |
| `hub.hero.primaryCtaLabel` | Primary action label | Yes |
| `hub.hero.primaryCtaUrl` | Primary action URL | Yes |
| `hub.hero.secondaryCtaLabel` | Secondary action label | No |
| `hub.hero.secondaryCtaUrl` | Secondary action URL | No |
| `hub.quickLinks[]` | Labels/destinations/audiences | Yes |
| `hub.resourceCards[]` | Card title/description/link/audience | Yes |
| `hub.newsSource` | News/list/page source | No |
| `hub.eventsSource` | Calendar/events source | No |
| `hub.supportRoute` | Help/intake destination | Yes |

## Page template: Owner Connection Home

| Parameter | Description | Required? |
|---|---|---:|
| `ownerSite.displayName` | Human-facing owner site name | Yes |
| `ownerSite.mailAlias` | OwnerConnection alias or brand-specific alias | Yes |
| `ownerSite.visibility` | Private/Public | Yes |
| `ownerSite.hero.title` | Owner-facing headline | Yes |
| `ownerSite.hero.subtitle` | Owner-facing subtitle | Yes |
| `ownerSite.quickActions[]` | Owner actions | Yes |
| `ownerSite.resourceCards[]` | Owner resource cards | Yes |
| `ownerSite.intakeRoute` | Ask/request path | No |
| `ownerSite.teamsLink` | Teams channel link, if approved | No |
| `ownerSite.audienceGroups[]` | Owners/franchisor/support groups | Yes |

## Audience parameters

Do not bake group names into page content. Use logical audiences:

| Logical audience | DCE mapping | Future brand mapping |
|---|---|---|
| `audience.staff` | DCE staff/all users TBD | TBD |
| `audience.owners` | DCE franchise owners | TBD |
| `audience.franchisorLeadership` | DCE/HTT leadership | TBD |
| `audience.managers` | DCE managers | TBD |
| `audience.supportUsers` | approved corporate support users | TBD |
| `audience.admins` | tenant/site admins | TBD |

## Owner-connect naming parameters

From `docs/naming-conventions/owners-connect-cross-brand.md`:

| Parameter | Standard |
|---|---|
| Display name | `<Brand Word> Connection` |
| mailNickname | `<BrandWord>Connection` |
| Primary SMTP | `<BrandWord>Connection@<brand-domain>` |
| Required alias | `OwnerConnection@<brand-domain>` |
| Site URL | `/sites/<BrandWord>Connection` |
| Visibility | Private |
| Membership launch scope | Franchise owners only |
| Owners | Brand IT admin + operations leader |

## Minimum page object shape

```json
{
  "brand": {
    "displayName": "Delta Crown Extensions",
    "shortName": "DCE"
  },
  "hub": {
    "title": "Your home base for Delta Crown resources.",
    "quickLinks": [],
    "resourceCards": []
  },
  "ownerSite": {
    "displayName": "Crown Connection",
    "quickActions": [],
    "resourceCards": []
  },
  "audiences": {
    "staff": [],
    "owners": [],
    "supportUsers": []
  }
}
```

## Build rules

- Keep page templates data-driven.
- Keep brand values in parameters/tokens.
- Keep audience mappings out of copy where possible.
- Do not reuse DCE-specific URLs in future brand templates.
- Do not assume every brand has the same owner-connect maturity.
- Do not parameterize prematurely into a giant abstraction beast. Start with fields proven by DCE/Crown Connection.

## Open questions

1. Should future brand templates include Viva dashboard cards, or should Viva remain a separate layer?
2. Should owner-connect templates always start private and non-Team-enabled?
3. Should manager-specific pages/sites become a first-class template?
4. Which brand should be the second pilot after DCE?
