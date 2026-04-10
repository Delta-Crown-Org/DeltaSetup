# DCE Sensitivity Labels Specification
## Compensating Control #3: Sensitivity Labels (DCE-Internal)

---

## Overview

**Control Purpose**: Provide content classification and encryption-based protection for Delta Crown Extensions data, compensating for the lack of Information Barriers in Business Premium.

**Standard**: Microsoft Purview Sensitivity Labels (Business Premium supported)

---

## Label Configuration

### Primary Label: DCE-Internal

| Property | Value |
|----------|-------|
| **Name** | DCE-Internal |
| **Display Name** | Delta Crown - Internal |
| **Description for users** | "Content exclusive to Delta Crown Extensions staff. Do not share with other brands or external parties." |
| **Description for admins** | "Auto-applied to all DCE site collections. Encrypts content and restricts access to SG-DCE-AllStaff." |
| **Tooltip** | "Delta Crown confidential - internal use only" |

### Label Settings

#### Encryption Configuration

| Setting | Value |
|---------|-------|
| **Encryption** | Enabled |
| **Assign permissions now** | Yes |
| **User access** | Co-author |
| **Allow offline access** | 30 days |
| **Double Key Encryption** | No (requires E5) |

#### Permission Assignment

```powershell
# Specific users/groups with permissions
$permissions = @(
    "SG-DCE-AllStaff",           # All DCE employees - Co-author
    "SG-DCE-Leadership",         # Leadership - Co-author
    "SG-Corp-IT-Admins"          # IT admins - Co-author (emergency access)
)

# Domain restrictions
$allowedDomains = @(
    "deltacrownext.onmicrosoft.com"
)
```

#### Content Marking

| Marking Type | Configuration |
|--------------|---------------|
| **Header** | Enabled |
| **Header text** | "Delta Crown Extensions — INTERNAL USE ONLY" |
| **Header font** | Calibri, 10pt |
| **Header color** | #C9A227 (Gold) |
| **Header alignment** | Center |
| **Footer** | Enabled |
| **Footer text** | "Confidential - Do Not Distribute" |
| **Footer font** | Calibri, 8pt |
| **Watermark** | Enabled (for documents) |
| **Watermark text** | "DELTA CROWN INTERNAL" |

---

## Auto-Labeling Rules

### Rule 1: DCE Site Auto-Label

**Purpose**: Automatically apply DCE-Internal label to content in DCE site collections

```powershell
# PowerShell Configuration
$autoLabelRule = @{
    Name = "DCE-Site-AutoLabel"
    Description = "Auto-apply DCE-Internal label to content in DCE sites"
    
    # Conditions (ANY match)
    Conditions = @{
        Operator = "OR"
        Rules = @(
            @{
                Type = "SharePointSite"
                Property = "Url"
                Operator = "Contains"
                Value = "dce-"
            },
            @{
                Type = "SharePointSite"
                Property = "Url"
                Value = "deltacrown"
            },
            @{
                Type = "SharePointSite"
                Property = "DisplayName"
                Operator = "Contains"
                Value = "Delta Crown"
            }
        )
    }
    
    # Action
    Actions = @{
        ApplySensitivityLabel = "DCE-Internal"
    }
}
```

### Rule 2: DCE Document Metadata

```powershell
$metadataRule = @{
    Name = "DCE-Metadata-AutoLabel"
    Description = "Apply label based on document metadata"
    
    Conditions = @{
        Operator = "OR"
        Rules = @(
            @{
                Type = "DocumentProperty"
                Property = "Department"
                Operator = "Equals"
                Value = "Delta Crown"
            },
            @{
                Type = "DocumentProperty"
                Property = "Company"
                Operator = "Equals"
                Value = "Delta Crown Extensions"
            }
        )
    }
}
```

---

## Label Policy Configuration

### Policy: DCE-Data-Classification

```powershell
$labelPolicy = @{
    Name = "DCE-Data-Classification"
    Description = "Publish DCE sensitivity labels to DCE sites"
    
    # Published labels
    Labels = @(
        "DCE-Internal"
        "General"              # Built-in label
        "Public"               # Built-in label
    )
    
    # Scope
    Scope = @{
        Locations = @{
            SharePointSites = @(
                "https://deltacrownext.sharepoint.com/sites/dce-*",
                "https://deltacrownext.sharepoint.com/sites/dce-*/*"
            )
            Teams = @(
                "Delta Crown Operations",
                "DCE-*"
            )
        }
    }
    
    # Policy settings
    Settings = @{
        RequireJustificationForRemoval = $true
        RequireUsersToApplyLabel = $false    # Auto-apply, but allow change
        MandatoryLabeling = $false           # Can save without label (will auto-apply)
        DefaultLabel = "DCE-Internal"        # For DCE sites
    }
}
```

---

## Implementation Script

