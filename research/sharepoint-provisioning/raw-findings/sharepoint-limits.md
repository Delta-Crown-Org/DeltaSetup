# SharePoint Online Limits - Official Microsoft Documentation

Source: https://learn.microsoft.com/en-us/office365/servicedescriptions/sharepoint-online-service-description/sharepoint-online-limits
Last Updated: 11/06/2025

## Hub Site Limits

**Key Finding from Microsoft Learn Documentation:**

- **Maximum hub sites per tenant: 2,000**
  - Note: "Your organization is limited to 2,000 hub sites. You might not need a hub site for every function and it's important to do some planning before you create hubs."

- **Hub site associations**: Not explicitly limited beyond general site limits
  - Associated sites inherit hub navigation, theme, and search scope
  - Sites can be associated to only ONE hub at a time

- **Navigation items limit**: 500 child links at each level
  - Extra nodes added after the limit has been reached will receive an error
  - Applies to site, hub, global, and footer navigation types

## Managed Metadata Limits

- **Total terms**: 1 million
- **Term labels**: 2 million total (global & site-level combined)
- **Term properties**: 1 million
- **Global term sets**: 1,000
- **Global groups**: 1,000

**Recommendations:**
- Maximum 50 Terms as Default on MMD Column
- More than 50 terms may cause downstream experiences (like Search) to not work properly

## Other Relevant Limits for Multi-Brand Deployment

### Sites and Site Collections
- **Sites per organization**: 2 million
- **Storage per site (site collection)**: 25 TB
- **Total storage per organization**: 
  - Microsoft 365 Business Basic/Standard/Premium: 1 TB + 10 GB per license purchased
  - Enterprise: 1 TB + 10 GB per license purchased
  - Plus additional storage can be purchased

### Lists and Libraries
- **Lists/libraries per site collection**: 2,000 combined
- **Items per list**: 30 million
- **Files per library**: 30 million
- **Unique security scopes per list/library**: 50,000 (recommended: 5,000)

### Users and Groups
- **Users per site collection**: 2 million
- **SharePoint groups per site**: 10,000
- **Users per group**: 5,000
- **Groups a user can belong to per site**: 5,000

### Subsites
- **Subsites per site collection**: 2,000
- Microsoft recommendation: "We recommend creating sites and organizing them into hubs instead of creating subsites"
