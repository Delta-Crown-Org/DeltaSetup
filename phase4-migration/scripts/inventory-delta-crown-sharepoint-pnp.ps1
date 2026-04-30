<#
.SYNOPSIS
Enhanced read-only SharePoint/PnP inventory for Delta Crown.

.DESCRIPTION
Uses PnP.PowerShell delegated auth to inventory SharePoint tenant sites,
site/web metadata, lists/libraries, list-level unique permission flags, site
groups, group member counts, and web role assignment summaries. The script does
not read list items, file contents, or item-level permissions. Raw outputs are
local-only and must not be committed.
#>

[CmdletBinding()]
param(
    [string]$Tenant = "deltacrown.com",
    [string]$AdminUrl = "https://deltacrown-admin.sharepoint.com",
    [Parameter(Mandatory)]
    [string]$ClientId,
    [string]$OutputPath = ".local/reports/tenant-inventory/sharepoint-pnp",
    [switch]$IncludeOneDriveSites
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RiskListNames = @("Client Records", "Service History", "Feedback")
$RiskLibraryNames = @("Consent Forms")

function Write-InventoryLog {
    param([string]$Message)
    $timestamp = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    Write-Host "[$timestamp] $Message"
}

function Ensure-OutputPath {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Export-Rows {
    param(
        [object[]]$Rows,
        [Parameter(Mandatory)] [string]$Path
    )
    @($Rows) | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
}

function Safe-Count {
    param([object[]]$Rows)
    if ($null -eq $Rows) { return 0 }
    return @($Rows).Count
}

function Get-OptionalProperty {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Join-Values {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    if ($Value -is [string]) { return $Value }
    return (@($Value) | ForEach-Object { [string]$_ }) -join ";"
}

function Connect-PnPInventory {
    param([string]$Url)
    $params = @{
        Url         = $Url
        Tenant      = $Tenant
        Interactive = $true
        ErrorAction = "Stop"
    }
    if ($ClientId) { $params.ClientId = $ClientId }
    Connect-PnPOnline @params
}

function Select-TenantSite {
    param([object]$Site)
    [pscustomobject]@{
        Url               = Get-OptionalProperty $Site "Url"
        Title             = Get-OptionalProperty $Site "Title"
        Template          = Get-OptionalProperty $Site "Template"
        Owner             = Get-OptionalProperty $Site "Owner"
        StorageUsageCurrent = Get-OptionalProperty $Site "StorageUsageCurrent"
        StorageQuota      = Get-OptionalProperty $Site "StorageQuota"
        SharingCapability = [string](Get-OptionalProperty $Site "SharingCapability")
        LockState         = [string](Get-OptionalProperty $Site "LockState")
        Status            = [string](Get-OptionalProperty $Site "Status")
        GroupId           = [string](Get-OptionalProperty $Site "GroupId")
        HubSiteId         = [string](Get-OptionalProperty $Site "HubSiteId")
        IsHubSite         = [string](Get-OptionalProperty $Site "IsHubSite")
        LastContentModifiedDate = Get-OptionalProperty $Site "LastContentModifiedDate"
        TimeZoneId        = Get-OptionalProperty $Site "TimeZoneId"
        DenyAddAndCustomizePages = [string](Get-OptionalProperty $Site "DenyAddAndCustomizePages")
    }
}

function Get-WebSummary {
    param([string]$SiteUrl)
    $web = Get-PnPWeb -Includes Title,Url,Description,HasUniqueRoleAssignments,AssociatedOwnerGroup,AssociatedMemberGroup,AssociatedVisitorGroup
    [pscustomobject]@{
        SiteUrl             = $SiteUrl
        WebTitle            = $web.Title
        WebUrl              = $web.Url
        Description         = $web.Description
        HasUniqueRoleAssignments = $web.HasUniqueRoleAssignments
        OwnerGroup          = if ($web.AssociatedOwnerGroup) { $web.AssociatedOwnerGroup.Title } else { "" }
        MemberGroup         = if ($web.AssociatedMemberGroup) { $web.AssociatedMemberGroup.Title } else { "" }
        VisitorGroup        = if ($web.AssociatedVisitorGroup) { $web.AssociatedVisitorGroup.Title } else { "" }
    }
}

function Get-ListSummaries {
    param([string]$SiteUrl)
    $lists = @(Get-PnPList -Includes Title,RootFolder,BaseTemplate,BaseType,Hidden,ItemCount,HasUniqueRoleAssignments,EnableVersioning,EnableMinorVersions,ContentTypesEnabled)
    foreach ($list in $lists) {
        $rootUrl = if ($list.RootFolder) { $list.RootFolder.ServerRelativeUrl } else { "" }
        $isLibrary = ([string]$list.BaseType -eq "DocumentLibrary")
        $isRiskName = ($RiskListNames -contains $list.Title) -or ($RiskLibraryNames -contains $list.Title)
        [pscustomobject]@{
            SiteUrl          = $SiteUrl
            Title            = $list.Title
            BaseType         = [string]$list.BaseType
            BaseTemplate     = $list.BaseTemplate
            Hidden           = $list.Hidden
            ItemCount        = $list.ItemCount
            RootFolderUrl    = $rootUrl
            IsDocumentLibrary = $isLibrary
            HasUniqueRoleAssignments = $list.HasUniqueRoleAssignments
            EnableVersioning = $list.EnableVersioning
            EnableMinorVersions = $list.EnableMinorVersions
            ContentTypesEnabled = $list.ContentTypesEnabled
            IsRiskName       = $isRiskName
        }
    }
}

function Get-GroupSummaries {
    param([string]$SiteUrl)
    $groups = @(Get-PnPGroup -ErrorAction SilentlyContinue)
    foreach ($group in $groups) {
        $members = @()
        try {
            $members = @(Get-PnPGroupMember -Identity $group.Title -ErrorAction Stop)
        }
        catch {
            $members = @()
        }
        [pscustomobject]@{
            SiteUrl     = $SiteUrl
            GroupTitle  = $group.Title
            OwnerTitle  = if ($group.OwnerTitle) { $group.OwnerTitle } else { "" }
            MemberCount = Safe-Count $members
            LoginNames  = Join-Values ($members | ForEach-Object { $_.LoginName })
        }
    }
}

function Get-WebRoleAssignmentSummaries {
    param([string]$SiteUrl)
    $web = Get-PnPWeb -Includes RoleAssignments
    $assignments = @()
    try {
        Get-PnPProperty -ClientObject $web -Property RoleAssignments | Out-Null
        foreach ($assignment in $web.RoleAssignments) {
            Get-PnPProperty -ClientObject $assignment -Property Member,RoleDefinitionBindings | Out-Null
            $assignments += [pscustomobject]@{
                SiteUrl       = $SiteUrl
                PrincipalName = $assignment.Member.Title
                PrincipalType = [string]$assignment.Member.PrincipalType
                Roles         = Join-Values ($assignment.RoleDefinitionBindings | ForEach-Object { $_.Name })
            }
        }
    }
    catch {
        $assignments += [pscustomobject]@{
            SiteUrl       = $SiteUrl
            PrincipalName = "<error>"
            PrincipalType = "Error"
            Roles         = $_.Exception.Message
        }
    }
    return @($assignments)
}

function Build-Summary {
    param(
        [object[]]$TenantSites,
        [object[]]$Webs,
        [object[]]$Lists,
        [object[]]$Groups,
        [object[]]$RoleAssignments,
        [object[]]$Errors
    )
    $riskLists = @($Lists | Where-Object { $_.IsRiskName })
    $uniqueLists = @($Lists | Where-Object { $_.HasUniqueRoleAssignments })
    $externalSharingSites = @($TenantSites | Where-Object { [string]$_.SharingCapability -notin @("Disabled", "ExistingExternalUserSharingOnly", "") })
    $clientServicesSites = @($TenantSites | Where-Object { $_.Url -match "/sites/dce-clientservices$" })
    $brandResourcesMatches = @($TenantSites + $Lists | Where-Object {
        $title = [string](Get-OptionalProperty $_ "Title")
        $url = [string](Get-OptionalProperty $_ "Url")
        $rootFolderUrl = [string](Get-OptionalProperty $_ "RootFolderUrl")
        ($title -match "Brand Resources|Brand Assets") -or
        ($url -match "BrandResources|BrandAssets|Brand%20Assets") -or
        ($rootFolderUrl -match "BrandResources|BrandAssets|Brand Assets|Brand%20Assets")
    })

    [pscustomobject]@{
        GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
        TenantSiteCount = Safe-Count $TenantSites
        WebCount = Safe-Count $Webs
        ListCount = Safe-Count $Lists
        DocumentLibraryCount = Safe-Count (@($Lists | Where-Object { $_.IsDocumentLibrary }))
        RiskNamedListOrLibraryCount = Safe-Count $riskLists
        ListUniquePermissionCount = Safe-Count $uniqueLists
        GroupCount = Safe-Count $Groups
        WebRoleAssignmentCount = Safe-Count $RoleAssignments
        ExternalSharingSiteCount = Safe-Count $externalSharingSites
        ClientServicesSiteCount = Safe-Count $clientServicesSites
        BrandResourceOrAssetNameMatchCount = Safe-Count $brandResourcesMatches
        ErrorCount = Safe-Count $Errors
        TenantSites = @($TenantSites | Select-Object Url,Title,Template,SharingCapability,Owner,GroupId,HubSiteId,IsHubSite)
        RiskNamedLists = @($riskLists | Select-Object SiteUrl,Title,BaseType,ItemCount,HasUniqueRoleAssignments)
        UniquePermissionLists = @($uniqueLists | Select-Object SiteUrl,Title,BaseType,ItemCount)
        Errors = $Errors
    }
}

Ensure-OutputPath -Path $OutputPath
Import-Module PnP.PowerShell -ErrorAction Stop

$tenantSites = @()
$webRows = @()
$listRows = @()
$groupRows = @()
$roleRows = @()
$errors = @()

try {
    Write-InventoryLog "Connecting to SharePoint admin center"
    Connect-PnPInventory -Url $AdminUrl
    Write-InventoryLog "Reading tenant sites"
    $tenantSiteParams = @{ Detailed = $true }
    if ($IncludeOneDriveSites) { $tenantSiteParams.IncludeOneDriveSites = $true }
    $tenantSites = @(Get-PnPTenantSite @tenantSiteParams | ForEach-Object { Select-TenantSite $_ })
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}

foreach ($site in $tenantSites) {
    $siteUrl = $site.Url
    if (-not $siteUrl) { continue }
    Write-InventoryLog "Inventorying site: $siteUrl"
    try {
        Connect-PnPInventory -Url $siteUrl
        $webRows += Get-WebSummary -SiteUrl $siteUrl
        $listRows += Get-ListSummaries -SiteUrl $siteUrl
        $groupRows += Get-GroupSummaries -SiteUrl $siteUrl
        $roleRows += Get-WebRoleAssignmentSummaries -SiteUrl $siteUrl
    }
    catch {
        $errors += [pscustomobject]@{ SiteUrl = $siteUrl; Scope = "site-detail"; Error = $_.Exception.Message }
    }
    finally {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }
}

Export-Rows -Rows $tenantSites -Path (Join-Path $OutputPath "sharepoint-pnp-tenant-sites.csv")
Export-Rows -Rows $webRows -Path (Join-Path $OutputPath "sharepoint-pnp-webs.csv")
Export-Rows -Rows $listRows -Path (Join-Path $OutputPath "sharepoint-pnp-lists.csv")
Export-Rows -Rows $groupRows -Path (Join-Path $OutputPath "sharepoint-pnp-site-groups.csv")
Export-Rows -Rows $roleRows -Path (Join-Path $OutputPath "sharepoint-pnp-web-role-assignments.csv")
Export-Rows -Rows $errors -Path (Join-Path $OutputPath "sharepoint-pnp-errors.csv")

$summary = Build-Summary -TenantSites $tenantSites -Webs $webRows -Lists $listRows -Groups $groupRows -RoleAssignments $roleRows -Errors $errors
$summary | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutputPath "sharepoint-pnp-summary.json") -Encoding UTF8
Write-InventoryLog "Wrote enhanced SharePoint/PnP inventory outputs to $OutputPath"
