# ============================================================================
# 4.3-Document-Migration.ps1
# Cross-tenant document migration from HTTHQ to DCE hub-and-spoke
# ============================================================================
# PURPOSE: Copy documents from httbrands.sharepoint.com/sites/HTTHQ
#          "Master DCE" folder to the new hub-and-spoke sites on
#          deltacrown.sharepoint.com
# ============================================================================
# USAGE:
#   # Full migration from mapping CSV:
#   ./4.3-Document-Migration.ps1 -MappingFile "../config/dce-file-mapping.csv"
#
#   # Dry run (report what would be copied):
#   ./4.3-Document-Migration.ps1 -MappingFile "../config/dce-file-mapping.csv" -WhatIf
#
#   # Single folder migration:
#   ./4.3-Document-Migration.ps1 -SourceUrl "https://httbrands.sharepoint.com/sites/HTTHQ" `
#       -SourceLibrary "Shared Documents" -SourceFolder "Master DCE/Marketing" `
#       -DestUrl "https://deltacrown.sharepoint.com/sites/dce-marketing" `
#       -DestLibrary "Brand Assets" -DestFolder "Marketing"
#
#   # Migrate only priority 1 items:
#   ./4.3-Document-Migration.ps1 -MappingFile "../config/dce-file-mapping.csv" -Priority 1
# ============================================================================
# IMPORTANT: This script requires PnP connections to BOTH tenants.
#            You will be prompted to authenticate to httbrands (source)
#            and deltacrown (destination) separately.
# ============================================================================
# DEPENDENCIES: PnP.PowerShell >= 2.0.0
# MODULE DEPS:  DeltaCrown.Auth, DeltaCrown.Common
# ============================================================================

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "CsvFile")]
param(
    # CSV mode
    [Parameter(Mandatory, ParameterSetName = "CsvFile")]
    [ValidateScript({ Test-Path $_ })]
    [string]$MappingFile,

    # Single-folder mode
    [Parameter(Mandatory, ParameterSetName = "SingleFolder")]
    [string]$SourceUrl,

    [Parameter(Mandatory, ParameterSetName = "SingleFolder")]
    [string]$SourceLibrary,

    [Parameter(Mandatory, ParameterSetName = "SingleFolder")]
    [string]$SourceFolder,

    [Parameter(Mandatory, ParameterSetName = "SingleFolder")]
    [string]$DestUrl,

    [Parameter(Mandatory, ParameterSetName = "SingleFolder")]
    [string]$DestLibrary,

    [Parameter(Mandatory, ParameterSetName = "SingleFolder")]
    [string]$DestFolder,

    # Common params
    [Parameter()]
    [ValidateSet(1, 2, 3)]
    [int]$Priority = 0,

    [Parameter()]
    [switch]$IncludeVersionHistory,

    [Parameter()]
    [switch]$VerifyAfterCopy,

    [Parameter()]
    [string]$LogPath = $null,

    [Parameter()]
    [switch]$SkipExisting,

    [Parameter()]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development"
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

$script:MigrationLog = [System.Collections.ArrayList]::new()
$script:Stats = @{
    TotalFiles     = 0
    Copied         = 0
    Skipped        = 0
    Failed         = 0
    TotalSizeBytes = 0
    CopiedSizeBytes = 0
}

# Connection tracking — we need connections to both source and destination tenants
$script:SourceConnection = $null
$script:DestConnection = $null

# ============================================================================
# FUNCTIONS
# ============================================================================

function Connect-SourceTenant {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SiteUrl)

    Write-DeltaCrownLog "Connecting to SOURCE tenant: $SiteUrl" "INFO"
    Write-DeltaCrownLog "⚠️  You will be prompted to sign in to the httbrands tenant" "WARNING"

    try {
        # PnP connection to source — must be interactive since it's a different tenant
        Connect-PnPOnline -Url $SiteUrl -Interactive -ErrorAction Stop
        $script:SourceConnection = Get-PnPConnection
        Write-DeltaCrownLog "Connected to source: $SiteUrl" "SUCCESS"
    }
    catch {
        Write-DeltaCrownLog "Failed to connect to source tenant: $_" "CRITICAL" -Exception $_.Exception
        throw
    }
}

