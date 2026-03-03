<#
.SYNOPSIS
    Installs required PowerShell modules for Delta Crown Extensions setup.
.DESCRIPTION
    Checks for and installs Microsoft.Graph, ExchangeOnlineManagement, and Az modules.
.EXAMPLE
    .\00-Install-Prerequisites.ps1
#>

#Requires -Version 7.0

$modules = @(
    @{ Name = "Microsoft.Graph"; MinVersion = "2.0.0" },
    @{ Name = "ExchangeOnlineManagement"; MinVersion = "3.0.0" },
    @{ Name = "Az"; MinVersion = "12.0.0" },
    @{ Name = "Az.Resources"; MinVersion = "7.0.0" }
)

Write-Host "`n=== Delta Crown Extensions — Module Installation ===" -ForegroundColor Cyan
Write-Host ""

foreach ($mod in $modules) {
    $installed = Get-Module -ListAvailable -Name $mod.Name | Sort-Object Version -Descending | Select-Object -First 1

    if ($installed) {
        Write-Host "[OK] $($mod.Name) v$($installed.Version) already installed" -ForegroundColor Green
    } else {
        Write-Host "[INSTALLING] $($mod.Name)..." -ForegroundColor Yellow
        try {
            Install-Module -Name $mod.Name -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
            Write-Host "[OK] $($mod.Name) installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to install $($mod.Name): $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nAll prerequisites checked." -ForegroundColor Cyan
Write-Host "Run '. .\scripts\01-Connect-Tenants.ps1' to load tenant connection functions.`n" -ForegroundColor Gray
