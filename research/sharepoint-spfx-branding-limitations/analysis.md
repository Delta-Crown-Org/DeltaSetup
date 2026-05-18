# Multi-dimensional analysis

## Security

- Tenant suite branding requires Global Admin to configure and group themes must map to Microsoft 365 Groups. Use least privilege: Global Admin only for setup/approval, not routine content changes.
- SPFx packages run client-side in users' browsers. Avoid broad tenant-wide deployment unless the customizer is simple, reviewed, and hosted from approved Microsoft 365 CDN/app catalog patterns.
- Do not inject arbitrary CSS/JS against private SharePoint DOM. Microsoft explicitly states the SharePoint page HTML DOM is not an API and DOM/CSS dependencies can break.
- Owner-editable content should live in SharePoint pages/lists/libraries with existing permissions, version history, and optional approvals—not in code.

## Cost

- Native suite branding, site themes, modern pages, Lists, Libraries, News, and OAL are included platform capabilities.
- SPFx adds developer/build/release maintenance cost, app catalog governance, QA across browsers/mobile/Viva/Teams contexts, and future break/fix risk.
- Brand Center may require enabling Public CDN and has operational setup overhead, but is still lower cost than custom SPFx for normal brand assets.

## Implementation complexity

Low complexity:
- Configure Microsoft 365 tenant theme.
- Apply SharePoint hub/site themes and logos.
- Create organization asset library / Brand Center if assets need centralized picker access.
- Use page templates, web parts, lists, and library views.

Medium complexity:
- SPFx web part for a specific interactive widget.

Higher complexity/risk:
- SPFx Application Customizer tenant-wide banner/footer.
- Any attempt to restyle/replace SharePoint chrome or command bar.

## Stability / maintainability

- Native modern pages and web parts are Microsoft-supported and remain editable by site owners.
- SPFx is supported, but only inside its supported APIs/surfaces. DOM/CSS hacks are brittle.
- Application Customizer placeholders are supported but not guaranteed present in every context, so code must fail gracefully.
- Routine content in code creates a developer bottleneck and launch friction.

## Optimization / performance

- OAL/Brand Center/CDN can optimize reuse of common images/assets.
- SPFx should be kept minimal to avoid adding page weight to every modern page.
- Tenant-wide Application Customizer performance impact is multiplied across pages; defer until value is proven.

## Compatibility

- Suite theme affects Microsoft 365 suite header/top navigation experience broadly.
- SharePoint themes/Brand Center affect SharePoint and, for fonts, Viva Connections contexts per Microsoft docs.
- SPFx web parts can render in SharePoint pages and can also be used in Teams tabs, but that should not be interpreted as global shell control.

## Maintenance

- Native owner content: maintained by DCE team owners with permissions and governance.
- Brand assets: maintained by designated brand managers/site owners.
- SPFx: maintained by developers with dependency upgrades, app catalog deployment, accessibility testing, and regression checks.

## Bottom line

For the Delta Crown rollout, native SharePoint + tenant suite branding is the right pragmatic boundary. SPFx should be a selective enhancement path, not the foundation for basic branding or editable owner content.
