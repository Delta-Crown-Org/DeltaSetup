# ============================================================================
# 4.2-User-Onboarding.ps1
# Bulk-update Azure AD user properties for DCE hub-and-spoke onboarding
# ============================================================================
# PURPOSE: Set companyName, department, and jobTitle on existing tenant users
#          so they auto-join the correct dynamic security groups and get
#          access to the DCE hub-and-spoke sites.
# ============================================================================
# USAGE:
#   # From CSV mapping file:
#   ./4.2-User-Onboarding.ps1 -MappingFile "../config/dce-user-mapping.csv"
#
#   # Single user:
#   ./4.2-User-Onboarding.ps1 -UserPrincipalName "user@deltacrownext.onmicrosoft.com" `
#       -CompanyName "Delta Crown Extensions" -JobTitle "Stylist" -Department "Operations"
#
#   # Dry run (show what would change):
#   ./4.2-User-Onboarding.ps1 -MappingFile "../config/dce-user-mapping.csv" -WhatIf
# ============================================================================
# DEPENDENCIES: Microsoft.Graph.Users, Microsoft.Graph.Groups
# MODULE DEPS:  DeltaCrown.Auth, DeltaCrown.Common
# ============================================================================

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "CsvFile")]
param(
    # CSV mode
    [Parameter(Mandatory, ParameterSetName = "CsvFile")]
    [ValidateScript({ Test-Path $_ })]
    [string]$MappingFile,

    # Single-user mode
    [Parameter(Mandatory, ParameterSetName = "SingleUser")]
    [ValidatePattern('^[^@]+@[^@]+\.[^@]+$')]
    [string]$UserPrincipalName,

    [Parameter(ParameterSetName = "SingleUser")]
    [string]$CompanyName = "Delta Crown Extensions",

    [Parameter(ParameterSetName = "SingleUser")]
    [string]$JobTitle,

    [Parameter(ParameterSetName = "SingleUser")]
    [string]$Department,

    # Common params
    [Parameter()]
    [string]$TenantName = "deltacrownext",

    [Parameter()]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter()]
    [switch]$SkipGroupVerification,

    [Parameter()]
    [int]$GroupEvaluationWaitMinutes = 5,

    [Parameter()]
    [int]$MaxGroupEvaluationWaitMinutes = 20,

    [Parameter()]
    [string]$LogPath = $null
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

$script:UpdateResults = [System.Collections.ArrayList]::new()
$script:TargetGroups = @("SG-DCE-AllStaff", "SG-DCE-Leadership", "SG-DCE-Marketing")

# Properties that trigger dynamic group evaluation
$script:GroupTriggerProperties = @("CompanyName", "JobTitle", "Department")

# ============================================================================
# FUNCTIONS
# ============================================================================

function Import-UserMappings {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $csv = Import-Csv -Path $Path -Encoding UTF8
    $mappings = [System.Collections.ArrayList]::new()

    foreach ($row in $csv) {
        # Skip empty rows
        if ([string]::IsNullOrWhiteSpace($row.UserPrincipalName)) { continue }

        $mapping = @{
            UPN            = $row.UserPrincipalName.Trim()
            DisplayName    = $row.DisplayName
            CompanyName    = if ($row.NewCompanyName) { $row.NewCompanyName.Trim() } else { $null }
            JobTitle       = if ($row.NewJobTitle) { $row.NewJobTitle.Trim() } else { $null }
            Department     = if ($row.NewDepartment) { $row.NewDepartment.Trim() } else { $null }
            Notes          = $row.Notes
        }

        # Only include if there's something to update
        if ($mapping.CompanyName -or $mapping.JobTitle -or $mapping.Department) {
            [void]$mappings.Add($mapping)
        }
        else {
            Write-DeltaCrownLog "Skipping $($mapping.UPN) — no new values to set" "DEBUG"
        }
    }

    return $mappings
}

