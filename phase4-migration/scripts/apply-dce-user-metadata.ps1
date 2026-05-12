# ============================================================================
# APPLY DCE USER METADATA
# Reads a local validated/apply CSV and updates Delta Crown Entra user metadata.
#
# Default mode is dry-run. Use -Apply to write changes.
# CSV fields required:
#   userPrincipalName, companyName, department, jobTitle, officeLocation,
#   employeeType
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="Microsoft.Graph.Authentication";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Users";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30",
    [string]$InputCsv = ".local/reports/tenant-inventory/metadata-teams-verification/dce-user-metadata-apply-values.csv",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host $Message -ForegroundColor $Color
}

function Assert-InputCsv {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        throw "Input CSV not found: $Path"
    }
}

function Assert-RequiredColumns {
    param([object[]]$Rows)
    if (!$Rows -or $Rows.Count -eq 0) {
        throw "Input CSV has no rows."
    }
    $required = @(
        "userPrincipalName",
        "companyName",
        "department",
        "jobTitle",
        "officeLocation",
        "employeeType"
    )
    $columns = @($Rows[0].PSObject.Properties.Name)
    foreach ($column in $required) {
        if ($columns -notcontains $column) {
            throw "Input CSV missing required column: $column"
        }
    }
}

function Get-DesiredValues {
    param([object]$Row)
    return [ordered]@{
        CompanyName    = [string]$Row.companyName
        Department     = [string]$Row.department
        JobTitle       = [string]$Row.jobTitle
        OfficeLocation = [string]$Row.officeLocation
        EmployeeType   = [string]$Row.employeeType
    }
}

function Get-CurrentValues {
    param([object]$User)
    return [ordered]@{
        CompanyName    = [string]$User.CompanyName
        Department     = [string]$User.Department
        JobTitle       = [string]$User.JobTitle
        OfficeLocation = [string]$User.OfficeLocation
        EmployeeType   = [string]$User.EmployeeType
    }
}

function Compare-Values {
    param(
        [hashtable]$Current,
        [hashtable]$Desired
    )
    $changes = @()
    foreach ($key in $Desired.Keys) {
        $old = if ($null -eq $Current[$key]) { "" } else { [string]$Current[$key] }
        $new = if ($null -eq $Desired[$key]) { "" } else { [string]$Desired[$key] }
        if ($old -ne $new) {
            $changes += [pscustomobject]@{ Field = $key; Current = $old; Desired = $new }
        }
    }
    return $changes
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
if ($Apply) {
    Write-Host "  LIVE RUN: Apply DCE user metadata" -ForegroundColor Red
} else {
    Write-Host "  DRY RUN: Preview DCE user metadata changes" -ForegroundColor Yellow
}
Write-Host "  Tenant: $TenantId" -ForegroundColor Cyan
Write-Host "  Input:  $InputCsv" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Assert-InputCsv -Path $InputCsv
$rows = @(Import-Csv -Path $InputCsv)
Assert-RequiredColumns -Rows $rows

Write-Step "Rows loaded: $($rows.Count)" "Cyan"

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.ReadWrite.All" -TenantId $TenantId -NoWelcome

$ctx = Get-MgContext
if (!$ctx -or $ctx.TenantId -ne $TenantId) {
    throw "Connected Graph tenant mismatch. Expected $TenantId, got $($ctx.TenantId)."
}
Write-Step "Connected to tenant: $($ctx.TenantId)" "Green"
Write-Host ""

$updated = 0
$unchanged = 0
$errors = 0
$plannedChanges = 0

foreach ($row in $rows) {
    $upn = [string]$row.userPrincipalName
    Write-Step "User: $($row.displayName) <$upn>" "White"

    try {
        $user = Get-MgUser -UserId $upn -Property "id,displayName,userPrincipalName,companyName,department,jobTitle,officeLocation,employeeType" -ErrorAction Stop
        $current = Get-CurrentValues -User $user
        $desired = Get-DesiredValues -Row $row
        $changes = @(Compare-Values -Current $current -Desired $desired)

        if ($changes.Count -eq 0) {
            Write-Host "  No changes needed." -ForegroundColor DarkGray
            $unchanged++
            Write-Host ""
            continue
        }

        foreach ($change in $changes) {
            Write-Host "  $($change.Field): '$($change.Current)' -> '$($change.Desired)'" -ForegroundColor Yellow
        }
        $plannedChanges += $changes.Count

        if ($Apply) {
            $params = @{
                CompanyName    = $desired.CompanyName
                Department     = $desired.Department
                JobTitle       = $desired.JobTitle
                OfficeLocation = $desired.OfficeLocation
                EmployeeType   = $desired.EmployeeType
            }
            if ($PSCmdlet.ShouldProcess($upn, "Update Graph user metadata")) {
                Update-MgUser -UserId $upn @params -ErrorAction Stop
                Write-Host "  UPDATED" -ForegroundColor Green
                $updated++
            }
        } else {
            Write-Host "  WOULD UPDATE (dry-run)" -ForegroundColor Yellow
            $updated++
        }
    }
    catch {
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
    Write-Host ""
}

Write-Host "============================================================" -ForegroundColor Cyan
if ($Apply) {
    Write-Host "  RESULTS (LIVE)" -ForegroundColor Green
} else {
    Write-Host "  RESULTS (DRY RUN)" -ForegroundColor Yellow
}
Write-Host "  Rows needing updates: $updated"
Write-Host "  Rows unchanged:       $unchanged"
Write-Host "  Field changes:        $plannedChanges"
Write-Host "  Errors:               $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "White" })
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (!$Apply -and $updated -gt 0) {
    Write-Host "To apply for real, run:" -ForegroundColor Yellow
    Write-Host "  pwsh -File ./phase4-migration/scripts/apply-dce-user-metadata.ps1 -Apply" -ForegroundColor Yellow
    Write-Host ""
}

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null

if ($errors -gt 0) { exit 1 }
