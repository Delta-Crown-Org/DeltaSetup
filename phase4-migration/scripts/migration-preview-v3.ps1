# ============================================================================
# Phase 4: Document Migration — PREVIEW / DRY RUN
# ============================================================================
# Shows what files exist in HTTHQ source and where they'd go in DCE
# Tyler: 2 device codes (httbrands source, deltacrown destination)
# ============================================================================

$ErrorActionPreference = "Stop"

# Source: HTTHQ (httbrands tenant)
$sourceUrl = "https://httbrands.sharepoint.com/sites/HTTHQ"
$sourceTenant = "httbrands.onmicrosoft.com"  # or get tenant ID

# Dest: DCE (deltacrown tenant)
$destClientId = "6d8820fe-7a7b-4226-bc3b-2c53add3c207"
$destTenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"

$Mappings = @(
    @{ SourceFolder = "Master DCE/Operations";               DestSite = "deltacrown.sharepoint.com/sites/dce-operations";  DestLib = "Documents";          DestFolder = "Operations" },
    @{ SourceFolder = "Master DCE/_Franchisees";             DestSite = "deltacrown.sharepoint.com/sites/dce-operations";  DestLib = "Documents";          DestFolder = "Franchisees" },
    @{ SourceFolder = "Master DCE/Status";                  DestSite = "deltacrown.sharepoint.com/sites/dce-operations";  DestLib = "Documents";          DestFolder = "Status" },
    @{ SourceFolder = "Master DCE/Fran Dev";                DestSite = "deltacrown.sharepoint.com/sites/dce-operations";  DestLib = "Documents";          DestFolder = "Franchise-Development" },
    @{ SourceFolder = "Master DCE/Marketing";                DestSite = "deltacrown.sharepoint.com/sites/dce-marketing";    DestLib = "Brand Assets";       DestFolder = "Marketing" },
    @{ SourceFolder = "Master DCE/Product";                  DestSite = "deltacrown.sharepoint.com/sites/dce-docs";        DestLib = "Documents";          DestFolder = "Product" },
    @{ SourceFolder = "Master DCE/Strategy";                DestSite = "deltacrown.sharepoint.com/sites/dce-docs";        DestLib = "Documents";          DestFolder = "Strategy" },
    @{ SourceFolder = "Master DCE/Training";                DestSite = "deltacrown.sharepoint.com/sites/dce-docs";        DestLib = "Training";           DestFolder = "" },
    @{ SourceFolder = "Master DCE/Financials & Proforma"; DestSite = "deltacrown.sharepoint.com/sites/dce-operations";  DestLib = "Documents";          DestFolder = "Financials" },
    @{ SourceFolder = "Master DCE/Corp Docs";              DestSite = "deltacrown.sharepoint.com/sites/corp-hub";        DestLib = "Shared Documents";   DestFolder = "Corporate" },
    @{ SourceFolder = "Master DCE/Real Estate & Construction"; DestSite = "deltacrown.sharepoint.com/sites/corp-hub";     DestLib = "Shared Documents";   DestFolder = "Real-Estate" },
    @{ SourceFolder = "Master DCE/zArchive";                DestSite = "deltacrown.sharepoint.com/sites/dce-docs";        DestLib = "Archive";            DestFolder = "" }
)

