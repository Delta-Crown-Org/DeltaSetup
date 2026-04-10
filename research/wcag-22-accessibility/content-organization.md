# Content Organization Patterns for Franchise Portals

## Overview

This document provides content architecture patterns for organizing operational and training resources in franchise portals, specifically designed for Microsoft 365 SharePoint/Teams environments with multi-tenant considerations.

---

## Information Architecture Strategy

### Flat Architecture Principle

Modern SharePoint recommends **flat architecture** over hierarchical site collections.

**Traditional (Deprecated)**:
```
Franchise Portal
├── Operations
│   ├── Procedures
│   ├── Guidelines
│   └── Training
│       ├── New Hire
│       └── Annual
└── Marketing
    ├── Brand Assets
    └── Campaigns
```

**Modern (Recommended)**:
```
Hub: DCE Operations Hub
├── Site: Operations Procedures (standalone)
├── Site: Training Center (standalone)
├── Site: Marketing Resources (standalone)
└── Site: Franchise Support (standalone)
```

### Hub Site Strategy for Franchise Organizations

```
DCE Home Site (Home Site)
├── Hub: Operations Hub
│   ├── Site: Standard Operating Procedures
│   ├── Site: Safety & Compliance
│   ├── Site: Quality Standards
│   └── Site: Equipment Maintenance
│
├── Hub: Training Hub
│   ├── Site: Onboarding Program
│   ├── Site: Product Training
│   ├── Site: Service Training
│   └── Site: Leadership Development
│
├── Hub: Franchise Management Hub
│   ├── Site: Franchisee Resources
│   ├── Site: Territory Management
│   ├── Site: Performance Dashboards
│   └── Site: Support Center
│
└── Hub: Corporate Hub
    ├── Site: HR & Benefits
    ├── Site: IT Support
    └── Site: Communications
```

---

## Taxonomy Design

### Core Taxonomy Structure

#### Hierarchical Taxonomy

**1. Content Type (Required)**
```
Content Type
├── Document
│   ├── Policy
│   ├── Procedure
│   ├── Form
│   └── Guideline
├── Training
│   ├── Video
│   ├── Course
│   ├── Certification
│   └── Assessment
├── Communication
│   ├── News
│   ├── Announcement
│   └── Update
└── Reference
    ├── FAQ
    ├── Knowledge Base
    └── Resource
```

**2. Department/Function**
```
Department
├── Operations
├── Training
├── Marketing
├── Finance
├── HR
├── IT
├── Legal
└── Compliance
```

**3. Franchise Level**
```
Franchise Level
├── Corporate
├── Regional
├── Area
├── Multi-Unit
└── Single-Unit
```

**4. Audience (Required)**
```
Audience
├── Role
│   ├── Franchisee
│   ├── Operations Manager
│   ├── Trainer
│   ├── Staff
│   └── Corporate
├── Experience
│   ├── New Hire
│   ├── Experienced
│   └── Leadership
└── Access Level
    ├── All Franchises
    ├── Regional Group
    └── Specific Franchise
```

### Metadata Schema

#### Global Metadata (All Content)

| Column | Type | Required | Values |
|--------|------|----------|--------|
| Content Type | Choice | Yes | See Content Type taxonomy |
| Department | Choice | Yes | See Department taxonomy |
| Language | Choice | Yes | en, es, fr, etc. |
| Publish Date | Date | Yes | Auto-filled |
| Expiration Date | Date | No | Manual |
| Status | Choice | Yes | Draft, Review, Published, Archived |
| Content Owner | Person | Yes | Lookup |
| Approved By | Person | No | Lookup |
| Target Audience | Multi-choice | Yes | See Audience taxonomy |

#### Document-Specific Metadata

| Column | Type | Required | Purpose |
|--------|------|----------|---------|
| Document Type | Choice | Yes | Policy, Procedure, Form, Guideline |
| Document Number | Text | Yes | Unique identifier (e.g., OPS-001) |
| Version | Text | Yes | Major.minor (e.g., 2.3) |
| Review Cycle | Choice | Yes | Annual, Bi-annual, Quarterly, As-needed |
| Compliance Level | Choice | Yes | Critical, Required, Recommended, Optional |
| Franchise Level | Choice | Yes | Corporate, Regional, Area, Multi-Unit, Single-Unit |
| Regional Tags | Multi-choice | No | North, South, East, West, etc. |
| Related Documents | Lookup | No | Link related docs |