function Update-SingleUser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$UPN,
        [Parameter()][string]$NewCompanyName,
        [Parameter()][string]$NewJobTitle,
        [Parameter()][string]$NewDepartment
    )

    $result = [PSCustomObject]@{
        UPN           = $UPN
        Status        = "Unknown"
        Changes       = @()
        Errors        = @()
        PreviousValues = @{}
        NewValues     = @{}
    }

    try {
        # Get current user
        $user = Get-MgUser -UserId $UPN -Property "CompanyName,Department,JobTitle,DisplayName" -ErrorAction Stop
        $result | Add-Member -NotePropertyName "DisplayName" -NotePropertyValue $user.DisplayName -Force

        # Build update body
        $updateBody = @{}
        $changes = @()

        if ($NewCompanyName -and $NewCompanyName -ne $user.CompanyName) {
            $updateBody["CompanyName"] = $NewCompanyName
            $changes += "companyName: '$($user.CompanyName)' → '$NewCompanyName'"
            $result.PreviousValues["CompanyName"] = $user.CompanyName
            $result.NewValues["CompanyName"] = $NewCompanyName
        }

        if ($NewJobTitle -and $NewJobTitle -ne $user.JobTitle) {
            $updateBody["JobTitle"] = $NewJobTitle
            $changes += "jobTitle: '$($user.JobTitle)' → '$NewJobTitle'"
            $result.PreviousValues["JobTitle"] = $user.JobTitle
            $result.NewValues["JobTitle"] = $NewJobTitle
        }

        if ($NewDepartment -and $NewDepartment -ne $user.Department) {
            $updateBody["Department"] = $NewDepartment
            $changes += "department: '$($user.Department)' → '$NewDepartment'"
            $result.PreviousValues["Department"] = $user.Department
            $result.NewValues["Department"] = $NewDepartment
        }

        if ($updateBody.Count -eq 0) {
            Write-DeltaCrownLog "  ⏭️  $($user.DisplayName) ($UPN) — no changes needed" "INFO"
            $result.Status = "NoChange"
            $result.Changes = @("Already correct")
            return $result
        }

        $result.Changes = $changes

        # Apply changes
        if ($PSCmdlet.ShouldProcess("$($user.DisplayName) ($UPN)", "Update: $($changes -join '; ')")) {
            Update-MgUser -UserId $UPN -BodyParameter $updateBody -ErrorAction Stop
            Write-DeltaCrownLog "  ✅ $($user.DisplayName) ($UPN)" "SUCCESS"
            foreach ($change in $changes) {
                Write-DeltaCrownLog "      $change" "INFO"
            }
            $result.Status = "Updated"
        }
        else {
            Write-DeltaCrownLog "  🔍 $($user.DisplayName) ($UPN) — WOULD update:" "INFO"
            foreach ($change in $changes) {
                Write-DeltaCrownLog "      $change" "INFO"
            }
            $result.Status = "WhatIf"
        }
    }
    catch {
        Write-DeltaCrownLog "  ❌ $UPN — $($_.Exception.Message)" "ERROR" -Exception $_.Exception
        $result.Status = "Error"
        $result.Errors += $_.Exception.Message
    }

    return $result
}

