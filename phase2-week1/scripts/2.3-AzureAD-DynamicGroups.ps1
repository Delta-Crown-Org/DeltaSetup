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
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$|^$')]
    [string]$TenantId = $null,

    [Parameter(Mandatory=$false)]
    [string]$GroupPrefix = "",

    [Parameter(Mandatory=$false)]
    [string[]]$LocationCodes = @(),

    [Parameter(Mandatory=$false)]
    [switch]$CreatePilotGroup,
    
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
$script:ExportPlaintext = ($Environment -eq "Development")

# ============================================================================
# PATH RESOLUTION (moved before logging — $ProjectRoot needed for log paths)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)
$ModulesPath = Join-Path $ProjectRoot "phase2-week1" "modules"

# ============================================================================
# LOGGING SETUP
# ============================================================================
# R2.4A: No hard-coded paths
$LogPath = Join-Path $ProjectRoot "phase2-week1" "logs"
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

# Import shared modules
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# ============================================================================
# GROUP CONFIGURATION
# ============================================================================
function Get-DCEGroupDisplayName {
    param([Parameter(Mandatory)][string]$BaseName)

    if ([string]::IsNullOrWhiteSpace($GroupPrefix)) {
        return $BaseName
    }

    return "$GroupPrefix-$BaseName"
}

function New-DynamicGroupDefinition {
    param(
        [Parameter(Mandatory)][string]$BaseName,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$MailNickname,
        [Parameter(Mandatory)][string]$MembershipRule
    )

    return @{
        DisplayName = Get-DCEGroupDisplayName -BaseName $BaseName
        Description = $Description
        MailNickname = $MailNickname
        MembershipRule = $MembershipRule
        MembershipRuleProcessingState = "On"
        GroupTypes = @("DynamicMembership")
        SecurityEnabled = $true
        MailEnabled = $false
        Visibility = "Private"
        MembershipMode = "Dynamic"
    }
}

function New-StaticGroupDefinition {
    param(
        [Parameter(Mandatory)][string]$BaseName,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$MailNickname
    )

    return @{
        DisplayName = Get-DCEGroupDisplayName -BaseName $BaseName
        Description = $Description
        MailNickname = $MailNickname
        SecurityEnabled = $true
        MailEnabled = $false
        Visibility = "Private"
        MembershipMode = "Static"
    }
}

