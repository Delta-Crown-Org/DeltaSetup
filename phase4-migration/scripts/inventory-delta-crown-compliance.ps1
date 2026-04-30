<#
.SYNOPSIS
Read-only Purview / Security & Compliance inventory for Delta Crown.

.DESCRIPTION
Connects to Exchange Online Protection / Purview PowerShell and exports DLP,
sensitivity label, and label policy metadata to local-only outputs. Uses read
cmdlets only. Raw outputs may include tenant policy details and should not be
committed.
#>

[CmdletBinding()]
param(
    [string]$Organization = "deltacrown.com",
    [string]$OutputPath = ".local/reports/tenant-inventory/compliance",
    [string]$UserPrincipalName = "",
    [switch]$UseDelegatedOrganization
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Connect-ComplianceInventory {
    param(
        [string]$Org,
        [string]$Upn,
        [switch]$Delegated
    )
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $params = @{
        ShowBanner   = $false
        CommandName  = @(
            "Get-DlpCompliancePolicy",
            "Get-DlpComplianceRule",
            "Get-Label",
            "Get-LabelPolicy",
            "Get-RetentionCompliancePolicy",
            "Get-RetentionComplianceRule"
        )
    }
    if ($Delegated) { $params.DelegatedOrganization = $Org }
    else { $params.Organization = $Org }
    if ($Upn) { $params.UserPrincipalName = $Upn }
    Write-InventoryLog "Connecting to Purview/IPPSSession for $Org"
    Connect-IPPSSession @params
}

function Invoke-InventoryCommand {
    param(
        [Parameter(Mandatory)] [string]$CommandName,
        [scriptblock]$Transform
    )
    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        return [pscustomobject]@{
            Rows = @()
            Error = "$CommandName is not available in this session."
        }
    }
    try {
        $rows = & $CommandName -ErrorAction Stop
        if ($Transform) {
            $rows = @($rows | ForEach-Object { & $Transform $_ })
        }
        return [pscustomobject]@{ Rows = @($rows); Error = "" }
    }
    catch {
        return [pscustomobject]@{ Rows = @(); Error = $_.Exception.Message }
    }
}

