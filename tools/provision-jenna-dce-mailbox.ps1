<#
.SYNOPSIS
    Provision jenna.bowden@deltacrown.com as a SharedMailbox in DCE Exchange
    and grant Jenna's DCE guest object Full Access + Send As permissions.

.DESCRIPTION
    Jenna Bowden is the Colorado Springs owner of record (confirmed by Jamie Baer).
    Her primary mailbox is at HTT: jenna.bowden@httbrands.com.
    This script creates a @deltacrown.com identity she can send FROM without
    consuming a Business Premium license.

    After this runs, Jenna:
    - Opens Outlook connected to her HTT account.
    - The jenna.bowden@deltacrown.com shared mailbox appears automatically
      (Full Access grants auto-mount in Outlook).
    - She selects "From: jenna.bowden@deltacrown.com" when composing DCE emails.

    Entra guest object: 26e9afa6-3e1b-4830-b0c6-68eceba42781
    DCE ext UPN:        Jenna.Bowden_httbrands.com#EXT#@deltacrown.onmicrosoft.com

.PARAMETER DryRun
    Show what WOULD happen. No changes made. Default: true.

.PARAMETER Confirm
    Actually execute the changes. Requires approval file at:
    approvals/exchange-jenna-dce-mailbox.txt

.NOTES
    Approval gate: create approvals/exchange-jenna-dce-mailbox.txt containing:
      APPROVED: provision jenna.bowden@deltacrown.com SharedMailbox
      Date: YYYY-MM-DD
      Tyler Granlund

    Pre-approved Exchange write patterns: Apply-DceMetadataPopulation.ps1 framework.
    This script follows the same dry-run-by-default convention.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DryRun = $true,
    [switch]$Confirm
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

$TargetMailbox  = 'jenna.bowden@deltacrown.com'
$TargetAlias    = 'jenna.bowden'
$DisplayName    = 'Jenna Bowden'
$DceOrg         = 'deltacrown.onmicrosoft.com'
$AdminUpn       = 'tyler.granlund-admin@httbrands.com'
$ApprovalFile   = Join-Path $PSScriptRoot '../approvals/exchange-jenna-dce-mailbox.txt'

# Jenna's DCE guest UPN (cross-tenant guest object in deltacrown tenant)
$JennaDceGuestUpn = 'Jenna.Bowden_httbrands.com#EXT#@deltacrown.onmicrosoft.com'

# ---------------------------------------------------------------------------
# Approval gate
# ---------------------------------------------------------------------------

$isLive = $Confirm.IsPresent -and -not $DryRun.IsPresent

