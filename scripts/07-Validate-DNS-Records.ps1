<#
.SYNOPSIS
    Validates SPF, DKIM, and DMARC DNS records for deltacrown.com.
.DESCRIPTION
    Uses Resolve-DnsName to check email authentication records and reports Pass/Fail.
.EXAMPLE
    .\07-Validate-DNS-Records.ps1
#>

#Requires -Version 7.0

# Load config
$configPath = Join-Path $PSScriptRoot "..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$domain = $config.tenants.target.domain

Write-Host "`n=== DNS Record Validation — $domain ===" -ForegroundColor Cyan
Write-Host ""

$results = @()

# ---- SPF Check ----
Write-Host "Checking SPF record..." -ForegroundColor Yellow
try {
    $spfRecords = Resolve-DnsName -Name $domain -Type TXT -ErrorAction Stop |
        Where-Object { $_.Strings -like "*spf*" }

    if ($spfRecords) {
        $spfValue = ($spfRecords.Strings | Where-Object { $_ -like "*spf*" }) -join ""
        $spfPass = $spfValue -like "*include:spf.protection.outlook.com*"
        if ($spfPass) {
            Write-Host "  [PASS] SPF: $spfValue" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] SPF exists but missing spf.protection.outlook.com: $spfValue" -ForegroundColor Yellow
        }
        $results += [PSCustomObject]@{ Record = "SPF"; Status = if ($spfPass) { "PASS" } else { "WARN" }; Value = $spfValue }
    } else {
        Write-Host "  [FAIL] No SPF record found" -ForegroundColor Red
        $results += [PSCustomObject]@{ Record = "SPF"; Status = "FAIL"; Value = "Not found" }
    }
} catch {
    Write-Host "  [FAIL] DNS lookup failed: $_" -ForegroundColor Red
    $results += [PSCustomObject]@{ Record = "SPF"; Status = "FAIL"; Value = "DNS error" }
}

# ---- DKIM Check ----
Write-Host "Checking DKIM records..." -ForegroundColor Yellow
foreach ($selector in @("selector1", "selector2")) {
    $dkimHost = "$selector._domainkey.$domain"
    try {
        $dkimRecord = Resolve-DnsName -Name $dkimHost -Type CNAME -ErrorAction Stop
        if ($dkimRecord) {
            $target = $dkimRecord.NameHost
            Write-Host "  [PASS] $($selector): $target" -ForegroundColor Green
            $results += [PSCustomObject]@{ Record = "DKIM ($selector)"; Status = "PASS"; Value = $target }
        } else {
            Write-Host "  [FAIL] $($selector): No CNAME record" -ForegroundColor Red
            $results += [PSCustomObject]@{ Record = "DKIM ($selector)"; Status = "FAIL"; Value = "Not found" }
        }
    } catch {
        Write-Host "  [FAIL] $($selector): $_" -ForegroundColor Red
        $results += [PSCustomObject]@{ Record = "DKIM ($selector)"; Status = "FAIL"; Value = "DNS error" }
    }
}

# ---- DMARC Check ----
Write-Host "Checking DMARC record..." -ForegroundColor Yellow
try {
    $dmarcRecords = Resolve-DnsName -Name "_dmarc.$domain" -Type TXT -ErrorAction Stop
    if ($dmarcRecords) {
        $dmarcValue = ($dmarcRecords.Strings) -join ""
        $dmarcPass = $dmarcValue -like "*v=DMARC1*"
        if ($dmarcPass) {
            Write-Host "  [PASS] DMARC: $dmarcValue" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] TXT record found but not valid DMARC: $dmarcValue" -ForegroundColor Yellow
        }
        $results += [PSCustomObject]@{ Record = "DMARC"; Status = if ($dmarcPass) { "PASS" } else { "WARN" }; Value = $dmarcValue }
    } else {
        Write-Host "  [FAIL] No DMARC record found" -ForegroundColor Red
        $results += [PSCustomObject]@{ Record = "DMARC"; Status = "FAIL"; Value = "Not found" }
    }
} catch {
    Write-Host "  [FAIL] DNS lookup failed: $_" -ForegroundColor Red
    $results += [PSCustomObject]@{ Record = "DMARC"; Status = "FAIL"; Value = "DNS error" }
}

# ---- MX Check (bonus) ----
Write-Host "Checking MX record..." -ForegroundColor Yellow
try {
    $mxRecords = Resolve-DnsName -Name $domain -Type MX -ErrorAction Stop
    if ($mxRecords) {
        foreach ($mx in $mxRecords) {
            $isO365 = $mx.NameExchange -like "*mail.protection.outlook.com*"
            $status = if ($isO365) { "PASS" } else { "INFO" }
            Write-Host "  [$status] MX: $($mx.NameExchange) (Priority: $($mx.Preference))" -ForegroundColor $(if ($isO365) { "Green" } else { "Cyan" })
            $results += [PSCustomObject]@{ Record = "MX"; Status = $status; Value = "$($mx.NameExchange) (pri: $($mx.Preference))" }
        }
    }
} catch {
    Write-Host "  [FAIL] MX lookup failed" -ForegroundColor Red
    $results += [PSCustomObject]@{ Record = "MX"; Status = "FAIL"; Value = "DNS error" }
}

# Summary
Write-Host "`n=== DNS Validation Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
if ($failCount -gt 0) {
    Write-Host "[WARN] $failCount record(s) failed validation. See docs/05-dns-spf-dkim-dmarc.md" -ForegroundColor Yellow
} else {
    Write-Host "[OK] All DNS records validated successfully!" -ForegroundColor Green
}
Write-Host ""