function Write-Log {
    param([string]$Msg, [string]$Lvl = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $c = @{ INFO="White"; SUCCESS="Green"; WARNING="Yellow"; ERROR="Red"; STAGE="Cyan"; DRY="Magenta" }
    $p = @{ SUCCESS="[OK]"; ERROR="[!!]"; WARNING="[??]"; STAGE="[==]"; INFO="[..]"; DRY="[DRY]" }
    Write-Host "$ts $($p[$Lvl]) $Msg" -ForegroundColor $c[$Lvl]
}

function Do-DeviceLogin {
    param([string]$Url, [string]$ClientId, [string]$Tenant, [string]$Label)
    Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
    Write-Host "  AUTH: $Label" -ForegroundColor Cyan
    Write-Host "  Tyler: code at https://microsoft.com/devicelogin" -ForegroundColor Yellow
    Write-Host "$('=' * 60)" -ForegroundColor Cyan

    if ($ClientId -and $Tenant) {
        Connect-PnPOnline -Url $Url -DeviceLogin -ClientId $ClientId -Tenant $Tenant -ErrorAction Stop
    } elseif ($Tenant) {
        Connect-PnPOnline -Url $Url -DeviceLogin -Tenant $Tenant -ErrorAction Stop
    } else {
        Connect-PnPOnline -Url $Url -DeviceLogin -ErrorAction Stop
    }
    Write-Log "Connected: $Label" "SUCCESS"
}

# ============================================================================
# AUTH 1: Source (httbrands)
# ============================================================================
Do-DeviceLogin -Url $sourceUrl -ClientId $null -Tenant $sourceTenant -Label "HTTHQ Source (httbrands)"

Write-Log "=== Phase 4: Document Migration Preview ===" "STAGE"
Write-Log "DRY RUN MODE — No files will be copied" "DRY"
Write-Log ""

# Scan each mapped folder
$results = @()
foreach ($map in $Mappings) {
    $folderPath = $map.SourceFolder
    Write-Log "Scanning: $folderPath" "STAGE"

    try {
        $relativePath = "Shared Documents/$folderPath"
        $files = Get-PnPFolderItem -FolderSiteRelativeUrl $relativePath -ItemType File -ErrorAction Stop

        $fileCount = if ($files) { @($files).Count } else { 0 }
        $sizeKB = 0
        if ($files) {
            $files | ForEach-Object { $sizeKB += ($_.Length / 1KB) }
        }

        Write-Log "  Files found: $fileCount ($([math]::Round($sizeKB, 2)) KB)" "SUCCESS"
        Write-Log "  → Would migrate to: https://$($map.DestSite)/$($map.DestLib)/$($map.DestFolder)" "DRY"

        # Show first few files
        if ($files) {
            @($files) | Select-Object -First 5 | ForEach-Object {
                Write-Log "    📄 $($_.Name) ($([math]::Round($_.Length/1KB, 1)) KB)" "INFO"
            }
            if ($fileCount -gt 5) {
                Write-Log "    ... and $($fileCount - 5) more" "INFO"
            }
        }

        $results += [PSCustomObject]@{
            SourceFolder = $folderPath
            FileCount = $fileCount
            SizeKB = [math]::Round($sizeKB, 2)
            Destination = "https://$($map.DestSite)/$($map.DestLib)/$($map.DestFolder)"
            Status = "Ready"
        }
    }
    catch {
        Write-Log "  Error accessing folder: $_" "WARNING"
        $results += [PSCustomObject]@{
            SourceFolder = $folderPath
            FileCount = 0
            SizeKB = 0
            Destination = "https://$($map.DestSite)/$($map.DestLib)/$($map.DestFolder)"
            Status = "Error"
        }
    }
    Write-Log ""
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 2: Dest (deltacrown) — Verify sites exist
# ============================================================================
Do-DeviceLogin -Url "https://deltacrown-admin.sharepoint.com" -ClientId $destClientId -Tenant $destTenantId -Label "DCE Admin (deltacrown)"

Write-Log "=== Verifying Destination Sites ===" "STAGE"

$destSites = @(
    "https://deltacrown.sharepoint.com/sites/dce-operations"
    "https://deltacrown.sharepoint.com/sites/dce-marketing"
    "https://deltacrown.sharepoint.com/sites/dce-docs"
    "https://deltacrown.sharepoint.com/sites/corp-hub"
)

foreach ($site in $destSites) {
    try {
        $siteInfo = Get-PnPTenantSite -Url $site -ErrorAction Stop
        Write-Log "  ✅ $site" "SUCCESS"
    }
    catch {
        Write-Log "  ❌ $site (NOT FOUND)" "ERROR"
    }
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "`n$('=' * 60)" -ForegroundColor Green
Write-Host "  MIGRATION PREVIEW COMPLETE" -ForegroundColor Green
Write-Host "$('=' * 60)" -ForegroundColor Green
Write-Host ""

$totalFiles = ($results | Measure-Object -Property FileCount -Sum).Sum
$totalSize = ($results | Measure-Object -Property SizeKB -Sum).Sum

Write-Log "Total folders mapped: $($Mappings.Count)" "INFO"
Write-Log "Total files ready:    $totalFiles" "SUCCESS"
Write-Log "Total size:           $([math]::Round($totalSize/1024, 2)) MB" "SUCCESS"
Write-Host ""

Write-Log "Migration Plan:" "STAGE"
$results | Format-Table SourceFolder, FileCount, @{N='Size(MB)';E={[math]::Round($_.SizeKB/1024, 2)}}, Status -AutoSize | Out-String | Write-Host

Write-Log "To execute migration for real, run:" "INFO"
Write-Log "  pwsh ./4.3-Document-Migration.ps1 -MappingFile '../config/dce-file-mapping.csv'" "INFO"