#### Training Content Metadata

| Column | Type | Required | Purpose |
|--------|------|----------|---------|
| Training Type | Choice | Yes | Orientation, Skill, Certification, Compliance |
| Duration | Number | Yes | Minutes |
| Difficulty | Choice | Yes | Beginner, Intermediate, Advanced |
| Prerequisites | Multi-lookup | No | Required prior training |
| Certification | Yes/No | Yes | Leads to certification? |
| Certification Valid | Number | No | Days valid (0 = never expires) |
| Delivery Method | Multi-choice | Yes | Video, Document, In-person, Virtual |
| Equipment Required | Multi-choice | No | Software, Hardware, etc. |

### Managed Metadata Term Sets

```powershell
# SharePoint PnP PowerShell: Create Term Sets
# This will be configured in the DCE tenant

# Term Set: Content Classification
$termSet = @{
    "ContentClassification" = @{
        "Public" = @{
            "Marketing Materials"
            "Press Releases"
            "General Information"
        }
        "Internal" = @{
            "Operations"
            "Training"
            "HR"
        }
        "Confidential" = @{
            "Financial Data"
            "Franchisee Information"
            "Strategic Plans"
        }
        "Restricted" = @{
            "Legal Documents"
            "Compliance Records"
            "Security Information"
        }
    }
}

# Term Set: Training Categories
$trainingTerms = @{
    "TrainingCategories" = @{
        "Onboarding" = @{
            "New Franchisee"
            "New Manager"
            "New Staff"
        }
        "Operations" = @{
            "Customer Service"
            "Safety"
            "Quality"
            "Equipment"
        }
        "Compliance" = @{
            "Food Safety"
            "Health & Safety"
            "Legal Requirements"
        }
        "Leadership" = @{
            "Management Skills"
            "Business Planning"
            "Team Development"
        }
    }
}
```

---

## Document Library Architecture

### Library Design Patterns

#### Pattern 1: Function-Based Libraries

```
Operations Site
├── Libraries
│   ├── Policies (Content type: Policy)
│   ├── Procedures (Content type: Procedure)
│   ├── Forms (Content type: Form)
│   └── Reference (Content type: Guideline, FAQ)
```

**Best For**: Smaller organizations, clear functional separation

#### Pattern 2: Content Type Libraries

```
Operations Site
├── Libraries
│   ├── Documents (All types, filtered views)
│   │   ├── View: Policies
│   │   ├── View: Procedures
│   │   └── View: Forms
│   └── Archive (All expired/deprecated content)
```

**Best For**: Consistent metadata, simplified management

#### Pattern 3: Lifecycle-Based Libraries

```
Training Site
├── Libraries
│   ├── Drafts (In development)
│   ├── Published (Live content)
│   ├── Review Queue (Pending review)
│   └── Archive (Expired content)
```

**Best For**: Approval workflows, content lifecycle management

#### Pattern 4: Audience-Based Libraries

```
Training Site
├── Libraries
│   ├── Corporate Only (Restricted access)
│   ├── Franchisee Resources (All franchisees)
│   ├── Regional Content (Scoped by region)
│   └── Public (No authentication)
```

**Best For**: Complex permission requirements

### Recommended: Hybrid Pattern for DCE

```
Hub: Training Hub
├── Site: Training Center
│   ├── Document Libraries
│   │   ├── 📚 Course Materials
│   │   │   ├── Metadata: Course, Module, Format
│   │   │   └── Views: By Course, By Format, By Difficulty
│   │   ├── 📝 Assessment Templates
│   │   │   ├── Metadata: Course, Assessment Type
│   │   │   └── Views: By Course, By Type
│   │   ├── 📹 Training Videos
│   │   │   ├── Metadata: Duration, Course, Format
│   │   │   └── Views: By Duration, By Course
│   │   └── 📋 Training Records
│   │       ├── Metadata: Employee, Course, Completion Date
│   │       └── Views: By Employee, By Course, Due Soon
│   │
│   └── Lists
│       ├── 📅 Training Schedule
│       ├── ✅ Certification Tracking
│       └── 📊 Compliance Dashboard
```

---

## Content Hierarchy for Training Resources

### Training Content Structure

