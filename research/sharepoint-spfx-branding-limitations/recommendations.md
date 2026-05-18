# Project-specific recommendations

## Recommended Delta Crown plan

### 1. Adopt light Microsoft 365 suite branding

Configure the default Microsoft 365 organization theme:
- Delta Crown logo / compact logo suitable for responsive suite header.
- Logo click URL to DCE Hub or a corporate landing page.
- Suite/header background and text/icon color with 4.5:1 contrast target.
- Accent color if it harmonizes with DCE gold/black branding.

Do not create multiple group themes unless there is a clear audience need. Microsoft supports default + four group themes, but conflicting membership falls back to default and only Microsoft 365 Groups are supported.

### 2. Use SharePoint site-level branding as the primary intranet brand layer

For DCE Hub and spokes:
- Apply site themes for DCE black/gold palette.
- Use SharePoint Brand Center / organization assets for shared logos, approved hero images, icons, templates, and eventually fonts if desired.
- Use hub navigation and site navigation instead of custom nav code.
- Use page templates to standardize repeated owner pages.

### 3. Keep SPFx web parts selective

Use SPFx web parts only when native SharePoint web parts cannot solve a business need. Examples that might justify SPFx:
- A live operational dashboard combining multiple lists/APIs.
- A specialized intake/status component with custom business logic.
- A Teams/Viva-compatible widget that reuses SharePoint data.

Avoid SPFx for:
- Owner resources links.
- Static copy blocks.
- PDF/process links.
- Contact cards and basic “where do I go” content.
- Anything a trained site owner should be able to update.

### 4. Defer Application Customizer unless native pages feel insufficient

If owners still want extra polish after native launch, consider a thin Application Customizer with:
- Optional Top banner for DCE launch/state notices.
- Optional Bottom footer for cross-site resources/legal/support links.
- No dependency on private DOM structure.
- Graceful no-op if placeholders are unavailable.
- Accessibility review and performance budget.

Do not use Application Customizer to:
- Replace the Microsoft 365 suite header.
- Rewrite command bars/navigation.
- Hide or monkey-patch SharePoint controls.
- Inject global CSS targeting Microsoft internal class names.

### 5. Treat team-owned content as content, not software

Use native editable storage:
- **Modern pages / News:** announcements, process guides, onboarding, owner resources.
- **SharePoint Lists:** intake links, FAQs, resource directory, owner/action register, operational status tables.
- **Document Libraries:** SOPs, PDFs, templates, brand assets.
- **Organization Assets / Brand Center:** approved reusable images/logos/fonts/templates.

Governance minimum:
- Assign at least two site/page owners.
- Use simple naming conventions and page templates.
- Review quarterly.
- Use page approval only where risk justifies it; avoid approval overengineering for routine owner pages.

## Prioritized action items

1. **Decision:** Close the “full chrome” question as “no full custom chrome; native + light suite branding.”
2. **Admin task:** Configure default tenant suite theme if owner approves colors/logo.
3. **SharePoint task:** Confirm DCE Hub/spoke themes and logos; create page templates for owner resource pages.
4. **Content task:** Store Crown Connection / owner resources / intake links in SharePoint pages or a simple list, not SPFx.
5. **Backlog only:** File optional future SPFx Application Customizer task for banner/footer if needed after launch.
