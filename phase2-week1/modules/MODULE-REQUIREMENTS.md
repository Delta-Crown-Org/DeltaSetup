# Module Requirements Manifest
## DeltaCrown M365 Provisioning — Required PowerShell Modules

| Module | Minimum Version | Used By | Purpose |
|--------|----------------|---------|---------|
| PnP.PowerShell | 2.0.0 | All provisioning + security scripts | SharePoint Online management |
| Microsoft.Graph.Authentication | 2.0.0 | Teams, Groups, Security scripts | Graph API authentication |
| Microsoft.Graph.Teams | 2.0.0 | Teams provisioning (Phase 3) | Teams management |
| Microsoft.Graph.Groups | 2.0.0 | Azure AD groups, security verification | Group management |
| ExchangeOnlineManagement | 3.0.0 | DLP policies, shared mailboxes | Exchange + Compliance |

## Version Policy

- **Minimum versions** are enforced via `#Requires` statements in every script
- **All scripts** must use the `@{ModuleName="...";ModuleVersion="X.Y.Z"}` syntax
- **Never** use bare module names (e.g., `#Requires -Modules PnP.PowerShell`) without version
- **Version bumps** require updating this manifest AND all affected scripts

## Pre-Flight Check

Run this before any deployment:

```powershell
$requiredModules = @(
    @{Name="PnP.PowerShell"; MinVersion="2.0.0"}
    @{Name="Microsoft.Graph.Authentication"; MinVersion="2.0.0"}
    @{Name="Microsoft.Graph.Teams"; MinVersion="2.0.0"}
    @{Name="Microsoft.Graph.Groups"; MinVersion="2.0.0"}
    @{Name="ExchangeOnlineManagement"; MinVersion="3.0.0"}
)

foreach ($mod in $requiredModules) {
    $installed = Get-Module -ListAvailable -Name $mod.Name | 
        Sort-Object Version -Descending | Select-Object -First 1
    if ($installed -and $installed.Version -ge [Version]$mod.MinVersion) {
        Write-Host "✅ $($mod.Name) v$($installed.Version) (requires >= $($mod.MinVersion))" -ForegroundColor Green
    } elseif ($installed) {
        Write-Host "⚠️ $($mod.Name) v$($installed.Version) — UPGRADE NEEDED (requires >= $($mod.MinVersion))" -ForegroundColor Yellow
    } else {
        Write-Host "❌ $($mod.Name) — NOT INSTALLED (requires >= $($mod.MinVersion))" -ForegroundColor Red
    }
}
```

## Installation

```powershell
Install-Module PnP.PowerShell -MinimumVersion 2.0.0 -Scope CurrentUser
Install-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0 -Scope CurrentUser
Install-Module Microsoft.Graph.Teams -MinimumVersion 2.0.0 -Scope CurrentUser
Install-Module Microsoft.Graph.Groups -MinimumVersion 2.0.0 -Scope CurrentUser
Install-Module ExchangeOnlineManagement -MinimumVersion 3.0.0 -Scope CurrentUser
```
