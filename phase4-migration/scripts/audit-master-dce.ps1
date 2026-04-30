# ============================================================================
# Audit HTTHQ Master DCE Folder Structure + Permissions
# ============================================================================
# Purpose:
#   Inventory the existing HTTHQ/Shared Documents/Master DCE folder so the team
#   can map real folders into Delta Crown pillar resources before copying,
#   shortcutting, or rebuilding anything in the deltacrown tenant.
#
# Output:
#   reports/master-dce-folder-inventory.csv
#   reports/master-dce-permissions.csv
#   reports/master-dce-summary.md
#
# Notes:
#   - This script is read-only.
#   - It does NOT migrate files.
#   - PnP.PowerShell 3.x may require -ClientId or HTT_PNP_CLIENT_ID.
# ============================================================================

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SiteUrl = "https://httbrands.sharepoint.com/sites/HTTHQ",

    [Parameter()]
    [string]$LibraryName = "Shared Documents",

    [Parameter()]
    [string]$RootFolder = "Master DCE",

    [Parameter()]
    [string]$ClientId = $env:HTT_PNP_CLIENT_ID,

    [Parameter()]
    [string]$Tenant = $(if ($env:HTT_TENANT_ID) { $env:HTT_TENANT_ID } else { "httbrands.onmicrosoft.com" }),

    [Parameter()]
    [string]$OutputDirectory = "reports",

    [Parameter()]
    [switch]$Recursive
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter()][string]$Level = "INFO"
    )

    $color = switch ($Level) {
        "OK" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Ensure-OutputDirectory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }
}

function Connect-HttSharePoint {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter()][string]$AppClientId,
        [Parameter()][string]$TenantName
    )

    Write-Status "Connecting to $Url"
    if ($AppClientId) {
        Connect-PnPOnline -Url $Url -Interactive -ClientId $AppClientId -Tenant $TenantName -ErrorAction Stop
    }
    else {
        Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
    }
    Write-Status "Connected" "OK"
}

function Convert-PrincipalToText {
    param($Principal)

    if (-not $Principal) { return "" }
    if ($Principal.Email) { return $Principal.Email }
    if ($Principal.LoginName) { return $Principal.LoginName }
    return $Principal.Title
}

function Get-ItemPermissions {
    param(
        [Parameter(Mandatory)]$ListItem,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ItemType
    )

    $hasUnique = Get-PnPProperty -ClientObject $ListItem -Property HasUniqueRoleAssignments
    $assignments = Get-PnPProperty -ClientObject $ListItem -Property RoleAssignments

    $rows = @()
    foreach ($assignment in $assignments) {
        $member = Get-PnPProperty -ClientObject $assignment -Property Member
        $bindings = Get-PnPProperty -ClientObject $assignment -Property RoleDefinitionBindings
        $roles = ($bindings | ForEach-Object { $_.Name }) -join "; "

        $rows += [PSCustomObject]@{
            Path = $Path
            ItemType = $ItemType
            HasUniqueRoleAssignments = [bool]$hasUnique
            Principal = Convert-PrincipalToText -Principal $member
            PrincipalTitle = $member.Title
            PrincipalType = $member.PrincipalType
            Roles = $roles
        }
    }

    return $rows
}