if ($isLive) {
    if (-not (Test-Path $ApprovalFile)) {
        Write-Error @"
BLOCKED: live run requires an approval file at:
  $ApprovalFile

Create that file containing:
  APPROVED: provision jenna.bowden@deltacrown.com SharedMailbox
  Date: YYYY-MM-DD
  Tyler Granlund
"@
    }
    $approvalContent = Get-Content $ApprovalFile -Raw
    if ($approvalContent -notmatch 'APPROVED') {
        Write-Error "Approval file found but does not contain 'APPROVED'. Check $ApprovalFile."
    }
    Write-Host "[APPROVAL] Approval file verified: $ApprovalFile" -ForegroundColor Green
}
else {
    Write-Host "[DRY-RUN] No changes will be made. Pass -Confirm to execute." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Connect to DCE Exchange Online
# ---------------------------------------------------------------------------

Write-Host "`n[CONNECT] Connecting to DCE Exchange Online (delegated)..."
if ($isLive -or -not $DryRun) {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline `
        -UserPrincipalName $AdminUpn `
        -DelegatedOrganization $DceOrg `
        -ShowBanner:$false
    Write-Host "[CONNECT] Connected." -ForegroundColor Green
}
else {
    Write-Host "[DRY-RUN] Would connect: Connect-ExchangeOnline -DelegatedOrganization $DceOrg"
}

# ---------------------------------------------------------------------------
# Step 1: Check if mailbox already exists
# ---------------------------------------------------------------------------

Write-Host "`n[STEP 1] Check if $TargetMailbox already exists..."

$existingMailbox = $null
if (-not $DryRun) {
    try {
        $existingMailbox = Get-Mailbox -Identity $TargetMailbox -ErrorAction Stop
        Write-Host "  Mailbox exists: RecipientTypeDetails = $($existingMailbox.RecipientTypeDetails)"
    }
    catch {
        Write-Host "  Mailbox does not exist yet — will create."
    }
}
else {
    Write-Host "[DRY-RUN] Would check: Get-Mailbox -Identity '$TargetMailbox'"
    Write-Host "  Assuming mailbox does not exist (dry run)."
}

# ---------------------------------------------------------------------------
# Step 2: Create SharedMailbox (if it does not exist)
# ---------------------------------------------------------------------------

Write-Host "`n[STEP 2] Create SharedMailbox $TargetMailbox..."

if ($existingMailbox -and $existingMailbox.RecipientTypeDetails -eq 'SharedMailbox') {
    Write-Host "  Already a SharedMailbox — skipping creation."
}
elseif ($existingMailbox -and $existingMailbox.RecipientTypeDetails -ne 'SharedMailbox') {
    Write-Warning "  Mailbox exists but is type '$($existingMailbox.RecipientTypeDetails)' — convert manually."
    Write-Host "  Run: Set-Mailbox -Identity '$TargetMailbox' -Type Shared"
}
else {
    $createCmd = @"
New-Mailbox ``
    -Shared ``
    -Name '$DisplayName' ``
    -DisplayName '$DisplayName' ``
    -Alias '$TargetAlias' ``
    -PrimarySmtpAddress '$TargetMailbox'
"@
    if ($isLive) {
        Write-Host "  Creating shared mailbox..."
        New-Mailbox `
            -Shared `
            -Name $DisplayName `
            -DisplayName $DisplayName `
            -Alias $TargetAlias `
            -PrimarySmtpAddress $TargetMailbox
        Write-Host "  Created $TargetMailbox." -ForegroundColor Green
    }
    else {
        Write-Host "[DRY-RUN] Would run:`n$createCmd"
    }
}

# ---------------------------------------------------------------------------
# Step 3: Grant Full Access to Jenna's DCE guest object
# ---------------------------------------------------------------------------

Write-Host "`n[STEP 3] Grant Full Access to $JennaDceGuestUpn..."

$fullAccessCmd = @"
Add-MailboxPermission ``
    -Identity '$TargetMailbox' ``
    -User '$JennaDceGuestUpn' ``
    -AccessRights FullAccess ``
    -InheritanceType All ``
    -AutoMapping `$true
"@

if ($isLive) {
    Add-MailboxPermission `
        -Identity $TargetMailbox `
        -User $JennaDceGuestUpn `
        -AccessRights FullAccess `
        -InheritanceType All `
        -AutoMapping $true
    Write-Host "  Full Access granted to $JennaDceGuestUpn." -ForegroundColor Green
}
else {
    Write-Host "[DRY-RUN] Would run:`n$fullAccessCmd"
}

# ---------------------------------------------------------------------------
# Step 4: Grant Send As to Jenna's DCE guest object
# ---------------------------------------------------------------------------

Write-Host "`n[STEP 4] Grant Send As to $JennaDceGuestUpn..."

$sendAsCmd = @"
Add-RecipientPermission ``
    -Identity '$TargetMailbox' ``
    -Trustee '$JennaDceGuestUpn' ``
    -AccessRights SendAs ``
    -Confirm:`$false
"@

if ($isLive) {
    Add-RecipientPermission `
        -Identity $TargetMailbox `
        -Trustee $JennaDceGuestUpn `
        -AccessRights SendAs `
        -Confirm:$false
    Write-Host "  Send As granted to $JennaDceGuestUpn." -ForegroundColor Green
}
else {
    Write-Host "[DRY-RUN] Would run:`n$sendAsCmd"
}

# ---------------------------------------------------------------------------
# Step 5: Verify
# ---------------------------------------------------------------------------

Write-Host "`n[STEP 5] Verify..."

if ($isLive) {
    $mb = Get-Mailbox -Identity $TargetMailbox
    Write-Host "  Mailbox type: $($mb.RecipientTypeDetails)"
    Write-Host "  Primary SMTP: $($mb.PrimarySmtpAddress)"

    $perms = Get-MailboxPermission -Identity $TargetMailbox |
        Where-Object { $_.User -like '*Bowden*' }
    Write-Host "  Full Access permissions for Jenna:"
    $perms | Format-Table User, AccessRights -AutoSize

    $sendPerms = Get-RecipientPermission -Identity $TargetMailbox |
        Where-Object { $_.Trustee -like '*Bowden*' }
    Write-Host "  Send As permissions for Jenna:"
    $sendPerms | Format-Table Trustee, AccessRights -AutoSize
}
else {
    Write-Host "[DRY-RUN] Would run verification Get-Mailbox + Get-MailboxPermission + Get-RecipientPermission"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host ""
if ($isLive) {
    Write-Host "=== PROVISIONING COMPLETE ===" -ForegroundColor Green
    Write-Host "  $TargetMailbox provisioned as SharedMailbox."
    Write-Host "  Jenna Bowden ($JennaDceGuestUpn) has Full Access + Send As."
    Write-Host "  No Business Premium license was used."
    Write-Host ""
    Write-Host "  Jenna's next step:"
    Write-Host "  Open Outlook (connected to jenna.bowden@httbrands.com)."
    Write-Host "  The jenna.bowden@deltacrown.com mailbox will appear automatically."
    Write-Host "  When composing, click From and select jenna.bowden@deltacrown.com."
}
else {
    Write-Host "=== DRY-RUN COMPLETE — no changes made ===" -ForegroundColor Yellow
    Write-Host "  Review the commands above, then run with -Confirm to execute."
    Write-Host "  Remember to create the approval file first:"
    Write-Host "  $ApprovalFile"
}

if (-not $DryRun -and $isLive) {
    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    Write-Host "[DISCONNECT] Disconnected from Exchange Online."
}