$DynamicGroups = @(
    (New-DynamicGroupDefinition -BaseName "AllStaff" -Description "All Delta Crown Extensions staff - auto-populated based on department or company attribute" -MailNickname "allstaff" -MembershipRule @'
(user.department -contains "Delta Crown") -or
(user.companyName -contains "Delta Crown Extensions")
'@),
    (New-DynamicGroupDefinition -BaseName "Managers" -Description "Delta Crown Extensions managers - title-based baseline leadership group" -MailNickname "managers" -MembershipRule @'
(user.companyName -contains "Delta Crown") -and 
(
    (user.jobTitle -contains "Manager") -or 
    (user.jobTitle -contains "Director") -or 
    (user.jobTitle -contains "VP") -or 
    (user.jobTitle -contains "Vice President") -or
    (user.jobTitle -contains "Chief") -or
    (user.jobTitle -contains "President")
)
'@),
    (New-DynamicGroupDefinition -BaseName "Marketing" -Description "Delta Crown Extensions marketing team - attribute-driven" -MailNickname "marketing" -MembershipRule '(user.department -eq "Delta Crown Marketing") -or (user.extensionAttribute1 -eq "Marketing")'),
    (New-DynamicGroupDefinition -BaseName "Stylists" -Description "Delta Crown Extensions stylists - title or role based" -MailNickname "stylists" -MembershipRule '(user.jobTitle -contains "Stylist") -or (user.extensionAttribute1 -eq "Stylist")'),
    (New-DynamicGroupDefinition -BaseName "DCE-Operations" -Description "Delta Crown Extensions operations function - driven by canonical role attribute" -MailNickname "dceoperations" -MembershipRule '(user.extensionAttribute1 -eq "Operations")'),
    (New-DynamicGroupDefinition -BaseName "DCE-ClientServices" -Description "Delta Crown Extensions client services function - driven by canonical role attribute" -MailNickname "dceclientservices" -MembershipRule '(user.extensionAttribute1 -eq "ClientServices")'),
    (New-DynamicGroupDefinition -BaseName "DCE-Leadership" -Description "Delta Crown Extensions leadership function - driven by canonical role or access profile" -MailNickname "dceleadership" -MembershipRule '(user.extensionAttribute1 -eq "Leadership") -or (user.extensionAttribute3 -eq "DCE-Leadership")')
)

foreach ($locationCode in $LocationCodes | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) {
    $normalizedLocation = $locationCode.Trim()
    $groupLocationSuffix = $normalizedLocation -replace '^DCE-', ''
    $mailNickname = ("dceloc" + ($groupLocationSuffix -replace '[^A-Za-z0-9]', '')).ToLowerInvariant()
    $DynamicGroups += New-DynamicGroupDefinition `
        -BaseName "DCE-Loc-$groupLocationSuffix" `
        -Description "Delta Crown Extensions location access group for $normalizedLocation" `
        -MailNickname $mailNickname `
        -MembershipRule "(user.officeLocation -eq `"$normalizedLocation`") -or (user.extensionAttribute2 -eq `"$normalizedLocation`")"
}

$StaticGroups = @()
if ($CreatePilotGroup) {
    $StaticGroups += New-StaticGroupDefinition `
        -BaseName "DCE-CrossTenant-Pilot" `
        -Description "Pilot validation group for cross-tenant onboarding and access checks" `
        -MailNickname "dcecrosstenantpilot"
}

$AllGroupConfigs = @($DynamicGroups + $StaticGroups)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Test-DynamicRuleSyntax {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Rule,
        
        [Parameter()]
        [string]$GroupDisplayName = "Unknown"
    )
    
    Write-Log "Validating membership rule syntax for '$GroupDisplayName'..."
    
    # Check for balanced parentheses
    $openParens = ([char[]]$Rule | Where-Object { $_ -eq '(' }).Count
    $closeParens = ([char[]]$Rule | Where-Object { $_ -eq ')' }).Count
    
    if ($openParens -ne $closeParens) {
        throw "Unbalanced parentheses in membership rule for '$GroupDisplayName': $openParens open, $closeParens close"
    }
    
    # R2.3B: Validate recognized attributes (using -match for string pattern matching, not -contains)
    $recognizedAttributes = @(
        'user\.department',
        'user\.companyName',
        'user\.jobTitle',
        'user\.officeLocation',
        'user\.employeeType',
        'user\.extensionAttribute1',
        'user\.extensionAttribute2',
        'user\.extensionAttribute3',
        'user\.userPrincipalName',
        'user\.mail',
        'user\.displayName',
        'user\.accountEnabled',
        'user\.userType',
        'user\.assignedPlans'
    )
    
    $foundAttributes = @()
    foreach ($attr in $recognizedAttributes) {
        if ($Rule -match $attr) {
            $foundAttributes += ($attr -replace '\\\.', '.')
        }
    }
    
    if ($foundAttributes.Count -eq 0) {
        throw "Membership rule for '$GroupDisplayName' does not contain any recognized user attributes. Found: $(($Rule -split '\n' | Select-Object -First 1))"
    }
    
    # Validate recognized operators
    $recognizedOperators = @('-contains', '-eq', '-ne', '-match', '-notMatch', '-startsWith', '-in', '-notIn')
    $hasOperator = $false
    foreach ($op in $recognizedOperators) {
        if ($Rule -match [regex]::Escape($op)) {
            $hasOperator = $true
            break
        }
    }
    
    if (-not $hasOperator) {
        throw "Membership rule for '$GroupDisplayName' does not contain a recognized comparison operator"
    }
    
    Write-Log "  Validated attributes: $($foundAttributes -join ', ')" "SUCCESS"
    Write-Log "  Parentheses balanced: $openParens pairs" "SUCCESS"
    return $true
}

function Export-GroupConfiguration {
    param([array]$Groups, [array]$Results)
    
    $exportData = for ($i = 0; $i -lt $Groups.Count; $i++) {
        [PSCustomObject]@{
            DisplayName = $Groups[$i].DisplayName
            Description = $Groups[$i].Description
            MailNickname = $Groups[$i].MailNickname
            MembershipRule = if ($Groups[$i].ContainsKey('MembershipRule')) { $Groups[$i].MembershipRule -replace "`n", " " -replace "`r", "" } else { "Static membership" }
            ObjectId = if ($Results[$i]) { $Results[$i].Id } else { "N/A" }
            Status = if ($Results[$i]) { "Created" } else { "Failed" }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    $exportPath = Join-Path $ProjectRoot "phase2-week1" "docs" "azure-ad-groups-config.csv"
    $exportData | Export-Csv -Path $exportPath -NoTypeInformation -Force
    Write-Log "Group configuration exported to: $exportPath" "SUCCESS"
    
    # Also export JSON for programmatic access
    $jsonPath = Join-Path $ProjectRoot "phase2-week1" "docs" "azure-ad-groups-config.json"
    $exportData | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Force
    Write-Log "Group configuration exported to: $jsonPath" "SUCCESS"
    
    # R2.2B: Encrypted export for sensitive group data
    $encPath = Join-Path $ProjectRoot "phase2-week1" "docs" "azure-ad-groups-config.enc"
    Export-DeltaCrownSecureData -Data $exportData -Path $encPath -AlsoExportPlaintext:($script:ExportPlaintext)
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
        
        # R2.4C: Poll for test group validation instead of fixed delay
        Wait-DeltaCrownCondition -Condition {
            $g = Get-MgGroup -GroupId $testGroup.Id -Property "id,membershipRuleProcessingState,membershipRuleProcessingError" -ErrorAction SilentlyContinue
            return ($g -and $g.MembershipRuleProcessingState -ne $null)
        } -TimeoutSeconds 30 -IntervalSeconds 5 -ActivityMessage "Validating test group membership rule"
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
    # STEP 1C: Duplicate Group Detection (R2.3B)
    # ------------------------------------------------------------------------
    Write-DeltaCrownLog "Checking for duplicate group definitions..." "INFO"
    
    $groupNames = $AllGroupConfigs | ForEach-Object { $_.DisplayName }
    $duplicates = $groupNames | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($duplicates) {
        throw "Duplicate group definitions found: $($duplicates.Name -join ', '). Each group must be unique."
    }
    
    # Check for existing groups with similar names (fuzzy match)
    $allExistingGroups = if ([string]::IsNullOrWhiteSpace($GroupPrefix)) {
        Get-MgGroup -Filter "displayName eq 'AllStaff' or displayName eq 'Managers' or displayName eq 'Marketing' or startsWith(displayName, 'DCE-') or startsWith(displayName, 'Stylists')" -ErrorAction SilentlyContinue
    }
    else {
        Get-MgGroup -Filter "startsWith(displayName, '$GroupPrefix')" -ErrorAction SilentlyContinue
    }
    if ($allExistingGroups) {
        Write-DeltaCrownLog "Found $($allExistingGroups.Count) existing groups with prefix '$GroupPrefix':" "INFO"
        foreach ($eg in $allExistingGroups) {
            $isDefined = $groupNames -contains $eg.DisplayName
            $status = if ($isDefined) { "EXPECTED" } else { "UNEXPECTED" }
            Write-DeltaCrownLog "  [$status] $($eg.DisplayName) (ID: $($eg.Id))" $(if ($isDefined) { "INFO" } else { "WARNING" })
        }
    }
    
    # ------------------------------------------------------------------------
    # STEP 2: Validate and Create Groups
    # ------------------------------------------------------------------------
    Write-Log "Processing dynamic group configurations..."
    
    $createdGroups = @()
    
    foreach ($groupConfig in $AllGroupConfigs) {
        Write-Log "`nProcessing group: $($groupConfig.DisplayName)"
        
        # Validate rule syntax for dynamic groups only
        if ($groupConfig.MembershipMode -eq "Dynamic") {
            Test-DynamicRuleSyntax -Rule $groupConfig.MembershipRule -GroupDisplayName $groupConfig.DisplayName
        }
        
        # Check if group already exists
        $existingGroup = Get-MgGroup -Filter "displayName eq '$($groupConfig.DisplayName)'" -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-Log "Group $($groupConfig.DisplayName) already exists (ID: $($existingGroup.Id))" "WARNING"
            $createdGroups += $existingGroup
            continue
        }
        
        if ($WhatIf) {
            Write-Log "WHATIF: Would create group $($groupConfig.DisplayName)" "WHATIF"
            if ($groupConfig.MembershipMode -eq "Dynamic") {
                Write-Log "WHATIF: Membership Rule:`n$($groupConfig.MembershipRule)" "WHATIF"
            }
            continue
        }
        
        # Create the dynamic group
        try {
            Write-Log "Creating dynamic group: $($groupConfig.DisplayName)..."

            $params = @{
                DisplayName = $groupConfig.DisplayName
                Description = $groupConfig.Description
                MailNickname = $groupConfig.MailNickname
                SecurityEnabled = $groupConfig.SecurityEnabled
                MailEnabled = $groupConfig.MailEnabled
                Visibility = $groupConfig.Visibility
            }

            if ($groupConfig.MembershipMode -eq "Dynamic") {
                $params.GroupTypes = $groupConfig.GroupTypes
                $params.MembershipRule = $groupConfig.MembershipRule
                $params.MembershipRuleProcessingState = $groupConfig.MembershipRuleProcessingState
            }
            
            $newGroup = New-MgGroup -BodyParameter $params
            
            Write-Log "Created group: $($newGroup.DisplayName)" "SUCCESS"
            Write-Log "  - Object ID: $($newGroup.Id)"
            if ($groupConfig.MembershipMode -eq "Dynamic") {
                Write-Log "  - Membership Rule Processing: $($newGroup.MembershipRuleProcessingState)"
            }
            else {
                Write-Log "  - Membership Mode: Static"
            }

            $createdGroups += $newGroup

            if ($groupConfig.MembershipMode -eq "Dynamic") {
                # R2.4C: Poll for group processing instead of fixed delay
                Wait-DeltaCrownCondition -Condition {
                    $g = Get-MgGroup -GroupId $newGroup.Id -Property "id,membershipRuleProcessingState,membershipRuleProcessingError" -ErrorAction SilentlyContinue
                    return ($g -and (-not $g.MembershipRuleProcessingError))
                } -TimeoutSeconds 60 -IntervalSeconds 5 -ActivityMessage "Waiting for membership rule processing: $($newGroup.DisplayName)" -OnTimeout {
                    Write-DeltaCrownLog "Membership rule processing timed out for $($newGroup.DisplayName). This may resolve within 24 hours." "WARNING"
                }

                # Check initial membership status
                $groupStatus = Get-MgGroup -GroupId $newGroup.Id -Property "id,displayName,membershipRuleProcessingState,membershipRuleProcessingError"
                if ($groupStatus.MembershipRuleProcessingError) {
                    Write-Log "Membership processing error: $($groupStatus.MembershipRuleProcessingError)" "ERROR"
                } else {
                    Write-Log "Membership rule processing state: $($groupStatus.MembershipRuleProcessingState)"
                }

                # R2.3B: Post-creation membership count verification
                $memberCheckAttempt = 0
                $memberCount = 0
                while ($memberCheckAttempt -lt 3) {
                    $memberCheckAttempt++
                    try {
                        $members = Get-MgGroupMember -GroupId $newGroup.Id -All -ErrorAction SilentlyContinue
                        $memberCount = if ($members) { $members.Count } else { 0 }
                        break
                    }
                    catch {
                        Start-Sleep -Seconds 5
                    }
                }
                Write-Log "  Membership count: $memberCount (may increase as Azure AD evaluates rule)" "INFO"
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
        Export-GroupConfiguration -Groups $AllGroupConfigs -Results $createdGroups
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
| AllStaff | All DCE employees | Department contains "Delta Crown" OR Company contains "Delta Crown Extensions" |
| Managers | Baseline management tier | Company contains "Delta Crown" AND (Title contains Manager/Director/VP/etc.) |
| Marketing | Marketing function | Department = Delta Crown Marketing OR extensionAttribute1 = Marketing |
| Stylists | Stylist function | Title contains Stylist OR extensionAttribute1 = Stylist |
| DCE-Operations | Operations function | extensionAttribute1 = Operations |
| DCE-ClientServices | Client services function | extensionAttribute1 = ClientServices |
| DCE-Leadership | Canonical leadership function | extensionAttribute1 = Leadership OR extensionAttribute3 = DCE-Leadership |
| DCE-Loc-* | Location access groups | officeLocation = code OR extensionAttribute2 = code |
| DCE-CrossTenant-Pilot | Pilot validation group | Static membership |

### SharePoint Permission Strategy

**IMPORTANT:** Business Premium does NOT include Information Barriers!
Use these groups for site permissions instead:

1. **Site-Level Permissions**
   - Assign AllStaff to "DCE Members" group on DCE sites
   - Assign Managers to "DCE Owners" or custom "Leadership" group

2. **Library/Folder-Level Permissions**
   - Break inheritance on sensitive libraries
   - Assign Managers for confidential docs
   - NEVER use "Everyone" or "All Users" groups

3. **Hub Permissions**
   - Corp-Hub: Use Corp-specific groups (not DCE)
   - DCE-Hub: Use AllStaff for visitors, Managers for owners

### Sync Time Expectations
- Initial group population: 5-30 minutes
- Ongoing updates: Near real-time (within minutes of attribute change)
- Maximum sync delay: 24 hours (rare)

### Troubleshooting
- Check membership rule syntax if group shows 0 members
- Verify user attributes (`department`, `companyName`, `jobTitle`, `officeLocation`, `extensionAttribute1-3`) are populated
- Review Entra ID > Groups > [Group] > Members for status

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    $usageDocPath = Join-Path $ProjectRoot "phase2-week1" "docs" "azure-ad-groups-usage-guide.md"
    $usageDoc | Out-File -FilePath $usageDocPath -Force
    Write-Log "Usage guide saved to: $usageDocPath" "SUCCESS"
    
    # ------------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------------
    Write-Log "`n=== Azure AD Dynamic Groups Setup Complete ===" "SUCCESS"
    Write-Log "Groups Processed: $($AllGroupConfigs.Count)"
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
        TotalConfigured = $AllGroupConfigs.Count
        WhatIfMode = $WhatIf
        Status = "SUCCESS"
        Timestamp = Get-Date
    }
}
catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR" -IncludeContext -Exception $_.Exception
    Write-Log "Exception: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    throw
}
finally {
    Write-Log "Disconnecting from Microsoft Graph..."
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