function Get-FolderRows {
    param(
        [Parameter(Mandatory)][string]$FolderSiteRelativeUrl,
        [Parameter(Mandatory)][string]$RootSiteRelativeUrl,
        [Parameter(Mandatory)][bool]$IncludeRecursive
    )

    $scope = if ($IncludeRecursive) { "Recursive" } else { "Top level" }
    Write-Status "Scanning $scope folder inventory: $FolderSiteRelativeUrl"

    $folderItems = Get-PnPListItem `
        -List $LibraryName `
        -PageSize 500 `
        -Fields "FileLeafRef", "FileRef", "FSObjType", "Modified", "Editor", "File_x0020_Size" `
        -ScriptBlock { param($items) $items.Context.ExecuteQuery() } |
        Where-Object {
            $fileRef = $_.FieldValues.FileRef
            $isFolder = $_.FieldValues.FSObjType -eq "1"
            if (-not $isFolder) { return $false }
            if ($IncludeRecursive) {
                return $fileRef -like "*/$RootSiteRelativeUrl/*"
            }
            $relative = $fileRef -replace "^.*?/$([regex]::Escape($RootSiteRelativeUrl))/?", ""
            return $fileRef -like "*/$RootSiteRelativeUrl/*" -and $relative -notmatch "/"
        }

    $rows = @()
    $permissionRows = @()

    foreach ($item in $folderItems) {
        $path = $item.FieldValues.FileRef
        $folderUrl = $path -replace "^/sites/HTTHQ/", ""

        $childFiles = Get-PnPFolderItem -FolderSiteRelativeUrl $folderUrl -ItemType File -ErrorAction SilentlyContinue
        $childFolders = Get-PnPFolderItem -FolderSiteRelativeUrl $folderUrl -ItemType Folder -ErrorAction SilentlyContinue
        $hasUnique = Get-PnPProperty -ClientObject $item -Property HasUniqueRoleAssignments

        $rows += [PSCustomObject]@{
            Name = $item.FieldValues.FileLeafRef
            ServerRelativeUrl = $path
            SiteRelativeUrl = $folderUrl
            DirectFileCount = @($childFiles).Count
            DirectFolderCount = @($childFolders).Count
            Modified = $item.FieldValues.Modified
            ModifiedBy = $item.FieldValues.Editor.LookupValue
            HasUniqueRoleAssignments = [bool]$hasUnique
        }

        $permissionRows += Get-ItemPermissions -ListItem $item -Path $path -ItemType "Folder"
    }

    return @{
        Inventory = $rows
        Permissions = $permissionRows
    }
}

function Write-SummaryMarkdown {
    param(
        [Parameter(Mandatory)]$Inventory,
        [Parameter(Mandatory)]$Permissions,
        [Parameter(Mandatory)][string]$Path
    )

    $uniqueCount = @($Inventory | Where-Object { $_.HasUniqueRoleAssignments }).Count
    $principalCount = @($Permissions | Select-Object -ExpandProperty Principal -Unique).Count
    $generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $lines = @(
        "# Master DCE Audit Summary",
        "",
        "Generated: $generated",
        "Source: `$SiteUrl / $LibraryName / $RootFolder`",
        "",
        "## Totals",
        "",
        "- Folders scanned: $(@($Inventory).Count)",
        "- Folders with unique permissions: $uniqueCount",
        "- Unique principals found: $principalCount",
        "",
        "## Top-Level Folder Inventory",
        "",
        "| Folder | Files | Child folders | Unique permissions | Modified | Modified by |",
        "|---|---:|---:|---|---|---|"
    )

    foreach ($folder in ($Inventory | Sort-Object Name)) {
        $lines += "| $($folder.Name) | $($folder.DirectFileCount) | $($folder.DirectFolderCount) | $($folder.HasUniqueRoleAssignments) | $($folder.Modified) | $($folder.ModifiedBy) |"
    }

    $lines += ""
    $lines += "## Next Mapping Decision"
    $lines += ""
    $lines += "Use this audit to decide whether each folder should become:"
    $lines += "- a Delta Crown brand-owned resource,"
    $lines += "- a corporate HTT-owned reference/shortcut,"
    $lines += "- a restricted leadership/finance area,"
    $lines += "- archived historical content, or"
    $lines += "- deleted/deprecated after owner review."

    $lines -join "`n" | Set-Content -Path $Path -Encoding UTF8
}

Ensure-OutputDirectory -Path $OutputDirectory
Connect-HttSharePoint -Url $SiteUrl -AppClientId $ClientId -TenantName $Tenant

$rootSiteRelativeUrl = "$LibraryName/$RootFolder"
$result = Get-FolderRows `
    -FolderSiteRelativeUrl $rootSiteRelativeUrl `
    -RootSiteRelativeUrl $rootSiteRelativeUrl `
    -IncludeRecursive ([bool]$Recursive)

$inventoryPath = Join-Path $OutputDirectory "master-dce-folder-inventory.csv"
$permissionsPath = Join-Path $OutputDirectory "master-dce-permissions.csv"
$summaryPath = Join-Path $OutputDirectory "master-dce-summary.md"

$result.Inventory | Sort-Object Name | Export-Csv -NoTypeInformation -Path $inventoryPath
$result.Permissions | Sort-Object Path, Principal | Export-Csv -NoTypeInformation -Path $permissionsPath
Write-SummaryMarkdown -Inventory $result.Inventory -Permissions $result.Permissions -Path $summaryPath

Write-Status "Inventory written: $inventoryPath" "OK"
Write-Status "Permissions written: $permissionsPath" "OK"
Write-Status "Summary written: $summaryPath" "OK"
Disconnect-PnPOnline -ErrorAction SilentlyContinue
