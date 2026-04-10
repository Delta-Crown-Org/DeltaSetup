# ============================================================================
# DeltaCrown.Common.psm1
# Shared Functions Module for Delta Crown Extensions
# ============================================================================
# DESCRIPTION: Common utilities including logging, validation, rollback,
#              polling, and error handling patterns.
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

$script:LogBuffer = [System.Collections.ArrayList]::new()
$script:RollbackStack = [System.Collections.Stack]::new()
$script:Config = $null

#region Logging

<#
.SYNOPSIS
    Writes a log entry with timestamp and severity level.
.DESCRIPTION
    Enhanced logging with structured output and multiple targets.
#>
function Write-DeltaCrownLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Message,
        
        [Parameter(Position=1)]
        [ValidateSet("DEBUG", "INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL", "STAGE")]
        [string]$Level = "INFO",
        
        [Parameter()]
        [string]$LogFile = $null,
        
        [Parameter()]
        [switch]$NoConsole,
        
        [Parameter()]
        [switch]$IncludeContext,
        
        [Parameter()]
        [System.Exception]$Exception = $null
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $caller = (Get-PSCallStack)[1].Command
    $logEntry = "[$timestamp] [$Level]"
    
    if ($IncludeContext) {
        $logEntry += " [$caller]"
    }
    
    $logEntry += " $Message"
    
    # Add exception details if provided
    if ($Exception) {
        $logEntry += "`n  Exception: $($Exception.GetType().Name): $($Exception.Message)"
        $logEntry += "`n  Stack: $($Exception.StackTrace)"
    }
    
    # Color mapping for console
    $color = switch ($Level) {
        "DEBUG" { "DarkGray" }
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "CRITICAL" { "Magenta" }
        "STAGE" { "Blue" }
        default { "White" }
    }
    
    # Console output
    if (!$NoConsole) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # Buffer for later flush
    $null = $script:LogBuffer.Add($logEntry)
    
    # Direct file write if specified
    if ($LogFile) {
        $logDir = Split-Path -Parent $LogFile
        if (!(Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $logEntry
    }
}

<#
.SYNOPSIS
    Writes a formatted banner for major sections.
#>
function Write-DeltaCrownBanner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter()]
        [string]$LogFile = $null
    )
    
    $banner = @"

================================================================================
  $Title
================================================================================
"@
    
    Write-Host $banner -ForegroundColor Blue
    
    if ($LogFile) {
        Add-Content -Path $LogFile -Value $banner
    }
}

<#
.SYNOPSIS
    Flushes the log buffer to file.
#>
function Export-DeltaCrownLogBuffer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    $logDir = Split-Path -Parent $Path
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $script:LogBuffer | Out-File -FilePath $Path -Force
    $script:LogBuffer.Clear()
}

#endregion

#region Validation

<#
.SYNOPSIS
    Validates an email address format.
#>
function Test-DeltaCrownEmailFormat {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Email
    )
    
    process {
        $pattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return $Email -match $pattern
    }
}

<#
.SYNOPSIS
    Validates a SharePoint tenant name format.
#>
function Test-DeltaCrownTenantName {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$TenantName
    )
    
    # Tenant names: alphanumeric and hyphens, 3-64 chars, no spaces
    $pattern = '^[a-zA-Z0-9-]{3,64}$'
    return $TenantName -match $pattern
}

<#
.SYNOPSIS
    Validates a SharePoint URL.
#>
function Test-DeltaCrownSharePointUrl {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )
    
    $pattern = '^https://[a-zA-Z0-9-]+\.sharepoint\.com(/sites/[a-zA-Z0-9-]+)?$'
    return $Url -match $pattern
}

<#
.SYNOPSIS
    Validates required modules are installed with minimum versions.
#>
function Test-DeltaCrownPrerequisites {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$RequiredModules = @{
            "PnP.PowerShell" = "2.0.0"
            "Microsoft.Graph.Authentication" = "2.0.0"
            "Microsoft.Graph.Groups" = "2.0.0"
            "Microsoft.Graph.Identity.DirectoryManagement" = "2.0.0"
        }
    )
    
    $results = @()
    $allPassed = $true
    
    foreach ($moduleName in $RequiredModules.Keys) {
        $requiredVersion = [version]$RequiredModules[$moduleName]
        $installedModule = Get-Module -ListAvailable -Name $moduleName | 
            Sort-Object Version -Descending | 
            Select-Object -First 1
        
        $status = "FAIL"
        $currentVersion = "Not Installed"
        
        if ($installedModule) {
            $currentVersion = $installedModule.Version
            if ($installedModule.Version -ge $requiredVersion) {
                $status = "PASS"
            }
            else {
                $status = "VERSION_MISMATCH"
                $allPassed = $false
            }
        }
        else {
            $allPassed = $false
        }
        
        $results += [PSCustomObject]@{
            Module = $moduleName
            RequiredVersion = $requiredVersion
            CurrentVersion = $currentVersion
            Status = $status
        }
    }
    
    # PowerShell version check
    $results += [PSCustomObject]@{
        Module = "PowerShell"
        RequiredVersion = "5.1"
        CurrentVersion = $PSVersionTable.PSVersion.ToString()
        Status = if ($PSVersionTable.PSVersion.Major -ge 5) { "PASS" } else { "FAIL" }
    }
    
    return [PSCustomObject]@{
        Results = $results
        AllPassed = $allPassed
    }
}