```powershell
#Requires -Module ExchangeOnlineManagement

<#
.SYNOPSIS
    Configures DCE Sensitivity Labels and Auto-Labeling Policies
.DESCRIPTION
    Implements Compensating Control #3: Sensitivity Labels
    Creates DCE-Internal label with encryption and auto-apply rules
.NOTES
    Requires Compliance Admin or Security Admin role
    Business Premium supports basic sensitivity labels
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AdminUPN,  # Admin email
    
    [Parameter(Mandatory=$false)]
    [string]$LabelName = "DCE-Internal",
    
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrownext",
    
    [switch]$WhatIf
)

# Connect to Security & Compliance Center
Write-Host "Connecting to Security & Compliance Center..." -ForegroundColor Cyan
Connect-IPPSSession -UserPrincipalName $AdminUPN

# Create the sensitivity label
$labelParams = @{
    Name = $LabelName
    DisplayName = "Delta Crown - Internal"
    Description = "Content exclusive to Delta Crown Extensions staff"
    Tooltip = "Delta Crown confidential - internal use only"
    EncryptionEnabled = $true
    EncryptionProtectionType = "UserDefined"
    EncryptionAssignUsers = @(
        "SG-DCE-AllStaff",
        "SG-DCE-Leadership",
        "SG-Corp-IT-Admins"
    )
    EncryptionOfflineAccessDays = 30
    HeaderEnabled = $true
    HeaderText = "Delta Crown Extensions — INTERNAL USE ONLY"
    HeaderFontSize = 10
    HeaderFontColor = "#C9A227"
    HeaderAlignment = "Center"
    FooterEnabled = $true
    FooterText = "Confidential - Do Not Distribute"
    FooterFontSize = 8
    ApplyContentMarkingHeader = $true
}

try {
    if (-not $WhatIf) {
        $label = New-Label @labelParams
        Write-Host "Created sensitivity label: $($label.Name)" -ForegroundColor Green
    } else {
        Write-Host "WHATIF: Would create label '$LabelName'" -ForegroundColor Magenta
        Write-Host "  - Encryption: Enabled (UserDefined)" -ForegroundColor Magenta
        Write-Host "  - Offline access: 30 days" -ForegroundColor Magenta
        Write-Host "  - Header: Delta Crown Extensions — INTERNAL USE ONLY" -ForegroundColor Magenta
    }
}
catch {
    Write-Error "Failed to create label: $_"
    return
}

# Create auto-label policy for DCE sites
$autoLabelPolicy = @{
    Name = "DCE-AutoLabel-Policy"
    Description = "Auto-apply DCE-Internal to DCE site content"
    Label = $LabelName
    Mode = "TestWithNotifications"  # Test mode for 90 days
    Rules = @{
        RuleName = "DCE-Site-Rule"
        Conditions = @{
            ContentContainsSensitiveInformation = @{
                Operator = "And"
                Groups = @(
                    @{
                        Operator = "Or"
                        Name = "DCE Sites"
                        Conditions = @(
                            @{
                                ContentField = "SiteUrl"
                                Operator = "Contains"
                                Value = "dce-"
                            }
                        )
                    }
                )
            }
        }
    }
    SharePointLocation = @(
        "https://$TenantName.sharepoint.com/sites/dce-hub",
        "https://$TenantName.sharepoint.com/sites/dce-*"
    )
    TeamsLocation = @(
        "Delta Crown Operations"
    )
}

try {
    if (-not $WhatIf) {
        $policy = New-AutoSensitivityLabelPolicy @autoLabelPolicy
        Write-Host "Created auto-label policy: $($policy.Name)" -ForegroundColor Green
        Write-Host "  Mode: TestWithNotifications (90-day evaluation)" -ForegroundColor Yellow
    } else {
        Write-Host "WHATIF: Would create auto-label policy 'DCE-AutoLabel-Policy'" -ForegroundColor Magenta
        Write-Host "  - Scope: DCE sites and Teams" -ForegroundColor Magenta
        Write-Host "  - Mode: TestWithNotifications" -ForegroundColor Magenta
    }
}
catch {
    Write-Error "Failed to create auto-label policy: $_"
}

# Create label policy (publish to users)
$publishPolicy = @{
    Name = "DCE-Label-Publishing"
    Description = "Publish DCE labels to DCE sites"
    Labels = @($LabelName)
    SharePointLocation = @(
        "https://$TenantName.sharepoint.com/sites/dce-*"
    )
    TeamsLocation = @(
        "Delta Crown Operations"
    )
    Settings = @{
        DefaultLabel = $LabelName
        RequireJustification = $true
    }
}

try {
    if (-not $WhatIf) {
        $published = New-LabelPolicy @publishPolicy
        Write-Host "Published label policy: $($published.Name)" -ForegroundColor Green
    } else {
        Write-Host "WHATIF: Would publish labels to DCE locations" -ForegroundColor Magenta
    }
}
catch {
    Write-Error "Failed to publish label policy: $_"
}

Write-Host "`n=== Sensitivity Labels Configuration Complete ===" -ForegroundColor Green
Write-Host "Review auto-label policy results after 90 days, then switch to Enforce mode" -ForegroundColor Yellow

Disconnect-ExchangeOnline
```

---

## Verification Steps

```powershell
# Verify label was created
Get-Label | Where-Object { $_.Name -eq "DCE-Internal" }

# Verify auto-label policy
Get-AutoSensitivityLabelPolicy | Where-Object { $_.Name -eq "DCE-AutoLabel-Policy" }

# Check label application on a document
Get-Label -Identity "<DocumentId>"
```

---

## Compliance Notes

| Requirement | Implementation |
|-------------|----------------|
| **OWASP ASVS 7.1** | Content classification implemented |
| **OWASP ASVS 7.2** | Encryption at rest via sensitivity labels |
| **SOC 2 CC6.1** | Logical access controls via encryption |
| **ISO 27001 A.8.2.1** | Classification labels applied |

---

## Maintenance Tasks

| Task | Frequency | Owner |
|------|-----------|-------|
| Review auto-label matches | Weekly | Security Team |
| Audit label policy scope | Monthly | Compliance Officer |
| Update encryption permissions | Quarterly | IT Security |
| Train users on labels | Quarterly | Training Team |

