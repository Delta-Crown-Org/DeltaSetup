# ============================================================================
# 4.1-User-Property-Audit.ps1
# Audit existing Azure AD user properties on deltacrown tenant
# ============================================================================
# PURPOSE: Before onboarding users into the hub-and-spoke architecture,
#          we need to know what their current Azure AD properties look like.
#          This script audits every user and generates a report showing:
#          - Current companyName, department, jobTitle
#          - Which dynamic security groups they WOULD match
#          - Gaps that need to be filled before deployment
# ============================================================================
# USAGE:
#   ./4.1-User-Property-Audit.ps1 -TenantName "deltacrown"
#   ./4.1-User-Property-Audit.ps1 -TenantName "deltacrown" -ExportCsv
#   ./4.1-User-Property-Audit.ps1 -TenantName "deltacrown" -FilterBrand "DCE"
# ============================================================================
# DEPENDENCIES: Microsoft.Graph.Users, Microsoft.Graph.Groups
# MODULE DEPS:  DeltaCrown.Auth, DeltaCrown.Common
# ============================================================================

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TenantName = "deltacrown",

    [Parameter()]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter()]
    [switch]$ExportCsv,

    [Parameter()]
    [string]$OutputPath = $null,

    [Parameter()]
    [string]$FilterBrand = $null,

    [Parameter()]
    [switch]$IncludeServiceAccounts,

    [Parameter()]
    [switch]$ShowGroupMembership
)

# ============================================================================
# MODULE IMPORTS
# ============================================================================

$modulesPath = Join-Path $PSScriptRoot "..\..\phase2-week1\modules"
Import-Module (Join-Path $modulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:AuditResults = [System.Collections.ArrayList]::new()
$script:GroupSimulation = @{
    "AllStaff" = {
        param($user)
        $user.CompanyName -eq "Delta Crown Extensions"
    }
    "Managers" = {
        param($user)
        $user.CompanyName -eq "Delta Crown Extensions" -and
        ($user.JobTitle -match "Manager|Director|VP|Vice President|Chief|Head of|Lead")
    }
    "Marketing" = {
        param($user)
        $user.CompanyName -eq "Delta Crown Extensions" -and
        ($user.Department -match "Marketing")
    }
}

# Brand detection patterns (for FilterBrand)
$script:BrandPatterns = @{
    "DCE"  = @("Delta Crown", "DCE")
    "BCC"  = @("Bishops", "BCC")
    "FMN"  = @("Frenchies", "FMN")
    "TLL"  = @("Lash Lounge", "TLL")
    "HTT"  = @("Head to Toe", "HTT")
    "CORP" = @("Corporate", "Corp", "Head to Toe Brands")
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Get-UserBrandAssignment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$User)

    $brand = "Unknown"
    $companyName = $User.CompanyName

    if ([string]::IsNullOrWhiteSpace($companyName)) {
        return "UNASSIGNED"
    }

    foreach ($key in $script:BrandPatterns.Keys) {
        foreach ($pattern in $script:BrandPatterns[$key]) {
            if ($companyName -match [regex]::Escape($pattern)) {
                return $key
            }
        }
    }

    return "OTHER: $companyName"
}

function Test-DynamicGroupMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$User,
        [Parameter(Mandatory)][string]$GroupName
    )

    if ($script:GroupSimulation.ContainsKey($GroupName)) {
        try {
            return (& $script:GroupSimulation[$GroupName] -user $User)
        }
        catch {
            return $false
        }
    }
    return $false
}

