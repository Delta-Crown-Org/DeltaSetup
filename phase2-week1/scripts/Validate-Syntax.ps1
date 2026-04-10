# Syntax validation for all Phase 2 scripts
$scripts = @(
    'scripts/2.0-Master-Provisioning.ps1',
    'scripts/2.1-CorpHub-Provisioning.ps1',
    'scripts/2.2-DCEHub-Provisioning.ps1',
    'scripts/2.3-AzureAD-DynamicGroups.ps1',
    'scripts/2.4-Verification.ps1',
    'scripts/security-controls/Test-CrossBrandIsolation.ps1',
    'scripts/security-controls/Security-Configuration-Verification.ps1'
)

$results = @()
foreach ($script in $scripts) {
    $content = Get-Content -Path $script -Raw -ErrorAction SilentlyContinue
    if (!$content) {
        $results += [PSCustomObject]@{ Script = $script; Status = 'NOT_FOUND'; Errors = 'File not found' }
        continue
    }
    
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
    
    if ($errors.Count -eq 0) {
        $results += [PSCustomObject]@{ Script = $script; Status = 'VALID'; Errors = 'None' }
    } else {
        $errorMsg = ($errors | ForEach-Object { $_.Message }) -join '; '
        $results += [PSCustomObject]@{ Script = $script; Status = 'SYNTAX_ERROR'; Errors = $errorMsg }
    }
}

$results | ConvertTo-Json -AsArray
