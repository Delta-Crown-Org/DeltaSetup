# SharePoint Taxonomy and Content Types for Multi-Brand Deployment

Sources:
- https://learn.microsoft.com/en-us/sharepoint/managed-metadata
- https://learn.microsoft.com/en-us/sharepoint/term-store-overview
- https://learn.microsoft.com/en-us/office365/servicedescriptions/sharepoint-online-service-description/sharepoint-online-limits

## Overview

Managed metadata, term stores, and content types are essential for organizing content across a multi-brand/franchise SharePoint deployment.

## Term Store Architecture Options

### Option 1: Shared Term Store with Brand-Specific Term Groups (Recommended)

**Structure:**
```
Term Store (Tenant-level)
├── Brands (Term Group)
│   ├── Brand A
│   ├── Brand B
│   └── Brand C
├── Products (Term Group)
│   └── Shared product taxonomy
├── Locations (Term Group)
│   └── Global locations
└── Departments (Term Group)
    └── Corporate departments
```

**Pros:**
- ✅ Centralized governance
- ✅ Cross-brand reporting possible
- ✅ Easier to manage
- ✅ Consistent terminology
- ✅ Single point of administration

**Cons:**
- ❌ Requires careful planning
- ❌ Term store admins can see all terms
- ❌ Permission management complexity

### Option 2: Separate Term Groups per Brand with Shared Corporate Group

**Structure:**
```
Term Store
├── Brand A (Term Group)
│   ├── Categories
│   ├── Products
│   └── Locations
├── Brand B (Term Group)
│   ├── Categories
│   ├── Products
│   └── Locations
├── Brand C (Term Group)
└── Corporate (Term Group)
    └── Shared terms
```

**Pros:**
- ✅ Clear brand separation
- ✅ Brand autonomy
- ✅ Easier to delegate administration

**Cons:**
- ❌ Duplication of common terms
- ❌ Harder to maintain consistency
- ❌ More complex reporting
- ❌ Potential term conflicts

### Option 3: Hybrid Approach (Best Practice for Franchises)

**Structure:**
```
Term Store
├── Corporate (Term Group)
│   ├── Brands (Term Set)
│   ├── Departments
│   ├── Document Types
│   └── Compliance Tags
├── Brand A (Term Group)
│   ├── Categories (unique to brand)
│   └── Products (unique to brand)
├── Brand B (Term Group)
│   ├── Categories (unique to brand)
│   └── Products (unique to brand)
└── Shared (Term Group)
    ├── Locations
    ├── Product Categories (common)
    └── Document Templates
```

## Term Store Limits

From Microsoft documentation:
- **1 million total terms**
- **2 million term labels**
- **1 million term properties**
- **1,000 global term sets**
- **1,000 global groups**

**Practical Recommendations:**
- Maximum 50 Terms as Default on MMD Column
- More than 50 terms may cause search issues
- Plan for growth within limits

## Content Type Strategy

### Approach 1: Site Content Types per Brand (Hub Site Level)

**Implementation:**
1. Create content type hub (separate site collection)
2. Publish corporate content types from hub
3. Each brand hub can:
   - Inherit corporate content types
   - Create brand-specific content types
   - Override as needed

**Pros:**
- ✅ Corporate standards maintained
- ✅ Brand flexibility preserved
- ✅ Centralized publishing

### Approach 2: Content Type Inheritance Chain

**Structure:**
```
Corporate Document (Parent)
├── Brand A Document
├── Brand B Document
└── Brand C Document

Corporate Policy (Parent)
├── Brand A Policy
├── Brand B Policy
└── Brand C Policy
```

**Pros:**
- ✅ Consistent base structure
- ✅ Brand customization possible
- ✅ Updates propagate from parent

## Recommended Multi-Brand Taxonomy Structure

### 1. Corporate Terms (Global)

**Purpose:** Shared across all brands

| Term Set | Description | Example Terms |
|----------|-------------|---------------|
| Brands | List of all brands | Brand A, Brand B, Brand C |
| Document Types | Standard document types | Policy, Procedure, Form, Report |
| Departments | Corporate departments | HR, Finance, Legal, IT |
| Compliance | Compliance categories | GDPR, SOX, PCI, HIPAA |
| Status | Document status | Draft, Published, Archived |

