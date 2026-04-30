<#
.SYNOPSIS
Read-only confirmation for Delta Crown singleton security policies.

.DESCRIPTION
Uses Microsoft Graph PowerShell with delegated read scopes to confirm policy
states that were inaccessible through the Azure CLI Graph token inventory:
security defaults, authentication methods policy, and admin consent request
policy. Raw JSON outputs are local-only and should not be committed.
#>

[CmdletBinding()]
param(
    [string]$TenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30",
    [string]$OutputPath = ".local/reports/tenant-inventory/security-policy-confirmation"
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

Ensure-OutputPath -Path $OutputPath
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$scopes = @("Policy.Read.All", "Directory.Read.All", "Organization.Read.All")
$endpoints = [ordered]@{
    identitySecurityDefaults      = "https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy"
    authenticationMethodsPolicy   = "https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy"
    adminConsentRequestPolicy     = "https://graph.microsoft.com/v1.0/policies/adminConsentRequestPolicy"
}

try {
    Write-InventoryLog "Connecting to Microsoft Graph"
    Connect-MgGraph -TenantId $TenantId -Scopes $scopes -NoWelcome -ErrorAction Stop

    $results = @()
    foreach ($name in $endpoints.Keys) {
        Write-InventoryLog "Reading $name"
        try {
            $value = Invoke-MgGraphRequest -Method GET -Uri $endpoints[$name] -ErrorAction Stop
            $json = $value | ConvertTo-Json -Depth 20
            Set-Content -Path (Join-Path $OutputPath "$name.json") -Value $json -Encoding UTF8
            $results += [pscustomobject]@{
                Scope    = $name
                Readable = $true
                Error    = ""
            }
        }
        catch {
            $results += [pscustomobject]@{
                Scope    = $name
                Readable = $false
                Error    = $_.Exception.Message
            }
        }
    }

    $identitySecurityDefaults = $null
    $authenticationMethodsPolicy = $null
    $adminConsentRequestPolicy = $null

    $identityPath = Join-Path $OutputPath "identitySecurityDefaults.json"
    if (Test-Path -LiteralPath $identityPath) {
        $identitySecurityDefaults = Get-Content -Raw $identityPath | ConvertFrom-Json
    }
    $authMethodsPath = Join-Path $OutputPath "authenticationMethodsPolicy.json"
    if (Test-Path -LiteralPath $authMethodsPath) {
        $authenticationMethodsPolicy = Get-Content -Raw $authMethodsPath | ConvertFrom-Json
    }
    $adminConsentPath = Join-Path $OutputPath "adminConsentRequestPolicy.json"
    if (Test-Path -LiteralPath $adminConsentPath) {
        $adminConsentRequestPolicy = Get-Content -Raw $adminConsentPath | ConvertFrom-Json
    }

    $methodRows = @()
    if ($authenticationMethodsPolicy -and $authenticationMethodsPolicy.authenticationMethodConfigurations) {
        $methodRows = @($authenticationMethodsPolicy.authenticationMethodConfigurations | ForEach-Object {
            [pscustomobject]@{ Id = $_.id; State = $_.state }
        })
    }

    $summary = [pscustomobject]@{
        GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
        SecurityDefaultsEnabled = if ($identitySecurityDefaults) { $identitySecurityDefaults.isEnabled } else { $null }
        AuthenticationMethodsPolicyVersion = if ($authenticationMethodsPolicy) { $authenticationMethodsPolicy.policyVersion } else { $null }
        AuthenticationMethodConfigurations = $methodRows
        AdminConsentRequestEnabled = if ($adminConsentRequestPolicy) { $adminConsentRequestPolicy.isEnabled } else { $null }
        AdminConsentNotifyReviewers = if ($adminConsentRequestPolicy) { $adminConsentRequestPolicy.notifyReviewers } else { $null }
        AdminConsentRemindersEnabled = if ($adminConsentRequestPolicy) { $adminConsentRequestPolicy.remindersEnabled } else { $null }
        AdminConsentRequestDurationInDays = if ($adminConsentRequestPolicy) { $adminConsentRequestPolicy.requestDurationInDays } else { $null }
        Results = $results
    }

    $summary | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $OutputPath "policy-confirmation-summary.json") -Encoding UTF8
    $results | Format-Table -AutoSize
    Write-InventoryLog "Wrote policy confirmation outputs to $OutputPath"
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
