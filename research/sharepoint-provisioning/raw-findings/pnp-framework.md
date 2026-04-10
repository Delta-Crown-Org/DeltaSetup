# PnP Framework - Provisioning Documentation

Source: https://github.com/pnp/pnpframework
Documentation: https://pnp.github.io/pnpframework/

## Overview

PnP Framework is a .NET Standard 2.0 / .NET 8.0 / .NET 9.0 library targeting Microsoft 365 containing the PnP Provisioning engine and extensions.

## Current Version (April 2025)

- **Latest Release**: v1.18.0 (April 17, 2025)
- **Nightly Development**: v1.18.346-nightly
- **NuGet Package**: PnP.Framework

## Key Capabilities

### PnP Provisioning Engine
The provisioning engine allows you to:
- Create site templates (XML/JSON based)
- Apply templates to SharePoint Online sites
- Extract existing sites as templates
- Support for modern SharePoint sites (team, communication, hub)

### Comparison: PnP vs Site Scripts/Site Designs

| Feature | PnP Framework | Site Scripts/Site Designs |
|---------|---------------|---------------------------|
| **Complexity** | High - Full control | Low - Simple declarative |
| **Capabilities** | Extensive (lists, content types, pages, web parts) | Limited to supported actions |
| **Learning Curve** | Steeper - Requires .NET/CSOM knowledge | Easier - JSON based |
| **Flexibility** | Maximum - Can execute custom code | Limited to schema actions |
| **Deployment** | Requires custom application/azure function | Native - Built into SharePoint |
| **Hub Site Support** | Yes - Full provisioning | Yes - Limited actions |
| **Teams Provisioning** | Yes - via Graph API integration | No - Site scripts only |

## Template Formats

### PnP Provisioning Template (XML)
- Based on PnP Provisioning Schema
- Supports full site structure: lists, libraries, content types, fields, pages, navigation
- Can include custom actions and extensibility handlers

### JSON-based Provisioning
- Site Scripts use JSON schema
- Limited to actions defined in the schema
- Cannot execute custom code or complex logic

## Migration Status

**Important**: PnP Framework is the cross-platform successor to PnP Sites Core:
- PnP Sites Core is retired and archived
- Only actively maintaining PnP Framework
- PnP Sites Core only worked on Windows (.NET Framework dependency)
- PnP Framework works cross-platform but only supports SharePoint Online

## Future: PnP Core SDK
Microsoft is also building a new **PnP Core SDK** that:
- Targets modern .NET development
- Will work everywhere .NET will run
- Is the long-term evolution of PnP Framework
- Will enable phased transition without impacting users

## Supportability

- **Open Source**: Community provided component
- **No Microsoft SLA**: Not a Microsoft-provided component
- **No Direct Support**: From Microsoft for this open-source component
- **Community Support**: Active community providing support
- **Issues**: Report via GitHub issues list

## Requirements

### For Building/Contributing:
- Visual Studio 2022
- .NET SDK version 8.0

### For Usage:
- .NET Standard 2.0 compatible project
- Or .NET 8.0+ application
- SharePoint Online tenant

## Recommendation for Multi-Brand Deployment

**Use PnP Framework when:**
- Need complex site structures with multiple lists/libraries
- Require custom content types and managed metadata
- Need to provision hub sites with associated sites
- Require custom page layouts and web parts
- Need integration with Teams provisioning

**Use Site Scripts/Site Designs when:**
- Simple site creation needs
- Standard team site configurations
- Non-developer friendly approach required
- Quick deployment without custom code