function Format-AuditReport {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Collections.ArrayList]$Results)

    $total = $Results.Count
    $assigned = ($Results | Where-Object { $_.Brand -ne "UNASSIGNED" }).Count
    $unassigned = $total - $assigned
    $dceUsers = ($Results | Where-Object { $_.Brand -eq "DCE" }).Count
    $leadershipMatch = ($Results | Where-Object { $_.MatchesLeadership -eq $true }).Count
    $marketingMatch = ($Results | Where-Object { $_.MatchesMarketing -eq $true }).Count

    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
    Write-DeltaCrownLog "        USER PROPERTY AUDIT REPORT" "STAGE"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "SUMMARY:" "INFO"
    Write-DeltaCrownLog "  Total users audited:       $total" "INFO"
    Write-DeltaCrownLog "  Brand assigned:            $assigned" $(if ($assigned -eq $total) { "SUCCESS" } else { "WARNING" })
    Write-DeltaCrownLog "  UNASSIGNED (no company):   $unassigned" $(if ($unassigned -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "DCE DYNAMIC GROUP SIMULATION:" "INFO"
    Write-DeltaCrownLog "  Would join AllStaff:   $dceUsers" "INFO"
    Write-DeltaCrownLog "  Would join Managers: $leadershipMatch" "INFO"
    Write-DeltaCrownLog "  Would join Marketing:  $marketingMatch" "INFO"
    Write-DeltaCrownLog "" "INFO"

    # Brand breakdown
    Write-DeltaCrownLog "BRAND BREAKDOWN:" "INFO"
    $brandGroups = $Results | Group-Object Brand | Sort-Object Count -Descending
    foreach ($group in $brandGroups) {
        $icon = if ($group.Name -eq "UNASSIGNED") { "⚠️" } elseif ($group.Name -eq "DCE") { "⭐" } else { "📦" }
        Write-DeltaCrownLog "  $icon $($group.Name): $($group.Count) users" "INFO"
    }

    # Users needing attention
    $needsAttention = $Results | Where-Object {
        $_.Brand -eq "UNASSIGNED" -or
        [string]::IsNullOrWhiteSpace($_.Department) -or
        [string]::IsNullOrWhiteSpace($_.JobTitle)
    }

    if ($needsAttention.Count -gt 0) {
        Write-DeltaCrownLog "" "INFO"
        Write-DeltaCrownLog "USERS NEEDING PROPERTY UPDATES ($($needsAttention.Count)):" "WARNING"
        foreach ($user in $needsAttention) {
            $issues = @()
            if ($user.Brand -eq "UNASSIGNED") { $issues += "no companyName" }
            if ([string]::IsNullOrWhiteSpace($user.Department)) { $issues += "no department" }
            if ([string]::IsNullOrWhiteSpace($user.JobTitle)) { $issues += "no jobTitle" }
            Write-DeltaCrownLog "  ⚠️  $($user.DisplayName) ($($user.UPN)) — $($issues -join ', ')" "WARNING"
        }
    }

    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-DeltaCrownLog "Starting User Property Audit for tenant: $TenantName" "STAGE"
Write-DeltaCrownLog "Environment: $Environment" "INFO"

# Connect to Microsoft Graph
try {
    $authConfig = Import-DeltaCrownAuthConfig -Environment $Environment
    Connect-DeltaCrownGraph -AuthConfig $authConfig -RequiredScopes @(
        "User.Read.All",
        "Group.Read.All",
        "Directory.Read.All"
    )
    Write-DeltaCrownLog "Connected to Microsoft Graph" "SUCCESS"
}
catch {
    Write-DeltaCrownLog "Failed to connect to Microsoft Graph: $_" "CRITICAL" -Exception $_.Exception
    exit 2
}

# Get all users
try {
    Write-DeltaCrownLog "Fetching all users from Azure AD..." "INFO"

    $selectProperties = @(
        "Id",
        "UserPrincipalName",
        "DisplayName",
        "CompanyName",
        "Department",
        "JobTitle",
        "AccountEnabled",
        "UserType",
        "UsageLocation",
        "CreatedDateTime",
        "LastSignInDateTime"
    )

    $allUsers = Get-MgUser -All -Property ($selectProperties -join ",") `
        -Filter "UserType eq 'Member'" `
        -ConsistencyLevel eventual `
        -CountVariable userCount

    Write-DeltaCrownLog "Found $($allUsers.Count) member users" "SUCCESS"

    # Filter out service accounts unless requested
    if (-not $IncludeServiceAccounts) {
        $allUsers = $allUsers | Where-Object {
            $_.UserPrincipalName -notmatch "^(admin|service|sync|noreply|mailbox)" -and
            $_.DisplayName -notmatch "^(System|Service|Sync|Automation)"
        }
        Write-DeltaCrownLog "After filtering service accounts: $($allUsers.Count) users" "INFO"
    }

    # Filter by brand if specified
    if ($FilterBrand -and $script:BrandPatterns.ContainsKey($FilterBrand)) {
        $patterns = $script:BrandPatterns[$FilterBrand]
        $allUsers = $allUsers | Where-Object {
            $cn = $_.CompanyName
            $match = $false
            foreach ($p in $patterns) {
                if ($cn -match [regex]::Escape($p)) { $match = $true; break }
            }
            $match
        }
        Write-DeltaCrownLog "Filtered to $FilterBrand brand: $($allUsers.Count) users" "INFO"
    }
}
catch {
    Write-DeltaCrownLog "Failed to fetch users: $_" "CRITICAL" -Exception $_.Exception
    exit 2
}

# Audit each user
Write-DeltaCrownLog "Auditing user properties..." "INFO"

foreach ($user in $allUsers) {
    $brand = Get-UserBrandAssignment -User $user
    $matchesAllStaff = Test-DynamicGroupMatch -User $user -GroupName "AllStaff"
    $matchesLeadership = Test-DynamicGroupMatch -User $user -GroupName "Managers"
    $matchesMarketing = Test-DynamicGroupMatch -User $user -GroupName "Marketing"

    $auditEntry = [PSCustomObject]@{
        UPN              = $user.UserPrincipalName
        DisplayName      = $user.DisplayName
        CompanyName      = $user.CompanyName
        Department       = $user.Department
        JobTitle         = $user.JobTitle
        Brand            = $brand
        AccountEnabled   = $user.AccountEnabled
        UsageLocation    = $user.UsageLocation
        CreatedDate      = $user.CreatedDateTime
        MatchesAllStaff  = $matchesAllStaff
        MatchesLeadership = $matchesLeadership
        MatchesMarketing = $matchesMarketing
        MissingFields    = @(
            $(if ([string]::IsNullOrWhiteSpace($user.CompanyName)) { "companyName" })
            $(if ([string]::IsNullOrWhiteSpace($user.Department)) { "department" })
            $(if ([string]::IsNullOrWhiteSpace($user.JobTitle)) { "jobTitle" })
            $(if ([string]::IsNullOrWhiteSpace($user.UsageLocation)) { "usageLocation" })
        ) | Where-Object { $_ } | Join-String -Separator ", "
    }

    [void]$script:AuditResults.Add($auditEntry)
}

# Get actual group membership if requested
if ($ShowGroupMembership) {
    Write-DeltaCrownLog "Fetching actual dynamic group memberships..." "INFO"

    $targetGroups = @("AllStaff", "Managers", "Marketing")

    foreach ($groupName in $targetGroups) {
        try {
            $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
            if ($group) {
                $members = Get-MgGroupMember -GroupId $group.Id -All
                $memberUpns = $members | ForEach-Object {
                    (Get-MgUser -UserId $_.Id -Property "UserPrincipalName").UserPrincipalName
                }

                foreach ($entry in $script:AuditResults) {
                    $propName = "Actual_$groupName"
                    $entry | Add-Member -NotePropertyName $propName -NotePropertyValue ($entry.UPN -in $memberUpns) -Force
                }

                Write-DeltaCrownLog "  $groupName`: $($members.Count) actual members" "INFO"
            }
            else {
                Write-DeltaCrownLog "  $groupName`: Group not found (not yet created)" "WARNING"
            }
        }
        catch {
            Write-DeltaCrownLog "  $groupName`: Error fetching members — $_" "WARNING"
        }
    }
}

