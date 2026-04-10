# ============================================================================
# QUICK AUDIT: Run this directly in PowerShell 7 terminal
# Usage: pwsh ./run-audit-now.ps1
# ============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
if (!$ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$LogsDir = Join-Path (Split-Path $ScriptDir -Parent) "logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DCE User Property Audit — deltacrownext"   -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "A browser window will open for authentication." -ForegroundColor Yellow
Write-Host "Sign in with your deltacrownext admin account." -ForegroundColor Yellow
Write-Host ""

# Connect
Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","Directory.Read.All" `
    -TenantId "deltacrownext.onmicrosoft.com" -NoWelcome

$ctx = Get-MgContext
if (!$ctx -or !$ctx.TenantId) {
    Write-Host "ERROR: Authentication failed. Run this script in a real terminal." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== CONNECTED ===" -ForegroundColor Green
Write-Host "Account:  $($ctx.Account)"
Write-Host "TenantId: $($ctx.TenantId)"
Write-Host ""

# Get users
Write-Host "=== ALL MEMBER USERS ===" -ForegroundColor Cyan
$users = Get-MgUser -All -Property "UserPrincipalName","DisplayName","CompanyName","Department","JobTitle","AccountEnabled","UserType","UsageLocation","CreatedDateTime" -ConsistencyLevel eventual

$members = $users | Where-Object { $_.UserType -eq "Member" }
Write-Host "Total: $($users.Count) users | Members: $($members.Count)"
Write-Host ""

$members | Format-Table @{L="UPN";E={$_.UserPrincipalName}},
    @{L="Name";E={$_.DisplayName}},
    @{L="Company";E={$_.CompanyName}},
    @{L="Dept";E={$_.Department}},
    @{L="Title";E={$_.JobTitle}},
    @{L="On";E={$_.AccountEnabled}},
    @{L="Loc";E={$_.UsageLocation}} -AutoSize -Wrap

# Property gaps
Write-Host ""
Write-Host "=== PROPERTY GAPS ===" -ForegroundColor Yellow
$noCompany = ($members | Where-Object { [string]::IsNullOrWhiteSpace($_.CompanyName) }).Count
$noDept    = ($members | Where-Object { [string]::IsNullOrWhiteSpace($_.Department) }).Count
$noTitle   = ($members | Where-Object { [string]::IsNullOrWhiteSpace($_.JobTitle) }).Count
$noLoc     = ($members | Where-Object { [string]::IsNullOrWhiteSpace($_.UsageLocation) }).Count
Write-Host "Missing companyName:   $noCompany / $($members.Count)"
Write-Host "Missing department:    $noDept / $($members.Count)"
Write-Host "Missing jobTitle:      $noTitle / $($members.Count)"
Write-Host "Missing usageLocation: $noLoc / $($members.Count)"

# Dynamic group simulation
Write-Host ""
Write-Host "=== DYNAMIC GROUP SIMULATION ===" -ForegroundColor Cyan
$allStaff   = ($members | Where-Object { $_.CompanyName -eq "Delta Crown Extensions" }).Count
$leadership = ($members | Where-Object { $_.CompanyName -eq "Delta Crown Extensions" -and $_.JobTitle -match "Manager|Director|VP|Vice President|Chief|Head of|Lead" }).Count
$marketing  = ($members | Where-Object { $_.CompanyName -eq "Delta Crown Extensions" -and $_.Department -match "Marketing" }).Count
Write-Host "SG-DCE-AllStaff:   $allStaff"
Write-Host "SG-DCE-Leadership: $leadership"
Write-Host "SG-DCE-Marketing:  $marketing"

# Export
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $LogsDir "user-audit-$timestamp.csv"
$members | Select-Object UserPrincipalName, DisplayName, CompanyName, Department, JobTitle, AccountEnabled, UsageLocation, CreatedDateTime |
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "=== EXPORTED ===" -ForegroundColor Green
Write-Host "CSV: $csvPath"
Write-Host ""

Disconnect-MgGraph -ErrorAction SilentlyContinue
