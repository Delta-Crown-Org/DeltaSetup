# DCE DLP Policies Specification
## Compensating Control #4: DLP Policies

---

## Overview

**Control Purpose**: Prevent unauthorized sharing of Delta Crown Extensions content across brand boundaries and external parties.

**Standard**: Microsoft Purview DLP Policies (Business Premium supported with limitations)

**Business Premium Limitations**:
- 10 DLP policies per tenant
- Manual policy application only (no automatic sensitive info detection)
- Basic sensitive info types only

---

## Policy Configuration

### Policy: DCE-Data-Protection

| Property | Value |
|----------|-------|
| **Name** | DCE-Data-Protection |
| **Description** | "Prevents DCE content from being shared outside brand boundaries. 90-day test period before enforcement." |
| **Status** | TestWithNotifications (90 days) |
| **Priority** | High |

---

## Policy Rules

### Rule 1: Block Cross-Brand Sharing

**Purpose**: Prevent DCE-Internal labeled content from being shared with other brands

```powershell
$rule1 = @{
    Name = "Block-Cross-Brand-Access"
    Description = "Block DCE content sharing with non-DCE recipients"
    
    Conditions = @{
        Operator = "AND"
        Conditions = @(
            @{
                # Content has DCE-Internal label
                ContentIsShared = $true
                Label = "DCE-Internal"
            },
            @{
                # Recipient is NOT in DCE groups
                Operator = "NOT"
                RecipientGroups = @(
                    "SG-DCE-AllStaff",
                    "SG-DCE-Leadership"
                )
            }
        )
    }
    
    Actions = @{
        BlockAccess = $true
        AllowOverride = $false  # No bypass in enforce mode
        UserNotification = @{
            Enabled = $true
            PolicyTip = "This content is restricted to Delta Crown Extensions staff only. Sharing with other brands or external parties is prohibited."
            EmailNotification = $true
        }
        IncidentReport = @{
            Enabled = $true
            SendTo = @("security@deltacrown.com")
            Severity = "High"
        }
    }
}
```

### Rule 2: Warn on External Sharing

**Purpose**: Warn when any DCE content is shared externally (includes email)

```powershell
$rule2 = @{
    Name = "Warn-External-Sharing"
    Description = "Warn users when sharing DCE content externally"
    
    Conditions = @{
        ContentIsShared = $true
        ExternalAccess = $true
        SiteUrl = @(
            "*dce-*",
            "*deltacrown*"
        )
    }
    
    Actions = @{
        BlockAccess = $false  # Warn only
        AllowOverride = $true
        UserNotification = @{
            Enabled = $true
            PolicyTip = "WARNING: You are sharing Delta Crown Extensions content externally. Please confirm this action is authorized."
            EmailNotification = $true
        }
        IncidentReport = @{
            Enabled = $true
            SendTo = @("security@deltacrown.com")
            Severity = "Medium"
        }
    }
}
```

### Rule 3: Prevent DCE Document Download by External Users

**Purpose**: Block external guest users from downloading DCE content

```powershell
$rule3 = @{
    Name = "Block-External-Download"
    Description = "Prevent external users from downloading DCE documents"
    
    Conditions = @{
        ContentContainsSensitiveInformation = @{
            Label = "DCE-Internal"
        }
        ExternalAccess = $true
        Action = "Download"
    }
    
    Actions = @{
        BlockAccess = $true
        AllowOverride = $false
        UserNotification = @{
            Enabled = $true
            PolicyTip = "Download restricted: External users cannot download Delta Crown Extensions confidential content."
        }
    }
}
```

---

## Locations Configuration

```powershell
$locations = @{
    # SharePoint Sites
    SharePoint = @{
        Enabled = $true
        Sites = @(
            "https://deltacrown.sharepoint.com/sites/dce-hub",
            "https://deltacrown.sharepoint.com/sites/dce-*"
        )
        ExcludeSites = @(
            "https://deltacrown.sharepoint.com/sites/corp-*"
        )
    }
    
    # OneDrive (user personal sites)
    OneDrive = @{
        Enabled = $true
        Accounts = @(
            # All DCE users (dynamic via group membership)
            "SG-DCE-AllStaff"
        )
    }
    
    # Microsoft Teams
    Teams = @{
        Enabled = $true
        Channels = @(
            "Delta Crown Operations",
            "DCE-*"
        )
    }
    
    # Exchange Email
    Exchange = @{
        Enabled = $true
        Recipients = @(
            "*@deltacrown.com.au"
        )
    }
}
```

---

## Test Mode Configuration

### 90-Day Testing Period