```
Training Program
├── Program: Franchise Operations Certification
│   ├── Phase 1: Foundation
│   │   ├── Module: Welcome to DCE
│   │   │   ├── Lesson: Company History
│   │   │   ├── Lesson: Mission & Values
│   │   │   └── Assessment: Culture Check
│   │   │
│   │   ├── Module: Safety Fundamentals
│   │   │   ├── Lesson: Safety Overview
│   │   │   ├── Lesson: Emergency Procedures
│   │   │   ├── Lesson: Equipment Safety
│   │   │   └── Assessment: Safety Certification
│   │   │
│   │   └── Phase Assessment: Foundation Mastery
│   │
│   ├── Phase 2: Operations
│   │   ├── Module: Daily Operations
│   │   ├── Module: Customer Experience
│   │   ├── Module: Quality Standards
│   │   └── Phase Assessment: Operations Mastery
│   │
│   ├── Phase 3: Management
│   │   ├── Module: Team Leadership
│   │   ├── Module: Business Metrics
│   │   ├── Module: Compliance
│   │   └── Phase Assessment: Management Mastery
│   │
│   └── Final Certification
│       ├── Comprehensive Assessment
│       ├── Practical Evaluation
│       └── Certificate Generation
```

### Content Types Definition

#### Training Module Content Type

```json
{
  "ContentType": {
    "Name": "Training Module",
    "Description": "A standalone training unit",
    "Columns": [
      {
        "Name": "ModuleTitle",
        "Type": "Text",
        "Required": true
      },
      {
        "Name": "ModuleNumber",
        "Type": "Text",
        "Required": true,
        "Validation": "Pattern: MOD-###"
      },
      {
        "Name": "LearningObjectives",
        "Type": "Note",
        "Required": true,
        "Multi": true
      },
      {
        "Name": "EstimatedDuration",
        "Type": "Number",
        "Required": true,
        "Suffix": "minutes"
      },
      {
        "Name": "Prerequisites",
        "Type": "Lookup",
        "List": "Training Modules",
        "Multi": true
      },
      {
        "Name": "Competencies",
        "Type": "ManagedMetadata",
        "TermSet": "Competencies"
      },
      {
        "Name": "DeliveryFormat",
        "Type": "Choice",
        "Choices": [
          "Self-paced Online",
          "Instructor-led Virtual",
          "Instructor-led In-person",
          "Blended"
        ]
      },
      {
        "Name": "AssessmentRequired",
        "Type": "Boolean",
        "Default": true
      }
    ]
  }
}
```

#### Course Content Type

```json
{
  "ContentType": {
    "Name": "Training Course",
    "Description": "A complete training course comprising modules",
    "Columns": [
      {
        "Name": "CourseTitle",
        "Type": "Text",
        "Required": true
      },
      {
        "Name": "CourseCode",
        "Type": "Text",
        "Required": true,
        "Validation": "Pattern: CRS-YYYY-###"
      },
      {
        "Name": "CourseDescription",
        "Type": "Note",
        "Required": true,
        "RichText": true
      },
      {
        "Name": "TotalDuration",
        "Type": "Number",
        "Calculated": "Sum of module durations"
      },
      {
        "Name": "CertificationTrack",
        "Type": "Choice",
        "Choices": [
          "Franchise Operations",
          "Manager Development",
          "Specialized Skills",
          "Compliance"
        ]
      },
      {
        "Name": "CourseModules",
        "Type": "Lookup",
        "List": "Training Modules",
        "Multi": true,
        "Ordered": true
      }
    ]
  }
}
```

---

## Tagging and Search Strategy

### Search Schema Configuration

#### Managed Properties

```powershell
# SharePoint Search Configuration
# Configure crawled properties and managed properties

$managedProperties = @(
    @{
        Name = "TrainingAudience"
        Type = "Text"
        MultiValued = $true
        Queryable = $true
        Retrievable = $true
        Refinable = $true
        Sortable = $false
    },
    @{
        Name = "TrainingDifficulty"
        Type = "Text"
        MultiValued = $false
        Queryable = $true
        Retrievable = $true
        Refinable = $true
        Sortable = $true
    },
    @{
        Name = "ContentOwnerDepartment"
        Type = "Text"
        MultiValued = $false
        Queryable = $true
        Retrievable = $true
        Refinable = $true
        Sortable = $true
    },
    @{
        Name = "DocumentComplianceLevel"
        Type = "Text"
        MultiValued = $false
        Queryable = $true
        Retrievable = $true
        Refinable = $true
        Sortable = $true
    },
    @{
        Name = "ReviewDueDate"
        Type = "DateTime"
        MultiValued = $false
        Queryable = $true
        Retrievable = $true
        Refinable = $false
        Sortable = $true
    }
)
```

