#Requires -Modules @{ModuleName="Pester";ModuleVersion="5.0.0"}

BeforeAll {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ScriptsPath = Join-Path $ProjectRoot "phase3-week2" "scripts"
}

Describe "3.1 Site Configuration" {
    BeforeAll {
        # Dot-source just the config section (not the execution)
        # We'll parse the file to extract $DCESites and $SiteSchemas
        $content = Get-Content (Join-Path $ScriptsPath "3.1-DCE-Sites-Provisioning.ps1") -Raw

        # Extract site definitions by pattern matching
        $siteCount = ([regex]::Matches($content, '@\{\s*Url\s*=\s*"/sites/dce-')).Count
    }

    It "Should define exactly 4 DCE sites" {
        $siteCount | Should -Be 4
    }

    It "Should include DCE-Operations" {
        $content | Should -Match '"/sites/dce-operations"'
    }

    It "Should include DCE-ClientServices" {
        $content | Should -Match '"/sites/dce-clientservices"'
    }

    It "Should include DCE-Marketing as CommunicationSite" {
        $content | Should -Match 'SITEPAGEPUBLISHING#0'
    }

    It "Should include DCE-Docs" {
        $content | Should -Match '"/sites/dce-docs"'
    }

    It "Should define Bookings list with required columns" {
        $content | Should -Match '"Bookings"'
        $content | Should -Match '"ServiceType"'
        $content | Should -Match '"BookingDate"'
        $content | Should -Match '"Stylist"'
    }

    It "Should define Client Records with PII columns" {
        $content | Should -Match '"Client Records"'
        $content | Should -Match '"AllergyNotes"'
        $content | Should -Match '"Email"'
        $content | Should -Match '"Phone"'
    }

    It "Should use SupportsShouldProcess" {
        $content | Should -Match '\[CmdletBinding\(SupportsShouldProcess\)\]'
    }

    It "Should import DeltaCrown.Auth module" {
        $content | Should -Match 'DeltaCrown\.Auth\.psm1'
    }

    It "Should NOT contain Read-Host in executable code" {
        # Exclude comments — scripts may reference Read-Host in docs explaining its removal
        $codeLines = ($content -split "`n") | Where-Object { $_ -notmatch '^\s*#' }
        ($codeLines -join "`n") | Should -Not -Match 'Read-Host'
    }

    It "Should NOT contain hardcoded backslash paths" {
        # Allow backslashes in regex patterns and comments, but not in Join-Path-able paths
        $codeLines = ($content -split "`n") | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch 'regex|pattern|\\n|\\t|\\r|\\\$|\\.' }
        $pathViolations = $codeLines | Where-Object { $_ -match '"[^"]*\\[^"]*modules[^"]*"' -or $_ -match '"[^"]*\\[^"]*scripts[^"]*"' }
        $pathViolations.Count | Should -Be 0
    }
}

Describe "3.3 Security Configuration" {
    BeforeAll {
        $content = Get-Content (Join-Path $ScriptsPath "3.3-Security-Hardening.ps1") -Raw
    }

    It "Should define forbidden groups list" {
        $content | Should -Match '"Everyone"'
        $content | Should -Match '"Everyone except external users"'
        $content | Should -Match '"All Users"'
    }

    It "Should define permission matrix" {
        $content | Should -Match 'PermissionMatrix'
    }

    It "Should reference all 4 DCE sites in permission matrix" {
        $content | Should -Match '"/sites/dce-hub"'
        $content | Should -Match '"/sites/dce-clientservices"'
        $content | Should -Match '"/sites/dce-marketing"'
        $content | Should -Match '"/sites/dce-docs"'
    }

    It "Should NOT contain raw Connect-PnPOnline in helper functions" {
        # Helper functions should use Connect-DeltaCrownSharePoint, not raw Connect-PnPOnline
        # Extract function bodies (between 'function ' and next 'function ' or section marker)
        $helperFunctions = [regex]::Matches($content, '(?s)function\s+(Set-|Remove-|Disable-|Get-DCE)\w+.*?(?=function\s|\#\s*(STEP|MAIN|={5,}))')
        foreach ($fn in $helperFunctions) {
            $fn.Value | Should -Not -Match 'Connect-PnPOnline'
        }
    }

    It "Should use connection ownership pattern" {
        $content | Should -Match '\$script:OwnsPnPConnection'
        $content | Should -Match '\$script:OwnsGraphConnection'
    }

    It "Should create Marketing group" {
        $content | Should -Match 'Marketing'
    }
}