function Wait-ForGroupEvaluation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$UpdatedUPNs,
        [Parameter()][int]$InitialWaitMinutes = 5,
        [Parameter()][int]$MaxWaitMinutes = 20,
        [Parameter()][int]$PollIntervalSeconds = 30
    )

    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "Waiting for Azure AD dynamic group evaluation..." "STAGE"
    Write-DeltaCrownLog "Azure AD evaluates dynamic groups within 5-15 minutes after property changes" "INFO"
    Write-DeltaCrownLog "Initial wait: $InitialWaitMinutes minutes, then polling every ${PollIntervalSeconds}s..." "INFO"

    # Initial wait
    $waitSeconds = $InitialWaitMinutes * 60
    $elapsed = 0
    while ($elapsed -lt $waitSeconds) {
        $remaining = $waitSeconds - $elapsed
        $remainMin = [math]::Floor($remaining / 60)
        $remainSec = $remaining % 60
        Write-Progress -Activity "Waiting for dynamic group evaluation" `
            -Status "${remainMin}m ${remainSec}s remaining" `
            -PercentComplete (($elapsed / $waitSeconds) * 100)
        Start-Sleep -Seconds 10
        $elapsed += 10
    }
    Write-Progress -Activity "Waiting for dynamic group evaluation" -Completed

    # Poll for group membership
    $maxPollTime = ($MaxWaitMinutes - $InitialWaitMinutes) * 60
    $pollElapsed = 0
    $allVerified = $false

    while ($pollElapsed -lt $maxPollTime -and -not $allVerified) {
        Write-DeltaCrownLog "Checking group membership... (elapsed: $([math]::Round(($InitialWaitMinutes * 60 + $pollElapsed) / 60, 1))m)" "INFO"

        $verified = 0
        $total = $UpdatedUPNs.Count

        foreach ($upn in $UpdatedUPNs) {
            $user = Get-MgUser -UserId $upn -Property "CompanyName" -ErrorAction SilentlyContinue
            if ($user -and $user.CompanyName -eq "Delta Crown Extensions") {
                # Check if user is in SG-DCE-AllStaff
                $group = Get-MgGroup -Filter "displayName eq 'SG-DCE-AllStaff'" -ErrorAction SilentlyContinue
                if ($group) {
                    $isMember = Get-MgGroupMember -GroupId $group.Id -Filter "id eq '$($user.Id)'" -ErrorAction SilentlyContinue
                    if ($isMember) {
                        $verified++
                    }
                }
            }
        }

        if ($verified -eq $total) {
            $allVerified = $true
            Write-DeltaCrownLog "✅ All $total users verified in SG-DCE-AllStaff" "SUCCESS"
        }
        else {
            Write-DeltaCrownLog "  $verified / $total verified — waiting ${PollIntervalSeconds}s..." "INFO"
            Start-Sleep -Seconds $PollIntervalSeconds
            $pollElapsed += $PollIntervalSeconds
        }
    }

    if (-not $allVerified) {
        Write-DeltaCrownLog "⚠️  Timed out waiting for group evaluation. Some users may not yet be in groups." "WARNING"
        Write-DeltaCrownLog "    This is normal — Azure AD can take up to 24 hours in rare cases." "WARNING"
        Write-DeltaCrownLog "    Run 4.1-User-Property-Audit.ps1 -ShowGroupMembership to check later." "WARNING"
    }

    return $allVerified
}

function Format-OnboardingReport {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Collections.ArrayList]$Results)

    $updated = ($Results | Where-Object { $_.Status -eq "Updated" }).Count
    $noChange = ($Results | Where-Object { $_.Status -eq "NoChange" }).Count
    $errors = ($Results | Where-Object { $_.Status -eq "Error" }).Count
    $whatIf = ($Results | Where-Object { $_.Status -eq "WhatIf" }).Count

    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
    Write-DeltaCrownLog "        USER ONBOARDING REPORT" "STAGE"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "  Updated:    $updated" "SUCCESS"
    Write-DeltaCrownLog "  No change:  $noChange" "INFO"
    Write-DeltaCrownLog "  Errors:     $errors" $(if ($errors -gt 0) { "ERROR" } else { "INFO" })
    if ($whatIf -gt 0) {
        Write-DeltaCrownLog "  WhatIf:     $whatIf (dry run — no changes made)" "WARNING"
    }

    if ($errors -gt 0) {
        Write-DeltaCrownLog "" "INFO"
        Write-DeltaCrownLog "FAILED USERS:" "ERROR"
        foreach ($r in ($Results | Where-Object { $_.Status -eq "Error" })) {
            Write-DeltaCrownLog "  ❌ $($r.UPN): $($r.Errors -join '; ')" "ERROR"
        }
    }

    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-DeltaCrownLog "Starting User Onboarding for tenant: $TenantName" "STAGE"
Write-DeltaCrownLog "Environment: $Environment | Mode: $($PSCmdlet.ParameterSetName)" "INFO"

