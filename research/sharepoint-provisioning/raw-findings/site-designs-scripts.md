# SharePoint Site Designs and Site Scripts

Source: https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-overview
JSON Schema: https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-json-schema

## Overview

Site designs and site scripts provide a declarative way to customize SharePoint sites. They are JSON-based and integrated natively into SharePoint.

## Key Concepts

### Site Script
A JSON file that describes the customizations to apply:
- Lists and libraries to create
- Columns and content types
- Navigation
- Theme/branding
- Site features to activate

### Site Design
A wrapper around one or more site scripts that:
- Can be applied to specific site templates
- Appears in site creation UI
- Can include thumbnail, description, and metadata

## Available Actions (Verbs) in Site Scripts

### Content Management
- **createSPList** - Create lists/libraries
- **addContentTypes** - Add content types to lists
- **addSPField** - Add fields to lists
- **setSiteLogo** - Set site logo
- **applyTheme** - Apply color theme
- **setRegionalSettings** - Configure regional settings
- **updateNav** - Update navigation (hub, footer, quick launch)

### Permissions
- **addPrincipalToSPGroup** - Add users/groups to SharePoint groups
- **createSPGroup** - Create SharePoint groups
- **grantWebAccess** - Grant permissions

### Hub Sites
- **joinHubSite** - Associate site with hub
- **setSiteBranding** - Configure hub branding

### Extensions
- **triggerFlow** - Trigger Power Automate flow
- **installSPFxSolution** - Install SPFx solutions

## Site Script JSON Schema Structure

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/sp/site-design-script-actions.schema.json",
  "actions": [
    {
      "verb": "createSPList",
      "listName": "Documents",
      "templateType": 101,
      "subactions": [
        {
          "verb": "addSPField",
          "fieldType": "Text",
          "displayName": "Project Name"
        }
      ]
    },
    {
      "verb": "joinHubSite",
      "hubSiteId": "00000000-0000-0000-0000-000000000000"
    }
  ]
}
```

## Site Design JSON Schema

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/sp/site-design-script-actions.schema.json",
  "siteScriptIds": ["script-id-1", "script-id-2"],
  "description": "Site design description",
  "displayName": "My Site Design",
  "previewImageUrl": "https://...",
  "thumbnailUrl": "https://...",
  "webTemplate": "64" // 64 = Team Site, 68 = Communication Site
}
```

## Web Template IDs

| Template | ID |
|----------|-----|
| Team Site | 64 |
| Communication Site | 68 |
| Group Team Site | 64 (with Group) |

## Creating Site Designs

### Using PowerShell (PnP):
```powershell
# Create site script
$script = Add-PnPSiteScript -Title "Brand Template" -Description "Template for brands" -Content $jsonContent

# Create site design
Add-PnPSiteDesign -Title "Brand Site Design" -SiteScriptIds $script.Id -WebTemplate TeamSite -Description "Deploy brand site"
```

### Using REST API:
```
POST https://tenant.sharepoint.com/_api/Microsoft.SharePoint.Utilities.WebTemplateExtensions.SiteScriptUtility.CreateSiteScript
```

## Limitations Compared to PnP Framework

| Capability | Site Scripts | PnP Framework |
|------------|--------------|---------------|
| Custom code execution | ❌ No | ✅ Yes |
| Complex provisioning logic | ❌ Limited | ✅ Full |
| Content type publishing | ✅ Yes | ✅ Yes |
| Managed metadata provisioning | ✅ Limited | ✅ Full |
| Page provisioning | ✅ Basic | ✅ Advanced |
| Custom web parts | ❌ No | ✅ Yes |
| Requires custom infrastructure | ❌ No (native) | ✅ Yes (Azure/function) |
| Developer knowledge required | Low | Medium-High |
| Non-developer friendly | ✅ Yes | ❌ No |

## When to Use Site Scripts vs PnP

### Use Site Scripts When:
- Simple site creation needs
- Standard team/communication sites
- Quick deployment required
- Non-developers need to create templates
- Native SharePoint integration needed
- No custom code required

### Use PnP Framework When:
- Complex site structures
- Custom business logic needed
- Integration with external systems
- Need full control over provisioning
- Developers available
- Advanced customization required

## Multi-Brand Deployment Strategy

### Option 1: Site Scripts per Brand
- Create separate site scripts for each brand
- Include brand-specific:
  - Color themes
  - Logos
  - Document templates
  - Navigation
  - Hub site associations

### Option 2: Parameterized Site Scripts
- Single site script with parameters
- Use Power Automate flows for customization
- Dynamic values based on brand selection

### Hub Site Association
Site scripts can automatically join sites to hub sites:
```json
{
  "verb": "joinHubSite",
  "hubSiteId": "[hub-site-id]"
}
```

## Best Practices

1. **Start Simple** - Begin with basic site scripts, add complexity as needed
2. **Test Thoroughly** - Validate JSON syntax and action availability
3. **Version Control** - Store site scripts in source control
4. **Document** - Maintain documentation of available site designs
5. **Monitor** - Track site design application success/failure