#endregion

#region Polling and Retry

<#
.SYNOPSIS
    Polls a condition with timeout instead of using fixed delays.
.DESCRIPTION
    Replaces arbitrary Start-Sleep calls with intelligent polling.
#>
function Wait-DeltaCrownCondition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Condition,
        
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSeconds = 60,
        
        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$IntervalSeconds = 5,
        
        [Parameter()]
        [string]$ActivityMessage = "Waiting for condition...",
        
        [Parameter()]
        [scriptblock]$OnTimeout = { throw "Polling timed out after $TimeoutSeconds seconds" }
    )
    
    $elapsed = 0
    
    while ($elapsed -lt $TimeoutSeconds) {
        Write-Progress -Activity $ActivityMessage -Status "${elapsed}s elapsed" -PercentComplete (($elapsed / $TimeoutSeconds) * 100)
        
        $result = & $Condition
        if ($result) {
            Write-Progress -Activity $ActivityMessage -Completed
            return $true
        }
        
        Start-Sleep -Seconds $IntervalSeconds
        $elapsed += $IntervalSeconds
    }
    
    Write-Progress -Activity $ActivityMessage -Completed
    & $OnTimeout
}

<#
.SYNOPSIS
    Polls for site provisioning completion.
#>
function Wait-DeltaCrownSiteProvisioned {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SiteUrl,
        
        [Parameter()]
        [int]$TimeoutSeconds = 120
    )
    
    Wait-DeltaCrownCondition `
        -Condition { 
            try {
                $site = Get-PnPTenantSite -Url $SiteUrl -ErrorAction SilentlyContinue
                return $site -and $site.Status -eq "Active"
            }
            catch { return $false }
        } `
        -TimeoutSeconds $TimeoutSeconds `
        -IntervalSeconds 5 `
        -ActivityMessage "Waiting for site provisioning: $SiteUrl"
}

<#
.SYNOPSIS
    Executes a script block with retry logic.
#>
function Invoke-DeltaCrownWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,
        
        [Parameter()]
        [int]$InitialDelaySeconds = 2,
        
        [Parameter()]
        [string]$OperationName = "Operation"
    )
    
    $attempt = 0
    $delay = $InitialDelaySeconds
    
    while ($attempt -lt $MaxRetries) {
        $attempt++
        
        try {
            Write-DeltaCrownLog "Attempting $OperationName (attempt $attempt/$MaxRetries)..." "DEBUG"
            $result = & $ScriptBlock
            Write-DeltaCrownLog "$OperationName succeeded on attempt $attempt" "SUCCESS"
            return $result
        }
        catch {
            if ($attempt -eq $MaxRetries) {
                Write-DeltaCrownLog "$OperationName failed after $MaxRetries attempts" "ERROR" -Exception $_.Exception
                throw
            }
            
            Write-DeltaCrownLog "$OperationName failed on attempt $attempt, retrying in ${delay}s..." "WARNING"
            Start-Sleep -Seconds $delay
            $delay *= 2  # Exponential backoff
        }
    }
}

#endregion

#region Rollback Mechanisms

<#
.SYNOPSIS
    Registers a rollback action to be executed on failure.
#>
function Register-DeltaCrownRollbackAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,
        
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    $rollbackItem = [PSCustomObject]@{
        Name = $ActionName
        Action = $Action
        Context = $Context
        RegisteredAt = Get-Date
    }
    
    $script:RollbackStack.Push($rollbackItem)
    Write-DeltaCrownLog "Registered rollback action: $ActionName" "DEBUG"
}

<#
.SYNOPSIS
    Executes all registered rollback actions in LIFO order.
