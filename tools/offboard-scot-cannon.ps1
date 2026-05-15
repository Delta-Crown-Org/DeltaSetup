<#
.SYNOPSIS
    Offboard Scot Cannon — convert mailbox to shared, grant Kayla Bramlett access,
    remove from _fullHTT, block sign-in, remove license.

.DESCRIPTION
    Per Tyler 2026-05-15: Scot's account was supposed to have been revoked with
    drive files transferred to Kayla Bramlett. Friday audit shows his HTT user/
    mailbox is still fully active. Complete the offboarding properly.

    Steps (in order):
      1. Verify Scot's current state + Kayla exists (pre-check)
      2. Convert Scot's mailbox to shared (no license required after this)
      3. Grant Kayla FullAccess on Scot's mailbox
      4. Hide Scot from the GAL
      5. Remove Scot from _fullHTT distribution group
      6. Block sign-in (Update-MgUser -AccountEnabled $false)
      7. Remove all licenses
      8. Post-state report

    Steps 1-5 use Exchange Online. Steps 6-7 use Microsoft Graph (separate
    device-code flow).

    KNOWN GOTCHA (encountered 2026-05-15): the Microsoft Graph PowerShell
    public-client app (14d82eec-...) under raw OAuth device-code flow can
    return Authorization_RequestDenied on PATCH /users/{id} accountEnabled
    even when the caller has Global Administrator. Workaround: use the
    Azure CLI's existing tenant session for the Graph admin-write phase:

        TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)
        curl -X PATCH -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
             -d '{"accountEnabled":false}' \
             https://graph.microsoft.com/v1.0/users/<id>
        curl -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Length: 0' \
             https://graph.microsoft.com/v1.0/users/<id>/revokeSignInSessions
        curl -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
             -d '{"addLicenses":[],"removeLicenses":["<sku>",...]}' \
             https://graph.microsoft.com/v1.0/users/<id>/assignLicense

    revokeSignInSessions requires explicit Content-Length: 0 header because
    Graph rejects empty bodies with HTTP 411 otherwise.

.PARAMETER Apply
    Without -Apply, runs WhatIf — shows what would change without changing anything.
    With -Apply, actually performs the offboarding.

.NOTES
    Tracking: DeltaSetup-9av
    Tenant:   HTT (httbrands.onmicrosoft.com / 0c0e35dc-188a-4eb3-b8ba-61752154b407)
    Targets:  Scot.Cannon@httbrands.com (offboard), Kayla.Bramlett@httbrands.com (delegate)
#>