Describe "3.4 DLP Policy Configuration" {
    BeforeAll {
        $content = Get-Content (Join-Path $ScriptsPath "3.4-DLP-Policies.ps1") -Raw
    }

    It "Should define exactly 3 DLP policies" {
        $policyMatches = [regex]::Matches($content, 'Name\s*=\s*"[A-Z].*Protection"|Name\s*=\s*"External-Sharing-Block"')
        $policyMatches.Count | Should -Be 3
    }

    It "Should use TestWithNotifications mode for brand policies" {
        $content | Should -Match '"TestWithNotifications"'
    }

    It "Should use Enable (enforce) mode for external sharing block" {
        $content | Should -Match 'Mode\s*=\s*"Enable"'
    }

    It "Should default to 30-day test period (SEC-002-1)" {
        $content | Should -Match '\$TestPeriodDays\s*=\s*30'
    }

    It "Should have AccessScope conditions on rules (not no-ops)" {
        $content | Should -Match 'AccessScope'
    }

    It "Should import DeltaCrown.Auth module" {
        $content | Should -Match 'DeltaCrown\.Auth\.psm1'
    }
}

Describe "3.7 Verification Coverage" {
    BeforeAll {
        $content = Get-Content (Join-Path $ScriptsPath "3.7-Phase3-Verification.ps1") -Raw
    }

    It "Should verify DLP policies (Category 8)" {
        $content | Should -Match 'DLP Policies'
        $content | Should -Match 'Get-DlpCompliancePolicy'
    }

    It "Should verify shared mailboxes (Category 9)" {
        $content | Should -Match 'Shared Mailboxes'
        $content | Should -Match 'Get-Mailbox'
    }

    It "Should check for forbidden groups" {
        $content | Should -Match '"Everyone"'
    }

    It "Should verify PII columns on Client Records" {
        $content | Should -Match 'AllergyNotes'
    }

    It "Should include ScriptVersion in JSON report" {
        $content | Should -Match 'ScriptVersion'
    }

    It "Should include TenantName in JSON report" {
        $content | Should -Match 'TenantName.*=.*\$TenantName'
    }

    It "Should use script scope (not global)" {
        $content | Should -Not -Match '\$global:'
    }

    It "Should define 3 exit codes" {
        $content | Should -Match 'exit 0'
        $content | Should -Match 'exit 1'
        $content | Should -Match 'exit 2'
    }
}

Describe "All Scripts: Auth Pattern Compliance" {
    BeforeAll {
        $scripts = Get-ChildItem -Path $ScriptsPath -Filter "3.*.ps1"
    }

    It "All scripts should exist (8 total)" {
        $scripts.Count | Should -Be 8
    }

    foreach ($script in (Get-ChildItem -Path $ScriptsPath -Filter "3.*.ps1")) {
        Context $script.Name {
            BeforeAll {
                $scriptContent = Get-Content $script.FullName -Raw
            }

            It "Should NOT contain direct Connect-PnPOnline -Interactive" {
                $scriptContent | Should -Not -Match 'Connect-PnPOnline\s+-Url\s+.*-Interactive'
            }

            It "Should NOT contain direct Connect-MgGraph" {
                # 3.0 Master may not need Graph directly
                if ($script.Name -ne "3.0-Master-Phase3.ps1") {
                    # Allow in comments
                    $codeLines = ($scriptContent -split "`n") | Where-Object { $_ -notmatch '^\s*#' }
                    $directGraphCalls = $codeLines | Where-Object { $_ -match 'Connect-MgGraph\s' }
                    $directGraphCalls.Count | Should -Be 0
                }
            }

            It "Should NOT contain hardcoded backslash path joins" {
                # Check for "string\string" patterns that should use Join-Path
                $codeLines = ($scriptContent -split "`n") | Where-Object { $_ -notmatch '^\s*#' }
                $backslashPaths = $codeLines | Where-Object { $_ -match '"phase[23]-week[12]\\' }
                $backslashPaths.Count | Should -Be 0
            }

            It "Should use Join-Path for path construction" {
                $scriptContent | Should -Match 'Join-Path'
            }

            It "Should have error handling (try/catch)" {
                $scriptContent | Should -Match 'try\s*\{'
                $scriptContent | Should -Match 'catch\s*\{'
            }
        }
    }
}

Describe "Master Orchestrator (3.0)" {
    BeforeAll {
        $content = Get-Content (Join-Path $ScriptsPath "3.0-Master-Phase3.ps1") -Raw
    }

    It "Should pre-authenticate to SharePoint" {
        $content | Should -Match 'Connect-DeltaCrownSharePoint'
    }

    It "Should pre-authenticate to Graph" {
        $content | Should -Match 'Connect-DeltaCrownGraph'
    }

    It "Should pre-authenticate to Exchange (conditional)" {
        $content | Should -Match 'Connect-DeltaCrownExchange'
    }

    It "Should pre-authenticate to IPPS (conditional)" {
        $content | Should -Match 'Connect-DeltaCrownIPPS'
    }

    It "Should disconnect all in finally" {
        $content | Should -Match 'Disconnect-DeltaCrownAll'
    }

    It "Should NOT use LASTEXITCODE for pre-check" {
        $content | Should -Not -Match '\$LASTEXITCODE'
    }

    It "Should define all 7 steps in execution plan" {
        $stepMatches = [regex]::Matches($content, 'Id\s*=\s*"3\.\d"')
        $stepMatches.Count | Should -Be 7
    }
}