```powershell
$testConfig = @{
    Mode = "TestWithNotifications"  # 90-day test period
    StartDate = (Get-Date)
    EndDate = (Get-Date).AddDays(90)
    
    # During test mode
    ActionsInTestMode = @{
        BlockAccess = $false  # Log only, don't block
        SendNotifications = $true
        GenerateAlerts = $true
        TrackMatches = $true
    }
}
```

### Metrics to Track During Test Period

| Metric | Threshold | Action if Exceeded |
|--------|-----------|-------------------|
| Policy matches per day | < 50 | Investigate if higher |
| False positives | < 5% | Tune conditions |
| User override requests | < 10% | Review policy rules |
| Blocked external shares | Track all | Security review each |

---

## Alert Configuration

### Alert: DCE-High-Risk-Sharing

```powershell
$alertConfig = @{
    Name = "DCE-High-Risk-Sharing"
    Description = "Alert on high-risk DCE data sharing events"
    
    Triggers = @{
        # Trigger on any blocked share
        OnPolicyMatch = $true
        SeverityFilter = @("High", "Critical")
    }
    
    Recipients = @{
        Email = @(
            "security@deltacrown.com",
            "compliance@deltacrown.com"
        )
        TeamsWebhook = "https://deltacrown.webhook.office.com/..."  # Optional
    }
    
    Frequency = "Immediate"  # Alert within 15 minutes
    
    IncludeDetails = @{
        UserName = $true
        ContentLocation = $true
        PolicyRule = $true
        RecipientInfo = $true
        Timestamp = $true
    }
}
```

### Alert: DCE-External-Sharing-Attempt

```powershell
$externalAlert = @{
    Name = "DCE-External-Sharing-Attempt"
    Description = "Daily digest of external sharing attempts"
    
    Triggers = @{
        EventType = "ExternalSharingAttempt"
        Threshold = 1  # Alert on any external share
    }
    
    Recipients = @{
        Email = @("security@deltacrown.com")
    }
    
    Frequency = "DailyDigest"  # Once per day summary
}
```

---

## Implementation Script

```powershell
#Requires -Module ExchangeOnlineManagement

<#
.SYNOPSIS
    Configures DCE DLP Policies for brand isolation
.DESCRIPTION
    Implements Compensating Control #4: DLP Policies
    Prevents cross-brand sharing and external data leakage
.NOTES
    Requires Compliance Admin role
    Business Premium: 10 policy limit
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AdminUPN,
    
    [Parameter(Mandatory=$false)]
    [string]$PolicyName = "DCE-Data-Protection",
    
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "deltacrown",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("TestWithNotifications", "TestWithoutNotifications", "Enforce")]
    [string]$Mode = "TestWithNotifications",
    
    [switch]$WhatIf
)

# Connect to Security & Compliance Center
Write-Host "Connecting to Security & Compliance Center..." -ForegroundColor Cyan
Connect-IPPSSession -UserPrincipalName $AdminUPN

# Policy parameters
$policyParams = @{
    Name = $PolicyName
    Comment = "Prevents DCE content from being shared outside brand boundaries. 90-day test period before enforcement."
    Mode = $Mode
    Priority = "High"
}

# Locations
$sharePointParams = @{
    SharePointLocation = @{
        Enabled = $true
        Urls = @(
            "https://$TenantName.sharepoint.com/sites/dce-*"
        )
    }
    ExchangeLocation = @{
        Enabled = $true
    }
    TeamsLocation = @{
        Enabled = $true
    }
}

try {
    if (-not $WhatIf) {
        # Check if policy exists
        $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Warning "Policy '$PolicyName' already exists. Use Remove-DlpCompliancePolicy to recreate."
        } else {
            # Create policy with locations
            $policy = New-DlpCompliancePolicy @policyParams @sharePointParams
            Write-Host "Created DLP Policy: $($policy.Name)" -ForegroundColor Green
            Write-Host "  Mode: $Mode" -ForegroundColor Yellow
            
            # Add rules
            Write-Host "Creating policy rules..." -ForegroundColor Cyan
            
            # Rule 1: Block cross-brand sharing
            $rule1Params = @{
                Name = "Block-Cross-Brand-Access"
                Policy = $PolicyName
                BlockAccess = $true
                BlockAccessScope = "PerUser"
                ContentContainsSensitiveInformation = @{
                    Operator = "And"
                    Groups = @{
                        Operator = "Or"
                        Name = "DCE Content"
                        Labels = @("DCE-Internal")
                    }
                }
                ExceptIfRecipientDomainIs = @{
                    Value = @("deltacrown.onmicrosoft.com")
                }
                GenerateAlert = $true
                AlertRecipients = @("security@deltacrown.com")
                UserNotificationPolicyTipText = "This content is restricted to Delta Crown Extensions staff only. Sharing with other brands or external parties is prohibited."
            }
            
            New-DlpComplianceRule @rule1Params
            Write-Host "  Created rule: Block-Cross-Brand-Access" -ForegroundColor Green
            
            # Rule 2: Warn on external sharing
            $rule2Params = @{
                Name = "Warn-External-Sharing"
                Policy = $PolicyName
                BlockAccess = $false  # Warn only
                ContentSharedFrom = @{
                    Location = "SharePoint"
                    Urls = @("https://$TenantName.sharepoint.com/sites/dce-*")
                }
                ContentIsSharedWith = @{
                    Location = "OutsideOrganization"
                }
                GenerateAlert = $true
                AlertRecipients = @("security@deltacrown.com")
                UserNotificationPolicyTipText = "WARNING: You are sharing Delta Crown Extensions content externally. Please confirm this action is authorized."
            }
            
            New-DlpComplianceRule @rule2Params
            Write-Host "  Created rule: Warn-External-Sharing" -ForegroundColor Green
            
            Write-Host "`nDLP Policy configuration complete!" -ForegroundColor Green
            Write-Host "Mode: $Mode - Review after 90 days before switching to Enforce" -ForegroundColor Yellow
        }
    } else {
        Write-Host "WHATIF: Would create DLP Policy '$PolicyName'" -ForegroundColor Magenta
        Write-Host "  - Mode: $Mode" -ForegroundColor Magenta
        Write-Host "  - Scope: DCE sites, Exchange, Teams" -ForegroundColor Magenta
        Write-Host "  - Rules: Block cross-brand, Warn external" -ForegroundColor Magenta
    }
}
catch {
    Write-Error "Failed to create DLP policy: $_"
    Write-Error "Exception: $($_.Exception.Message)"
}
finally {
    Disconnect-ExchangeOnline
}

