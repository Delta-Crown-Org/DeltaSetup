<#
.SYNOPSIS
    Runs end-to-end validation tests for the Delta Crown Extensions setup.
.DESCRIPTION
    Checks synced users, shared mailboxes, permissions, groups, and DNS records.
    Outputs a comprehensive validation report.
.EXAMPLE
    .\08-Validation-Tests.ps1
#>

#Requires -Version 7.0

# Load config
$configPath = Join-Path $PSScriptRoot "..\config\tenant-config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$sourceTenant = $config.tenants.source
$targetTenant = $config.tenants.target

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  DELTA CROWN EXTENSIONS — FULL VALIDATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allResults = @()

# ---- Test 1: Synced Users in DCE Tenant ----
Write-Host "=== Test 1: Cross-Tenant Synced Users ===" -ForegroundColor Yellow
try {
    Connect-MgGraph -TenantId $targetTenant.tenantId -Scopes "User.Read.All" -NoWelcome
    $syncedUsers = Get-MgUser -Filter "creationType eq 'Invitation' and userType eq 'Member'" -Property DisplayName, UserPrincipalName, UserType, CreationType -All

    if ($syncedUsers.Count -gt 0) {
        Write-Host "[PASS] Found $($syncedUsers.Count) synced member-type user(s):" -ForegroundColor Green
        foreach ($u in $syncedUsers) {
            Write-Host "  - $($u.DisplayName) ($($u.UserPrincipalName)) [Type: $($u.UserType)]" -ForegroundColor Gray
        }
        $allResults += [PSCustomObject]@{ Test = "Synced Users"; Result = "PASS"; Detail = "$($syncedUsers.Count) users found" }
    } else {
        Write-Host "[FAIL] No synced member-type users found in DCE tenant" -ForegroundColor Red
        Write-Host "  → Run cross-tenant sync configuration (Phase 2)" -ForegroundColor Gray
        $allResults += [PSCustomObject]@{ Test = "Synced Users"; Result = "FAIL"; Detail = "No synced users" }
    }
    Disconnect-MgGraph -ErrorAction SilentlyContinue
} catch {
    Write-Host "[ERROR] Could not check users: $_" -ForegroundColor Red
    $allResults += [PSCustomObject]@{ Test = "Synced Users"; Result = "ERROR"; Detail = "$_" }
}

