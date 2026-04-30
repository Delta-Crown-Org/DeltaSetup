# ============================================================================
# Phase 4: Document Migration — PREVIEW REPORT (No Auth Required)
# ============================================================================
# Generates a migration plan summary without connecting to SharePoint
# Tyler: Verify manually or run from local machine with browser access
# ============================================================================

Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
Write-Host "  PHASE 4: DOCUMENT MIGRATION — PREVIEW REPORT" -ForegroundColor Cyan
Write-Host "$('=' * 70)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Migration mapping
$Mappings = @(
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Operations";                Dest = "dce-operations/Documents/Operations";               Priority = 1; Notes = "Daily ops documents" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/_Franchisees";               Dest = "dce-operations/Documents/Franchisees";              Priority = 1; Notes = "Franchise management" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Status";                    Dest = "dce-operations/Documents/Status";                   Priority = 2; Notes = "Status tracking" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Fran Dev";                  Dest = "dce-operations/Documents/Franchise-Development";    Priority = 2; Notes = "Growth/development" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Marketing";                 Dest = "dce-marketing/Brand Assets/Marketing";              Priority = 1; Notes = "Brand marketing materials" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Product";                   Dest = "dce-docs/Documents/Product";                        Priority = 2; Notes = "Product reference" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Strategy";                  Dest = "dce-docs/Documents/Strategy";                       Priority = 2; Notes = "Leadership only access" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Training";                  Dest = "dce-docs/Training";                                 Priority = 3; Notes = "Training materials" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Financials & Proforma";   Dest = "dce-operations/Documents/Financials";               Priority = 1; Notes = "Review each file — some may go to corp-finance" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Corp Docs";                Dest = "corp-hub/Shared Documents/Corporate";               Priority = 3; Notes = "Cross-brand corporate docs" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/Real Estate & Construction"; Dest = "corp-hub/Shared Documents/Real-Estate";            Priority = 3; Notes = "Cross-brand function" },
    @{ Source = "HTTHQ/Shared Documents/Master DCE/zArchive";                  Dest = "dce-docs/Archive";                                  Priority = 3; Notes = "Historical reference" }
)

# Group by destination site
$bySite = $Mappings | Group-Object -Property { $_.Dest.Split('/')[0] }

Write-Host "MIGRATION OVERVIEW" -ForegroundColor Green
Write-Host "-" -ForegroundColor Green
Write-Host "Total folders to migrate: $($Mappings.Count)" -ForegroundColor White
Write-Host "Source tenant:          httbrands.sharepoint.com" -ForegroundColor White
Write-Host "Destination tenant:     deltacrown.sharepoint.com" -ForegroundColor White
Write-Host ""

Write-Host "DESTINATION SITES" -ForegroundColor Green
Write-Host "-" -ForegroundColor Green

foreach ($siteGroup in $bySite) {
    $siteName = $siteGroup.Name
    $count = $siteGroup.Count

    switch ($siteName) {
        "dce-operations" { $icon = "🔧"; $desc = "Operations Hub" }
        "dce-marketing"  { $icon = "📢"; $desc = "Marketing Hub" }
        "dce-docs"       { $icon = "📚"; $desc = "Document Center" }
        "corp-hub"       { $icon = "🏢"; $desc = "Corporate Hub" }
        default          { $icon = "📁"; $desc = "" }
    }

    Write-Host "$icon $siteName" -ForegroundColor Yellow
    Write-Host "   $desc ($count folder mappings)" -ForegroundColor Gray

    foreach ($map in $siteGroup.Group) {
        $priorityColor = if ($map.Priority -eq 1) { "Red" } elseif ($map.Priority -eq 2) { "Yellow" } else { "Gray" }
        Write-Host "   └─ P$($map.Priority): $($map.Source.Split('/')[-1]) → $($map.Dest.Split('/', 2)[1])" -ForegroundColor White
    }
    Write-Host ""
}

Write-Host "PRIORITY BREAKDOWN" -ForegroundColor Green
Write-Host "-" -ForegroundColor Green
$p1 = ($Mappings | Where-Object { $_.Priority -eq 1 }).Count
$p2 = ($Mappings | Where-Object { $_.Priority -eq 2 }).Count
$p3 = ($Mappings | Where-Object { $_.Priority -eq 3 }).Count
Write-Host "P1 (Critical): $p1 folders — Migrate first" -ForegroundColor Red
Write-Host "P2 (Standard): $p2 folders — Migrate second" -ForegroundColor Yellow
Write-Host "P3 (Deferred): $p3 folders — Migrate last" -ForegroundColor Gray
Write-Host ""

Write-Host "MIGRATION STEPS" -ForegroundColor Green
Write-Host "-" -ForegroundColor Green
Write-Host "1. Authenticate to HTTHQ (httbrands) source tenant" -ForegroundColor White
Write-Host "2. Authenticate to DCE (deltacrown) destination tenant" -ForegroundColor White
Write-Host "3. Copy files maintaining folder structure" -ForegroundColor White
Write-Host "4. Preserve metadata (Modified, Created, Author)" -ForegroundColor White
Write-Host "5. Generate migration report" -ForegroundColor White
Write-Host ""

Write-Host "CURRENT DECISION: MIGRATION SKIPPED" -ForegroundColor Yellow
Write-Host "-" -ForegroundColor Yellow
Write-Host "Do not execute document migration for production cutover." -ForegroundColor White
Write-Host "This report is historical planning context only." -ForegroundColor Gray
Write-Host ""

Write-Host "$('=' * 70)" -ForegroundColor Green
Write-Host "  END OF PREVIEW REPORT" -ForegroundColor Green
Write-Host "$('=' * 70)" -ForegroundColor Green
Write-Host ""

# Export to file
$reportPath = "../logs/migration-preview-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$reportContent = @"
PHASE 4 DOCUMENT MIGRATION PREVIEW REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

MIGRATION MAPPING:
$($Mappings | Format-Table Source, Dest, Priority, Notes -AutoSize | Out-String)

DESTINATION SITES:
$(foreach ($site in $bySite) { "$($site.Name): $($site.Count) folders`n$(foreach ($m in $site.Group) { "  - $($m.Source.Split('/')[-1])`n" })" })

PRIORITY SUMMARY:
- P1 (Critical): $p1 folders
- P2 (Standard): $p2 folders  
- P3 (Deferred): $p3 folders

NEXT STEPS:
Do not run document migration for production cutover. Migration is skipped by Tyler's 2026-04-29 decision.
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Report saved to: $reportPath" -ForegroundColor Green
