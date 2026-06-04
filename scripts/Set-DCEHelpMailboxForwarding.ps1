#Requires -Modules @{ModuleName="ExchangeOnlineManagement";ModuleVersion="3.0.0"}
<#
.SYNOPSIS
  Configure forwarding on help@deltacrown.com shared mailbox to Freshdesk.

.DESCRIPTION
  Sets the forwarding address on the help@ shared mailbox so emails are
  delivered to both the mailbox AND Freshdesk. This preserves an Exchange
  copy for compliance while routing to Freshdesk.

.PARAMETER FreshdeskIngestionAddress
  The Freshdesk-provided email address for ticket ingestion.

.PARAMETER AdminUPN
  Default: tyler.granlund-admin@httbrands.com

.EXAMPLE
  .\Set-DCEHelpMailboxForwarding.ps1 -FreshdeskIngestionAddress "support@deltacrown.freshdesk.com"
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [string]$FreshdeskIngestionAddress,
    [string]$AdminUPN = "tyler.granlund-admin@httbrands.com"
)

$ErrorActionPreference = "Stop"

Write-Host "[MAILBOX] Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline -UserPrincipalName $AdminUPN -DelegatedOrganization "deltacrown.onmicrosoft.com" -ShowBanner:$false

$mbx = Get-Mailbox -Identity "help@deltacrown.com" -ErrorAction Stop
Write-Host "[MAILBOX] Current forwarding: $($mbx.ForwardingSmtpAddress)" -ForegroundColor Cyan

if ($PSCmdlet.ShouldProcess("help@deltacrown.com", "Set forwarding to $FreshdeskIngestionAddress")) {
    Set-Mailbox -Identity "help@deltacrown.com" `
        -DeliverToMailboxAndForward $true `
        -ForwardingSmtpAddress $FreshdeskIngestionAddress `
        -ErrorAction Stop

    Write-Host "[MAILBOX] Forwarding configured." -ForegroundColor Green

    $mbx2 = Get-Mailbox -Identity "help@deltacrown.com"
    Write-Host "[MAILBOX] Forwarding address: $($mbx2.ForwardingSmtpAddress)" -ForegroundColor Cyan
    Write-Host "[MAILBOX] Deliver + Forward: $($mbx2.DeliverToMailboxAndForward)" -ForegroundColor Cyan
}

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "[MAILBOX] Done." -ForegroundColor Green