if ($WhatIfPreference) {
    Write-DeltaCrownLog "*** DRY RUN MODE — No changes will be made ***" "WARNING"
}

# Connect to Microsoft Graph
try {
    $authConfig = Import-DeltaCrownAuthConfig -Environment $Environment
    Connect-DeltaCrownGraph -AuthConfig $authConfig -RequiredScopes @(
        "User.ReadWrite.All",
        "Group.Read.All",
        "Directory.ReadWrite.All"
    )
    Write-DeltaCrownLog "Connected to Microsoft Graph" "SUCCESS"
}
catch {
    Write-DeltaCrownLog "Failed to connect to Microsoft Graph: $_" "CRITICAL" -Exception $_.Exception
    exit 2
}

# Load user mappings
$userMappings = @()

if ($PSCmdlet.ParameterSetName -eq "CsvFile") {
    Write-DeltaCrownLog "Loading user mappings from: $MappingFile" "INFO"
    $userMappings = Import-UserMappings -Path $MappingFile
    Write-DeltaCrownLog "Loaded $($userMappings.Count) user mappings" "INFO"
}
else {
    # Single user mode
    $userMappings = @(@{
        UPN         = $UserPrincipalName
        CompanyName = $CompanyName
        JobTitle    = $JobTitle
        Department  = $Department
    })
}

if ($userMappings.Count -eq 0) {
    Write-DeltaCrownLog "No user mappings to process" "WARNING"
    exit 0
}

# Process each user
Write-DeltaCrownLog "" "INFO"
Write-DeltaCrownLog "Processing $($userMappings.Count) users..." "STAGE"

$updatedUPNs = @()

foreach ($mapping in $userMappings) {
    $result = Update-SingleUser `
        -UPN $mapping.UPN `
        -NewCompanyName $mapping.CompanyName `
        -NewJobTitle $mapping.JobTitle `
        -NewDepartment $mapping.Department

    [void]$script:UpdateResults.Add($result)

    if ($result.Status -eq "Updated") {
        $updatedUPNs += $mapping.UPN
    }
}

# Report
Format-OnboardingReport -Results $script:UpdateResults

# Wait for dynamic group evaluation (only if we actually updated users)
if ($updatedUPNs.Count -gt 0 -and -not $SkipGroupVerification -and -not $WhatIfPreference) {
    $groupsVerified = Wait-ForGroupEvaluation `
        -UpdatedUPNs $updatedUPNs `
        -InitialWaitMinutes $GroupEvaluationWaitMinutes `
        -MaxWaitMinutes $MaxGroupEvaluationWaitMinutes

    if ($groupsVerified) {
        Write-DeltaCrownLog "" "INFO"
        Write-DeltaCrownLog "🎉 All users onboarded and verified in dynamic groups!" "SUCCESS"
        Write-DeltaCrownLog "   Users now have access to DCE Hub, sites, and Teams." "SUCCESS"
    }
}
elseif ($WhatIfPreference) {
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "Dry run complete. Re-run without -WhatIf to apply changes." "INFO"
}

# Export results log
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = if ($LogPath) { $LogPath } else { Join-Path $PSScriptRoot "..\logs\onboarding-$timestamp.json" }
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$exportData = @{
    Timestamp    = Get-Date -Format "o"
    TenantName   = $TenantName
    Environment  = $Environment
    WhatIf       = $WhatIfPreference
    TotalUsers   = $script:UpdateResults.Count
    Updated      = ($script:UpdateResults | Where-Object { $_.Status -eq "Updated" }).Count
    NoChange     = ($script:UpdateResults | Where-Object { $_.Status -eq "NoChange" }).Count
    Errors       = ($script:UpdateResults | Where-Object { $_.Status -eq "Error" }).Count
    Results      = $script:UpdateResults
}

$exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $logFile -Encoding UTF8
Write-DeltaCrownLog "Onboarding log exported to: $logFile" "INFO"

# Exit code
$errorCount = ($script:UpdateResults | Where-Object { $_.Status -eq "Error" }).Count
if ($errorCount -gt 0) {
    exit 1
}
exit 0
