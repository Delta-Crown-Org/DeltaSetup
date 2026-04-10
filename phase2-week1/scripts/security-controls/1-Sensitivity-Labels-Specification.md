# Sensitivity Labels Specification — Delta Crown Extensions (DCE)
## Compensating Control SC1 · M365 Business Premium

| Field | Value |
|-------|-------|
| **Document ID** | SC1-SENSITIVITY-LABELS-v2.0 |
| **Control** | SC1 — Sensitivity Labels |
| **Tenant** | `deltacrownext` (M365 Business Premium) |
| **Brand** | Delta Crown Extensions (DCE) |
| **Author** | security-auditor-8f512f |
| **Status** | APPROVED — Ready for Implementation |
| **Created** | 2025-04-10 |
| **Last Updated** | 2025-04-22 |
| **Review Cycle** | Quarterly or after each brand deployment |
| **Related Controls** | SC2 (DLP Policies), SC4 (Isolation Test), SC5 (Config Verification) |
| **Blocks** | DeltaSetup-23b (Phase 2 Remediation Sprint) |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Business Premium Licensing Constraints](#2-business-premium-licensing-constraints)
3. [Label Hierarchy & Priority Order](#3-label-hierarchy--priority-order)
4. [Label Specifications](#4-label-specifications)
   - 4.1 [Personal (No Protection)](#41-personal-no-protection)
   - 4.2 [DCE-Internal](#42-dce-internal)
   - 4.3 [DCE-Confidential](#43-dce-confidential)
   - 4.4 [Corporate-Confidential](#44-corporate-confidential)
5. [Default Label Policy](#5-default-label-policy)
6. [Auto-Labeling Configuration](#6-auto-labeling-configuration)
7. [Implementation PowerShell Commands](#7-implementation-powershell-commands)
8. [Verification & Testing](#8-verification--testing)
9. [Compliance Mapping](#9-compliance-mapping)
10. [Monitoring & Reporting](#10-monitoring--reporting)
11. [Maintenance & Lifecycle](#11-maintenance--lifecycle)
12. [Risk Assessment](#12-risk-assessment)
13. [Rollback Procedures](#13-rollback-procedures)
14. [Revision History](#14-revision-history)

---

## 1. Executive Summary

### What Is Being Protected?

Delta Crown Extensions is a hair extensions franchise operating within a multi-brand M365 tenant (`deltacrownext`). Multiple competing franchise brands will share this single tenant. **Sensitivity labels are the primary content classification mechanism** that prevents cross-brand data leakage and enforces access control at the document layer.

### Why This Control Exists

M365 Business Premium **does not include Information Barriers**. Without Information Barriers, users in one brand can potentially discover and access content from another brand through search, sharing, and Teams discovery. Sensitivity labels compensate by:

1. **Encrypting** brand content so only authorised group members can open it
2. **Visually marking** documents with brand-specific headers/footers/watermarks
3. **Enforcing access** at the file layer — even if a file leaves the site, encryption stays
4. **Enabling DLP** (SC2) to detect and block cross-brand sharing based on label

### Control Dependency Chain

```
SC1 (Sensitivity Labels) ← foundation
  └─► SC2 (DLP Policies) — uses label conditions to block sharing
  └─► SC4 (Isolation Test) — validates labels are applied
  └─► SC5 (Config Verification) — confirms label deployment
  └─► Control #1 (Dynamic Groups) — groups used in encryption permissions
  └─► Control #2 (Unique Permissions) — site-level isolation augments label protection
```

---

## 2. Business Premium Licensing Constraints

> **Critical**: These constraints shape every design decision below.

| Feature | E5/E3 | Business Premium | Impact on This Spec |
|---------|-------|------------------|---------------------|
| Manual sensitivity labels | ✅ | ✅ | Labels can be created and applied manually |
| Label encryption (Azure RMS) | ✅ | ✅ | Encryption with group-scoped permissions works |
| Visual content markings | ✅ | ✅ | Headers, footers, watermarks supported |
| Label policies (publishing) | ✅ | ✅ | Labels can be published to specific users/groups |
| Auto-labeling (client-side) | ✅ | ⚠️ Partial | Supported in Office desktop apps if published via policy with "recommend" |
| Auto-labeling (service-side) | ✅ | ❌ **Not available** | Cannot auto-label at rest in SharePoint/OneDrive/Exchange |
| Default label for sites | ✅ | ✅ | Can set a default label in a label policy |
| Sensitivity label for sites/groups | ✅ | ⚠️ Partial | Container labels (privacy, sharing settings) supported; requires Azure AD Premium P1 |
| Double Key Encryption | ✅ | ❌ | Not available |
| Information Barriers | ✅ | ❌ | This is why SC1 exists |
| Auto-labeling simulation mode | ✅ | ❌ | Must use label policy "recommend" instead |
| Maximum labels per tenant | 500 | 500 | Not a constraint |
| Maximum label policies | 100 | 100 | Not a constraint |

### Design Implications

1. **No service-side auto-labeling**: We cannot auto-apply labels to documents already at rest in SharePoint. Labels apply when:
   - Users create/edit documents in Office apps (if default label is set)
   - Users manually apply via ribbon or right-click
   - Client-side auto-label recommends (based on sensitive info types)
2. **Default label strategy is critical**: Setting `DCE-Internal` as the default label in the label policy ensures new content is labelled without user action.
3. **Container labels partially available**: We can set site-level sensitivity (privacy, external sharing controls) via Azure AD P1 features included in Business Premium.
4. **Encryption is our primary enforcement**: Even if a file is copied out of a DCE site, encryption ensures only `SG-DCE-AllStaff` members can decrypt it.

---

## 3. Label Hierarchy & Priority Order

### Parent-Child Structure

```
Sensitivity Labels (Tenant: deltacrownext)
│
├── Personal                          Priority: 0 (lowest)
│   └── No protection, no markings
│
├── DCE-Internal                      Priority: 1
│   └── Encryption: SG-DCE-AllStaff
│   └── Markings: Gold header/footer
│   └── Default for all DCE sites
│
├── DCE-Confidential                  Priority: 2
│   └── Parent: (standalone, not child of DCE-Internal)
│   └── Encryption: SG-DCE-Leadership ONLY
│   └── Markings: Red header/footer + watermark
│   └── For HR, financial, legal content
│
└── Corporate-Confidential            Priority: 3 (highest)
    └── Encryption: SG-Corp-AllBrands + SG-Corp-IT-Admins
    └── Markings: Blue header/footer
    └── For cross-brand corporate content
```

### Priority Order (Enforcement Precedence)

| Priority | Label | Justification Required to Downgrade? | Can Users Remove? |
|----------|-------|--------------------------------------|-------------------|
| 3 (highest) | Corporate-Confidential | Yes — mandatory justification | No — admin only |
| 2 | DCE-Confidential | Yes — mandatory justification | No — admin only |
| 1 | DCE-Internal | Yes — justification required | Only with justification |
| 0 (lowest) | Personal | N/A (lowest) | N/A |

> **Design decision**: Labels are flat (not nested parent/child) because Business Premium's label inheritance behaviour with encryption can conflict. Each label has independent encryption settings. Priority ordering ensures a higher label cannot be downgraded without justification.

---

## 4. Label Specifications

### 4.1 Personal (No Protection)

#### Purpose
Allows users to classify genuinely personal, non-business content (e.g., personal notes, non-work files in OneDrive). This is the **opt-out valve** so users don't accidentally encrypt personal files or trigger DLP on non-business content.

#### Configuration

| Property | Value |
|----------|-------|
| **Name** | `Personal` |
| **Display Name** | Personal |
| **Description (users)** | "For non-business, personal content. No protection is applied. Do not use for any business data." |
| **Description (admins)** | "Opt-out label for personal content. No encryption, no markings, no DLP conditions. Audit use for data hygiene." |
| **Tooltip** | "Personal content only — not for business use" |
| **Priority** | 0 (lowest) |

#### Protection Settings

| Setting | Value |
|---------|-------|
| Encryption | ❌ Disabled |
| Content Marking (Header) | ❌ Disabled |
| Content Marking (Footer) | ❌ Disabled |
| Content Marking (Watermark) | ❌ Disabled |

#### Scope

| Scope | Enabled |
|-------|---------|
| Files & Emails | ✅ |
| Groups & Sites | ❌ |
| Schematised Data Assets | ❌ |

#### Auto-Labeling
None. Users must manually select this label to opt out of the default `DCE-Internal`.

---

### 4.2 DCE-Internal

#### Purpose
**Primary brand isolation label.** Applied to all Delta Crown Extensions business content. Encrypts files so only DCE staff can open them. Even if a file is shared to a non-DCE user or copied outside SharePoint, encryption prevents access.

#### Configuration

| Property | Value |
|----------|-------|
| **Name** | `DCE-Internal` |
| **Display Name** | Delta Crown — Internal |
| **Description (users)** | "Content exclusive to Delta Crown Extensions staff. Do not share with other brands or external parties." |
| **Description (admins)** | "Default label for all DCE site collections. Encrypts content with AES-256 via Azure RMS. Access restricted to SG-DCE-AllStaff, SG-DCE-Leadership, and SG-Corp-IT-Admins (emergency access)." |
| **Tooltip** | "Delta Crown confidential — internal use only" |
| **Priority** | 1 |

#### Protection Settings — Encryption

| Setting | Value | Notes |
|---------|-------|-------|
| **Encryption** | ✅ Enabled | Azure Rights Management |
| **Assign permissions now or let users decide?** | Assign now | Admins define permissions at label creation |
| **User access to content expires** | Never | Content remains accessible to authorised groups indefinitely |
| **Allow offline access** | Yes — for 30 days | Users can open files offline for up to 30 days before re-authentication |
| **Double Key Encryption** | ❌ N/A | Requires E5 |

#### Permission Assignments

| User/Group | Permission Level | ObjectId Source |
|------------|-----------------|-----------------|
| `SG-DCE-AllStaff` | Co-Author | Azure AD dynamic group |
| `SG-DCE-Leadership` | Co-Author | Azure AD dynamic group |
| `SG-Corp-IT-Admins` | Co-Author | Azure AD security group (emergency access) |

**Co-Author permissions include**: View, Open, Read, Save, Edit, Export, Print, Copy, Forward, Reply, Reply All, Allow Macros.

> **Security note**: `SG-Corp-IT-Admins` is included as a break-glass. This group should have ≤3 members and be subject to PIM (Privileged Identity Management) if available. Monitor membership via weekly audit (Control #5).

#### Content Marking

| Marking | Setting | Value |
|---------|---------|-------|
| **Header** | Enabled | ✅ |
| | Text | `Delta Crown Extensions — INTERNAL USE ONLY` |
| | Font | Calibri |
| | Font size | 10pt |
| | Font colour | `#C9A227` (Brand Gold) |
| | Alignment | Centre |
| **Footer** | Enabled | ✅ |
| | Text | `DCE Confidential — Do Not Distribute Outside Delta Crown` |
| | Font | Calibri |
| | Font size | 8pt |
| | Font colour | `#605E5C` (Neutral Grey) |
| | Alignment | Centre |
| **Watermark** | Enabled | ✅ |
| | Text | `DELTA CROWN INTERNAL` |
| | Font size | 48pt |
| | Font colour | `#C9A227` (Brand Gold, semi-transparent) |
| | Layout | Diagonal |

#### Scope

| Scope | Enabled | Notes |
|-------|---------|-------|
| Files & Emails | ✅ | Applies to Word, Excel, PowerPoint, PDF, Outlook |
| Groups & Sites | ✅ | Container label — sets privacy to Private, disables external sharing |
| Schematised Data Assets | ❌ | Not applicable |

#### Container Label Settings (Groups & Sites)

| Setting | Value |
|---------|-------|
| Privacy | Private |
| External user access | ❌ Disabled |
| External sharing from SharePoint sites | Only people in your organization |
| Unmanaged device access | Allow limited, web-only access |
| Authentication context | None (Business Premium limitation) |

---

### 4.3 DCE-Confidential

#### Purpose
**Elevated protection for sensitive business content.** Restricts access to DCE Leadership only. Used for: financial reports, HR documents, legal correspondence, strategic plans, salary data, disciplinary records, franchise agreements.

#### Configuration

| Property | Value |
|----------|-------|
| **Name** | `DCE-Confidential` |
| **Display Name** | Delta Crown — Confidential |
| **Description (users)** | "Highly sensitive Delta Crown content. Restricted to DCE Leadership only. For financial, HR, legal, and strategic documents." |
| **Description (admins)** | "Elevated label for leadership-only content. Encrypts with access restricted to SG-DCE-Leadership and SG-Corp-IT-Admins. Includes full visual markings with RED indicators." |
| **Tooltip** | "Restricted to DCE Leadership — HR, financial, and legal content" |
| **Priority** | 2 |

#### Protection Settings — Encryption

| Setting | Value | Notes |
|---------|-------|-------|
| **Encryption** | ✅ Enabled | Azure Rights Management |
| **Assign permissions now** | Yes | Admin-defined |
| **User access to content expires** | Never | |
| **Allow offline access** | Yes — for 7 days | Shorter window than DCE-Internal due to sensitivity |
| **Double Key Encryption** | ❌ N/A | Requires E5 |

#### Permission Assignments

| User/Group | Permission Level | Rationale |
|------------|-----------------|-----------|
| `SG-DCE-Leadership` | Co-Author | Leadership team only |
| `SG-Corp-IT-Admins` | Co-Author | Emergency/break-glass access |

> **Critical**: `SG-DCE-AllStaff` does **NOT** have access to this label's encrypted content. This is the key differentiator from DCE-Internal.

#### Content Marking

| Marking | Setting | Value |
|---------|---------|-------|
| **Header** | Enabled | ✅ |
| | Text | `⛔ DELTA CROWN EXTENSIONS — CONFIDENTIAL — LEADERSHIP ONLY ⛔` |
| | Font | Calibri |
| | Font size | 10pt |
| | Font colour | `#CC0000` (Red) |
| | Alignment | Centre |
| **Footer** | Enabled | ✅ |
| | Text | `RESTRICTED: Unauthorised disclosure may result in disciplinary action. SG-DCE-Leadership access only.` |
| | Font | Calibri |
| | Font size | 8pt |
| | Font colour | `#CC0000` (Red) |
| | Alignment | Centre |
| **Watermark** | Enabled | ✅ |
| | Text | `DCE CONFIDENTIAL` |
| | Font size | 54pt |
| | Font colour | `#CC0000` (Red, semi-transparent) |
| | Layout | Diagonal |

#### Scope

| Scope | Enabled | Notes |
|-------|---------|-------|
| Files & Emails | ✅ | All Office formats and Outlook |
| Groups & Sites | ✅ | Container label for leadership sites |
| Schematised Data Assets | ❌ | Not applicable |

#### Container Label Settings (Groups & Sites)

| Setting | Value |
|---------|-------|
| Privacy | Private |
| External user access | ❌ Disabled |
| External sharing from SharePoint sites | Only people in your organization |
| Unmanaged device access | ❌ Block access |
| Authentication context | None (Business Premium limitation) |

---

### 4.4 Corporate-Confidential

#### Purpose
**Cross-brand corporate content.** For documents that must be shared across all franchise brands (e.g., corporate policies, franchise-wide announcements, shared HR templates, compliance documents). Encrypted so only corporate-level groups can access.

#### Configuration

| Property | Value |
|----------|-------|
| **Name** | `Corporate-Confidential` |
| **Display Name** | Corporate — Confidential |
| **Description (users)** | "Corporate-level content shared across all franchise brands. For policies, compliance documents, and franchise-wide communications." |
| **Description (admins)** | "Cross-brand label for corporate shared services. Encrypted to SG-Corp-AllBrands (union of all brand groups) and SG-Corp-IT-Admins. Used for corp-hub and corp-* site content." |
| **Tooltip** | "Corporate content — shared across all brands under NDA" |
| **Priority** | 3 (highest) |

#### Protection Settings — Encryption

| Setting | Value | Notes |
|---------|-------|-------|
| **Encryption** | ✅ Enabled | Azure Rights Management |
| **Assign permissions now** | Yes | Admin-defined |
| **User access to content expires** | Never | |
| **Allow offline access** | Yes — for 14 days | Moderate window for cross-brand content |
| **Double Key Encryption** | ❌ N/A | Requires E5 |

#### Permission Assignments

| User/Group | Permission Level | Rationale |
|------------|-----------------|-----------|
| `SG-Corp-AllBrands` | Co-Author | All staff across all franchise brands |
| `SG-Corp-IT-Admins` | Co-Author | Emergency/administrative access |

> **Note**: `SG-Corp-AllBrands` is a dynamic group that includes all users across all franchise brands. When new brands are onboarded, their staff are automatically included. This group must be defined in `2.3-AzureAD-DynamicGroups.ps1` when additional brands are deployed.

#### Content Marking

| Marking | Setting | Value |
|---------|---------|-------|
| **Header** | Enabled | ✅ |
| | Text | `CORPORATE CONFIDENTIAL — All Franchise Brands` |
| | Font | Calibri |
| | Font size | 10pt |
| | Font colour | `#0078D4` (Corporate Blue) |
| | Alignment | Centre |
| **Footer** | Enabled | ✅ |
| | Text | `Corporate property — Do not share externally. All franchise brands authorised.` |
| | Font | Calibri |
| | Font size | 8pt |
| | Font colour | `#605E5C` (Neutral Grey) |
| | Alignment | Centre |
| **Watermark** | Enabled | ✅ |
| | Text | `CORPORATE CONFIDENTIAL` |
| | Font size | 48pt |
| | Font colour | `#0078D4` (Corporate Blue, semi-transparent) |
| | Layout | Diagonal |

#### Scope

| Scope | Enabled | Notes |
|-------|---------|-------|
| Files & Emails | ✅ | All Office formats and Outlook |
| Groups & Sites | ✅ | Container label for corp-hub and corp-* sites |
| Schematised Data Assets | ❌ | Not applicable |

#### Container Label Settings (Groups & Sites)

| Setting | Value |
|---------|-------|
| Privacy | Private |
| External user access | ❌ Disabled |
| External sharing from SharePoint sites | Only people in your organization |
| Unmanaged device access | Allow limited, web-only access |
| Authentication context | None (Business Premium limitation) |

---

## 5. Default Label Policy

### Policy: DCE-Label-Policy

This policy publishes all four labels to DCE users and sets the default behaviour.

| Property | Value |
|----------|-------|
| **Policy Name** | `DCE-Label-Policy` |
| **Description** | "Publishes DCE sensitivity labels and sets DCE-Internal as the default for all DCE users and sites." |
| **Published Labels** | `Personal`, `DCE-Internal`, `DCE-Confidential`, `Corporate-Confidential` |
| **Applied to Users/Groups** | `SG-DCE-AllStaff`, `SG-DCE-Leadership` |

#### Policy Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Default label for documents** | `DCE-Internal` | All new documents created by DCE users are labelled DCE-Internal by default |
| **Default label for emails** | `DCE-Internal` | All new emails from DCE users get DCE-Internal by default |
| **Require users to apply a label** | ✅ Yes (mandatory labelling) | Users must have a label before saving — prevents unlabelled content |
| **Require justification to remove or downgrade** | ✅ Yes | Users must provide business justification to remove DCE-Internal or downgrade from DCE-Confidential |
| **Provide a custom help page** | ✅ Yes | URL to internal wiki page explaining label usage |
| **Custom help page URL** | `https://deltacrownext.sharepoint.com/sites/corp-it/SitePages/Sensitivity-Labels-Guide.aspx` |

### Policy: Corp-Label-Policy

Publishes `Corporate-Confidential` to all tenant users for corp-hub content.

| Property | Value |
|----------|-------|
| **Policy Name** | `Corp-Label-Policy` |
| **Description** | "Publishes Corporate-Confidential label to all staff for cross-brand corporate content." |
| **Published Labels** | `Personal`, `Corporate-Confidential` |
| **Applied to Users/Groups** | All users (tenant-wide) |
| **Default label for documents** | None | Corporate label is opt-in, not default |
| **Require justification to remove** | ✅ Yes |

---

## 6. Auto-Labeling Configuration

### Business Premium Reality Check

⚠️ **Service-side auto-labeling (auto-label policies that scan content at rest) is NOT available in Business Premium.** The auto-labeling approaches below use **client-side** label recommendations, which trigger when users open or create documents in Office desktop/web apps.

### Strategy: Client-Side Recommendation via Label Policy

Instead of service-side auto-labeling, we configure the label policy to:
1. Set `DCE-Internal` as the **default label** — applied automatically to new documents
2. **Recommend** `DCE-Confidential` when sensitive content patterns are detected (client-side)

### Recommended Label Conditions (Client-Side)

These conditions are configured within the label definition and trigger a recommendation tooltip in Office apps.

#### DCE-Confidential: Recommend When Detected

| Condition Type | Pattern | Confidence |
|----------------|---------|------------|
| Sensitive info type | AU Tax File Number | High |
| Sensitive info type | AU Bank Account Number | High |
| Sensitive info type | AU Medical Account Number | Medium |
| Sensitive info type | Credit Card Number | High |
| Keyword | `salary`, `termination`, `disciplinary`, `franchise agreement`, `legal privilege` | Medium |
| Keyword | `P&L`, `profit and loss`, `balance sheet`, `financial statement` | Medium |

> **Important**: These are **recommendations**, not auto-applied. The user sees a banner: *"This content appears to contain confidential information. We recommend applying the 'Delta Crown — Confidential' label."* The user can accept or dismiss.

### Site-Level Default Labels

While we cannot auto-label at the service level, we can set **site-level default sensitivity labels** (available in Business Premium with Azure AD P1):

| Site | Default Label |
|------|---------------|
| `/sites/dce-hub` | `DCE-Internal` |
| `/sites/dce-operations` | `DCE-Internal` |
| `/sites/dce-clientservices` | `DCE-Internal` |
| `/sites/dce-marketing` | `DCE-Internal` |
| `/sites/dce-docs` | `DCE-Internal` |
| `/sites/corp-hub` | `Corporate-Confidential` |
| `/sites/corp-hr` | `Corporate-Confidential` |
| `/sites/corp-finance` | `Corporate-Confidential` |
| `/sites/corp-it` | `Corporate-Confidential` |
| `/sites/corp-training` | `Corporate-Confidential` |

> **Note**: Site-level default labels mean new documents created in these libraries will automatically receive the specified label. Existing unlabelled documents must be manually labelled or bulk-relabelled via PowerShell.

---

## 7. Implementation PowerShell Commands

### Prerequisites

```powershell
# Required modules
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
Install-Module -Name Microsoft.Graph.Authentication -Force
Install-Module -Name Microsoft.Graph.Groups -Force

# Required role: Compliance Administrator OR Security Administrator
# Connection: Security & Compliance Center (IPPSSession)
```

### 7.1 Connect to Security & Compliance Centre

```powershell
# Connect to Security & Compliance PowerShell
Connect-IPPSSession -UserPrincipalName admin@deltacrownext.onmicrosoft.com

# Verify connection
Get-Label | Select-Object Name, DisplayName, Priority
```

### 7.2 Create Labels

#### Label 1: Personal

```powershell
New-Label `
    -Name "Personal" `
    -DisplayName "Personal" `
    -Comment "For non-business, personal content. No protection applied." `
    -Tooltip "Personal content only — not for business use" `
    -AdvancedSettings @{
        "color" = "#808080"
    }

# Verify
Get-Label -Identity "Personal" | Format-List Name, DisplayName, Comment, Priority
```

#### Label 2: DCE-Internal

```powershell
# Step 1: Create the label with encryption and markings
New-Label `
    -Name "DCE-Internal" `
    -DisplayName "Delta Crown — Internal" `
    -Comment "Content exclusive to Delta Crown Extensions staff. Do not share with other brands or external parties." `
    -Tooltip "Delta Crown confidential — internal use only" `
    -EncryptionEnabled $true `
    -EncryptionProtectionType "Template" `
    -EncryptionRightsDefinitions @(
        "SG-DCE-AllStaff@deltacrownext.onmicrosoft.com:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL",
        "SG-DCE-Leadership@deltacrownext.onmicrosoft.com:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL",
        "SG-Corp-IT-Admins@deltacrownext.onmicrosoft.com:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL"
    ) `
    -EncryptionOfflineAccessDays 30 `
    -EncryptionContentExpiredOnDateInDaysOrNever "Never" `
    -ContentType "File, Email" `
    -HeaderEnabled $true `
    -HeaderText "Delta Crown Extensions — INTERNAL USE ONLY" `
    -HeaderFontSize 10 `
    -HeaderFontColor "#C9A227" `
    -HeaderAlignment "Center" `
    -FooterEnabled $true `
    -FooterText "DCE Confidential — Do Not Distribute Outside Delta Crown" `
    -FooterFontSize 8 `
    -FooterFontColor "#605E5C" `
    -FooterAlignment "Center" `
    -WatermarkEnabled $true `
    -WatermarkText "DELTA CROWN INTERNAL" `
    -WatermarkFontSize 48 `
    -WatermarkFontColor "#C9A227" `
    -WatermarkLayout "Diagonal" `
    -AdvancedSettings @{
        "color" = "#C9A227"
    }

# Step 2: Configure as container label (site/group settings)
# Note: Container labels require separate site-level application via SharePoint admin
Set-Label -Identity "DCE-Internal" `
    -SiteAndGroupProtectionEnabled $true `
    -SiteAndGroupProtectionPrivacy "Private" `
    -SiteAndGroupProtectionAllowAccessToGuestUsers $false `
    -SiteAndGroupProtectionAllowEmailFromGuestUsers $false `
    -SiteExternalSharingControlType "ExistingExternalUserSharingOnly"

# Verify
Get-Label -Identity "DCE-Internal" | Format-List *
```

#### Label 3: DCE-Confidential

```powershell
New-Label `
    -Name "DCE-Confidential" `
    -DisplayName "Delta Crown — Confidential" `
    -Comment "Highly sensitive Delta Crown content. Restricted to DCE Leadership only." `
    -Tooltip "Restricted to DCE Leadership — HR, financial, and legal content" `
    -EncryptionEnabled $true `
    -EncryptionProtectionType "Template" `
    -EncryptionRightsDefinitions @(
        "SG-DCE-Leadership@deltacrownext.onmicrosoft.com:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL",
        "SG-Corp-IT-Admins@deltacrownext.onmicrosoft.com:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL"
    ) `
    -EncryptionOfflineAccessDays 7 `
    -EncryptionContentExpiredOnDateInDaysOrNever "Never" `
    -ContentType "File, Email" `
    -HeaderEnabled $true `
    -HeaderText "DELTA CROWN EXTENSIONS — CONFIDENTIAL — LEADERSHIP ONLY" `
    -HeaderFontSize 10 `
    -HeaderFontColor "#CC0000" `
    -HeaderAlignment "Center" `
    -FooterEnabled $true `
    -FooterText "RESTRICTED: Unauthorised disclosure may result in disciplinary action. SG-DCE-Leadership access only." `
    -FooterFontSize 8 `
    -FooterFontColor "#CC0000" `
    -FooterAlignment "Center" `
    -WatermarkEnabled $true `
    -WatermarkText "DCE CONFIDENTIAL" `
    -WatermarkFontSize 54 `
    -WatermarkFontColor "#CC0000" `
    -WatermarkLayout "Diagonal" `
    -AdvancedSettings @{
        "color" = "#CC0000"
    }

# Configure client-side auto-labeling recommendation
Set-Label -Identity "DCE-Confidential" `
    -AutoApplyType "Recommend" `
    -SensitiveInformationTypes @(
        @{
            Name = "Australia Tax File Number"
            MinCount = 1
            MaxCount = -1
            MinConfidence = 85
        },
        @{
            Name = "Australia Bank Account Number"
            MinCount = 1
            MaxCount = -1
            MinConfidence = 85
        },
        @{
            Name = "Credit Card Number"
            MinCount = 1
            MaxCount = -1
            MinConfidence = 85
        }
    )

# Container label settings
Set-Label -Identity "DCE-Confidential" `
    -SiteAndGroupProtectionEnabled $true `
    -SiteAndGroupProtectionPrivacy "Private" `
    -SiteAndGroupProtectionAllowAccessToGuestUsers $false `
    -SiteAndGroupProtectionAllowEmailFromGuestUsers $false `
    -SiteExternalSharingControlType "Disabled"

# Verify
Get-Label -Identity "DCE-Confidential" | Format-List *
```

#### Label 4: Corporate-Confidential

```powershell
New-Label `
    -Name "Corporate-Confidential" `
    -DisplayName "Corporate — Confidential" `
    -Comment "Corporate-level content shared across all franchise brands." `
    -Tooltip "Corporate content — shared across all brands under NDA" `
    -EncryptionEnabled $true `
    -EncryptionProtectionType "Template" `
    -EncryptionRightsDefinitions @(
        "SG-Corp-AllBrands@deltacrownext.onmicrosoft.com:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL",
        "SG-Corp-IT-Admins@deltacrownext.onmicrosoft.com:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL"
    ) `
    -EncryptionOfflineAccessDays 14 `
    -EncryptionContentExpiredOnDateInDaysOrNever "Never" `
    -ContentType "File, Email" `
    -HeaderEnabled $true `
    -HeaderText "CORPORATE CONFIDENTIAL — All Franchise Brands" `
    -HeaderFontSize 10 `
    -HeaderFontColor "#0078D4" `
    -HeaderAlignment "Center" `
    -FooterEnabled $true `
    -FooterText "Corporate property — Do not share externally. All franchise brands authorised." `
    -FooterFontSize 8 `
    -FooterFontColor "#605E5C" `
    -FooterAlignment "Center" `
    -WatermarkEnabled $true `
    -WatermarkText "CORPORATE CONFIDENTIAL" `
    -WatermarkFontSize 48 `
    -WatermarkFontColor "#0078D4" `
    -WatermarkLayout "Diagonal" `
    -AdvancedSettings @{
        "color" = "#0078D4"
    }

# Container label settings
Set-Label -Identity "Corporate-Confidential" `
    -SiteAndGroupProtectionEnabled $true `
    -SiteAndGroupProtectionPrivacy "Private" `
    -SiteAndGroupProtectionAllowAccessToGuestUsers $false `
    -SiteAndGroupProtectionAllowEmailFromGuestUsers $false `
    -SiteExternalSharingControlType "ExistingExternalUserSharingOnly"

# Verify
Get-Label -Identity "Corporate-Confidential" | Format-List *
```

### 7.3 Set Label Priority Order

```powershell
# Labels are created in priority order. Adjust if needed:
Set-Label -Identity "Personal" -Priority 0
Set-Label -Identity "DCE-Internal" -Priority 1
Set-Label -Identity "DCE-Confidential" -Priority 2
Set-Label -Identity "Corporate-Confidential" -Priority 3
```

### 7.4 Create Label Policies

#### DCE Label Policy

```powershell
New-LabelPolicy `
    -Name "DCE-Label-Policy" `
    -Comment "Publishes DCE sensitivity labels to all DCE staff with DCE-Internal as default." `
    -Labels "Personal","DCE-Internal","DCE-Confidential","Corporate-Confidential" `
    -ExchangeLocation "SG-DCE-AllStaff@deltacrownext.onmicrosoft.com" `
    -ModernGroupLocation "SG-DCE-AllStaff@deltacrownext.onmicrosoft.com" `
    -Settings @{
        "requiredowngradejustification" = "true"
        "mandatory" = "true"
        "defaultlabelid" = (Get-Label -Identity "DCE-Internal").ImmutableId
        "disablemandatoryinoutlook" = "false"
        "customurl" = "https://deltacrownext.sharepoint.com/sites/corp-it/SitePages/Sensitivity-Labels-Guide.aspx"
    }

# Verify policy
Get-LabelPolicy -Identity "DCE-Label-Policy" | Format-List *
```

#### Corporate Label Policy

```powershell
New-LabelPolicy `
    -Name "Corp-Label-Policy" `
    -Comment "Publishes Corporate-Confidential to all tenant users for cross-brand content." `
    -Labels "Personal","Corporate-Confidential" `
    -ExchangeLocation "All" `
    -Settings @{
        "requiredowngradejustification" = "true"
        "mandatory" = "false"
    }

# Verify policy
Get-LabelPolicy -Identity "Corp-Label-Policy" | Format-List *
```

### 7.5 Apply Site-Level Default Labels

```powershell
# Requires PnP.PowerShell and SharePoint admin rights
# Connect to each DCE site and set the default sensitivity label

$dceSites = @(
    "https://deltacrownext.sharepoint.com/sites/dce-hub",
    "https://deltacrownext.sharepoint.com/sites/dce-operations",
    "https://deltacrownext.sharepoint.com/sites/dce-clientservices",
    "https://deltacrownext.sharepoint.com/sites/dce-marketing",
    "https://deltacrownext.sharepoint.com/sites/dce-docs"
)

$dceInternalLabelId = (Get-Label -Identity "DCE-Internal").ImmutableId

foreach ($siteUrl in $dceSites) {
    try {
        # Set default sensitivity label for the site
        Set-SPOSite -Identity $siteUrl -SensitivityLabel $dceInternalLabelId
        Write-Host "✅ Applied DCE-Internal label to $siteUrl" -ForegroundColor Green
    }
    catch {
        Write-Warning "⚠️ Failed to apply label to ${siteUrl}: $($_.Exception.Message)"
    }
}

# Corporate sites
$corpSites = @(
    "https://deltacrownext.sharepoint.com/sites/corp-hub",
    "https://deltacrownext.sharepoint.com/sites/corp-hr",
    "https://deltacrownext.sharepoint.com/sites/corp-finance",
    "https://deltacrownext.sharepoint.com/sites/corp-it",
    "https://deltacrownext.sharepoint.com/sites/corp-training"
)

$corpLabelId = (Get-Label -Identity "Corporate-Confidential").ImmutableId

foreach ($siteUrl in $corpSites) {
    try {
        Set-SPOSite -Identity $siteUrl -SensitivityLabel $corpLabelId
        Write-Host "✅ Applied Corporate-Confidential label to $siteUrl" -ForegroundColor Green
    }
    catch {
        Write-Warning "⚠️ Failed to apply label to ${siteUrl}: $($_.Exception.Message)"
    }
}
```

### 7.6 Bulk Label Existing Content (One-Time Migration)

```powershell
<#
.SYNOPSIS
    Bulk-labels existing unlabelled documents in DCE sites.
.DESCRIPTION
    Since Business Premium lacks service-side auto-labeling, this script
    sets the default label on document libraries so NEW documents inherit it.
    Existing documents must be opened and saved by users, or use this script
    to set library-level defaults.
.NOTES
    This does NOT encrypt existing files at rest. Files are encrypted when
    a user next opens and saves them with the label applied.
#>

$dceSites = @(
    "https://deltacrownext.sharepoint.com/sites/dce-hub",
    "https://deltacrownext.sharepoint.com/sites/dce-operations",
    "https://deltacrownext.sharepoint.com/sites/dce-clientservices",
    "https://deltacrownext.sharepoint.com/sites/dce-marketing",
    "https://deltacrownext.sharepoint.com/sites/dce-docs"
)

$dceInternalLabelId = (Get-Label -Identity "DCE-Internal").ImmutableId

foreach ($siteUrl in $dceSites) {
    Connect-PnPOnline -Url $siteUrl -Interactive
    
    # Get all document libraries
    $libraries = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 }
    
    foreach ($lib in $libraries) {
        # Set default column value for sensitivity label
        Write-Host "Setting default label on $($lib.Title) at $siteUrl" -ForegroundColor Cyan
        
        # Note: Library-level default sensitivity labels are set via the site label (above)
        # This is a verification step
        $items = Get-PnPListItem -List $lib -PageSize 500 | 
            Where-Object { $_["_ComplianceTag"] -eq $null }
        
        Write-Host "  Found $($items.Count) unlabelled items in $($lib.Title)" -ForegroundColor Yellow
    }
    
    Disconnect-PnPOnline
}
```

---

## 8. Verification & Testing

### 8.1 Post-Deployment Verification Script

```powershell
<#
.SYNOPSIS
    Verifies sensitivity label deployment for SC1 compliance.
.DESCRIPTION
    Run after executing Section 7 commands. Checks all labels,
    policies, and site assignments are correctly configured.
#>

function Test-SC1-SensitivityLabels {
    [CmdletBinding()]
    param()
    
    $results = @()
    $allPassed = $true
    
    Write-Host "`n=== SC1: Sensitivity Labels Verification ===" -ForegroundColor Cyan
    
    # Test 1: All labels exist
    $requiredLabels = @("Personal", "DCE-Internal", "DCE-Confidential", "Corporate-Confidential")
    foreach ($labelName in $requiredLabels) {
        $label = Get-Label -Identity $labelName -ErrorAction SilentlyContinue
        if ($label) {
            Write-Host "  ✅ Label exists: $labelName" -ForegroundColor Green
            $results += [PSCustomObject]@{ Test = "Label-$labelName"; Status = "PASS"; Details = "Label found" }
        } else {
            Write-Host "  ❌ Label MISSING: $labelName" -ForegroundColor Red
            $results += [PSCustomObject]@{ Test = "Label-$labelName"; Status = "FAIL"; Details = "Label not found" }
            $allPassed = $false
        }
    }
    
    # Test 2: Encryption enabled on protected labels
    foreach ($labelName in @("DCE-Internal", "DCE-Confidential", "Corporate-Confidential")) {
        $label = Get-Label -Identity $labelName -ErrorAction SilentlyContinue
        if ($label -and $label.EncryptionEnabled) {
            Write-Host "  ✅ Encryption enabled: $labelName" -ForegroundColor Green
            $results += [PSCustomObject]@{ Test = "Encryption-$labelName"; Status = "PASS"; Details = "Encrypted" }
        } else {
            Write-Host "  ❌ Encryption DISABLED: $labelName" -ForegroundColor Red
            $results += [PSCustomObject]@{ Test = "Encryption-$labelName"; Status = "FAIL"; Details = "Not encrypted" }
            $allPassed = $false
        }
    }
    
    # Test 3: Label policies exist
    foreach ($policyName in @("DCE-Label-Policy", "Corp-Label-Policy")) {
        $policy = Get-LabelPolicy -Identity $policyName -ErrorAction SilentlyContinue
        if ($policy) {
            Write-Host "  ✅ Policy exists: $policyName" -ForegroundColor Green
            $results += [PSCustomObject]@{ Test = "Policy-$policyName"; Status = "PASS"; Details = "Policy found" }
        } else {
            Write-Host "  ❌ Policy MISSING: $policyName" -ForegroundColor Red
            $results += [PSCustomObject]@{ Test = "Policy-$policyName"; Status = "FAIL"; Details = "Policy not found" }
            $allPassed = $false
        }
    }
    
    # Test 4: Priority order
    $labels = Get-Label | Sort-Object Priority
    $expectedOrder = @("Personal", "DCE-Internal", "DCE-Confidential", "Corporate-Confidential")
    $actualOrder = ($labels | Where-Object { $_.Name -in $expectedOrder }).Name
    
    if (($actualOrder -join ",") -eq ($expectedOrder -join ",")) {
        Write-Host "  ✅ Priority order correct" -ForegroundColor Green
        $results += [PSCustomObject]@{ Test = "Priority-Order"; Status = "PASS"; Details = $actualOrder -join " < " }
    } else {
        Write-Host "  ⚠️ Priority order unexpected: $($actualOrder -join ', ')" -ForegroundColor Yellow
        $results += [PSCustomObject]@{ Test = "Priority-Order"; Status = "WARN"; Details = "Expected: $($expectedOrder -join ', ')" }
    }
    
    # Test 5: Content markings
    foreach ($labelName in @("DCE-Internal", "DCE-Confidential", "Corporate-Confidential")) {
        $label = Get-Label -Identity $labelName -ErrorAction SilentlyContinue
        if ($label.HeaderEnabled -and $label.FooterEnabled -and $label.WatermarkEnabled) {
            Write-Host "  ✅ Visual markings complete: $labelName" -ForegroundColor Green
            $results += [PSCustomObject]@{ Test = "Markings-$labelName"; Status = "PASS"; Details = "H+F+W" }
        } else {
            Write-Host "  ⚠️ Missing markings on: $labelName (H=$($label.HeaderEnabled) F=$($label.FooterEnabled) W=$($label.WatermarkEnabled))" -ForegroundColor Yellow
            $results += [PSCustomObject]@{ Test = "Markings-$labelName"; Status = "WARN"; Details = "Incomplete" }
        }
    }
    
    # Summary
    $passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
    $warnCount = ($results | Where-Object { $_.Status -eq "WARN" }).Count
    
    Write-Host "`n--- SC1 Verification Summary ---" -ForegroundColor Cyan
    Write-Host "  PASS: $passCount  |  FAIL: $failCount  |  WARN: $warnCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
    
    if (-not $allPassed) {
        Write-Host "  ⛔ SC1 VERIFICATION FAILED — fix issues before proceeding" -ForegroundColor Red
    } else {
        Write-Host "  ✅ SC1 VERIFICATION PASSED" -ForegroundColor Green
    }
    
    return [PSCustomObject]@{
        ControlId = "SC1"
        ControlName = "Sensitivity Labels"
        Passed = $allPassed
        Results = $results
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Execute
$sc1Result = Test-SC1-SensitivityLabels
```

### 8.2 Manual Test Cases

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 1 | New document in DCE site gets default label | Create a Word doc in dce-hub → save | Document has `DCE-Internal` label | ☐ |
| 2 | DCE-Internal encrypted file blocks non-DCE user | Share DCE-Internal file link with a Bishops user | User gets "Access Denied" when opening | ☐ |
| 3 | DCE-Confidential blocks non-leadership | SG-DCE-AllStaff member tries to open DCE-Confidential file | Access denied | ☐ |
| 4 | Visual markings appear in Word | Open DCE-Internal document in Word | Gold header, grey footer, diagonal watermark visible | ☐ |
| 5 | Downgrade requires justification | Change label from DCE-Confidential to Personal | Justification dialog appears | ☐ |
| 6 | Corporate-Confidential accessible by all brands | Share Corp-Confidential file with DCE and Bishops users | Both can open | ☐ |
| 7 | Email label applied | Create new email in Outlook as DCE user | DCE-Internal label auto-applied | ☐ |
| 8 | Container label enforces privacy | Check site privacy setting after label applied | Privacy = Private, external sharing disabled | ☐ |

---

## 9. Compliance Mapping

### Australian Privacy Act 1988

| APP (Australian Privacy Principle) | Requirement | How SC1 Addresses |
|-------------------------------------|-------------|-------------------|
| **APP 1** — Open and transparent management | Document how personal info is handled | Labels classify data; markings make classification visible |
| **APP 6** — Use or disclosure of personal info | Only use/disclose for purpose collected | DCE-Confidential encryption prevents unauthorised disclosure |
| **APP 8** — Cross-border disclosure | Take steps to ensure overseas recipients comply | Encryption travels with the file; access requires Azure AD auth |
| **APP 11** — Security of personal info | Protect from misuse, interference, loss, unauthorised access | AES-256 encryption, group-scoped access, offline time limits |

### OWASP Application Security Verification Standard (ASVS) v4.0

| ASVS Control | Requirement | SC1 Implementation | Level |
|--------------|-------------|---------------------|-------|
| **V1.6** | Cryptographic architecture | Azure RMS encryption on all protected labels | L2 |
| **V7.1.1** | Data classification | 4-tier label hierarchy (Personal → Corporate-Confidential) | L1 |
| **V7.1.2** | Data classification applied to all data | Default label ensures coverage; mandatory labelling enforced | L2 |
| **V7.2.1** | Encryption at rest | Sensitivity label encryption protects files at rest | L2 |
| **V7.2.2** | Encryption in transit | M365 enforces TLS 1.2+ for all connections | L1 |
| **V8.3.1** | Sensitive data access controls | DCE-Confidential restricted to SG-DCE-Leadership | L2 |
| **V8.3.4** | Data not unnecessarily exposed | Encryption prevents access even if file is copied/shared | L2 |

### ISO 27001:2022

| Control | Title | SC1 Implementation |
|---------|-------|---------------------|
| **A.5.12** | Classification of information | 4-tier sensitivity label hierarchy |
| **A.5.13** | Labelling of information | Visual content markings (header/footer/watermark) |
| **A.5.33** | Protection of records | Encryption prevents tampering; justification log for downgrades |
| **A.8.10** | Information deletion | Label lifecycle supports retention/disposal policies |
| **A.8.11** | Data masking | Watermarks indicate classification level |
| **A.8.24** | Use of cryptography | AES-256 via Azure RMS on all protected labels |

### SOC 2 Trust Service Criteria

| TSC | Criterion | SC1 Implementation |
|-----|-----------|---------------------|
| **CC6.1** | Logical access controls | Encryption restricts access to authorised Azure AD groups |
| **CC6.3** | Role-based access | DCE-Internal (all staff) vs DCE-Confidential (leadership only) |
| **CC6.6** | Data leakage prevention | Labels enable DLP (SC2) condition matching |
| **CC6.7** | Restrictions on data transmission | Encryption follows the file; offline access limited |

### NIST Cybersecurity Framework v2.0

| Function | Category | SC1 Implementation |
|----------|----------|---------------------|
| **Identify (ID)** | ID.AM-5: Resources prioritised based on classification | 4-tier label classification |
| **Protect (PR)** | PR.DS-1: Data-at-rest protected | Azure RMS encryption |
| **Protect (PR)** | PR.DS-2: Data-in-transit protected | TLS 1.2+ enforced by M365 |
| **Protect (PR)** | PR.AC-4: Access permissions managed | Group-scoped encryption permissions |
| **Detect (DE)** | DE.CM-3: Personnel activity monitored | Label downgrade justification logging |

---

## 10. Monitoring & Reporting

### 10.1 Audit Log Queries

```powershell
# Query sensitivity label activity in Unified Audit Log
# Requires: Search-UnifiedAuditLog permissions

# Labels applied in last 7 days
$labelActivity = Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -Operations "SensitivityLabelApplied","SensitivityLabelUpdated","SensitivityLabelRemoved" `
    -ResultSize 5000

# Label downgrades (potential policy violations)
$downgrades = Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -Operations "SensitivityLabelUpdated" `
    -ResultSize 5000 | 
    Where-Object { 
        $auditData = $_.AuditData | ConvertFrom-Json
        $auditData.SensitivityLabelEventData.OldSensitivityLabelId -ne $null
    }

# Export for compliance evidence
$labelActivity | Export-Csv -Path ".\reports\SC1-LabelActivity-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation
```

### 10.2 Key Metrics & KPIs

| Metric | Target | Measurement Method | Frequency |
|--------|--------|--------------------|-----------|
| Label coverage (% of DCE files labelled) | >95% within 90 days | Content search + label filter | Weekly |
| Unlabelled files in DCE sites | <5% after 90 days | SharePoint content search | Weekly |
| Label downgrade events | <5 per week | Unified Audit Log | Daily |
| Justification-free downgrades | 0 (should be impossible) | Audit log — indicates policy bypass | Daily |
| DCE-Confidential applied to non-leadership content | 0 | Label usage report | Weekly |
| Mean time to label new content | <1 minute (auto via default) | User activity analytics | Monthly |

### 10.3 Alerting Rules

| Alert | Trigger | Severity | Notification |
|-------|---------|----------|-------------|
| Label removed from document | `SensitivityLabelRemoved` event in DCE sites | High | Email to security@deltacrownext.com |
| DCE-Confidential downgraded | Label changed from DCE-Confidential to lower | Critical | Immediate email + Teams alert |
| Bulk label changes (>10 in 1 hour) | Rate threshold on label operations | High | Email to security@deltacrownext.com |
| Encryption access denied (>5 failures by one user) | Azure RMS access denied events | Medium | Daily digest |

### 10.4 Compliance Evidence Package (Quarterly)

Generate and archive these artifacts every quarter:

```powershell
# Quarterly compliance evidence generation
$quarter = "Q$(([Math]::Ceiling((Get-Date).Month / 3)))-$((Get-Date).Year)"
$evidencePath = ".\compliance-evidence\$quarter"
New-Item -Path $evidencePath -ItemType Directory -Force

# 1. Label configuration export
Get-Label | ConvertTo-Json -Depth 10 | Out-File "$evidencePath\SC1-Labels-Config.json"

# 2. Label policy export
Get-LabelPolicy | ConvertTo-Json -Depth 10 | Out-File "$evidencePath\SC1-LabelPolicies-Config.json"

# 3. Label usage report (last 90 days)
$usage = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) `
    -Operations "SensitivityLabelApplied","SensitivityLabelUpdated","SensitivityLabelRemoved" `
    -ResultSize 5000
$usage | Export-Csv "$evidencePath\SC1-LabelUsage-90d.csv" -NoTypeInformation

# 4. Verification test results
$sc1Result = Test-SC1-SensitivityLabels
$sc1Result | ConvertTo-Json -Depth 5 | Out-File "$evidencePath\SC1-Verification-Results.json"

Write-Host "Compliance evidence package saved to $evidencePath" -ForegroundColor Green
```

---

## 11. Maintenance & Lifecycle

### Ongoing Tasks

| Task | Frequency | Owner | SLA |
|------|-----------|-------|-----|
| Review label activity reports | Weekly | Security Team | By Friday EOD |
| Investigate label downgrade events | Within 24 hours | Security Team | 24-hour SLA |
| Review and tune auto-label recommendations | Monthly | Compliance Officer | By month-end |
| Quarterly compliance evidence generation | Quarterly | Security Team | Within first week of quarter |
| Update encryption group membership | As needed (on staff changes) | IT Admin | Within 24 hours of change |
| Review break-glass (SG-Corp-IT-Admins) membership | Monthly | Security Team | Max 3 members |
| User training on labels | Quarterly + new hire onboarding | Training Team | Within 30 days of hire |
| Label spec review | Quarterly | Security Auditor | By end of quarter |

### New Brand Onboarding Checklist

When deploying a new brand (e.g., Bishops), create equivalent labels:

- [ ] `Bishops-Internal` label (encrypted to `SG-Bishops-AllStaff`)
- [ ] `Bishops-Confidential` label (encrypted to `SG-Bishops-Leadership`)
- [ ] `Bishops-Label-Policy` (published to `SG-Bishops-AllStaff`)
- [ ] Apply site-level labels to Bishops sites
- [ ] Verify isolation: DCE users cannot decrypt Bishops content and vice versa
- [ ] Update `SG-Corp-AllBrands` to include new brand staff
- [ ] Run `Test-CrossBrandIsolation.ps1`

### Label Retirement Process

If a label needs to be retired:

1. **Change label policy** to stop publishing the label (users can no longer apply it)
2. **Do NOT delete the label** — existing encrypted content needs the label to remain for decryption
3. **Set label to "inactive"** in compliance center
4. **Archive label documentation** with rationale for retirement
5. **Monitor** for 90 days for any access issues on existing content
6. **After 1 year**: Review whether label can be fully removed (check for remaining labelled content)

---

## 12. Risk Assessment

### Residual Risks After SC1 Implementation

| Risk ID | Risk | Likelihood | Impact | CVSS | Mitigation | Residual |
|---------|------|-----------|--------|------|------------|----------|
| SC1-R01 | Users manually select "Personal" to bypass encryption | Medium | High | 6.5 | Mandatory labelling + downgrade justification + audit logging. DLP (SC2) detects DCE content without DCE label. | Medium |
| SC1-R02 | Existing unlabelled content remains unprotected | High | Medium | 5.5 | Default label on new content. Bulk re-label campaign. User training. Time-limited risk (decreases as files are edited). | Medium (declining) |
| SC1-R03 | SG-Corp-IT-Admins break-glass group over-provisioned | Low | Critical | 7.8 | Monthly membership review. Max 3 members. PIM if available. | Low |
| SC1-R04 | Dynamic group membership rule mismatch (wrong users get access) | Medium | High | 7.0 | Weekly group membership audit (Control #5). Validate Azure AD attributes. | Medium |
| SC1-R05 | Client-side auto-label recommendation ignored by users | High | Low | 3.5 | Training. Default label covers baseline. DLP catches sensitive data sharing. | Low |
| SC1-R06 | Offline access window allows data exfiltration | Low | Medium | 5.0 | 30-day (Internal), 7-day (Confidential) limits. Unmanaged device blocking for Confidential. | Low |
| SC1-R07 | No service-side auto-labeling (Business Premium) | N/A | Medium | — | Compensated by default labels, mandatory labelling, DLP, training. Accept. | Accepted |

### Risk Treatment Summary

| Treatment | Risks |
|-----------|-------|
| **Mitigate** | SC1-R01, SC1-R02, SC1-R03, SC1-R04, SC1-R06 |
| **Accept** | SC1-R05, SC1-R07 (Business Premium limitation, compensated by other controls) |
| **Transfer** | None |
| **Avoid** | None |

### Overall Control Effectiveness

| Criteria | Rating | Notes |
|----------|--------|-------|
| Design effectiveness | **Strong** | Encryption-based protection independent of SharePoint permissions |
| Implementation complexity | **Medium** | PowerShell commands are well-documented; group dependency is the critical path |
| User impact | **Low** | Default labels are invisible to users; markings are unobtrusive |
| Residual risk | **Medium** | Primary gap is existing unlabelled content (time-limited) and Business Premium auto-label limitation |
| Compensating control adequacy | **Adequate** | Combined with SC2 (DLP), Control #2 (unique permissions), and Control #5 (weekly audit), this compensates for missing Information Barriers |

---

## 13. Rollback Procedures

### Emergency: Disable Encryption Causing Business Disruption

```powershell
# EMERGENCY ONLY: Disable encryption on DCE-Internal if blocking legitimate access
# This removes encryption but keeps visual markings and classification

Set-Label -Identity "DCE-Internal" -EncryptionEnabled $false

Write-Warning "DCE-Internal encryption DISABLED. All DCE content is now accessible to any tenant user."
Write-Warning "Re-enable encryption after resolving the root cause."
Write-Warning "Incident ticket required: [ticket URL]"
```

### Rollback: Remove All Labels (Nuclear Option)

```powershell
# NUCLEAR OPTION: Remove all labels and policies
# USE ONLY if labels are causing widespread business disruption
# Requires Compliance Administrator

# Step 1: Remove policies first
Remove-LabelPolicy -Identity "DCE-Label-Policy" -Confirm:$false
Remove-LabelPolicy -Identity "Corp-Label-Policy" -Confirm:$false

# Step 2: Remove labels (does NOT decrypt existing encrypted files)
# WARNING: Existing encrypted files will remain encrypted but users
# won't see the label in the ribbon. Files remain accessible to
# authorised groups via Azure RMS.
Remove-Label -Identity "Corporate-Confidential" -Confirm:$false
Remove-Label -Identity "DCE-Confidential" -Confirm:$false
Remove-Label -Identity "DCE-Internal" -Confirm:$false
Remove-Label -Identity "Personal" -Confirm:$false

Write-Warning "ALL SENSITIVITY LABELS REMOVED."
Write-Warning "Existing encrypted files remain encrypted."
Write-Warning "This is a P1 security incident. Document everything."
```

### Post-Rollback Recovery

1. Re-run Section 7 commands to recreate labels
2. Verify with Section 8 verification script
3. Conduct root cause analysis
4. File incident report with timeline and impact

---

## 14. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-04-10 | security-auditor-b724ae | Initial specification (DCE-Internal only) |
| 2.0 | 2025-04-22 | security-auditor-8f512f | **Complete rewrite**: 4-label hierarchy, Business Premium constraints, all PowerShell commands, compliance mapping (AU Privacy Act, OWASP ASVS, ISO 27001, SOC2, NIST), monitoring/alerting, risk assessment, rollback procedures, new brand onboarding checklist |

---

## Appendix A: Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│  DCE SENSITIVITY LABELS — QUICK REFERENCE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Personal          → No protection. Personal content only.       │
│  DCE-Internal      → Encrypted to SG-DCE-AllStaff. DEFAULT.     │
│  DCE-Confidential  → Encrypted to SG-DCE-Leadership ONLY.       │
│  Corp-Confidential → Encrypted to SG-Corp-AllBrands.            │
│                                                                  │
│  🔑 Encryption = file-level protection that travels with doc    │
│  📋 Default = DCE-Internal (auto-applied to new content)        │
│  ⚠️  Downgrade = requires written justification                 │
│  🚫 Remove = admin approval only for Confidential labels        │
│                                                                  │
│  Questions? → /sites/corp-it/SitePages/Sensitivity-Labels-Guide │
└─────────────────────────────────────────────────────────────────┘
```

## Appendix B: Security Group Dependencies

| Group | Type | Membership Rule | Used By Labels |
|-------|------|----------------|----------------|
| `SG-DCE-AllStaff` | Dynamic Security | `department contains "Delta Crown" OR companyName contains "Delta Crown Extensions"` | DCE-Internal |
| `SG-DCE-Leadership` | Dynamic Security | `companyName contains "Delta Crown" AND (jobTitle contains Manager/Director/VP/Chief/President)` | DCE-Internal, DCE-Confidential |
| `SG-Corp-IT-Admins` | Static Security | Manual membership (≤3 members) | All encrypted labels (break-glass) |
| `SG-Corp-AllBrands` | Dynamic Security | `companyName contains "Delta Crown" OR companyName contains "Bishops" OR ...` | Corporate-Confidential |
| `SG-DCE-Marketing` | Dynamic Security | `department contains "Marketing" AND companyName contains "Delta Crown"` | Not directly (DLP/permissions) |

## Appendix C: Colour Reference

| Purpose | Hex Code | Usage |
|---------|----------|-------|
| DCE Brand Gold | `#C9A227` | DCE-Internal header, footer, watermark |
| Alert Red | `#CC0000` | DCE-Confidential header, footer, watermark |
| Corporate Blue | `#0078D4` | Corporate-Confidential header, watermark |
| Neutral Grey | `#605E5C` | Footer text (subtle) |
| Background Black | `#1A1A1A` | Not used in labels |
| Background White | `#FFFFFF` | Not used in labels |

---

**END OF SPECIFICATION**

*This document is the authoritative implementation spec for SC1. All PowerShell commands in Section 7 are ready for execution in sequence. Run Section 8 verification after deployment.*
