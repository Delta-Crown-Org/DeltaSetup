# ============================================================================
# PHASE 2.3: Azure AD Dynamic Groups Setup (REMEDIATED)
# Delta Crown Extensions - SharePoint Hub & Spoke Architecture
# ============================================================================
# VERSION: 2.1.0
# DESCRIPTION: Creates dynamic security groups for DCE staff with membership
#              rules based on department and job title attributes.
# REMEDIATION: Module version constraints, test group validation,
#              staging for group activation, enhanced error handling
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Identity.DirectoryManagement";ModuleVersion="2.0.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TenantId = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$GroupPrefix = "SG-DCE",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateTestGroup = $false,  # R2.3B: Test group validation
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBusinessPremiumWarning
)

# Error handling
$ErrorActionPreference = "Stop"

# ============================================================================
# LOGGING SETUP
# ============================================================================
$LogPath = ".\phase2-week1\logs"
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}
$LogFile = Join-Path $LogPath "AzureAD-Groups-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {"INFO"{"Cyan"} "SUCCESS"{"Green"} "WARNING"{"Yellow"} "ERROR"{"Red"} "WHATIF"{"Magenta"} default{"White"}})
    Add-Content -Path $LogFile -Value $logEntry
}

# ============================================================================
# PATH RESOLUTION
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)
$ModulesPath = Join-Path $ProjectRoot "phase2-week1\modules"

