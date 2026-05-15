<#
.SYNOPSIS
    Find Kayla Bramlett in the HTT tenant. Display-name + recipient + user searches.
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ExchangeOnlineManagement
Write-Host "[$([DateTime]::UtcNow.ToString('HH:mm:ssZ'))] Connecting Exchange Online HTT (device code)..." -ForegroundColor Cyan
Connect-ExchangeOnline -Device -ShowBanner:$false -DelegatedOrganization 'httbrands.onmicrosoft.com' | Out-Null

$patterns = @(
    "Kayla*",            # any Kayla
    "*Bramlett*",        # any Bramlett
    "Bramlet*",          # spelling variant
    "*Bramblett*",       # spelling variant
    "Kayleigh*","Kaylee*","Kaila*","Kaylah*"  # first-name variants
)

$found = New-Object System.Collections.Generic.HashSet[string]
foreach ($p in $patterns) {
    Write-Host "  -- Get-Recipient -Filter DisplayName -like '$p' --" -ForegroundColor DarkCyan
    $hits = Get-Recipient -Filter "DisplayName -like '$p'" -ResultSize Unlimited -ErrorAction SilentlyContinue
    foreach ($h in $hits) {
        $key = $h.PrimarySmtpAddress
        if (-not $found.Contains($key)) {
            [void]$found.Add($key)
            "  HIT: $($h.DisplayName)  /  $($h.PrimarySmtpAddress)  /  $($h.RecipientTypeDetails)"
        }
    }
}

Write-Host "  -- Get-User by display name pattern --" -ForegroundColor DarkCyan
$users = Get-User -ResultSize Unlimited |
    Where-Object { $_.DisplayName -match '(?i)kayla|bramlett|bramlet|kayleigh|kaylee|kaila' }
foreach ($u in $users) {
    "  USER: $($u.DisplayName)  /  $($u.UserPrincipalName)  /  Title=$($u.Title)  Dept=$($u.Department)"
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