#>
function Invoke-DeltaCrownRollback {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Reason = "Execution failed",
        
        [Parameter()]
        [switch]$ContinueOnError
    )
    
    Write-DeltaCrownLog "Initiating rollback sequence. Reason: $Reason" "WARNING"
    
    $executedCount = 0
    $failedCount = 0
    
    while ($script:RollbackStack.Count -gt 0) {
        $action = $script:RollbackStack.Pop()
        
        try {
            Write-DeltaCrownLog "Executing rollback: $($action.Name)" "INFO"
            & $action.Action $action.Context
            $executedCount++
        }
        catch {
            $failedCount++
            Write-DeltaCrownLog "Rollback action failed: $($action.Name) - $($_.Exception.Message)" "ERROR"
            if (!$ContinueOnError) {
                throw
            }
        }
    }
    
    Write-DeltaCrownLog "Rollback complete. Executed: $executedCount, Failed: $failedCount" "INFO"
    
    # Clear any remaining
    $script:RollbackStack.Clear()
}

<#
.SYNOPSIS
    Clears the rollback stack (use after successful completion).
#>
function Clear-DeltaCrownRollbackStack {
    [CmdletBinding()]
    param()
    
    $count = $script:RollbackStack.Count
    $script:RollbackStack.Clear()
    Write-DeltaCrownLog "Cleared $count rollback actions from stack" "DEBUG"
}

#endregion

#region Error Handling

<#
.SYNOPSIS
    Creates a detailed error record with full context.
#>
function New-DeltaCrownErrorRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [string]$ErrorId = "DeltaCrownError",
        
        [Parameter()]
        [System.Exception]$InnerException = $null,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    $callStack = Get-PSCallStack | ForEach-Object { 
        "  at $($_.Command), $($_.ScriptName):$($_.ScriptLineNumber)" 
    } | Out-String
    
    $fullMessage = @"
$Message

Context:
$($Context | ConvertTo-Json -Depth 3)

Stack Trace:
$callStack
"@
    
    if ($InnerException) {
        $exception = [System.Exception]::new($fullMessage, $InnerException)
    }
    else {
        $exception = [System.Exception]::new($fullMessage)
    }
    
    return [System.Management.Automation.ErrorRecord]::new(
        $exception,
        $ErrorId,
        [System.Management.Automation.ErrorCategory]::OperationStopped,
        $null
    )
}

<#
.SYNOPSIS
    Wraps a script block with comprehensive error handling.
#>
function Invoke-DeltaCrownWithErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$OperationName = "Operation",
        
        [Parameter()]
        [switch]$InvokeRollbackOnError = $false
    )
    
    try {
        return & $ScriptBlock
    }
    catch {
        $errorRecord = New-DeltaCrownErrorRecord `
            -Message "$OperationName failed" `
            -ErrorId "${OperationName}Failed" `
            -InnerException $_.Exception `
            -Context @{ Operation = $OperationName; Timestamp = Get-Date }
        
        Write-DeltaCrownLog $errorRecord.Exception.Message "ERROR" -Exception $_.Exception
        
        if ($InvokeRollbackOnError) {
            Invoke-DeltaCrownRollback -Reason $errorRecord.Exception.Message
        }
        
        throw $errorRecord
    }
}

#endregion

#region Secure Configuration

<#
.SYNOPSIS
    Loads configuration from secure sources (Key Vault, env vars, or encrypted file).
#>
function Import-DeltaCrownConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = $null,
        
        [Parameter()]
        [string]$KeyVaultName = $null,
        
        [Parameter()]
        [ValidateSet("Development", "Staging", "Production")]
        [string]$Environment = "Development"
    )
    
    if ($script:Config) {
        return $script:Config
    }
    
    $config = @{}
    
    # Priority 1: Key Vault (Production)
    if ($KeyVaultName) {
        # Implementation would use Az.KeyVault
        throw "Key Vault loading not yet implemented"
    }
    
    # Priority 2: Encrypted file
    if ($Path -and (Test-Path $Path)) {
        $config = Import-Clixml -Path $Path
    }
    
    # Priority 3: Environment variables
    $config['TenantName'] = $env:DCE_TENANT_NAME
    $config['TenantId'] = $env:DCE_TENANT_ID
    $config['Environment'] = $Environment
    
    $script:Config = $config
    return $config
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    # Logging
    'Write-DeltaCrownLog'
    'Write-DeltaCrownBanner'
    'Export-DeltaCrownLogBuffer'
    
    # Validation
    'Test-DeltaCrownEmailFormat'
    'Test-DeltaCrownTenantName'
    'Test-DeltaCrownSharePointUrl'
    'Test-DeltaCrownPrerequisites'
    
    # Polling and Retry
    'Wait-DeltaCrownCondition'
    'Wait-DeltaCrownSiteProvisioned'
    'Invoke-DeltaCrownWithRetry'
    
    # Rollback
    'Register-DeltaCrownRollbackAction'
    'Invoke-DeltaCrownRollback'
    'Clear-DeltaCrownRollbackStack'
    
    # Error Handling
    'New-DeltaCrownErrorRecord'
    'Invoke-DeltaCrownWithErrorHandling'
    
    # Configuration
    'Import-DeltaCrownConfig'
)
