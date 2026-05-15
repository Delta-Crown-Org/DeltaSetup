<#
Diagnostic: what directory roles does Scot Cannon hold? If he's in a privileged
admin role, that explains why standard User.ReadWrite.All can't modify him.
#>
$ErrorActionPreference = 'Stop'
$publicClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
$HttTenantId = '0c0e35dc-188a-4eb3-b8ba-61752154b407'

function Get-DeviceCodeToken {
    param([string]$TenantId, [string]$Scope)
    $resp = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode" `
        -Body @{ client_id=$publicClientId; scope=$Scope } `
        -ContentType 'application/x-www-form-urlencoded'
    Write-Host ''
    Write-Host '======================== DEVICE CODE ========================' -ForegroundColor Yellow
    Write-Host ("  URL:  {0}" -f $resp.verification_uri) -ForegroundColor Yellow
    Write-Host ("  CODE: {0}" -f $resp.user_code) -ForegroundColor Yellow
    Write-Host '=============================================================' -ForegroundColor Yellow
    if (Get-Command pbcopy -ErrorAction SilentlyContinue) { $resp.user_code | pbcopy }
    if (Get-Command open -ErrorAction SilentlyContinue) { Start-Process 'open' -ArgumentList $resp.verification_uri | Out-Null }
    $deadline = [DateTime]::UtcNow.AddSeconds([int]$resp.expires_in)
    $interval = [Math]::Max(5, [int]$resp.interval)
    while ([DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Seconds $interval
        try {
            return (Invoke-RestMethod -Method Post `
                -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                -Body @{ grant_type='urn:ietf:params:oauth:grant-type:device_code'; client_id=$publicClientId; device_code=$resp.device_code } `
                -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop).access_token
        } catch {
            $err = $null; try { $err = $_.ErrorDetails.Message | ConvertFrom-Json } catch {}
            if ($err.error -eq 'authorization_pending') { continue }
            if ($err.error -eq 'slow_down') { $interval += 5; continue }
            throw
        }
    }
    throw 'timeout'
}

$token = Get-DeviceCodeToken -TenantId $HttTenantId -Scope (
    'https://graph.microsoft.com/Directory.Read.All ' +
    'https://graph.microsoft.com/User.Read.All ' +
    'https://graph.microsoft.com/RoleManagement.Read.Directory ' +
    'offline_access'
)
$hdr = @{ Authorization = "Bearer $token"; Accept = 'application/json' }
$scotId = '1defe45b-af8d-460c-a80b-9189cb520737'

Write-Host ''
Write-Host "=== Scot directory role memberships ===" -ForegroundColor Cyan
$roleAssignments = Invoke-RestMethod -Method Get -Headers $hdr `
    -Uri "https://graph.microsoft.com/v1.0/users/$scotId/memberOf"
foreach ($r in $roleAssignments.value) {
    if ($r.'@odata.type' -eq '#microsoft.graph.directoryRole') {
        "  ROLE: $($r.displayName) [$($r.roleTemplateId)]"
    }
}

Write-Host ''
Write-Host "=== Scot active role assignments (PIM-aware) ===" -ForegroundColor Cyan
try {
    $active = Invoke-RestMethod -Method Get -Headers $hdr `
        -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?`$filter=principalId eq '$scotId'&`$expand=roleDefinition"
    foreach ($a in $active.value) {
        "  ACTIVE: $($a.roleDefinition.displayName)  scope=$($a.directoryScopeId)"
    }
    if ($active.value.Count -eq 0) { "  (none active)" }
} catch {
    Write-Warning "Role-management read failed: $_"
}

Write-Host ''
Write-Host "=== Calling user identity (whoami) ===" -ForegroundColor Cyan
$me = Invoke-RestMethod -Method Get -Headers $hdr -Uri "https://graph.microsoft.com/v1.0/me"
"  $($me.displayName) / $($me.userPrincipalName) / $($me.id)"

Write-Host ''
Write-Host "=== Calling user directory roles ===" -ForegroundColor Cyan
$meRoles = Invoke-RestMethod -Method Get -Headers $hdr -Uri "https://graph.microsoft.com/v1.0/me/memberOf"
foreach ($r in $meRoles.value) {
    if ($r.'@odata.type' -eq '#microsoft.graph.directoryRole') {
        "  ROLE: $($r.displayName) [$($r.roleTemplateId)]"
    }
}