function Connect-DestTenant {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SiteUrl)

    Write-DeltaCrownLog "Connecting to DESTINATION tenant: $SiteUrl" "INFO"
    Write-DeltaCrownLog "⚠️  You will be prompted to sign in to the deltacrown tenant" "WARNING"

    try {
        # For destination, use our auth module if available, else interactive
        $authConfig = Import-DeltaCrownAuthConfig -Environment $Environment -ErrorAction SilentlyContinue
        if ($authConfig -and -not $authConfig.Interactive) {
            Connect-DeltaCrownSharePoint -Url $SiteUrl -AuthConfig $authConfig
        }
        else {
            Connect-PnPOnline -Url $SiteUrl -Interactive -ErrorAction Stop
        }
        $script:DestConnection = Get-PnPConnection
        Write-DeltaCrownLog "Connected to destination: $SiteUrl" "SUCCESS"
    }
    catch {
        Write-DeltaCrownLog "Failed to connect to destination tenant: $_" "CRITICAL" -Exception $_.Exception
        throw
    }
}

function Get-SourceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SiteUrl,
        [Parameter(Mandatory)][string]$Library,
        [Parameter(Mandatory)][string]$FolderPath
    )

    try {
        # Ensure we're connected to source
        Connect-PnPOnline -Url $SiteUrl -Interactive -ErrorAction Stop

        $serverRelativeUrl = "/$($Library)/$($FolderPath)" -replace "//", "/"

        # Get all files in the folder recursively
        $items = Get-PnPFolderItem -FolderSiteRelativeUrl "$Library/$FolderPath" -ItemType File -Recursive -ErrorAction Stop

        $files = foreach ($item in $items) {
            [PSCustomObject]@{
                Name             = $item.Name
                ServerRelativeUrl = $item.ServerRelativeUrl
                Length           = $item.Length
                TimeCreated      = $item.TimeCreated
                TimeLastModified = $item.TimeLastModified
                RelativePath     = $item.ServerRelativeUrl -replace [regex]::Escape($serverRelativeUrl), "" -replace "^/", ""
            }
        }

        return $files
    }
    catch {
        Write-DeltaCrownLog "Error listing source files in $FolderPath`: $_" "ERROR" -Exception $_.Exception
        return @()
    }
}

function Copy-FileToDestination {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][PSCustomObject]$SourceFile,
        [Parameter(Mandatory)][string]$SourceSiteUrl,
        [Parameter(Mandatory)][string]$DestSiteUrl,
        [Parameter(Mandatory)][string]$DestLibrary,
        [Parameter(Mandatory)][string]$DestFolder
    )

    $logEntry = [PSCustomObject]@{
        SourceUrl    = $SourceFile.ServerRelativeUrl
        FileName     = $SourceFile.Name
        FileSize     = $SourceFile.Length
        DestSite     = $DestSiteUrl
        DestPath     = "$DestLibrary/$DestFolder/$($SourceFile.RelativePath)"
        Status       = "Pending"
        Error        = $null
        CopiedAt     = $null
        Duration     = $null
    }

    $script:Stats.TotalFiles++
    $script:Stats.TotalSizeBytes += $SourceFile.Length

    # Build destination path
    $destRelativePath = if ($SourceFile.RelativePath) {
        "$DestFolder/$($SourceFile.RelativePath)"
    } else {
        "$DestFolder/$($SourceFile.Name)"
    }

    $destFullPath = "$DestLibrary/$destRelativePath"

    try {
        if ($PSCmdlet.ShouldProcess("$($SourceFile.Name) → $destFullPath", "Copy")) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Download from source
            Connect-PnPOnline -Url $SourceSiteUrl -Interactive -ErrorAction Stop
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "dce-migration"
            if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
            $tempFile = Join-Path $tempDir $SourceFile.Name

            Get-PnPFile -Url $SourceFile.ServerRelativeUrl -Path $tempDir -FileName $SourceFile.Name -AsFile -Force -ErrorAction Stop

            # Ensure destination folder exists
            Connect-PnPOnline -Url $DestSiteUrl -Interactive -ErrorAction Stop

            # Create folder path if needed
            $folderParts = $destRelativePath.Split("/") | Where-Object { $_ -and $_ -ne $SourceFile.Name }
            $currentPath = $DestLibrary
            foreach ($part in $folderParts) {
                $currentPath = "$currentPath/$part"
                try {
                    Resolve-PnPFolder -SiteRelativePath $currentPath -ErrorAction Stop | Out-Null
                }
                catch {
                    # Folder doesn't exist, create it
                    Add-PnPFolder -Name $part -Folder ($currentPath -replace "/$part$", "") -ErrorAction SilentlyContinue | Out-Null
                }
            }

            # Upload to destination
            $destFolderPath = ($destFullPath -replace "/$($SourceFile.Name)$", "")
            Add-PnPFile -Path $tempFile -Folder $destFolderPath -ErrorAction Stop | Out-Null

            # Clean up temp file
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

            $stopwatch.Stop()

            $logEntry.Status = "Copied"
            $logEntry.CopiedAt = Get-Date -Format "o"
            $logEntry.Duration = "$([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s"

            $script:Stats.Copied++
            $script:Stats.CopiedSizeBytes += $SourceFile.Length

            $sizeMB = [math]::Round($SourceFile.Length / 1MB, 2)
            Write-DeltaCrownLog "  ✅ $($SourceFile.Name) (${sizeMB}MB) → $destFullPath [$($logEntry.Duration)]" "SUCCESS"
        }
        else {
            $logEntry.Status = "WhatIf"
            $script:Stats.Skipped++
            $sizeMB = [math]::Round($SourceFile.Length / 1MB, 2)
            Write-DeltaCrownLog "  🔍 WOULD copy: $($SourceFile.Name) (${sizeMB}MB) → $destFullPath" "INFO"
        }
    }
    catch {
        $logEntry.Status = "Failed"
        $logEntry.Error = $_.Exception.Message
        $script:Stats.Failed++
        Write-DeltaCrownLog "  ❌ $($SourceFile.Name): $($_.Exception.Message)" "ERROR" -Exception $_.Exception
    }

    [void]$script:MigrationLog.Add($logEntry)
}

