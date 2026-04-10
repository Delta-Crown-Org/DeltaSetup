#Requires -Modules @{ModuleName="Pester";ModuleVersion="5.0.0"}

BeforeAll {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path $ProjectRoot "phase2-week1" "modules" "DeltaCrown.Auth.psm1"
    $content = Get-Content $ModulePath -Raw
}

Describe "DeltaCrown.Auth Module Structure" {
    It "Should export Connect-DeltaCrownSharePoint" {
        $content | Should -Match "'Connect-DeltaCrownSharePoint'"
    }

    It "Should export Connect-DeltaCrownGraph" {
        $content | Should -Match "'Connect-DeltaCrownGraph'"
    }

    It "Should export Connect-DeltaCrownExchange" {
        $content | Should -Match "'Connect-DeltaCrownExchange'"
    }

    It "Should export Connect-DeltaCrownIPPS" {
        $content | Should -Match "'Connect-DeltaCrownIPPS'"
    }

    It "Should export Disconnect-DeltaCrownAll" {
        $content | Should -Match "'Disconnect-DeltaCrownAll'"
    }

    It "Should block interactive auth in Production for SharePoint" {
        $content | Should -Match 'Interactive authentication is NOT allowed in Production'
    }

    It "Should block interactive auth in Production for Exchange" {
        # Check that the Exchange function also blocks production interactive
        $exchangeSection = ($content -split 'function Connect-DeltaCrownExchange')[1]
        $exchangeSection = ($exchangeSection -split 'function ')[0]
        $exchangeSection | Should -Match 'NOT allowed in Production'
    }

    It "Should block interactive auth in Production for IPPS" {
        $ippsSection = ($content -split 'function Connect-DeltaCrownIPPS')[1]
        $ippsSection = ($ippsSection -split 'function ')[0]
        $ippsSection | Should -Match 'NOT allowed in Production'
    }

    It "Should have retry logic for all Connect functions" {
        $content | Should -Match 'function Connect-DeltaCrownSharePoint'
        $content | Should -Match 'function Connect-DeltaCrownGraph'
        $content | Should -Match 'function Connect-DeltaCrownExchange'
        $content | Should -Match 'function Connect-DeltaCrownIPPS'
        # All should have RetryCount parameter
        ([regex]::Matches($content, '\$RetryCount')).Count | Should -BeGreaterOrEqual 4
    }

    It "Should disconnect Exchange in Disconnect-DeltaCrownAll" {
        $disconnectSection = ($content -split 'function Disconnect-DeltaCrownAll')[1]
        $disconnectSection = ($disconnectSection -split 'function ')[0]
        $disconnectSection | Should -Match 'Disconnect-ExchangeOnline'
    }

    It "Should NOT contain hardcoded tenant names" {
        $content | Should -Not -Match 'deltacrownext(?!.*\$)'
    }
}
