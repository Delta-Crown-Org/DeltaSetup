#Requires -Modules @{ModuleName="ExchangeOnlineManagement";ModuleVersion="3.0.0"}
<#
.SYNOPSIS
  Create Exchange transport rule to forward help@deltacrown.com to Freshdesk.

.DESCRIPTION
  Creates a transport rule that redirects emails sent to help@deltacrown.com
  to the Freshdesk ingestion mailbox. Follows the same pattern as HTT and Bishops.

.PARAMETER FreshdeskIngestionAddress
  The Freshdesk-provided email address for ticket ingestion (e.g., support@deltacrown.freshdesk.com)

.PARAMETER AdminUPN
  The admin UPN for delegated Exchange Online auth. Default: tyler.granlund-admin@httbrands.com

.PARAMETER Organization
  The DCE organization domain. Default: deltacrown.com

.EXAMPLE
  .\New-DCEFreshdeskTransportRule.ps1 -FreshdeskIngestionAddress "support@deltacrown.freshdesk.com"

.NOTES
  Requires Exchange Online Management module and device authentication.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [string]$FreshdeskIngestionAddress,

    [string]$AdminUPN = "tyler.granlund-admin@httbrands.com",
    [string]$Organization = "deltacrown.com"
)

$ErrorActionPreference = "Stop"
$ruleName = "Freshdesk support forwarding - Delta Crown Extensions"

Write-Host "[EXCHANGE] Connecting to Exchange Online ($Organization)..." -ForegroundColor Cyan
Connect-ExchangeOnline -UserPrincipalName $AdminUPN -DelegatedOrganization "deltacrown.onmicrosoft.com" -ShowBanner:$false

# Check if rule already exists
$existing = Get-TransportRule -Identity $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Warning "Transport rule '$ruleName' already exists. State: $($existing.State)"
    Write-Host "[EXCHANGE] To update the forwarding target, remove the rule first:" -ForegroundColor Yellow
    Write-Host "  Remove-TransportRule -Identity '$ruleName' -Confirm:`$false"
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    exit 1
}

if ($PSCmdlet.ShouldProcess($ruleName, "Create transport rule forwarding help@ to $FreshdeskIngestionAddress")) {
    Write-Host "[EXCHANGE] Creating transport rule '$ruleName'..." -ForegroundColor Cyan

    New-TransportRule -Name $ruleName `
        -SentTo "help@deltacrown.com" `
        -RedirectMessageTo $FreshdeskIngestionAddress `
        -Mode Enforce `
        -Priority 0 `
        -Comments "Route DCE support email to Freshdesk ticket ingestion. Created $(Get-Date -Format 'yyyy-MM-dd')." `
        -ErrorAction Stop

    Write-Host "[EXCHANGE] Transport rule created successfully." -ForegroundColor Green

    # Verify
    $rule = Get-TransportRule -Identity $ruleName
    Write-Host "[EXCHANGE] Rule state: $($rule.State)" -ForegroundColor Cyan
    Write-Host "[EXCHANGE] SentTo: help@deltacrown.com" -ForegroundColor Cyan
    Write-Host "[EXCHANGE] RedirectTo: $FreshdeskIngestionAddress" -ForegroundColor Cyan
}

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "[EXCHANGE] Done." -ForegroundColor Green