### Search Verticals

```json
{
  "SearchConfiguration": {
    "Verticals": [
      {
        "Name": "All",
        "Default": true,
        "Query": "*"
      },
      {
        "Name": "Training",
        "Query": "ContentType:Training OR Path:/sites/training",
        "Icon": "Education"
      },
      {
        "Name": "Policies",
        "Query": "ContentType:Policy",
        "Icon": "Documentation"
      },
      {
        "Name": "Procedures",
        "Query": "ContentType:Procedure",
        "Icon": "TextDocument"
      },
      {
        "Name": "Forms",
        "Query": "ContentType:Form",
        "Icon": "Page"
      },
      {
        "Name": "My Documents",
        "Query": "Author:{User.Name}",
        "Icon": "Contact"
      }
    ]
  }
}
```

### Search Filters (Refiners)

```json
{
  "SearchFilters": {
    "Layout": "Vertical",
    "Refiners": [
      {
        "Property": "RefinableString00",
        "DisplayName": "Content Type",
        "Type": "Multi-select"
      },
      {
        "Property": "RefinableString01",
        "DisplayName": "Department",
        "Type": "Multi-select"
      },
      {
        "Property": "RefinableString02",
        "DisplayName": "Training Difficulty",
        "Type": "Single-select"
      },
      {
        "Property": "RefinableDate00",
        "DisplayName": "Last Modified",
        "Type": "Date range"
      },
      {
        "Property": "RefinableString03",
        "DisplayName": "Compliance Level",
        "Type": "Multi-select"
      },
      {
        "Property": "RefinableString04",
        "DisplayName": "Language",
        "Type": "Multi-select"
      }
    ]
  }
}
```

---

## Navigation Structure

### Global Navigation

```
DCE Home Site
├── Global Navigation (App Bar)
│   ├── 🏠 Home
│   ├── 📋 Operations
│   │   ├── Policies & Procedures
│   │   ├── Safety & Compliance
│   │   └── Quality Standards
│   ├── 🎓 Training
│   │   ├── My Training
│   │   ├── Course Catalog
│   │   ├── Certifications
│   │   └── Training Schedule
│   ├── 🏪 Franchise Support
│   │   ├── Resources
│   │   ├── Performance
│   │   └── Support Center
│   ├── 📊 Reports
│   │   ├── My Reports
│   │   └── Analytics
│   └── ❓ Help
│       ├── Knowledge Base
│       ├── Contact Support
│       └── FAQs
```

### Hub Navigation

```
Operations Hub
├── Hub Navigation
│   ├── 📋 Standard Operating Procedures
│   ├── 🛡️ Safety & Compliance
│   ├── ✓ Quality Standards
│   ├── 🔧 Equipment Maintenance
│   └── 📊 Operations Reports
│
└── Associated Sites
    ├── Site: DCE West Region
    ├── Site: DCE East Region
    └── Site: DCE Central Region
```

### Local Site Navigation

```
Training Center Site
├── Site Navigation (Quick Launch)
│   ├── 📚 Course Materials
│   │   ├── By Category
│   │   ├── By Difficulty
│   │   └── Recently Added
│   ├── 📝 Assessments
│   │   ├── My Assessments
│   │   ├── Assessment Schedule
│   │   └── Past Assessments
│   ├── ✅ Certifications
│   │   ├── My Certifications
│   │   ├── Certification Tracks
│   │   └── Renewal Status
│   ├── 📅 Schedule
│   │   ├── Upcoming Training
│   │   ├── My Schedule
│   │   └── Request Training
│   └── 📊 Reports
│       ├── Completion Rates
│       ├── Compliance Status
│       └── Individual Progress
```

---

## Content Lifecycle Management

### Content States

