# ============================================================================
# Rename Azure AD Groups — Remove DCE- prefix
# Run this from Tyler's terminal against the deltacrown tenant
# ============================================================================
# PURPOSE: Renames the existing DCE-* groups to prefix-free names to match
#          the updated scripts. Must be run BEFORE any updated scripts.
# ============================================================================

$tenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"

Write-Host "Renaming Azure AD Groups (DCE-* → prefix-free)..." -ForegroundColor Cyan
Write-Host "Tyler: you'll get a browser popup for Graph auth" -ForegroundColor Yellow

Connect-MgGraph -Scopes "Group.ReadWrite.All" -TenantId $tenantId

$renames = @(
    @{ Old = "DCE-AllStaff";  New = "AllStaff" }
    @{ Old = "DCE-Managers";  New = "Managers" }
    @{ Old = "DCE-Stylists";  New = "Stylists" }
    @{ Old = "DCE-External";  New = "External" }
)

$results = @()
foreach ($r in $renames) {
    $group = Get-MgGroup -Filter "displayName eq '$($r.Old)'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $group) {
        # Maybe already renamed?
        $already = Get-MgGroup -Filter "displayName eq '$($r.New)'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($already) {
            Write-Host "  Already renamed: $($r.New) (ID: $($already.Id))" -ForegroundColor Yellow
            $results += [PSCustomObject]@{ Old = $r.Old; New = $r.New; Status = "Already Done"; Id = $already.Id }
        } else {
            Write-Host "  NOT FOUND: $($r.Old) — skipping" -ForegroundColor Red
            $results += [PSCustomObject]@{ Old = $r.Old; New = $r.New; Status = "Not Found"; Id = $null }
        }
        continue
    }

    try {
        Update-MgGroup -GroupId $group.Id -DisplayName $r.New
        Write-Host "  Renamed: $($r.Old) → $($r.New) (ID: $($group.Id))" -ForegroundColor Green
        $results += [PSCustomObject]@{ Old = $r.Old; New = $r.New; Status = "Renamed"; Id = $group.Id }
    } catch {
        Write-Host "  FAILED: $($r.Old) → $($r.New) — $_" -ForegroundColor Red
        $results += [PSCustomObject]@{ Old = $r.Old; New = $r.New; Status = "Failed: $_"; Id = $group.Id }
    }
}

Write-Host "`nResults:" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Verify
Write-Host "`nVerification — current groups:" -ForegroundColor Cyan
$expectedNames = @('AllStaff', 'Managers', 'Stylists', 'External')
foreach ($name in $expectedNames) {
    $g = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($g) {
        Write-Host "  ✅ $name (ID: $($g.Id), Members: $(($g.MembershipRule -ne $null)))" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $name — NOT FOUND" -ForegroundColor Red
    }
}

Disconnect-MgGraph
Write-Host "`nDone! Run '5.1-Exchange-Setup.ps1 -VerifyOnly' to confirm everything works." -ForegroundColor Green