<#
.SYNOPSIS
    Switches DLP policy from Test to Enforce mode after validation
#>
function Set-DCE-DLP-Enforce {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PolicyName = "DCE-Data-Protection"
    )
    
    Connect-IPPSSession
    
    Set-DlpCompliancePolicy -Identity $PolicyName -Mode Enforce
    Write-Host "Policy '$PolicyName' switched to Enforce mode" -ForegroundColor Green
    
    Disconnect-ExchangeOnline
}

Export-ModuleMember -Function Set-DCE-DLP-Enforce
```

---

## Monitoring Queries

### PowerShell: Review DLP Matches

```powershell
# Get DLP policy matches for DCE
Get-DlpDetailReport -PolicyName "DCE-Data-Protection" -StartDate (Get-Date).AddDays(-7)

# Get high-severity alerts
Get-ComplianceCase | Get-CaseHoldPolicy | Where-Object { $_.Name -like "*DCE*" }

# Check policy effectiveness
Get-DlpCompliancePolicy -Identity "DCE-Data-Protection" | Select-Object Name, Mode, Rules
```

### Security Dashboard Metrics

| Dashboard Widget | Data Source | Refresh |
|------------------|-------------|---------|
| DLP Matches by Day | DLP reports | Hourly |
| Blocked vs Warned | Policy reports | Hourly |
| Top Violators | User activity | Daily |
| False Positive Rate | Alert feedback | Weekly |

---

## Compliance Mapping

| Framework | Control | Implementation |
|-----------|---------|----------------|
| **OWASP ASVS 7.3** | Data transmission protection | DLP prevents unauthorized sharing |
| **SOC 2 CC6.6** | Data leakage prevention | DLP policies block external sharing |
| **ISO 27001 A.13.2.1** | Information transfer policies | DLP enforces transfer controls |
| **GDPR Article 32** | Security of processing | DLP prevents unauthorized disclosure |

---

## Maintenance Schedule

| Task | Frequency | Owner | Action |
|------|-----------|-------|--------|
| Review policy matches | Weekly | Security | Analyze reports |
| Tune false positives | Monthly | Compliance | Adjust rules |
| Evaluate for Enforce mode | 90 days | Security Admin | Switch from Test |
| Review scope coverage | Quarterly | IT Security | Add new sites |
| User training refresh | Quarterly | Training | Update guidance |

---

## Emergency Procedures

### False Positive Blocking Business

```powershell
# Temporarily disable specific rule
Set-DlpComplianceRule -Identity "Block-Cross-Brand-Access" -Disabled $true

# Or switch policy to Test mode
Set-DlpCompliancePolicy -Identity "DCE-Data-Protection" -Mode TestWithoutNotifications
```

### Report Security Incident

1. Document the incident in Security Log
2. Review DLP match details
3. Check if user bypassed policy
4. Escalate to Security Team Lead
5. Update incident in tracking system