# Import shared modules
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# ============================================================================
# DYNAMIC GROUP CONFIGURATION
# ============================================================================
$DynamicGroups = @(
    @{
        DisplayName = "$GroupPrefix-AllStaff"
        Description = "All Delta Crown Extensions staff - auto-populated based on department or company attribute"
        MailNickname = "sg-dce-allstaff"
        MembershipRule = @'
(user.department -contains "Delta Crown") -or 
(user.companyName -contains "Delta Crown Extensions")
'@
        MembershipRuleProcessingState = "On"
        GroupTypes = @("DynamicMembership")
        SecurityEnabled = $true
        MailEnabled = $false
        Visibility = "Private"
    },
    @{
        DisplayName = "$GroupPrefix-Leadership"
        Description = "Delta Crown Extensions leadership team - Managers, Directors, and VPs"
        MailNickname = "sg-dce-leadership"
        MembershipRule = @'
(user.companyName -contains "Delta Crown") -and 
(
    (user.jobTitle -contains "Manager") -or 
    (user.jobTitle -contains "Director") -or 
    (user.jobTitle -contains "VP") -or 
    (user.jobTitle -contains "Vice President") -or
    (user.jobTitle -contains "Chief") -or
    (user.jobTitle -contains "President")
)
'@
        MembershipRuleProcessingState = "On"
        GroupTypes = @("DynamicMembership")
        SecurityEnabled = $true
        MailEnabled = $false
        Visibility = "Private"
    }
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Test-DynamicRuleSyntax {
    param([string]$Rule)
    
    Write-Log "Validating membership rule syntax..."
    
    # Basic validation - Microsoft Graph will do full validation on create
    $requiredAttributes = @('user.department', 'user.companyName', 'user.jobTitle')
    $hasValidAttributes = $requiredAttributes | Where-Object { $Rule -contains $_ }
    
    if (-not $hasValidAttributes) {
        Write-Log "Warning: Rule may not contain standard attributes" "WARNING"
    }
    
    # Check for balanced parentheses
    $openParens = ($Rule -split '\(').Count - 1
    $closeParens = ($Rule -split '\)').Count - 1
    
    if ($openParens -ne $closeParens) {
        throw "Unbalanced parentheses in membership rule"
    }
    
    Write-Log "Basic syntax validation passed" "SUCCESS"
    return $true
}

function Export-GroupConfiguration {
    param([array]$Groups, [array]$Results)
    
    $exportData = for ($i = 0; $i -lt $Groups.Count; $i++) {
        [PSCustomObject]@{
            DisplayName = $Groups[$i].DisplayName
            Description = $Groups[$i].Description
            MailNickname = $Groups[$i].MailNickname
            MembershipRule = $Groups[$i].MembershipRule -replace "`n", " " -replace "`r", ""
            ObjectId = if ($Results[$i]) { $Results[$i].Id } else { "N/A" }
            Status = if ($Results[$i]) { "Created" } else { "Failed" }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    $exportPath = ".\phase2-week1\docs\azure-ad-groups-config.csv"
    $exportData | Export-Csv -Path $exportPath -NoTypeInformation -Force
    Write-Log "Group configuration exported to: $exportPath" "SUCCESS"
    
    # Also export JSON for programmatic access
    $jsonPath = ".\phase2-week1\docs\azure-ad-groups-config.json"
    $exportData | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Force
    Write-Log "Group configuration exported to: $jsonPath" "SUCCESS"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "=== Starting Azure AD Dynamic Groups Setup ==="
    Write-Log "Group Prefix: $GroupPrefix"
    Write-Log "WhatIf Mode: $WhatIf"
    
    # Business Premium Warning
    if (!$SkipBusinessPremiumWarning) {
        Show-DeltaCrownBusinessPremiumWarning -ForceAcknowledgment ($Environment -eq "Production")
    }
    
    # ------------------------------------------------------------------------
    # STEP 1: Connect to Microsoft Graph (R2.1)
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "Connecting to Microsoft Graph..."
    
    $authStatus = Connect-DeltaCrownGraph -Environment $Environment -RequiredScopes @(
        "Group.ReadWrite.All",
        "Directory.ReadWrite.All",
        "User.Read.All"
    )
    
    $context = Get-MgContext
    Write-DeltaCrownLog "Connected to tenant: $($context.TenantId)" "SUCCESS"
    Write-DeltaCrownLog "Authenticated as: $($context.Account)"
    
    # ------------------------------------------------------------------------
    # STEP 1B: Test Group Validation (R2.3B)
    # ------------------------------------------------------------------------
    if ($CreateTestGroup) {
        Write-DeltaCrownLog "Creating test validation group..." "STAGE"
        
        $testGroupName = "$GroupPrefix-TEST-Validation"
        $testRule = '(user.userPrincipalName -eq "test@example.com")'  # Matches no one
        
        $testParams = @{
            DisplayName = $testGroupName
            Description = "TEST GROUP - Will be deleted after validation"
            MailNickname = "sg-dce-test-validation"
            GroupTypes = @("DynamicMembership")
            SecurityEnabled = $true
            MailEnabled = $false
            Visibility = "Private"
            MembershipRule = $testRule
            MembershipRuleProcessingState = "Paused"  # Start in Paused state
        }
        
        $testGroup = New-MgGroup @testParams
        Write-DeltaCrownLog "Test group created with ID: $($testGroup.Id)" "SUCCESS"
        Write-DeltaCrownLog "Group started in 'Paused' state for validation"
        
        # Validate membership rule processing
        Start-Sleep -Seconds 10
        $testGroupStatus = Get-MgGroup -GroupId $testGroup.Id -Property "id,displayName,membershipRuleProcessingState,membershipRuleProcessingError"
        
        if ($testGroupStatus.MembershipRuleProcessingError) {
            Write-DeltaCrownLog "Test group validation FAILED: $($testGroupStatus.MembershipRuleProcessingError)" "ERROR"
            Remove-MgGroup -GroupId $testGroup.Id
            throw "Membership rule validation failed. Check rule syntax and user attributes."
        }
        
        Write-DeltaCrownLog "Test group validation PASSED" "SUCCESS"
        
        # Stage to On (R2.3B: Staging for group activation)
        Update-MgGroup -GroupId $testGroup.Id -MembershipRuleProcessingState "On"
        Write-DeltaCrownLog "Test group activation staged (Paused → On)"
        
        # Clean up test group
        Remove-MgGroup -GroupId $testGroup.Id
        Write-DeltaCrownLog "Test group cleaned up"
    }
    
    # ------------------------------------------------------------------------
    # STEP 2: Validate and Create Groups
    # ------------------------------------------------------------------------
    Write-Log "Processing dynamic group configurations..."
    
    $createdGroups = @()
    
    foreach ($groupConfig in $DynamicGroups) {
        Write-Log "`nProcessing group: $($groupConfig.DisplayName)"
        
        # Validate rule syntax
        Test-DynamicRuleSyntax -Rule $groupConfig.MembershipRule
        
        # Check if group already exists
        $existingGroup = Get-MgGroup -Filter "displayName eq '$($groupConfig.DisplayName)'" -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-Log "Group $($groupConfig.DisplayName) already exists (ID: $($existingGroup.Id))" "WARNING"
            $createdGroups += $existingGroup
            continue
        }
        
        if ($WhatIf) {
            Write-Log "WHATIF: Would create group $($groupConfig.DisplayName)" "WHATIF"
            Write-Log "WHATIF: Membership Rule:`n$($groupConfig.MembershipRule)" "WHATIF"
            continue
        }
        
        # Create the dynamic group
        try {
            Write-Log "Creating dynamic group: $($groupConfig.DisplayName)..."
            
            $params = @{
                DisplayName = $groupConfig.DisplayName
                Description = $groupConfig.Description
                MailNickname = $groupConfig.MailNickname
                GroupTypes = $groupConfig.GroupTypes
                SecurityEnabled = $groupConfig.SecurityEnabled
                MailEnabled = $groupConfig.MailEnabled
                Visibility = $groupConfig.Visibility
                MembershipRule = $groupConfig.MembershipRule
                MembershipRuleProcessingState = $groupConfig.MembershipRuleProcessingState
            }
            
            $newGroup = New-MgGroup -BodyParameter $params
            
            Write-Log "Created group: $($newGroup.DisplayName)" "SUCCESS"
            Write-Log "  - Object ID: $($newGroup.Id)"
            Write-Log "  - Membership Rule Processing: $($newGroup.MembershipRuleProcessingState)"
            
            $createdGroups += $newGroup
            
            # Wait for processing to begin
            Write-Log "Waiting for membership evaluation to begin..."
            Start-Sleep -Seconds 5
            
            # Check initial membership status
            $groupStatus = Get-MgGroup -GroupId $newGroup.Id -Property "id,displayName,membershipRuleProcessingState,membershipRuleProcessingError"
            if ($groupStatus.MembershipRuleProcessingError) {
                Write-Log "Membership processing error: $($groupStatus.MembershipRuleProcessingError)" "ERROR"
            } else {
                Write-Log "Membership rule processing state: $($groupStatus.MembershipRuleProcessingState)"
            }
        }
        catch {
            Write-Log "Error creating group $($groupConfig.DisplayName): $_" "ERROR"
            Write-Log "Exception details: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # ------------------------------------------------------------------------
    # STEP 3: Export Configuration
    # ------------------------------------------------------------------------
    if (!$WhatIf) {
        Export-GroupConfiguration -Groups $DynamicGroups -Results $createdGroups
    }
    
    # ------------------------------------------------------------------------
    # STEP 4: Generate Group Usage Documentation
    # ------------------------------------------------------------------------
    Write-Log "`nGenerating group usage documentation..."
    
    $usageDoc = @"
# Delta Crown Extensions - Azure AD Dynamic Groups
## Usage Guide for SharePoint Permissions

### Groups Created

| Group Name | Purpose | Membership Rule |
|------------|---------|-----------------|
| SG-DCE-AllStaff | All DCE employees | Department contains "Delta Crown" OR Company contains "Delta Crown Extensions" |
| SG-DCE-Leadership | Management tier | Company contains "Delta Crown" AND (Title contains Manager/Director/VP/etc.) |

### SharePoint Permission Strategy

**IMPORTANT:** Business Premium does NOT include Information Barriers!
Use these groups for site permissions instead:

1. **Site-Level Permissions**
   - Assign SG-DCE-AllStaff to "DCE Members" group on DCE sites
   - Assign SG-DCE-Leadership to "DCE Owners" or custom "Leadership" group

2. **Library/Folder-Level Permissions**
   - Break inheritance on sensitive libraries
   - Assign SG-DCE-Leadership for confidential docs
   - NEVER use "Everyone" or "All Users" groups

3. **Hub Permissions**
   - Corp-Hub: Use Corp-specific groups (not DCE)
   - DCE-Hub: Use SG-DCE-AllStaff for visitors, SG-DCE-Leadership for owners

### Sync Time Expectations
- Initial group population: 5-30 minutes
- Ongoing updates: Near real-time (within minutes of attribute change)
- Maximum sync delay: 24 hours (rare)

### Troubleshooting
- Check membership rule syntax if group shows 0 members
- Verify user attributes (department, companyName, jobTitle) are populated
- Review Azure AD > Groups > [Group] > Members for status

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    $usageDocPath = ".\phase2-week1\docs\azure-ad-groups-usage-guide.md"
    $usageDoc | Out-File -FilePath $usageDocPath -Force
    Write-Log "Usage guide saved to: $usageDocPath" "SUCCESS"
    
    # ------------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------------
    Write-Log "`n=== Azure AD Dynamic Groups Setup Complete ===" "SUCCESS"
    Write-Log "Groups Processed: $($DynamicGroups.Count)"
    Write-Log "Groups Created: $($createdGroups.Count)"
    Write-Log "Log saved to: $LogFile"
    
    if (!$WhatIf) {
        Write-Log "`nGroup Summary:"
        foreach ($group in $createdGroups) {
            Write-Log "  - $($group.DisplayName): $($group.Id)"
        }
    }
    
    return [PSCustomObject]@{
        GroupsCreated = $createdGroups
        TotalConfigured = $DynamicGroups.Count
        WhatIfMode = $WhatIf
        Status = "SUCCESS"
        Timestamp = Get-Date
    }
}
catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR"
    Write-Log "Exception: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    throw
}
finally {
    Write-Log "Disconnecting from Microsoft Graph..."
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