function Get-OptionalProperty {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Select-DlpPolicy {
    param([object]$Policy)
    [pscustomobject]@{
        Name        = Get-OptionalProperty $Policy "Name"
        Mode        = [string](Get-OptionalProperty $Policy "Mode")
        State       = [string](Get-OptionalProperty $Policy "State")
        Workload    = ((Get-OptionalProperty $Policy "Workload") -join ";")
        ExchangeLocation = ((Get-OptionalProperty $Policy "ExchangeLocation") -join ";")
        SharePointLocation = ((Get-OptionalProperty $Policy "SharePointLocation") -join ";")
        TeamsLocation = ((Get-OptionalProperty $Policy "TeamsLocation") -join ";")
        OneDriveLocation = ((Get-OptionalProperty $Policy "OneDriveLocation") -join ";")
        WhenCreatedUTC = Get-OptionalProperty $Policy "WhenCreatedUTC"
        WhenChangedUTC = Get-OptionalProperty $Policy "WhenChangedUTC"
        Comment = Get-OptionalProperty $Policy "Comment"
    }
}

function Select-DlpRule {
    param([object]$Rule)
    [pscustomobject]@{
        Name        = $Rule.Name
        Policy      = $Rule.Policy
        Disabled    = $Rule.Disabled
        Mode        = [string]$Rule.Mode
        Priority    = $Rule.Priority
        BlockAccess = $Rule.BlockAccess
        NotifyUser  = ($Rule.NotifyUser -join ";")
        GenerateIncidentReport = ($Rule.GenerateIncidentReport -join ";")
        WhenCreatedUTC = $Rule.WhenCreatedUTC
        WhenChangedUTC = $Rule.WhenChangedUTC
    }
}

function Select-Label {
    param([object]$Label)
    [pscustomobject]@{
        Name        = $Label.Name
        DisplayName = $Label.DisplayName
        Comment     = $Label.Comment
        Disabled    = $Label.Disabled
        Priority    = $Label.Priority
        Tooltip     = $Label.Tooltip
        WhenCreatedUTC = $Label.WhenCreatedUTC
        WhenChangedUTC = $Label.WhenChangedUTC
    }
}

function Select-LabelPolicy {
    param([object]$Policy)
    [pscustomobject]@{
        Name        = $Policy.Name
        Enabled     = $Policy.Enabled
        Labels      = ($Policy.Labels -join ";")
        ExchangeLocation = ($Policy.ExchangeLocation -join ";")
        SharePointLocation = ($Policy.SharePointLocation -join ";")
        OneDriveLocation = ($Policy.OneDriveLocation -join ";")
        WhenCreatedUTC = $Policy.WhenCreatedUTC
        WhenChangedUTC = $Policy.WhenChangedUTC
    }
}

function Select-RetentionPolicy {
    param([object]$Policy)
    [pscustomobject]@{
        Name        = $Policy.Name
        Enabled     = $Policy.Enabled
        Mode        = [string]$Policy.Mode
        Workload    = ($Policy.Workload -join ";")
        ExchangeLocation = ($Policy.ExchangeLocation -join ";")
        SharePointLocation = ($Policy.SharePointLocation -join ";")
        OneDriveLocation = ($Policy.OneDriveLocation -join ";")
        WhenCreatedUTC = $Policy.WhenCreatedUTC
        WhenChangedUTC = $Policy.WhenChangedUTC
    }
}

function Select-RetentionRule {
    param([object]$Rule)
    [pscustomobject]@{
        Name        = $Rule.Name
        Policy      = $Rule.Policy
        Disabled    = $Rule.Disabled
        RetentionDuration = $Rule.RetentionDuration
        RetentionComplianceAction = [string]$Rule.RetentionComplianceAction
        WhenCreatedUTC = $Rule.WhenCreatedUTC
        WhenChangedUTC = $Rule.WhenChangedUTC
    }
}

Ensure-OutputPath -Path $OutputPath
$connected = $false
try {
    Connect-ComplianceInventory -Org $Organization -Upn $UserPrincipalName -Delegated:$UseDelegatedOrganization
    $connected = $true

    Write-InventoryLog "Reading DLP policies"
    $dlpPoliciesResult = Invoke-InventoryCommand -CommandName "Get-DlpCompliancePolicy" -Transform ${function:Select-DlpPolicy}
    Write-InventoryLog "Reading DLP rules"
    $dlpRulesResult = Invoke-InventoryCommand -CommandName "Get-DlpComplianceRule" -Transform ${function:Select-DlpRule}
    Write-InventoryLog "Reading sensitivity labels"
    $labelsResult = Invoke-InventoryCommand -CommandName "Get-Label" -Transform ${function:Select-Label}
    Write-InventoryLog "Reading label policies"
    $labelPoliciesResult = Invoke-InventoryCommand -CommandName "Get-LabelPolicy" -Transform ${function:Select-LabelPolicy}
    Write-InventoryLog "Reading retention policies"
    $retentionPoliciesResult = Invoke-InventoryCommand -CommandName "Get-RetentionCompliancePolicy" -Transform ${function:Select-RetentionPolicy}
    Write-InventoryLog "Reading retention rules"
    $retentionRulesResult = Invoke-InventoryCommand -CommandName "Get-RetentionComplianceRule" -Transform ${function:Select-RetentionRule}

    $errors = @()
    foreach ($entry in @(
        @{ Scope = "DLP policies"; Result = $dlpPoliciesResult },
        @{ Scope = "DLP rules"; Result = $dlpRulesResult },
        @{ Scope = "Sensitivity labels"; Result = $labelsResult },
        @{ Scope = "Label policies"; Result = $labelPoliciesResult },
        @{ Scope = "Retention policies"; Result = $retentionPoliciesResult },
        @{ Scope = "Retention rules"; Result = $retentionRulesResult }
    )) {
        if ($entry.Result.Error) {
            $errors += [pscustomobject]@{ Scope = $entry.Scope; Error = $entry.Result.Error }
        }
    }

    Export-Rows -Rows $dlpPoliciesResult.Rows -Path (Join-Path $OutputPath "compliance-dlp-policies.csv")
    Export-Rows -Rows $dlpRulesResult.Rows -Path (Join-Path $OutputPath "compliance-dlp-rules.csv")
    Export-Rows -Rows $labelsResult.Rows -Path (Join-Path $OutputPath "compliance-sensitivity-labels.csv")
    Export-Rows -Rows $labelPoliciesResult.Rows -Path (Join-Path $OutputPath "compliance-label-policies.csv")
    Export-Rows -Rows $retentionPoliciesResult.Rows -Path (Join-Path $OutputPath "compliance-retention-policies.csv")
    Export-Rows -Rows $retentionRulesResult.Rows -Path (Join-Path $OutputPath "compliance-retention-rules.csv")
    Export-Rows -Rows $errors -Path (Join-Path $OutputPath "compliance-inventory-errors.csv")

    $summary = [pscustomobject]@{
        GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
        Organization = $Organization
        DlpPolicyCount = Safe-Count $dlpPoliciesResult.Rows
        DlpRuleCount = Safe-Count $dlpRulesResult.Rows
        SensitivityLabelCount = Safe-Count $labelsResult.Rows
        LabelPolicyCount = Safe-Count $labelPoliciesResult.Rows
        RetentionPolicyCount = Safe-Count $retentionPoliciesResult.Rows
        RetentionRuleCount = Safe-Count $retentionRulesResult.Rows
        ErrorCount = Safe-Count $errors
        DlpPolicies = @($dlpPoliciesResult.Rows | Select-Object Name, Mode, State, Workload)
        Labels = @($labelsResult.Rows | Select-Object DisplayName, Disabled, Priority)
        LabelPolicies = @($labelPoliciesResult.Rows | Select-Object Name, Enabled, Labels)
        Errors = $errors
    }
    $summary | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutputPath "compliance-summary.json") -Encoding UTF8
    Write-InventoryLog "Wrote compliance inventory outputs to $OutputPath"
}
finally {
    if ($connected) {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Write-InventoryLog "Disconnected from Purview/IPPSSession"
    }
}