### 2. Shared Terms (Cross-Brand)

**Purpose:** Common across multiple brands

| Term Set | Description | Example Terms |
|----------|-------------|---------------|
| Product Categories | High-level categories | Electronics, Clothing, Food |
| Locations | Physical locations | North, South, East, West |
| Customer Types | Customer segments | Enterprise, SMB, Consumer |

### 3. Brand-Specific Terms (Per Brand)

**Purpose:** Unique to each brand

| Term Set | Description | Managed By |
|----------|-------------|------------|
| Brand A Categories | Specific to Brand A | Brand A admin |
| Brand A Products | Product line for Brand A | Brand A admin |
| Brand B Categories | Specific to Brand B | Brand B admin |
| Brand B Products | Product line for Brand B | Brand B admin |

## Content Type Recommendations

### Corporate Content Types (Published from Hub)

1. **Document**
   - Fields: Title, Document Type, Status, Brand
   - Used across all brands

2. **Policy**
   - Fields: Policy Number, Effective Date, Review Date, Brand
   - Inherits from Document

3. **Form**
   - Fields: Form ID, Category, Department, Brand
   - Inherits from Document

### Brand-Specific Content Types

Each brand can create content types that:
- Inherit from corporate types
- Add brand-specific fields
- Override default behaviors

## Implementation Best Practices

### 1. Use Managed Metadata Columns

Instead of choice columns, use managed metadata:
- Better governance
- Easier updates
- Consistent values
- Search integration

### 2. Set Up Content Type Hub

1. Create dedicated site collection as Content Type Hub
2. Publish corporate content types
3. Configure subscriber sites to receive published types

### 3. Permission Model

**Term Store Administrators:**
- Corporate IT team (full access)
- Each brand manager (access to their term groups)

**Group Managers:**
- Brand content managers
- Subject matter experts

### 4. Naming Conventions

**Term Groups:**
- Corporate
- Shared
- [Brand Name] - e.g., "Brand A", "Brand B"

**Term Sets:**
- Descriptive names
- Consistent across groups where applicable

**Terms:**
- Standardized capitalization
- No abbreviations (unless industry standard)
- Consistent pluralization

## Site-Level Configuration

### Per Brand Hub Site

**Managed Metadata Columns:**
- Brand (required, single value from Brands term set)
- Document Type (from Document Types term set)
- Category (from brand-specific Categories term set)
- Product (from brand-specific Products term set)

**Content Types:**
- Inherit Corporate Document
- Brand-specific document types
- Local overrides as needed

## Governance Considerations

### 1. Term Store Governance

**Roles:**
- **Term Store Administrator**: Corporate IT (full control)
- **Group Manager**: Brand managers (manage their groups)
- **Contributor**: Content managers (add/edit terms)

**Processes:**
- New term requests via form/workflow
- Regular review cycles
- Deprecation process for outdated terms

### 2. Content Type Governance

**Publishing:**
- Corporate types published from hub
- Brand types managed locally
- Version control for changes

**Documentation:**
- Content type catalog
- Field definitions
- Usage guidelines

## Migration and Setup

### Initial Setup Steps

1. **Plan Taxonomy**
   - Identify corporate vs. brand-specific terms
   - Design term group structure
   - Define content type hierarchy

2. **Configure Term Store**
   - Create term groups
   - Add term sets and terms
   - Set up permissions

3. **Set Up Content Type Hub**
   - Create hub site collection
   - Define corporate content types
   - Configure publishing

4. **Configure Brand Sites**
   - Subscribe to published content types
   - Create brand-specific types
   - Configure managed metadata columns

5. **Deploy to Hub Sites**
   - Apply content types to document libraries
   - Configure default values
   - Set up views and filters

## Summary Recommendations

| Aspect | Recommendation |
|--------|------------------|
| **Term Store Structure** | Hybrid: Corporate + Shared + Brand-specific groups |
| **Content Types** | Corporate hub with brand inheritance |
| **Governance** | Centralized with delegated brand management |
| **Permissions** | Term store admins + group managers per brand |
| **Columns** | Managed metadata for taxonomy, choice for simple values |