function Test-MigrationIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DestSiteUrl,
        [Parameter(Mandatory)][string]$DestLibrary,
        [Parameter(Mandatory)][string]$DestFolder,
        [Parameter(Mandatory)][int]$ExpectedFileCount
    )

    try {
        Connect-PnPOnline -Url $DestSiteUrl -Interactive -ErrorAction Stop
        $destFiles = Get-PnPFolderItem -FolderSiteRelativeUrl "$DestLibrary/$DestFolder" -ItemType File -Recursive -ErrorAction Stop

        $actualCount = ($destFiles | Measure-Object).Count

        if ($actualCount -eq $ExpectedFileCount) {
            Write-DeltaCrownLog "  ✅ Integrity check PASSED: $actualCount / $ExpectedFileCount files" "SUCCESS"
            return $true
        }
        else {
            Write-DeltaCrownLog "  ⚠️  Integrity check WARNING: $actualCount / $ExpectedFileCount files" "WARNING"
            return $false
        }
    }
    catch {
        Write-DeltaCrownLog "  ❌ Integrity check FAILED: $_" "ERROR"
        return $false
    }
}

function Format-MigrationReport {
    [CmdletBinding()]
    param()

    $totalMB = [math]::Round($script:Stats.TotalSizeBytes / 1MB, 2)
    $copiedMB = [math]::Round($script:Stats.CopiedSizeBytes / 1MB, 2)

    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
    Write-DeltaCrownLog "        DOCUMENT MIGRATION REPORT" "STAGE"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "  Total files:  $($script:Stats.TotalFiles)" "INFO"
    Write-DeltaCrownLog "  Copied:       $($script:Stats.Copied) (${copiedMB}MB)" "SUCCESS"
    Write-DeltaCrownLog "  Skipped:      $($script:Stats.Skipped)" "INFO"
    Write-DeltaCrownLog "  Failed:       $($script:Stats.Failed)" $(if ($script:Stats.Failed -gt 0) { "ERROR" } else { "INFO" })
    Write-DeltaCrownLog "  Total size:   ${totalMB}MB" "INFO"

    if ($script:Stats.Failed -gt 0) {
        Write-DeltaCrownLog "" "INFO"
        Write-DeltaCrownLog "FAILED FILES:" "ERROR"
        foreach ($entry in ($script:MigrationLog | Where-Object { $_.Status -eq "Failed" })) {
            Write-DeltaCrownLog "  ❌ $($entry.FileName): $($entry.Error)" "ERROR"
        }
    }

    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "═══════════════════════════════════════════════════" "STAGE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-DeltaCrownLog "Starting Document Migration" "STAGE"
Write-DeltaCrownLog "Mode: $($PSCmdlet.ParameterSetName) | Environment: $Environment" "INFO"

if ($WhatIfPreference) {
    Write-DeltaCrownLog "*** DRY RUN MODE — No files will be copied ***" "WARNING"
}

# Load mapping
$mappings = @()

if ($PSCmdlet.ParameterSetName -eq "CsvFile") {
    Write-DeltaCrownLog "Loading file mappings from: $MappingFile" "INFO"
    $csv = Import-Csv -Path $MappingFile -Encoding UTF8

    # Filter by priority if specified
    if ($Priority -gt 0) {
        $csv = $csv | Where-Object { [int]$_.Priority -le $Priority }
        Write-DeltaCrownLog "Filtered to priority ≤ $Priority`: $($csv.Count) mappings" "INFO"
    }

    # Filter out already-completed mappings
    $csv = $csv | Where-Object { $_.Status -ne "completed" }

    $mappings = $csv
    Write-DeltaCrownLog "Loaded $($mappings.Count) folder mappings to process" "INFO"
}
else {
    $mappings = @([PSCustomObject]@{
        SourceSite          = $SourceUrl
        SourceLibrary       = $SourceLibrary
        SourceFolder        = $SourceFolder
        DestinationSite     = $DestUrl
        DestinationLibrary  = $DestLibrary
        DestinationFolder   = $DestFolder
        Priority            = 1
        Status              = "pending"
        Notes               = "Single folder migration"
    })
}

if ($mappings.Count -eq 0) {
    Write-DeltaCrownLog "No mappings to process (all may be completed or filtered)" "WARNING"
    exit 0
}

# Collect unique source and destination sites for auth
$sourceSites = $mappings | Select-Object -ExpandProperty SourceSite -Unique
$destSites = $mappings | Select-Object -ExpandProperty DestinationSite -Unique

Write-DeltaCrownLog "" "INFO"
Write-DeltaCrownLog "SOURCE sites ($($sourceSites.Count)):" "INFO"
foreach ($s in $sourceSites) { Write-DeltaCrownLog "  📤 $s" "INFO" }
Write-DeltaCrownLog "DESTINATION sites ($($destSites.Count)):" "INFO"
foreach ($d in $destSites) { Write-DeltaCrownLog "  📥 $d" "INFO" }
Write-DeltaCrownLog "" "INFO"

# Process each mapping
$mappingIndex = 0
foreach ($mapping in $mappings) {
    $mappingIndex++
    Write-DeltaCrownLog "" "INFO"
    Write-DeltaCrownLog "[$mappingIndex/$($mappings.Count)] $($mapping.SourceFolder) → $($mapping.DestinationSite)/$($mapping.DestinationLibrary)/$($mapping.DestinationFolder)" "STAGE"

    if ($mapping.Notes) {
        Write-DeltaCrownLog "  Notes: $($mapping.Notes)" "DEBUG"
    }

    # Get source files
    Write-DeltaCrownLog "  Listing source files..." "INFO"
    $sourceFiles = Get-SourceFiles -SiteUrl $mapping.SourceSite -Library $mapping.SourceLibrary -FolderPath $mapping.SourceFolder

    if ($sourceFiles.Count -eq 0) {
        Write-DeltaCrownLog "  ⚠️  No files found in source folder: $($mapping.SourceFolder)" "WARNING"
        continue
    }

    Write-DeltaCrownLog "  Found $($sourceFiles.Count) files" "INFO"

    # Copy each file
    foreach ($file in $sourceFiles) {
        Copy-FileToDestination `
            -SourceFile $file `
            -SourceSiteUrl $mapping.SourceSite `
            -DestSiteUrl $mapping.DestinationSite `
            -DestLibrary $mapping.DestinationLibrary `
            -DestFolder $mapping.DestinationFolder
    }

    # Verify if requested
    if ($VerifyAfterCopy -and -not $WhatIfPreference) {
        Write-DeltaCrownLog "  Verifying migration integrity..." "INFO"
        Test-MigrationIntegrity `
            -DestSiteUrl $mapping.DestinationSite `
            -DestLibrary $mapping.DestinationLibrary `
            -DestFolder $mapping.DestinationFolder `
            -ExpectedFileCount $sourceFiles.Count
    }
}

# Final report
Format-MigrationReport

# Export migration log
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = if ($LogPath) { $LogPath } else { Join-Path $PSScriptRoot "..\logs\migration-$timestamp.json" }
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$exportData = @{
    Timestamp  = Get-Date -Format "o"
    WhatIf     = [bool]$WhatIfPreference
    Stats      = $script:Stats
    Mappings   = $mappings.Count
    Files      = $script:MigrationLog
}

$exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $logFile -Encoding UTF8
Write-DeltaCrownLog "Migration log exported to: $logFile" "INFO"

# Exit code
if ($script:Stats.Failed -gt 0) {
    Write-DeltaCrownLog "⚠️  Migration completed with $($script:Stats.Failed) failures — review log" "WARNING"
    exit 1
}
exit 0
