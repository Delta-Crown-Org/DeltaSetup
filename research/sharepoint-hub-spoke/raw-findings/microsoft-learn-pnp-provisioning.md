# Raw Findings: Microsoft Learn - PnP Provisioning Engine

**Source**: https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/introducing-the-pnp-provisioning-engine  
**Date Extracted**: April 2025

---

## Overview

The PnP Provisioning Engine provides a code-based approach to provisioning artifacts in Microsoft 365, extending beyond what can be achieved through web browser configuration alone.

### What You Can Model
Using the PnP provisioning engine, you can model a site by configuring:
- Site columns
- Content types
- List definitions and instances
- Pages
- Much more (via web browser)

### Export Capability
When design is complete, export configurations into provisioning template formats:
- XML
- JSON
- PnP file (container format)

Apply these templates to as many target sites as needed.

---

## Extended Capabilities

### Beyond SharePoint Sites
The PnP Provisioning Engine can provision:
- Microsoft Teams teams
- Azure AD users
- Site Designs and Site Scripts
- Tenant-scoped themes
- And more

---

## Two Types of Templates

### 1. Site Templates (Provisioning Templates)
- Original template type
- Also called "Provisioning Templates"
- Focused on site-level artifacts

### 2. Tenant Templates (Extended Version)
- Introduced after Site Templates
- Distinguishes itself by provisioning artifacts BEYOND SharePoint sites
- Capabilities include:
  - Microsoft Teams teams
  - Azure AD users
  - Site Designs and Site Scripts
  - Tenant-scoped themes
  - Create 'Sequence' for site collections

### Key Difference
- Site Template = Site-level provisioning
- Tenant Template = Tenant-level provisioning (can contain Site Templates)

---

## PowerShell Cmdlet Approach

### Primary Tooling
Article focuses on **PnP PowerShell** to work with the Provisioning Engine.

### Alternative
For C# developers: See "PnP Provisioning Engine and the Core Library"

---

## Practical Application

### Example Scenario
Custom homepage created with:
- Events list with sample events
- Export site as provisioning template
- Apply to multiple target sites

### Supported Operations
1. **Export site as template**
   - PowerShell or CSOM code
   - Using OfficeDev PnP Core Library extension methods

2. **Apply provisioning template**
   - To new or existing sites
   - Reusable across environment

3. **Apply tenant template**
   - For tenant-level artifacts
   - Sequences for complex deployments

---

## Documentation Structure

Related topics covered in documentation:
- Configuring the PnP Provisioning Engine
- PnP provisioning framework
- PnP provisioning engine and the Core library
- Provisioning Tenant Templates
- Applying PnP Templates to SharePoint Sites
- PnP Open XML File format
- PnP provisioning schema
- Provisioning console application sample
- PnP remote timer job framework
- PnP CLI for Microsoft 365
- PnP PowerShell reference
- SharePoint APIs
- SharePoint schema reference
- SharePoint glossary

---

## Key Takeaways for Multi-Brand Deployment

1. **PnP Provisioning Engine supports complete brand template deployment**
   - Site structure
   - Content types
   - Lists and libraries
   - Pages and web parts

2. **Tenant Templates enable multi-artifact provisioning**
   - SharePoint sites AND Teams teams
   - Can create complete "brand workspace" templates

3. **Multiple format support**
   - XML for traditional approach
   - JSON for modern development
   - PnP files for packaging

4. **Automation-ready**
   - PowerShell for admin automation
   - CSOM for custom applications
   - Can integrate with site provisioning workflows

---

*Extracted from Microsoft Learn - Introducing the PnP provisioning engine*
*URL: https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/introducing-the-pnp-provisioning-engine*