# ---- Test 2: Shared Mailboxes ----
Write-Host "`n=== Test 2: Shared Mailboxes ===" -ForegroundColor Yellow
try {
    Connect-ExchangeOnline -Organization $targetTenant.domain -ShowBanner:$false
    $sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

    if ($sharedMailboxes.Count -gt 0) {
        Write-Host "[PASS] Found $($sharedMailboxes.Count) shared mailbox(es):" -ForegroundColor Green
        foreach ($mb in $sharedMailboxes) {
            Write-Host "  - $($mb.DisplayName) ($($mb.PrimarySmtpAddress))" -ForegroundColor Gray

            # Check Send-As permissions
            $sendAs = Get-RecipientPermission -Identity $mb.PrimarySmtpAddress | Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" }
            if ($sendAs) {
                foreach ($perm in $sendAs) {
                    Write-Host "    Send-As: $($perm.Trustee)" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "    [WARN] No Send-As permissions configured" -ForegroundColor Yellow
            }
        }
        $allResults += [PSCustomObject]@{ Test = "Shared Mailboxes"; Result = "PASS"; Detail = "$($sharedMailboxes.Count) mailboxes" }
    } else {
        Write-Host "[FAIL] No shared mailboxes found" -ForegroundColor Red
        $allResults += [PSCustomObject]@{ Test = "Shared Mailboxes"; Result = "FAIL"; Detail = "None found" }
    }
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
} catch {
    Write-Host "[ERROR] Could not check mailboxes: $_" -ForegroundColor Red
    $allResults += [PSCustomObject]@{ Test = "Shared Mailboxes"; Result = "ERROR"; Detail = "$_" }
}

# ---- Test 3: M365 Groups ----
Write-Host "`n=== Test 3: Microsoft 365 Groups ===" -ForegroundColor Yellow
try {
    Connect-MgGraph -TenantId $targetTenant.tenantId -Scopes "Group.Read.All" -NoWelcome

    foreach ($grp in $config.groups) {
        $existing = Get-MgGroup -Filter "mailNickname eq '$($grp.mailNickname)'" -ErrorAction SilentlyContinue
        if ($existing) {
            $memberCount = (Get-MgGroupMember -GroupId $existing.Id -All).Count
            Write-Host "[PASS] $($grp.displayName) — $memberCount member(s)" -ForegroundColor Green
            $allResults += [PSCustomObject]@{ Test = "Group: $($grp.displayName)"; Result = "PASS"; Detail = "$memberCount members" }
        } else {
            Write-Host "[FAIL] $($grp.displayName) — not found" -ForegroundColor Red
            $allResults += [PSCustomObject]@{ Test = "Group: $($grp.displayName)"; Result = "FAIL"; Detail = "Not created" }
        }
    }
    Disconnect-MgGraph -ErrorAction SilentlyContinue
} catch {
    Write-Host "[ERROR] Could not check groups: $_" -ForegroundColor Red
    $allResults += [PSCustomObject]@{ Test = "M365 Groups"; Result = "ERROR"; Detail = "$_" }
}

# ---- Test 4: DNS Records ----
Write-Host "`n=== Test 4: DNS Records ===" -ForegroundColor Yellow
$domain = $targetTenant.domain

# SPF
try {
    $spf = Resolve-DnsName -Name $domain -Type TXT -ErrorAction Stop | Where-Object { $_.Strings -like "*spf*" }
    if ($spf -and ($spf.Strings -join "") -like "*spf.protection.outlook.com*") {
        Write-Host "[PASS] SPF configured correctly" -ForegroundColor Green
        $allResults += [PSCustomObject]@{ Test = "DNS: SPF"; Result = "PASS"; Detail = ($spf.Strings -join "") }
    } else {
        Write-Host "[FAIL] SPF missing or misconfigured" -ForegroundColor Red
        $allResults += [PSCustomObject]@{ Test = "DNS: SPF"; Result = "FAIL"; Detail = "Check docs/05" }
    }
} catch {
    $allResults += [PSCustomObject]@{ Test = "DNS: SPF"; Result = "FAIL"; Detail = "DNS error" }
}

# DKIM
foreach ($sel in @("selector1", "selector2")) {
    try {
        $dkim = Resolve-DnsName -Name "$sel._domainkey.$domain" -Type CNAME -ErrorAction Stop
        if ($dkim) {
            Write-Host "[PASS] DKIM $sel configured" -ForegroundColor Green
            $allResults += [PSCustomObject]@{ Test = "DNS: DKIM ($sel)"; Result = "PASS"; Detail = $dkim.NameHost }
        }
    } catch {
        Write-Host "[FAIL] DKIM $sel not found" -ForegroundColor Red
        $allResults += [PSCustomObject]@{ Test = "DNS: DKIM ($sel)"; Result = "FAIL"; Detail = "Not found" }
    }
}

# DMARC
try {
    $dmarc = Resolve-DnsName -Name "_dmarc.$domain" -Type TXT -ErrorAction Stop
    if ($dmarc -and ($dmarc.Strings -join "") -like "*v=DMARC1*") {
        Write-Host "[PASS] DMARC configured" -ForegroundColor Green
        $allResults += [PSCustomObject]@{ Test = "DNS: DMARC"; Result = "PASS"; Detail = ($dmarc.Strings -join "") }
    }
} catch {
    Write-Host "[FAIL] DMARC not found" -ForegroundColor Red
    $allResults += [PSCustomObject]@{ Test = "DNS: DMARC"; Result = "FAIL"; Detail = "Not found" }
}

# ---- FINAL REPORT ----
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  VALIDATION REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$allResults | Format-Table -AutoSize

$passCount = ($allResults | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = ($allResults | Where-Object { $_.Result -eq "FAIL" }).Count
$errorCount = ($allResults | Where-Object { $_.Result -eq "ERROR" }).Count
$total = $allResults.Count

Write-Host "Results: $passCount PASS / $failCount FAIL / $errorCount ERROR (out of $total tests)" -ForegroundColor $(if ($failCount -eq 0 -and $errorCount -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
