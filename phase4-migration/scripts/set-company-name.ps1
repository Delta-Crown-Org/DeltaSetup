# ============================================================================
# SET COMPANY NAME: Apply "Delta Crown Extensions" to 4 licensed native users
# Usage: pwsh ./set-company-name.ps1           # Dry run (default)
#        pwsh ./set-company-name.ps1 -Apply    # Actually update Azure AD
# ============================================================================

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$DCETenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
$CompanyName = "Delta Crown Extensions"

$targetUsers = @(
    "Allynn.Shepherd@deltacrown.com",
    "Jay.Miller@deltacrown.com",
    "Lindy.Sturgill@deltacrown.com",
    "Sarah.Miller@deltacrown.com"
)

# --- Banner ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
if ($Apply) {
    Write-Host "  LIVE RUN: Setting companyName" -ForegroundColor Red
} else {
    Write-Host "  DRY RUN: Preview changes only" -ForegroundColor Yellow
}
Write-Host "  Target: $CompanyName" -ForegroundColor Cyan
Write-Host "  Users:  $($targetUsers.Count)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Connect ---
Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.ReadWrite.All" `
    -TenantId $DCETenantId -NoWelcome

$ctx = Get-MgContext
if (!$ctx -or $ctx.TenantId -ne $DCETenantId) {
    Write-Host "ERROR: Not connected to deltacrownext tenant." -ForegroundColor Red
    exit 1
}
Write-Host "Connected: $($ctx.TenantId) (deltacrown)" -ForegroundColor Green
Write-Host ""

# --- Process each user ---
$updated = 0
$skipped = 0
$errors = 0

foreach ($upn in $targetUsers) {
    $u = Get-MgUser -UserId $upn -Property "displayName","companyName","department","jobTitle" -ErrorAction Stop

    Write-Host "  $($u.DisplayName) ($upn)" -ForegroundColor White
    Write-Host "    companyName: '$($u.CompanyName)' -> '$CompanyName'"

    if ($u.CompanyName -eq $CompanyName) {
        Write-Host "    STATUS: Already set — SKIP" -ForegroundColor DarkGray
        $skipped++
        Write-Host ""
        continue
    }

    if ($Apply) {
        try {
            Update-MgUser -UserId $upn -CompanyName $CompanyName -ErrorAction Stop
            Write-Host "    STATUS: UPDATED" -ForegroundColor Green
            $updated++
        }
        catch {
            Write-Host "    STATUS: FAILED — $_" -ForegroundColor Red
            $errors++
        }
    } else {
        Write-Host "    STATUS: WOULD UPDATE (dry run)" -ForegroundColor Yellow
        $updated++
    }
    Write-Host ""
}

# --- Summary ---
Write-Host "============================================" -ForegroundColor Cyan
if ($Apply) {
    Write-Host "  RESULTS (LIVE)" -ForegroundColor Green
} else {
    Write-Host "  RESULTS (DRY RUN)" -ForegroundColor Yellow
}
Write-Host "  Updated: $updated" -ForegroundColor $(if ($updated -gt 0) { "Green" } else { "White" })
Write-Host "  Skipped: $skipped" -ForegroundColor White
Write-Host "  Errors:  $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "White" })
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (!$Apply -and $updated -gt 0) {
    Write-Host "To apply for real, run:" -ForegroundColor Yellow
    Write-Host "  pwsh ./set-company-name.ps1 -Apply" -ForegroundColor Yellow
    Write-Host ""
}

# --- Verify (live run only) ---
if ($Apply -and $updated -gt 0) {
    Write-Host "=== Verification ===" -ForegroundColor Cyan
    foreach ($upn in $targetUsers) {
        $u = Get-MgUser -UserId $upn -Property "displayName","companyName" -ErrorAction SilentlyContinue
        $match = if ($u.CompanyName -eq $CompanyName) { "OK" } else { "MISMATCH" }
        $color = if ($match -eq "OK") { "Green" } else { "Red" }
        Write-Host "  $($u.DisplayName): companyName='$($u.CompanyName)' [$match]" -ForegroundColor $color
    }
    Write-Host ""
}

Disconnect-MgGraph -ErrorAction SilentlyContinue
