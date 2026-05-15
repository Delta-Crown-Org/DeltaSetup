<#
.SYNOPSIS
    2026-05-15 Friday re-audit: SharePoint sites (HTT + DCE) + _fullHTT Scot evidence.

.DESCRIPTION
    Read-only re-audit using raw OAuth 2.0 device authorization flow against
    Microsoft Graph. We implement the flow directly (instead of Connect-MgGraph)
    because the Graph PowerShell SDK buffers its device-code prompt when stdout
    is piped to a non-TTY, which broke the agent-driven workflow.

    Steps:
      HTT-Graph    — Graph: sites + groups + organization for HTT
      DCE-Graph    — Graph: sites + groups + organization for DCE
      HTT-Exchange — Exchange Online: _fullHTT group detail + Scot Cannon state

    Graph steps use raw HTTP (this script handles auth).
    Exchange step uses ExchangeOnlineManagement -Device (SDK handles auth — its
    device-code prompt does flush correctly).

.PARAMETER Step
    HTT-Graph | DCE-Graph | HTT-Exchange | All

.PARAMETER OutDir
    Local-only output directory.

.NOTES
    Public client ID: 14d82eec-204b-4c2f-b7e8-296a70dab67e (Microsoft Graph PowerShell)
    This is a well-known Microsoft-published public client present in every tenant.
#>