# Output report
Format-AuditReport -Results $script:AuditResults

# Export to CSV if requested
if ($ExportCsv) {
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputPath = Join-Path $PSScriptRoot "..\logs\user-audit-$timestamp.csv"
    }

    $outputDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    $script:AuditResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-DeltaCrownLog "Audit exported to: $OutputPath" "SUCCESS"

    # Also export a "needs attention" CSV for easy editing
    $attentionPath = $OutputPath -replace '\.csv$', '-needs-attention.csv'
    $needsAttention = $script:AuditResults | Where-Object {
        $_.Brand -eq "UNASSIGNED" -or $_.MissingFields -ne ""
    }
    if ($needsAttention) {
        $needsAttention | Export-Csv -Path $attentionPath -NoTypeInformation -Encoding UTF8
        Write-DeltaCrownLog "Users needing attention exported to: $attentionPath" "WARNING"
    }
}

# Exit code
$unassignedCount = ($script:AuditResults | Where-Object { $_.Brand -eq "UNASSIGNED" }).Count
if ($unassignedCount -gt 0) {
    Write-DeltaCrownLog "⚠️  $unassignedCount users have no brand assignment — review before onboarding" "WARNING"
    exit 1
}
else {
    Write-DeltaCrownLog "✅ All users have brand assignments" "SUCCESS"
    exit 0
}