[CmdletBinding()]
param(
    [switch]$Apply,

    [string]$OutDir = '.local/reports/friday-sharepoint-hub-audit',

    [string]$ScotUpn  = 'Scot.Cannon@httbrands.com',
    [string]$KaylaUpn = 'Kayla.Bramlet@httbrands.com',
    [string]$FullHttIdentity = '_fullHTT@httbrands.com',
    [string]$HttTenantId = '0c0e35dc-188a-4eb3-b8ba-61752154b407'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$publicClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$null = New-Item -ItemType Directory -Force -Path $OutDir

$mode = if ($Apply) { 'APPLY' } else { 'WHATIF (dry run)' }

function Write-Stamp([string]$msg, [string]$color = 'Cyan') {
    Write-Host "[$([DateTime]::UtcNow.ToString('HH:mm:ssZ'))] $msg" -ForegroundColor $color
}
function Write-Plan([string]$msg) { Write-Host "  PLAN:    $msg" -ForegroundColor Yellow }
function Write-Act([string]$msg)  { Write-Host "  APPLIED: $msg" -ForegroundColor Green }
function Write-Skip([string]$msg) { Write-Host "  SKIPPED: $msg" -ForegroundColor DarkGray }

Write-Stamp "Mode: $mode" 'Magenta'
Write-Stamp "Targets: Scot=$ScotUpn  Kayla=$KaylaUpn  DL=$FullHttIdentity"

# ---------- Graph device-code helper (reused from friday-re-audit.ps1) ----------
function Get-DeviceCodeToken {
    param([string]$TenantId, [string]$Scope)
    $deviceUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode"
    $tokenUri  = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $deviceResp = Invoke-RestMethod -Method Post -Uri $deviceUri -Body @{
        client_id = $publicClientId; scope = $Scope
    } -ContentType 'application/x-www-form-urlencoded'

    Write-Host ''
    Write-Host '======================== DEVICE CODE ========================' -ForegroundColor Yellow
    Write-Host ("  URL:  {0}" -f $deviceResp.verification_uri) -ForegroundColor Yellow
    Write-Host ("  CODE: {0}" -f $deviceResp.user_code)        -ForegroundColor Yellow
    Write-Host '=============================================================' -ForegroundColor Yellow
    Write-Host ''
    if (Get-Command pbcopy -ErrorAction SilentlyContinue) { $deviceResp.user_code | pbcopy; Write-Stamp 'Code on clipboard.' }
    if (Get-Command open -ErrorAction SilentlyContinue) { Start-Process 'open' -ArgumentList $deviceResp.verification_uri | Out-Null }

    $deadline = [DateTime]::UtcNow.AddSeconds([int]$deviceResp.expires_in)
    $interval = [Math]::Max(5, [int]$deviceResp.interval)
    while ([DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Seconds $interval
        try {
            return (Invoke-RestMethod -Method Post -Uri $tokenUri -Body @{
                grant_type='urn:ietf:params:oauth:grant-type:device_code'
                client_id=$publicClientId; device_code=$deviceResp.device_code
            } -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop).access_token
        } catch {
            $err = $null; try { $err = $_.ErrorDetails.Message | ConvertFrom-Json } catch {}
            if ($err.error -eq 'authorization_pending') { continue }
            if ($err.error -eq 'slow_down') { $interval += 5; continue }
            throw
        }
    }
    throw 'Device code timed out.'
}

# ============================ EXCHANGE ONLINE PHASE ============================
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Write-Stamp 'Connecting to HTT Exchange Online (device code)...'
Connect-ExchangeOnline -Device -ShowBanner:$false -DelegatedOrganization 'httbrands.onmicrosoft.com' | Out-Null
Write-Stamp 'Connected.' 'Green'

# --- Pre-checks ---
Write-Stamp '-- Pre-check: Scot mailbox --'
$scotMbx = Get-Mailbox -Identity $ScotUpn -ErrorAction Stop
"  Current type: $($scotMbx.RecipientTypeDetails)  Hidden: $($scotMbx.HiddenFromAddressListsEnabled)"

Write-Stamp '-- Pre-check: Kayla recipient --'
try {
    $kaylaRcpt = Get-Recipient -Identity $KaylaUpn -ErrorAction Stop
    "  Found: $($kaylaRcpt.DisplayName) / $($kaylaRcpt.PrimarySmtpAddress) / $($kaylaRcpt.RecipientTypeDetails)"
} catch {
    Write-Warning "Kayla not found at $KaylaUpn — searching by display name..."
    $kaylaRcpt = Get-Recipient -Filter "DisplayName -like 'Kayla*Bramlett*'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $kaylaRcpt) { throw "Cannot locate Kayla Bramlett. Aborting." }
    "  Found via display-name search: $($kaylaRcpt.DisplayName) / $($kaylaRcpt.PrimarySmtpAddress)"
    $KaylaUpn = $kaylaRcpt.PrimarySmtpAddress
}

Write-Stamp '-- Pre-check: _fullHTT membership of Scot --'
$scotInFullHtt = Get-DistributionGroupMember -Identity $FullHttIdentity -ResultSize Unlimited |
    Where-Object { $_.PrimarySmtpAddress -eq $ScotUpn }
"  Scot in _fullHTT: $($null -ne $scotInFullHtt)"

# --- Step 1: convert to shared ---
Write-Stamp '-- Step 1: Convert mailbox to Shared --'
if ($scotMbx.RecipientTypeDetails -eq 'SharedMailbox') {
    Write-Skip 'Already SharedMailbox.'
} else {
    Write-Plan "Set-Mailbox -Identity $ScotUpn -Type Shared"
    if ($Apply) {
        Set-Mailbox -Identity $ScotUpn -Type Shared
        Write-Act "Mailbox converted to Shared."
    }
}

# --- Step 2: grant Kayla FullAccess ---
Write-Stamp '-- Step 2: Grant Kayla FullAccess --'
$existingPerm = Get-MailboxPermission -Identity $ScotUpn |
    Where-Object { $_.User -like "*$($kaylaRcpt.Name)*" -or $_.User -like "*$KaylaUpn*" }
if ($existingPerm) {
    Write-Skip "Kayla already has $($existingPerm.AccessRights -join ',') on Scot's mailbox."
} else {
    Write-Plan "Add-MailboxPermission -Identity $ScotUpn -User $KaylaUpn -AccessRights FullAccess -InheritanceType All -AutoMapping:`$true"
    if ($Apply) {
        Add-MailboxPermission -Identity $ScotUpn -User $KaylaUpn -AccessRights FullAccess -InheritanceType All -AutoMapping:$true | Out-Null
        Write-Act "Kayla granted FullAccess on Scot's mailbox."
    }
}

# --- Step 3: hide from GAL ---
Write-Stamp '-- Step 3: Hide from GAL --'
if ($scotMbx.HiddenFromAddressListsEnabled) {
    Write-Skip 'Already hidden from GAL.'
} else {
    Write-Plan "Set-Mailbox -Identity $ScotUpn -HiddenFromAddressListsEnabled `$true"
    if ($Apply) {
        Set-Mailbox -Identity $ScotUpn -HiddenFromAddressListsEnabled $true
        Write-Act "Mailbox hidden from GAL."
    }
}

# --- Step 4: remove from _fullHTT ---
Write-Stamp '-- Step 4: Remove Scot from _fullHTT --'
if (-not $scotInFullHtt) {
    Write-Skip 'Scot is not in _fullHTT.'
} else {
    Write-Plan "Remove-DistributionGroupMember -Identity $FullHttIdentity -Member $ScotUpn -BypassSecurityGroupManagerCheck -Confirm:`$false"
    if ($Apply) {
        Remove-DistributionGroupMember -Identity $FullHttIdentity -Member $ScotUpn -BypassSecurityGroupManagerCheck -Confirm:$false
        Write-Act "Scot removed from _fullHTT."
    }
}

Write-Stamp 'Disconnecting Exchange Online...'
Disconnect-ExchangeOnline -Confirm:$false | Out-Null

# ============================ GRAPH PHASE ============================
Write-Stamp '-- Step 5+6: Block sign-in and remove licenses (Graph) --'
$graphToken = Get-DeviceCodeToken -TenantId $HttTenantId -Scope (
    'https://graph.microsoft.com/User.ReadWrite.All ' +
    'https://graph.microsoft.com/Directory.Read.All ' +
    'offline_access'
)
$hdr = @{ Authorization = "Bearer $graphToken"; 'Content-Type' = 'application/json' }

$scotUser = Invoke-RestMethod -Method Get -Headers $hdr `
    -Uri "https://graph.microsoft.com/v1.0/users/$ScotUpn`?`$select=id,displayName,userPrincipalName,accountEnabled,assignedLicenses"
"  Current state — accountEnabled=$($scotUser.accountEnabled)  assignedLicenses=$($scotUser.assignedLicenses.skuId.Count)"

# --- Step 5: block sign-in ---
if (-not $scotUser.accountEnabled) {
    Write-Skip 'Already accountEnabled=false.'
} else {
    Write-Plan "PATCH /users/$($scotUser.id) {accountEnabled:false}"
    if ($Apply) {
        Invoke-RestMethod -Method Patch -Headers $hdr `
            -Uri "https://graph.microsoft.com/v1.0/users/$($scotUser.id)" `
            -Body (@{ accountEnabled = $false } | ConvertTo-Json)
        Write-Act 'accountEnabled set to false.'
    }
}

# Revoke active sessions to invalidate any refresh tokens
Write-Stamp '-- Revoke sign-in sessions --'
Write-Plan "POST /users/$($scotUser.id)/revokeSignInSessions"
if ($Apply) {
    Invoke-RestMethod -Method Post -Headers $hdr `
        -Uri "https://graph.microsoft.com/v1.0/users/$($scotUser.id)/revokeSignInSessions" | Out-Null
    Write-Act 'Sign-in sessions revoked.'
}

# --- Step 6: remove all licenses ---
$skus = @($scotUser.assignedLicenses | Select-Object -ExpandProperty skuId)
Write-Stamp "-- Step 6: Remove licenses ($($skus.Count) currently assigned) --"
if ($skus.Count -eq 0) {
    Write-Skip 'No licenses assigned.'
} else {
    Write-Plan "POST /users/$($scotUser.id)/assignLicense  removeLicenses=$($skus -join ',') addLicenses=[]"
    if ($Apply) {
        $body = @{
            addLicenses    = @()
            removeLicenses = $skus
        } | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Method Post -Headers $hdr `
            -Uri "https://graph.microsoft.com/v1.0/users/$($scotUser.id)/assignLicense" `
            -Body $body | Out-Null
        Write-Act "Removed $($skus.Count) license(s)."
    }
}

# ============================ POST-STATE VERIFICATION ============================
Write-Stamp '== Post-state verification =='
$post = [ordered]@{
    Mode = $mode
    Timestamp = $timestamp
}

if ($Apply) {
    # Re-check Graph state
    $scotAfter = Invoke-RestMethod -Method Get -Headers $hdr `
        -Uri "https://graph.microsoft.com/v1.0/users/$ScotUpn`?`$select=id,displayName,userPrincipalName,accountEnabled,assignedLicenses"
    $post.User = @{
        accountEnabled = $scotAfter.accountEnabled
        licenseCount = $scotAfter.assignedLicenses.Count
    }

    # Re-check Exchange (quick reconnect)
    Connect-ExchangeOnline -Device -ShowBanner:$false -DelegatedOrganization 'httbrands.onmicrosoft.com' | Out-Null
    $mbxAfter = Get-Mailbox -Identity $ScotUpn
    $post.Mailbox = @{
        RecipientTypeDetails = $mbxAfter.RecipientTypeDetails
        HiddenFromAddressListsEnabled = $mbxAfter.HiddenFromAddressListsEnabled
    }
    $kaylaPerm = Get-MailboxPermission -Identity $ScotUpn |
        Where-Object { $_.User -like "*$($kaylaRcpt.Name)*" -or $_.User -like "*$KaylaUpn*" } |
        Select-Object User, AccessRights, IsInherited
    $post.KaylaPermission = $kaylaPerm
    $fullHttAfter = Get-DistributionGroupMember -Identity $FullHttIdentity -ResultSize Unlimited |
        Where-Object { $_.PrimarySmtpAddress -eq $ScotUpn }
    $post.ScotStillInFullHTT = ($null -ne $fullHttAfter)
    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
}

$outFile = Join-Path $OutDir "$timestamp-scot-offboard-$(if($Apply){'apply'}else{'whatif'}).json"
$post | ConvertTo-Json -Depth 6 | Out-File -FilePath $outFile -Encoding utf8
Write-Stamp "Wrote report -> $outFile" 'Green'

Write-Host ''
$post | ConvertTo-Json -Depth 6
