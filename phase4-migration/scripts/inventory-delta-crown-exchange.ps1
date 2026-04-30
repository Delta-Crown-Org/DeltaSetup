<#
.SYNOPSIS
Read-only Exchange Online inventory for the Delta Crown tenant.

.DESCRIPTION
Connects to Exchange Online and exports mail resource metadata to local-only
CSV/JSON outputs. The script uses Exchange Online read cmdlets only. Raw outputs
may contain names, email addresses, aliases, and permissions; do not commit raw
outputs.
#>

[CmdletBinding()]
param(
    [string]$Organization = "deltacrown.com",
    [string]$OutputPath = ".local/reports/tenant-inventory/exchange",
    [string]$UserPrincipalName = "",
    [switch]$UseDeviceAuthentication,
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

function Connect-ExchangeInventory {
    param(
        [string]$Org,
        [string]$Upn,
        [switch]$Device,
        [switch]$Delegated
    )
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $params = @{
        Organization       = $Org
        ShowBanner         = $false
        ShowProgress       = $true
        CommandName        = @(
            "Get-OrganizationConfig",
            "Get-AcceptedDomain",
            "Get-EXOMailbox",
            "Get-Recipient",
            "Get-DistributionGroup",
            "Get-DistributionGroupMember",
            "Get-DynamicDistributionGroup",
            "Get-MailboxPermission",
            "Get-RecipientPermission",
            "Get-MailboxAutoReplyConfiguration",
            "Get-TransportRule",
            "Get-InboundConnector",
            "Get-OutboundConnector"
        )
    }
    if ($Delegated) {
        $params.Remove("Organization")
        $params.DelegatedOrganization = $Org
    }
    if ($Upn) { $params.UserPrincipalName = $Upn }
    if ($Device) { $params.Device = $true }
    Write-InventoryLog "Connecting to Exchange Online organization $Org"
    Connect-ExchangeOnline @params
}

function Select-MailboxSummary {
    param([object]$Mailbox)
    [pscustomobject]@{
        DisplayName          = $Mailbox.DisplayName
        PrimarySmtpAddress   = [string]$Mailbox.PrimarySmtpAddress
        RecipientTypeDetails = [string]$Mailbox.RecipientTypeDetails
        Alias                = $Mailbox.Alias
        HiddenFromAddressListsEnabled = $Mailbox.HiddenFromAddressListsEnabled
        WhenCreated          = $Mailbox.WhenCreated
        WhenChanged          = $Mailbox.WhenChanged
        EmailAddresses       = ($Mailbox.EmailAddresses -join ";")
    }
}

function Select-RecipientSummary {
    param([object]$Recipient)
    [pscustomobject]@{
        DisplayName          = $Recipient.DisplayName
        PrimarySmtpAddress   = [string]$Recipient.PrimarySmtpAddress
        RecipientType        = [string]$Recipient.RecipientType
        RecipientTypeDetails = [string]$Recipient.RecipientTypeDetails
        Alias                = $Recipient.Alias
        HiddenFromAddressListsEnabled = $Recipient.HiddenFromAddressListsEnabled
        EmailAddresses       = ($Recipient.EmailAddresses -join ";")
    }
}

function Select-DistributionGroupSummary {
    param([object]$Group)
    [pscustomobject]@{
        DisplayName        = $Group.DisplayName
        PrimarySmtpAddress = [string]$Group.PrimarySmtpAddress
        Alias              = $Group.Alias
        ManagedBy          = ($Group.ManagedBy -join ";")
        MemberJoinRestriction  = [string]$Group.MemberJoinRestriction
        MemberDepartRestriction = [string]$Group.MemberDepartRestriction
        HiddenFromAddressListsEnabled = $Group.HiddenFromAddressListsEnabled
        EmailAddresses     = ($Group.EmailAddresses -join ";")
    }
}

function Select-DynamicDistributionGroupSummary {
    param([object]$Group)
    [pscustomobject]@{
        DisplayName        = $Group.DisplayName
        PrimarySmtpAddress = [string]$Group.PrimarySmtpAddress
        Alias              = $Group.Alias
        RecipientFilter    = $Group.RecipientFilter
        ManagedBy          = ($Group.ManagedBy -join ";")
        HiddenFromAddressListsEnabled = $Group.HiddenFromAddressListsEnabled
        EmailAddresses     = ($Group.EmailAddresses -join ";")
    }
}

function Select-AcceptedDomainSummary {
    param([object]$Domain)
    [pscustomobject]@{
        Name              = $Domain.Name
        DomainName        = [string]$Domain.DomainName
        DomainType        = [string]$Domain.DomainType
        Default           = $Domain.Default
        AddressBookEnabled = $Domain.AddressBookEnabled
    }
}

function Select-TransportRuleSummary {
    param([object]$Rule)
    [pscustomobject]@{
        Name     = $Rule.Name
        State    = [string]$Rule.State
        Mode     = [string]$Rule.Mode
        Priority = $Rule.Priority
        Comments = $Rule.Comments
    }
}

function Get-OptionalProperty {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Select-ConnectorSummary {
    param([object]$Connector, [string]$Direction)
    [pscustomobject]@{
        Direction = $Direction
        Name      = $Connector.Name
        Enabled   = Get-OptionalProperty $Connector "Enabled"
        ConnectorType = [string](Get-OptionalProperty $Connector "ConnectorType")
        SenderDomains = ((Get-OptionalProperty $Connector "SenderDomains") -join ";")
        RecipientDomains = ((Get-OptionalProperty $Connector "RecipientDomains") -join ";")
        SmartHosts = ((Get-OptionalProperty $Connector "SmartHosts") -join ";")
    }
}

function Get-SafePermissions {
    param([object[]]$Mailboxes)
    $mailboxPermissionRows = @()
    $recipientPermissionRows = @()

    foreach ($mailbox in $Mailboxes) {
        $identity = [string]$mailbox.PrimarySmtpAddress
        if (-not $identity) { continue }
        Write-InventoryLog "Reading permissions for $identity"
        $mailboxPermissionRows += Get-MailboxPermission -Identity $identity -ErrorAction SilentlyContinue |
            Where-Object { -not $_.IsInherited } |
            Select-Object @{Name="Mailbox";Expression={$identity}}, User, AccessRights, Deny, IsInherited
        $recipientPermissionRows += Get-RecipientPermission -Identity $identity -ErrorAction SilentlyContinue |
            Where-Object { $_.Trustee -ne "NT AUTHORITY\\SELF" } |
            Select-Object @{Name="Mailbox";Expression={$identity}}, Trustee, AccessRights, IsInherited
    }
    return [pscustomobject]@{
        MailboxPermissions   = @($mailboxPermissionRows)
        RecipientPermissions = @($recipientPermissionRows)
    }
}

function Build-Summary {
    param(
        [object]$OrganizationConfig,
        [object[]]$AcceptedDomains,
        [object[]]$Mailboxes,
        [object[]]$Recipients,
        [object[]]$DistributionGroups,
        [object[]]$DynamicDistributionGroups,
        [object[]]$TransportRules,
        [object[]]$InboundConnectors,
        [object[]]$OutboundConnectors,
        [object[]]$MailboxPermissions,
        [object[]]$RecipientPermissions
    )

    $expectedShared = @("operations@deltacrown.com", "bookings@deltacrown.com", "info@deltacrown.com")
    $mailboxAddresses = @($Mailboxes | ForEach-Object { ([string]$_.PrimarySmtpAddress).ToLowerInvariant() })
    $sharedMailboxes = @($Mailboxes | Where-Object { [string]$_.RecipientTypeDetails -eq "SharedMailbox" })
    $userMailboxes = @($Mailboxes | Where-Object { [string]$_.RecipientTypeDetails -eq "UserMailbox" })
    $expectedRows = foreach ($address in $expectedShared) {
        $match = $Mailboxes | Where-Object { ([string]$_.PrimarySmtpAddress).ToLowerInvariant() -eq $address } | Select-Object -First 1
        [pscustomobject]@{
            Address = $address
            Present = [bool]$match
            RecipientTypeDetails = if ($match) { [string]$match.RecipientTypeDetails } else { "" }
        }
    }

    [pscustomobject]@{
        GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
        Organization = $OrganizationConfig.Name
        AcceptedDomainCount = Safe-Count $AcceptedDomains
        MailboxCount = Safe-Count $Mailboxes
        UserMailboxCount = Safe-Count $userMailboxes
        SharedMailboxCount = Safe-Count $sharedMailboxes
        RecipientCount = Safe-Count $Recipients
        DistributionGroupCount = Safe-Count $DistributionGroups
        DynamicDistributionGroupCount = Safe-Count $DynamicDistributionGroups
        TransportRuleCount = Safe-Count $TransportRules
        InboundConnectorCount = Safe-Count $InboundConnectors
        OutboundConnectorCount = Safe-Count $OutboundConnectors
        MailboxPermissionRows = Safe-Count $MailboxPermissions
        RecipientPermissionRows = Safe-Count $RecipientPermissions
        ExpectedSharedMailboxes = @($expectedRows)
        AcceptedDomains = @($AcceptedDomains | Select-Object Name, DomainName, DomainType, Default)
        DynamicDistributionGroups = @($DynamicDistributionGroups | Select-Object DisplayName, PrimarySmtpAddress, RecipientFilter)
        TransportRules = @($TransportRules | Select-Object Name, State, Mode, Priority)
        Connectors = @(
            $InboundConnectors | ForEach-Object { [pscustomobject]@{ Direction = "Inbound"; Name = $_.Name; Enabled = $_.Enabled; ConnectorType = [string]$_.ConnectorType } }
            $OutboundConnectors | ForEach-Object { [pscustomobject]@{ Direction = "Outbound"; Name = $_.Name; Enabled = $_.Enabled; ConnectorType = [string]$_.ConnectorType } }
        )
    }
}

Ensure-OutputPath -Path $OutputPath
$connected = $false
try {
    Connect-ExchangeInventory -Org $Organization -Upn $UserPrincipalName -Device:$UseDeviceAuthentication -Delegated:$UseDelegatedOrganization
    $connected = $true

    Write-InventoryLog "Reading organization config"
    $organizationConfig = Get-OrganizationConfig

    Write-InventoryLog "Reading accepted domains"
    $acceptedDomains = @(Get-AcceptedDomain | ForEach-Object { Select-AcceptedDomainSummary $_ })
    $domainMatched = @($acceptedDomains | Where-Object { ([string]$_.DomainName).ToLowerInvariant() -eq $Organization.ToLowerInvariant() }).Count -gt 0
    if (-not $domainMatched) {
        $seenDomains = ($acceptedDomains | ForEach-Object { [string]$_.DomainName }) -join ", "
        throw "Connected Exchange context does not include expected domain '$Organization'. Seen accepted domains: $seenDomains. Refusing to inventory to avoid cross-tenant data capture."
    }

    Write-InventoryLog "Reading mailboxes"
    $mailboxes = @(Get-EXOMailbox -ResultSize Unlimited -Properties EmailAddresses,HiddenFromAddressListsEnabled,WhenCreated,WhenChanged |
        ForEach-Object { Select-MailboxSummary $_ })

    Write-InventoryLog "Reading recipients"
    $recipients = @(Get-Recipient -ResultSize Unlimited |
        ForEach-Object { Select-RecipientSummary $_ })

    Write-InventoryLog "Reading distribution groups"
    $distributionGroups = @(Get-DistributionGroup -ResultSize Unlimited |
        ForEach-Object { Select-DistributionGroupSummary $_ })

    Write-InventoryLog "Reading distribution group members"
    $distributionGroupMembers = @()
    foreach ($group in $distributionGroups) {
        $distributionGroupMembers += Get-DistributionGroupMember -Identity $group.PrimarySmtpAddress -ResultSize Unlimited -ErrorAction SilentlyContinue |
            Select-Object @{Name="Group";Expression={$group.PrimarySmtpAddress}}, DisplayName, PrimarySmtpAddress, RecipientType
    }

    Write-InventoryLog "Reading dynamic distribution groups"
    $dynamicDistributionGroups = @(Get-DynamicDistributionGroup -ResultSize Unlimited |
        ForEach-Object { Select-DynamicDistributionGroupSummary $_ })

    Write-InventoryLog "Reading transport rules"
    $transportRules = @(Get-TransportRule -ErrorAction SilentlyContinue |
        ForEach-Object { Select-TransportRuleSummary $_ })

    Write-InventoryLog "Reading connectors"
    $inboundConnectors = @(Get-InboundConnector -ErrorAction SilentlyContinue |
        ForEach-Object { Select-ConnectorSummary $_ "Inbound" })
    $outboundConnectors = @(Get-OutboundConnector -ErrorAction SilentlyContinue |
        ForEach-Object { Select-ConnectorSummary $_ "Outbound" })

    Write-InventoryLog "Reading shared mailbox permissions"
    $sharedMailboxes = @($mailboxes | Where-Object { [string]$_.RecipientTypeDetails -eq "SharedMailbox" })
    $permissions = Get-SafePermissions -Mailboxes $sharedMailboxes

    Write-InventoryLog "Reading shared mailbox auto-replies"
    $autoReplies = @()
    foreach ($mailbox in $sharedMailboxes) {
        $autoReplies += Get-MailboxAutoReplyConfiguration -Identity $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue |
            Select-Object @{Name="Mailbox";Expression={$mailbox.PrimarySmtpAddress}}, AutoReplyState, ExternalAudience
    }

    Export-Rows -Rows $acceptedDomains -Path (Join-Path $OutputPath "exchange-accepted-domains.csv")
    Export-Rows -Rows $mailboxes -Path (Join-Path $OutputPath "exchange-mailboxes.csv")
    Export-Rows -Rows $recipients -Path (Join-Path $OutputPath "exchange-recipients.csv")
    Export-Rows -Rows $distributionGroups -Path (Join-Path $OutputPath "exchange-distribution-groups.csv")
    Export-Rows -Rows $distributionGroupMembers -Path (Join-Path $OutputPath "exchange-distribution-group-members.csv")
    Export-Rows -Rows $dynamicDistributionGroups -Path (Join-Path $OutputPath "exchange-dynamic-distribution-groups.csv")
    Export-Rows -Rows $transportRules -Path (Join-Path $OutputPath "exchange-transport-rules.csv")
    Export-Rows -Rows $inboundConnectors -Path (Join-Path $OutputPath "exchange-inbound-connectors.csv")
    Export-Rows -Rows $outboundConnectors -Path (Join-Path $OutputPath "exchange-outbound-connectors.csv")
    Export-Rows -Rows $permissions.MailboxPermissions -Path (Join-Path $OutputPath "exchange-shared-mailbox-permissions.csv")
    Export-Rows -Rows $permissions.RecipientPermissions -Path (Join-Path $OutputPath "exchange-shared-recipient-permissions.csv")
    Export-Rows -Rows $autoReplies -Path (Join-Path $OutputPath "exchange-shared-mailbox-auto-replies.csv")

    $summary = Build-Summary `
        -OrganizationConfig $organizationConfig `
        -AcceptedDomains $acceptedDomains `
        -Mailboxes $mailboxes `
        -Recipients $recipients `
        -DistributionGroups $distributionGroups `
        -DynamicDistributionGroups $dynamicDistributionGroups `
        -TransportRules $transportRules `
        -InboundConnectors $inboundConnectors `
        -OutboundConnectors $outboundConnectors `
        -MailboxPermissions $permissions.MailboxPermissions `
        -RecipientPermissions $permissions.RecipientPermissions

    $summary | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutputPath "exchange-summary.json") -Encoding UTF8
    Write-InventoryLog "Wrote Exchange inventory outputs to $OutputPath"
}
finally {
    if ($connected) {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Write-InventoryLog "Disconnected from Exchange Online"
    }
}
