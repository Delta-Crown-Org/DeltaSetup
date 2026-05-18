# Sources and credibility

All key sources are Microsoft official documentation/support pages (Tier 1 unless noted). Accessed/researched 2026-05-18.

## Tier 1 — Microsoft official sources

1. **Customize the Microsoft 365 theme for your organization** — Microsoft Learn, last updated 2026-02-02.  
   URL: https://learn.microsoft.com/en-us/microsoft-365/admin/setup/customize-your-organization-theme?view=o365-worldwide  
   Credibility: Tier 1. Primary product/admin documentation.  
   Key facts: organization theme appears in the top navigation bar; controls include logo, logo link, navigation bar color, text/icon color, accent color; default theme + up to four group themes; group themes require Microsoft 365 Groups; logo may not show due to responsive suite header behavior.

2. **SharePoint brand center** — Microsoft Learn, last updated 2025-04-18.  
   URL: https://learn.microsoft.com/en-us/sharepoint/brand-center-overview  
   Credibility: Tier 1. Primary SharePoint product documentation.  
   Key facts: Brand Center centralizes colors, fonts, images and assets; uses Organization Asset Library; currently one Brand Center per organization; Global Admin enables it; requires Public CDN for setup/custom fonts.

3. **Create an organization assets library** — Microsoft Learn, last updated 2026-04-03.  
   URL: https://learn.microsoft.com/en-us/sharepoint/organization-assets-library  
   Credibility: Tier 1. Primary SharePoint admin documentation.  
   Key facts: OAL stores centrally managed image/logo/template assets; appears in modern page file picker under “Your organization”; up to 30 libraries, all on same site; contributors need appropriate permissions.

4. **Overview of SharePoint client-side web parts** — Microsoft Learn, last updated 2022-06-28.  
   URL: https://learn.microsoft.com/en-us/sharepoint/dev/spfx/web-parts/overview-client-side-web-parts  
   Credibility: Tier 1. Primary SPFx developer documentation; older but foundational.  
   Key facts: client-side web parts are controls that appear inside a SharePoint page and are the building blocks of pages; can also be used for SPAs and Teams tabs.

5. **Overview of SharePoint Framework Extensions** — Microsoft Learn, last updated 2026-03-11.  
   URL: https://learn.microsoft.com/en-us/sharepoint/dev/spfx/extensions/overview-extensions  
   Credibility: Tier 1. Primary SPFx developer documentation.  
   Key facts: Extensions customize facets of SharePoint UX such as notification areas, toolbars, list views, forms; Application Customizers add scripts and access well-known placeholders; “The SharePoint page HTML DOM is not an API.”

6. **Use page placeholders from Application Customizer** — Microsoft Learn, last updated 2026-01-15.  
   URL: https://learn.microsoft.com/en-us/sharepoint/dev/spfx/extensions/get-started/using-page-placeholder-with-extensions  
   Credibility: Tier 1. Primary SPFx tutorial.  
   Key facts: Application Customizers can create dynamic header/footer experiences using Top/Bottom placeholders; code should not assume expected placeholders are available; scopes can be Site, Web, and List; tenant-wide deployment is possible.

7. **SharePoint site theming** — Microsoft Learn, last updated 2026-03-20.  
   URL: https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-theming/sharepoint-site-theming-overview  
   Credibility: Tier 1. Primary SharePoint developer/admin documentation.  
   Key facts: SharePoint themes are JSON/palette-based site theming, manageable through PowerShell/CSOM/REST; useful for site-level visual identity, not arbitrary shell override.

8. **Create and use modern pages on a SharePoint site** — Microsoft Support.  
   URL: https://support.microsoft.com/en-us/office/create-and-use-modern-pages-on-a-sharepoint-site-b3d46deb-27a6-4b1e-87b8-df851e503dec  
   Credibility: Tier 1/Tier 2. Official end-user support documentation.  
   Key facts: site members with edit permissions can add pages; pages use web parts as building blocks; save draft/publish/republish flow; pages stored in Site Pages library; modern sites support coauthoring on most sites.

## Validation notes

- Microsoft 365 suite branding and SPFx boundaries are corroborated across separate Microsoft admin and SPFx developer docs.
- No third-party sources were needed because the question concerns support boundaries and current product behavior best answered by Microsoft primary docs.
- Currency is strong for most pages (2025-2026 updates). The web-part overview is older but confirmed by current Extensions docs and modern-pages support docs.