[CmdletBinding()]
param(
    [ValidateSet('HTT-Graph','DCE-Graph','HTT-Exchange','All')]
    [string]$Step = 'All',

    [string]$OutDir = '.local/reports/friday-sharepoint-hub-audit'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$tenants = @{
    HTT = '0c0e35dc-188a-4eb3-b8ba-61752154b407'
    DCE = 'ce62e17d-2feb-4e67-a115-8ea4af68da30'
}
$publicClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'  # Microsoft Graph PowerShell

$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$null = New-Item -ItemType Directory -Force -Path $OutDir

function Write-Stamp([string]$msg, [string]$color = 'Cyan') {
    Write-Host "[$([DateTime]::UtcNow.ToString('HH:mm:ssZ'))] $msg" -ForegroundColor $color
}

function Get-DeviceCodeToken {
    param(
        [Parameter(Mandatory)] [string]$TenantId,
        [Parameter(Mandatory)] [string]$Scope
    )

    $deviceUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode"
    $tokenUri  = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

    Write-Stamp "Requesting device code from $TenantId..."
    $deviceResp = Invoke-RestMethod -Method Post -Uri $deviceUri -Body @{
        client_id = $publicClientId
        scope     = $Scope
    } -ContentType 'application/x-www-form-urlencoded'

    # Flush the user-facing block immediately so the agent harness sees it.
    Write-Host ''
    Write-Host '======================== DEVICE CODE ========================' -ForegroundColor Yellow
    Write-Host ("  URL:  {0}" -f $deviceResp.verification_uri) -ForegroundColor Yellow
    Write-Host ("  CODE: {0}" -f $deviceResp.user_code)        -ForegroundColor Yellow
    Write-Host ("  Expires in: {0}s" -f $deviceResp.expires_in)
    Write-Host '=============================================================' -ForegroundColor Yellow
    Write-Host ''

    # macOS: stage code on clipboard + open browser
    if (Get-Command pbcopy -ErrorAction SilentlyContinue) {
        $deviceResp.user_code | pbcopy
        Write-Stamp 'Code copied to clipboard (pbcopy).'
    }
    if (Get-Command open -ErrorAction SilentlyContinue) {
        Start-Process 'open' -ArgumentList $deviceResp.verification_uri | Out-Null
        Write-Stamp "Opened browser to $($deviceResp.verification_uri)."
    }

    # Poll for token
    $deadline = [DateTime]::UtcNow.AddSeconds([int]$deviceResp.expires_in)
    $interval = [int]$deviceResp.interval
    if ($interval -lt 5) { $interval = 5 }

    while ([DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Seconds $interval
        try {
            $tokenResp = Invoke-RestMethod -Method Post -Uri $tokenUri -Body @{
                grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
                client_id   = $publicClientId
                device_code = $deviceResp.device_code
            } -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
            Write-Stamp 'Token acquired.' 'Green'
            return $tokenResp.access_token
        } catch {
            $err = $null
            try { $err = $_.ErrorDetails.Message | ConvertFrom-Json } catch {}
            if ($err -and $err.error -eq 'authorization_pending') {
                continue
            }
            if ($err -and $err.error -eq 'slow_down') {
                $interval += 5
                continue
            }
            if ($err -and $err.error -eq 'expired_token') {
                throw "Device code expired before user completed auth."
            }
            if ($err -and $err.error -eq 'authorization_declined') {
                throw "User declined the auth request."
            }
            throw
        }
    }
    throw "Device code authorization timed out at $($deadline.ToString('o'))."
}

function Invoke-GraphPaged {
    param(
        [Parameter(Mandatory)] [string]$Url,
        [Parameter(Mandatory)] [string]$Token
    )
    $items = New-Object System.Collections.Generic.List[object]
    $next = $Url
    while ($next) {
        $resp = Invoke-RestMethod -Method Get -Uri $next -Headers @{
            Authorization = "Bearer $Token"
            Accept        = 'application/json'
        }
        if ($resp.value) { $items.AddRange([object[]]$resp.value) }
        elseif ($resp -is [array]) { $items.AddRange([object[]]$resp) }
        else { $items.Add($resp) }
        $next = $resp.'@odata.nextLink'
    }
    return ,$items.ToArray()
}

function Invoke-GraphSitesAudit {
    param([Parameter(Mandatory)] [string]$Label, [Parameter(Mandatory)] [string]$TenantId)

    Write-Stamp "=== $Label Graph audit (Sites + Groups + Org) ==="

    # Scope concat per OAuth: space-delimited; offline_access optional for refresh tokens
    $token = Get-DeviceCodeToken -TenantId $TenantId -Scope (
        'https://graph.microsoft.com/Sites.Read.All ' +
        'https://graph.microsoft.com/Group.Read.All ' +
        'https://graph.microsoft.com/User.Read.All ' +
        'https://graph.microsoft.com/Directory.Read.All ' +
        'https://graph.microsoft.com/Organization.Read.All ' +
        'offline_access'
    )

    # Sites — use /sites?search=* which returns all sites the token can see
    Write-Stamp "Fetching sites (search=*)..."
    $sites = Invoke-GraphPaged -Url 'https://graph.microsoft.com/v1.0/sites?search=*&$top=200' -Token $token
    $sitesOut = Join-Path $OutDir "$timestamp-$Label-sites-full.json"
    $sites | ConvertTo-Json -Depth 6 | Out-File -FilePath $sitesOut -Encoding utf8
    Write-Stamp "Wrote $($sites.Count) sites -> $sitesOut" 'Green'

    # Root site
    try {
        $root = Invoke-RestMethod -Method Get `
            -Uri 'https://graph.microsoft.com/v1.0/sites/root' `
            -Headers @{ Authorization = "Bearer $token"; Accept = 'application/json' }
        $rootOut = Join-Path $OutDir "$timestamp-$Label-root-site.json"
        $root | ConvertTo-Json -Depth 6 | Out-File -FilePath $rootOut -Encoding utf8
        Write-Stamp "Wrote root site -> $rootOut" 'Green'
    } catch {
        Write-Warning "Root site fetch failed: $_"
    }

    # Summary
    $summary = [ordered]@{
        Label       = $Label
        TenantId    = $TenantId
        Timestamp   = $timestamp
        SiteCount   = $sites.Count
        WebTemplate = ($sites | Group-Object -NoElement -Property webUrl | Measure-Object).Count
        Sites       = $sites | Select-Object id,webUrl,displayName,name,createdDateTime,lastModifiedDateTime
    }
    $summaryOut = Join-Path $OutDir "$timestamp-$Label-sites-summary.json"
    $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryOut -Encoding utf8
    Write-Stamp "Wrote summary -> $summaryOut" 'Green'
}

function Invoke-FullHttScotAudit {
    Write-Stamp '=== HTT Exchange Online audit (_fullHTT + Scot Cannon state) ==='
    Import-Module ExchangeOnlineManagement -ErrorAction Stop

    # ExchangeOnlineManagement -Device prompt does flush correctly (different host bridge)
    Write-Stamp 'Connecting to HTT Exchange Online (device code) — copy code from the prompt that follows...'
    Connect-ExchangeOnline -Device -ShowBanner:$false -DelegatedOrganization 'httbrands.onmicrosoft.com' | Out-Null
    Write-Stamp 'Connected to HTT Exchange Online.' 'Green'

    $groupOut   = Join-Path $OutDir "$timestamp-HTT-fullHTT-group-detail.json"
    $membersOut = Join-Path $OutDir "$timestamp-HTT-fullHTT-members-detail.csv"
    $scotOut    = Join-Path $OutDir "$timestamp-HTT-scot-cannon-state.json"

    $group = Get-DistributionGroup -Identity '_fullHTT@httbrands.com' -ErrorAction Stop
    $group | Select-Object Name,DisplayName,PrimarySmtpAddress,GroupType,RecipientTypeDetails,WhenCreated,WhenChanged,ManagedBy,MemberJoinRestriction,MemberDepartRestriction,EmailAddresses |
        ConvertTo-Json -Depth 4 | Out-File -FilePath $groupOut -Encoding utf8
    Write-Stamp "Wrote group detail -> $groupOut"

    $members = Get-DistributionGroupMember -Identity '_fullHTT@httbrands.com' -ResultSize Unlimited
    $members | Select-Object DisplayName,PrimarySmtpAddress,RecipientType,RecipientTypeDetails,WhenCreated,WhenChanged |
        Export-Csv -Path $membersOut -NoTypeInformation -Encoding utf8
    Write-Stamp "Wrote $($members.Count) members -> $membersOut"

    $scotState = [ordered]@{}
    foreach ($cmd in @(
        @{ Name='Recipient'; Block={ Get-Recipient -Identity 'Scot.Cannon@httbrands.com' -ErrorAction Stop |
            Select-Object Name,DisplayName,PrimarySmtpAddress,RecipientType,RecipientTypeDetails,WhenCreated,WhenChanged,HiddenFromAddressListsEnabled,ExternalEmailAddress } },
        @{ Name='Mailbox'; Block={ Get-Mailbox -Identity 'Scot.Cannon@httbrands.com' -ErrorAction Stop |
            Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails,UserPrincipalName,WhenSoftDeleted,WhenMailboxCreated,HiddenFromAddressListsEnabled,ForwardingSmtpAddress,DeliverToMailboxAndForward,ExchangeGuid } },
        @{ Name='User'; Block={ Get-User -Identity 'Scot.Cannon@httbrands.com' -ErrorAction Stop |
            Select-Object DisplayName,UserPrincipalName,Company,Department,Title,Office,WhenChanged,AccountDisabled,RemotePowerShellEnabled } }
    )) {
        try { $scotState[$cmd.Name] = & $cmd.Block }
        catch { $scotState[$cmd.Name] = "ERROR: $_" }
    }
    $scotState | ConvertTo-Json -Depth 6 | Out-File -FilePath $scotOut -Encoding utf8
    Write-Stamp "Wrote Scot state -> $scotOut" 'Green'

    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    Write-Stamp 'Disconnected HTT Exchange Online.'
}

switch ($Step) {
    'HTT-Graph'    { Invoke-GraphSitesAudit -Label 'HTT' -TenantId $tenants.HTT }
    'DCE-Graph'    { Invoke-GraphSitesAudit -Label 'DCE' -TenantId $tenants.DCE }
    'HTT-Exchange' { Invoke-FullHttScotAudit }
    'All' {
        Invoke-GraphSitesAudit -Label 'HTT' -TenantId $tenants.HTT
        Invoke-GraphSitesAudit -Label 'DCE' -TenantId $tenants.DCE
        Invoke-FullHttScotAudit
    }
}

Write-Stamp "Done. Outputs under $OutDir (prefix $timestamp)" 'Green'
