# Raw findings / source excerpts

## Microsoft 365 organization theme

Source: https://learn.microsoft.com/en-us/microsoft-365/admin/setup/customize-your-organization-theme?view=o365-worldwide

- “The organization theme is what appears in the top navigation bar for people in your organization.”
- Admins can customize tabs: General, Logos, Colors.
- General: default theme applies to everyone; up to four additional group themes; group themes can be assigned to up to five Microsoft 365 Groups.
- Logos: default logo/alternate logo; logo click URL; HTTPS image URL that allows anonymous access; default uploaded logo under 10kb; SVG resized to 24px vertically; JPG/PNG/GIF scaled to 200x48 while preserving aspect ratio.
- Note: “The Microsoft 365 suite header is designed to accommodate a variety of screen sizes, window sizes, and display settings. The responsive behavior of the suite header sometimes results in the logo not showing…”
- Colors: navigation bar color, text and icon color, accent color.
- FAQ: group themes require Microsoft 365 Groups, not security/distribution groups; if user is assigned multiple group themes, default theme is shown.
- “Any theme appears in the top navigation bar for everyone in the organization as part of the Microsoft 365 suite header.”

## SPFx web parts

Source: https://learn.microsoft.com/en-us/sharepoint/dev/spfx/web-parts/overview-client-side-web-parts

- “SharePoint client-side web parts are controls that appear inside a SharePoint page and execute client-side in the browser.”
- “They're the building blocks of pages that appear on a SharePoint site.”
- Web parts can be deployed to modern pages and classic web part pages.
- Web parts can be used beyond SharePoint for SPAs and Teams tabs.

## SPFx Extensions / supported DOM boundary

Source: https://learn.microsoft.com/en-us/sharepoint/dev/spfx/extensions/overview-extensions

- SPFx Extensions “extend the SharePoint user experience within modern pages and document libraries.”
- Application Customizers: “Adds scripts to the page, and accesses well-known HTML element placeholders and extends them with custom renderings.”
- Extensions include Field Customizers, Command Sets, Form Customizers, Search Query Modifier.
- Important: “The SharePoint page HTML DOM is not an API. You should avoid taking any dependencies on the page DOM structure or CSS styles, which are subject to change and potentially break your solutions.”
- SPFx is “the only supported means to interact with the SharePoint page HTML DOM.”

## Application Customizer placeholders

Source: https://learn.microsoft.com/en-us/sharepoint/dev/spfx/extensions/get-started/using-page-placeholder-with-extensions

- Application Customizers provide access to “well-known locations on SharePoint pages” and can create “dynamic header and footer experiences.”
- Difference from old custom JavaScript: “your page elements won't change if changes are made to the HTML/DOM structure in SharePoint Online.”
- Supported scopes include Site, Web, and List; broader activation possible through tenant-wide deployment or Site UserCustomAction.
- Code example uses `PlaceholderName.Top` and `PlaceholderName.Bottom`.
- Explicit caution: “The extension should not assume that the expected placeholder is available.”

## Organization assets / Brand Center

Sources:
- https://learn.microsoft.com/en-us/sharepoint/organization-assets-library
- https://learn.microsoft.com/en-us/sharepoint/brand-center-overview

- OAL: “If your organization needs to store and manage files for all your users to use, you can specify one or more document libraries on a SharePoint site as an ‘organization assets library.’”
- Image assets appear in the modern page file picker under “Your organization.”
- Up to 30 organization asset libraries, all on same site; only libraries, not folders.
- Brand Center centralizes “colors, fonts, and images, and other assets all in one place.”
- Brand Center “currently only allows one brand center for your organization.”
- Brand Center uses Organization Asset Library in the background and requires Public CDN for setup/custom fonts.

## Modern pages / owner editing

Source: https://support.microsoft.com/en-us/office/create-and-use-modern-pages-on-a-sharepoint-site-b3d46deb-27a6-4b1e-87b8-df851e503dec

- “Using pages is a great way to share ideas using images, Excel, Word and PowerPoint documents, video, and more.”
- “When you create a page, you can add and customize web parts, and then publish your page…”
- “You as a site member with edit permissions can add pages.”
- “Web parts are the building blocks of your page.”
- Draft/publish flow: audience cannot view until published; site editors can access drafts.
- “On most modern SharePoint sites, coauthoring is enabled by default…”
- Pages are stored in the site’s Pages library.