```
Content State Workflow
├── Draft
│   ├── Visible to: Content owner, Reviewers
│   ├── Actions: Edit, Submit for Review
│   └── Exit: Submit for Review
│
├── Review
│   ├── Visible to: Reviewers, Approvers
│   ├── Actions: Approve, Reject, Request Changes
│   ├── Notifications: Reviewer assigned
│   └── Exit: Approved → Publish, Rejected → Draft
│
├── Published
│   ├── Visible to: Target audience
│   ├── Actions: Edit (creates new draft), Unpublish, Archive
│   ├── Notifications: Published announcement
│   └── Exit: Unpublish → Draft, Archive → Archived
│
└── Archived
    ├── Visible to: Admins, Archive viewers
    ├── Actions: Restore, Delete
    └── Exit: Restore → Draft
```

### Review Cycle Configuration

```json
{
  "ReviewCycles": {
    "Annual": {
      "Frequency": "12 months",
      "Notification": "30 days before due",
      "Escalation": "15 days before due",
      "Approvers": ["Content Owner", "Department Manager", "Compliance"],
      "Examples": ["Policies", "Critical Procedures"]
    },
    "BiAnnual": {
      "Frequency": "6 months",
      "Notification": "14 days before due",
      "Escalation": "7 days before due",
      "Approvers": ["Content Owner", "Department Manager"],
      "Examples": ["Standard Procedures", "Training Materials"]
    },
    "Quarterly": {
      "Frequency": "3 months",
      "Notification": "7 days before due",
      "Escalation": "3 days before due",
      "Approvers": ["Content Owner"],
      "Examples": ["Forms", "Quick Reference Guides"]
    },
    "AsNeeded": {
      "Frequency": "Ad-hoc",
      "Trigger": "Change in process, regulation, or business need",
      "Approvers": ["Content Owner"],
      "Examples": ["FAQ", "Reference Materials"]
    }
  }
}
```

---

## URL Structure

### SharePoint URL Design

```
Pattern: https://deltacrown.sharepoint.com/sites/{site-type}-{identifier}

Examples:
├── Hub Sites
│   ├── /sites/hub-operations
│   ├── /sites/hub-training
│   └── /sites/hub-franchise
│
├── Team Sites
│   ├── /sites/ops-safety (Operations - Safety)
│   ├── /sites/train-onboarding (Training - Onboarding)
│   └── /sites/frc-west (Franchise - West Region)
│
├── Communication Sites
│   ├── /sites/comms-home (Home Site)
│   ├── /sites/comms-news (News)
│   └── /sites/comms-executive (Executive)
│
└── Document URLs (Friendly)
    ├── /sites/hub-training/course-materials
    ├── /sites/hub-operations/policies
    └── /sites/hub-franchise/resources
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

- [ ] Define core taxonomy (Content Type, Department, Audience)
- [ ] Create managed metadata term sets
- [ ] Design hub site architecture
- [ ] Configure content types
- [ ] Set up document libraries with metadata

### Phase 2: Content Migration (Weeks 5-8)

- [ ] Migrate existing content with metadata tagging
- [ ] Configure search schema
- [ ] Set up search verticals and refiners
- [ ] Create navigation structure
- [ ] Configure permissions

### Phase 3: Governance (Weeks 9-12)

- [ ] Implement content lifecycle workflows
- [ ] Configure review cycles
- [ ] Set up content owner assignments
- [ ] Create compliance reporting
- [ ] Train content owners

### Phase 4: Optimization (Ongoing)

- [ ] Analyze search queries
- [ ] Refine taxonomy based on usage
- [ ] Optimize navigation based on analytics
- [ ] Expand metadata based on needs
- [ ] Continuous improvement

---

## Success Metrics

### KPIs for Content Organization

| Metric | Target | Measurement |
|--------|--------|-------------|
| Search Success Rate | >70% | Users find content in first 3 results |
| Content Discovery Time | <2 minutes | Average time to find specific content |
| Metadata Completeness | >95% | Percentage of items with required metadata |
| Content Freshness | >90% | Percentage reviewed within cycle |
| User Satisfaction | >4.0/5.0 | Survey rating for content findability |
| Broken Links | <1% | Percentage of broken internal links |

---

## Source References

- Microsoft: Information Architecture for Modern SharePoint
- Microsoft: SharePoint Taxonomy Planning
- Microsoft: Managed Metadata Service
- Microsoft: SharePoint Search Schema
- Nielsen Norman Group: Intranet Information Architecture
